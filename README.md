# docker-nagios v4.1.1 (plugins 2.1.1)

Simple docker container with [Nagios](http://nagios.org) built on [phusion/baseimage-docker](https://github.com/phusion/baseimage-docker).

#### Build

##### (Source)
````bash
git clone https://github.com/nmarus/docker-nagios.git
cd docker-nagios
docker build --rm -t nmarus/docker-nagios .
````

##### (Docker Hub)
````bash
docker pull nmarus/docker-nagios
````

#### Run
````bash
docker run -d -p 80:80 --name docker-nagios nmarus/docker-nagios
````

#### Admin
Open browser to `http://hostname`

