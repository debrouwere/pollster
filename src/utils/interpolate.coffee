last = (list) ->
    list[list.length-1]

# interpolate between two points
exports.interpolate = interpolate = (start, stop, x) ->
    [x0, y0] = start
    [x1, y1] = stop
    y0 + (y1 - y0) * ((x-x0)/(x1-x0))

# Pollster usually polls for data less frequently as time goes on, 
# but analysis of timeseries is considerably easier when you can
# assume a fixed time interval between each data point.
# This function takes an irregular timeseries and aligns it to 
# a grid, using real values where possible and interpolating 
# where necessary.
exports.align = (timeseries, interval) ->
    timestamps = timeseries.map (tuple) -> tuple[0]
    values = timeseries.map (tuple) -> tuple[1]

    start = Math.min timestamps...
    stop = Math.max timestamps...
    bound = timeseries.length - 1
    n = Math.ceil (stop - start) / interval
    
    grid = [0..n].map (i) -> i * interval

    pos = 0
    for tick, ix in grid
        while pos < bound and tick > timeseries[pos][0]
            pos++

        if timeseries[pos][0] is tick
            value = timeseries[pos][1]
        else
            # keep things inside of our timeseries array bounds
            prev = Math.max 0, pos - 1
            curr = Math.min pos, bound
            value = interpolate timeseries[prev], timeseries[curr], tick
        
        grid[ix] = [tick, value]

    grid