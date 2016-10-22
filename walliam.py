#!/usr/bin/python

import boto3,botocore
import hashlib
import base64
import binascii
import pyaes
import json
import sys

DBFILE="./authdb.json"

def load_db(fn):
  db = {}
  try:
     f=open(fn, "r").read()
     db = json.loads(f)
  except:
     pass
  return db


def add_user(name, password):
   db = load_db(DBFILE)

   iam = boto3.client('iam')
   # Delete user if already present
   try:
      user = iam.get_user(UserName=name)
      try:
         access_key = iam.list_access_keys(UserName=name)['AccessKeyMetadata'][0]['AccessKeyId']
         iam.delete_access_key(UserName=name, AccessKeyId=access_key)
      except:
         pass
      iam.delete_user(UserName=name)
   except botocore.exceptions.ClientError as e:
      pass
   except:
      raise

   iam.create_user(UserName=name, Path="/balliam/")
   user = boto3.resource('iam').User(name)
   keypair = user.create_access_key_pair()
   raw_secret = base64.b64decode(keypair.secret)
   aes = pyaes.AESModeOfOperationCTR(hashlib.sha256(password).digest())
   enc_secret = aes.encrypt(raw_secret)
   db[name]=base64.b64encode(enc_secret)
   open(DBFILE, "w").write(json.dumps(db) + "\n")

def check_user(name, password):
   db = load_db(DBFILE)

   aes = pyaes.AESModeOfOperationCTR(hashlib.sha256(password).digest())

   dec_secret = db[name]
   dec_secret = base64.b64decode(dec_secret)
   dec_secret = aes.decrypt(dec_secret)
   dec_secret = base64.b64encode(dec_secret)

   iam = boto3.client('iam')
   access_key = iam.list_access_keys(UserName=name)['AccessKeyMetadata'][0]['AccessKeyId']

   xiam = boto3.client('iam', aws_access_key_id = access_key, aws_secret_access_key = dec_secret)
   try:
      xiam.get_user()
   except Exception as e:
      if(e.message.find('An error occurred (AccessDenied)')==0): return True
   return False



if __name__ == "__main__":
   if(sys.argv[1]=="add"):   add_user(sys.argv[2], sys.argv[3])
   if(sys.argv[1]=="check"):
     status = check_user(sys.argv[2], sys.argv[3])
     print status
