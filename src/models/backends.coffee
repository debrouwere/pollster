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
utils = require '../utils'
{Facet} = require './facet'


# ConsoleHistory is useful during development
class exports.ConsoleHistory
    connect: (callback) -> callback null
    create: (callback) -> callback null
    read: (callback) ->
        callback new Error "Cannot read from the console. Use a different backend."

    write: (data, callback) ->
        console.log data
        if @buffer then @buffer.push data
        callback null

    constructor: (buffer = no) ->
        if buffer then @buffer = []


class exports.MongoDBHistory
    # create any tables, buckets and what-not
    connect: (callback) ->
        dbManager = new Server '127.0.0.1', 27017, {}
        dbClient = new mongodb.Db 'pollster', dbManager, {w: 1}
        dbClient.open (err, pClient) ->

    create: (callback) ->
        client.collection 'testCollection', (err, collection) ->

    read: ->

    write: ->

    update: ->

    delete: ->

    stat: ->

    constructor: (@location, @credentials) ->


class exports.DynamoDBHistory
    connect: (callback) ->
        @client = new AWS.DynamoDB().client

    create: (callback) ->
        @client.createTable params, (err, data) ->

    read: ->
        @client.getItem # single
        @client.query # range

    write: ->
        @client.putItem

    update: ->
        @client.updateItem

    delete: ->
        @client.deleteItem

    stat: ->

    constructor: (@location, @credentials) ->
        # perhaps get credentials from ENV?
        # { "accessKeyId": "akid", "secretAccessKey": "secret", "region": "us-west-2" }



class exports.MongoDBQueue
    connect: ->

    create: ->

    read: ->

    write: ->

    update: ->

    delete: ->

    stat: ->

    constructor: (@location, @credentials) ->


# TODO: add Redis queue
class exports.RedisQueue


# Not recommended but useful for development
class exports.MemoryCache
    ###


    # FIFO cache
    cache = (key, value) ->        
    ###

    connect: (callback) -> callback null
    create: (callback) -> callback null

    read: (key, callback) ->
        callback null, @store[key]

    write: (key, value, callback) ->
        oldestKey = @keys.pop()
        delete @store[oldestKey]
        @keys.unshift key
        @store[key] = value
        callback null

    update: (key, value, callback) ->
        if key of @store
            @store[key] = value
            callback null
        else
            callback new Error "#{key} not in cache."

    delete: (callback) ->
        delete @store[key]
        callback null

    stat: (callback) ->
        callback
            size: @keys.length
            items: (_.compact @keys).length

    constructor: (@size) ->
        @keys = new Array(@size)
        @store = {}

# TODO: add Redis cache
class exports.RedisCache


class exports.FileBlobStorage
    connect: ->
        # noop for compatibility

    read: ->

    write: ->

    size: ->


class exports.S3BlobStorage
    connect: ->
        @client = new AWS.DynamoDB().client

    read: ->

    write: ->

    stat: ->