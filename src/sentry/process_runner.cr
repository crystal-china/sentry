module Sentry
  class ProcessRunner
    FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

    {% if flag?(:linux) %}
      @audio_player : AudioPlayer?
    {% end %}

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

      Process.on_terminate do |reason|
        case reason
        when .interrupted?
          @should_kill = true
        end
      end

      {% if flag?(:linux) %}
        @audio_player = AudioPlayer.new if @should_play_audio
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

      audio_player = nil

      {% if flag?(:linux) %}
        audio_player = @audio_player
      {% end %}

      build_result = build_app_process

      if build_result && build_result.success?
        @app_built = true
        process = create_app_process

        audio_player.success unless audio_player.nil?

        process
      elsif !@app_built # if build fails on first time compiling, then exit
        stdout "🤖  Compile time errors detected. SentryBot shutting down..."

        audio_player.error unless audio_player.nil?

        exit 1
      else
        audio_player.error unless audio_player.nil?

        nil
      end
    end

    private def build_app_process : Process::Status
      stdout "🤖  compiling #{@display_name}..."

      {% if flag?(:win32) %}
        if (app_process = @app_process).is_a? Process
          stdout "🤖  killing #{@display_name}..."
          app_process.terminate
          # app_process.wait
        end
      {% end %}

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
          app_process.terminate
          app_process.wait
        end
      end

      stdout "🤖  starting #{@display_name}..."

      if File.file?(@run_command)
        @app_process = Process.new(
          @run_command,
          @run_args_list,
          output: :inherit,
          error: :inherit
        )
      else
        puts "🤖  Sentry error: the inferred run command file(#{@run_command}) \
does not exist. either set correct run command use `-r COMMAND' or fix the \
`BUILD ARGS' to output correct run command. SentryBot shutting down..."
        exit 1
      end
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
