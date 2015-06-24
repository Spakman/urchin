require_relative "../helpers"
require "fileutils"
require "minitest/mock"

module Urchin

  def eval_config_file(urchin_rb)
    @passed_urchin_rb = urchin_rb
  end

  module_function :eval_config_file

  describe "Underscore" do
    include TestHelpers

    def setup
      Urchin.send(:module_eval, "@passed_urchin_rb = nil")
    end

    def test_no_arguments_displays_urchin_pid
      pid = "my pid"
      ENV["URCHIN_PID"] = pid
      _ = Builtins::Underscore.new(JobTable.new)
      output = with_redirected_output do
        _.execute
      end
      assert_equal "#{pid}\n", output
    end

    def test_passing_reload_config_reloads_urchin_rb
      _ = Builtins::Underscore.new(JobTable.new) << "reload_config"
      output = with_redirected_output do
        _.execute
      end
      assert_equal URCHIN_RB, Urchin.send(:module_eval, "@passed_urchin_rb")
      assert_equal "", output
    end

    def test_useless_argument_displays_a_message
      _ = Builtins::Underscore.new(JobTable.new) << "useless"
      output = with_redirected_output do
        assert_raises(UrchinRuntimeError) { _.execute }
      end
      assert_equal "", output
    end

    def test_useless_argument_means_others_are_not_run
      _ = Builtins::Underscore.new(JobTable.new) << "reload_config" << "useless"
      output = with_redirected_output do
        assert_raises(UrchinRuntimeError) { _.execute }
      end
      assert_nil Urchin.send(:module_eval, "@passed_urchin_rb")
      assert_equal "", output
    end
  end
end
