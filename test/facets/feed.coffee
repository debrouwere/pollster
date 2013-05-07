should = require 'should'
{track, timing} = utils


describe 'Feed-driven watchlists.', ->
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