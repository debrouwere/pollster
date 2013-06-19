crypto = require 'crypto'
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
    constructor: (@location, @watchlist, @facets) ->
        @backend = this.constructor.name
        _.bindAll this

    initialize: (callback) ->
        async.series [@connect, @create], (err) =>
            callback err, @collection, @client

    unpack: (item, callback) ->
        {url, facet, timestamp} = item
        @push url, facet, timestamp, 1, callback

    # an easy way to divide up the workload between different 
    # pollster instances, this decides whether or not to push
    # something to the (local) queue.
    isResponsible: (url) ->
        # every pollster instance should process watchlist feeds;
        # it's only the workload contained in those feeds that 
        # gets divided between instances
        if url in @watchlist.feeds then return yes

        spec = @location?.instance or '1/1'
        [i, n] = spec.split '/'
        # i should be zero-indexed for our calculation
        i = i - 1

        # create an md5 digest and then turn it into 
        # a base 10 number
        md5 = crypto.createHash 'md5'
        md5.update url
        digest = md5.digest 'hex'
        x = parseInt digest.slice(-10), 16
        
        x % n is i

    nextFor: (url, facet, callback) ->
        @watchlist.getCalendarsFor url, (err, calendars) ->
            calendar = calendars[facet]
            timestamp = calendar.next()
            callback err, timestamp

    optionsFor: (url, facetName, callback) ->
        @watchlist.get url, (err, configuration) ->
            if err then return callback err
            facet = facets[facetName]
            facet = facet.extend configuration.options
            callback null, facet

    # TODO: perhaps make delay configurable, right now 
    # I'm putting in some delay to avoid hammering an API
    recover: (url, facet, timestamp, attempt) ->
        retry = =>
            console.log "[RETRY] [#{timestamp}] #{url} #{facet} "
            @push url, facet, timestamp, (attempt + 1), utils.noop
        setTimeout retry, 60 * 1000

    recoveryFor: (url, facetName, timestamp, attempt) ->
        retryId = @recover url, facetName, timestamp, attempt

        (err, done=utils.noop) ->
            clearTimeout retryId
            done err

    processTasks: (rawTasks, callback) ->
        # REFACTOR
        # sort of hackish... didn't properly abstract some 
        # of the MongoDB stuff
        rawTasks = rawTasks.map (task) ->
            if not task['facet+url']
                task['facet+url'] ?= task['facet'] + '+' + task['url']
            task

        next = @next.bind this
        inflate = @inflate.bind this

        uniqueTasks = rawTasks.filter (task) -> task.attempt is 1

        async.map uniqueTasks, inflate, (err, tasks) ->
            # remove these tasks from the queue and create new ones
            # before handing things off -- this avoids polling keys
            # twice
            keys = _.pluck uniqueTasks, 'facet+url'
            async.each keys, next, (err) ->
                callback err, tasks

    rebuild: (callback) ->
        unpack = (list, done) =>
            console.log "[REBUILDING QUEUE: #{list.length} items on the watchlist]"
            flattenedWatchList = []
            for url, relatedFacets of list
                for facet, calendar of relatedFacets
                    next = calendar.next null, align: yes
                    if next then flattenedWatchList.push {url, facet, timestamp: next}

            async.each flattenedWatchList, @unpack, done

        async.waterfall [@clear, @watchlist.list, unpack], callback
 
    log: (type, meta) ->
        switch type
            when 'push'
                console.log "[SCHEDULE] [#{meta.timestamp}] #{meta.key} [ATTEMPT #{meta.attempt}]"


class exports.MongoDB extends Queue
    connect: (callback) ->
        engines.MongoDB.collection @location, 'queue', (err, @collection, @client) =>
            callback err

    create: (callback) ->
        @collection.ensureIndex 'facet+url', callback

    clear: (callback) ->
        @collection.remove (err, res) -> callback err

    next: (key, callback=utils.noop) ->
        self = this
        [facet, url] = key.split '+'

        self.nextFor url, facet, (err, timestamp) ->
            self.collection.remove {'facet+url': key}, (err) =>
                self.push url, facet, timestamp, 1, callback

    inflate: (doc, callback) ->
        [facetName, url] = utils.split doc['facet+url'], '+', 1
        @optionsFor url, facetName, (err, facet) =>
            # `notify` is run when a task is finished, and this 
            # will call off the recovery (retry attempts)
            notify = @recoveryFor url, facetName, doc['timestamp'], doc['attempt']  
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

    push: (url, facet, timestamp, attempt, callback) ->
        responsible = @isResponsible url
        retryable = attempt < 4
        inWindow = timestamp

        if not (responsible and retryable and inWindow) then return callback null

        key = "#{facet}+#{url}"
        item = 
            'facet+url': key
            'timestamp': timestamp
            'attempt': attempt

        @collection.update {'facet+url': key}, item, {safe: yes, upsert: yes}, callback
        @log 'push', {key, timestamp, attempt}


class exports.Redis extends Queue
    connect: (callback) ->
        @client = engines.Redis.connect @location, callback

    create: (callback) ->
        process.nextTick -> callback null

    clear: (callback) ->
        @client.del 'queue', (err, res) -> callback err

    next: (key, callback=utils.noop) ->
        self = this
        [facet, url] = key.split '+'

        self.nextFor url, facet, (err, timestamp) ->
            self.client.zrem ['queue', key], (err, res) ->
                self.push url, facet, timestamp, 1, callback

    inflate: (doc, callback) ->
        [facetName, url] = utils.split doc['facet+url'], '+', 1
        @optionsFor url, facetName, (err, facet) =>
            # `notify` is run when a task is finished, and this 
            # will call off the recovery (retry attempts)
            notify = @recoveryFor url, facetName, doc['timestamp'], doc['attempt']
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
                [attempt, item] = utils.split member, '+', 1
                {'facet+url': item, timestamp: now, attempt: (parseInt attempt)}
            self.processTasks items, callback

    push: (url, facet, timestamp, attempt, callback) ->
        responsible = @isResponsible url
        retryable = attempt < 4
        inWindow = timestamp

        if not (responsible and retryable and inWindow) then return callback null

        member = "#{attempt}+#{facet}+#{url}"
        score = timestamp
        @client.zadd ['queue', score, member], callback
        @log 'push', {key: member, timestamp: "~#{score}", attempt}