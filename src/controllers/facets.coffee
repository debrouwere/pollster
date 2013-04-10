_ = require 'underscore'
async = require 'async'

# TODO: eventually we'll want to cache this for a little bit 
# (so we'll use this logic when we need to, but a memory cache
# whenever we can)
# 
# It might also be better at home in "data" than near the controllers.

fetch = 
    facets: (url, facets, callback) ->
        tasks = {}
        for name, facet of facets
            # closure wrapper
            do (name, facet) ->
                tasks[name] = (done) -> facet.poll url, done
        
        async.parallel tasks, callback

    urls: (urls, facets, callback) ->
        tasks = {}
        for url in urls
            do (url) ->
                tasks[url] = (done) -> fetch.facets url, facets, done
        # we can poll for many different things at once, but 
        # we shouldn't hammer any single API
        async.series tasks, callback


exports.list =
    get: (req, res) ->
        fetch.urls req.options.urls, req.options.facets, (err, results) ->
            res.jsonp results, req.options.single

    put: (req, res) ->

exports.detail =
    get: (req, res) ->
        # TODO: abstract this out so we can reuse it in 
        # exports.list too
        facet = req.app.facets[req.params.facet]
        facet.fetch req.query.url, (err, results) ->
            res.jsonp results, req.options.single
    
    put: (req, res) ->
