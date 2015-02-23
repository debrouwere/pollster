#!/usr/bin/env bash
 
rm -r /tmp/etc;
mkdir -p /tmp/etc;
 
for namespace in `etcdctl ls`
do
    destination="/tmp/etc$namespace"
    for key in `etcdctl ls $namespace | cut -d / -f 3`
    do
        path="$namespace/$key"
        value=`etcdctl get $path`
        echo "$key=$value"
    done > "$destination"
done