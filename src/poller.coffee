{timing} = require './utils'

###
Queueing service: 

- because polling intervals are dynamic (increase over time, and can be specific to the individual article or facet), we can't put all ticks in a queue ahead of time, and we can't just use a cron-esque regular schedule

* settings table (hash table) *

    url =>
      publication_date
      facets: {facet: {decay, window}}

    (or columnized for Dynamo)
    url => 
        publication_date
        <facet>-decay
        <facet>-window

    (or denormalized for Redis, though I'd have to think
    the performance increase would be minor)
    facet+url => publication_date | decay | window

We should make sure that the settings table is not essential 
for anything other than making queueing work, and is cleaned
up when there's no remaining ticks left for a piece of content.
Otherwise it will keep growing as the data set grows -- 
which is what DynamoDB is for.

(Calculated from global defaults, facet defaults and per-item overrides.)

* queue table (sorted set) *

    score => facet+url

    - when a new URL gets added: 
      add all its facets to the queue as well
      with score 0 (= now)
      ZADD 0 facet+url 0 facet+url 0 facet+url ...

    - every second:
      ZRANGE myzset 0 current_time
    - add to `async.queue` with MAX_CONCURRENT requests
      (this is *per facet/service*, Node itself will
      take care the server doesn't take on more -- globally --
      than it can handle)
    - if facet successfully fetched and saved
      - fetch settings[facet+url], compute next tick
        (meaning "earliest tick in the future" -- 
        if the service was interrupted and we've missed
        ticks, so be it)
      - update item score (next tick)
        ZADD score facet+url [this is a set, so ZADD = update]

(It should be possible to recalculate the queue table from scratch based on the DynamoDB settings data.)

For the Guardian, if you have 135K articles at a time
(about our yearly production, and with a tracking cut off
after a year so it doesn't keep rising) that still 
shouldn't be much more than 100MB in memory (incl. overhead)

* stats table(s) *

    (a) get every row for a daterange, split up by facet
    (b) sorted set in Redis, ZINCR, clear out every hour/day
    (c) count in Node, flush to Redis every minute, 
        push to last-hour and last-day lists, and use 
        ZTRIM to keep them 60 and 1440 elements long respectively
###

poller = ->
    now = timing.now()

    # pseudocode
    trackers.find().toArray (errors, results) ->
        for result in results
            facet = facets[result.facet]
            if now % facet.tick is 0
                db.add results.url, facet.update(result.url)
                
class exports.Poller
    track: (url, options, callback) ->
        console.log "Tracking #{url}"
        if callback? then callback null

    start: ->

#setInterval main, 1000