# da-connect-demo
Some simple demos for Consul Connect, mostly work in progress, but hopefully useful

## Docker
Simple example of running a Connect environment using Docker Compose.  The stack uses SoCat and PostgreSQL to show how you can secure simple Layer 4 services.

[./docker_compose](./docker_compose)

## Kubernetes
A more fully featured example of a small microservice system running in Kubernetes.  This example shows how to register services with Consul as they start as K8s pods, run Connect in a sidecar, and leverage the Go SDK for native integration.


[./kubernetes-azure](./kubernetes-azure)

## Slides
Slide deck showing why a Service Mesh is an important component in todays systems and also how Connect works.

[Keynote](https://github.com/hashicorp/da-connect-demo/tree/master/slides)

## Interactive Learning
We have an interactive tutorial for the Connect basics running in Instruqt, you can follow through the exercises without needing to set up any of your own infrastructure.

[https://play.instruqt.com/hashicorp/tracks/connect](https://play.instruqt.com/hashicorp/tracks/connect)

## Links

HashiDays 2018 Keynote (Mitchell Hashimoto):
[https://www.youtube.com/watch?v=XVD9PoExnRE](https://www.youtube.com/watch?v=XVD9PoExnRE)

HashiDays 2018 Connect Deep-dive (Paul Banks):
[https://youtu.be/KZIu33sbwQQ](https://youtu.be/KZIu33sbwQQ)

