should = require 'should'
{interpolate} = require '../src/utils'

describe 'Can align a timeseries with measurements at arbitrary times to a grid.', ->
    series = [
        [0, 10]
        [7, 20]
        [8, 30]
        [11, 40]
        [14, 50]
        [19, 60]
    ]

    fixedSeries = [
        [0, 0]
        [5, 10]
        [10, 20]
        [15, 30]
    ]

    it 'can interpolate between two points', ->
        (interpolate.interpolate [10, 10], [20, 60], 15).should.eql 35

    it 'can align an entire timeseries through linear interpolation', ->
        interpolated = [
            [0, 10]
            [5, 17]
            [10, 37]
            [15, 52]
            [20, 62]
        ]

        # aligning a series that's already aligned doesn't mess it up
        (interpolate.align fixedSeries, 5).should.eql fixedSeries
        # align a series that's not aligned
        (interpolate.align series, 5, 0).should.eql interpolated