# frozen_string_literal: true

require "logtastic/event"
require "logtastic/setup"

module Logtastic
  class ECS
    def initialize(index: nil, template: nil, ilm: nil, version: "1.5", output: :default)
      @index = index
      @output = output
      @elasticsearch = Logtastic.client(@output)

      @setup = Logtastic::Setup.new(
        @elasticsearch,
        template: { json: { path: File.new(template_path(version)) } }.merge(template || {}),
        ilm: ilm
      )
      @setup.perform!
    end

    def write(event_hash)
      event = Event.new(event_hash)
      Logtastic.write(@output, index: write_index(event), body: event.body)
    end

    def write_now(event_hash)
      event = Event.new(event_hash)
      @elasticsearch.index(index: write_index(event), body: event.body)
    end

    def search(**args)
      @elasticsearch.search({ index: query_index }.merge(**args))
    end

    def count(**args)
      @elasticsearch.count({ index: query_index }.merge(**args))
    end

    def query_index
      if @setup.ilm_enabled?
        "#{@setup.rollover_alias}-*"
      else
        @setup.template_pattern
      end
    end

    private

    def write_index(event)
      if @index.nil?
        @setup.rollover_alias
      elsif @index.respond_to?(:call)
        @index.call(event)
      else
        @index
      end
    end

    def template_path(version)
      File.join(__dir__, "ecs-template-#{version}.json")
    end
  end
end
