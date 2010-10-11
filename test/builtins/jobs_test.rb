require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/jobs"


module Urchin
  unless defined? JOB_TABLE
    JOB_TABLE = JobTable.new
  end

  module Builtins
    class JobsTestCase < Test::Unit::TestCase
      include TestHelpers

      def test_validate_arguments
        jobs = Jobs.new
        assert_nothing_raised { jobs.valid_arguments? }
        jobs.append_arguments [ "--hello" ]
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      end

      def test_execute
        begin
          Urchin::JobTable.class_eval <<-TOS
            alias_method :old_to_s, :to_s

            def to_s; "JOBS"; end
          TOS

          output = with_redirected_output do
            Jobs.new.execute
          end
          assert_equal "JOBS\n", output

        ensure
          Urchin::JobTable.class_eval <<-TOS
            alias_method :to_s, :old_to_s
          TOS
        end
      end
    end
  end
end
