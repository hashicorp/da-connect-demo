# Docker Compose Demo
This is a simple demo showing command line operations of Consul Connect using Docker containers

## Setup
1. Install Docker
2. Download the consul binary with connect from the private docs: [Connect Binary for Linux](https://s3.us-east-2.amazonaws.com/consul-dev-artifacts/consul-connect/1.2.0-beta2/consul_1.2.0-beta2_linux_amd64.zip) and save to this location
3. Build the base docker image (this probably only needs to be done once `docker build -t consul_connect:latest .`
4. Start the various services `docker-compose -p connect up`

## Services
Docker Compose will start 4 different containers:
1. Consul Server - with connect
2. Service1 - socat echo service bound to localhost 8080
3. Service2 - socat echo service bound to localhost 8080
4. Postgres SQL - bound to localhost 5432
5. Docker network for the 4 containers

* All netcat echo services are bound to localhost and are not accessible via Docker Networking
```bash
socat -v tcp-l:8080,bind=127.0.0.1,fork exec:"/bin/cat" 2>"$TMPDIR/service.out" &
```

* The Postgres service is also only bound to listen to localhost and is not accessible via Docker Networking.

* Shells can be obtained for any of the containers by running the following command:
```bash
docker exec -it connect_[container]_1 /bin/bash
// e.g. docker exec -it connect_Service1_1 /bin/bash
// e.g. docker exec -it connect_Service2_1 /bin/bash
// e.g. docker exec -it connect_Postgres_1 /bin/bash
```

## Show connect is running and a root certificate has been created
Consul is running as 8500 inside the container but this is mapped to 8501 outside of docker, the following command will show the root certificate which has automatically been generated for the Connect CA.

```bash
curl -s 'http://127.0.0.1:8501/v1/agent/connect/ca/roots' | jq
```

## Attempt to connect to Service2 from the Service1 container
Without connect it is not possible to reach `Service2` from `Service1`, while there is a network route, `Service2` is bound to localhost and will not accept any connections from `Service1`.  In production this could be further hardened by using network routes which restrict any network traffic other than between Connect proxies.

**From `Service1` shell
```bash
nc Service2 8080
Service2: forward host lookup failed: Unknown host
```

## Start the Connect proxy on Service1
In order to communicate with Service2 we can use Connect, connect runs as a point to point proxy securing both traffic via SSL and M/TLS, in order to use Connect we need to start the proxies.

We are registering a service on `localhost` port `8080` with an upstream to `service2`, the `service2` upstream started by the proxy will bind to `localhost` port `9191`.  The connect traffic port is defined by the `bind_port` setting and this is set to a value of `443`.

```json
{
  "name": "service1",
  "port": 8080,
  "connect": {
    "proxy": {
      "config": {
        "bind_port": 443,
        "upstreams": [
          {
            "destination_name": "service2",
            "local_bind_port": 9191
          }
        ]
      }
    }
  }
}
```

**Using the `Service1` docker shell**
```bash
curl -s -X PUT -d @/servicea.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

You will see this registered in the service catalog and connect 
```bash
curl -s "http://localhost:8500/v1/health/connect/service1" | jq
```

## Start the Connect proxy for `Service2`

For connect to work we also need to start a proxy on `Service2`, we are not defining any upstreams for this service.

```json
{
  "name": "service2",
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

**From the `Service2` docker shell**
```bash
curl -s -X PUT -d @/service.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

You will see this registered in the service catalog and connect 
```bash
curl -s "http://localhost:8500/v1/health/connect/service2" | jq
```

## Start `ngrep` to show traffic received on `Service2` in a separate shell

```
ngrep -d any port 8080 or 443
```

Connect routes the request from `localhost` port `9191` on the `Service1` container to port `443` on the `Service2` container, you will see in the shell running `ngrep` that traffic has been received on port `443` and that this traffic is encrypted.  The connect proxy running on `Service2` now routes the encrypted traffic to `localhost` port `8080` as plain traffic.  In addition to SSL, Mutual Authentication is also securing the two proxies.

```bash
root@a5013bd3948a:/# ngrep -d any port 8080 or 443
interface: any
filter: ( port 8080 or 443 ) and (ip || ip6)
#
T 172.21.0.2:52128 -> 172.21.0.4:443 [AP] #1
  ........................M....Q...k.                                                                                                        
#
T 127.0.0.1:40376 -> 127.0.0.1:8080 [AP] #2
  hello.                                                                                                                                     
#
T 127.0.0.1:8080 -> 127.0.0.1:40376 [AP] #3
  hello.                                                                                                                                     
##
T 172.21.0.4:443 -> 172.21.0.2:52128 [AP] #5
  ...............X... "...R..1.%|':J.                                                                                                        
```

## Using Connect to secure database traffic 
Connect does not just work with Services it can also be used to secure database traffic, we have a database server running in container `postgres`, currently this is only listening to localhost and is not accessible directly from `Service1`.

**From the Service1 shell**
```
PGPASSWORD=postgres psql -U postgres -h postgres
psql: FATAL:  pg_hba.conf rejects connection for host "172.21.0.5", user "postgres", database "postgres", SSL off
```

We need to register the connect proxy on the `Postgres` server, this is going to register the postgres service listening on `localhost` port `5432` and expose the connect proxy port `443`:

```json
{
  "name": "postgres",
  "port": 5432,
  "connect": {
    "proxy": {
      "config": {
        "bind_port": 443
      }
    }
  }
}
```

**From the `Postgres` docker shell**
```bash
curl -s -X PUT -d @/service.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

To communicate with the database we also need to register a new upstream which maps the local port `5432` to the connect proxy running on the `Postgres` server on the `Server1` instance.

```json
{
  "name": "service1",
  "port": 8080,
  "connect": {
    "proxy": {
      "config": {
        "bind_port": 8443,
        "upstreams": [
          {
            "destination_name": "service2",
            "local_bind_port": 9191
          },
          {
            "destination_name": "postgres",
            "local_bind_port": 5432
          }
        ]
      }
    }
  }
}
```

**From the `Service1` docker shell**
```bash
curl -s -X PUT -d @/serviceb.json "http://127.0.0.1:8500/v1/agent/service/register" | jq
```

We should now be able to connect to the postgres server from `Server1` using the proxy port `5432`, connect will again route the traffic from `localhost:5432` to the connect proxy running on the `Postgres` server at port `443`, this will in turn be routed to `localhost:5443` on the `Postgres` server.  All traffic is again secured by TLS and M/TLS.

```bash
PGPASSWORD=postgres psql -U postgres -h localhost
psql (10.4 (Ubuntu 10.4-0ubuntu0.18.04))
Type "help" for help.

postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(3 rows)

postgres=#
```

## Intentions
Intentions define access control for services via Connect and are used to control which services may establish connections. Intentions can be managed via the API, CLI, or UI.

Lets create an intention which denies all traffic
**From `Server` shell**
```
consul intention create -allow '*' '*'
```

```bash
consul intention get '*' '*'

Source:       *
Destination:  *
Action:       deny
ID:           b63e5f43-36f4-8636-3e0d-0184a0cbb4ae
Created At:   Thursday, 14-Jun-18 11:52:35 UTC
Created: * => * (deny)
```

When we attempt to connect to `Service2` via the connect proxy this time the server no longer responds:

**From `Service1` shell**
```bash
nc localhost 9191
hello
```

To enable the communication we can define an intention which allows `Service1` to communicate with `Service2`:
```bash
consul intention create -allow service1 service2
Created: service1 => service2 (allow)
```

It is also possible to show the details for the intention using the following command:
```bash
consul intention get service1 service2
Source:       service1
Destination:  service2
Action:       allow
ID:           de933b1b-a7b8-7260-ea7f-0dd47952f4d5
Created At:   Thursday, 14-Jun-18 11:14:15 UTC
```

When we again try the connection the service is now accessible:

```bash
nc localhost 9191
hello
hello
```

To re-enable communication to the database we can create another intention

**From `Service1` shell**
```bash
consul intention create -allow service1 postgres
Created: service1 => postgres (allow)
```
