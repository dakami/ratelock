#!/usr/bin/python

# -*- coding: utf-8 -*-
import boto3   
from boto3.dynamodb.conditions import Key, Attr
import sys

# Get the service resource.
table_to_create = 'authdb'

import zipfile
import StringIO

import json,time
from decimal import Decimal
from dynamo3 import Binary
from dql import Engine
import re

d = Engine()
d.connect("us-east-1")
# XXX choosing demo simplicity over cost
d.allow_select_scan = True

class AuthDB(object):
    def __init__(self, dbname):
        self.dbname = dbname
        self.resource = boto3.resource('dynamodb')
        self.client   = boto3.client('dynamodb')
        self.table = None
        self.table_ratelimit = None

    def start(self):
        if not d.describe(self.dbname):
            self.table = d.execute("create table " + self.dbname + " (username string HASH KEY, password string);")
        if not d.describe(self.dbname + "_ratelimit"):
            self.table_ratelimit = d.execute("create table " + self.dbname + "_ratelimit (stub string HASH KEY, time_accessed number RANGE KEY);")
        

    def delete(self):
       try: self.client.delete_table(TableName=self.dbname)
       except: pass
       try: self.client.delete_table(TableName=self.dbname+"_ratelimit")
       except: pass
        
    def do_scrypt_XXXSTUBXXX(self, password):
        # scrypt goes here, to be executed as close as possible to the actual write,
        # but not implemented twice.
        # XXX kept out for demo/dependency purposes
        return password
    
    def add(self, username, password):
       if not self.table: self.start()
       # Have we done more than 3 lookups in the last 10 seconds?
       hitcount_last_ten_seconds = d.execute("select CONSISTENT count(*) from " + self.dbname + "_ratelimit where time_accessed > " + str(time.time()-10) + ";")
       print hitcount_last_ten_seconds
       if(hitcount_last_ten_seconds > 3):
           return False
       # Log that we're looking something up.  Could log verb.           
       d.execute("insert into " + self.dbname + "_ratelimit (stub, time_accessed) values ('0', " + str(time.time()) + ");")

       # this is just for demo purposes, but I'm not so crazy as to ship obvious SQLi even in a demo
       # XXX submit patch for DQL
       validator = re.compile("^([1-zA-Z0-1@.]{1,255})$")
       if not validator.match(username) or not validator.match(password):
           return False
       #d.execute("update " + self.dbname + " set password = " + self.do_scrypt_XXXSTUBXXX(password) + " where username = " + username)
       sql = "insert into " + self.dbname + " (username, password) values ('" + username + "', '" + self.do_scrypt_XXXSTUBXXX(password) + "');"
       d.execute(sql)
       return True
       
    def check(self, username, password):
       if not self.table: self.start()
       # Have we done more than 3 lookups in the last 10 seconds?
       hitcount_last_ten_seconds = d.execute("select CONSISTENT count(*) from " + self.dbname + "_ratelimit where time_accessed > " + str(time.time()-10) + ";")
       print hitcount_last_ten_seconds
       if(hitcount_last_ten_seconds > 3):
           return False
       # Log that we're looking something up.  Could log verb.           
       d.execute("insert into " + self.dbname + "_ratelimit (stub, time_accessed) values ('0', " + str(time.time()) + ");")

       # this is just for demo purposes, but I'm not so crazy as to ship obvious SQLi even in a demo
       # XXX submit patch for DQL
       validator = re.compile("^([1-zA-Z0-1@.]{1,255})$")
       if not validator.match(username) or not validator.match(password):
           return False
       sql="select CONSISTENT count(*) from " + self.dbname + " where username = '" + username + "' and password = '" + self.do_scrypt_XXXSTUBXXX(password) + "';"
       correct = (1==(d.execute(sql)))
       return correct
    
    
if __name__ == "__main__":
   db = AuthDB("authdb")

   verb = sys.argv[1]
   if verb == "delete":
       print db.delete()
       sys.exit(0)
       
   verb, username, password = sys.argv[1:4]

   if verb == "add":   print db.add(username, password)
   if verb == "check": print db.check(username, password)
   if verb == "dump":  print "just because I don't exist, doesn't mean I don't have the permissions to"
   
   if verb == "remote":
       verb, username, password = sys.argv[2:5]
       client = boto3.client("lambda")
       response=client.invoke(
           FunctionName = "ratelimit",
           Payload = json.dumps({
               "verb": verb,
               "username": username,
               "password": password
       }))
       print response['Payload'].read()

def handler(event, context):
    verb, username, password = (event.get('verb'), event.get('username'), event.get('password'))
    db = AuthDB("authdb")
    if verb == "add":   return db.add(username, password)
    if verb == "check": return db.check(username, password)
