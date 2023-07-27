# Docker Windscribe Image

## About the image

Run a Windscribe VPN instance in docker via the Windscribe CLI tool. This can be used by other containers in the following way:

 1. Set a container to use the Windscribe container network. This way you keep the VPN and the apps using it seprately from one another. It also allows you to use the same VPN connection for multiple containers. 
 
 2. Extend this image and build your application into it. Preparations for this is already included in this image.
 
 3. Launch this image and mount your app directory to `/app` in the container _(#See: Extending the image)_

## Extending the image

To extend this image you simply need to place a single file into the `/app` directory called `app-run.sh`. This file will be executed on container start after the VPN has been configured and started. This file is executed as the `PUID` user. 

You can optionally include `app-init.sh` which is executed before anything else, even before the VPN has been setup. This file is executed as `root` and allows for app configurations before luanch. 

Another optional file is `app-health-check.sh` which is periodically called to check the health state of the app. This should exit with status codes such as `0` for `HEALTHY`. 

### Keep running

When the file `app-run.sh` is available, it becomes it's job to keep the container alive. If the file exists then the container will shut down. This control is passed to the `app-run.sh` to give custom applications full control of the containers lifecicle. 

It is also a good idea to update `/var/run/init.pid` with the correct `pid` that keeps the container running so to allow things like `health check` to signal the process to stop. 

__Example__

You could add something like this to the end of the `app-init.sh` script. 

```sh
trap : TERM INT; sleep infinity & echo $! > /var/run/init.pid; wait
```

## Usage

### docker

```
docker create \
  --name=docker-windscribe \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e WINDSCRIBE_USERNAME=username \
  -e WINDSCRIBE_PASSWORD=password \
  -e WINDSCRIBE_PROTOCOL=stealth \
  -e WINDSCRIBE_PORT=80 \
  -e WINDSCRIBE_PORT_FORWARD=9999 \
  -e WINDSCRIBE_LOCATION=US \
  -e WINDSCRIBE_LANBYPASS=on \
  -e WINDSCRIBE_FIREWALL=on \
  -e VPN_PORT=8080
  -v /location/on/host:/app \
  --dns 1.1.1.1 \
  --cap-add NET_ADMIN \
  --restart unless-stopped \
  dk-zero-cool/docker-windscribe:latest
```


### docker-compose

```
---
version: "2.1"
services:
  docker-windscribe:
    image: dk-zero-cool/docker-windscribe:latest
    container_name: docker-windscribe
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - WINDSCRIBE_USERNAME=username
      - WINDSCRIBE_PASSWORD=password
      - WINDSCRIBE_PROTOCOL=stealth
      - WINDSCRIBE_PORT=80
      - WINDSCRIBE_LOCATION=US
      - WINDSCRIBE_LANBYPASS=on
      - WINDSCRIBE_FIREWALL=on
      - VPN_PORT=9999
    volumes:
      - /location/on/host:/app
    dns:
      - 1.1.1.1
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above).

| Parameter | Examples/Options | Function |
| :----: | --- | --- |
| PUID | 1000 | The nummeric user ID to run the application as, and assign to the user docker_user |
| PGID | 1000 | The numeric group ID to run the application as, and assign to the group docker_group |
| TZ=Europe/London | The timezone to run the container in |
| WINDSCRIBE_USERNAME | username | The username used to connect to windscribe |
| WINDSCRIBE_PASSWORD | password | The password associated with the username |
| WINDSCRIBE_PROTOCOL | stealth OR tcp OR udp | The protocol to use when connecting to windscribe, which must be on 'windscribe protocol' list |
| WINDSCRIBE_PORT | 443, 80, 53 | The port to connect to windscribe over, which must be on 'windscribe port' list for that protocol |
| WINDSCRIBE_LOCATION | US | The location to connect to, which must be on 'windscribe location' list |
| WINDSCRIBE_LANBYPASS | on, off | Allow other applications on the docker bridge to connect to this container if on |
| WINDSCRIBE_FIREWALL | on, off | Enable the windscribe firewall if on, which is recommended. |
| VPN_PORT | 9898 | The port you have configured to forward via windscribe. Not used by this container, but made available |

## Volumes

| Volume | Function |
| :----: | --- |
| /app | The home directory of docker_user `PUID` |

## Building locally

```
git clone https://github.com/dk-zero-cool/docker-windscribe.git
cd docker-windscribe
docker build \
  --no-cache \
  -t dk-zero-cool/docker-windscribe:latest .
```
