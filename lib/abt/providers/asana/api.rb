# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class Api
        API_ENDPOINT = 'https://app.asana.com/api/1.0'
        VERBS = %i[get post put].freeze

        attr_reader :access_token

        def initialize(access_token:)
          @access_token = access_token
        end

        VERBS.each do |verb|
          define_method(verb) do |*args|
            request(verb, *args)['data']
          end
        end

        def get_paged(path, query = {})
          records = []

          loop do
            result = request(:get, path, query.merge(limit: 100))
            records += result['data']
            break if result['next_page'].nil?

            path = result['next_page']['path'][1..-1]
          end

          records
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

        def connection
          @connection ||= Faraday.new(API_ENDPOINT) do |connection|
            connection.headers['Authorization'] = "Bearer #{access_token}"
            connection.headers['Content-Type'] = 'application/json'
          end
        end
      end
    end
  end
end
