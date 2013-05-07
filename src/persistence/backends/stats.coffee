mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


###
* stats table(s) *

    (a) get every row for a daterange, split up by facet
    (b) sorted set in Redis, ZINCR, clear out every hour/day
    (c) count in Node, flush to Redis every minute, 
        push to last-hour and last-day lists, and use 
        ZTRIM to keep them 60 and 1440 elements long respectively
###


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