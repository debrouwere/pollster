# Pollster

Pollster tracks the social lifecycle of your content. How? By collecting metadata about URLs at regular intervals. Find out how content is being shared on Twitter, Facebook and a range of other social media, see when it goes viral and easily see today's, yesterday's or any day's top social content.

You can also hook up Pollster to Adobe Omniture or Google Analytics to track who is linking to your content. Or have Pollster download your homepage every five minutes to see how it changes over time. Or grab tweets about your content from the Twitter Search API. If it can be polled, you can have it. 

Pollster is the `cron` of web analytics. It comes with batteries included, but it's also very easy to write your own trackers and integrate with your existing analytics tools.

Pollster does not have a web interface but is accessible through a REST API, so you can build your own dashboards that display whatever information is relevant for you and your organization.

## Features

* Built in trackers for many different facets: Delicious, Digg, Facebook, Google Plus, LinkedIn, Pinterest, Reddit, StumbleUpon and Twitter.
* Per-tick data as well as aggregates.
* Feed tracking: automatically start tracking new content as you publish it.
* Tracking windows: track until *x* days after publication.
* Exponential reduction of granularity: update often soon after publication, update every once in a while as time goes by.
* Health statistics: at-a-glance view into how much content is being tracked, the amount of polling requests per second, database size et cetera.
* REST API.
* Split the polling workload across multiple machines with `node server.js --workload 1/3` (Uses a simple `hash(o) mod n` algorithm.)
* Add your own facets and controllers in about 50 lines of JavaScript.

## And I would want to use this because...

For most people, it's just really nice to be able to have the share counts – both totals and over time – for every piece of content you published today, yesterday, last week, whenever. Tracking shares over time also makes it easy to normalize these counts (e.g. get the counts one day after publication) and not give an unfair advantage to older content.

You'll enjoy Pollster if you're unhappy with the aggregate numbers you're getting out of your current analytics software or any kind of counter.

Traditional analytics software report mostly aggregate numbers. Social media counters only give you the latest tweet and like counts for a web page, not when those tweets and likes were made. Processing tweets with the firehose as they come in is an order of magnitude cheaper than buying historical twitter data. And some things have no history at all: whenever you make a change to a web page, what that page looked like five minutes ago is lost forever.

To keep track of how well your content is doing online, when an aggregator picked up a piece, when something is trending and when it disappears off the radar, you need a tool that can track social share counts and various other metrics over time. Not yet other piece of analytics software, but a tool to regularly poll Twitter, Facebook, Google Analytics, Omniture and any other content metadata for which you want a historical record. Pollster is that tool.

## Getting started

Pollster comes with a basic setup that'll get your server up and running without any programming. Just make sure you have `node.js` installed. In development mode, Pollster will write to a [MongoDB]() database so you'll need that, but it's built to use Amazon DynamoDB in production.

This basic setup gets you up and running in record time, but remember that Pollster is really more a framework than an app: explore `server.coffee` (or `server.js`) to see how it works and read `Extending Pollster` to figure out how to add new facets and views.

    site='guardian'
    mkdir -p pollster-$site/{data,log,server}
    cd pollster-$site/server
    npm install pollster
    cp -r node_modules/pollster/examples/basic/* .

Take a look at what the basic example does, it's `server.coffee` (or `server.js` if you prefer). As you will see, the basic example loads these four facets: 

* Facebook
* Twitter
* Google+
* LinkedIn

Now run the server with: 

    port=3000
    node server.coffee -p $port

We'll want to add some content to track. To add an individual piece of content: 

    # basic
    curl --TODO
    # you can also override some or all of the default tracking options 
    # (window, lower granularity over time)
    curl --TODO

In some cases it might be easier to just have Pollster follow a feed that contains all of your new content, and track each new piece in that feed.

    # start following a feed, and track any piece of content in that feed
    curl --TODO

Add some content, and let your server track if for fifteen minutes or so. That'll give us some information we can query.

    # basic aggregate query
    curl --TODO
    # individual data points for a facet for one particular URL
    curl --TODO
    # date range
    curl --TODO
    # all facets
    curl --TODO

Lastly, if you want, you can also finetune the tracking window for each facet or globally.

    ... COFFEESCRIPT TODO ...

You'll find full documentation for the REST API farther down in this README.

## Performance and database size

TODO: explaining windows and lowering granularity over time

TODO: getting an idea of what you're getting yourself into with /health/ and /queue/

    # curl /health/ --TODO

TODO: explain splitting up the workload

## Extending Pollster

Just like regular `cron`, Pollster is built so you can put pretty much anything on a schedule.

### Creating new facets

### Creating new views to your data

Pollster is built on the [express.js](http://expressjs.com) framework. Creating new views to your data essentially comes down to creating a new express.js controller.

## API

TODO: explain all endpoints

# ?url, ?daterange and ?detail parameters (individual data points or just the aggregates)
GET /
# PUT works like GET, but also starts tracking the article
PUT /
GET /:facet/ (same as GET / but limited to a single facet)
# when adding in facet data from an external source instead of via our polling mechanism
POST /:facet/
# auto-track content in a feed
GET, PUT, DELETE /feeds/
# calculate the amount of API requests we'll be executing per minute for every facet, 
# what errors we've gotten recently, and also what's currently in the queue
GET /health/
GET /queue/