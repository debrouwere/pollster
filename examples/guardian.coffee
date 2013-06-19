fs = require 'fs'
pollster = require '../src'
utils = require '../src/utils'
db = pollster.persistence.backends

here = (src) -> __dirname + src

local =
    ip: '127.0.0.1'
    port: 27017
    username: undefined
    password: undefined

aws = 
    accessKeyId: process.env.POLLSTER_AWS_ACCESS_KEY_ID
    secretAccessKey: process.env.POLLSTER_AWS_SECRET_ACCESS_KEY
    region: process.env.POLLSTER_AWS_REGION

aws.capacity =
    read: 50
    write: 50

localRedis = 
    instance: process.env.POLLSTER_INSTANCE or '1/1'

config =
    facets: [
        'twitter'
        'facebook'
        'google-plus'
        'linkedin'
        #'pinterest'
        'delicious'
        ]
    tick: [(utils.timing.minutes 5), (utils.timing.weeks 1)]
    window: [0, (utils.timing.years 1)]
    decay: 1.7

backends = {}
backends.local =
    watchlist: new db.watchlist.MongoDB local
    queue: new db.queue.MongoDB local
    history: new db.history.MongoDB local
backends.performance =
    watchlist: new db.watchlist.DynamoDB aws
    queue: new db.queue.Redis localRedis
    history: new db.history.DynamoDB aws

app = new pollster.Pollster backends.performance, config

# tip: a big page size (50) is recommended in production (we sometimes 
# publish in bulk) but for testing, a page size of 20 is ideal.
feed = 'http://content.guardianapis.com/search?page-size=50&format=json'
asWatchList =
    facets: ['file']
    tick: (utils.timing.minutes 1)
    window: [0, Infinity]
    decay: no
    options:
        watchlist: yes
        root: 'response.results'
        path: 'webUrl'
        replace: no
        parse: yes

resetLocal = (callback) ->
    app.poller.connect ->
        backends.local.history.client.dropDatabase callback

app.start 3000, (err) ->
    if err then throw err
    app.track feed, asWatchList