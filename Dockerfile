FROM golang:1.16-buster AS builder
ENV CGO_ENABLED=0
ARG COMPILE_FLAGS
WORKDIR /root/courier
COPY go.mod /root/courier/go.mod
COPY go.sum /root/courier/go.sum
run go mod download
COPY . /root/courier
RUN go build -ldflags "${COMPILE_FLAGS}" -o courier ./cmd/courier \
            && go build -ldflags "${COMPILE_FLAGS}" -o fuzzer ./cmd/fuzzer

FROM debian:buster AS courier
RUN adduser --uid 1000 --disabled-password --gecos '' --home /srv/courier courier
RUN apt-get -yq update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                unattended-upgrades \
                # ssl certs to external services
                ca-certificates \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean
COPY --from=builder /root/courier/courier /usr/bin/
COPY --from=builder /root/courier/fuzzer /usr/bin/
COPY entrypoint /usr/bin/
EXPOSE 8080
USER courier
ENTRYPOINT ["entrypoint"]
