# ratelock
Restricting Data Loss with Serverless Cloud Enforcement

# Subprojects
[WallIAM](https://github.com/dakami/ratelock/tree/master/walliam):
Protecting Password Hashes using Amazon IAM Secret Key Protection

# TL;DR
Let the cloud run policy enforcement functions, so that when your complex
code gets hacked, there can still be constraints on how much data is lost.

We'd have to trust the cloud.  Well, for the most part, we already *do*.
*If* we can trust the cloud, we should do so a heck of a lot more.
They're certainly better at running servers than we are.

# Demo (only allow 3 queries every 10 seconds, gated by Lambda and DynamoDB)
    ./ratelock.py add foo bar # prints true
    ./ratelock.py check foo bar # prints true
    ./ratelock.py check foo wrong # prints false           
    
    # while [ 1 ]; do ./ratelock.py check foo bar; sleep 0.25; done                                                      
    true ... true ... true ... true ... false ... false ... false

# What's happening here
We tend to assume compromise is all or nothing, i.e. if you break any part of
a system, the entire thing fails into an undefined state, ready for a hacker
to redefine.  For example, your database can have all sorts of clever
constraints, but once it's hacked, the attack could just dump the hard drive.

Historically, I've always said:  If you want two security domains, get two
computers.  Well, the cloud providers run computers by the million.  We
either live in the universe where we can't trust the clouds to keep those
computers separate, or the universe where we can.

If we can't trust the clouds, I have other techniques, but if we can trust them,
we should use them a heck of a lot more.  And the first thing we should do
is factor out the things that we really need not to fail -- say, a limit to
how fast we can lose data -- such that even when our complex code dies, the
attacker can only cost us so much.

The cash register at the gas station has $20.  It doesn't have payroll.  We
rate limit losses everywhere else.  Let's do this for our data, and get
credit card breaches where...500 records were lost.  Not a third of Germany.

# How the demo works
1. Client (with various AWS permissions) creates a Lambda function that uses
DynamoDB as a backing store.  This happens during installation.
2. Client (with nothing but Lambda Invoke privileges) executes that function,
adding or checking a password.  
3. Lambda goes to add or check a password, but first checks to see if there are
more than three queries logged in the last ten seconds.  If so, it reports
no password match.  Otherwise, it reports a password match if there is one.
And of course it logs the query, successful or not.

Client can be fully compromised, and as long as the provisioning credentials
are not on that node, it can never exceed 3 queries every 10 seconds.

Note that a major e-commerce provider (top 10) reports that at their peak,
their password database load is not thousands of queries a second, or even
hundreds.  It's 7.  These massive breaches are unnecessary.

# TODO

1. Add paths to the Lambda policy grant (right now, it has full access to
lambda and dynamodb).
2. Better docs.
3. Terraform main.tf needs to be cleaned up, and probably the entire thing
is too heavy especially for a demo.  It's a massively stateful codebase
that gets itself confused a little too easily for my tastes.  We're about
halfway to a quick include for an app that self publishes main to Lambda.
At minumum, clean up install (and add region defaults) and document
uninstall (which is often just ./terraform destroy, but not always.)
4. Support other backends than DynamoDB, which is being used for
Strong Consistency (which ultimately needs to permeate this entire approach,
we're locking sloppily).
5. Support other clouds, particularly Google App Engine, because this is
*amazing*:
   1. ![Prohibit Code Downloads](https://i.imgur.com/HwFdhhg.png "")
