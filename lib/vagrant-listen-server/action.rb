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

          config = @machine.config.listen_server
          folders = config.folders
          host = "#{config.ip}:#{config.port}"

          @ui.info "Starting listen server - #{host}"

          # Check whether the daemon is already running.
          if File.exists? config.pid_file
            pid = File.read config.pid_file
            begin
              Process.getpgid pid.to_i
              @ui.info 'Warning - listen server already running'
              return @app.call(env)
            rescue Errno::ESRCH
              @ui.info 'Warning - stale PID file'
            end
          end

          out = @app.call(env)

          # Vagrant-notify uses fork here, but that doesn't work on windows:
          #  https://github.com/fgrehm/vagrant-notify/blob/master/lib/vagrant-notify/server.rb
          # Only real option is to switch to Process.spawn? I need a windows
          # machine to test it out on...
          pid = fork do
            $0 = "vagrant-listen-server - #{@machine.name}"
            listener = Listen.to folders, forward_to: host do |modified, added, removed|
              File.open('/tmp/listen.txt', 'a+') do |f|
                f.puts 'listen fired', modified, added, removed
              end
            end

            begin
              listener.start
            rescue Errno::EADDRNOTAVAIL
              @ui.info "Can't start server - Port in use"
              exit
            end
            sleep
          end

          Process.detach pid
          File.write config.pid_file, pid
          @ui.info "Listen server started on PID #{pid}"

          out
        end
      end

      class KillServer
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @ui = env[:ui]
          config = env[:machine].config.listen_server
          @ui.info 'Killing listen server'
          if File.exists? config.pid_file
            pid = File.read config.pid_file
            begin
              Process.kill 'INT', pid.to_i
            rescue Errno::ESRCH
              @ui.info 'Stale PID file - no server found'
            end
            File.delete config.pid_file
          else
            @ui.info 'No listen server found'
          end

          @app.call(env)
        end
      end
    end
  end
end
