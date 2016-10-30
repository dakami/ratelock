#!/bin/bash
apt-get -y install virtualenv python-pip

ORIG=`pwd`
rm -rf build
virtualenv build
cd build
source ./bin/activate
pip install dynamo3 dql
cd lib/python2.7/site-packages/
cp $ORIG/../ratelock.py .
zip -r $ORIG/ratelock.zip .
