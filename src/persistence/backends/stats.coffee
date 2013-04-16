mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class Stats


# Not recommended but useful for development
class exports.Memory extends Stats
    connect: (callback) -> callback null

    create: (callback) -> callback null

    add: (key, value, callback) ->
        # maintain fixed size

    hourly: (callback) ->

    daily: (callback) ->

# TODO: add Redis cache
class exports.Redis extends Stats
    connect: (callback) ->

    create: (callback) ->

    add: (key, value, callback) ->
        # maintain fixed size

    hourly: (callback) ->

    daily: (callback) ->