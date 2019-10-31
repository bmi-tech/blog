#!/usr/bin/expect
set timeout 3
set machineURL [lindex $argv 0]
set machinePWD [lindex $argv 1]
spawn /bin/bash -c "scp -r build/html/* $machineURL"
expect ".*continue connecting (yes/no)?"
send "yes\r"
expect "Warning:.*"
expect ".*'s password: "
set timeout 100
send "$machinePWD\r"
expect 100%
set timeout 3
expect eof
