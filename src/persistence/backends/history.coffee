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
utils = require '../../utils'
{Facet} = require '../facet'

pluck = (row, facets) ->
    data = {}
    for name of facets
        data[name] = facets[name].pluck row
    data

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

    put: (data, callback) ->
        console.log data
        if @buffer then @buffer.push data
        callback null

    get: (id, callback) ->
        callback new Error "Cannot read from the console. Use a different backend."

    query: (filter, callback) ->

    constructor: (buffer, credentials, @facets) ->
        if buffer then @buffer = []


class exports.MongoDB extends History
    # create any tables, buckets and what-not
    connect: (callback) ->
        dbManager = new Server '127.0.0.1', 27017, {}
        dbClient = new mongodb.Db 'pollster', dbManager, {w: 1}
        dbClient.open (err, pClient) ->

    create: (callback) ->
        client.collection 'testCollection', (err, collection) ->

    put: (data, callback) ->

    get: (id, callback) ->

    query: (filter, callback) ->

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