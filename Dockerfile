FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Install Go prerequisite, ansible, openstack, and s3 packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-utils \
         software-properties-common \
    && apt-get install -y --no-install-recommends \
         ansible \
         bash \
         curl \
         g++ \
         gcc \
         git \
         graphviz \
         libc6-dev \
         make \
         openssh-client \
         pkg-config \
         python3-openstackclient \
         python3-setuptools \
         s3cmd \
         wget \
         unzip \
    && rm -rf /var/lib/apt/lists/*

# Build Go
ENV GOLANG_VERSION 1.7.4
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 47fda42e46b4c3ec93fa5d4d4cc6a748aa3f9411a2a2b7e08e3a6d80d753ec8b
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

# Build terraform
RUN go get github.com/mitchellh/gox
RUN go get github.com/hashicorp/terraform
WORKDIR $GOPATH/src/github.com/hashicorp/terraform
ENV XC_ARCH="amd64"
ENV XC_OS="linux"
RUN /bin/bash scripts/build.sh

# Build terragrunt
RUN mkdir -p $GOPATH/src/github.com/gruntwork-io
WORKDIR $GOPATH/src/github.com/gruntwork-io
RUN git clone https://github.com/gruntwork-io/terragrunt.git \
    && cd terragrunt \
    && git checkout v0.10.3 \
    && go get \
    && go install

# Install yatadis 
RUN cd /tmp \
    && git clone https://github.com/wtsi-hgi/yatadis.git \
    && cd yatadis \
    && git checkout 0.4.0 \
    && python3 setup.py install

# Install consul
ENV CONSUL_VERSION 0.7.5
RUN wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -O /tmp/consul.zip \
    && unzip -d /usr/local/bin /tmp/consul.zip \
    && consul version

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
