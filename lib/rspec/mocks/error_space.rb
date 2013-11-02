module RSpec
  module Mocks
    class ErrorSpace
      def proxy_for(*args)
        raise_lifecycle_message
      end

      def any_instance_recorder_for(*args)
        raise_lifecycle_message
      end

      def reset_all
      end

      private

      def raise_lifecycle_message
        raise "The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported."
      end
    end
  end
end
