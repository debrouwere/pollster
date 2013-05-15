pollster = require '../src'
utils = require '../src/utils'

here = (src) -> __dirname + src

location =
    ip: '127.0.0.1'
    port: 27017
    username: undefined
    password: undefined

config =
    facets: ['twitter', 'facebook']
    tick: (utils.timing.minutes 5)
    window: [0, (utils.timing.years 1)]
    decay: 1.7

backends =
    watchlist: new pollster.persistence.backends.watchlist.MongoDB location, config
    queue: new pollster.persistence.backends.queue.MongoDB location
    history: new pollster.persistence.backends.history.MongoDB location

console.log backends.watchlist.defaults

app = new pollster.Pollster backends
app.use 'twitter'
app.use 'facebook'
#app.use 'guardian-fields', here '/guardian/content-api.coffee'

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

app.start 3000, (err) ->
    if err then throw err
    #backends.history.client.dropDatabase ->
    app.track feed, asWatchList