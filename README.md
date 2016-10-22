# ratelock
Rate Limiting using Cloud Resources

# TL;DR
Use Amazon's zealous protection of their IAM Secret Keys to protect your
password hashes.

# Important Caveat
Right now, this requires an account with the role "IAMFullAccess"
(you're creating accounts).  Obviously I'm working on better, but
it's definitely wise to run this out of a separate Amazon account.

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
