module VagrantPlugins
  module ListenServer
    module Action
      class StartServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          # TOOD: fix these references to puts
          # @ui.info 'Starting listen server'
          puts 'Starting listen server'
          @app.call(env)
        end
      end

      class KillServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          # @ui.info 'Killing listen server'
          puts 'Killing listen server'
          @app.call(env)
        end
      end
    end
  end
end
