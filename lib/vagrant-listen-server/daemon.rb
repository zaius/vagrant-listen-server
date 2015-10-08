def array_wrap object
  if object.nil?
    []
  elsif object.respond_to?(:to_ary)
    object.to_ary || [object]
  else
    [object]
  end
end


# TODO: pre-fork use vagrant logging, post fork use puts.
def log message
  puts message
end


module Daemon
  def self.status_code config
    return :stopped unless File.exists? config.pid_file

    pid = File.read config.pid_file
    begin
      Process.getpgid pid.to_i
      return pid.to_i
    rescue Errno::ESRCH
      return :stale
    end
    :stopped
  end

  def self.status config
    code = self.status_code config
    case code
    when Fixnum then log "Running - PID: #{code}"
    when :stopped then log 'Stopped'
    when :stale then log 'Stopped. Stale PID file.'
    else
      log "Unknown status - #{code}"
    end
  end

  # Wasted way too long trying to use Process.daemon. Doing it by hand. Code
  # courtesy of:
  # https://gist.github.com/mynameisrufus/1372491/b76b60fb1842bf0507f47869ab19ad50a045b214
  # See also:
  #  * http://stackoverflow.com/questions/1740308/create-a-daemon-with-double-fork-in-ruby
  #  * http://allenlsy.com/working-with-unix-process-in-ruby/
  #
  # Related: Process.detach isn't what you think. It creates a process to
  # monitor the child so that this can exit without creating a zombie. Because
  # we want to remove parents, this actually makes life harder than just doing
  # a double fork.
  #
  # Vagrant-notify uses fork as well, but that doesn't work on windows:
  #  https://github.com/fgrehm/vagrant-notify/blob/master/lib/vagrant-notify/server.rb
  # Only real option is to switch to Process.spawn? I need a windows
  # machine to test it out on... Vagrant::Util::Subprocess allows spawning an
  # executable, but I don't know how to make that launch the included ruby
  # binary and make sure it's running the right file.
  def self.daemonize! out='/dev/null', err='/dev/null'
    raise 'First fork failed' if (pid = fork) == -1
    return nil unless pid.nil?
    Process.setsid
    raise 'Second fork failed' if (pid = fork) == -1
    exit unless pid.nil?

    # Dir.chdir '/'
    # File.umask 0000

    $stdin.reopen '/dev/null'
    $stdout.reopen File.new(out, "a")
    $stderr.reopen File.new(err, "a")
    $stdout.sync = $stderr.sync = true

    Process.pid
  end


  def self.start vm
    config = vm.config.listen_server
    log "Starting listen server - #{config.ip}:#{config.port}"

    status = self.status_code config
    if status == :running
      log 'Server already running.'
      return 1
    end

    File.delete config.pid_file if status == :stale

    # TODO: use machine name in log file name.
    # TODO: use machine name in PID file and drop it from config.
    pid = daemonize! '/tmp/listen.log', '/tmp/listen.log'
    # Usually a daemon wants the parent to exit here, but we need vagrant to
    # keep going with its init process.
    return unless pid

    $0 = "vagrant-listen-server - #{vm.name}"

    File.write config.pid_file, pid

    log "Listen server started on PID #{pid}"

    clients = []
    begin
      server = TCPServer.new config.ip, config.port
    rescue Errno::EADDRINUSE
      log "Can't start server - Port in use"
      exit 1
    end

    callback = Proc.new do |modified, added, removed|
      bad_clients = []
      log "Listen fired - #{clients.count} clients."

      clients.each do |client|
        begin
          client.puts [modified, added, removed].to_json
        rescue Errno::EPIPE
          log "Connection broke! #{client}"
          # Don't want to change the list of threads as we iterate.
          bad_clients.push client
        end
      end

      bad_clients.each do |client|
        clients.delete client
      end
    end

    folders = array_wrap config.folders

    # There is a recurring bug that keeps popping up in listen where only the
    # first directory is watched. Create a new listen object for each folder as
    # a workaround.
    # https://github.com/guard/listen/issues/243
    listeners = folders.map do |folder|
      Listen.to(folder, &callback)
    end

    listeners.each &:start

    # server.accept is blocking - we need it in its own thread so we can
    # continue to have listener callbacks fired, and so we can sleep and catch
    # any interrupts.
    Thread.new do
      loop do
        Thread.fork(server.accept) do |client|
          log "New connection - #{client}"
          clients.push client
        end
      end
    end

    exiting = false
    Signal.trap 'INT' do
      log 'SIGINT caught'
      exiting = true
    end

    sleep 0.5 while not exiting

    listeners.each &:stop
    log "Listen sleep finished"
  end


  def self.stop vm
    log 'Killing listen server'
    config = vm.config.listen_server
    status = self.status_code config
    unless status.is_a? Fixnum
      log 'Server is not running.'
      return 1
    end

    pid = File.read config.pid_file
    Process.kill 'INT', pid.to_i
    File.delete config.pid_file
  end
end
