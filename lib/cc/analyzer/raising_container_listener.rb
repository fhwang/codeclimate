module CC
  module Analyzer
    class RaisingContainerListener < ContainerListener
      def initialize(engine_name, failure_ex, timeout_ex)
        @engine_name = engine_name
        @failure_ex = failure_ex
        @timeout_ex = timeout_ex
      end

      def timed_out(data)
        message = "engine #{engine_name} ran for #{data.duration} seconds"
        message << " and was killed"

        raise timeout_ex, message
      end

      def finished(data)
        Analyzer.logger.warn("Analyzer::RaisingContainerListener#finished 0 #{data.status.success?}")
        unless data.status.success?
          Analyzer.logger.warn("Analyzer::RaisingContainerListener#finished 3 #{engine_name} #{data.status.existatus} #{data.stderr}")
          message = "engine #{engine_name} failed"
          message << " with status #{data.status.exitstatus}"
          message << " and stderr \n#{data.stderr}"

          raise failure_ex, message
        end
      end

      private

      attr_reader :engine_name, :failure_ex, :timeout_ex
    end
  end
end
