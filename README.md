# ratelock
Rate Limiting using Cloud Resources

# TL;DR
WallIAM:  Use Amazon's zealous protection of their IAM Secret Keys to protect your
password hashes (make the offline attack an online one, against a skilled
adversary).

Larger play:  If we can trust the cloud, we should be using it a lot more.
Specifically, we should be extracting components of our security model
(like, how much data we leak, on what terms) and letting the cloud we trust
to *actually run our servers anyway* manage those components separately.

# Security Note on WillIAM
The calling account *does not* require arbitrary access to Amazon via
IAMFullAccess.  Access is constrained to an ARN Path, prefixed with
"walliam", and then only allows a handful of operations.  Importantly,
none of these operations allow attaching roles or policies.  See
iam.json for details.

That being said, someone could probably make you hit some IAM limits,
which as in all Rate Limiting approaches is the risk you accept.

# Quick Demo

    ubuntu@ip-192-168-1-64:~/ratelock$ ls ~/.aws/
    credentials
    
    ubuntu@ip-192-168-1-64:~/ratelock$ ./walliam.py add demouser 1234567
    ubuntu@ip-192-168-1-64:~/ratelock$ cat authdb.json 
    {"demouser": "BvL40myloWAo39hbIpRpKOy4Skdtswcaa7WJUzWf"}
    ubuntu@ip-192-168-1-64:~/ratelock$ ./walliam.py check demouser 7654321
    False
    ubuntu@ip-192-168-1-64:~/ratelock$ ./walliam.py check demouser 1234567
    True

# TODO

1. Create simple Amazon Ratelocking demo, using AWS Lambda to rate limit access to
   resources hosted in Dynamo.  Demonstrate "triggers" such as a Twilio ping
   at one rate and an actual block at another.
2. Create simple Google Cloud demo, leveraging code hiding guarantee here:
   ![Prohibit Code Downloads](https://i.imgur.com/HwFdhhg.png "")
   Can we make a function that stores its own data, and updates itself?
   Note the tricky part of using even an external store is replay attacks.
   This is going to mirror some elements of coding to Intel SGX.
3. Automate the peskier aspects of keeping this safe, like deep separation
   between the operational account and the "control plane" rate limiting account.
   This is where we start getting to surviving developer breach.  Maybe.
4. Upgrade WillIAM to emit a PyNACL asymmetrically encrypted blob, against an
   offline private key.  There's two consumers for mass dumps of data -- backup
   and bad guys.  We can support the former and be really annoying to the
   latter.
5. Expand this document!


