# frozen_string_literal: true

require "json"
require "logger"

module Attio
  # Observability and instrumentation for Attio client
  #
  # @example Basic usage
  #   client.instrumentation = Attio::Observability.new(
  #     logger: Rails.logger,
  #     metrics_backend: :datadog
  #   )
  module Observability
    # Base instrumentation class
    class Instrumentation
      attr_reader :logger, :metrics, :traces

      def initialize(logger: nil, metrics_backend: nil, trace_backend: nil)
        @logger = logger || Logger.new($stdout)
        @metrics = Metrics.for(metrics_backend) if metrics_backend
        @traces = Traces.for(trace_backend) if trace_backend
        @enabled = true
      end

      # Record an API call
      #
      # @param method [Symbol] HTTP method
      # @param path [String] API path
      # @param duration [Float] Call duration in seconds
      # @param status [Integer] HTTP status code
      # @param error [Exception] Error if any
      def record_api_call(method:, path:, duration:, status: nil, error: nil)
        return unless @enabled

        log_api_call(method, path, duration, status, error)
        record_api_metrics(method, path, duration, error) if @metrics
        record_api_trace(method, path, status, error) if @traces
      end

      # Record rate limit information
      #
      # @param remaining [Integer] Requests remaining
      # @param limit [Integer] Rate limit
      # @param reset_at [Time] When limit resets
      def record_rate_limit(remaining:, limit:, reset_at:)
        return unless @enabled

        utilization = 1.0 - (remaining.to_f / limit)

        @logger.debug(format_log_entry(
                        event: "rate_limit",
                        remaining: remaining,
                        limit: limit,
                        utilization: utilization.round(3),
                        reset_in: (reset_at - Time.now).to_i
                      ))

        @metrics&.gauge("attio.rate_limit.remaining", remaining)
        @metrics&.gauge("attio.rate_limit.utilization", utilization)
      end

      # Record cache hit/miss
      #
      # @param key [String] Cache key
      # @param hit [Boolean] Whether it was a hit
      def record_cache(key:, hit:)
        return unless @enabled

        @logger.debug(format_log_entry(
                        event: "cache",
                        key: key,
                        hit: hit
                      ))

        @metrics&.increment("attio.cache.#{hit ? 'hits' : 'misses'}")
      end

      # Record circuit breaker state change
      #
      # @param endpoint [String] Endpoint name
      # @param old_state [Symbol] Previous state
      # @param new_state [Symbol] New state
      def record_circuit_breaker(endpoint:, old_state:, new_state:)
        return unless @enabled

        @logger.warn(format_log_entry(
                       event: "circuit_breaker",
                       endpoint: endpoint,
                       old_state: old_state,
                       new_state: new_state
                     ))

        @metrics&.increment("attio.circuit_breaker.transitions", tags: {
          from: old_state,
          to: new_state,
        })
      end

      # Record connection pool stats
      #
      # @param stats [Hash] Pool statistics
      def record_pool_stats(stats)
        return unless @enabled

        @metrics&.gauge("attio.pool.size", stats[:size])
        @metrics&.gauge("attio.pool.available", stats[:available])
        @metrics&.gauge("attio.pool.allocated", stats[:allocated])
        @metrics&.gauge("attio.pool.utilization", stats[:allocated].to_f / stats[:size])
      end

      # Disable instrumentation
      def disable!
        @enabled = false
      end

      # Enable instrumentation
      def enable!
        @enabled = true
      end

      private def format_log_entry(**fields)
        fields[:timestamp] = Time.now.iso8601
        fields[:service] = "attio-ruby"
        JSON.generate(fields)
      end

      private def sanitize_path(path)
        # Remove IDs from paths for metric aggregation
        path.gsub(%r{/[a-f0-9-]{36}}, "/:id")            # UUIDs
            .gsub(%r{/[a-zA-Z]+-\d+-[a-zA-Z]+}, "/:id")  # IDs like abc-123-def
            .gsub(%r{/\d+}, "/:id")                      # Numeric IDs
      end

      private def log_api_call(method, path, duration, status, error)
        @logger.info(format_log_entry(
                       event: "api_call",
                       method: method,
                       path: path,
                       duration_ms: (duration * 1000).round(2),
                       status: status,
                       error: error&.class&.name
                     ))
      end

      private def record_api_metrics(method, path, duration, error)
        @metrics.increment("attio.api.calls", tags: { method: method, path: sanitize_path(path) })
        @metrics.histogram("attio.api.duration", duration * 1000, tags: { method: method })

        return unless error

        @metrics.increment("attio.api.errors", tags: {
          method: method,
          error_class: error.class.name,
        })
      end

      private def record_api_trace(method, path, status, error)
        @traces.span("attio.api.call") do |span|
          span.set_attribute("http.method", method.to_s)
          span.set_attribute("http.path", path)
          span.set_attribute("http.status_code", status) if status
          span.set_attribute("error", true) if error
        end
      end
    end

    # Metrics backends
    module Metrics
      def self.for(backend)
        case backend
        when :datadog then Datadog.new
        when :statsd then StatsD.new
        when :prometheus then Prometheus.new
        when :memory then Memory.new
        else
          raise ArgumentError, "Unknown metrics backend: #{backend}"
        end
      end

      # In-memory metrics for testing
      class Memory
        attr_reader :counters, :gauges, :histograms

        def initialize
          @counters = Hash.new(0)
          @gauges = {}
          @histograms = Hash.new { |h, k| h[k] = [] }
        end

        def increment(metric, tags: {})
          key = tags.empty? ? "#{metric}:" : "#{metric}:#{format_tags(tags)}"
          @counters[key] += 1
        end

        def gauge(metric, value, tags: {})
          key = tags.empty? ? "#{metric}:" : "#{metric}:#{format_tags(tags)}"
          @gauges[key] = value
        end

        def histogram(metric, value, tags: {})
          key = tags.empty? ? "#{metric}:" : "#{metric}:#{format_tags(tags)}"
          @histograms[key] << value
        end

        def reset!
          @counters.clear
          @gauges.clear
          @histograms.clear
        end

        private def format_tags(tags)
          # Format tags in a consistent way that works across Ruby versions
          sorted = tags.sort.to_h
          content = sorted.map { |k, v| ":#{k}=>#{v.inspect}" }.join(", ")
          "{#{content}}"
        end
      end

      # StatsD metrics
      class StatsD
        def initialize
          require "statsd-ruby"
          @client = ::Statsd.new("localhost", 8125)
        rescue LoadError
          raise "Please add 'statsd-ruby' to your Gemfile"
        end

        def increment(metric, tags: {})
          @client.increment(metric, tags: format_tags(tags))
        end

        def gauge(metric, value, tags: {})
          @client.gauge(metric, value, tags: format_tags(tags))
        end

        def histogram(metric, value, tags: {})
          @client.histogram(metric, value, tags: format_tags(tags))
        end

        private def format_tags(tags)
          tags.map { |k, v| "#{k}:#{v}" }
        end
      end

      # Datadog metrics
      class Datadog
        def initialize
          require "datadog/statsd"
          @client = ::Datadog::Statsd.new("localhost", 8125)
        rescue LoadError
          raise "Please add 'dogstatsd-ruby' to your Gemfile"
        end

        def increment(metric, tags: {})
          @client.increment(metric, tags: format_tags(tags))
        end

        def gauge(metric, value, tags: {})
          @client.gauge(metric, value, tags: format_tags(tags))
        end

        def histogram(metric, value, tags: {})
          @client.histogram(metric, value, tags: format_tags(tags))
        end

        private def format_tags(tags)
          tags.map { |k, v| "#{k}:#{v}" }
        end
      end

      # Prometheus metrics
      class Prometheus
        def initialize
          require "prometheus/client"
          @registry = ::Prometheus::Client.registry
          @counters = {}
          @gauges = {}
          @histograms = {}
        rescue LoadError
          raise "Please add 'prometheus-client' to your Gemfile"
        end

        def increment(metric, tags: {})
          counter = @counters[metric] ||= @registry.counter(
            metric.to_sym,
            docstring: "Counter for #{metric}",
            labels: tags.keys
          )
          counter.increment(labels: tags)
        end

        def gauge(metric, value, tags: {})
          gauge = @gauges[metric] ||= @registry.gauge(
            metric.to_sym,
            docstring: "Gauge for #{metric}",
            labels: tags.keys
          )
          gauge.set(value, labels: tags)
        end

        def histogram(metric, value, tags: {})
          histogram = @histograms[metric] ||= @registry.histogram(
            metric.to_sym,
            docstring: "Histogram for #{metric}",
            labels: tags.keys
          )
          histogram.observe(value, labels: tags)
        end
      end
    end

    # Tracing backends
    module Traces
      def self.for(backend)
        case backend
        when :opentelemetry then OpenTelemetry.new
        when :datadog then DatadogAPM.new
        when :memory then Memory.new
        else
          raise ArgumentError, "Unknown trace backend: #{backend}"
        end
      end

      # OpenTelemetry tracing
      class OpenTelemetry
        def initialize
          require "opentelemetry-sdk"
          @tracer = ::OpenTelemetry.tracer_provider.tracer("attio-ruby")
        rescue LoadError
          raise "Please add 'opentelemetry-sdk' to your Gemfile"
        end

        def span(name, &block)
          @tracer.in_span(name, &block)
        end
      end

      # Datadog APM tracing
      class DatadogAPM
        def initialize
          require "datadog"
          @tracer = ::Datadog::Tracing
        rescue LoadError
          raise "Please add 'datadog' to your Gemfile"
        end

        def span(name)
          @tracer.trace(name) do |span|
            yield(span) if block_given?
          end
        end
      end

      # In-memory tracing for testing
      class Memory
        attr_reader :spans

        def initialize
          @spans = []
        end

        def span(name)
          span = Span.new(name)
          @spans << span
          yield(span) if block_given?
          span
        end

        def reset!
          @spans.clear
        end

        class Span
          attr_reader :name, :attributes

          def initialize(name)
            @name = name
            @attributes = {}
          end

          def set_attribute(key, value)
            @attributes[key] = value
          end
        end
      end
    end

    # Middleware for automatic instrumentation
    class Middleware
      def initialize(app, instrumentation)
        @app = app
        @instrumentation = instrumentation
      end

      def call(env)
        start_time = Time.now
        method = env[:method]
        path = env[:url].path

        begin
          response = @app.call(env)

          @instrumentation.record_api_call(
            method: method,
            path: path,
            duration: Time.now - start_time,
            status: response.status
          )

          response
        rescue StandardError => e
          @instrumentation.record_api_call(
            method: method,
            path: path,
            duration: Time.now - start_time,
            error: e
          )
          raise
        end
      end
    end
  end
end
