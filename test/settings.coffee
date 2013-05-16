engines = require '../src/persistence/engines'
backends = require '../src/persistence/backends'

exports.locations = locations =
    mongodb:
        name: 'application-test'
        host: '127.0.0.1'
        port: 27017

exports.clear = clear =
    mongodb: (done) ->
        engines.MongoDB.connect locations.mongodb, (err, client) ->
            client.dropDatabase done
    console: (done) ->
        history.Console = new backends.history.Console history.Console.level
        done()
    redis: (done) ->
        engines.Redis.connect undefined, (err, client) ->
            client.flushdb done

exports.queue = queue =
    MongoDB: new backends.queue.MongoDB locations.mongodb
    Redis: new backends.queue.Redis null, null

exports.history = history =
    MongoDB: new backends.history.MongoDB locations.mongodb
    Console: new backends.history.Console 1

exports.watchlist = watchlist =
    MongoDB: new backends.watchlist.MongoDB locations.mongodb

for name, driver of queue
    driver.watchlist = watchlist[name]

for name, driver of watchlist
    driver.queue = queue[name]