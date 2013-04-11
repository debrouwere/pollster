should = require 'should'
facets = require '../src/facets'

describe 'Poll for information like social share counts.', ->
    this.timeout 5000

    it 'can poll a Twitter count', (done) ->
        facets.twitter.poll 'http://example.org', (err, count) ->
            count.should.be.a 'number'
            count.should.be.above 50
            done()

    it 'can poll a Delicious count', (done) ->
        facets.delicious.poll 'https://delicious.com', (err, count) ->
            count.should.be.a 'number'
            count.should.be.above 200
            done()

    it 'can poll a LinkedIn count', (done) ->
        facets.linkedin.poll 'http://example.org', (err, count) ->
            count.should.be.a 'number'
            done()

    it 'can poll a Pinterest count', (done) ->
        url = 'http://www.cookinglight.com/food/world-cuisine/mexican-recipes-00412000075301/page28.html'
        facets.pinterest.poll url, (err, count) ->
            count.should.be.a 'number'
            done()

    it 'can poll Facebook counts with the old REST API', (done) ->
        facets['facebook-rest'].poll 'http://example.org', (err, counts) ->
            counts.likes.should.be.a 'number'
            counts.shares.should.be.a 'number'
            counts.comments.should.be.a 'number'
            done()

    it 'can poll Facebook counts with the Graph API', (done) ->
        # TechCrunch used to use the Facebook Comments Box plugin, so 
        # they're a good place to test the comment box counts for
        url = 'http://techcrunch.com/2012/12/27/the-last-imac-question-mark/'
        facets.facebook.poll url, (err, counts) ->
            counts.shares.should.be.a 'number'
            counts['comments-box'].should.be.a 'number'
            done()

    it 'can poll a Google+ count', (done) ->
        # TechCrunch used to use the Facebook Comments Box plugin, so 
        # they're a good place to test the comment box counts for
        url = 'http://example.org'
        facets['google-plus'].poll url, (err, count) ->
            count.should.be.a 'number'
            done()