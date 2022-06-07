# frozen_string_literal: true

require 'sidekiq/component'

module Sidekiq
  module History
    class Middleware
      include Sidekiq::Component

      def call(_worker, msg, queue)
        # Use the Sidekiq API to unwrap the job
        job_record = Sidekiq::JobRecord.new(msg)

        data = data_for(job_record).merge(queue:)

        Sidekiq.redis do |conn|
          if Sidekiq::History.record_to_history?(job_record.display_class)
            conn.zadd(LIST_KEY, data[:started_at].to_f, Sidekiq.dump_json(data))
          end

          conn.zremrangebyrank(LIST_KEY, 0, -(Sidekiq::History.max_count + 1)) if Sidekiq::History.max_count
        end

        yield
      end

      private

      def data_for(job_record)
        # Set up an unwrapped copy of the bare job data
        payload = job_record.value.dup.tap do |info|
          info['class'] = job_record.display_class
          info['args'] = job_record.display_args
        end

        {
          started_at: Time.now.utc,
          payload:,
          worker: job_record.display_class,
          processor: "#{identity}-#{Thread.current.object_id}"
        }
      end
    end
  end
end
