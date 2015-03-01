#!/usr/bin/env bash

if [ `expr $(date +%s) - $(stat -c %Y /tmp/etc)` -lt 60 ] || [ -d '/tmp/etc.part' ];
then
    exit
fi

mkdir -p /tmp/etc.part;

for namespace in `etcdctl ls`
do
    destination="/tmp/etc.part$namespace"
    for key in `etcdctl ls $namespace | cut -d / -f 3`
    do
        path="$namespace/$key"
        value=`etcdctl get $path`
        echo "$key=$value"
    done > "$destination"
done

rm -r /tmp/etc;
mv /tmp/etc.part /tmp/etc;
