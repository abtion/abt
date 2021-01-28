# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Api
        VERBS = %i[get post put].freeze

        attr_reader :organization_name, :project_name, :username, :access_token

        def initialize(organization_name:, project_name:, username:, access_token:)
          @organization_name = organization_name
          @project_name = project_name
          @username = username
          @access_token = access_token
        end

        VERBS.each do |verb|
          define_method(verb) do |*args|
            request(verb, *args)
          end
        end

        def get_paged(path, _query = {})
          result = request(:get, path)
          result['value']

          # TODO: Loop if necessary
        end

        def request(*args)
          response = connection.public_send(*args)

          if response.success?
            Oj.load(response.body)
          else
            error_class = Abt::HttpError.error_class_for_status(response.status)
            encoded_response_body = response.body.force_encoding('utf-8')
            raise error_class, "Code: #{response.status}, body: #{encoded_response_body}"
          end
        end

        def api_endpoint
          "https://dev.azure.com/#{organization_name}/#{project_name}/_apis"
        end

        def connection
          @connection ||= Faraday.new(api_endpoint) do |connection|
            connection.basic_auth username, access_token
          end
        end
      end
    end
  end
end
