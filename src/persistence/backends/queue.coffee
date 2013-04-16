mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class Queue
    rebuild: (watchlist, callback) ->
        callback new Error "Not implemented yet."
 
    constructor: (@location, @credentials) ->


class exports.MongoDB extends Queue
    connect: (callback) ->
        manager = new mongodb.Server '127.0.0.1', 27017, {}
        client = new mongodb.Db 'pollster', dbManager, {w: 1}
        client.open (err, @client) =>
            callback err

    create: (callback) ->
        callback null

    pop: (query, callback) ->
        client.collection 'queue', (err, collection) ->
            collection.find query, {safe: yes}, callback

    push: (object, callback) ->
        client.collection 'queue', (err, collection) ->
            collection.update object, {safe: yes, upsert: yes}, callback




# TODO: add Redis queue
class exports.Redis extends Queue
    connect: (callback) ->

    create: (callback) ->

    pop: (query, callback) ->

    push: (object, callback) ->