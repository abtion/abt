# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Start
        attr_reader :path

        def initialize(path = '')
          @path = path
        end

        def call
          Current.new(path).call

          body = Oj.dump({
                           project_id: Abt::GitConfig.local('abt.harvest.projectId'),
                           task_id: Abt::GitConfig.local('abt.harvest.taskId'),
                           user_id: Abt::GitConfig.global('harvest.userId'),
                           spent_date: Date.today.iso8601
                         }, mode: :json)
          result = harvest.post('time_entries', body)
          puts 'Tracker successfully started'
        rescue Abt::HttpError::HttpError => e
          puts e
          abort 'Unable to start tracker'
        end

        private

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
