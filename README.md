# peach pro

Dockerfile for [peach pro](https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce)
with everything set up as needed plus some extras.


## Why

The newly released peach pro source code does not compile on any Linux variant,
@Goldstar611 on Gitlab/Github created a shell script that makes it build on Debian Stretch
with quite some effort.
Hence I created a Dockerfile based on it that also generates documenation.

This container has quite a few extra tools for when using `--entrypoint /bin/bash`
that are likely only useful for me :)

## Beware

This only works with Debian Stretch and nothing else - and this release is not
supported anymore. So builing this Dockerfile can stop functioning in the
future at any time!

You can pull from docker hub in such a case:
```
docker run --privileged -v /tmp:/tmp vanhauser/peachpro /tmp/my.pit
```
