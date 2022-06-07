# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/history/version'
require 'sidekiq/history/middleware'
require 'sidekiq/history/web_extension'

module Sidekiq
  module History
    LIST_KEY = :history

    class << self
      attr_accessor :include_jobs, :exclude_jobs
      attr_writer :max_count
    end

    # Check if a job should be recorded. Inclusion takes precedence over exclusion.
    def self.record_to_history?(job_class)
      return include_jobs.include?(job_class) unless include_jobs.nil?

      return !exclude_jobs.include?(job_class) unless exclude_jobs.nil?

      true
    end

    # Use a default of 1000 unless specified. Max is 4294967295 per Redis Sorted Set limit.
    def self.max_count = @max_count.nil? ? 1000 : [@max_count, 4_294_967_295].min

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
