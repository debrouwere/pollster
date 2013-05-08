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

exports.queue = queue =
    MongoDB: new backends.queue.MongoDB locations.mongodb

exports.history = history =
    MongoDB: new backends.history.MongoDB locations.mongodb
    Console: new backends.history.Console 1

exports.watchlist = watchlist =
    MongoDB: new backends.watchlist.MongoDB locations.mongodb