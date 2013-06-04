fs = require 'fs'
fs.path = require 'path'
express = require 'express'
_ = require 'underscore'
controllers = require './controllers'
middleware = controllers.middleware
facets = require './facets'
poller = require './poller'
utils = require './utils'


# The core of Pollster is an expressjs application.
# We're defining the REST API here, but keeping other
# parts of Pollster in a subclass below: `exports.Pollster`
class Server
    route: (endpoint, controller) ->
        for method, action of controller
            @app[method] endpoint, action

    view: (endpoint, controller) ->
        @app.get '/views' + endpoint, controller

    constructor: (persistence) ->
        # the queue and the watchlist need to be aware of each other
        persistence.queue.watchlist = persistence.watchlist
        persistence.watchlist.queue = persistence.queue
        @persistence = persistence

        @app = express()
        @poller = new poller.Poller @persistence

        @app.enable 'strict routing'

        @route '/facets*', middleware.normalize
        @route '/health/', controllers.health.health
        @route '/queue/', controllers.health.queue
        @route '/facets/', controllers.facets.list
        @route '/facets/:facet/', controllers.facets.detail
        @route '/feeds/', controllers.feeds

    listen: (port = 3000) ->
        @app.listen port
        console.log "Pollster listening on port #{port}."

    start: (component..., port=3000, callback=utils.noop) ->
        component = if component.length then component else null
        all = not component

        if all or component is 'server'
            @listen port
        if all or component is 'poller'
            @poller.start callback

class exports.Pollster extends Server
    _use: (facetName, instance) ->
        @app.facets[facetName] = instance
        @configuration.facets = _.uniq @configuration.facets.concat facetName 

    use: (facet, src) ->
        if src
            instance = _.extend {name: facet}, new (require src)()
            @_use facet, instance
        else
            if facet of @availableFacets
                @_use facet, @availableFacets[facet]
            else
                throw new Error "Can't find #{facet}"

    configure: (key, value) ->
        @configuration[key] = value

    track: (url, parameters, callback) ->
        # parameters determine exactly how to track things, 
        # options enable or disable certain special features
        # we can do with the results from our tracking
        parameters = _.defaults parameters, @parameters
        @poller.track url, parameters, callback

    listen: (port) ->
        super port
        facets = (_.keys @app.facets).join(', ')
        console.log "Tracking #{facets}."

    constructor: (persistence, configuration={}) ->
        super persistence

        @app.pollster = this
        @availableFacets = _.clone facets
        @app.facets = {}

        @configuration = _.defaults configuration, 
            facets: []
            window: [0, (utils.timing.years 1)]
            tick: [(utils.timing.minutes 5), (utils.timing.weeks 1)]
            decay: 1.7
            options:
                replace: yes

        persistence.watchlist.defaults = @configuration