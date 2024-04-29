---
author: "OldTyT"
title: "Docker best practices"
date: "2024-04-29"
description: "Docker best practices"
tags: ["docker", "container", "dockerfile", "DevOps", "BestPractices"]
categories: ["BestPractices", "docker", "devops"]
series: ["docker"]
aliases: ["docker_best_practices"]
url: "/ru/posts/docker_best_practices/"
ShowToc: true
TocOpen: true
weight: 1
---

В рамках данной статьи будут рассмотрены наиболее частые антипаттерны при проектировании docker образов, а так же будет представлено оптимальное решение для каждого

## Использование избыточного базового образа

Один из распространенных антипаттернов при использовании Docker - это использование избыточного базового образа.

```Dockerfile
# Плохо
FROM ubuntu
```

Оптимальное решение - использовать наиболее легковесный базовый образ, который содержит только необходимые компоненты, в роли которого может выступать alpine.

```Dockerfile
# Хорошо
FROM alpine
```

Сравнение размера двух образов:

```bash
root@gusev:~# docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
alpine       latest    8ca4688f4f35   9 days ago    7.34MB
ubuntu       latest    3565a89d9e81   13 days ago   77.8MB
```

## Множество инструкций

Из-за особенностей работы docker, каждая выполненная инструкция - выполняет "снэпшот" состояния файловой системы контейнера на текущий момент, так что следует уменьшать количество этих самых инструкций.
Пример плохой реализации Dockerfil'a:

```Dockerfile
# Плохо
FROM ubuntu
RUN apt update
RUN apt install -y nginx
RUN apt install -y curl
RUN touch /my_file
RUN chmod +x /my_file
```

Оптимальным вариантом будет следующий:

```Dockerfile
# Плохо
FROM ubuntu
RUN apt update && \
    apt install -y nginx && \
    apt install -y curl && \
    touch /my_file && \
    chmod +x /my_file
```

## Не оптимальная установка пакетов

Часто можно наблюдать в Dockerfile такую конструкцию:

```Dockerfile
# Плохо
FROM alpine
RUN apk update && \ 
    apk add curl wget nginx
```

Данная конструкция не является оптимальной, т.к. выполняется обновление локальных кэшей, а это занимает драгоценное место, оптимальным решением будет следующее:

```Dockerfile
# Хорошо
FROM alpine
RUN apk add --no-cache curl wget nginx
```

В случае, если используется пакетный менеджер apt:

```Dockerfile
# Хорошо
FROM ubuntu
RUN apt update && \
    apt install -y curl wget nginx && \
    rm -rf /var/lib/apt/lists/*
```

## Использование последних версий

Зачастую в Dockerfile можно часто встретить конструкции по типу:

```Dockerfile
# Плохо
FROM alpine
RUN apk add --no-cache curl wget nginx
```

Эта конструкция является плохой, т.к. через время, может появиться необходимость пересобрать контейнер, но вероятно возникнет ошибка из-за того, что были обновлены артефакты которые используются при сборке. Оптимальный вариант:

```Dockerfile
# Хорошо
FROM alpine:3.18.4
RUN apk add --no-cache curl==8.3.0-r0 wget==1.21.4-r0 nginx==1.24.0-r6
```

## Multi-stage сборки

В Docker есть возможность реализовать multi-stage сборки, если кратко, то суть сводится к тому, что в Dockerfile описывается множество этапов, причем из каждого артефакты передаются в следующие. Отказ от использования такой возможности, может сильно увеличить размер конечного образа.

```Dockerfile
# Плохо
FROM alpine:3.18.4
WORKDIR /app_tmp
COPY . .
RUN apk add --no-cache hugo && hugo  --destination=/app --baseURL=https://oldtyt.xyz
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /app
RUN apk add --no-cache curl nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

Оптимальным же решением будет следующее:

```Dockerfile
# Хорошо
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

Healthcheck - это инструкция, которую Docker может использовать для проверки работоспособности запущенного контейнера.
По большей части healthcheck проверяют доступность страницы/порта приложения. Один из вариантов реализации:

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
