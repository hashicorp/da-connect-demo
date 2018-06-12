#! /bin/bash -e

socat -v tcp-l:8080,bind=127.0.0.1,fork exec:"/bin/cat" 2>"$TMPDIR/service1.out" &
consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl
