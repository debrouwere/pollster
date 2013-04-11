async = require 'async'
utils = require '../utils'
{Facet} = require './facet'
exports.CouldNotFetch = utils.CouldNotFetch
exports.Facet = Facet
exports.persistence = require './persistence'

exports.poll = poll = 
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
                tasks[url] = (done) -> poll.facets url, facets, done
        # we can poll for many different things at once, but 
        # we shouldn't hammer any single API
        async.series tasks, callback