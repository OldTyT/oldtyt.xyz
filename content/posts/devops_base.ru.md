---
author: "OldTyT"
title: "База DevOps"
date: "2024-03-13"
description: "Docker best practices"
tags: ["devops", "base"]
categories: ["devops", "base"]
series: ["devops_base"]
aliases: ["devops_base"]
url: "/ru/posts/devops_base/"
ShowToc: true
TocOpen: true
weight: 1
---

Данная статья предназначено для тех, кто только хочет вкатиться в DevOps. Она поможет понять некоторые нюансы.

# Статья находится в активной разработке

# База

* [FHS](https://ru.wikipedia.org/wiki/FHS)
* Знать и уметь рассказать за [top](https://1cloud.ru/help/security/prosmotr-i-upravlenie-protsessami-linux-s-pomoshhyu-top) и [htop](https://linux-bash.ru/menusistem/79-htop.html)(по меньшей мере)
* [cron](https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-ubuntu-1804-ru) (статья не полная, еще можно задать cron через /etc/cron*)
* Уметь в bash(написание каких-то простых скриптов, циклов)
* Уметь в systemd(написание untit'oв, просмотр логов в journalctl)
* Уметь в [траблшутинг](https://youtu.be/9A3QtGMuqvw)
* Пощупать ансибл и погонять сборки локально в [molecule](https://gitlab.com/DevBoxOps/ansible-molecule)(сразу скажу, там заложена ошибка специально, когда сделаешь molecule test ты это увидешь)

2. Продвинутый уровень
* Docker(что это? Зачем? Какие плюсы? Как оптимизировать сборку? Что такое overlay fs? Как работают слои?). Я попытался обяснить про него [тут](https://oldtyt.xyz/ru/posts/docker_for_the_youngest/) и [тут](https://oldtyt.xyz/ru/posts/docker_best_practices/)
* CI/CD
* Prometheus
* Grafana

3. Специфичное
* K8s
* Jenkins
* Python
* GO
* OpenSearch / ELK
* Написание SQL запросов
...
