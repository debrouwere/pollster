mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
async = require 'async'
engines = require '../engines'
utils = require '../../utils'
facets = require '../../facets'
{Facet} = require '../facet'


class Queue
    unpack: (item, callback) ->
        {url, facet, calendar} = item
        console.log 'unpacking', item
        @push url, facet, next, callback

    nextFor: (url, facet, callback) ->
        @watchlist.getCalendarsFor url, (err, calendars) ->
            calendar = calendars[facet]
            timestamp = calendar.next()
            callback err, timestamp

    optionsFor: (url, facetName, callback) ->
        @watchlist.get url, (err, configuration) ->
            if err then callback err
            facet = facets[facetName]
            facet = facet.extend configuration.options
            callback null, facet

    recover: (url, facet, timestamp) ->
        retry = =>
            console.log "[RETRY] [#{timestamp}] #{url} #{facet} "
            @push url, facet, timestamp, utils.noop
        setTimeout retry, 60 * 1000

    recoveryFor: (url, facetName, timestamp) ->
        retryId = @recover url, facetName, timestamp

        (err, done=utils.noop) ->
            clearTimeout retryId
            done err

    processTasks: (rawTasks, callback) ->
        next = @next.bind this
        inflate = @inflate.bind this
        async.map rawTasks, inflate, (err, tasks) ->
            # remove these tasks from the queue and create new ones
            # before handing things off -- this avoids polling keys
            # twice
            keys = _.pluck rawTasks, 'facet+url'
            async.each keys, next, (err) ->
                callback err, tasks

    rebuild: (callback) ->
        console.log '[REBUILDING WATCHLIST]'
        unpack = @unpack.bind this

        @watchlist.list (err, list) =>
            flattenedWatchList = []
            for url, relatedFacets of list
                for facet, calendar of relatedFacets
                    next = calendar.next align: yes
                    if next then flattenedWatchList.push {url, facet, next}

            async.each flattenedWatchList, unpack, callback
 
    log: (type, meta) ->
        switch type
            when 'push'
                console.log "[SCHEDULE] [#{meta.timestamp}] #{meta.key}"

    constructor: (@location, @watchlist, @facets) ->


class exports.MongoDB extends Queue
    connect: (callback) ->
        engines.MongoDB.collection @location, 'queue', (err, @collection, @client) =>
            callback err

    create: (callback) ->
        @collection.ensureIndex 'facet+url', callback

    next: (key, callback=utils.noop) ->
        self = this
        [facet, url] = key.split '+'

        self.nextFor url, facet, (err, timestamp) ->
            self.collection.remove {'facet+url': key}, (err) =>
                self.push url, facet, timestamp, callback

    inflate: (doc, callback) ->
        [facetName, url] = utils.split doc['facet+url'], '+', 1
        @optionsFor url, facetName, (err, facet) =>
            # `notify` is run when a task is finished, and this 
            # will call off the recovery (retry attempts)
            notify = @recoveryFor url, facetName, doc['timestamp']
            callback null, {url, facet, notify}

    pop: (callback) ->
        # once the caller has finished with whatever it has popped off
        # the queue, it should call `success` so we can do the necessary
        # cleanup on this end
        now = utils.timing.now()
        query = {timestamp: {$lte: now}}

        (@collection.find query).toArray (err, documents) =>
            if err then return callback err            
            @processTasks documents, callback

    push: (url, facet, timestamp, callback) ->
        if not timestamp then return callback null

        key = "#{facet}+#{url}"
        item = 
            'facet+url': key
            'timestamp': timestamp

        @collection.update {'facet+url': key}, item, {safe: yes, upsert: yes}, callback
        @log 'push', {key, timestamp}

# TODO: add Redis queue
class exports.Redis extends Queue
    connect: (callback) ->

    create: (callback) ->

###
* queue table (sorted set) *

    score => facet+url

    - when a new URL gets added: 
      add all its facets to the queue as well
      with score 0 (= now)
      ZADD 0 facet+url 0 facet+url 0 facet+url ...

    - every second:
      ZRANGE myzset 0 current_time
    - add to `async.queue` with MAX_CONCURRENT requests
      (this is *per facet/service*, Node itself will
      take care the server doesn't take on more -- globally --
      than it can handle)
    - if facet successfully fetched and saved
      - fetch settings[facet+url], compute next tick
        (meaning "earliest tick in the future" -- 
        if the service was interrupted and we've missed
        ticks, so be it)
      - update item score (next tick)
        ZADD score facet+url [this is a set, so ZADD = update]
###