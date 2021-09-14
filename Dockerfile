FROM debian:stretch AS peachpro
MAINTAINER vh@thc.org

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get install -y \
    coreutils apt-utils wget curl openssl ca-certificates bash-completion \
    joe vim nano \
    unzip p7zip \
    fping hping3 httping thc-ipv6 gdb \
    tcpdump wireshark-common \
    locales-all \
    git build-essential joe vim strace tcpdump python python-pip \
    ruby doxygen libxml2-utils less openjdk-8-jre xsltproc asciidoctor \
    nodejs node-typescript wget \
    apt-transport-https dirmngr gnupg ca-certificates apt-utils

RUN git clone https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce

# Pin to a known version
RUN cd protocol-fuzzer-ce && \
    git checkout 5697f699dc43593d69c44b8521a50976dfff266e

# Get specific mono packages
WORKDIR /protocol-fuzzer-ce/paket/.paket
RUN wget https://github.com/fsprojects/Paket/releases/download/5.257.0/paket.bootstrapper.exe
RUN wget https://github.com/fsprojects/Paket/releases/download/5.257.0/paket.targets
RUN wget https://github.com/fsprojects/Paket/releases/download/5.257.0/paket.exe
RUN wget https://github.com/fsprojects/Paket/releases/download/5.257.0/Paket.Restore.targets

WORKDIR /protocol-fuzzer-ce

# Download new PIN and change PIN version in build config
RUN wget https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.20-98437-gf02b61307-gcc-linux.tar.gz
RUN mv pin-3.20-98437-gf02b61307-gcc-linux.tar.gz 3rdParty/pin/
RUN cd 3rdParty/pin/ && tar -xf pin-3.20-98437-gf02b61307-gcc-linux.tar.gz
RUN sed -i s/pin-3.19-98425-gcc-linux/pin-3.20-98437-gf02b61307-gcc-linux/g build/config/linux.py
# && \
#    mv pin-3.20-98437-gf02b61307-gcc-linux pin-3.2-98437-gcc-linux
#RUN sed -i s/pin-3.19-98425-gcc-linux/pin-3.2-98437-gcc-linux/g build/config/linux.py
#RUN cd 3rdParty/pin/ && tar xzf pin-3.20-98437-gf02b61307-gcc-linux.tar.gz && \
#    mv pin-3.20-98437-gf02b61307-gcc-linux pin-3.2-98437-gcc-linux
#RUN sed -i s/pin-3.2-81205-gcc-linux/pin-3.20-98437-gf02b61307-gcc-linux/g build/config/linux.py

# Install specific mono for compiling
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/debian stable-stretch main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt-get update -y
RUN apt-get install -y mono-devel
RUN mozroots --import --sync

# Patch bblocks.cpp
# https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce/-/issues/1
# https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce/-/merge_requests/7
RUN sed -i '/^int main.*/itemplate<bool b>\nstruct StaticAssert {};\ntemplate <>\nstruct StaticAssert<true>\n{\n       static void myassert() {}\n};\n' core/BasicBlocks/bblocks.cpp
RUN sed -i 's/STATIC_ASSERT(sizeof(size_t) == sizeof(ADDRINT))/StaticAssert<sizeof(size_t) == sizeof(ADDRINT)>::myassert()/g' core/BasicBlocks/bblocks.cpp
# Patch BaseProgram.cs  error CS0219: Warning as Error: The variable `config' is assigned but its value is never used
# https://gitlab.com/gitlab-org/security-products/protocol-fuzzer-ce/-/issues/3
RUN sed -i 's/var config = new LicenseConfig();/\/\/var config = new LicenseConfig();/g' pro/Core/Runtime/BaseProgram.cs

# Configure and build
RUN ./waf configure
RUN ./waf build

# Downgrade mono back to 4.x for installation and runtime
# The installed mono version 6.12.0.122 (tarball Mon Feb 22 17:33:15 UTC 2021) is not supported.
# Ensure mono version 4.x and not 4.4 is installed and try again.
RUN apt purge -y mono* libmono* doxygen && \
    rm /etc/apt/sources.list.d/mono-official-stable.list
RUN apt update -y
RUN apt install -y mono-complete

RUN ./waf install

RUN cp -r output/linux_x86_64_release/bin /peach
RUN cp -r output/doc/sdk /peach/doc

WORKDIR    /peach

RUN rm -rf /protocol-fuzzer-ce
RUN echo 'alias joe="joe --wordwrap"' >> ~/.bashrc
RUN echo 'export PS1="docker[peach] $PS1"' >> ~/.bashrc

ENV        IS_DOCKER="1"
ENV        PATH="$PATH:/peach"
ENV        DOCKER_PS1="docker[peach] \w # "
ENV        DOTNET_CLI_TELEMETRY_OPTOUT=1
ENTRYPOINT ["/peach/peach"]
