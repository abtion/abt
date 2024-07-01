# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Api
        # Shamelessly copied from ERB::Util.url_encode
        # https://apidock.com/ruby/ERB/Util/url_encode
        def self.rfc_3986_encode_path_segment(string)
          string.to_s.b.gsub(/[^a-zA-Z0-9_\-.~]/) do |match|
            format("%%%02X", match.unpack1("C"))
          end
        end

        VERBS = [:get, :post, :put].freeze

        CONDITIONAL_ACCESS_POLICY_ERROR_CODE = "VS403463"

        attr_reader :organization_name, :project_name, :username, :access_token, :cli

        def initialize(organization_name:, username:, access_token:, cli:)
          @organization_name = organization_name
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
          result["value"]

          # TODO: Loop if necessary
        end

        def work_item_query(wiql)
          response = post("_apis/wit/wiql", Oj.dump({ query: wiql }, mode: :json))
          ids = response["workItems"].map { |work_item| work_item["id"] }

          work_items = []
          ids.each_slice(200) do |page_ids|
            work_items += get_paged("_apis/wit/workitems", ids: page_ids.join(","))
          end

          work_items
        end

        def request(*args)
          response = connection.public_send(*args)

          if response.success?
            Oj.load(response.body)
          else
            error_class = Abt::HttpError.error_class_for_status(response.status)
            encoded_response_body = response.body.dup.force_encoding("utf-8")
            raise error_class, "Code: #{response.status}, body: #{encoded_response_body}"
          end
        rescue Abt::HttpError::ForbiddenError => e
          handle_denied_by_conditional_access_policy!(e)
        end

        def base_url
          "https://#{organization_name}.visualstudio.com"
        end

        def url_for_work_item(work_item)
          project_name = self.class.rfc_3986_encode_path_segment(work_item["fields"]["System.TeamProject"])
          "#{base_url}/#{project_name}/_workitems/edit/#{work_item['id']}"
        end

        def url_for_board(project_name, team_name, board)
          board_name = self.class.rfc_3986_encode_path_segment(board["name"])
          "#{base_url}/#{project_name}/_boards/board/t/#{team_name}/#{board_name}"
        end

        def sanitize_work_item(work_item)
          return nil if work_item.nil?

          work_item.merge(
            "id" => work_item["id"].to_s,
            "name" => work_item["fields"]["System.Title"],
            "url" => url_for_work_item(work_item)
          )
        end

        def connection
          @connection ||= Faraday.new(base_url) do |connection|
            connection.basic_auth(username, access_token)
            connection.headers["Content-Type"] = "application/json"
            connection.headers["Accept"] = "application/json; api-version=6.0"
          end
        end

        private

        def handle_denied_by_conditional_access_policy!(exception)
          raise exception unless exception.message.include?(CONDITIONAL_ACCESS_POLICY_ERROR_CODE)

          cli.abort(<<~TXT)
            Access denied by conditional access policy.
            Try logging into the board using the URL below, then retry the command.

            #{base_url}
          TXT
        end
      end
    end
  end
end
