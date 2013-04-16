should = require 'should'
pollster = require '../src'
{track} = require '../src/utils'

describe 'Feed-driven watchlists.', ->
    # this.timeout 5000

    it 'should be able to extract URLs from a JSON feed', ->
        urls = [
            'http://example.org'
            'http://example.com'
        ]

        feed =
            root: 
                articles: [
                    {article: {url: urls[0]}} 
                    {article: {url: urls[1]}}
                ]
        
        root = 'root.articles'
        path = 'article.url'
        extractedUrls = track.pluck feed, root, path
        extractedUrls.should.eql urls

    it 'should be able to extract URLs from an ATOM feed'

    it 'should be able to extract URLs from an RSS feed'


describe 'Add, update and remove pages from the polling queue.', ->
    pollster = new pollster.Pollster()
    pollster.use 'facebook'
    pollster.use 'twitter'
    app = pollster.app

    it 'can add a URL to the queue programatically', (done) ->
        options = 
            facets: ['facebook']
            window: [0, 30]
            tick: 10
            decay: no

        pollster.track 'http://example.org', options, (err) ->
            # TODO: check whether it's actually in the queue
            done err       

    it 'can add a URL to the queue through the REST interface'
    (done) ->
        request(app)
            .put('/facets/twitter/?url=http://example.org')
            .expect(200)
            .end (err, res) ->
                if err then done err
                ix = 'twitter+http://example.org'
                (ix in pollster.watchlist).should.be.true

    it 'can add a URL to the queue by detecting new items in a feed'
    (done) ->

    it 'will start polling for any URL in the queue at the appropriate times'
    (done) ->
        this.timeout 60 * 1000

    it 'will remove a URL from the queue once the window has passed'
    (done) ->

    it 'will write the data gathered by polling to a history table'
    (done) ->