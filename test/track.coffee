should = require 'should'
pollster = require '../src'
engines = pollster.persistence.engines
# weird mocha bug with `module.exports` in `persistence/backends/index.coffee`, 
# so we're requiring this separately
db = require '../src/persistence/backends'
utils = require '../src/utils'
settings = require './settings'
async = require 'async'
{track, timing} = utils


describe 'Add, update and remove pages from the polling queue.', ->
    backends =
        watchlist: settings.watchlist.MongoDB
        queue: settings.queue.MongoDB
        history: settings.history.Console

    url = 'http://example.org'
    options = 
        facets: ['facebook', 'twitter']
        window: [0, 30]
        tick: 10
        decay: no
        start: timing.now()

    application = new pollster.Pollster backends
    application.use 'facebook'
    application.use 'twitter'
    app = application.app

    beforeEach (done) ->
        # hm, settings.clear.mongodb doesn't always work
        backends.history.buffer = []
        async.parallel [settings.clear.console, settings.clear.mongodb], done

    it 'can connect the poller to all the various database backends', (done) ->
        application.poller.connected.should.be.false
        application.poller.connect (err) ->
            application.poller.connected.should.be.true
            done()

    it 'can add a URL to the watchlist programatically', (done) ->
        # normally you'd just do application.start(), but we want 
        # to isolate certain parts so we're testing units rather
        # than the entire app
        application.poller.connect (err) ->
            should.not.exist err
            application.track url, options, (err) ->
                should.not.exist err
                application.poller.persistence.watchlist.collection.count (err, count) ->
                    should.not.exist err
                    count.should.eql 1
                    done err       

    it 'will use the watchlist to populate the queue', (done) ->
        application.poller.connect (err) ->
            application.track url, options, (err) ->
                key = {'facet+url': "#{options.facets[0]}+#{url}"}
                application.poller.persistence.queue.collection.findOne key, (err, task) ->
                    should.not.exist err
                    task.timestamp.should.be.above 0
                    done err     

    it 'can add a URL to the watchlist through the REST interface'
    (done) ->
        request(app)
            .put('/facets/twitter/?url=http://example.org')
            .expect(200)
            .end (err, res) ->
                if err then done err
                ix = 'twitter+http://example.org'
                (ix in application.watchlist).should.be.true

    it 'can add a URL to the watchlist by detecting new items in a feed'
    (done) ->
    # instead of detecting new items in a feed, just 
    # do a get-or-create for every item in the feed

    it 'can start polling for any URL in the queue', (done) ->
        this.timeout 1000 * timing.seconds 10
        poller = application.poller
        poller.connect (err) ->
            should.not.exist err
            application.track url, options, (err) ->
                should.not.exist err
                poller.poll ->
                    console.log poller.persistence.history.buffer
                    poller.persistence.history.buffer.length.should.eql 2
                    done()

    it 'can rebuild a queue from scratch, using a watchlist'
    (done) ->

    it 'will poll for any URL at the specified intervals', (done) ->
        this.timeout 1000 * timing.seconds 60
        now = timing.now()
        interval = 10
        ticks = [0, 10, 20, 30].map timing.seconds

        console.log 'QUERULANT.', application.persistence.history.buffer

        afterTicks = ->
            console.log application.persistence.history.buffer
            n = options.facets.length
            buffer = application.persistence.history.buffer
            buffer.length.should.equal ticks.length * n
            for row, i in buffer
                tick = Math.ceil (i + 1) / n
                ('twitter' of row or 'facebook' of row).should.be.true
                (row.twitter or row.facebook?.shares).should.be.a 'number'
                # intervals need to be respected
                if tick > 1
                    (row.timestamp - buffer[i-n].timestamp).should.not.be.below interval

            done()

        application.poller.start (err) ->
            application.track url, options, (err) ->
                setTimeout afterTicks, 40 * 1000

    # TODO: in addition to the raw functionality, also test the shortcuts like 
    # application.poll, convenience functions to get history, shortcuts that work
    # through the Facet class etc.

    # TODO: test all backends somehow

    it 'will remove a URL from the queue once the window has passed'
    (done) ->

    it 'will write the data gathered by polling to a history table'
    (done) ->