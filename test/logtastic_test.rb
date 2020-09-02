# frozen_string_literal: true

require "test_helper"

class LogtasticTest < Minitest::Test
  TEMPLATE_SETTINGS = {
    "number_of_shards" => 1,
    "number_of_replicas" => 0,
    "refresh_interval" => -1
  }

  def setup
    Logtastic.elasticsearch(
      :default,
      options: {
        logger: ENV.fetch("ES_LOG", "true") == "true" ? Logger.new(STDOUT) : nil,
        url: ENV.fetch("ES_URL", "http://localhost:9200")
      }
    )
  end

  def teardown
    Logtastic.client.indices.delete(index: "logtastic-*")

    begin
      Logtastic.client.indices.delete_template(name: "logtastic")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Continue
    end

    begin
      Logtastic.client.xpack.ilm.delete_policy(policy_id: "logtastic")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Continue
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::Logtastic::VERSION
  end

  def test_write
    dataset = Logtastic.ecs(
      template: {
        settings: {
          index: TEMPLATE_SETTINGS
        }
      }
    )

    Logtastic.watch(execution_interval: 1)

    dataset.write("message" => "First event")
    dataset.write("message" => "Second event")
    dataset.write("message" => "Third event")

    sleep 1 # Wait for timer task to trigger
    Logtastic.client.indices.refresh(index: dataset.query_index)

    assert_equal 1, dataset.count(q: "first").fetch("count")
    assert_equal 3, dataset.count(q: "event").fetch("count")
  end

  def test_write_now
    dataset = Logtastic.ecs(
      template: {
        settings: {
          index: TEMPLATE_SETTINGS
        }
      }
    )

    dataset.write_now("message" => "First event")
    dataset.write_now("message" => "Second event")
    dataset.write_now("message" => "Third event")

    Logtastic.client.indices.refresh(index: dataset.query_index)

    assert_equal 1, dataset.count(q: "first").fetch("count")
    assert_equal 3, dataset.count(q: "event").fetch("count")
  end
end
