# frozen_string_literal: true

require "json"

module Logtastic
  class Setup
    class Error < StandardError; end
    class AliasAlreadyExists < Error; end

    DEFAULT_ILM_POLICY = {
      "policy" => {
        "phases" => {
          "hot" => {
            "actions" => {
              "rollover" => {
                "max_size" => "50gb",
                "max_age" => "30d"
              }
            }
          }
        }
      }
    }.freeze

    def initialize(elasticsearch, template: nil, ilm: nil)
      @elasticsearch = elasticsearch
      @template = template || {}
      @ilm = ilm || {}
    end

    def perform!
      @elasticsearch.xpack.ilm.put_policy(put_ilm_policy_args) if put_ilm_policy?
      @elasticsearch.indices.put_template(put_template_args) if put_template?

      begin
        @elasticsearch.indices.create(create_rollover_alias_args) if create_rollover_alias?
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        raise AliasAlreadyExists, "An index exists with the same name as the alias [#{rollover_alias}]"
      end

      true
    end

    def ilm_enabled?
      @ilm.fetch(:enabled, true)
    end

    def ilm_overwrite?
      @ilm.fetch(:overwrite, false)
    end

    def ilm_policy_id
      @ilm.fetch(:policy_name, "logtastic")
    end

    def rollover_alias
      @ilm.fetch(:rollover_alias, "logtastic")
    end

    def ilm_pattern
      @ilm.fetch(:pattern, "{now/d}-000001")
    end

    def ilm_policy_body
      policy_file = @ilm.fetch(:policy_file, DEFAULT_ILM_POLICY)

      if policy_file.is_a?(Hash)
        policy_file
      else
        JSON.load(policy_file)
      end
    end

    def put_ilm_policy?
      return false unless ilm_enabled?
      return true if ilm_overwrite?

      begin
        @elasticsearch.xpack.ilm.get_policy(policy_id: ilm_policy_id)
        false
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        true
      end
    end

    def put_ilm_policy_args
      {
        policy_id: ilm_policy_id,
        body: ilm_policy_body
      }
    end

    def template_name
      @template.fetch(:name, "logtastic")
    end

    def template_pattern
      @template.fetch(:pattern, "logtastic-*")
    end

    def template_body
      JSON.load(@template.dig(:json, :path)).tap do |base_template|
        index_patterns = Array(template_pattern)
        base_template["index_patterns"] = index_patterns unless index_patterns.empty?
        base_template["settings"]["index"].merge!(template_index_settings)
      end
    end

    def template_index_settings
      {}.tap do |hash|
        if ilm_enabled?
          hash.merge!(
            "lifecycle.name" => ilm_policy_id,
            "lifecycle.rollover_alias" => rollover_alias
          )
        end

        hash.merge!(@template.dig(:settings, :index)) if @template.dig(:settings, :index)
      end
    end

    def template_overwrite?
      @template.fetch(:overwrite, false)
    end

    def put_template?
      return true if template_overwrite?

      !@elasticsearch.indices.exists_template?(name: template_name)
    end

    def put_template_args
      {
        name: template_name,
        create: !template_overwrite?,
        body: template_body
      }
    end

    def create_rollover_alias?
      return false unless ilm_enabled?

      !@elasticsearch.indices.exists_alias?(name: rollover_alias)
    end

    def create_rollover_alias_args
      {
        index: "<#{rollover_alias}-#{ilm_pattern}>",
        body: {
          "aliases" => {
            rollover_alias => {
              "is_write_index" => true
            }
          }
        }
      }
    end
  end
end
