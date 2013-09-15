exports.traverse = require './traverse'
exports.serialize = require './serialize'
exports.timing = timing = require './timing'
exports.retry = (require './retry').retry
exports.CouldNotFetch = (require './retry').CouldNotFetch

_ = require 'underscore'

exports.get = (v) ->
    if v instanceof Function
        v()
    else
        v

# Some APIs return exclusively JSONP.
# We strip out the padding and then treat it like regular JSON.
exports.jsonp =
    parse: (str) ->
        if str.match /^[_a-zA-Z]/
            start = (str.indexOf '(') + 1
            stop = (str.lastIndexOf ')') - 1
            str = str[start..stop]

        JSON.parse str


exports.split = (str, sep, times) ->
    chunks = str.split sep
    main = chunks.slice 0, times
    rest = (chunks.slice times)
    if rest.length then rest = rest.join sep
    main.concat rest


exports.last = (arr) ->
    arr[arr.length-1]


exports.affix = (prefix, base, suffix, connector='-') ->
    if prefix
        prefix = prefix + connector
    else
        prefix = ''

    if suffix
        suffix = connector + suffix
    else
        suffix = ''

    prefix + base + suffix


# with a function signature `(one, options..., two, three, etc)`
# extract options from the resulting array; also apply defaults
# if applicable
exports.optional = (options, defaults={}) ->
    options = if options.length then options[0] else {}
    _.defaults options, defaults


exports.noop = ->


# rate limit a function (like an async version of _.debounce)
exports.debounce = (fn, milliseconds) ->
    niceFn = ->
        fnArguments = arguments
        delay = Math.max 0, milliseconds - (timing.delta niceFn.lastCalled)
        niceFn.lastCalled = timing.now() + delay
        setTimeout (-> fn fnArguments...), delay

    niceFn.lastCalled = timing.now()

    niceFn