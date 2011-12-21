#!/usr/bin/env ruby

require "fileutils"
require "test/unit"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "version")
require "Shex"

class TestShexFileSystemTests < Test::Unit::TestCase

  def test_directory_true
    assert(Shex.directory?(File.dirname(__FILE__), :host => "localhost"))
  end

  def test_directory_false
    assert(!Shex.directory?(File.join(File.dirname(__FILE__), "non-existant"), :host => "localhost"))
  end

  def test_file_exists
    assert(Shex.file?(__FILE__, :host => "localhost"))
  end

  def test_file_false
    assert(!Shex.file?(__FILE__ + "-non-existant", :host => "localhost"))
  end

end
