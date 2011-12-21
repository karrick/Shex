#!/usr/bin/env ruby

require "fileutils"
require "test/unit"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "version")
require "Shex"

class TestShexFileSystemTransfers < Test::Unit::TestCase

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
