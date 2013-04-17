exports.timing = require './timing'
exports.interpolate = require './interpolate'
exports.track = require './track'
exports.serialize = require './serialize'
exports.retry = (require './retry').retry
exports.CouldNotFetch = (require './retry').CouldNotFetch

# Some APIs return exclusively JSONP.
# We strip out the padding and then treat it like regular JSON.
exports.jsonp =
    parse: (str) ->
        if str.match /^[a-zA-Z]/
            start = (str.indexOf '(') + 1
            stop = (str.lastIndexOf ')') - 1
            str = str[start..stop]

        JSON.parse str