FROM alpine:3.18.4 as builder

WORKDIR /app

COPY . .

RUN apk add --no-cache hugo && hugo  --destination=/app_out --baseURL=https://oldtyt.xyz

FROM alpine:3.18.4

COPY --from=builder /app_out /app
COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /app

RUN apk add --no-cache curl nginx

HEALTHCHECK --interval=5s --timeout=10s --retries=3 CMD curl -IL 127.0.0.1 | grep 200 || exit 1

ENTRYPOINT ["nginx", "-g", "daemon off;"]
