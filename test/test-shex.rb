#!/usr/bin/env ruby

require "fileutils"
require "test/unit"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "version")
require "Shex"

class TestShexHelpers < Test::Unit::TestCase

  def test_hostname
    assert_equal %x(hostname -s).strip, Shex::HOSTNAME
  end

  ################
  # is_localhost?

  def test_is_localhost?_no_host
    assert_equal("hostname", Shex.is_localhost?("hostname"))
  end

  def test_is_localhost?_localhost
    assert_equal("hostname", Shex.is_localhost?("hostname", "localhost"))
  end

  def test_is_localhost?_this_host
    assert_equal("hostname", Shex.is_localhost?("hostname", %x(hostname -s).strip))
  end

  def test_is_localhost?_other
    assert_equal("ssh -Tq -o PasswordAuthentication\\=no -o StrictHostKeyChecking\\=no -o ConnectTimeout\\=3 other hostname", 
                 Shex.is_localhost?("hostname", "other"))
  end

  ################
  # change_host

  def test_change_host_no_host
    assert_equal("hostname", Shex.change_host("hostname"))
  end

  def test_change_host_localhost
    assert_equal("hostname", Shex.change_host("hostname", "localhost"))
  end

  def test_change_host_this_host
    assert_equal("hostname", Shex.change_host("hostname", %x(hostname -s).strip))
  end

  def test_change_host_other
    assert_equal("ssh -Tq -o PasswordAuthentication\\=no -o StrictHostKeyChecking\\=no -o ConnectTimeout\\=3 other hostname", 
                 Shex.change_host("hostname", "other"))
  end

  ################
  # change_user

  def test_change_user_no_user
    assert_equal("id", Shex.change_user("id"))
  end

  def test_change_user_empty_string
    assert_equal("id", Shex.change_user("id", ""))
  end

  def test_change_user_logname
    assert_equal("id", Shex.change_user("id", ENV["LOGNAME"]))
  end

  def test_change_user_root
    assert_equal("sudo -n id", Shex.change_user("id", "root"))
  end

  def test_change_user_other
    assert_equal("sudo -inu other id", Shex.change_user("id", "other"))
  end

  ################
  # combine change_user and change_host

  def test_change_no_user_no_host
    assert_equal("hostname", Shex.noop("hostname"))
  end

  def test_change_other_user_no_host
    assert_equal("sudo -inu bozo hostname",
                 Shex.noop("hostname", :user => "bozo"))
  end

  def test_change_no_user_other_host
    assert_equal("ssh -Tq -o PasswordAuthentication\\=no -o StrictHostKeyChecking\\=no -o ConnectTimeout\\=3 other hostname",
                 Shex.noop("hostname", :host => "other"))
  end

  def test_change_other_user_other_host
    assert_equal("ssh -Tq -o PasswordAuthentication\\=no -o StrictHostKeyChecking\\=no -o ConnectTimeout\\=3 other sudo\\ -inu\\ bozo\\ hostname",
                 Shex.noop("hostname", :user => "bozo", :host => "other"))
  end

  ################
  # shell_quote

  def test_shell_quote
    assert_equal("id", Shex.shell_quote("id"))
  end

  def test_shell_quote_nil
    assert_equal("", Shex.shell_quote(nil))
  end

  def test_shell_quote_empty_string
    assert_equal("\"\"", Shex.shell_quote(""))
  end

  def test_shell_quote_single_quote
    assert_equal("echo\\ \\'hello\\ world\\'", Shex.shell_quote("echo 'hello world'"))
  end

  def test_shell_quote_double_quote
    assert_equal("echo\\ \\\"hello\\ world\\\"", Shex.shell_quote("echo \"hello world\""))
  end

  def test_shell_quote_dollar_sign
    assert_equal("echo\\ \\$HOSTNAME", Shex.shell_quote("echo $HOSTNAME"))
  end

end

class TestShexStatusAndOkay < Test::Unit::TestCase

  def test_true
    assert_equal({:status=>0, :stdout=>"", :stderr=>"", :okay=>true},
                 Shex.shex("true"))
  end

  def test_false
    assert_equal({:status=>1, :stdout=>"", :stderr=>"", :okay=>false},
                 Shex.shex("false"))
  end

  def test_false_raises
    assert_raises RuntimeError do
      Shex.shex!("false")
    end
  end

end

class TestShexWithStandardRedirection < Test::Unit::TestCase

  def test_reraises_exceptions
    assert_raises RuntimeError do
      Shex.with_standard_redirection do
        raise "unforgettable exception"
      end
    end
  end

  def test_returns_value
    assert_equal({:stdout=>"", :stderr=>"", :value=>42},
                 Shex.with_standard_redirection { 42 })
  end

  def test_redirect_stdout
    assert_equal({:stdout=>"one\ntwo\nthree\n", :stderr=>"", :value=>42},
                 Shex.with_standard_redirection do
                   %w(one two three).each do |line|
                     system("printf '%s\n' '#{line}'")
                   end
                   42
                 end)
  end

  def test_redirect_stderr
    assert_equal({:stderr=>"one\ntwo\nthree\n", :stdout=>"", :value=>42},
                 Shex.with_standard_redirection do
                   %w(one two three).each do |line|
                     system("printf '%s\n' '#{line}' >&2")
                   end
                   42
                 end)
  end

  def test_redirect_stdin
    assert_equal({:stdout=>"one\ntwo\nthree\n", :stderr=>"", :value=>nil},
                 Shex.with_standard_redirection(:stdin=>"one\ntwo\nthree\n") do
                   system("cat")
                   nil
                 end)
  end

end

class TestShexShexWrapping < Test::Unit::TestCase

  def test_redirect_stdin
    assert_equal({:status=>0, :stdout=>"one\ntwo\nthree\n", :stderr=>"", :okay=>true},
                 Shex.shex("cat",{:stdin => "one\ntwo\nthree\n"}))
  end

  def test_echo
    assert_equal({:status=>0, :stdout=>"hello world\n", :stderr=>"", :okay=>true},
                 Shex.shex("echo hello world"))
  end

  def test_redirect_to_stderr
    assert_equal({:status=>0, :stdout=>"", :stderr=>"hello world\n", :okay=>true},
                 Shex.shex("echo hello world >&2"))
  end

end

class TestShexFileSystem < Test::Unit::TestCase

  ################

  def test_directory?
    assert(Shex.directory?(File.dirname(__FILE__), :host => "localhost"))
  end

  def test_directory?_false
    assert(!Shex.directory?(File.join(File.dirname(__FILE__), "non-existant"),
                            :host => "localhost"))
  end

  def test_file?_exists
    assert(Shex.file?(__FILE__, :host => "localhost"))
  end

  def test_file?_false
    assert(!Shex.file?(__FILE__ + "-non-existant", :host => "localhost"))
  end

  ################

  def test_with_temp
    temp = nil
    Shex.with_temp do |temp_file|
      assert(File.exists?(temp_file))
      assert_equal(0, File.size(temp_file))
      temp = temp_file
    end
    assert(!File.exists?(temp), "should remove temp after block")
  end

  def test_with_temp_directory
    temp = nil
    Shex.with_temp(:dir => true) do |temp_dir|
      temp = temp_dir
      assert(File.directory?(temp_dir))
    end
    assert(!File.exists?(temp), "should remove temp after block")
  end

  def test_with_temp_remote
    entity = nil
    Shex.with_temp(:host => "localhost") do |temp|
      assert(Shex.file?(temp, :host => "localhost"))
      entity = temp
    end
    assert(!Shex.file?(entity, :host => "localhost"),
           "should remove temp after block")
  end

  def test_with_temp_remote_directory
    entity = nil
    Shex.with_temp(:dir => true, :host => "localhost") do |temp|
      assert(Shex.directory?(temp, :host => "localhost"))
      entity = temp
    end
    assert(!Shex.directory?(entity, :host => "localhost"),
           "should remove temp after block")
  end

  def test_scp
    Shex.with_temp do |local_temp|
      File.open(local_temp,"w") {|io| io.write "foo bar baz" }
      Shex.with_temp(:host => "localhost") do |remote_temp|
        Shex.scp(local_temp, "localhost:#{remote_temp}")
        assert_equal("foo bar baz", File.read(remote_temp),
                     "NOTE: test_scp only works if can ssh into localhost")
      end
    end
  end

  def test_move_directory_clobber_raises_when_missing_src
    assert_raises RuntimeError do
      Shex.move_directory_clobber("non-existant", File.join(File.dirname(__FILE__), "non-existant"))
    end
  end

  def test_move_directory_clobber_removes_dest_when_present
    Shex.with_temp(:dir => true) do |src|
      Shex.with_temp(:dir => true) do |dest|

        foo = File.join(src, "foo")
        File.open(foo, "w") {|io| io.write "foo"}

        bar = File.join(dest, "bar")
        File.open(bar, "w") {|io| io.write "bar"}

        Shex.move_directory_clobber(src, dest, :host => "localhost")

        assert(File.file?(File.join(dest, "foo")),
               "should copy foo")
        assert(!File.file?(bar), "should have eliminated bar")
      end
    end
  end

  def test_install
    Shex.with_temp(:dir => true) do |src|
      Shex.with_temp(:dir => true) do |dest|

        foo = File.join(src, "foo")
        File.open(foo, "w") {|io| io.write "foo"}

        bar = File.join(dest, "bar")
        File.open(bar, "w") {|io| io.write "bar"}

        Shex.install(foo, bar, :host => "localhost")

        assert(File.file?(foo))
        assert_equal(File.read(foo), File.read(bar))
      end
    end
  end

end
