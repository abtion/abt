# frozen_string_literal: true

module DevopsHelpers
  def stub_devops_request(global_git, organization_name, project_name, verb, path, *rest)
    path = "https://#{organization_name}.visualstudio.com/#{project_name}/_apis/#{path}"

    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json; api-version=6.0'
    }
    basic_auth = [
      global_git["organizations.#{organization_name}.username"],
      global_git["organizations.#{organization_name}.accessToken"]
    ]

    stub_request(verb, path, *rest).with(headers: headers, basic_auth: basic_auth)
  end

  # def stub_get_projects(git_config, query, projects)
  #   # Create a page per record to force the pagination code into action
  #   path = 'projects'
  #   used_query = query.merge(workspace: git_config['workspaceGid'], limit: 100)

  #   projects.each_with_index do |project, index|
  #     response_data = { "data": [project] }

  #     next_path = "projects?offset=#{index}"
  #     response_data['next_page'] = { 'path' => "/#{next_path}" } if index != projects.length - 1

  #     stub_asana_request(git_config, :get, path)
  #       .with(query: used_query)
  #       .to_return(body: Oj.dump(response_data, mode: :json))

  #     path = next_path
  #   end
  # end
end
