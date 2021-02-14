# frozen_string_literal: true

module HarvestHelpers
  def stub_project_assignments_request(git_config, project_assignments)
    request_headers = {
      'Authorization' => "Bearer #{git_config['accessToken']}",
      'Harvest-Account-Id' => git_config['accountId'], 'Content-Type' => 'application/json'
    }
    response_data = {
      "project_assignments": project_assignments,
      "total_pages": 1
    }

    stub_request(:get, 'https://api.harvestapp.com/v2/users/me/project_assignments?page=1')
      .with(headers: request_headers)
      .to_return(body: Oj.dump(response_data, mode: :json))
  end
end
