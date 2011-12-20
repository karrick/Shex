require "fileutils"
require "Shex/version"

module Shex

  ########################################
  # module constant below is set at load time
  ########################################

  HOSTNAME = %x(hostname -s).strip

  ########################################
  # api
  ########################################

  def self.directory?(pathname, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    shex("test -d #{pathname}", options)[:okay]
  end

  def self.file?(pathname, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    shex("test -e #{pathname}", options)[:okay]
  end

  def self.shex(command, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    result = nil
    begin
      stdin_saved  = $stdin.dup
      stdout_saved = $stdout.dup
      stderr_saved = $stderr.dup

      with_temp do |temp_stdin|
        if options[:stdin]
          File.open(temp_stdin,"w") {|io| io.write options[:stdin]}
          $stdin.reopen(temp_stdin,"r")
        end

        with_temp do |temp_stdout|
          $stdout.reopen(temp_stdout,"w")

          with_temp do |temp_stderr|
            $stderr.reopen(temp_stderr,"w")

            result = {:okay => system(noop(command,options))}
            result.update(:status => $?.exitstatus)
            result.update(:stdout => File.read(temp_stdout))
            result.update(:stderr => File.read(temp_stderr))
          end
        end 
     end
    rescue
      stderr_saved.puts $!
      raise $!
    ensure
      $stdin.reopen(stdin_saved)
      $stdout.reopen(stdout_saved)
      $stderr.reopen(stderr_saved)
    end
    result
  end

  def self.shex!(command, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    result = shex(command, options)
    if not result[:okay]
      error_message = options[:emsg] || "error #{result[:status]}: #{command}"
      error_class = options[:eclass] || RuntimeError
      raise(error_class, "#{error_message}#{$/}#{result[:stderr]}#{$/}")
    end
    result
  end

  ################

  def self.install(source, dest, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    raise sprintf("missing source file: %s", source) unless File.exists?(source)

    permissions = "-m #{options[:permissions]}" if options[:permissions]
    owner = "-o #{options[:owner]}" if options[:owner]
    group = "-g #{options[:group]}" if options[:group]
    suffix = "-S .#{options[:suffix]}" if options[:suffix]

    hostname = options[:host]
    with_temp(options.merge(:user => nil)) do |temp|
      if ! is_localhost?(hostname)
        scp(source, sprintf("%s:%s", hostname, temp))
        source = temp
      end
      shex!("install #{suffix} #{permissions} #{owner} #{group} #{source} #{dest}", options)
    end
  end

  def self.move_directory_clobber(source, dest, options={})
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)

    # TODO: backup and restore if exception raised

    if directory?(source, options)
      if directory?(dest, options)
        shex!("rm -rf #{dest}", options)
      end
      suffix = "-S .#{options[:suffix]}" if options[:suffix]
      shex!("mv #{suffix} #{source} #{dest}", options)
    else
      raise "error: missing #{options[:host]}:#{source}"
    end
  end

  def self.scp(source, dest)
    shex!("scp -qB -o StrictHostKeyChecking=no -o ConnectTimeout=3 #{source} #{dest}")
  end

  def self.with_temp(options={}, &block)
    raise(ArgumentError,"options should be a Hash") unless options.kind_of?(Hash)
    raise(ArgumentError,"method requires block") if not block_given?

    begin
      create = (options[:dir] ? "mktemp -d" : "mktemp")
      if is_localhost?(options[:host])
        temp = %x(#{create}).strip
      else
        temp = shex!(create, options)[:stdout].strip
      end
      yield temp
    ensure
      if temp
        if is_localhost?(options[:host])
          FileUtils.remove_entry(temp) if File.exists?(temp)
        else
          shex!("rm -rf #{temp}", options) 
        end
      end
    end
  end

  ########################################
  # helper methods
  ########################################

  def self.is_localhost?(hostname=nil)
    case hostname
    when nil, "localhost", HOSTNAME
      true
    else
      false
    end
  end

  def self.change_host(command, hostname=nil)
    if is_localhost?(hostname)
      command
    else
      a = %w[-Tq -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=3]
      a << [hostname, command]
      a.flatten.map { |x| shell_quote(x) }.unshift("ssh").join(" ")
    end
  end

  def self.change_user(command, user=nil)
    case user
    when nil, "", ENV["LOGNAME"]
      command
    when "root"
      "sudo -n #{command}"
    else
      "sudo -inu #{user} #{command}"
    end
  end    

  def self.noop(command, options={})
    change_host(change_user(command, options[:user]), options[:host])
  end

  def self.shell_quote(arg)
    case arg
    when nil
      ""
    when ""
      %q[""]
    else
      # Quote everything except POSIX filename characters.
      # This should be safe enough even for really weird shells.
      arg.gsub(/([^-0-9a-zA-Z_.\/])/) {|m| "\\#{m}"}
    end
  end

end
