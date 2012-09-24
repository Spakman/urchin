require "set"

module Urchin
  module Completion
    module Ssh

      def complete(word)
        hosts = known_hosts_hostnames + config_hostnames + hosts_hostnames
        hosts.grep(/^#{Regexp.escape(word)}/)
      end

      def known_hosts_hostnames
        hostnames = Set.new
        File.readlines("#{ENV["HOME"]}/.ssh/known_hosts").each do |line|
          hostnames += hostnames_from_known_hosts_line(line)
        end
        hostnames
      end

      def hostnames_from_known_hosts_line(line)
        line.chomp!
        return [] if line =~ /^ *$/
        # Don't complete comments or hashed hostnames.
        return [] if line =~ /^(?:#|\|)/
        hosts = line.split.first
        hosts.split(",").map do |host|
          # Remove square brackets and port.
          if host =~ /^\[(.+)\]:/
            $1
          else
            host
          end
        end
      end

      def hosts_hostnames
        hostnames = Set.new
        File.readlines("/etc/hosts").each do |line|
          hostnames += hostnames_from_hosts_line(line)
        end
        hostnames
      end

      def hostnames_from_hosts_line(line)
        line.chomp.sub(/#.*/, "").split(/\s+/)
      end

      def config_hostnames
        hostnames = Set.new
        File.readlines("#{ENV["HOME"]}/.ssh/config").each do |line|
          if host = hostname_from_config_line(line)
            hostnames << host
          end
        end
        hostnames
      end

      def hostname_from_config_line(line)
        return nil if line[0] == "#"
        return nil if line =~ /^ *$/
        # It seems to be rare, but config files can use =.
        line.sub!("=", " ")
        if line =~ /^(?: *)host(?:name)? +(.+)/i
          $1
        end
      end
    end
  end
end
