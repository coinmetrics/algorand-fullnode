FROM golang:latest as builder

ARG VERSION

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		sudo \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	mkdir -p $GOPATH/src/github.com/algorand; \
	cd $GOPATH/src/github.com/algorand; \
	git clone --depth 1 -b ${VERSION} https://github.com/algorand/go-algorand.git; \
	cd go-algorand; \
	./scripts/configure_dev.sh; \
	./scripts/build_prod.sh


FROM debian:latest

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		netbase \
		ca-certificates \
		curl \
	; \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/bin/* /usr/bin/
COPY --from=builder /go/src/github.com/algorand/go-algorand/installer/genesis/mainnet/genesis.json /opt/genesis.json

RUN useradd -m -u 1000 -s /bin/bash runner
USER runner
WORKDIR /home/runner

ENTRYPOINT ["algod", "-g", "/opt/genesis.json"]
