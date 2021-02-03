# frozen_string_literal: true

require 'simplecov'

unless ENV['DISABLE_SIMPLECOV'] == 'true'
  SimpleCov.start do
    add_filter 'spec'

    add_group 'Core', ['lib/abt.rb', %r{lib/abt/(?!docs|cli)[^/]*.rb}]
    add_group 'Cli', ['lib/abt/cli']
    add_group 'Docs', ['lib/abt/docs']
    add_group 'DevOps', 'lib/abt/providers/devops'
    add_group 'Asana', 'lib/abt/providers/asana'
    add_group 'Harvest', 'lib/abt/providers/harvest'

    minimum_coverage(100)
  end
end
