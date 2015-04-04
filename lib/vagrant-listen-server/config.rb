module VagrantPlugins
  module ListenServer
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :port

      def initialize
        @port = 4000
      end

      def finalize!
      end
    end
  end
end
