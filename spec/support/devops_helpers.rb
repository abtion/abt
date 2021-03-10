# frozen_string_literal: true

module DevopsHelpers
  def stub_devops_request(global_git, organization_name, project_name, verb, path, *rest)
    path = "https://#{organization_name}.visualstudio.com/#{project_name}/_apis/#{path}"

    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json; api-version=6.0"
    }
    basic_auth = [
      global_git["organizations.#{organization_name}.username"],
      global_git["organizations.#{organization_name}.accessToken"]
    ]

    stub_request(verb, path, *rest).with(headers: headers, basic_auth: basic_auth)
  end
end
