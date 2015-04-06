require 'celluloid'
require 'listen'

module VagrantPlugins
  module ListenServer
    module Action
      class StartServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          @ui = env[:ui]
          @machine = env[:machine]
          @ui.info 'Starting listen server'

          config = @machine.config.listen_server
          folders = config.folders
          host = "#{config.ip}:#{config.port}"

          # Vagrant-notify uses fork here, but that doesn't work on windows:
          #  https://github.com/fgrehm/vagrant-notify/blob/master/lib/vagrant-notify/server.rb
          # Only real option is to switch to Process.spawn? I need a windows
          # machine to test it out on...
          pid = fork do
            listener = Listen.to folders, forward_to: host do |modified, added, removed|
              File.open('/tmp/listen.txt', 'a+') do |f|
                f.puts 'listen fired', modified, added, removed
              end
            end
            listener.start
            sleep
          end
          @ui.info "Listen server started on PID #{pid}"
          Process.detach pid

          env[:listener] = pid

          @app.call(env)
        end
      end

      class KillServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          @ui = env[:ui]
          @ui.info 'Killing listen server'
          pid = env[:listener]
          if pid
            Process.kill 'INT', pid
          else
            @ui.info 'No listen server found'
          end

          @app.call(env)
        end
      end
    end
  end
end
