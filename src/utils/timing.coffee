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

milliseconds = ms  = exports.milliseconds = exports.ms  = (n) -> n / 1000
seconds      = sec = exports.seconds      = exports.sec = (n) -> n
minutes      = min = exports.minutes      = exports.min = (n) -> n * MINUTE
hours        = hrs = exports.hours        = exports.hrs = (n) -> n * HOUR
days         = d   = exports.days         = exports.d   = (n) -> n * DAY
weeks        = wks = exports.weeks        = exports.wks = (n) -> n * WEEK
years        = yrs = exports.years        = exports.yrs = (n) -> n * YEAR

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
    constructor: (tick=TICK, @window=WINDOW, @decay=DECAY) ->
        if not @window
            @window = [0, Infinity]
        if typeof @window is 'number'
            @window = [0, @window]

        if typeof tick is 'number'
            @tick = [tick, Infinity]
        else
            @tick = tick

        # give every function under the `reaches` 
        # namespace the proper `this` object
        namespace 'reaches', this

    # `bounded` makes sure that ranges etc. respect
    # the schedule's window
    bounded: (delta, output) ->
        if @window[0] <= delta <= @window[1]
            if output
                output
            else
                delta
        else
            NaN

    # return the nearest delta within the schedule's window
    limit: (delta) ->
        if delta < @window[0]
            @window[0]
        else if delta > @window[1]
            @window[1]
        else
            delta

    # clip an interval to it equals at most 
    # the specified maximum tick interval
    clip: (interval) ->
        Math.min @tick[1], interval

    # an interval is the amount of seconds per tick at a certain delta
    interval: (delta) ->
        if @decay
            decay = Math.pow (delta/DAY)+1, @decay
        else
            decay = 1

        time = (Math.round @tick[0] * decay)
        
        @bounded delta, @clip time

    # a frequency is the amount of ticks per second at a certain delta
    frequency: (delta) ->
        @bounded delta, (1 / @interval delta)

    # note: if you want a range not starting from 0 to be a true range
    # you should use
    # 
    #     fromDelta = ...
    #     toDelta = ...
    #     fromDelta = @closest fromDelta
    #     schedule.range fromDelta, toDelta
    # 
    # Otherwise your subset may not align with the full range.
    range: (deltas...) ->
        if not deltas.length
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
        fromDelta = @limit fromDelta
        toDelta = @limit toDelta

        ticks = [fromDelta]
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

    next: (delta, options={}) ->
        options = _.defaults options, {align: no}

        # we can align the next tick to the regular schedule
        # or we can simply calculate what interval to add 
        # to whatever delta we start from
        if delta < 0
            @window[0]
        else
            if options.align then delta = (@closest delta)
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


# a calendar is a schedule with a start date
# it deals with absolute dates, not deltas
class exports.Calendar
    constructor: (@schedule, @start=0) ->

    next: (time, options) ->
        time ?= exports.now()
        delta = time - @start
        (@schedule.next delta, options) + @start

    range: (times...) ->
        deltas = times.map (time) => time - @start
        (@schedule.range deltas...).map (delta) => delta + @start


exports.Calendar.create = (options) ->
    {tick, window, decay, start} = options
    start ?= exports.now()
    schedule = new exports.Schedule tick, window, decay
    new exports.Calendar schedule, start