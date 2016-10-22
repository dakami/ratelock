# ratelock
Rate Limiting using Cloud Resources

# TL;DR
Use Amazon's zealous protection of their IAM Secret Keys to protect your
password hashes.

# Security Note
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
