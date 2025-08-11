# frozen_string_literal: true

RSpec.describe Attio::Resources::WorkspaceMembers do
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:client) { instance_double(Attio::Client, connection: connection) }
  let(:workspace_members) { described_class.new(client) }

  describe "#list" do
    it "lists all workspace members" do
      expect(connection).to receive(:get)
        .with("workspace_members")
        .and_return({ "data" => [] })

      result = workspace_members.list
      expect(result).to eq({ "data" => [] })
    end

    it "lists workspace members with parameters" do
      params = { limit: 10, offset: "next_page" }
      expect(connection).to receive(:get)
        .with("workspace_members", params)
        .and_return({ "data" => [] })

      result = workspace_members.list(params)
      expect(result).to eq({ "data" => [] })
    end
  end

  describe "#get" do
    it "gets a specific workspace member" do
      member_id = "user_123"
      expect(connection).to receive(:get)
        .with("workspace_members/#{member_id}")
        .and_return({ "id" => member_id })

      result = workspace_members.get(member_id: member_id)
      expect(result).to eq({ "id" => member_id })
    end

    it "raises error for nil member_id" do
      expect { workspace_members.get(member_id: nil) }
        .to raise_error(ArgumentError, "Member ID is required")
    end

    it "raises error for empty member_id" do
      expect { workspace_members.get(member_id: "") }
        .to raise_error(ArgumentError, "Member ID is required")
    end
  end

  describe "#invite" do
    it "invites a new member with default role" do
      email = "new.member@example.com"
      expected_body = { email: email, role: "member" }

      expect(connection).to receive(:post)
        .with("workspace_members/invitations", expected_body)
        .and_return({ "id" => "inv_123" })

      result = workspace_members.invite(email: email)
      expect(result).to eq({ "id" => "inv_123" })
    end

    it "invites a new member with admin role" do
      email = "admin@example.com"
      role = "admin"
      expected_body = { email: email, role: role }

      expect(connection).to receive(:post)
        .with("workspace_members/invitations", expected_body)
        .and_return({ "id" => "inv_456" })

      result = workspace_members.invite(email: email, role: role)
      expect(result).to eq({ "id" => "inv_456" })
    end

    it "invites a member with additional data" do
      email = "member@example.com"
      role = "member"
      data = { department: "Sales", title: "Account Executive" }
      expected_body = data.merge(email: email, role: role)

      expect(connection).to receive(:post)
        .with("workspace_members/invitations", expected_body)
        .and_return({ "id" => "inv_789" })

      result = workspace_members.invite(email: email, role: role, data: data)
      expect(result).to eq({ "id" => "inv_789" })
    end

    it "raises error for invalid role" do
      expect { workspace_members.invite(email: "test@example.com", role: "superuser") }
        .to raise_error(ArgumentError, "Role must be one of: admin, member, guest")
    end

    it "raises error for nil email" do
      expect { workspace_members.invite(email: nil) }
        .to raise_error(ArgumentError, "Email is required")
    end

    it "raises error for empty email" do
      expect { workspace_members.invite(email: "") }
        .to raise_error(ArgumentError, "Email is required")
    end
  end

  describe "#update" do
    it "updates a member's role" do
      member_id = "user_123"
      data = { role: "admin" }

      expect(connection).to receive(:patch)
        .with("workspace_members/#{member_id}", data)
        .and_return({ "id" => member_id, "role" => "admin" })

      result = workspace_members.update(member_id: member_id, data: data)
      expect(result).to eq({ "id" => member_id, "role" => "admin" })
    end

    it "updates a member's permissions" do
      member_id = "user_456"
      data = { permissions: { can_edit: true, can_delete: false } }

      expect(connection).to receive(:patch)
        .with("workspace_members/#{member_id}", data)
        .and_return({ "id" => member_id })

      result = workspace_members.update(member_id: member_id, data: data)
      expect(result).to eq({ "id" => member_id })
    end

    it "raises error for nil member_id" do
      expect { workspace_members.update(member_id: nil, data: {}) }
        .to raise_error(ArgumentError, "Member ID is required")
    end

    it "raises error for nil data" do
      expect { workspace_members.update(member_id: "user_123", data: nil) }
        .to raise_error(ArgumentError, "Data is required")
    end
  end

  describe "#remove" do
    it "removes a member from the workspace" do
      member_id = "user_123"

      expect(connection).to receive(:delete)
        .with("workspace_members/#{member_id}")
        .and_return({ "success" => true })

      result = workspace_members.remove(member_id: member_id)
      expect(result).to eq({ "success" => true })
    end

    it "raises error for nil member_id" do
      expect { workspace_members.remove(member_id: nil) }
        .to raise_error(ArgumentError, "Member ID is required")
    end

    it "raises error for empty member_id" do
      expect { workspace_members.remove(member_id: "") }
        .to raise_error(ArgumentError, "Member ID is required")
    end
  end

  describe "#accept_invitation" do
    it "accepts a workspace invitation" do
      token = "inv_token_123"

      expect(connection).to receive(:post)
        .with("workspace_members/invitations/#{token}/accept")
        .and_return({ "id" => "user_123" })

      result = workspace_members.accept_invitation(invitation_token: token)
      expect(result).to eq({ "id" => "user_123" })
    end

    it "raises error for nil invitation_token" do
      expect { workspace_members.accept_invitation(invitation_token: nil) }
        .to raise_error(ArgumentError, "Invitation token is required")
    end

    it "raises error for empty invitation_token" do
      expect { workspace_members.accept_invitation(invitation_token: "") }
        .to raise_error(ArgumentError, "Invitation token is required")
    end
  end

  describe "#resend_invitation" do
    it "resends an invitation to a member" do
      member_id = "user_123"

      expect(connection).to receive(:post)
        .with("workspace_members/#{member_id}/resend_invitation")
        .and_return({ "success" => true })

      result = workspace_members.resend_invitation(member_id: member_id)
      expect(result).to eq({ "success" => true })
    end

    it "raises error for nil member_id" do
      expect { workspace_members.resend_invitation(member_id: nil) }
        .to raise_error(ArgumentError, "Member ID is required")
    end
  end

  describe "#me" do
    it "gets the current authenticated member" do
      expect(connection).to receive(:get)
        .with("workspace_members/me")
        .and_return({ "id" => "current_user", "email" => "me@example.com" })

      result = workspace_members.me
      expect(result).to eq({ "id" => "current_user", "email" => "me@example.com" })
    end
  end
end