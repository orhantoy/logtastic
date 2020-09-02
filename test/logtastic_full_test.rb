# frozen_string_literal: true

require "test_helper"

class LogtasticTest < Minitest::Test
  EXAMPLE_POLICY_PATH = File.join(__dir__, "example_policy.json")
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

  def test_with_ilm_enabled
    dataset = Logtastic.ecs(
      template: {
        name: "custom-logtastic",
        pattern: "custom-logtastic-ecs-development-*",
        settings: {
          index: TEMPLATE_SETTINGS
        },
        overwrite: false
      },
      ilm: {
        enabled: true,
        rollover_alias: "custom-logtastic-ecs-development",
        pattern: "{now/d}-000001",
        policy_name: "custom-policy-for-logtastic",
        policy_json: File.new(EXAMPLE_POLICY_PATH),
        overwrite: false
      }
    )

    dataset.write_now("message" => "This is an API request", "dataset" => "api")
    dataset.write_now("message" => "Analytics", "dataset" => "analytics")
    dataset.write_now("message" => "Analytics", "dataset" => "analytics")

    Logtastic.client.indices.refresh(index: dataset.query_index)

    assert_equal 1, dataset.count(body: { query: { bool: { filter: { term: { dataset: "api" } } } } }).fetch("count")
    assert_equal 2, dataset.count(body: { query: { bool: { filter: { term: { dataset: "analytics" } } } } }).fetch("count")
  ensure
    Logtastic.client.indices.delete(index: "custom-logtastic-*")

    begin
      Logtastic.client.indices.delete_template(name: "custom-logtastic")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Continue
    end

    begin
      Logtastic.client.xpack.ilm.delete_policy(policy_id: "custom-policy-for-logtastic")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Continue
    end
  end

  def test_with_ilm_disabled
    dataset = Logtastic.ecs(
      index: proc { |event| "custom-logtastic-ecs-development-#{event.dataset}-#{event.dig('agent', 'version')}-#{event.timestamp.strftime('%Y.%m.%d')}" },
      template: {
        name: "custom-logtastic",
        pattern: "custom-logtastic-ecs-development-*",
        settings: {
          index: TEMPLATE_SETTINGS
        },
        overwrite: false
      },
      ilm: {
        enabled: false
      }
    )

    dataset.write_now("message" => "This is an API request", "dataset" => "api")
    dataset.write_now("message" => "Analytics", "dataset" => "analytics")
    dataset.write_now("message" => "Analytics", "dataset" => "analytics")

    Logtastic.client.indices.refresh(index: dataset.query_index)

    assert_equal 1, dataset.count(body: { query: { bool: { filter: { term: { dataset: "api" } } } } }).fetch("count")
    assert_equal 2, dataset.count(body: { query: { bool: { filter: { term: { dataset: "analytics" } } } } }).fetch("count")
  ensure
    Logtastic.client.indices.delete(index: "custom-logtastic-ecs-development-*")

    begin
      Logtastic.client.indices.delete_template(name: "custom-logtastic")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Continue
    end
  end
end
