for ip in 10.0.{0..255}.{0..255}; do for port in {0..20000}; do timeout 1 bash -c "echo  > /dev/tcp/${ip}/${port}" $> /dev/null && echo "server ${ip} port ${port} open"; done; done

