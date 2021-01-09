# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Tasks
        attr_reader :project_gid

        def initialize(arg_str:, cli:)
          @project_gid = Asana.parse_arg_string(arg_str)[:project_gid]
        end

        def call
          puts project['name']
          tasks.each do |task|
            puts [
              "asana:#{project['gid']}/#{task['gid']}",
              ' - ',
              task['name']
            ].join('')
          end
        end

        private

        def project
          @project ||= begin
            asana.get("projects/#{project_gid}")
          end
        end

        def tasks
          @tasks ||= begin
            asana.get_paged("tasks", section: section_gid)
          end
        end

        def sections
          asana.get_paged("projects/#{project_gid}/sections")
        rescue Abt::HttpError::HttpError
          []
        end

        def section_gid
          @section_gid ||= begin
            section_gid = Abt::GitConfig.local('abt.asana.backlogSection')
            if section_gid.nil?
              section_gid = prompt_section['gid']
              Abt::GitConfig.local('abt.asana.backlogSection', section_gid)
            end
            section_gid
          end
        end

        def prompt_section
          abort 'The project has no sections (columns)' if sections.empty?

          sections.each_with_index do |section, index|
            puts "#{section['name']} (#{index})"
          end

          puts "Please pick a backlog section (0-#{sections.length - 1})"
          loop do
            section = sections[STDIN.gets.strip.to_i]
            return section unless section.nil?
          end
        end

        def asana
          Abt::Asana::Client
        end
      end
    end
  end
end
