###
For ease-of-use during development or for small deployments, Pollster 
can be used with MongoDB as its only backend. However, the recommended
setup is DynamoDB for polling history and Redis for the queue and cache.
The latter will be considerably faster.
###

mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

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

    getFacetsFor: (id, callback) ->
        @get id, (err, result) ->
            return callback err if err
            callback err, (pluck result, facets)

    queryFacetsFor: (filter, callback) ->
        @query filter, (err, results) ->
            return callback err if err
            callback err, results.map (result) -> pluck result, facets


# ConsoleHistory is useful during development
class exports.Console extends History
    connect: (callback) -> callback null

    create: (callback) -> callback null

    put: (url, facet, timestamp, data, callback) ->
        if @level in [0, 2]
            # converting the data object into something that is more easily
            # readable on the command line
            values = _.flatten _.pairs utils.serialize.deflate row url, facet, timestamp, data
            console.log "[HISTORY]", values...
        if @level in [1, 2]
            @buffer.push row url, facet, timestamp, data

        callback null

    get: (id, callback) ->
        callback new Error "Cannot read from the console. Use a different backend."

    query: (filter, callback) ->
        callback new Error "Cannot read from the console. Use a different backend."

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
        @collection.insert object, callback

    get: (_id, callback) ->
        @collection.findOne {_id}, callback

    query: (filter, callback) ->
        (@collection.find filter).toArray callback

    stat: (callback) ->


class exports.DynamoDB extends History
    connect: (callback) ->
        @client = new AWS.DynamoDB().client

    create: (callback) ->
        @client.createTable params, (err, data) ->

    put: (data, callback) ->
        @client.putItem

    get: (id, callback) ->
        @client.getItem # single

    query: (filter, callback) ->
        @client.query # range

    stat: (callback) ->

    constructor: (@location, @credentials) ->
        # perhaps get credentials from ENV?
        # { "accessKeyId": "akid", "secretAccessKey": "secret", "region": "us-west-2" }