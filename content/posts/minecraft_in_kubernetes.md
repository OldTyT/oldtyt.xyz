---
author: "OldTyT"
title: "How I launched minecraft in kubernetes"
date: "2023-06-05"
description: "Minecraft in kubernetes."
tags: ["kubernetes", "minecraft", "skills"]
categories: ["kubernetes", "syntax"]
series: ["kubernetes"]
aliases: ["minecraft_in_kubernetes"]
ShowToc: true
TocOpen: true
weight: 1
---

# Minecraft in kubernetes

Hello everyone, in this article I will share with you my experience in launching minecraft in kubernetes.

The main problem that arises when trying to launch minecraft in kubernetes is that while minecraft is running, files are being worked on on the local disk, and this approach in kubernetes is anti-pathetic, since in case of failure of the node (let's call it node A) on which the pod was deployed - pod will not be able to be created on another node (node B), since it is known that pod previously worked on node A and, accordingly, all its permanent files are there.

## Options for solving problems with the use of permanent files

While searching for a solution to this problem, I identified the following solutions for myself:
* rejection of permanent files
* use native Persistent Volume
* create a network drive
* use [csi-s3](https://cloud.yandex.com/en/docs/managed-kubernetes/operations/volumes/s3-csi-integration)

Let's take a closer look at each of the options

### Abandoning permanent files

Positive:
* The best solution for applications in kubernetes

Minuses:
* Not applicable to the current application

### Use Native Persistent Volume

Positive:
* High speed of reading/writing files

Minuses:
* All data is on the same node, in case of its breakdown, the pod will not be able to rise

### Create a network drive

Positive:
* The data is replicated to multiple nodes

Minuses:
* Low file read/write speed

### Use csi-s3

Positive:
* The data was taken out from the cluster

Minuses:
* Low file read/write speed
* An extremely high price may come out due to the large number of API calls

## Analysis of options

Based on the data obtained, we come to the conclusion that at the moment, there is no solution that could meet our requirements, namely:
* high speed of reading / writing files
* there must be no binding to a specific node
* it should be done as budget-friendly as possible

## Solving the problem using persistent data

To solve this problem, was prepared [docker container](https://github.com/OldTyT/docker_minecraft).

### The algorithm of the container

1. SSH keys are being added. The keys are taken from the values of the ENV variables.
2. The repository is cloned from github with the server configuration to the directory - `/app`
3. The sequences `MYSQL_.+` are replaced in all files in `/app/plugins` by their value.
4. The game world is being copied from s3 storage and unpacked
5. Game plugins and kernel are being copied from s3 storage
6. Starts `/task_manager.py ` - which is responsible for the execution of `cron` tasks, the operation of the server and the output of `syslog`

#### Cron tasks

In cron tasks, the following tasks are currently configured:

```
* * * * * root /git_pull.sh | logger
* * * * * root /git_commit.sh | logger
0 * * * * root /copy_worlds.sh | logger
```

Learn more about each task:

* `/git_pull.sh` - executes `git pull` in the `/app` directory
* `/git_commit.sh ` - creates a commit and pushes it to the repository
* `/copy_worlds.sh` - makes a copy of the world and uploads it to s3 storage in place of the existing one

## Example of service deployment

### Setting up the `ingress` controller

Consider the example of `traffic'. To configure the `ingress` controller, you will need to run the following command:

```shell
$ helm upgrade --values traefik-values.yaml traefik traefik/traefik -n kube-system
```

Contents of the `traefik-values.yaml` file:

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

After that, connections to `LoadBalancer` will be allowed on port `25565`:

```shell
$ kubectl get svc -n kube-system | grep -v "none"
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
traefik              LoadBalancer   10.43.2.50      100.10.0.11   25565:30224/TCP,80:31380/TCP,443:30226/TCP   2d21h
```

### Deploy

Example of the final manifest that contains the required configuration:

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

The command to deploy the manifest:

```shell
$ kubectl apply -f minecraft.yaml
```

<!--more-->