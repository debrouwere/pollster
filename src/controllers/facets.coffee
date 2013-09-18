_ = require 'underscore'
utils = require '../utils'
async = require 'async'
dynode = require 'dynode'
redis = require 'redis'

cache = redis.createClient() 

# TODO: may want to find a way to dedupe data/model code (it's also in poller.coffee)
credentials = 
    accessKeyId: process.env.AWS_ACCESS_KEY_ID
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    region: process.env.AWS_REGION

namespace = 'pollster'

dynamo = new dynode.Client credentials

query = (url, callback) ->
    inflate = (item) ->
        item = utils.serialize.inflate item, '/'
        # this is a redundant field
        delete item.url
        item

    pluck = (err, {Items}) ->
        items = Items.map inflate
        items = _.sortBy items, (item) -> item.timestamp
        callback err, items
        # getting all this stuff from the database isn't hugely taxing for DynamoDB, 
        # but if this data is going to be used in dashboards with many eyes on them, 
        # might as well cache it a bit
        cache.set url, JSON.stringify items
        cache.expire url, 150

    cache.get url, (err, value) ->
        if value isnt null
            callback err, JSON.parse value
        else
            dynamo.query namespace, url, pluck

urlToQuery = (url) ->
    [url, (async.apply query, url)]

exports.list =
    # TODO: support for ranges and deltas (from which we compute a [then, now] range)
    # where we get *all* URLs that match the range, rather than *all* the history
    # for the URLs that were asked. (How to cache this, though? Simply not at all?)
    # TODO: perhaps by default only return *latest* info, not the entire history?
    # (-- otoh we need at least a partial history to compute velocity)
    get: (req, res) ->
        queries = _.object req.options.urls.map urlToQuery

        async.parallel queries, (err, items) ->
            if req.options.single
                res.send (_.values items)[0]
            else
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


round = (n, decimals) ->
    0.01 * Math.round n * 100


exports.velocity =
    get: (req, res) ->
        # this is wasteful, we don't need to fetch everything, 
        # but it'll do for prototyping
        queries = _.object req.options.urls.map urlToQuery
        async.parallel queries, (err, items) ->
            velocities = {}
            interval = 14 * 60 * 1000

            for url, history of items
                history = _.clone history
                now = _.last history
                earlier = _.find history.reverse(), (data) ->
                    (now.timestamp - data.timestamp) > interval
                if not earlier then continue

                duration = (now.timestamp - earlier.timestamp) / (60 * 1000)
                # what we're interested in for velocity 
                # is relative difference between 
                # now and earlier (we need a number that's independent 
                # of current popularity, but instead documents rise/acceleration)
                delta = now.twitter / earlier.twitter
                velocities[url] =
                    shares: [
                        [earlier.timestamp, earlier.twitter]
                        [now.timestamp, now.twitter]
                    ]
                    velocity: (round delta / duration) or 0

            if req.options.single
                # perhaps a 404 is more appropriate if there's nothing 
                # we found?
                res.send (_.values velocities)[0] or {}
            else
                res.send velocities


exports.latest =
    get: (req, res) ->
        recent = new Date() - 60 * 60 * 1000

        params = 
            TableName: namespace
            IndexName: 'timestamp'
            KeyConditions:
                timestamp:
                    AttributeValueList: [{N: recent}]
                    ComparisonOperator: 'GE'

        dynamo._request 'Query', params, (err, data) ->
            console.log err
            console.log data
            res.send 200



exports.detail =
    get: exports.list.get
    
    put: exports.list.put

    # PONY
    # when adding in facet data from an external source instead of our polling mechanism
    # post: (req, res) ->