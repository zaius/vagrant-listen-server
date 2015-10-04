require 'listen'
require 'socket'
require 'json'

# No ActiveSupport in vagrant
def array_wrap object
  if object.nil?
    []
  elsif object.respond_to?(:to_ary)
    object.to_ary || [object]
  else
    [object]
  end
end


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
          folders = array_wrap config.folders

          @ui.info "Starting listen server - #{config.ip}:#{config.port}"

          # Check whether the daemon is already running.
          if File.exists? config.pid_file
            pid = File.read config.pid_file
            begin
              Process.getpgid pid.to_i
              @ui.info 'Warning - listen server already running'
              return @app.call(env)
            rescue Errno::ESRCH
              @ui.info "Warning - stale PID: #{pid}"
            end
          end

          out = @app.call(env)

          # Vagrant-notify uses fork here, but that doesn't work on windows:
          #  https://github.com/fgrehm/vagrant-notify/blob/master/lib/vagrant-notify/server.rb
          # Only real option is to switch to Process.spawn? I need a windows
          # machine to test it out on...
          pid = fork do
            $0 = "vagrant-listen-server - #{@machine.name}"

            clients = []
            server = TCPServer.new config.ip, config.port

            callback = Proc.new do |modified, added, removed|
              bad_clients = []
              @ui.detail "Listen fired - #{clients.count} clients."
              clients.each do |client|
                begin
                  client.puts [modified, added, removed].to_json
                rescue Errno::EPIPE
                  @ui.detail "Connection broke! #{client}"
                  # Don't want to change the list of threads as we iterate.
                  bad_clients.push client
                end
              end

              bad_clients.each do |client|
                clients.delete client
              end
            end

            # There is a recurring bug that keeps popping up in listen where
            # only the first directory is watched. Create a new listen object
            # for each folder as a workaround.
            # https://github.com/guard/listen/issues/243
            listeners = folders.map do |folder|
              Listen.to(folder, &callback)
            end

            listeners.each &:start

            # server.accept blocks - we need it in its own thread so we can
            # continue to have listener callbacks fired, and so we can sleep
            # and catch any interrupts from vagrant.
            Thread.new do
              loop do
                Thread.fork(server.accept) do |client|
                  @ui.detail "New connection - #{client}"
                  clients.push client
                end
              end
            end

            # TODO: this error won't happen on the listen anymore - it will
            # happen somewhere on the tcp call. Not sure where.
            #
            # begin
            #   listener.start
            # rescue Errno::EADDRNOTAVAIL
            #   @ui.info "Can't start server - Port in use"
            #   exit
            # end

            # Uhh... this needs work. Vagrant steals the interrupt from us and
            # there's no way to get it back
            #  * https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/action/runner.rb#L49
            # Is there a way to register more callbacks to the busy block?
            #  * https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/util/busy.rb
            while not env[:interrupted]
              sleep 1
            end

            listeners.each &:stop
            @ui.info "Listen sleep finished"
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
