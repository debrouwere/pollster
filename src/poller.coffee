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

        initialize = (db, done) -> 
            db.initialize done
        notify = (err) =>
            @connected = yes
            callback err  

        async.each backends, initialize, notify


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
            if err then return callback err
            poller.persistence.queue.rebuild (err) ->
                if err then return callback err
                poller.iid = setInterval (poller.poll.bind poller), 1000 * (timing.seconds 1)
                callback null

    stop: (callback) ->
        @onStop = callback