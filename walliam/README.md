# WallIAM
Protecting Password Hashes using Amazon IAM Secret Key Protection

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

# How it works
Amazon IAM accounts have a "password", in the form of an AWS Secret Key.
It's random, it's Amazon generated, and if you ever lose it, Amazon is never,
ever giving it back to you.  They're quite zealous about that.

Great.  We can make a password storage scheme out of this.  We use the
user supplied password string as an encryption key for the AWS Secret Key.
The attacker who compromises our password store can guess any password string
he likes, but to validate he guessed correctly, he has to try to log into
an IAM account with his guess.

He can't do that 100M times a second.  His offline attack is now an online
attack, against a skilled adversary who will eventually rate linit his attempts.

# How it would fail

AWS Secret Keys are normally expressed in Base64.  If we encrypted the Base64
expression, rather than the raw (presumably random) bits inside, the attacker
wouldn't need to probe IAM.  He could just see if the attempt decrypted into
valid Base64.

In a similar vein, if we did the normal actual best practice (NaCl Boxes) an
attacker would be able to detect a successful decryption by NaCl's sudden lack
of complaint.

If the AWS Secret Key bits weren't random after all, that too would cause
failure.

# Security Note
The calling account *does not* require arbitrary access to Amazon via
IAMFullAccess.  Access is constrained to an ARN Path, prefixed with
"walliam", and then only allows a handful of operations.  Importantly,
none of these operations allow attaching roles or policies.  See
iam.json for details.

That being said, someone could probably make you hit some IAM limits,
which as in all Rate Limiting approaches is the risk you accept.

# TODO

1. Should automate submission of the walliam_policy.json policies, which need
to be present on the calling account.
2. Maybe expose via API Gateway?
3. Provide API to count how many IAM accounts have been created in this context.
As of writing, AWS has a 5000 account limit.  You can ask for, and almost
certainly buy a higher limit.
4. Merge with ratelock.py properly -- should be able to transparently swap
between lambda/dynamo and IAM
5. Proper optparse
6. Demo emitting a asymmetrically encrypted copy of the actual user password,
for backup/restore (since IAM is really not going to give even you that)
7. Create simple Google Cloud demo, leveraging code hiding guarantee here:
   1. ![Prohibit Code Downloads](https://i.imgur.com/HwFdhhg.png "")
   2. Can we make a function that stores its own data, and updates itself?
Note the tricky part of using even an external store is replay attacks.
This is going to mirror some elements of coding to Intel SGX.
