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


# TODO: add Redis queue
class exports.MongoDBQueue
    connect: ->

    create: ->

    read: ->

    write: ->

    update: ->

    delete: ->

    stat: ->

    constructor: (@location, @credentials) ->


# TODO: add Redis cache
class exports.MongoDBCache
    connect: ->

    create: ->

    read: ->

    write: ->

    update: ->

    delete: ->

    stat: ->

    constructor: (@location, @credentials) ->


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