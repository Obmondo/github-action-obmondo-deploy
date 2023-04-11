# Alpine with git, rsync and jsonnet
FROM alpine:3.15 AS build
RUN apk add git go make github-cli

# jsonnet
RUN go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest && \
  go install github.com/brancz/gojsontoyaml@latest &&                      \
  go install github.com/google/go-jsonnet/cmd/jsonnet@latest

FROM alpine:3.15
  LABEL org.opencontainers.image.authors="Rune Juhl Jacobsen <runejuhl@enableit.dk>"
ENV PATH="/root/go/bin:${PATH}"

RUN apk add bash jq git rsync
COPY --from=build /root/go/bin/* /usr/local/bin/
COPY --from=build /usr/bin/gh /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
