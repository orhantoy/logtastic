# Logtastic

Log directly to Elasticsearch, inspired by Filebeat.

Logtastic provides a flexible and simple way for you to index your custom application log/data into Elasticsearch.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logtastic'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install logtastic

## Usage

```ruby
# Configure which Elasticsearch cluster to write to
Logtastic.elasticsearch(:default, options: { url: ENV.fetch("ES_URL", "http://localhost:9200") })

# The configuration options are similar to Filebeat.
logtastic_http = Logtastic.ecs(
  template: {
    name: "my-app-http-requests-tpl",
    pattern: "my-app-http-requests-*",
    settings: {
      index: {
        "number_of_shards" => 1,
        "number_of_replicas" => 0
      }
    },
    overwrite: false
  },
  ilm: {
    enabled: true,
    rollover_alias: "my-app-http-requests",
    policy_name: "my-app-http-requests-ilm",
    overwrite: false
  }
)

# Writes will be batched and automatically written to the Elasticsearch cluster in a background thread.
logtastic_http.write("message" => "Sending an ECS-formatted payload...")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
Note: make sure to have a running Elasticsearch instance to successfully run the tests. The `ES_URL` environment variable can be set to specify the Elasticsearch URL and credentials, e.g. `ES_URL=http://elastic:changeme@localhost:9200 rake test`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/orhantoy/logtastic. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/orhantoy/logtastic/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Logtastic project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/orhantoy/logtastic/blob/master/CODE_OF_CONDUCT.md).
