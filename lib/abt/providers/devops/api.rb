# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Api
        VERBS = %i[get post put].freeze

        CONDITIONAL_ACCESS_POLICY_ERROR_CODE = 'VS403463'

        attr_reader :organization_name, :project_name, :username, :access_token, :cli

        def initialize(organization_name:, project_name:, username:, access_token:, cli:)
          @organization_name = organization_name
          @project_name = project_name
          @username = username
          @access_token = access_token
          @cli = cli
        end

        VERBS.each do |verb|
          define_method(verb) do |*args|
            request(verb, *args)
          end
        end

        def get_paged(path, query = {})
          result = request(:get, path, query)
          result['value']

          # TODO: Loop if necessary
        end

        def work_item_query(wiql)
          response = post('wit/wiql', Oj.dump({ query: wiql }, mode: :json))
          ids = response['workItems'].map { |work_item| work_item['id'] }

          work_items = []
          ids.each_slice(200) do |page_ids|
            work_items += get_paged('wit/workitems', ids: page_ids.join(','))
          end

          work_items
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
        rescue Abt::HttpError::ForbiddenError => e
          handle_denied_by_conditional_access_policy!(e)
        end

        def base_url
          "https://#{organization_name}.visualstudio.com/#{project_name}"
        end

        def api_endpoint
          "#{base_url}/_apis"
        end

        def url_for_work_item(work_item)
          "#{base_url}/_workitems/edit/#{work_item['id']}"
        end

        def url_for_board(board)
          "#{base_url}/_boards/board/#{URI.escape(board['name'])}"
        end

        def connection
          @connection ||= Faraday.new(api_endpoint) do |connection|
            connection.basic_auth username, access_token
            connection.headers['Content-Type'] = 'application/json'
            connection.headers['Accept'] = 'application/json; api-version=6.0'
          end
        end

        private

        def handle_denied_by_conditional_access_policy!(exception)
          raise exception unless exception.message.include?(CONDITIONAL_ACCESS_POLICY_ERROR_CODE)

          cli.abort <<~TXT
            Access denied by conditional access policy.
            Try logging into the board using the URL below, then retry the command.

            #{base_url}
          TXT
        end
      end
    end
  end
end
