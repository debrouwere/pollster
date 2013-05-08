should = require 'should'
backends = require '../../src/persistence/backends'
settings = require '../settings'
async = require 'async'

describe 'Console history backend', ->
    it 'can output history to the console', (done) ->
        history = new backends.history.Console 0
        history.put 'http://propublica.org', 'facebook', 0, 'test', ->
            should.not.exist history.buffer
            done()

    it 'can buffer history in an in-memory array', (done) ->
        history = new backends.history.Console 1
        url = 'http://propublica.org'
        facet = 'facebook'
        timestamp = 0
        data = 'test'
        history.put url, facet, timestamp, data, ->
            history.buffer.length.should.eql 1
            row = history.buffer[0]
            row.should.have.property 'url', url
            row.should.have.property 'timestamp', timestamp
            row.should.have.property facet
            row[facet].should.eql data
            done()


test = (db) -> ->
    if not db
        console.log 'WARNING: no DynamoDB credentials found, skipping tests'
        return

    beforeEach (done) ->
        dbtype = db.constructor.name.toLowerCase()
        connect = db.connect.bind db
        setup = [settings.clear[dbtype], connect]
        async.parallel setup, done

    url = 'http://example.org'
    facet = 'facebook'
    timestamp = 0
    data = 'test'

    it 'can add a data point', (done) ->
        db.put url, facet, timestamp, data, (err) ->
            should.not.exist err
            db.query {url}, (err, results) ->
                should.not.exist err
                result = results[0]
                result.url.should.eql url
                result.timestamp.should.eql timestamp
                result.should.have.property facet
                result[facet].should.eql data
                done()
            

    it 'can get all data points that match a query'
    (done) ->

    # put: (url, facet, timestamp, data, callback) ->
    # get: (id, callback) ->
    # queryFacetsFor: (filter, callback) ->
    # getFacetsFor: (id, callback) ->

describe 'MongoDB history backend', test settings.history.MongoDB
describe 'DynamoDB history backend', test settings.history.DynamoDB