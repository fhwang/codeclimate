require "securerandom"

module CC
  module Analyzer
    class EnginesRunner
      InvalidEngineName = Class.new(StandardError)
      NoEnabledEngines = Class.new(StandardError)

      def initialize(registry, formatter, source_dir, config, requested_paths = [], container_label = nil)
        @registry = registry
        @formatter = formatter
        @source_dir = source_dir
        @config = config
        @requested_paths = requested_paths
        @container_label = container_label
      end

      def run(container_listener = ContainerListener.new)
        raise NoEnabledEngines if engines.empty?

        @formatter.started

        engines.each { |engine| run_engine(engine, container_listener) }

        @formatter.finished
      ensure
        @formatter.close if @formatter.respond_to?(:close)
      end

      private

      attr_reader :requested_paths

      def engines
        @engines ||= Engines.new(
          registry: @registry,
          config: @config,
          container_label: @container_label,
          source_dir: @source_dir,
          requested_paths: @requested_paths
        )
      end

      def run_engine(engine, container_listener)
        @formatter.engine_running(engine) do
          container_result = engine.run(@formatter, container_listener)
          if container_result.timed_out?
            message = "engine #{engine.name} ran for #{container_result.duration} seconds"
            message << " and was killed"
            raise Engine::EngineTimeout, message
          elsif container_result.exitstatus != 0
            message = "engine #{engine.name} failed"
            message << " with status #{container_result.exitstatus}"
            message << " and stderr \n#{container_result.stderr}"
            raise Engine::EngineFailure, message
          end
        end
      end
    end
  end
end
