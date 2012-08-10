#!/bin/bash

for x in `knife rackspace server list  | grep perf-dfw | awk '{print $1}'`; do knife rackspace server delete ${x} -y; done
