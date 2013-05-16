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


class exports.Redis extends Queue
    connect: (callback) ->
        @client = engines.Redis.connect @location, callback

    create: (callback) ->
        callback null

    next: (key, callback=utils.noop) ->
        self = this
        [facet, url] = key.split '+'

        self.nextFor url, facet, (err, timestamp) ->
            self.client.zrem ['queue', key], (err, res) ->
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
        self = this
        now = utils.timing.now()
        query = ['queue', 0, now]
        self.client.zrangebyscore query, (err, items) ->
            items = items.map (member) ->
                {'facet+url': member, timestamp: now}
            self.processTasks items, callback

    push: (url, facet, timestamp, callback) ->
        if not timestamp then return callback null

        member = "#{facet}+#{url}"
        score = timestamp
        @client.zadd ['queue', score, member], callback
        @log 'push', {key: member, timestamp: "~#{score}"}
