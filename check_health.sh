#!/bin/bash

# Simple script to check the health of a created droplet
fail_count=1

while true
do
  response=$(curl --write-out %{http_code} --silent --output /dev/null $1)

  if [ $response -eq 200 ] ; then
    echo "$(date -u) Server available"
    # wait for loadbalancer to register

    echo "$(date -u) Waiting for ASG to register with LB"
    sleep 60

    exit 0
  else
    if [ $fail_count -eq 201 ]; then
      echo "$(date -u) Server unavailable"
      exit 2
    else
      echo "$(date -u) Attempt ${fail_count}/200: Server not yet available"
      sleep 3
      fail_count=$[$fail_count +1]
    fi
  fi
done