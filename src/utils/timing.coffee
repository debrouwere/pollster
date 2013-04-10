_ = require 'underscore'

MINUTE = 60
HOUR = MINUTE * 60
DAY = HOUR * 24
WEEK = DAY * 7
MONTH = WEEK * 4.345
YEAR = WEEK * 52

# the scheduling defaults
TICK = exports.TICK = 5 * MINUTE
DECAY = exports.DECAY = 1.7
WINDOW = [0, YEAR]

minutes = exports.minutes = (n) -> n * MINUTE
hours = exports.hours = (n) -> n * HOUR
days = exports.days = (n) -> n * DAY
weeks = exports.weeks = (n) -> n * WEEK
years = exports.years = (n) -> n * YEAR


# the time that has passed since `start`, in seconds
exports.delta = (start) ->
    stop = new Date()
    Math.round (stop - start) / 1000

exports.now = ->
    Math.round new Date().getTime() / 1000

RESOLUTION = 1000

# ([(day-1)/7, Math.round((RESOLUTION * TICK * (Math.pow day, BACK_OFF)) / DAY) / RESOLUTION] for day in [1..365] by 7)

# range = timing.ticks.range(0, timing.days 1)
# intervals = range.map (t, i) -> range[i] - range[Math.max i-1, 1]
# minutes = intervals.map (itv) -> itv / 60
# (every 16 minutes by the end of the first day)

namespace = (name, dest) ->
    obj = dest[name]
    for key, fn of obj
        obj[key] = _.bind fn, dest

class exports.Schedule
    constructor: (@tick=TICK, @window=WINDOW, @decay=DECAY) ->
        if not @window
            @window = [0, Infinity]
        if typeof @window is 'number'
            @window = [0, @window]

        # give every function under the `reaches` 
        # namespace the proper `this` object
        namespace 'reaches', this

    bounded: (delta, output) ->
        if @window[0] <= delta <= @window[1]
            if output
                output
            else
                delta
        else
            NaN

    clip: (delta) ->
        if delta < @window[0]
            @window[0]
        else if delta > @window[1]
            @window[1]
        else
            delta

    # an interval is the amount of seconds per tick at a certain delta
    interval: (delta) ->
        if @decay
            decay = Math.pow (delta/DAY)+1, @decay
        else
            decay = 1

        @bounded delta, (Math.round @tick * decay)

    # a frequency is the amount of ticks per second at a certain delta
    frequency: (delta) ->
        @bounded delta, (1 / @interval delta)

    range: (deltas...) ->
        if not deltas
            stops = @window[1] isnt Infinity
            decays = @decay
            finite = stops or decay

            if finite
                [fromDelta, toDelta] = @window
            else
                throw new Error "Cannot compute an infinite range."

        else if deltas.length is 1
            fromDelta = 0
            toDelta = deltas[0]
        else
            [fromDelta, toDelta] = deltas

        # limit fromDelta and toDelta to the window
        fromDelta = @clip fromDelta
        toDelta = @clip toDelta

        firstTick = @tick * Math.ceil fromDelta/@tick
        ticks = [firstTick]
        delta = fromDelta

        loop
            delta = @next delta
            break unless delta <= toDelta
            ticks.push delta

        ticks

    count: (deltas...) ->
        (@range deltas...).length

    closest: (delta) ->
        # this is inefficient, but shouldn't be a huge deal
        (@range delta).pop()

    next: (delta, align=no) ->
        # we can align the next tick to the regular schedule
        # or we can simply calculate what interval to add 
        # to whatever delta we start from
        if align then delta = (@closest delta)
        delta + @interval delta

    reaches:
        frequency: (hz) ->
            throw new Error "Not implemented yet"

        count: (n) ->
            # start counting from 1, because `delta = 0` 
            # already accounts for the first tick
            i = 1
            delta = 0
            while i < n
                i++
                delta = @next delta
                # if the window closes before we reach the requested amount
                # of observations, it will never reach that count
                if delta is NaN then return NaN

            delta

        end: ->
            if @window[1]
                (@range @window...).pop()
            else
                NaN


exports.interpolate = (ticks, frequency) ->
    throw new Error "Not implemented yet"
        

###
- calculate all ticks (timestamps) for a given time range, 
  or x ticks from a starting point
- all ticks but as a simple count
- time of next tick, given nth tick (or delta) and window and decay
- calculate ticks/second for a given timestamp and piece of content
- calculate seconds/tick for a given timestamp and piece of content
- calculate timestamp the decay will reach a certain ticks/second frequency
###