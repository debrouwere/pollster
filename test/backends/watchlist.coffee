should = require 'should'
async = require 'async'
_ = require 'underscore'
settings = require '../settings'

test = (db) -> ->
    if not db
        console.log 'WARNING: no DynamoDB credentials found, skipping tests'
        return

    # TODO: take care of creation of the DB too
    # (necessary in the case of DynamoDB)
    beforeEach (done) ->    
        this.timeout 120 * 1000
        dbtype = db.backend.toLowerCase()
        setup = [settings.clear[dbtype], db.initialize]
        async.series setup, done

    url = 'http://guardian.co.uk'
    facets = ['facebook', 'twitter']

    # queue mock
    db.queue = 
        push: (_url, facet, nextTick, done) ->
            _url.should.eql url
            (facet in facets).should.be.true
            nextTick.should.be.a 'number'
            done.should.be.a 'function'
            done null

    it 'can fetch polling calendars associated with a URL in the watchlist', (done) ->
        db.watch url, {facets}, (err) ->
            should.not.exist err
            db.getCalendarsFor url, (err, calendars) ->
                should.not.exist err
                calendars.should.have.property facets[0]
                calendars.should.have.property facets[1]
                calendar = calendars[facets[0]]
                calendar.should.be.a 'object'
                done()

    it 'can watch a URL and list all watched URLs', (done) ->
        db.watch url, {facets}, (err) ->
            should.not.exist err
            db.list (err, list) ->
                (_.values list[url]).length.should.eql 2
                list[url][facets[0]].should.be.a 'object'
                done()

    it 'can unwatch a URL', (done) ->
        db.watch url, {facets}, (err) ->
            db.unwatch url, (err) ->
                should.not.exist err
                db.list (err, list) ->
                    (_.values list).length.should.eql 0
                    done()

    # watch: (url, options, callback) ->
    # unwatch: (url, callback) ->

describe 'MongoDB watchlist backend', test settings.watchlist.MongoDB
#describe 'DynamoDB watchlist backend', test settings.watchlist.DynamoDB