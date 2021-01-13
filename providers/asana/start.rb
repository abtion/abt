# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Start < BaseCommand
        def self.command
          'start asana[:<project-gid>/<task-gid>]'
        end

        def self.description
          'Set current task and move it to a section (column) of your choice'
        end

        def call
          Current.new(arg_str: arg_str, cli: cli).call unless arg_str.nil?
          Move.new(arg_str: arg_str, cli: cli).call
        end
      end
    end
  end
end
