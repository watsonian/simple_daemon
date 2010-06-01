require 'rubygems'
require 'ostruct'
require 'simple_pid'
begin
  require 'system_timer'
  SimpleDaemonTimer = SystemTimer
rescue LoadError
  puts "Falling back to the default timeout library. You should install the SystemTimer gem for better timeout support."
  require 'timeout'
  SimpleDaemonTimer = Timeout
end

class SimpleDaemon
  @@config = OpenStruct.new

  class << self

    def setup(&block)
      yield @@config
    end

    # Run block in the foreground
    def foreground(&block)
      self.set_prerun_config_defaults
      self.set_process_name
      self.chroot
      self.clean_fd
      self.redirect_io(true)

      yield
    end

    # Run block as a daemon
    def daemonized(&block)
      self.set_prerun_config_defaults
      self.set_process_name
      self.drop_privileges
      self.daemonize
      self.chroot
      self.clean_fd
      self.redirect_io

      yield
    end

    # def stop
    #   @pid_file = SimplePid.new(@@config.pid_file)
    # 
    #   unless @pid_file.running?
    #     @pid_file.cleanup
    #     puts "Nothing to stop"
    #     exit
    #   end
    # 
    #   target_pid = @pid_file.pid
    # 
    #   puts "Sending TERM to #{target_pid}"
    #   Process.kill( 'TERM', target_pid )
    # 
    #   if seconds = @@config.force_kill_wait
    #     begin
    #       SimpleDaemonTimer::timeout(seconds) do
    #         loop do
    #           puts "Waiting #{seconds} seconds for #{target_pid} before sending KILL"
    # 
    #           break unless @pid_file.running?
    # 
    #           seconds -= 1
    #           sleep 1
    #         end
    #       end
    #     rescue Timeout::Error
    #       Process.kill('KILL', target_pid)
    #     end
    #   end
    # 
    #   if @pid_file.running?
    #     puts "Process still running, leaving pidfile behind! Consider using the :force_kill_wait configuration option."
    #   else
    #     @pid_file.cleanup
    #   end
    # end

    # Exit the daemon
    # TODO: Make configurable callback chain
    # TODO: Hook into at_exit()
    # def exit!(code = 0)
    # end

    # http://gist.github.com/304739
    #
    # Stolen from Unicorn::Util
    #
    # This reopens ALL logfiles in the process that have been rotated
    # using logrotate(8) (without copytruncate) or similar tools.
    # A +File+ object is considered for reopening if it is:
    #   1) opened with the O_APPEND and O_WRONLY flags
    #   2) opened with an absolute path (starts with "/")
    #   3) the current open file handle does not match its original open path
    #   4) unbuffered (as far as userspace buffering goes, not O_SYNC)
    # Returns the number of files reopened
    # def reopen_logs
    #   nr = 0
    #   append_flags = File::WRONLY | File::APPEND
    #   @@logger.info "Rotating logs" if @@logger
    # 
    #   #logs = [STDOUT, STDERR]
    #   #logs.each do |fp|
    #   ObjectSpace.each_object(File) do |fp|
    #     next if fp.closed?
    #     next unless (fp.sync && fp.path[0..0] == "/")
    #     next unless (fp.fcntl(Fcntl::F_GETFL) & append_flags) == append_flags
    # 
    #     begin
    #       a, b = fp.stat, File.stat(fp.path)
    #       next if a.ino == b.ino && a.dev == b.dev
    #     rescue Errno::ENOENT
    #     end
    # 
    #     open_arg = 'a'
    #     if fp.respond_to?(:external_encoding) && enc = fp.external_encoding
    #       open_arg << ":#{enc.to_s}"
    #       enc = fp.internal_encoding and open_arg << ":#{enc.to_s}"
    #     end
    #     @@logger.info "Rotating path: #{fp.path}" if @@logger
    #     fp.reopen(fp.path, open_arg)
    #     fp.sync = true
    #     nr += 1
    #   end # each_object
    #   nr
    # end

    protected
    def set_process_name
      $0 = @@config.daemon_name
    end

    # Set default options (called prior to yield blocks)
    def set_prerun_config_defaults
      @@config.daemon_name = File.basename(__FILE__) unless @@config.daemon_name
      @@config.pid_file = "#{@@config.daemon_name}.pid" unless @@config.pid_file
      @@config.force_kill_wait = nil unless @@config.force_kill_wait
      @@config.group = nil unless @@config.group
      @@config.user = nil unless @@config.user
    end

    # Daemonize the process
    def daemonize
      @pid_file = SimplePid.new(@@config.pid_file)
      @pid_file.ensure_stopped!

      if RUBY_VERSION < "1.9"
        exit if fork
        Process.setsid
        exit if fork
      else
        Process.daemon( true, true )
      end

      @pid_file.write!

      # TODO: Convert into shutdown hook
      at_exit { @pid_file.cleanup }
    end

    # Release the old working directory and insure a sensible umask
    # TODO: Make chroot directory configurable
    def chroot
      Dir.chdir '/'
      File.umask 0000
    end

    # Make sure all file descriptors are closed (with the exception
    # of STDIN, STDOUT & STDERR)
    def clean_fd
      ObjectSpace.each_object(IO) do |io|
        unless [STDIN, STDOUT, STDERR].include?(io)
          begin
            unless io.closed?
              io.close
            end
          rescue ::Exception
          end
        end
      end
    end

    # Redirect our IO
    # TODO: make this configurable
    def redirect_io( simulate = false )
      begin
        STDIN.reopen '/dev/null'
      rescue ::Exception
      end

      unless simulate
        STDOUT.reopen '/dev/null', 'a'
        STDERR.reopen '/dev/null', 'a'
      end
    end

    def drop_privileges
      if @@config.group
        begin
          group = Etc.getgrnam(@@config.group)
          Process::Sys.setgid(group.gid.to_i)
        rescue => e
          $stderr.puts "Caught exception while trying to drop group privileges: #{e.message}"
        end
      end
      if @@config.user
        begin
          user = Etc.getpwnam(@@config.user)
          Process::Sys.setuid(user.uid.to_i)
        rescue => e
          $stderr.puts "Caught exception while trying to drop user privileges: #{e.message}"
        end
      end
    end
  end
end