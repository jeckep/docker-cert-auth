# ==============================================================================
# First stage build (compile the Go server)
# ==============================================================================
FROM golang:1.9.2-alpine3.6 as builder

WORKDIR /
COPY web/main.go .
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server .

# ==============================================================================
# Second stage build
# ==============================================================================
FROM alpine:edge

RUN apk add --no-cache nginx s6

# Copy s6 configuration
ADD s6 /s6

RUN chmod +x -R /s6 && \
    mkdir -p /run/nginx && \
    mkdir /web && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Copy the internal server from the first stage build
#ADD server /web/
COPY --from=builder /server /web/

# Copy server config
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/

# Copy certs to server
#RUN mkdir -p /etc/nginx/certs
#COPY certs/server.crt \
#     certs/server.key \
#     certs/ca.crt \
#     /etc/nginx/certs/

STOPSIGNAL SIGTERM

EXPOSE 443

CMD ["s6-svscan", "/s6"]