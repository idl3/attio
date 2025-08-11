# frozen_string_literal: true

module Attio
  module Resources
    # Workspace Members resource for managing workspace member access
    #
    # @example List all workspace members
    #   client.workspace_members.list
    #
    # @example Get a specific member
    #   client.workspace_members.get(member_id: "user_123")
    #
    # @example Invite a new member
    #   client.workspace_members.invite(
    #     email: "new.member@example.com",
    #     role: "member"
    #   )
    class WorkspaceMembers < Base
      # List all workspace members
      #
      # @param params [Hash] Optional query parameters
      # @option params [Integer] :limit Maximum number of results
      # @option params [String] :offset Pagination offset
      # @return [Hash] The API response
      def list(params = {})
        request(:get, "workspace_members", params)
      end

      # Get a specific workspace member
      #
      # @param member_id [String] The member ID
      # @return [Hash] The member data
      def get(member_id:)
        validate_id!(member_id, "Member")
        request(:get, "workspace_members/#{member_id}")
      end

      # Invite a new member to the workspace
      #
      # @param email [String] The email address to invite
      # @param role [String] The role to assign (admin, member, guest)
      # @param data [Hash] Additional member data
      # @return [Hash] The created invitation
      def invite(email:, role: "member", data: {})
        validate_required_string!(email, "Email")
        validate_required_string!(role, "Role")

        raise ArgumentError, "Role must be one of: admin, member, guest" unless %w[admin member guest].include?(role)

        body = data.merge(email: email, role: role)
        request(:post, "workspace_members/invitations", body)
      end

      # Update a workspace member's role or permissions
      #
      # @param member_id [String] The member ID to update
      # @param data [Hash] The data to update
      # @option data [String] :role The new role
      # @option data [Hash] :permissions Custom permissions
      # @return [Hash] The updated member
      def update(member_id:, data:)
        validate_id!(member_id, "Member")
        validate_required_hash!(data, "Data")

        request(:patch, "workspace_members/#{member_id}", data)
      end

      # Remove a member from the workspace
      #
      # @param member_id [String] The member ID to remove
      # @return [Hash] Confirmation of removal
      def remove(member_id:)
        validate_id!(member_id, "Member")
        request(:delete, "workspace_members/#{member_id}")
      end

      # Accept a workspace invitation
      #
      # @param invitation_token [String] The invitation token
      # @return [Hash] The workspace member data
      def accept_invitation(invitation_token:)
        validate_required_string!(invitation_token, "Invitation token")
        request(:post, "workspace_members/invitations/#{invitation_token}/accept")
      end

      # Resend an invitation
      #
      # @param member_id [String] The member ID with pending invitation
      # @return [Hash] Confirmation of resent invitation
      def resend_invitation(member_id:)
        validate_id!(member_id, "Member")
        request(:post, "workspace_members/#{member_id}/resend_invitation")
      end

      # Get current member (self)
      #
      # @return [Hash] The current authenticated member's data
      def me
        request(:get, "workspace_members/me")
      end
    end
  end
end
