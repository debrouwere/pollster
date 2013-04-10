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

    it 'can calculate when the schedule reaches a certain frequency', ->
        # this is a fixed schedule and hence the degenerate case
        #(schedule.reaches.frequency 1/60).should.eql 0

    it 'can calculate what the last tick will be', ->
        schedule.reaches.end().should.eql timing.minutes 30


describe 'Calculate when to poll for information: reduced granularity over time.', ->
    tick = timing.minutes 1
    window = timing.minutes 30
    decay = 5
    schedule = new timing.Schedule tick, window, decay

    it 'can calculate the interval between one tick and the next at any point in time'

    it 'can calculate the tick frequency at any point in time'

    it 'can calculate all ticks within a certain range, starting from zero'

    it 'can calculate all ticks within a certain range'

    it 'can count the amount of ticks within a certain time range'

    it 'can calculate when the next tick should be, from any delta'

    it 'can calculate how long it will take to collect n data points'

    it 'can align ticks to fixed interval through linear interpolation'
        # timing.interpolate [...]

    it 'can handle finite windows'
        # finite windows shouldn't get us into endless loops etc.