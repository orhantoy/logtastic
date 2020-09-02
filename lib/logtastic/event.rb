# frozen_string_literal: true

require "logtastic/version"

module Logtastic
  class Event
    TIMESTAMP_FIELD = "@timestamp"
    AGENT = { "name" => "Logtastic", "version" => Logtastic::VERSION }.freeze

    attr_reader :timestamp

    def initialize(event_hash)
      @event_hash = event_hash.reject { |k, _| [TIMESTAMP_FIELD, TIMESTAMP_FIELD.to_sym].include?(k) }
      @timestamp = event_hash[TIMESTAMP_FIELD.to_sym] || event_hash[TIMESTAMP_FIELD] || Time.now
    end

    def body
      @body ||= { TIMESTAMP_FIELD => @timestamp.strftime("%FT%T%:z"), "agent" => AGENT }.merge!(@event_hash)
    end

    def method_missing(method_name, *arguments, &block)
      if body.respond_to?(method_name)
        body.public_send(method_name, *arguments)
      elsif body.key?(method_name)
        body.fetch(method_name)
      elsif body.key?(method_name.to_s)
        body.fetch(method_name.to_s)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      body.respond_to?(method_name) || body.key?(method_name) || body.key?(method_name.to_s) || super
    end
  end
end
