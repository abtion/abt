# frozen_string_literal: true

module HarvestHelpers
  def harvest_credentials
    { "accessToken" => "access_token", "accountId" => "account_id", "userId" => "user_id" }
  end

  def stub_harvest_request(git_config, verb, path, *rest)
    path = "https://api.harvestapp.com/v2/#{path}"
    stub_request(verb, path, *rest).with(headers: request_headers_for_git_config(git_config))
  end

  def stub_get_project_assignments(git_config, project_assignments)
    # Create a page per project assignment to force our pagination code into action
    project_assignments.each_with_index do |project_assignment, index|
      page = index + 1

      response_data = {
        project_assignments: [project_assignment],
        total_pages: project_assignments.length
      }

      stub_request(:get, "https://api.harvestapp.com/v2/users/me/project_assignments?page=#{page}")
        .with(headers: request_headers_for_git_config(git_config))
        .to_return(body: Oj.dump(response_data, mode: :json))
    end
  end

  def stub_post_time_entry(git_config, time_entry)
    stub_request(:post, "https://api.harvestapp.com/v2/time_entries")
      .with(headers: request_headers_for_git_config(git_config))
      .to_return(body: Oj.dump(time_entry, mode: :json))
  end

  def request_headers_for_git_config(git_config)
    {
      "Authorization" => "Bearer #{git_config['accessToken']}",
      "Harvest-Account-Id" => git_config["accountId"], "Content-Type" => "application/json"
    }
  end
end
