#!/bin/bash
apt-get -y install virtualenv python-pip

ORIG=`pwd`
virtualenv build
cd build
source ./bin/activate
pip install dynamo3 dql
cd lib/python2.7/site-packages/
cp $ORIG/dynamo_local.py .
zip -r $ORIG/dynamo_local.zip .
