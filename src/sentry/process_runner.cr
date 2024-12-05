module Sentry
  class ProcessRunner
    FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

    @sound_player : String?
    @success_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("success.wav")
    @error_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("error.wav")
    @app_process : Process?

    def initialize(
      @display_name : String,
      @build_command : String,
      @run_command : String,
      @build_args_list : Array(String) = [] of String,
      @run_args_list : Array(String) = [] of String,
      @files = [] of String,
      @should_build = true,
      @run_shards_install = false,
      @should_play_audio = true,
      @colorize = true
    )
      @should_kill = false
      @app_built = false

      Signal::INT.trap do
        @should_kill = true
      end

      {% if flag?(:linux) %}
        @sound_player = Process.find_executable("aplay") if @should_play_audio
      {% end %}
    end

    def run : Nil
      stdout "🤖  Your SentryBot is vigilant. beep-boop..."

      run_shards_install if @run_shards_install

      File.delete?(@run_command) if @should_build

      loop do
        if @should_kill
          stdout "🤖  Powering down your SentryBot..."

          break
        end

        scan_files

        sleep 1.second
      end
    end

    private def run_shards_install : Nil
      stdout "🤖  Installing shards..."

      install_result = Process.run(
        "shards",
        ["install"],
        output: :inherit,
        error: :inherit
      )

      if !install_result || !install_result.success?
        stdout "🤖  Error installing shards. SentryBot shutting down..."

        exit 1
      end
    end

    # Scans all of the `@files`
    #
    private def scan_files : Process?
      file_changed = false
      app_process = @app_process

      begin
        Dir.glob(@files) do |file|
          timestamp = File.info(file).modification_time.to_unix.to_s

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

      start_app() if file_changed || app_process.nil?
    end

    # Compiles and starts the application
    #
    private def start_app : Process?
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

    private def build_app_process : Process::Status
      stdout "🤖  compiling #{@display_name}..."

      Process.run(
        @build_command,
        @build_args_list,
        output: :inherit,
        error: :inherit
      )
    end

    private def create_app_process : Process
      if (app_process = @app_process).is_a? Process
        unless app_process.terminated?
          stdout "🤖  killing #{@display_name}..."
          app_process.signal(:kill)
          app_process.wait
        end
      end

      stdout "🤖  starting #{@display_name}..."

      @app_process = Process.new(
        @run_command,
        @run_args_list,
        output: :inherit,
        error: :inherit
      )
    end

    private def stdout(str : String) : Nil
      if @colorize
        puts str.colorize.fore(:yellow)
      else
        puts str
      end
    end
  end
end
