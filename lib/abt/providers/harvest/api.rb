# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class Api
        API_ENDPOINT = "https://api.harvestapp.com/v2"
        VERBS = [:get, :post, :patch].freeze

        attr_reader :access_token, :account_id

        def initialize(access_token:, account_id:)
          @access_token = access_token
          @account_id = account_id
        end

        VERBS.each do |verb|
          define_method(verb) do |*args|
            request(verb, *args)
          end
        end

        def get_paged(path, query = {})
          result_key = path.split("?").first.split("/").last

          page = 1
          records = []

          loop do
            result = get(path, query.merge(page: page))
            records += result[result_key]
            break if result["total_pages"] == page

            page += 1
          end

          records
        end

        def request(*args)
          response = connection.public_send(*args)

          if response.success?
            Oj.load(response.body)
          else
            error_class = Abt::HttpError.error_class_for_status(response.status)
            encoded_response_body = response.body.force_encoding("utf-8")
            raise error_class, "Code: #{response.status}, body: #{encoded_response_body}"
          end
        end

        def connection
          @connection ||= Faraday.new(API_ENDPOINT) do |connection|
            connection.headers["Authorization"] = "Bearer #{access_token}"
            connection.headers["Harvest-Account-Id"] = account_id
            connection.headers["Content-Type"] = "application/json"
          end
        end
      end
    end
  end
end
