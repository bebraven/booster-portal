environment_configuration(defined?(config) && config) do |config|
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # run rake js:build to build the optimized JS if set to true
  # ENV['USE_OPTIMIZED_JS']                            = 'true'

  # Really do care if the message wasn't sent.
  config.action_mailer.raise_delivery_errors = true

  # initialize cache store. has to eval, not just require, so that it has
  # access to config.
  cache_store_rb = File.dirname(__FILE__) + "/cache_store.rb"
  eval(File.new(cache_store_rb).read, nil, cache_store_rb, 1)

  # allow debugging only in development environment by default
  #
  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    if RUBY_VERSION >= '2.0.0'
      require 'byebug'
      if ENV['REMOTE_DEBUGGING_ENABLED']
        require 'byebug/core'
        Byebug.start_server('0.0.0.0', 0)
        puts "Byebug listening on 0.0.0.0:#{Byebug.actual_port}" # rubocop:disable Rails/Output
        byebug_port_file = File.join(Dir.tmpdir, 'byebug.port')
        File.write(byebug_port_file, Byebug.actual_port)
      end
    else
    end
  end

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # we use lots of db specific stuff - don't bother trying to dump to ruby
  # (it also takes forever)
  config.active_record.schema_format = :sql

  config.eager_load = false

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read, nil, localfile, 1) }
end
