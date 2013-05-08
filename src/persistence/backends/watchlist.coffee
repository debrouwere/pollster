_ = require 'underscore'
async = require 'async'
engines = require '../engines'
utils = require '../../utils'
{Facet} = require '../facet'


###
    url =>
      publication_date
      facets: {facet: {decay, window}}

    (or columnized for Dynamo)
    url => 
        publication_date
        <facet>-decay
        <facet>-window

    (or denormalized for Redis, though I'd have to think
    the performance increase would be minor)
    facet+url => publication_date | decay | window

We should make sure that the settings table is not essential 
for anything other than making queueing work, and is cleaned
up when there's no remaining ticks left for a piece of content.
Otherwise it will keep growing as the data set grows -- 
which is what DynamoDB is for.

(Calculated from global defaults, facet defaults and per-item overrides.)
###


# different calendars can share the same options, but it's
# useful to have them split out per facet too
untangle = (result) ->
    result.facets.map (facet) -> _.extend {facet}, result


class WatchList
    constructor: (@location, @queue) ->


class exports.MongoDB extends WatchList
    connect: (callback) ->
        engines.MongoDB.collection @location, 'watchlist', (err, @collection, @client) =>
            callback err

    create: (callback) ->
        @collection.ensureIndex 'url', callback

    _buildCalendarsFor: (results) ->
        parameters = _.flatten results.map untangle
        calendars = parameters.map (params) -> 
            [params.facet, utils.timing.Calendar.create params]        
        _.object calendars

    getCalendarsFor: (url, callback) ->
        (@collection.find {url}).toArray (err, results) =>
            if err
                callback err
            else
                callback null, @_buildCalendarsFor results

    list: (callback) ->
        @collection.find().toArray (err, results) =>
            calendars = _.groupBy results, 'url'
            for url, parameters of calendars
                calendars[url] = @_buildCalendarsFor parameters
            callback err, calendars

    watch: (url, options, callback) ->
        item = _.extend options, {url}
        calendar = utils.timing.Calendar.create options
        nextTick = calendar.next -1
        enqueue = (facet, done) => @queue.push url, facet, nextTick, done

        @collection.update {url}, item, {safe: yes, upsert: yes}, (err) ->
            async.each item.facets, enqueue, callback

    unwatch: (url, callback) ->
        @collection.remove {url}, callback

class exports.DynamoDB extends WatchList
    connect: (callback) ->
        @client = new AWS.DynamoDB().client

    create: (callback) ->

    getCalendarsFor: (url, facets..., callback) ->

    list: (callback) ->

    watch: (url, options, callback) ->

    unwatch: (url, callback) ->
