import os

from boto.utils import get_instance_metadata

local = os.getenv('ENVIRONMENT') == 'local'
if local:
    region = False
else:
    region = os.getenv('AWS_REGION')


def get_instance_id():
    if local:
        return None
    else:
        return get_instance_metadata()['instance-id']
