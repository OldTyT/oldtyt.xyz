---
author: "OldTyT"
title: "Как я запускал minecraft в kubernetes"
date: "2023-10-07"
description: "Minecraft в kubernetes."
tags: ["kubernetes", "майнкрафт", "опыт", "файл", "нода", "проблема", "решение", "traefik", "cron", "данные", "задача", "DevOps"]
categories: ["kubernetes", "minecraft"]
series: ["kubernetes"]
aliases: ["minecraft_in_kubernetes"]
ShowToc: true
TocOpen: true
weight: 1
url: "/ru/posts/minecraft_in_kubernetes/"
---

# Minecraft в kubernetes

Всем привет, в этой статье я поделюсь своим опытом запуска Minecraft в kubernetes.

Основная проблема, возникающая при попытке запустить Minecraft в Kubernetes, заключается в том, что во время работы Minecraft происходит работа с файлами на локальном диске, а такой подход в Kubernetes является нежелательным, поскольку в случае сбоя ноды (назовем его нода A), на которой развернут под - под не сможет быть создан на другой ноде (нода B), так как известно, что под ранее работал на ноде A и, соответственно, все его постоянные файлы находятся там.

## Варианты решения проблем с использованием постоянных файлов

В поисках решения этой проблемы, я определил возможные методы решения:
* отказ от постоянных файлов
* использовать Persistent Volume
* создать сетевой диск
* использовать [csi-s3](https://cloud.yandex.com/en/docs/managed-kubernetes/operations/volumes/s3-csi-integration)

Давайте подробнее рассмотрим каждый из вариантов

### Отказ от постоянных файлов

Плюсы:
* Работает нативно
* Это лучшее решение, т.к. не будет проблем с пересозданием пода на другой ноде в случае сбоя

Минусы:
* Не применимо к текущему приложению

### Использовать Persistent Volume

Плюсы:
* Высокая скорость чтения/записи файлов

Минусы:
* Все данные находятся на одной ноде, в случае его поломки pod не сможет подняться

### Создать сетевой диск

Плюсы:
* Данные реплицируются на несколько нод

Минусы:
* Более низкая скорость чтения/записи файлов

### Использовать csi-s3

Плюсы:
* Данные не находятся в кластере

Минусы:
* Более низкая скорость чтения/записи файлов
* Из-за большого количества вызовов API может получиться высокая цена

## Анализ вариантов

Основываясь на полученных данных, мы приходим к выводу, что на данный момент не существует решения, которое могло бы соответствовать нашим требованиям, а именно:
* высокая скорость чтения/записи файлов
* не должно быть привязки к определенной ноде
* минимальные затраты на реализацию данного функционала

## Решение проблемы с использованием постоянных данных

Чтобы решить эту проблему, был подготовлен [docker контейнер](https://github.com/OldTyT/docker_minecraft).

### Алгоритм работы контейнера

1. Добавляются SSH-ключи. Ключи берутся из значений переменных ENV
2. Репозиторий сервера клонируется из git с конфигурацией сервера в каталог - `/app`
3. Последовательности `MYSQL_.+` заменяются во всех файлах в `/app/plugins` на их значение ENV
4. Игровой мир копируется из хранилища s3 и распаковывается
5. Игровые плагины и ядро копируются из хранилища s3
6. Начинается `/task_manager.py ` - который отвечает за выполнение задач `cron`, работу сервера и вывод `syslog`

#### Cron задачи

В задачах cron в настоящее время настроены следующие задачи:

```
* * * * * root /git_pull.sh | logger
* * * * * root /git_commit.sh | logger
0 * * * * root /copy_worlds.sh | logger
```

Информация по каждой задаче:

* `/git_pull.sh` - выполняет `git pull` в каталоге `/app`
* `/git_commit.sh ` - создает commit и отправляет его в репозиторий
* `/copy_worlds.sh` - создает копию мира и загружает ее в хранилище s3 вместо существующей

## Пример развертывания службы

### Настройка `ingress` контроллера

Рассмотрим пример с `traefik`. Чтобы настроить `ingres` контроллер, вам нужно будет выполнить следующую команду:

```shell
$ helm upgrade --values traefik-values.yaml traefik traefik/traefik -n kube-system
```

Контент файла `traefik-values.yaml`:

```yaml
ports:
  traefik:
    port: 9000
    expose: false
    exposedPort: 9000
    protocol: TCP
  web:
    port: 8000
    expose: true
    exposedPort: 80
    protocol: TCP
  minecraft:
    port: 22565
    expose: true
    exposedPort: 25565
    protocol: TCP
  websecure:
    port: 8443
    expose: true
    exposedPort: 443
    protocol: TCP
    http3:
      enabled: false
    tls:
      enabled: true
      options: ""
      certResolver: ""
      domains: []
    middlewares: []
  metrics:
    port: 9100
    expose: false
    exposedPort: 9100
    protocol: TCP
```

После этого подключения к `LoadBalancer` будут разрешены через порт `25565`

```shell
$ kubectl get svc -n kube-system | grep -v "none"
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
traefik              LoadBalancer   10.43.2.50      100.10.0.11   25565:30224/TCP,80:31380/TCP,443:30226/TCP   2d21h
```

### Deploy

Пример окончательного манифеста, содержащего требуемую конфигурацию:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: minecraft
---
apiVersion: v1
kind: Secret
metadata:
  name: minecraft-secret
  namespace: minecraft
type: Opaque
data:
  SSH_KEY_PUBLIC: "SECRET"
  SSH_KEY_PRIVATE: "SECRET"
  MYSQL_ROOT_PASSWORD: "SECRET"
  MYSQL_DBS: "SECRET"
  MYSQL_HOST: "SECRET"
  MYSQL_USER: "SECRET"
  MYSQL_PASSWORD: "SECRET"
  S3_BUCKET: "SECRET"
  S3_ACCESS_KEY: "SECRET"
  S3_ACCESS_KEY_ID: "SECRET"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: some_worlds_name
  namespace: minecraft
spec:
  selector:
    matchLabels:
      app: some_worlds_name
  strategy:
    type: Recreate
  template:
    metadata:
      namespace: minecraft
      labels:
        app: some_worlds_name
    spec:
      imagePullSecrets:
      - name: github-registry
      containers:
      - image: ghcr.io/oldtyt/docker_minecraft
        imagePullPolicy: Always
        name: some_worlds_name
        resources:
          requests:
            cpu: 1000m
            memory: 5G
          limits:
            memory: 6G
            cpu: 1200m
        env:
          - name: XMX
            value: "5G"
          - name: "XMS"
            value: "512M"
          - name: MYSQL_HOST
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: MYSQL_HOST
          - name: MYSQL_USER
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: MYSQL_USER
          - name: MYSQL_DB
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: MYSQL_USER
          - name: MYSQL_PASSWORD
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: MYSQL_PASSWORD
          - name: S3_BUCKET
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: S3_BUCKET
          - name: S3_ACCESS_KEY
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: S3_ACCESS_KEY
          - name: S3_ACCESS_KEY_ID
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: S3_ACCESS_KEY_ID
          - name: SSH_KEY_PRIVATE
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: SSH_KEY_PRIVATE
          - name: SSH_KEY_PUBLIC
            valueFrom:
              secretKeyRef:
                name: minecraft-secret
                key: SSH_KEY_PUBLIC
          - name: PLUGINS_LIST
            value: "some,plugins,list"
          - name: GIT_REPO
            value: "git@github.com:USER/REPO.git"
          - name: KERNEL
            value: "KERNEL"
          - name: "WORLDS"
            value: "some_worlds_name"
---
apiVersion: v1
kind: Service
metadata:
  name: some_worlds_name
  namespace: minecraft
  labels:
    env: prod
    app: some_worlds_name
    owner: OldTyT
spec:
  ports:
  - name: minecraft
    targetPort: 25565
    port: 25565
    protocol: TCP
  selector:
    app: some_worlds_name
```

Команда для развертывания манифеста:

```shell
$ kubectl apply -f minecraft.yaml
```

<!--more-->