_ = require 'underscore'
should = require 'should'
{timing} = require '../src/utils'

describe 'Calculate when to poll for information: fixed, cron-like intervals.', ->
    tick = timing.minutes 1
    window = timing.minutes 30
    decay = no
    schedule = new timing.Schedule tick, window, decay

    it 'can calculate the interval between one tick and the next at any point in time', ->
        for i in [0..30]
            (schedule.interval timing.minutes i).should.eql tick

        time = schedule.interval timing.minutes 31
        isNaN(time).should.be.true

    it 'can calculate the tick frequency at any point in time', ->
        for i in [0..30]
            (schedule.frequency timing.minutes i).should.eql 1/tick

        time = schedule.frequency timing.minutes 31
        isNaN(time).should.be.true

    it 'can calculate all ticks within a certain range, starting from zero', ->
        range = (_.range 0, 31).map (delta) -> delta * 60
        (schedule.range window).should.eql range

    it 'can calculate all ticks within a certain range', ->
        start = 5
        stop = 15
        range = (_.range start, stop+1).map (delta) -> delta * 60
        (schedule.range start*60, stop*60).should.eql range

    it 'can calculate all ticks within a certain range, using the window', ->
        range = (_.range 0, 31).map (delta) -> delta * 60
        schedule.range().should.eql range

    it 'can calculated aligned and offset ranges', ->
        start = timing.minutes 1
        stop = timing.minutes 30
        (schedule.range start, stop).should.eql schedule.range()[1..]

        # offset by 30 seconds
        start = (timing.minutes 1) - 30
        stop = (timing.minutes 30) - 30
        offset = schedule.range start, stop
        realigned = schedule.range()[1..].map (tick) -> tick - 30
        offset.should.eql realigned

        # offset by 15 seconds but realigned
        alignedStart = timing.minutes 1
        realignedStart = schedule.closest alignedStart + 15
        stop = timing.minutes 30
        (schedule.range alignedStart, stop).should.eql schedule.range realignedStart, stop

    it 'can count the amount of ticks within a certain time range', ->
        start = timing.minutes 21
        stop = Infinity
        (schedule.count start, Infinity).should.eql 10

    it 'can calculate when the next tick should be, from any delta', ->
        start = timing.minutes 20
        stop = timing.minutes 21
        (schedule.next start).should.eql stop

    it 'can calculate how many ticks fit in a range', ->
        # the first tick is at zero, so we'll have 20 ticks after 19 minutes
        (schedule.count timing.minutes 19).should.eql 20

    it 'can calculate when the schedule reaches n ticks', ->
        (schedule.reaches.count 20).should.eql timing.minutes 19

    it 'can calculate when the schedule reaches a certain frequency'
        # this is a fixed schedule and hence the degenerate case
        #(schedule.reaches.frequency 1/60).should.eql 0

    it 'can calculate what the last tick will be', ->
        schedule.reaches.end().should.eql timing.minutes 30


describe 'Calculate when to poll for information: reduced granularity over time.', ->
    tick = timing.hours 1
    window = timing.days 7
    decay = 2
    schedule = new timing.Schedule tick, window, decay

    it 'can calculate the interval between one tick and the next at any point in time', ->
        (schedule.interval timing.days 0).should.eql tick
        (schedule.interval timing.days 7).should.eql tick * 64

    it 'can calculate the tick frequency at any point in time', ->
        (schedule.frequency timing.days 7).should.eql 1 / (tick * 64)

    it 'can calculate all ticks within a certain range, starting from zero', ->
        range = schedule.range window
        count = range.length
        stop = range.pop()
        start = range.pop()
        interval = stop - start
        interval.should.eql schedule.interval start
        (schedule.count window).should.eql count

    it 'can calculate all ticks within a certain range', ->
        fullRange = schedule.range()
        last = (list) -> list[list.length-1]
        range = schedule.range fullRange[5], last(fullRange)
        range.should.eql fullRange[5..]

    it 'can count the amount of ticks within a certain time range'

    it 'can calculate when the next tick should be, from any delta'

    it 'can calculate how long it will take to collect n data points'

    it 'can align ticks to fixed interval through linear interpolation'
        # timing.interpolate [...]

    it 'can calculate what the last tick will be'
        #schedule.reaches.end().should.eql schedule.range window

    it 'can have a maximum interval', ->
        clippedTick = [(timing.hours 1), (timing.hours 8)]
        clippedSchedule = new timing.Schedule clippedTick, window, decay

        # a schedule with a maximum interval should have more data points 
        # than one where intervals keep growing indefinitely, at least 
        # provided that the maximum interval is ever exceeded
        schedule.range().length.should.be.below clippedSchedule.range().length

        # test whether the maximum interval is respected
        range = clippedSchedule.range()
        range[1].should.eql clippedTick[0]
        clippedInterval = range.pop() - range.pop()
        clippedInterval.should.eql clippedTick[1]


describe 'it can work with calendars: schedules that start at a specific point in time', ->
    it 'can calculate a range of ticks'
    (done) ->
        s = new timing.Schedule()
        c = new timing.Calendar(s)
        c.start = timing.minutes 5
        s.next timing.days 5
        c.next timing.days 5
        s.range()[..5]
        c.range()[..5]

    it 'can calculate the next tick from a starting point'