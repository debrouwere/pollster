###
For ease-of-use during development or for small deployments, Pollster 
can be used with MongoDB as its only backend. However, the recommended
setup is DynamoDB for polling history and Redis for the queue and cache.
The latter will be considerably faster.
###

mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'
async = require 'async'
_ = require 'underscore'
engines = require '../engines'
utils = require '../../utils'
{Facet} = require '../facet'

pluck = (row, facets) ->
    data = {}
    for name of facets
        data[name] = facets[name].pluck row
    data

row = (url, facet, timestamp, data) ->
    object = {url, timestamp}
    object[facet] = data
    object


class History
    constructor: (@location, @credentials, @facets) ->
        @backend = this.constructor.name
        _.bindAll this

    initialize: (callback) ->
        async.series [@connect, @create], (err) =>
            callback err, @collection, @client

    getFacetsFor: (id, callback) ->
        @get id, (err, result) ->
            if err then return callback err
            callback err, (pluck result, facets)

    queryFacetsFor: (filter, callback) ->
        @query filter, (err, results) ->
            if err then return callback err
            callback err, results.map (result) -> pluck result, facets

    log: (type, meta) ->
        switch type
            when 'write'
                values = _.flatten _.pairs utils.serialize.deflate meta.row
                console.log "[HISTORY]", values...


# ConsoleHistory is useful during development
class exports.Console extends History
    connect: (callback) -> callback null

    create: (callback) -> callback null

    put: (url, facet, timestamp, data, callback) ->
        object = row url, facet, timestamp, data
        if @level in [0, 2]
            # converting the data object into something that is more easily
            # readable on the command line
            @log 'write', {row: object}
        if @level in [1, 2]
            @buffer.push object

        callback null

    get: (id, callback) ->
        callback new Error "Cannot read from the console. Use a different backend."

    query: (filter, callback) ->
        if not @buffer
            callback new Error "Cannot read from an unbuffered console. Use a different backend."

    # get the last row from the database, 
    # optionally limited to a url and a facet
    last: (filter..., callback) ->
        filter = utils.optional filter
        callback null, _.findWhere @buffer.reverse(), filter

    # 0: output to console
    # 1: output to buffer
    # 2: output to both
    constructor: (@level = 0, credentials, @facets) ->
        if level > 0 then @buffer = []


class exports.MongoDB extends History
    # create any tables, buckets and what-not
    connect: (callback) ->
        engines.MongoDB.collection @location, 'history', (err, @collection, @client) =>
            callback err

    create: (callback) ->
        @collection.ensureIndex {timestamp: -1, url: 1}, callback

    put: (url, facet, timestamp, data, callback) ->
        object = row url, facet, timestamp, data
        @log 'write', {row: object}
        @collection.insert object, callback

    get: (_id, callback) ->
        @collection.findOne {_id}, callback

    query: (filter, callback) ->
        (@collection.find filter).toArray callback

    stat: (callback) ->
        throw new Error "Not implemented yet."


class exports.DynamoDB extends History
    constructor: ->
        super arguments...
        @tableName = utils.affix @location.prefix, 'pollster-history', @location.suffix
        @capacity = @location.capacity or {read: 10, write: 5}

    connect: (callback) ->
        @client = engines.DynamoDB.connect @location, callback
        @collection = engines.DynamoDB.interfaceFor @client, @tableName

    create: (callback) ->
        params = 
            TableName: @tableName
            AttributeDefinitions: [
                {
                    AttributeName: 'url'
                    AttributeType: 'S'
                }
                {
                    AttributeName: 'timestamp'
                    AttributeType: 'N'
                }
            ]
            KeySchema: [
                {
                    AttributeName: 'url'
                    KeyType: 'HASH'
                }
                {
                    AttributeName: 'timestamp'
                    KeyType: 'RANGE'
                }
            ]
            ProvisionedThroughput: 
                ReadCapacityUnits: @capacity.read
                WriteCapacityUnits: @capacity.write

        @collection.createTable params, callback

    put: (url, facet, timestamp, data, callback) ->
        item = row url, facet, timestamp, data
        @log 'write', {row: item}
        @collection.put item, callback

    # TODO: this isn't proper
    get: (key..., value, callback) ->
        key = 'url'
        @collection.get key, value, callback

    query: (filter, callback) ->
        throw new Error "Not implemented yet."
        #@collection.query

    stat: (callback) ->
        throw new Error "Not implemented yet."
