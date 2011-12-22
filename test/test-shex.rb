#!/usr/bin/env ruby

require 'fileutils'
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib', 'version')
require 'Shex'

class TestShexShexWrapping < Test::Unit::TestCase

  def test_redirects_stdin
    assert_equal({:status=>0, :stdout=>"one\ntwo\nthree\n", :stderr=>'', :okay=>true},
                 Shex.shex('cat',{:stdin => "one\ntwo\nthree\n"}))
  end

  def test_redirects_stdout
    assert_equal({:status=>0, :stdout=>"hello world\n", :stderr=>'', :okay=>true},
                 Shex.shex('echo hello world'))
  end

  def test_redirects_stderr
    assert_equal({:status=>0, :stdout=>'', :stderr=>"hello world\n", :okay=>true},
                 Shex.shex('echo hello world >&2'))
  end

end

class TestShexStatusAndOkay < Test::Unit::TestCase

  def test_true
    assert_equal({:status=>0, :stdout=>'', :stderr=>'', :okay=>true},
                 Shex.shex('true'))
  end

  def test_false
    assert_equal({:status=>1, :stdout=>'', :stderr=>'', :okay=>false},
                 Shex.shex('false'))
  end

  def test_false_raises
    assert_raises RuntimeError do
      Shex.shex!('false')
    end
  end

  def test_connection_error_raises
    assert_raises Shex::ConnectionError do
      Shex.shex!('true', :host => 'example.com')
    end
  end

end
