mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'
_ = require 'underscore'
utils = require '../utils'

module.exports = 
    MongoDB:
        connect: (location, callback) ->
            defaults =
                host: '127.0.0.1'
                port: 27017
                name: 'pollster'
            location = _.defaults location, defaults

            manager = new mongodb.Server location.host, location.port, {}
            client = new mongodb.Db location.name, manager, {w: 1}
            client.open callback

        collection: (location, name, callback) ->
            module.exports.MongoDB.connect location, (err, client) ->
                return callback err if err
                client.collection name, (err, collection) ->
                    return callback err if err
                    callback null, collection, client

    DynamoDB:
        connect: (callback) ->

    Redis:
        # allows for a callback for consistency, but doesn't need one
        connect: (location, callback=utils.noop) ->
            if location
                client = redis.createClient location.port, location.host
            else
                client = redis.createClient()
            callback null, client
            return client