# Copyright (c) 2010-2012 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class History < Builtin

      EXECUTABLE = "history"

      def parse(args)
        options = {}
        options[:separator] = "  "

        opts = OptionParser.new do |opt|
          opt.banner = "Usage: history [options]"

          opt.on("-f", "--fields", "List the available fields") do
            options[:list_fields] = true
          end

          opt.on_tail("-h", "--help", "Show this message") do
            options[:help] = true
            puts opts
          end

          opt.on("-o", "--output a,b,c", Array, "Display these fields") do |fields|
            options[:fields] = Set.new(fields.map { |f| f.to_sym })
          end

          opt.on("-s", "--separator [SEPARATOR]", "Specify record separator (default \"  \")") do |separator|
            options[:separator] = separator
          end
        end

        opts.parse!(args)
        validate(options)
      end

      def validate(options)
        unless options[:help]
          if options[:fields]
            missing_fields = (options[:fields] - @job_table.shell.history.fields).to_a
            if missing_fields.any?
              STDERR.puts "Cannot find in any history entries: #{missing_fields.join(", ")}"
              return false
            end
          end
        end
        options
      end

      def execute
        if options = parse(@args)
          return if options[:help]
          if options[:list_fields]
            puts fields
          elsif options[:fields]
            puts history_columns(options)
          else
            puts history_inputs
          end
        end
      end

      def fields
        @job_table.shell.history.fields.to_a
      end

      def history_inputs
        @job_table.shell.history.entries.map do |line|
          line.input
        end
      end

      def history_columns(options)
        lines = []
        column_widths = Hash.new(0)

        # Iterate over the entries to establish the column widths.
        @job_table.shell.history.entries.each do |line|
          options[:fields].each do |field|
            value = line.send(field).to_s
            if value.length > column_widths[field]
              column_widths[field] = value.length
            end
          end
        end

        # Iterate over the entries to justify the column entries.
        @job_table.shell.history.entries.each do |line|
          values = []
          options[:fields].each do |field|
            value = line.send(field).to_s
            unless field == options[:fields].to_a.last
              value = value.ljust(column_widths[field])
            end
            values << value
          end
          lines << values.join(options[:separator])
        end
        lines
      end

    end
  end
end
