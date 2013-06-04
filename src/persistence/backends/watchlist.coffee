_ = require 'underscore'
async = require 'async'
engines = require '../engines'
utils = require '../../utils'
{Facet} = require '../facet'


# different calendars can share the same options, but it's
# useful to have them split out per facet too
untangle = (result) ->
    result.facets.map (facet) -> _.extend {facet}, result


class WatchList
    constructor: (@location, @defaults={}) ->
        @backend = this.constructor.name
        _.bindAll this

    initialize: (callback) ->
        async.series [@connect, @create], (err) =>
            callback err, @collection, @client

    _buildCalendarsFor: (results) ->
        parameters = _.flatten results.map untangle
        calendars = parameters.map (params) -> 
            [params.facet, utils.timing.Calendar.create params]  
        _.object calendars

    getParameters: (url, parameters) ->
        params = _.extend {url}, @defaults, parameters
        if params.window[1]? in [null, -1]
            params.window[1] = Infinity
        params

    buildTask: (url, parameters) ->
        item = @getParameters url, parameters
        # in some cases we don't want to replace existing calendars
        # when the URL is already in the system; we can do this with
        # the `replace: no` option
        calendar = utils.timing.Calendar.create item
        nextTick = calendar.next -1

        (facet, done) =>
            @queue.push url, facet, nextTick, done


class exports.MongoDB extends WatchList
    connect: (callback) ->
        engines.MongoDB.collection @location, 'watchlist', (err, @collection, @client) =>
            callback err

    create: (callback) ->
        @collection.ensureIndex 'url', callback

    getCalendarsFor: (url, callback) ->
        (@collection.find {url}).toArray (err, results) =>
            if err
                callback err
            else
                callback null, @_buildCalendarsFor results

    get: (url, callback) ->
        @collection.findOne {url}, (err, result) =>
            if err then return callback err
            result.calendars = @_buildCalendarsFor [result]
            callback null, result

    list: (callback) ->
        @collection.find().toArray (err, results) =>
            calendars = _.groupBy results, 'url'
            for url, parameters of calendars
                calendars[url] = @_buildCalendarsFor parameters
            callback err, calendars

    watch: (url, parameters, callback) ->
        item = @getParameters url, parameters
        enqueue = @buildTask url, parameters

        @collection.findOne {url}, (err, found) =>
            if found and not (parameters.replace or found.options.replace)
                callback null
            else
                @collection.update {url}, item, {safe: yes, upsert: yes}, (err) ->
                    async.each item.facets, enqueue, callback

    unwatch: (url, callback) ->
        @collection.remove {url}, callback


class exports.DynamoDB extends WatchList
    constructor: ->
        super arguments...

        @tableName = utils.affix @location.prefix, 'pollster-watchlist', @location.suffix
        @capacity = @location.capacity or {read: 10, write: 5}

    connect: (callback) ->
        @client = engines.DynamoDB.connect @location, callback
        options = 
            serialized: yes
            pk: 'url'
            keys:
                url: 'S'
        @collection = engines.DynamoDB.interfaceFor @client, @tableName, options

    create: (callback) ->
        params = 
            TableName: @tableName
            AttributeDefinitions: [
                {
                    AttributeName: 'url'
                    AttributeType: 'S'
                }
            ]
            KeySchema: [
                {
                    AttributeName: 'url'
                    KeyType: 'HASH'
                }
            ]
            ProvisionedThroughput: 
                ReadCapacityUnits: @capacity.read
                WriteCapacityUnits: @capacity.write

        @collection.createTable params, callback

    getCalendarsFor: (url, callback) ->
        @collection.get url, (err, result) =>
            if err
                callback err
            else
                callback err, @_buildCalendarsFor [result]

    get: (url, callback) ->
        @collection.get url, (err, result) =>
            if err then return callback err
            result.calendars = @_buildCalendarsFor [result]
            callback null, result

    list: (callback) ->
        @collection.scan (err, results) =>
            if err then return callback err

            calendars = _.groupBy results, 'url'

            for url, parameters of calendars
                calendars[url] = @_buildCalendarsFor parameters

            callback err, calendars

    watch: (url, parameters, callback) ->
        collection = @collection
        item = @getParameters url, parameters
        enqueue = @buildTask url, parameters

        collection.get url, (err, found) ->
            if false and found and not (parameters.replace or found.options.replace)
                callback null
            else
                collection.put item, (err) ->
                    if err
                        callback err
                    else
                        async.each item.facets, enqueue, callback

    unwatch: (url, callback) ->
        @collection.remove url, callback
