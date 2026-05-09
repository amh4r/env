#!/bin/bash
iostat -c 2 disk0 | tail -n 1 | awk '{printf "%3.0f%%", 100-$6}'
