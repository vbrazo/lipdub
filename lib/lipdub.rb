# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"

require_relative "lipdub/version"
require_relative "lipdub/configuration"
require_relative "lipdub/client"
require_relative "lipdub/errors"
require_relative "lipdub/resources/base"
require_relative "lipdub/resources/videos"
require_relative "lipdub/resources/audios"
require_relative "lipdub/resources/shots"
require_relative "lipdub/resources/projects"

module Lipdub
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.client
    @client ||= Client.new
  end
end
