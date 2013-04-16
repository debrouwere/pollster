mongodb = require 'mongodb'
redis = require 'redis'
AWS = require 'aws-sdk'

_ = require 'underscore'
utils = require '../../utils'
{Facet} = require '../facet'


class BlobStorage


class exports.File extends BlobStorage
    connect: ->
        # noop for compatibility

    get: (id, callback) ->

    put: (content, callback) ->
        callback null, id

    size: (callback) ->


class exports.S3 extends BlobStorage
    connect: ->
        @client = new AWS.DynamoDB().client

    get: (id, callback) ->

    put: (content, callback) ->
        callback null, id

    size: (callback) ->