#!/usr/bin/env ruby

require "fileutils"
require "test/unit"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "version")
require "Shex"

class TestShexWithStandardRedirection < Test::Unit::TestCase

  def test_bubbles_exceptions
    assert_raises RuntimeError do
      Shex.with_standard_redirection do
        raise "test exception to be bubbled"
      end
    end
  end

  def test_returns_value
    assert_equal({:stdout=>"", :stderr=>"", :value=>42},
                 Shex.with_standard_redirection { 42 })
  end

  def test_redirects_stdout
    assert_equal({:stdout=>"one\ntwo\nthree\n", :stderr=>"", :value=>42},
                 Shex.with_standard_redirection do
                   %w(one two three).each do |line|
                     puts line
                   end
                   42
                 end)
  end

  def test_redirects_stderr
    assert_equal({:stderr=>"one\ntwo\nthree\n", :stdout=>"", :value=>42},
                 Shex.with_standard_redirection do
                   %w(one two three).each do |line|
                     STDERR.puts line
                   end
                   42
                 end)
  end

  def test_redirects_stdin
    assert_equal({:stdout=>"one\ntwo\nthree\n", :stderr=>"", :value=>36},
                 Shex.with_standard_redirection(:stdin=>"one\ntwo\nthree\n") do
                   while ! STDIN.eof?
                     puts readline
                   end
                   36
                 end)
  end

end

