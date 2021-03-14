# frozen_string_literal: true

RSpec.describe Abt::Providers::Devops::Api do
  context "when request returns a 403 status" do
    it "raises a ForbiddenError" do
      stub_request(:post, "https://org-name.visualstudio.com/project-name/_apis/path")
        .with(headers: { "Content-Type" => "application/json", "Accept" => "application/json; api-version=6.0" },
              basic_auth: %w[username access_token])
        .to_return(status: 403)

      api = Abt::Providers::Devops::Api.new(organization_name: "org-name",
                                            project_name: "project-name",
                                            username: "username",
                                            access_token: "access_token",
                                            cli: nil)

      expect { api.post("path") }.to raise_error(Abt::HttpError::ForbiddenError)
    end

    context "when conditional access policy denial" do
      it "aborts with correct error message" do
        conditional_access_policy_body = <<~TXT
          {"$id":"1","innerException":null,"message":"VS403463: The conditional access policy defined by your Azure Active Directory administrator has failed.","typeName":"Microsoft.VisualStudio.Services.Common.VssServiceException, Microsoft.VisualStudio.Services.Common","typeKey":"VssServiceException","errorCode":0,"eventId":3000}
        TXT

        stub_request(:post, "https://org-name.visualstudio.com/project-name/_apis/path")
          .with(headers: { "Content-Type" => "application/json", "Accept" => "application/json; api-version=6.0" },
                basic_auth: %w[username access_token])
          .to_return(status: 403, body: conditional_access_policy_body.strip)

        cli = Abt::Cli.new
        api = Abt::Providers::Devops::Api.new(organization_name: "org-name",
                                              project_name: "project-name",
                                              username: "username",
                                              access_token: "access_token",
                                              cli: cli)

        expect { api.post("path") }.to raise_error do |error|
          expect(error).to be_an(Abt::Cli::Abort)
          expect(error.message).to include("Access denied by conditional access policy.")
        end
      end
    end
  end
end
