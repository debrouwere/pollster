_ = require 'underscore'
async = require 'async'
fetch = (require './persistence').process.tasks
utils = require './utils'
timing = utils.timing

class exports.Poller
    constructor: (@persistence) ->
        @connected = no
        @busy = no

    connect: (callback) ->
        backends = (_.values @persistence)
        _connect = (db, done) -> 
            db.connect done
        async.each backends, _connect, (err) =>
            @connected = yes
            callback err

    track: (url, parameters, callback) ->
        console.log "[POLLER] Now tracking #{url}"
        @persistence.watchlist.watch url, parameters, (callback or utils.noop)

    poll: (callback=utils.noop) ->
        {persistence} = this

        if @busy
            return callback null
        else
            @busy = yes

        if @onStop?
            clearInterval @iid
            @onStop()
        else
            persistence.queue.pop (err, definitions) =>
                @busy = no
                if err then return callback err
                console.log "[POLLER] popped #{definitions.length} task(s) from the queue"
                fetch definitions, persistence, callback

    start: (callback) ->
        poller = this
        poller.connect (err) ->
            if err then callback err
            console.log 'connected to DB, rebuilding queue'
            poller.persistence.queue.rebuild (err) ->
                if err then callback err
                poller.iid = setInterval (poller.poll.bind poller), 1000 * (timing.seconds 1)
                callback null

    stop: (callback) ->
        @onStop = callback