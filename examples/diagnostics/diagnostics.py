import collections
import json
import pandas as pd
import subprocess

for collection in ['history', 'watchlist', 'queue']
    subprocess.call("mongoexport -d pollster -c {} -o {}.json".format(collection))

def flatten(d, parent_key='', connector='-'):
    items = []
    for k, v in d.items():
        new_key = parent_key + connector + k if parent_key else k
        if isinstance(v, collections.MutableMapping):
            items.extend(flatten(v, new_key, connector).items())
        else:
            items.append((new_key, v))
    return dict(items)

def load(filename):
    rows = map(json.loads, open(filename).read().split('\n')[0:-1])

    # this really only applies to history.json
    for row in rows:
        if 'undefined' in row:
            row['data'] = row['undefined']
            del row['undefined']

            if 'guardianapis.com' in row.get('url', ''):
                row['data'] = json.dumps(row['data'])

    flat_list = [flatten(row) for row in rows]

    return pd.DataFrame(flat_list)

history = load('history.json')
queue = load('queue.json')
watchlist = load('watchlist.json')

if __name__ == '__main__':
    # did we fetch stuff as often (but not more often) than we should?
    history['url'].value_counts().value_counts().plot()

    # let's check a raw data excerpt
    history.dropna(subset=['data-shares']).groupby('url').head(1).to_csv('excerpt.csv')

    # did we fetch stuff at the right intervals?
    rows = history[history['url'] == url].dropna(subset=['data-shares']).sort('timestamp')
    rows['delta'] = rows['timestamp'] - 1368616192
    deltas = list(rows['delta'])
    for ix, delta in enumerate(deltas):
        print deltas[ix] - deltas[max(ix-1, 0)]

    # map everything we fetched over time, relative to delta
    grouped_timestamps = history.groupby('url')['timestamp'].min()
    grouped_timestamps.name = 'base'
    hist = history.join(grouped_timestamps, on='url', how='outer')
    hist['delta'] = hist.apply(lambda row: row['timestamp'] - row['base'], axis=1)
    hist = hist.sort('delta')
    for url, h in hist.dropna(subset=['data-shares']).groupby('url'):
        plt.plot(h['delta'], h['data-shares'])