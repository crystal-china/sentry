module Sentry
  class ProcessRunner
    FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

    getter app_process : Process? = nil
    property display_name : String
    property should_build = true
    property files = [] of String
    @sound_player : String?
    @success_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("success.wav")
    @error_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("error.wav")

    def initialize(
      @display_name : String,
      @build_command : String,
      @run_command : String,
      @build_args : Array(String) = [] of String,
      @run_args : Array(String) = [] of String,
      files = [] of String,
      should_build = true,
      install_shards = false,
      colorize = true
    )
      @files = files
      @should_build = should_build
      @should_kill = false
      @app_built = false
      @should_install_shards = install_shards
      @colorize = colorize

      {% if flag?(:linux) %}
        @sound_player = `which aplay 2>/dev/null`.chomp
      {% end %}
    end

    private def stdout(str : String) : Nil
      if @colorize
        puts str.colorize.fore(:yellow)
      else
        puts str
      end
    end

    private def build_app_process : Process::Status
      stdout "🤖  compiling #{display_name}..."
      build_args = @build_args
      if build_args.size > 0
        Process.run(@build_command, build_args, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      else
        Process.run(@build_command, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      end
    end

    private def create_app_process : Process
      if (app_process = @app_process).is_a? Process
        unless app_process.terminated?
          stdout "🤖  killing #{display_name}..."
          app_process.signal(:kill)
          app_process.wait
        end
      end

      stdout "🤖  starting #{display_name}..."

      run_args = @run_args.size > 0 ? @run_args : [] of String

      @app_process = Process.new(
        @run_command,
        run_args,
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit
      )
    end

    private def get_timestamp(file : String) : String
      File.info(file).modification_time.to_unix.to_s
    end

    # Compiles and starts the application
    #
    def start_app : Process?
      return create_app_process unless @should_build

      sound_player = @sound_player
      build_result = build_app_process

      if build_result && build_result.success?
        @app_built = true
        process = create_app_process

        unless sound_player.nil?
          Process.new(command: sound_player, input: @success_wav)
          @success_wav.rewind
        end

        process
      elsif !@app_built # if build fails on first time compiling, then exit
        stdout "🤖  Compile time errors detected. SentryBot shutting down..."

        unless sound_player.nil?
          Process.new(command: sound_player, input: @error_wav)
          @error_wav.rewind
        end

        exit 1
      else
        unless sound_player.nil?
          Process.new(command: sound_player, input: @error_wav)
          @error_wav.rewind
        end

        nil
      end
    end

    # Scans all of the `@files`
    #
    def scan_files : Process?
      file_changed = false
      app_process = @app_process
      files = @files

      begin
        Dir.glob(files) do |file|
          timestamp = get_timestamp(file)
          if FILE_TIMESTAMPS[file]? && FILE_TIMESTAMPS[file] != timestamp
            FILE_TIMESTAMPS[file] = timestamp
            file_changed = true
            stdout "🤖  #{file}"
          elsif FILE_TIMESTAMPS[file]?.nil?
            stdout "🤖  watching file: #{file}"
            FILE_TIMESTAMPS[file] = timestamp
            file_changed = true if (app_process && !app_process.terminated?)
          end
        end
      rescue ex : File::Error
        # The underlining lib for reading directories will fail very rarely, crashing Sentry
        # This catches that error and allows Sentry to carry on normally
        # https://github.com/crystal-lang/crystal/blob/677422167cbcce0aeea49531896dbdcadd2762db/src/crystal/system/unix/dir.cr#L19
      end

      start_app() if (file_changed || app_process.nil?)
    end

    def run_install_shards : Nil
      stdout "🤖  Installing shards..."

      install_result = Process.run(
        "shards install",
        ["install"],
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit
      )

      if !install_result || !install_result.success?
        stdout "🤖  Error installing shards. SentryBot shutting down..."
        exit 1
      end
    end

    def run : Nil
      stdout "🤖  Your SentryBot is vigilant. beep-boop..."

      run_install_shards if @should_install_shards

      loop do
        if @should_kill
          stdout "🤖  Powering down your SentryBot..."
          break
        end

        scan_files
        sleep 1.second
      end
    end

    # def kill
    #   @should_kill = true
    # end
  end
end
