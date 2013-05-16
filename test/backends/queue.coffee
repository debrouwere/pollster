should = require 'should'
async = require 'async'
_ = require 'underscore'
settings = require '../settings'
facets = require '../../src/facets'

test = (db) -> ->
    row = ['http://example.org', 'facebook', 123]
    {url, facet, timestamp} = row

    # db.next and db.optionsFor test the watchlist more than the queue, so
    # we're turning them into noops / stubs here
    db = _.clone db
    db.next = (key, callback) ->
        callback null
    db.optionsFor = (url, facetName, callback) ->
        callback null, facets[facetName]

    beforeEach (done) ->    
        dbtype = db.constructor.name.toLowerCase()
        connect = db.connect.bind db
        setup = [settings.clear[dbtype], connect]
        async.parallel setup, done

    it 'can push a task to the queue', (done) ->
        db.push row..., (err) ->
            should.not.exist err
            done()

    it 'can pop a task from the queue', (done) ->
        db.push row..., (err) ->
            db.pop (err, tasks) ->
                console.log 'popped tasks', tasks
                tasks.length.should.eql 1
                task = tasks[0]
                task.url.should.eql row[0]
                task.facet.name.should.eql row[1]
                task.notify.should.be.a 'function'
                done()

describe 'MongoDB queue backend', test settings.queue.MongoDB
describe 'Redis queue backend', test settings.queue.Redis