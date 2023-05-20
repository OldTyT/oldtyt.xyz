FROM ghcr.io/oldtyt/hugo-docker
ARG BASEURL=https://oldtyt.xyz
ENV BASEURL=$BASEURL
COPY . /app

