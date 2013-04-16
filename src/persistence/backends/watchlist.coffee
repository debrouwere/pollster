mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class WatchList
    constructor: (@location, @credentials) ->


class exports.MongoDB extends WatchList
    connect: (callback) ->
        manager = new mongodb.Server '127.0.0.1', 27017, {}
        client = new mongodb.Db 'pollster', dbManager, {w: 1}
        client.open (err, @client) =>
            callback err

    # create any tables, buckets and what-not
    create: (callback) ->

    watch: (url, options, callback) ->

    unwatch: (url, callback) ->


class exports.DynamoDB extends WatchList
    connect: (callback) ->
        @client = new AWS.DynamoDB().client

    create: (callback) ->

    watch: (url, options, callback) ->

    unwatch: (url, callback) ->