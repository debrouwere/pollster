pollster = require '../src'

location =
    ip: '127.0.0.1'
    port: 27017
    username: undefined
    password: undefined

backends =
    watchlist: pollster.persistence.backends.watchlist.MongoDB location
    queue: pollster.persistence.backends.queue.MongoDB location
    history: pollster.backends.history.Console()

app = new pollster.Pollster backends
app.use 'twitter'
app.use 'facebook'

app.start 'server', 3000
#pollster.start 'poller'