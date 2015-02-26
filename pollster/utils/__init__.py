import json
from urllib.parse import urlparse

import requests

from . import environment
from . import fleet
from . import persistence


def split(string, delimiter=',', eol='\n'):
    return [line.split(delimiter) for line in string.split(eol)]


def flatten(obj, skip=[], connector='_', parent_key=''):
    items = []

    for sub_key, v in obj.items():
        if parent_key:
            key = parent_key + connector + sub_key
        else:
            key = sub_key

        if isinstance(v, dict) and not (key in skip):
            items.extend(flatten(v, skip, connector, key).items())
        elif isinstance(v, list):
            items.append((key, v))
        else:
            items.append((key, v))

    return dict(items)


def traverse(obj, segments):
    if isinstance(segments, str):
        segments = list(filter(None, segments.split('.')))

    if len(segments):
        if isinstance(obj, list):
            return [traverse(item, segments) for item in obj]
        else:
            head = segments[0]
            tail = segments[1:]
            obj = obj[head]
            return traverse(obj, tail)
    else:
        return obj


def request(uri, json=False):
    segments = urlparse(uri)
    if scheme in ('http', 'https'):
        text = requests.get(uri).text
    elif scheme == 's3':
        path = segments.path.lstrip('/')
        text = persistence.from_file(path, segments.hostname)
    else:
        raise ValueError()

    if json:
        text = json.loads(text)

    return text
