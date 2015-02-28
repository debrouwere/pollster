import os
import json

from boto import dynamodb2, sqs, ec2, s3
from boto.sqs.message import Message, RawMessage
from boto.s3.key import Key as S3Key
from boto.dynamodb2 import fields, types
from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2.table import Table
from boto.dynamodb2.exceptions import ConditionalCheckFailedException
from boto.ec2 import cloudwatch


from . import environment


def setup_dynamodb(connection):
    table_name = 'social-shares'
    tables = connection.list_tables()['TableNames']
    if table_name in tables:
        return True

    schema = [
        fields.HashKey('url'),
        fields.RangeKey('timestamp', data_type=types.NUMBER)
    ]
    return Table.create(table_name, schema=schema, connection=connection)


def connect_to_dynamodb(key_id, key, region=None, local=False):
    config = {
        'aws_access_key_id': key_id, 
        'aws_secret_access_key': key,        
    }

    if not (region or local):
        raise ValueError()

    if environment.local:
        host = os.getenv('AWS_DYNAMODB_HOST', 'dynamodb')
        port = int(os.getenv('AWS_DYNAMODB_PORT', 8000))
        config.update({
            'host': host, 
            'port': port, 
            'is_secure': False, 
        })
    else:
        config.update({
            'region': environment.get_dynamodb_region(region)
        })

    connection = DynamoDBConnection(**config)

    if environment.local:
        setup_dynamodb(connection)

    return connection


dynamodb = connect_to_dynamodb(
    key_id=os.getenv('AWS_ACCESS_KEY_ID'), 
    key=os.getenv('AWS_SECRET_ACCESS_KEY'), 
    region=environment.region, 
    local=environment.local,
    )

s3 = s3.connect_to_region(
    os.getenv('AWS_REGION'), 
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), 
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'), 
    )

sqs = sqs.connect_to_region(
    os.getenv('AWS_REGION'), 
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'), 
    )

cloudwatch = cloudwatch.connect_to_region(
    os.getenv('AWS_REGION'), 
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'), 
    )


def to_file(string, path, bucket_name, mime):
    if environment.local:
        print('[file] {}'.format(path))
    else:
        bucket = s3.get_bucket(bucket_name, validate=False)  
        output = S3Key(bucket)
        output.key = path
        output.content_type = mime
        output.set_contents_from_string(string)

def from_file(path, bucket_name):
    bucket = s3.get_bucket(bucket_name, validate=False)  
    output = S3Key(bucket)
    output.key = path
    try:
        return output.get_contents_as_string().decode('utf-8')
    except Exception:
        return None


def to_queue(obj, queue_name):
    if environment.local:
        print('[queue] {}'.format(queue_name))
    else:
        queue = sqs.get_queue(queue_name)
        message = RawMessage()
        message.set_body(json.dumps(obj))
        queue.write(message)


def get_keys(obj):
    return dict(url=obj['url'], timestamp=obj['timestamp'])

def to_db(obj, table_name):
    table = Table(table_name, connection=dynamodb)

    # create or update
    # 
    # occassionally, a careful and frequent poller will try 
    # to put data into DynamoDB at the same time, leading
    # to a timestamp+url key clash
    try:
        table.put_item(data=obj)
    except ConditionalCheckFailedException:
        existing = table.get_item(**get_keys(obj))
        existing._data.update(obj)
        existing.save()

def to_console(string, **local):
    print(string.format(**local))


def to_monitor(event, dimensions={}, n=1, unit='Count'):
    if environment.local:
        print('[monitor] {}'.format(event))
    else:
        cloudwatch.put_metric_data('social-shares', event, 
            value=n, unit=unit, dimensions=dimensions)
