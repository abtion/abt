# frozen_string_literal: true

module HarvestHelpers
  def stub_get_project_assignments(git_config, project_assignments)
    response_data = {
      "project_assignments": project_assignments,
      "total_pages": 1
    }

    stub_request(:get, 'https://api.harvestapp.com/v2/users/me/project_assignments?page=1')
      .with(headers: request_headers_for_git_config(git_config))
      .to_return(body: Oj.dump(response_data, mode: :json))
  end

  def stub_post_time_entry(git_config, time_entry)
    stub_request(:post, 'https://api.harvestapp.com/v2/time_entries')
      .with(headers: request_headers_for_git_config(git_config))
      .to_return(body: Oj.dump(time_entry, mode: :json))
  end

  def request_headers_for_git_config(git_config)
    {
      'Authorization' => "Bearer #{git_config['accessToken']}",
      'Harvest-Account-Id' => git_config['accountId'], 'Content-Type' => 'application/json'
    }
  end
end
