feedparser = require 'feedparser'
request = require 'request'
async = require 'async'
_ = require 'underscore'
utils = require '../src/utils'
timing = utils.timing

parseFeed = (options, done) ->
    feedparser.parseUrl options, (err, meta, articles) ->
        done err, articles

parseFile = request.get

module.exports = (options) ->
    {input, root, path, output, feed} = options
    input ?= 'http://localhost:3334/facets/'
    parse = if feed then parseFeed else parseFile

    parse {uri: input, json: yes}, (err, meta, articles) ->
        if err then throw err

        urls = utils.traverse.pluck articles, root, path

        register = (url, done) ->
            # TODO: make `tick` (in minutes) and `stop` and `decay` CLI arguments too (in days)
            params = 
                uri: output
                qs:
                    url: url
                body:
                    replace: no
                    cron: '*/5'
                    stop: timing.after timing.days 10
                    decay: timing.days 1
                json: yes     

            request.put params, done

        async.each urls, register, (err, res, body) ->
            if err
                console.log err
            else
                console.log "Submitted #{urls.length} URLs for tracking."
