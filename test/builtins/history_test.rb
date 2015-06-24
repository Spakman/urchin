require_relative "../helpers"
require "fileutils"

module Urchin
  describe "History" do
    include TestHelpers

    def add_to_history(inputs, history)
      inputs.each do |input|
        line = OpenStruct.new
        line.input = input
        line.date = Time.now
        line.notes = "Apples and bananas"
        history.add_entry line
      end
    end

    def setup
      @shell = Shell.new
      @job_table = @shell.job_table

      add_to_history(%w( the history is populated ), @shell.history)
    end

    def test_list_fields
      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table) << "--fields"
        history.execute
      end
      assert_equal %w( input date notes ).join("\n"), output.chomp
    end

    def test_help
      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table) << "--help"
        history.execute
      end
      assert output.chomp =~ /^Usage.+message$/m
    end

    def test_no_arguments
      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table)
        history.execute
      end
      assert_equal %w( history is populated ).join("\n"), output.chomp
    end

    def test_display_fields
      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table) << "--output" << "input,notes"
        history.execute
      end
      lines = []
      lines << "history    Apples and bananas"
      lines << "is         Apples and bananas"
      lines << "populated  Apples and bananas"
      assert_equal lines.join("\n"), output.chomp

      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table) << "--output" << "input,notes" << "-s" << " @@ "
        history.execute
      end
      lines = []
      lines << "history   @@ Apples and bananas"
      lines << "is        @@ Apples and bananas"
      lines << "populated @@ Apples and bananas"
      assert_equal lines.join("\n"), output.chomp
    end

    def test_invalid_parameters
      skip("Need a way to capture STDERR from builtins.")
      output = with_redirected_output do
        history = Builtins::History.new(@shell.job_table) << "--output" << "input,invalid"
        history.execute
      end
      assert_equal "Cannot find in any history entries: invalid", output.chomp
    end
  end
end

