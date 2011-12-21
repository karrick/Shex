#!/usr/bin/env ruby

require "fileutils"
require "test/unit"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "version")
require "Shex"

class TestShexTemporaries < Test::Unit::TestCase

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

end
