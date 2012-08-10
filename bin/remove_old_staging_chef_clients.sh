#!/bin/bash

echo "deleting old staging chef clients"
for x in `knife client list | grep staging-vb`; do knife client delete -y ${x}; done
sleep 10

echo "deleting old staging nodes in chef"
for x in `knife node list | grep staging-vb`; do knife node delete -y ${x}; done
