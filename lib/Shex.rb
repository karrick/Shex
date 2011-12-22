require 'fileutils'
require 'Shex/version'

module Shex

  ########################################
  # module constant below is set at load time
  ########################################

  class ConnectionError < RuntimeError ; end

  HOSTNAME = %x(hostname -s).strip

  # remembers the observed username when logging into remote host
  REMOTE_USERS = {}

  ########################################
  # api
  ########################################

  def self.directory?(pathname, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    file_system_test(pathname, options.merge(:test => 'd'))
  end

  def self.file?(pathname, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    file_system_test(pathname, options.merge(:test => 'f'))
  end

  def self.maybe_shex(command, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    if not can_connect?(options[:host])
      raise(ConnectionError, sprintf('connection error: %s', options[:host]))
    else
      shex(command, options)
    end
  end

  def self.shex(command, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    result = with_standard_redirection(options) do
      okay = system(noop(command, options))
      {:okay => okay, :status => $?.exitstatus}
    end

    { :okay   => result[:value][:okay],
      :status => result[:value][:status],
      :stdout => result[:stdout],
      :stderr => result[:stderr],
    }
  end

  def self.shex!(command, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    result = shex(command, options)

    if ((result[:status] == 255) && (not is_localhost?(options[:host])))
      raise(ConnectionError, sprintf('connection error: %s', options[:host]))
    end

    if not result[:okay]
      error_message = (options[:emsg] || sprintf('status %s: %s', result[:status], command))
      error_class = (options[:eclass] || RuntimeError)
      raise(error_class, sprintf("%s\n%s\n", error_message, result[:stderr]))
    end
    result
  end

  def self.with_standard_redirection(options={}, &block)
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)
    raise(ArgumentError, 'method requires block') unless block_given?

    result = {}
    stdin_saved  = $stdin.dup
    stdout_saved = $stdout.dup
    stderr_saved = $stderr.dup

    with_temp do |temp_stdin|
      if options[:stdin]
        File.open(temp_stdin, 'w') { |io| io.write options[:stdin] }
        $stdin.reopen(temp_stdin, 'r')
      end

      with_temp do |temp_stdout|
        $stdout.reopen(temp_stdout, 'w')

        with_temp do |temp_stderr|
          $stderr.reopen(temp_stderr, 'w')

          begin
            result.update(:value => yield)

          rescue
            stderr_saved.puts $!
            raise

          ensure
            $stdout.flush
            $stderr.flush

            $stdin.reopen(stdin_saved)
            $stdout.reopen(stdout_saved)
            $stderr.reopen(stderr_saved)

            result.update(:stdout => File.read(temp_stdout))
            result.update(:stderr => File.read(temp_stderr))
          end

        end
      end
    end
    result
  end

  ################

  def self.install(source, dest, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)
    raise sprintf('missing source file: %s', source) unless File.exists?(source)

    permissions = sprintf('-m %s', options[:permissions]) if options[:permissions]
    owner = sprintf('-o %s', options[:owner]) if options[:owner]
    group = sprintf('-g %s', options[:group]) if options[:group]
    suffix = sprintf('-S .%s', options[:suffix]) if options[:suffix]

    hostname = options[:host]
    with_temp(options.merge(:user => nil)) do |temp|
      if not is_localhost?(hostname)
        scp(source, sprintf('%s:%s', hostname, temp))
        source = temp
      end
      shex!(sprintf('install %s %s %s %s %s %s',
                    suffix, permissions, owner, group, source, dest),
            options)
    end
  end

  def self.move_directory_clobber(source, dest, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    # TODO: backup and restore if exception raised

    if not directory?(source, options)
      raise sprintf('missing %s:%s', options[:host], source)
    else
      if directory?(dest, options)
        shex!(sprintf('rm -rf %s', dest), options)
      end
      suffix = sprintf('-S .%s', options[:suffix]) if options[:suffix]
      shex!(sprintf('mv %s %s %s', suffix, source, dest), options)
    end
  end

  def self.scp(source, dest)
    if source =~ /^(.+):.+/
      source_host = $1
    end
    if dest =~ /^(.+):.+/
      dest_host = $1
    end

    if ! source_host.nil? && ! dest_host.nil?
      raise sprintf('source host and dest host cannot both be remote hosts: %s, %s', source_host, dest_host)
    else
      hostname = (source_host || dest_host)
    end

    if hostname.nil? || can_connect?(hostname)
      shex!(sprintf('scp -Bpq -o StrictHostKeyChecking=no -o ConnectTimeout=2 %s %s', source, dest))
    end
  end

  def self.with_temp(options={}, &block)
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)
    raise(ArgumentError, 'method requires block') unless block_given?

    begin
      create = (options[:dir] ? 'mktemp -d' : 'mktemp')
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
          shex!(sprintf('rm -rf %s', temp), options)
        end
      end
    end
  end

  ########################################
  # helper methods
  ########################################

  def self.can_connect?(hostname, retest=false)
    REMOTE_USERS.delete(hostname) if retest

    if not REMOTE_USERS.has_key?(hostname)
      STDERR.print sprintf("* Checking connection to %s\n", hostname) if $DEBUG
      command = noop('whoami', :host => hostname)
      result = %x(#{command})
      if result != ''
        REMOTE_USERS[hostname] = result.strip
      end
    end

    (REMOTE_USERS.has_key?(hostname) ? true : false)
  end

  def self.change_host(command, hostname=nil)
    if is_localhost?(hostname)
      command
    else
      a = %w[-qTx -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=2]
      a << [hostname, command]
      a.flatten.map { |x| shell_quote(x) }.unshift('ssh').join(' ')
    end
  end

  def self.change_user(command, user=nil)
    case user
    when nil, '', ENV['LOGNAME']
      command
    when 'root'
      sprintf('sudo -n %s', command)
    else
      sprintf('sudo -inu %s %s', user, command)
    end
  end

  def self.file_system_test(pathname, options={})
    raise(ArgumentError, 'options should be a Hash') unless options.kind_of?(Hash)

    result = shex(sprintf('test -%s %s', options[:test], pathname), options)
    case result[:status]
    when 0
      true
    when 1
      false
    when 255
      raise(ConnectionError, sprintf('connection error: %s', options[:host]))
    else
      raise sprintf('unexpected status: %d', result[:status])
    end
  end

  def self.is_localhost?(hostname)
    case hostname
    when nil, '', 'localhost', HOSTNAME
      true
    else
      false
    end
  end

  def self.noop(command, options={})
    change_host(change_user(command, options[:user]), options[:host])
  end

  def self.shell_quote(arg)
    case arg
    when nil
      ''
    when ''
      %q[""]
    else
      # Quote everything except POSIX filename characters.
      # This should be safe enough even for really weird shells.
      arg.gsub(/([^-0-9a-zA-Z_.\/])/) { |m| "\\#{m}" }
    end
  end

end
