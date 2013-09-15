_ = require 'underscore'
utils = require '../utils'
async = require 'async'
dynode = require 'dynode'

# TODO: may want to find a way to dedupe data/model code (it's also in poller.coffee)
credentials = 
    accessKeyId: process.env.AWS_ACCESS_KEY_ID
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    region: process.env.AWS_REGION

namespace = 'pollster'

dynamo = new dynode.Client credentials

urlToQuery = (url) ->
    query = (done) ->
        inflate = (item) -> utils.serialize.inflate item, '/'
        pluck = (err, {Items}) -> done err, Items.map inflate
        dynamo.query namespace, url, pluck
    [url, query]

exports.list =
    # TODO: support for ranges and deltas (from which we compute a [then, now] range)
    get: (req, res) ->
        queries = _.object req.options.urls.map urlToQuery

        async.parallel queries, (err, items) ->
            res.send items

    # PONY: make put work exactly like GET (= immediately return a result), 
    # but it also adds the URL to our tracker
    put: (req, res) ->
        track = (url, done) ->
            req.app.pollster.track url, req.body, done

        async.each req.options.urls, track, (err) ->
            if err
                res.send 500
            else
                res.send 201



exports.detail =
    get: exports.list.get
    
    put: exports.list.put

    # PONY
    # when adding in facet data from an external source instead of our polling mechanism
    # post: (req, res) ->