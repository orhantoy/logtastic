# frozen_string_literal: true

require "logtastic/version"
require "logtastic/ecs"
require "elasticsearch"
require "elasticsearch/xpack"
require "concurrent/array"
require "concurrent/timer_task"

module Logtastic
  @elasticsearch = {}
  @events = Concurrent::Array.new
  @watching = Concurrent::AtomicBoolean.new(false)

  TIMER_EXECUTION_INTERVAL = 3 # seconds
  MAX_SLICE_EVENTS = 100

  class << self
    def elasticsearch(output, options: nil, client: nil)
      if options || client
        @elasticsearch[output] = client || Elasticsearch::Client.new(options)
      else
        @elasticsearch.fetch(output)
      end
    end

    def ecs(output = :default, **args)
      if output == :default && !@elasticsearch.key?(output)
        elasticsearch(output, client: Elasticsearch::Client.new)
      else
        elasticsearch(output)
      end

      ECS.new(**args, output: output)
    end

    def client(output = :default)
      @elasticsearch.fetch(output)
    end

    def write(output, index:, body:)
      @events << { output: output, index: index, body: body }
      watch
    end

    def watch(execution_interval: TIMER_EXECUTION_INTERVAL)
      return unless @watching.make_true

      Concurrent::TimerTask.execute(execution_interval: execution_interval, run_now: true) do
        bulk_index
      end
    end

    def bulk_index(limit = MAX_SLICE_EVENTS)
      events = @events.slice!(0, limit)
      grouped_events = events.group_by { |event| event.fetch(:output) }
      grouped_events.each do |output, group_events|
        bulk_body = group_events.map do |event|
          {
            index: {
              _index: event.fetch(:index),
              data: event.fetch(:body)
            }
          }
        end

        client(output).bulk(body: bulk_body)
      end
    end
  end
end
