# Golang application container to work with SQL databases.

FROM golang:1.8-alpine
WORKDIR /go/src/app
COPY ./code /go/src/app
RUN apk --no-cache add git \
&&  go-wrapper download \
&&  go-wrapper install
CMD ["go-wrapper", "run"]

