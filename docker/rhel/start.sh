#!/bin/bash

for i in `/opt/startup/`; do
	bash "$i &"
done

tail -f /dev/null
