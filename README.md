# Pollster

Pollster follows an article feed, and for every new article it encounters, it starts polling for social media share counts, saving them to DynamoDB and putting them on an SQS queue for further processing. At the end of the day, all share counts for that day are additionally persisted to S3 for easy analysis.

Pollster polls often for services that can handle it (Twitter, Facebook) and less often for services that can't (Pinterest, LinkedIn etc.)

Pollster relies on [Jobs](https://github.com/debrouwere/jobs) for scheduling and [Fleet](https://coreos.com/using-coreos/clustering/) for clustering.

## Installation

### Local installation

You can run Pollster locally using [Fig](http://www.fig.sh/), though when running locally some aspects (like saving to a production database) will be simulated.

### Installation on a cluster

Pollster is most easily deployed on Amazon Web Services EC2 machines with [CoreOS](https://coreos.com/). That way, you'll have [Fleet](https://coreos.com/using-coreos/clustering/), [Etcd](https://github.com/coreos/etcd), [Docker](https://www.docker.com/) and AWS autoscaling available out of the box to manage your cluster.

Before we set up our cluster, install [Fleet](https://coreos.com/docs/launching-containers/launching/fleet-using-the-client/) on your local machine. On OS X this is `brew install fleetctl`.

(For development, additionally install [Docker](https://www.docker.com/), [Fig](http://www.fig.sh/) and [Jobs](https://github.com/debrouwere/jobs).)

You will also want to have an [Amazon EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) on AWS and your local machine.

1. Create a CoreOS cluster on Amazon Web Services. Go to your AWS dashboard, navigate to the CloudFormation interface, and click on "Create Stack". Upload the CloudFormation template in this repo at `stack/floudformation.json`. The CloudFormation interface will ask you how many machines you'd like to spin up and a couple of other questions. Then, it will set up your machines, security groups and so on.
2. Go to the AWS EC2 dashboard and note down the public IP or hostname to one of the machines in your CoreOS cluster -- any machine will do.
3. When creating your cluster you specified which keypair to use. With your private key, do `ssh-add ~/.ssh/my-key.pem`
4. Add your AWS access keys and the desired Pollster configuration to an environment file; you can use `example.env` as a starting point.
5. `./utils/configure <machine> <configuration>.env` will upload this configuration to your cluster.
6. Start all required services.

```shell
cd stack/services
# if you don't have `repl` installed, prefix `fleetctl --tunnel <machine>`
# onto each command that follows
repl fleetctl --tunnel <machine>
submit *.service *.timer
start update.timer
start redis
start scheduler
load backup submit summarize heartbeat count
start *.timer
start poller.careful@{1..3}
start poller.frequent@{1..3}
```

Congratulations! You should now have a functional Pollster cluster. Verify with `fleetctl --tunnel <machine> --list-units`.

#### Troubleshooting

* Keep into account that, when launching each service, CoreOS will download the latest Redis, Jobs and Pollster application images from the public Docker repository. These images are a couple hundred megabytes, so this will take a couple of minutes. If you try to launch things too fast, Fleet can sometimes choke up. In this case, `fleetctl destroy <service>` followed by a fresh `fleetctl submit <service>; fleetctl start <service>` can help.
* The backup, submitter and summarize services are on a timer. It is normal for them to have a `dead` status when they're not running, and their related timers to read `active, waiting`.
* To inspect failed services, `fleetctl status <my-service>` is your friend, e.g. `fleetctl --tunnel <machine> start poller@1`.
* Pollster puts share counts in DynamoDB, SQS and also logs each poll with CloudWatch. It also makes a backup of all articles and their polling schedule in S3.
    * Check the status of `store` and `scheduler` to see if the Jobs scheduler is online.
    * Check the status of your `poller@n` services to see if these are running. Check the `social-shares` custom metrics in CloudWatch to see if share counts are properly getting saved.
    * Check your CPU credits in CloudWatch. Performance on your `t2.micro` machines will drop if they don't have any CPU credit left. In this case, you might need to increase the size of your cluster.
    * Monitor your SQS queue or, alternatively, download a dump from DynamoDB to see if the data is what you expect it to be like.
