pollster = require '../src'

queue = pollster.backends.queue.MongoDB()
#history = pollster.backends.history.MongoDB()

app = new pollster.Pollster()
app.use 'twitter'
app.use 'facebook'

app.start 'server', 3000
#pollster.start 'poller'