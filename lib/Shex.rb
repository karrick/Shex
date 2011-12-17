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
    shex("test -d #{pathname}", options)[:okay]
  end

  def self.file?(pathname, options={})
    shex("test -e #{pathname}", options)[:okay]
  end

  def self.shex(command, options={})
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
    result = shex(command, options)
    if not result[:okay]
      error_message = options[:emsg] || "error #{result[:status]}: #{command}"
      error_class = options[:eclass] || RuntimeError
      raise(error_class, "#{error_message}#{$/}#{result[:stderr]}#{$/}")
    end
    result
  end

  def self.scp(src, dest)
    shex!("scp -qB -o StrictHostKeyChecking=no -o ConnectTimeout=3 #{src} #{dest}")
  end

  def self.with_temp(options={}, &block)
    if not block_given?
      raise(ArgumentError, "method requires block")
    end

    begin
      create = (options[:dir] ? "mktemp -d" : "mktemp")
      case options[:host]
      when nil
        temp = %x(#{create}).strip
      else
        temp = shex!(create, options)[:stdout].strip
      end
      yield(temp)
    ensure
      if temp
        case options[:host]
        when nil
          FileUtils.remove_entry(temp) if File.exists?(temp)
        else
          if file?(temp, options[:host])
            shex!("rm -rf #{temp}", options) 
          end
        end
      end
    end
  end

  def self.move_directory_clobber(src, dest, options)
    # TODO: backup and restore if exception raised
    if directory?(src, options)
      if directory?(dest, options)
        shex!("rm -rf #{dest}", options)
      end
      shex!("mv #{src} #{dest}", options)
    else
      raise "error: missing #{options[:host]}:#{src}"
    end
  end

  def self.install(src, dest, options)
    suffix = "-S .#{options[:suffix]}" if options[:suffix]
    permissions = "-m #{options[:permissions]}" if options[:permissions]
    owner = "-o #{options[:owner]}" if options[:owner]
    group = "-o #{options[:group]}" if options[:group]

    with_temp(options) do |temp|
      scp(src,"#{options[:host]}:#{temp}")
      shex!("install #{suffix} #{permissions} #{owner} #{group} #{src} #{dest}", options)
    end
  end

  ########################################
  # helper methods
  ########################################

  def self.change_host(command, hostname=nil)
    case hostname
    when nil, "localhost", HOSTNAME
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
