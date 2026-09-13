FROM golang:1.26-alpine3.23 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

ENV CGO_ENABLED=0
RUN go test ./... \
    && go build -trimpath -ldflags="-s -w" -o /app/backend-report .

FROM alpine:3.23

RUN apk add --no-cache ca-certificates \
    && addgroup -S reporter \
    && adduser -S -G reporter reporter
WORKDIR /app
COPY --from=builder --chown=reporter:reporter /app/backend-report ./backend-report

USER reporter
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app/backend-report"]
