# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/history/version'
require 'sidekiq/history/middleware'
require 'sidekiq/history/web_extension'

module Sidekiq
  module History
    LIST_KEY = :history

    # Check if a job should be recorded. Inclusion takes precedence over exclusion.
    def record_to_history?(job_class)
      return include_jobs.include?(job_class) if include_jobs.any?

      return !exclude_jobs.include?(job_class) if exclude_jobs.any?

      true
    end

    def self.max_count=(value)
      @max_count = value
    end

    def self.max_count
      return @max_count unless @max_count.nil?

      # Use a default of 1000 unless specified in config. Max is 4294967295 per Redis Sorted Set limit.
      defined?(MAX_COUNT) ? [MAX_COUNT, 4_294_967_295].min : 1000
    end

    def self.exclude_jobs=(value)
      @exclude_jobs = value
    end

    def self.exclude_jobs
      return @exclude_jobs unless @exclude_jobs.nil?

      return Sidekiq::History::EXCLUDE_JOBS if defined? Sidekiq::History::EXCLUDE_JOBS

      []
    end

    def self.include_jobs=(value)
      @include_jobs = value
    end

    def self.include_jobs
      return @include_jobs unless @include_jobs.nil?

      return Sidekiq::History::INCLUDE_JOBS if defined? Sidekiq::History::INCLUDE_JOBS

      []
    end

    def self.reset_history(counter: false)
      Sidekiq.redis do |conn|
        conn.multi do
          conn.del(LIST_KEY)

          conn.set('stat:history', 0) if counter
        end
      end
    end

    def self.count = Sidekiq.redis { _1.zcard(LIST_KEY) }

    class HistorySet < Sidekiq::JobSet
      def initialize = super LIST_KEY
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware { _1.add Sidekiq::History::Middleware }
end

Sidekiq::Web.register(Sidekiq::History::WebExtension)

Sidekiq::Web.tabs['History'] = 'history'
