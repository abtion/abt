# frozen_string_literal: true

module AsanaHelpers
  def stub_asana_request(git_config, verb, path, *rest)
    path = "https://app.asana.com/api/1.0/#{path}"
    stub_request(verb, path, *rest).with(headers: request_headers_for_git_config(git_config))
  end

  def stub_get_projects(git_config, query, projects)
    # Create a page per record to force the pagination code into action
    path = 'projects'
    used_query = query.merge(workspace: git_config['workspaceGid'], limit: 100)

    projects.each_with_index do |project, index|
      response_data = { "data": [project] }

      next_path = "projects?offset=#{index}"
      response_data['next_page'] = { 'path' => "/#{next_path}" } if index != projects.length - 1

      stub_asana_request(git_config, :get, path)
        .with(query: used_query)
        .to_return(body: Oj.dump(response_data, mode: :json))

      path = next_path
    end
  end

  def request_headers_for_git_config(git_config)
    {
      'Authorization' => "Bearer #{git_config['accessToken']}"
    }
  end
end
