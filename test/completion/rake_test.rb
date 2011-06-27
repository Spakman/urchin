require "helpers"
require "#{File.dirname(__FILE__)}/../../completion/rake"

module Urchin
  module Completion

    class Rake
      class << self
        attr_reader :commands
      end
    end

    class RakeTestCase < Test::Unit::TestCase
      def test_commands_with_empty_first_arg
        assert_equal %w( test todo ), Rake.new.tasks
      end
    end
  end
end
