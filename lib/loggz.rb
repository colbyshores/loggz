require 'rubygems'
require 'redis'
require 'open-uri'
require 'open3'

class Loggz
  attr_accessor :redis_ip
  attr_accessor :redis_password
  attr_accessor :redis_port
  attr_accessor :verbose
  attr_accessor :file_path
  attr_accessor :file_type_flag
  attr_accessor :keystore
  attr_accessor :skip_first_line

  #move config options in to the object
  def initialize()
    @redis_ip = redis_ip
    @redis_password = redis_password
    @verbose = verbose
    @file_path = file_path
    @file_type_flag = file_type_flag
    @keystore = keystore
    @skip_first_line = skip_first_line
  end

  def sendtoredis
    #zcat_type is the type of zcat to use.  OSX and older systems use gzcat
    host_os = RbConfig::CONFIG['host_os']
    case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        puts "only compatible with Linux, Unix and OSX"
        exit(1)
      when /darwin|mac os/
        zcat_type = "gzcat"
      when /linux/
        zcat_type = "zcat"
      when /solaris|bsd/
        zcat_type = "gzcat"
      else
        puts "unknown os: #{host_os.inspect}"
        puts "only compatible with Linux, Unix and OSX"
        exit(1)
    end

    #spawn the redis object
    if redis_password != "" then
      redis_object = Redis.new(:host => redis_ip, :port => redis_port, :password => redis_password)
    else
      redis_object = Redis.new(:host => redis_ip, :port => redis_port)
    end if

    file = Dir.glob(file_path + file_type_flag + "*").max_by {|f| File.mtime(f)}

    #create a new array called log_input
    log_input = []

    #file has just been parsed, reset the new file to match that for the conditional
    file_new = file
    while true do
      if file_new != file  
        if File.extname(file_new) == ".gz" then
          #parse the first letters of the log file
          #this will determine what keystore to send to reddis based on the first few matching characters

          #This is a patch I implemented on 10/28, extract only the file_type_flag for the file type 
          file_type = file_new[0, file_path.length + file_type_flag.length]
          file_type.slice!(0, file_path.length)

          #if file_type matches the extention crieteria then proceeed
          if file_type != file_type_flag then
            sleep 0
            else
              #zcat_type is the type of zcat to use.  OSX and older systems use gzcat
              unzip = `#{zcat_type + " " + file_new}`
              #I need to take the array and push it to redis
              log_input = unzip.split("\n")
              #remove the first array element as that is just log definitions
	      if skip_first_line == true then log_input.shift end

              #the next few lines are experimental!!!!!!
              #the next line checks to see if the last element in log_input matches the content stored the last element that was logged in to redis
              #This is to prevent multiple ftp servers from logging the same information before pushing the string array of new logs
              #to the redis server.  lindex returns the content from redis, keystore is the key name, llen is the redis list total and - 1 is to account for array element 0
              if log_input.last != redis_object.lindex(keystore, redis_object.llen(keystore) - 1) then
                log_input.each do |log_input|
                  #this redis object may require debugging
                  redis_object.rpush(keystore,log_input)
                  #put verbose output
                  if verbose == true then puts "\nkeyname: " + keystore + "\n" + log_input + "\n\n" end
                end
              end

              file = Dir.glob(file_path + file_type_flag + "*").max_by {|f| File.mtime(f)}
            end
            #Remove all array elements by relying on garbage collection
            log_input = []
          else
            #if the file does not end with .gz and do not start with the result of file_type_flag, ignore and keep on trucking
            sleep 0
        end
      end
      #compare new file to old file names
      file_new = Dir.glob(file_path + file_type_flag + "*").max_by {|f| File.mtime(f)}
      #force the process to sleep so it doesnt suck up cpu cycles running this command
      sleep 1
    end
  end
end
