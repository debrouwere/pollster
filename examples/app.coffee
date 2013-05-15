pollster = require '../src'

location =
    ip: '127.0.0.1'
    port: 27017
    username: undefined
    password: undefined

backends =
    watchlist: new pollster.persistence.backends.watchlist.MongoDB location
    queue: new pollster.persistence.backends.queue.MongoDB location
    history: new pollster.persistence.backends.history.MongoDB location

app = new pollster.Pollster backends
app.use 'twitter'
app.use 'facebook'

watchlist = 'http://content.guardianapis.com/search?page-size=50&format=json'
options =
    facets: ['file']
    root: 'results'
    unique: 'webUrl'
    multiple: yes
    watchlist: yes
    parse: yes

app.track watchlist, options
app.start 3000
#pollster.start 'poller'