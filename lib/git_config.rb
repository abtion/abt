# frozen_string_literal: true

module Abt
  class GitConfig
    class << self
      def local(*args)
        git_config(true, *args)
      end

      def global(*args)
        git_config(false, *args)
      end

      def prompt_local(*args)
        prompt_for_config(true, *args)
      end

      def prompt_global(*args)
        prompt_for_config(false, *args)
      end

      private

      def git_config(local, key, value = nil)
        if value
          `git config --#{local ? 'local' : 'global'} --replace-all #{key.inspect} #{value.inspect}`
          value
        else
          git_value = `git config --get #{key.inspect}`.strip
          git_value.empty? ? nil : git_value
        end
      end

      def prompt(msg)
        STDERR.print "#{msg} > "
        value = read_user_input.strip
        warn
        value
      end

      def prompt_for_config(local, key, prompt_msg, remedy) # rubocop:disable Metrics/MethodLength
        value = git_config(local, key)

        return value unless value == '' || value.nil?

        warn <<~TXT
          Missing git config "#{key}":
          To find this value:
          #{remedy}
        TXT

        new_value = prompt(prompt_msg)

        if new_value.empty?
          abort 'Empty value, aborting'
        else
          git_config(local, key, new_value)
        end
      end

      def read_user_input
        open('/dev/tty', &:gets)
      end
    end
  end
end
