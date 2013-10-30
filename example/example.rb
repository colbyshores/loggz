#!/usr/bin/env ruby
require 'loggz'

example = Loggz.new
#configuration
example.redis_ip = "localhost"
example.redis_password = ""
example.redis_port = 6379
#display verbose output
example.verbose = true
#path to where the file is located(ie /mnt/nfs/Edgecast)  It MUST have a trailing slash
example.file_path = "/path/to/where/the/logs/are/"
#this will determine what keystore to send to reddis based on the first few matching characters
example.file_type_flag = "example"
#keystore is what is stored in redis according to the file type being parsed
example.keystore = "example_key"
#if the first line contains data about the log, then skip it
example.skip_first_line=true

#make sure the next admin who checks out this system process knows where it is and how to remove it from startup
puts "initiating /usr/sbin/loggz_" + example.file_type_flag + ".rb process.\n This takes the logs from the cdn folder:" + example.file_path + "\n"
puts "and moves them to the redis server " + example.redis_ip + "\n"
puts "If you need to remove this process from startup,\nedit the entry from /etc/init.d/before.local\n"

#run process
Process.daemon
example.sendtoredis
