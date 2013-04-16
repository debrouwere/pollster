fs = require 'fs'
fs.path = require 'path'
express = require 'express'
_ = require 'underscore'
controllers = require './controllers'
middleware = controllers.middleware
facets = require './facets'
poller = require './poller'


# The core of Pollster is an expressjs application.
# We're defining the REST API here, but keeping other
# parts of Pollster in a subclass below: `exports.Pollster`
class Server
    route: (endpoint, controller) ->
        for method, action of controller
            @app[method] endpoint, action

    view: (endpoint, controller) ->
        @app.get '/views' + endpoint, controller

    constructor: ->
        @app = express()
        @poller = new poller.Poller()

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

    start: (component='server', port=3000) ->
        if component is 'poller'
            @poller.start()
        else
            @listen port


class exports.Pollster extends Server
    use: (facet, src) ->
        if src
            @app.facets[facet] = new (require src)()
        else
            if facet of @availableFacets
                @app.facets[facet] = @availableFacets[facet]
            else
                throw new Error "Can't find #{facet}"

    track: (url, options, callback) ->
        @poller.track url, options, callback

    listen: (port) ->
        super port
        facets = (_.keys @app.facets).join(', ')
        console.log "Tracking #{facets}."

    constructor: (app) ->
        super app

        @app.pollster = this
        @availableFacets = _.clone facets
        @app.facets = {}