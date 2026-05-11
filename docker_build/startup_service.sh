#! /bin/sh -e
# Copyright IBM Corp. 2018, 2026


socat -v tcp-l:8080,bind=127.0.0.1,fork exec:"/bin/cat" 2>"$TMPDIR/service1.out" &
consul agent -config-dir /etc/consul.d 
