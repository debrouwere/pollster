#!/usr/bin/env python3

import os
import re
import sh

# can run locally or inside of a Docker container that's 
# part of a Fleet cluster
def connect():
    if 'FLEETCTL_TUNNEL_IPV4' in os.environ:
        fleet = sh.fleetctl.bake(
            tunnel=os.environ['FLEETCTL_TUNNEL_IPV4'])
    else:
        endpoint = "http://{localhost}:2379/".format(
            localhost=os.environ['COREOS_PRIVATE_IPV4'])
        fleet = sh.fleetctl.bake(endpoint=endpoint)

    return fleet

def clean(string):
    return re.sub(r'\t+', '\t', string).strip()

def read(string, delimiter='\t', eol='\n'):
    lines = string.split(eol)
    return [line.split(delimiter) for line in lines]

def parse_unit(info):
    unit, sub = info

    if '@' in unit:
        container, instance = unit.split('@')
        i, service_type = instance.split('.')
    else:
        container, service_type = unit.split('.')
        i = '1'

    unit = {
        'container': container, 
        'type': service_type, 
        'instance': i, 
    }

    return (unit, sub)

def list_etc():
    return sh.etcdctl.ls()

def get_etc(key):
    return sh.etcdctl.get(key)

def set_etc(key, value):
    return sh.etcdctl.set(key)

def list_units():
    fleet = connect()
    raw = fleet('list-units', fields='unit,sub', no_legend=True)
    units = read(clean(str(raw)))
    return map(parse_unit, units)

def list_machines():
    fleet = connect()
    raw = fleet('list-machines', fields='ip', no_legend=True)
    return read(clean(str(raw)))
