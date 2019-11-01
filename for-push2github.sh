#!/usr/bin/expect
set timeout 3
set githubURL [lindex $argv 0]
set githubUser [lindex $argv 1]
set githubPWD [lindex $argv 2]
spawn git remote add github $githubURL
spawn git push -f github remotes/origin/master:master
set timeout 10
expect "Username for 'https://github.com':"
send "$githubUser\r"
set timeout 10
expect "Password for 'https://bmi-tech@github.com':"
set timeout 1000
send "$githubPWD\r"
expect "*To https://github.com/bmi-tech/blog.git"
expect "*master -> master"
set timeout 3
expect eof
