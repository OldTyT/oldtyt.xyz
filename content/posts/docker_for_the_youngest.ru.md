---
author: "OldTyT"
title: "Docker для чайников"
date: "2024-04-29"
description: "Docker для чайников"
tags: ["docker", "контейнер", "разработка", "приложение", "dockerfile", "основа", "база", "DevOps", "docker", "devops", "base", "для_чайников"]
categories: ["docker"]
series: ["docker"]
aliases: ["docker_for_the_youngest"]
ShowToc: true
TocOpen: true
weight: 1
url: "/ru/posts/docker_for_the_youngest/"
---

# Docker для самых маленьких

Для закрепления материала, рекомендуется выполнить команды указанные в статье

## Введение

Docker - это платформа для разработки, доставки и запуска приложений в контейнерах. Контейнеры представляют собой легковесные и изолированные окружения, которые позволяют запускать приложения на любой операционной системе без необходимости установки дополнительных зависимостей. В этой статье мы рассмотрим основы Docker и покажем, как использовать его для разработки приложений.

## Установка Docker

Перед тем, как начать использовать Docker, вам необходимо установить его на свою систему. Для этого следуйте инструкциям на официальном сайте [Docker](https://docs.docker.com/engine/install/). Там Вы найдете подробные инструкции для различных операционных систем.

## Создание контейнера

После установки Docker Вы готовы создавать свои контейнеры. Для этого Вам понадобится файл Dockerfile, в котором описываются шаги по созданию контейнера. Вот пример простого Dockerfile:

```Dockerfile
FROM alpine:latest
ENTRYPOINT ["echo", "Hello world!"]
```

В этом примере мы используем базовый образ [Alpine](https://hub.docker.com/_/alpine) и устанавливаем [команду для выполнения](https://docs.docker.com/engine/reference/builder/#entrypoint) -`echo "Hello world!"`.

## Сборка контейнера

Чтобы собрать контейнер, выполните следующую команду в терминале:

```
docker build -t first_container:local .
```

Эта команда соберет контейнер с именем `first_container` и тэгом `local` на основе Dockerfile в текущей директории.

## Запуск контейнера

После сборки контейнера Вы можете запустить его с помощью следующей команды:

```
docker run --rm --name my_first_container first_container:local
```

Эта команда запустит контейнер `first_container:local` и выполнит команду, указанную в entrypoint Dockerfil'a.

## Работа с контейнером

После запуска контейнера Вы можете взаимодействовать с ним, открыв терминал внутри контейнера или выполнив команды внутри него. Для этого используйте команду:

```
docker exec -it my_first_container ash
```

Эта команда откроет интерактивный терминал внутри контейнера `my_first_container`.

Но в данном случае, это будет не возможно выполнить, т.к. контейнер после выполнения команды echo - погибает. Для того, что бы запустить в контейнере интерактивную оболочку, потребуется выполнить следующую команду:

```
docker run --rm --entrypoint ash -ti first_container:local
```
