---
author: "OldTyT"
title: "Docker best practices practices"
date: "2023-10-08"
description: "Docker best practices"
tags: ["docker", "container", "dockerfile", "DevOps", "BestPractices"]
categories: ["BestPractices", "docker"]
series: ["docker"]
aliases: ["docker_best_practices"]
ShowToc: true
TocOpen: true
weight: 1
---

Within the framework of this article, the most frequent antipatterns in the design of docker images will be considered, and the optimal solution for each will be presented.

## Using a redundant base image

One of the common antipatterns when using Docker is the use of a redundant base image.

```Dockerfile
# Bad
FROM ubuntu
```

The optimal solution is to use the most lightweight base image, which contains only the necessary components, which can act as alpine.

```Dockerfile
# Good
FROM alpine
```

Comparing the size of two images:

```bash
root@gusev:~# docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
alpine       latest    8ca4688f4f35   9 days ago    7.34MB
ubuntu       latest    3565a89d9e81   13 days ago   77.8MB
```

## Lots of instructions

Due to the peculiarities of docker's work, each executed instruction performs a "snapshot" of the state of the container's file system at the moment, so you should reduce the number of these very instructions, an example of a bad implementation of Dockerfil:

```Dockerfile
# Bad
FROM ubuntu
RUN apt update
RUN apt install -y nginx
RUN apt install -y curl
RUN touch /my_file
RUN chmod +x /my_file
```

The best option would be the following:

```Dockerfile
# Good
FROM ubuntu
RUN apt update && \
    apt install -y nginx && \
    apt install -y curl && \
    touch /my_file && \
    chmod +x /my_file
```

## Not optimal package installation

It is often possible to observe such a construction in Dockerfile:

```Dockerfile
# Bad
FROM alpine
RUN apk update && \ 
    apk add curl wget nginx
```

This design is not optimal, because local caches are being updated, and this takes up precious space, the best solution would be the following:

```Dockerfile
# Good
FROM alpine
RUN apk add --no-cache curl wget nginx
```

In case the apt package manager is used:

```Dockerfile
# Good
FROM ubuntu
RUN apt update && \
    apt install -y curl wget nginx && \
    rm -rf /var/lib/apt/lists/*
```

## Using the latest versions

Often in Dockerfile you can often find constructions of the type:

```Dockerfile
# Bad
FROM alpine
RUN apk add --no-cache curl wget nginx
```

This design is bad, because after a while, it may be necessary to rebuild the container, but an error will probably occur due to the fact that the artifacts that are used during assembly have been updated. The best option:

```Dockerfile
# Good
FROM alpine:3.18.4
RUN apk add --no-cache curl==8.3.0-r0 wget==1.21.4-r0 nginx==1.24.0-r6
```

## Multi-stage builds

In Docker, it is possible to implement multi-stage builds, in short, the essence boils down to the fact that Dockerfile describes many stages, and artifacts are transferred from each to the next. Failure to use this feature can greatly increase the size of the final image.

```Dockerfile
# Bad
FROM alpine:3.18.4
WORKDIR /app_tmp
COPY . .
RUN apk add --no-cache hugo && hugo  --destination=/app --baseURL=https://oldtyt.xyz
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /app
RUN apk add --no-cache curl nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

The optimal solution would be the following:

```Dockerfile
# Good
FROM alpine:3.18.4 as builder
WORKDIR /app
COPY . .
RUN apk add --no-cache hugo && hugo  --destination=/app_out --baseURL=https://oldtyt.xyz

FROM alpine:3.18.4
COPY --from=builder /app_out /app
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /app
RUN apk add --no-cache curl nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

## Healthcheck

Health check is an instruction that Docker can use to check the health of a running container.
For the most part, healthcheck checks the availability of the page/port of the application. One of the implementation options:

```Dockerfile
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
```
