_ = require 'underscore'
utils = require '../utils'


class exports.Facet
    # Most facets shouldn't need to touch `Facet#pluck`,  
    # but facets that store data outside of the MongoDB 
    # should override this.
    # (For example, screenshots in a file directory.)
    #
    #     data.engines.blob.read(...)
    # 
    # Actually fetching the data happens elsewhere.
    # (Because facets are stored as columns in DynamoDB
    # and as embedded documents in MongoDB it doesn't
    # make sense to fetch an individual facet.)
    pluck: (data, callback) ->
        # TODO: allow proxied content to be cached in Redis
        if @isProxy
            @fetch data.url, callback
        else
            facet = @name.toLowerCase()
            callback null, data[facet]

    # similar to `pluck`, but only the latest value
    pluckLatest: (data, callback) ->

    # `@options` is a good place to put API keys and such
    constructor: (@options) ->
        # external APIs can be a bit flaky, so we don't 
        # give up right away
        poll = _.bind @poll, this
        @poll = utils.retry poll, 5

    # fetch fn
    poll: (url, callback) ->
        # should also be able to return `null` if nothing
        # should be stored
        # (for most facets, data that stays the same
        # should still be captured, for others, e.g. 
        # a page archive, it should not)
        callback null, {a: 'data-structure'}

    # aggregate (fn that aggregates the data from each individual tick)
    # (we will call this a couple of times with different data: once  
    # for daily totals, once for weekly totals, once for a grand total)
    aggregate: null

    update: (url) ->
        self = this
        # fetch new data
        @fetch url, (errors, data) ->
            # get old data
            db.find {url, facet}, (errors, points) ->
                days = groupByDay points
                weeks = groupByWeek days

                aggregates =
                    days: (self.aggregate(day) for day in days)
                    weeks: (self.aggregate(week) for week in weeks)
                    total: self.aggregate(points)