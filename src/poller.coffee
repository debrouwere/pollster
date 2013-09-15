async = require 'async'
_ = require 'underscore'
AWS = require 'aws-sdk'
dynode = require 'dynode'
facets = require './facets'
utils = require './utils'

credentials = 
    accessKeyId: process.env.AWS_ACCESS_KEY_ID
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    region: process.env.AWS_REGION

sqs = new AWS.SQS credentials
dynamo = new dynode.Client credentials
namespace = 'pollster'


# initialization
createTable = (done) ->
    dynamo.listTables (err, {TableNames}) ->
        if err then return done err

        if namespace in TableNames
            done null
        else
            indexes = {hash: {url: String}, range: {timestamp: Number}}
            dynamo.createTable namespace, indexes, done

createQueue = (done) ->
    sqs.createQueue {QueueName: namespace}, done


class Break

Break.prototype = new Error


# pluck a single message from the queue
inquire = (QueueUrl, callback) ->
    receive = (done) ->
        sqs.receiveMessage {QueueUrl}, done

    process = ({Messages}, done) ->
        if not Messages?.length then return done new Break()

        message = Messages[0]
        {url, subset} = JSON.parse message.Body
        subset ?= facets.all
        # TODO: make what facets to fetch configurable through the CLI
        facets.poll url, subset, (err, data) ->
            timestamp = utils.timing.now()
            indexedData = _.extend {url, timestamp}, data
            done err, message.ReceiptHandle, indexedData

    store = (handle, data, _done) ->
        done = (err) -> _done err, handle

        if data?
            console.log 'saving data', (utils.serialize.deflate data, '/')
            dynamo.putItem namespace, (utils.serialize.deflate data, '/'), done
        else
            done null

    acknowledge = (ReceiptHandle, done) ->
        if ReceiptHandle
            sqs.deleteMessage {QueueUrl, ReceiptHandle}, done
        else
            done null

    async.waterfall [receive, process, store, acknowledge], (err) ->
        if err instanceof Break
            callback null
        else
            callback err

# listen for new messages indefinitely, but one at a time
# and only once per second at most
listen = ({QueueUrl}, done) ->
    inquireForQueue = async.apply inquire, QueueUrl
    niceInquire = utils.debounce inquireForQueue, 1000
    async.forever niceInquire, done


# initialize and listen
exports.listen = ->
    async.waterfall [createTable, createQueue, listen], (err) ->
        console.log err