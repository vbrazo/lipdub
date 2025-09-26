# frozen_string_literal: true

module Lipdub
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def get(path, params = {})
        client.get(path, params)
      end

      def post(path, body = {}, headers = {})
        client.post(path, body, headers)
      end

      def put(path, body = {}, headers = {})
        client.put(path, body, headers)
      end

      def put_file(url, file_content, content_type)
        client.put_file(url, file_content, content_type)
      end
    end
  end
end
