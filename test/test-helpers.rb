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

  def test_is_localhost?_no_parameter
    assert(Shex.is_localhost?)
  end

  def test_is_localhost?_localhost
    assert(Shex.is_localhost?("localhost"))
  end

  def test_is_localhost?_this_host
    assert(Shex.is_localhost?(%x(hostname -s).strip))
  end

  def test_is_localhost?_other
    assert(!Shex.is_localhost?("other"))
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

