# peach pro

Dockerfile for [peach pro](https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce)
with everything set up as needed plus some extras.


## Why

The newly released peach pro source code does not compile on any Linux variant,
@Goldstar61 on Gitlab created a shell script that makes it build on Debian Stretch
with quite some effort.
Hence I created a Dockerfile based on it that also generates documenation.

This container has quite a few extra tools for when using `--entrypoint /bin/bash`
that are likely only useful for me :)
