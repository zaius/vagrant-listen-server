require 'listen'
require 'socket'
require 'json'

module VagrantPlugins
  module ListenServer
    module Action
      class StartServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          out = @app.call(env)
          # config = env[:machine].config.listen_server
          vm = env[:machine]
          Daemon.start vm

          out
        end
      end

      class KillServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          out = @app.call env
          vm = env[:machine]
          Daemon.stop vm

          out
        end
      end
    end
  end
end
