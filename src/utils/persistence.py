# unbuffered standard output
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

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


def to_sqs(obj, config):
    connection = sqs.connect_to_region(
        config.region, 
        aws_access_key_id=config.username,
        aws_secret_access_key=config.password, 
        )
    queue = connection.get_queue('social-shares')
    message = sqs.message.RawMessage()
    message.set_body(json.dumps(obj))
    queue.write(message)


def to_dynamodb(data, config):
    connection = dynamodb2.connect_to_region(
        config.region,
        aws_access_key_id=config.username,
        aws_secret_access_key=config.password,
        )
    table = Table('social-shares', connection=connection)

    # occassionally, a careful and frequent poller will try 
    # to put data into DynamoDB at the same time, leading
    # to a timestamp+url key clash
    try:
        table.put_item(data=data)
    except ConditionalCheckFailedException:
        obj = table.get_item(**get_keys(data))
        obj._data.update(data)
        obj.save()

def to_console(url, keys):
    platforms = ', '.join(keys)
    print('Fetched {} counts for {}'.format(platforms, url))

def to_cloudwatch(keys, container, config):
    connection = cloudwatch.connect_to_region(
        config.region, 
        aws_access_key_id=config.username, 
        aws_secret_access_key=config.password, 
        )
    for key in keys:
        connection.put_metric_data('social-shares', 'polls', value=1, unit='Count', dimensions={
            'container': container, 
            'platform': key, 
            })
