mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class Cache


# Not recommended but useful for development
class exports.Memory extends Cache
    connect: (callback) -> callback null

    create: (callback) -> callback null

    get: (key, callback) ->
        callback null, @store[key]

    set: (key, value, callback) ->
        if not key of @store
            oldestKey = @keys.pop()
            delete @store[oldestKey]
        
        @keys.unshift key
        @store[key] = value
        callback null

    invalidate: (key, callback) ->
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
class exports.Redis extends Cache
    connect: (callback) ->

    create: (callback) ->

    get: (key, callback) ->

    set: (key, value, callback) ->

    invalidate: (key, callback) ->

    stat: (callback) ->

    constructor: (@size) ->