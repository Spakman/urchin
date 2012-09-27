require_relative "../helpers"

module Urchin
  module Completion

    class SshTestCommand
      attr_accessor :args
      def initialize; @args = []; end
    end

    class SshTestCase < Test::Unit::TestCase
      def test_hostnames_from_known_hosts_line
        command = SshTestCommand.new
        command.send(:extend, Ssh)
        assert_equal [], command.hostnames_from_known_hosts_line("|1|3MKmy5ebOAAAAK/MGg/ofLSXIoY=|BB7fHkFdZhjet7pW5936emPsJq8= ssh-rsa AAAAB3NzaC1yc2....\n")
        assert_equal [], command.hostnames_from_known_hosts_line("# comment...\n")
        assert_equal [], command.hostnames_from_known_hosts_line("   \n")
        assert_equal %w( host1 127.0.0.1 ), command.hostnames_from_known_hosts_line("host1,127.0.0.1 ssh-rsa AAAAC5Ny\n")
      end

      def test_hostnames_from_hosts_line
        command = SshTestCommand.new
        command.send(:extend, Ssh)
        assert_equal %w( 127.0.0.1 localhost.localdomain localhost ), command.hostnames_from_hosts_line("127.0.0.1  localhost.localdomain  localhost\n")
        assert_equal %w( ::1 localhost6 ), command.hostnames_from_hosts_line("::1	localhost6\n")
        assert_equal [], command.hostnames_from_hosts_line("   \n")
        assert_equal [], command.hostnames_from_hosts_line("# comment...\n")
        assert_equal %w( 127.0.0.1 host1 ), command.hostnames_from_hosts_line("127.0.0.1 host1 # comment...\n")
      end

      def test_hostnames_from_config_line
        command = SshTestCommand.new
        command.send(:extend, Ssh)
        assert_equal "example", command.hostname_from_config_line("host example\n")
        assert_equal "example", command.hostname_from_config_line("  Host example\n")
        assert_equal "example.com", command.hostname_from_config_line("HostName example.com\n")
        assert_equal "example.com", command.hostname_from_config_line("  hostname example.com\n")
        assert_equal "example.com", command.hostname_from_config_line("  hostname=example.com\n")
        assert_equal "example.com", command.hostname_from_config_line("  hostname = example.com\n")
        assert_equal "example.com", command.hostname_from_config_line("  hostname= example.com\n")
        assert_nil command.hostname_from_config_line("  user mark\n")
      end
    end
  end
end
