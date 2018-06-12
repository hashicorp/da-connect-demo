# Docker Compose Demo
This is a simple demo showing command line operations of Consul Connect using Docker containers

## Setup
1. Install Docker
2. Download the consul binary with connect from the private docs: (https://s3.us-east-2.amazonaws.com/consul-dev-artifacts/consul-connect/1.2.0-beta2/consul_1.2.0-beta2_linux_amd64.zip)[https://s3.us-east-2.amazonaws.com/consul-dev-artifacts/consul-connect/1.2.0-beta2/consul_1.2.0-beta2_linux_amd64.zip] and save to this location
3. Build the base docker image (this probably only needs to be done once `docker build -t consul_connect:latest .`
4. Start the various services `docker-compose -p connect up`

## Services
Docker Compose will start 4 different containers:
1. Consul Server
2. Service1 - socat echo service
3. Service2 - socat echo service
4. Service3 - socat echo service
5. Docker network for the 4 containers

All netcat echo services are bound to localhost and are not accessible via Docker Networking
```bash
socat -v tcp-l:8080,bind=127.0.0.1,fork exec:"/bin/cat" 2>"$TMPDIR/service.out" &
```

The intention is to show how both `Service2` and `Service3` can register upstreams with the Consul in order to communicate with `Service1` via the Connect proxy.  By default the connect intentions do not allow any communication even though both `Service2` and `Service3` have registered `Service1` as an upstream.  We can show how intentions can be set to allow communication from `Service2` but not `Service3`.

## Show connect is running and a root certificate has been created
Consul is running as 8500 inside the container but this is mapped to 8501 outside of docker

```bash
curl -s 'http://127.0.0.1:8501/v1/agent/connect/ca/roots' | jq
```


## Show netcat connecting to `Service1` locally
1. Create a shell for the docker container

```bash
docker exec -it connect_Service1_1 /bin/bash
```

2. Connect to the service and show the echo

```bash
nc localhost 8080
hello
hello
```

## Show that it is not possible to connect from `Service2`
1. Create a shell for the docker container

```bash
docker exec -it connect_Service2_1 /bin/bash
```

2. Connect to the service and show the echo does not work

```bash
nc Service1 8080
```

## Start the Connect proxy on Service1

We are registering a service on port 8080 with no upstreams, the bind_port for the connect proxy is port `443`

```json
{
  "name": "service1",
  "port": 8080,
  "connect": {
    "proxy": {
      "config": {
        "bind_port": 443
      }
    }
  }
}
```

From the `Service1` docker shell
```bash
curl -s -X PUT -d @/service.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

You will see this registered in the service catalog and connect 
```bash
curl -s "http://localhost:8500/v1/health/connect/service1" | jq
```

## Start the Connect proxy for `Service2`

We are registering a service on port 8080 again the bind port is `443` however this time we are registering an upstream called `service1` on port `9191`, this will allow us to contact the socat service in the `Service1` container 

```json
{
  "name": "service2",
  "port": 8080,
  "connect": {
    "proxy": {
      "config": {
        "bind_port": 443,
        "upstreams": [{
            "destination_name": "service1",
            "local_bind_port": 9191
        }]
      }
    }
  }
}
```

**TODO** Intentions are currently allow all, this needs to be changed


From the `Service2` docker shell
```bash
curl -s -X PUT -d @/service.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

You will see this registered in the service catalog and connect 
```bash
curl -s "http://localhost:8500/v1/health/connect/service2" | jq

```
2. Connect to the service and show the echo works

```bash
nc localhost 9191
```

## TODO
[ ] Add intentions and show denied intention with `Service3`
[ ] Add real PostgreSQL database
[ ] Show using `ngrep` traffic is secured with TLS
