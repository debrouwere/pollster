_ = require 'underscore'
async = require 'async'
timing = require './timing'

exports.CouldNotFetch = (@message) ->

exports.retry = (fn, times) ->
    (args..., callback) ->
        attempt = 0
        results = null
        err = null
        redirected_fn = (done) -> 
            # exponential back-off
            wait = 500 * Math.pow attempt, 2
            _.delay fn, wait, args..., ->
                attempt++
                [err, results] = arguments
                done()

        shouldRetry = -> 
            hope = attempt < times
            fetchError = err instanceof exports.CouldNotFetch
            return hope and fetchError

        async.doWhilst redirected_fn, shouldRetry, ->
            callback err, results