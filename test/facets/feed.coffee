should = require 'should'
{traverse, timing} = require '../../src/utils'


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
        extractedUrls = traverse.pluck feed, root, path
        extractedUrls.should.eql urls

        root = undefined
        path = undefined
        extractedArticles = traverse.pluck feed.root.articles, root, path
        for article in extractedArticles
            article.article.url.should.be.a 'string'

    it 'should be able to extract URLs from an ATOM feed'

    it 'should be able to extract URLs from an RSS feed'