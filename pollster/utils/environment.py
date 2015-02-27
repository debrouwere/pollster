import os

from boto.utils import get_instance_metadata
from boto.dynamodb2 import regions as get_regions


local = os.getenv('ENVIRONMENT') == 'local'
development = os.getenv('ENVIRONMENT') == 'development'
if local:
    region = False
else:
    region = os.getenv('AWS_REGION')


def get_dynamodb_region(region=region):
    return next(r for r in get_regions() if r.name == region)

def get_instance_id():
    if local or development:
        return 'localhost'
    else:
        return get_instance_metadata()['instance-id']
