
require 'rubygems'
require 'minitest/spec'

MiniTest::Unit.autorun

module Shareable

  def before(type = :each, &block)
    raise "unsupported before type: #{type}" unless type == :each
    define_method :setup, &block
  end

  def after(type = :each, &block)
    raise "unsupported after type: #{type}" unless type == :each
    define_method :teardown, &block
  end

  def it desc, &block
    define_method "test_#{desc.gsub(/\W+/, '_').downcase}", &block
  end

  def xit desc, &block
    puts "**Skipping: #{desc}"
    define_method "test_#{desc.gsub(/\W+/, '_').downcase}", lambda {print "s" }
  end

end

module MiniTest
  class Unit
    def run_test_suites filter = /./
      @test_count, @assertion_count = 0, 0
      old_sync, @@out.sync = @@out.sync, true if @@out.respond_to? :sync=
        TestCase.test_suites.each do |suite|
          tmethods_to_run = suite.test_methods.grep(filter)
          @@out.puts "#{suite}:" if tmethods_to_run.size > 0
          tmethods_to_run.each do |test|
            inst = suite.new test
            inst._assertions = 0
            @@out.print "- #{test.sub(/^test_/,'').gsub('_',' ')} " if @verbose

            t = Time.now if @verbose
            result = inst.run(self)

            #@@out.print "%.2f s: " % (Time.now - t) if @verbose
            @@out.print result
            @@out.puts if @verbose
            @test_count += 1
            @assertion_count += inst._assertions
          end
          end
        @@out.sync = old_sync if @@out.respond_to? :sync=
          [@test_count, @assertion_count]
    end
  end
end

