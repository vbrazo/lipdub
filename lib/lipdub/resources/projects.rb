# frozen_string_literal: true

module Lipdub
  module Resources
    class Projects < Base
      # List all projects
      #
      # @param page [Integer] Page number for pagination (defaults to 1)
      # @param per_page [Integer] Number of items per page, max 100 (defaults to 20)
      # @return [Hash] Response containing list of projects and count
      #
      # @example
      #   projects = client.projects.list(page: 1, per_page: 50)
      #   # => {
      #   #   "data" => [
      #   #     {
      #   #       "project_id" => 123,
      #   #       "projects_tenant_id" => 1,
      #   #       "projects_user_id" => 47,
      #   #       "project_name" => "My Sample Project",
      #   #       "user_email" => "user@example.com",
      #   #       "created_at" => "2024-01-15T10:30:00Z",
      #   #       "updated_at" => nil,
      #   #       "source_language" => {
      #   #         "language_id" => 1,
      #   #         "name" => "English",
      #   #         "supported" => true
      #   #       },
      #   #       "project_identity_type" => "single_identity",
      #   #       "language_project_links" => []
      #   #     }
      #   #   ],
      #   #   "count" => 1
      #   # }
      def list(page: 1, per_page: 20)
        validate_pagination_params!(page, per_page)
        
        params = {
          page: page,
          per_page: per_page
        }
        get("/v1/projects", params)
      end

      private

      def validate_pagination_params!(page, per_page)
        raise ValidationError, "Page must be >= 1" if page < 1
        raise ValidationError, "Per page must be between 1 and 100" unless (1..100).include?(per_page)
      end
    end
  end
end
