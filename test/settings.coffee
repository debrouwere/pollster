async = require 'async'
engines = require '../src/persistence/engines'
backends = require '../src/persistence/backends'

exports.locations = locations =
    mongodb:
        name: 'pollster-test'
        host: '127.0.0.1'
        port: 27017



if process.env.POLLSTER_AWS_ACCESS_KEY_ID
    locations.dynamodb = 
        accessKeyId: process.env.POLLSTER_AWS_ACCESS_KEY_ID
        secretAccessKey: process.env.POLLSTER_AWS_SECRET_ACCESS_KEY
        region: process.env.POLLSTER_AWS_REGION
        prefix: 'test'


exports.clear = clear =
    mongodb: (callback) ->
        engines.MongoDB.connect locations.mongodb, (err, client) ->
            client.dropDatabase callback
            
    console: (callback) ->
        history.Console = new backends.history.Console history.Console.level
        callback()

    redis: (callback) ->
        engines.Redis.connect undefined, (err, client) ->
            client.flushdb callback

    dynamodb: (callback) ->
        client = engines.DynamoDB.connect locations.dynamodb
        tables = [
            'test-pollster-watchlist'
            'test-pollster-history'
            ]

        deleteTable = (name, done) ->
            table = engines.DynamoDB.interfaceFor client, name
            table.deleteTable done

        async.each tables, deleteTable, callback


exports.queue = queue =
    MongoDB: new backends.queue.MongoDB locations.mongodb
    Redis: new backends.queue.Redis null, null

exports.history = history =
    Console: new backends.history.Console 1
    MongoDB: new backends.history.MongoDB locations.mongodb
    #DynamoDB: new backends.history.DynamoDB locations.dynamodb

exports.watchlist = watchlist =
    MongoDB: new backends.watchlist.MongoDB locations.mongodb
    DynamoDB: new backends.watchlist.DynamoDB locations.dynamodb

for name, driver of queue
    driver.watchlist = watchlist[name]

for name, driver of watchlist
    driver.queue = queue[name]