---
author: "OldTyT"
title: "Docker for the youngest"
date: "2023-10-08"
description: "Docker for the youngest"
tags: ["docker", "container", "development", "application", "dockerfile", "base", "DevOps", "docker"]
categories: ["docker"]
series: ["docker"]
aliases: ["docker_for_the_youngest"]
ShowToc: true
TocOpen: true
weight: 1
---

To consolidate the material, it is recommended to execute the commands specified in the article

## Introduction

Docker is a platform for developing, delivering, and running applications in containers. Containers are lightweight and isolated environments that allow you to run applications on any operating system without the need for additional dependencies. In this article, we will explore the basics of Docker and demonstrate how to use it for application development.

## Installing Docker

Before you can start using Docker, you need to install it on your system. Follow the instructions on the official Docker website [Docker](https://docs.docker.com/engine/install/) for detailed instructions for various operating systems.

## Creating a Container

After installing Docker, you are ready to create your containers. To do this, you will need a Dockerfile that describes the steps to create the container. Here is an example of a simple Dockerfile:

```Dockerfile
FROM alpine:latest
ENTRYPOINT ["echo", "Hello world!"]
```

In this example, we use the base image [Alpine](https://hub.docker.com/_/alpine) and set the [entrypoint command](https://docs.docker.com/engine/reference/builder/#entrypoint) to `echo "Hello world!"`.

## Building the Container

To build the container image, execute the following command in the terminal:

```
docker build -t first_container:local .
```

This command will build a container image named `first_container` with the tag `local` based on the Dockerfile in the current directory.

## Running the Container

After building the container, you can run it using the following command:

```
docker run --rm --name my_first_container first_container:local
```

This command will run the `first_container:local` container and execute the command specified in the Dockerfile's entrypoint.

## Working with the Container

After running the container, you can interact with it by opening a terminal inside the container or executing commands within it. To do this, use the command:

```
docker exec -it my_first_container ash
```

This command will open an interactive terminal inside the `my_first_container` container.

But in this case, it will not be possible to execute, as the container dies after executing the echo command. To launch an interactive shell in the container, the following command needs to be executed:

```
docker run --rm --entrypoint ash -ti first_container:local
```
