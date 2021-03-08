

# OpenShift OKD on Fedora CoreOS on DigitalOcean Part 0: Preparation

### Introduction

This blog post is the first in a series that will illustrate how to set up an OpenShift OKD cluster on DigitalOcean using the bare metal install documentation (user provisioned infrastructure). OKD has tight integrations with the Operating System and uses Fedora CoreOS as a platform for driving the underlying infrastructure, thus we’ll be deploying on top of Fedora CoreOS images inside of DigitalOcean.

The documentation for OKD is pretty comprehensive, but there is nothing like having a guide to help fill in some of the gaps and show an example of it working with real world values. This series aims to do just that.
Grabbing the OKD software

To install OKD you’ll use a program called openshift-installer. You’ll then use the oc or kubectl binaries to interact with your cluster. You can grab them all from the latest release on the releases page. Currently the latest release is 4.5.0-0.okd-2020-07-14-153706, which is the first GA release of OKD. Follow the instructions in the Getting Started section to download and verify the software.

Place oc, kubectl and openshift-install into your $PATH so they can be used by a script we run later. Placing them in /usr/local/bin/ should suffice.
DigitalOcean Account and CLI Client

I assume since you want to run OKD on DigitalOcean you already have an account. If you want to run through this tutorial, but don’t have an account, go register for one.

You’ll also need to grab doctl and an API key to use with it. Once you have an API key, set it in your bash environment so doctl can pick it up:

export DIGITALOCEAN_ACCESS_TOKEN=xxxxxxxxxxxxxxxxxxxx

Place doctl into your $PATH so it can be used by a script we run later. /usr/local/bin/doctl should work. Run doctl account get to verify you have access.
DigitalOcean Spaces Bucket and CLI Client

DigitalOcean has an S3 compatible object storage offering called Spaces. We’ll use this object storage to house our config that we use to bootstrap the cluster. We do this for two reasons:

    DigitalOcean limits instance userdata to 64KiB. The bootstrap Igition config is larger than that.
    The bootstrap Ignition config contains secrets for the cluster. Storing it behind a webserver without open access is a good idea.

To manage Spaces within DigitalOcean, we’ll use the AWS CLI. On Fedora you can grab it using dnf install awscli. In other environments, refer to the upstream documentation.

After installing the CLI, create an access key for Spaces in the api tokens page and set them in the environment:

export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxx

Now we’ll confirm we have access by listing available spaces. Getting no output from the command is possible. As long as you don’t see an error you should be OK.

aws --endpoint-url https://nyc3.digitaloceanspaces.com s3 ls

Choose a Domain

Naming is fun, right? You need a domain that can be used with DNS. For this cluster I have chosen to use a subdomain of a domain I already own. The subdomain is okdtest.dustymabe.com.
DNS

OKD needs entries in DNS in order to set up a cluster. We can use DigitalOcean to manage the DNS entries for us if you configure our registrar to delegate management of the domain to DigitalOcean. DigitalOcean has a tutorial on how to do this at various registrars. For this example I configured my registrar with three NS records:
Type 	Name 	Value
NS 	okdtest.dustymabe.com. 	ns1.digitalocean.com
NS 	okdtest.dustymabe.com. 	ns2.digitalocean.com
NS 	okdtest.dustymabe.com. 	ns3.digitalocean.com

Now we can manage the domain using DigitalOcean. We’ll get to that part later.
Certificates

NOTE: you can skip this step if you’re just creating a test cluster and don’t care about insecure TLS

If you want users of the cluster to see valid certificates when connecting to services you’ll want to create some certificates for the cluster. I won’t cover how to do this here, but I used Let’s Encrypt as my provider and created the certificates using certbot. The certificate you create can cover your API server, your apps, or both at the same time. For simplicity I created one that would cover both with the following domains:

    api.okdtest.dustymabe.com
    *.apps.okdtest.dustymabe.com

### Conclusion

This post goes through some preparation steps for you to deploy an OKD cluster on DigitalOcean. Followup entries in this series will further detail how to bring up and administer a cluster.


-https://dustymabe.com/2020/07/28/openshift-okd-on-fedora-coreos-on-digitalocean-part-0-preparation/
-https://github.com/coreos/fcct
