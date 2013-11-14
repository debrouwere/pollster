# Pollster

Pollster tracks the social lifecycle of your content. How? By collecting metadata about URLs at regular intervals. Find out how content is being shared on Twitter, Facebook and a range of other social media. Do it for your own site or for those of your competitors.

Think of Pollster as the `cron` of web analytics.

## Features

* Feed tracking: automatically start tracking new content as you publish it.
* Tracking windows: track until *x* days after publication.
* Reduction of granularity over time: poll often at first, poll every once in a while as time goes by.
* Easily extensible: if it can be polled, you can have it.
* Accessible through a REST API (there is no GUI), so you can build your own dashboards that display whatever information is relevant for you and your organization – or do any kind of analysis.
* Scalable: run it on as many servers as you like, and the load will be shared using a message queue to coordinate.
* Optimized to run on AWS infrastructure: EC2 micro instances, DynamoDB and SQS. (What I really mean is that you probably don't want to try to run it anywhere else.)

## Why?

You'll enjoy Pollster if you're unhappy with the aggregate numbers you're getting out of your current analytics software or the counts and tweets and likes you're getting from Facebook, Twitter or any kind of counter.

Traditional analytics software report mostly aggregate numbers. Social media counters only give you the latest tweet and like counts for a web page, not when those tweets and likes were made. Processing tweets with the firehose as they come in is an order of magnitude cheaper than buying historical twitter data. And some things have no history at all: whenever you make a change to a web page, what that page looked like five minutes ago is lost forever.

To keep track of how well your content is doing online, when an aggregator picked up a piece, when something is trending and when it disappears off the radar, you need a tool that can track social share counts and various other metrics over time. Not yet other piece of analytics software, but a tool to regularly poll Twitter, Facebook (and perhaps even Google Analytics or Omniture) and any other content metadata for which you want a historical record. Pollster is that tool.

## Getting started

Set up a DynamoDB table. With the Amazon CLI, this should work: 

    create-table
        --table-name pollster
        --key-schema AttributeName=url,KeyType=HASH AttributeName=timestamp,KeyType=RANGE
        --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10

Wait until the table's been created before proceeding. It'll avoid race conditions.

Spin up a couple of micros – make sure at least one of them is accessible from the outside world on port 80. As a rule, for a daily publication volume of about 100 articles, tracked for 10 days, starting at every 15 minutes, you'll want one micro. Make sure you grab your private key (PEM file) from Amazon so you can actually log into your micros.

Pollster should work on any flavor of Linux, but the Ansible playbook depends on Ubuntu.

Add your micros to `/etc/ansible/hosts` under the `[pollsters]` group.

Download `playbook.yml` from the Pollster git repository, and run the Ansible playbook like this: 

    ansible-playbook playbook.yml --private-key ~/.ssh/mykey.pem -u ubuntu

At this point everything should be running. But there's still one more step. You need to tell Pollster where to grab content. Pollster includes a little CLI tool (`feedster`) that can either grab it from an RSS / ATOM feed, or from a JSON file. See `feedster --help` for more information.

Here's how you'd grab the latest articles from The Guardian: 

    feedster -i http://content.guardianapis.com/search\?page-size\=50\&format\=json -root response.results -path webUrl

By default, this will tell Pollster to track all content that you add every 15 minutes (with decay) for a week.

You probably want to add feedster to a cron, so it keeps adding new content: 

    */5 * * * * /usr/bin/feedster ... > $HOME/feedster.log

## API

The main endpoint works like this: 

    /facets/?url=<url>
    /facets/?urls=<url>,<url>,...
