# frozen_string_literal: true

module DevopsHelpers
  def devops_credentials
    { "organizations.org-name.username" => "username",
      "organizations.org-name.accessToken" => "accessToken" }
  end

  def stub_devops_request(global_git, organization_name, project_name, *stub_request_args)
    headers = { "Content-Type" => "application/json", "Accept" => "application/json; api-version=6.0" }

    basic_auth = [
      global_git["organizations.#{organization_name}.username"],
      global_git["organizations.#{organization_name}.accessToken"]
    ]

    (method, path, *rest) = stub_request_args
    path = "https://#{organization_name}.visualstudio.com/#{project_name}/_apis/#{path}"

    stub_request(method, path, *rest).with(headers: headers, basic_auth: basic_auth)
  end
end
