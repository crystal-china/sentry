module Sentry
  class Config
    include YAML::Serializable

    # `shard_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property shard_name : String?

    @[YAML::Field(ignore: true)]
    property? sets_build_full_command : Bool = false
    @[YAML::Field(ignore: true)]
    property? sets_run_command : Bool = false
    @[YAML::Field(ignore: true)]

    @[YAML::Field(ignore: true)]
    getter? sets_display_name : Bool = false
    @[YAML::Field(ignore: true)]
    getter? sets_build_command : Bool = false
    getter? sets_build_args : Bool = false
    @[YAML::Field(ignore: true)]
    getter? sets_should_play_audio : Bool = false
    @[YAML::Field(ignore: true)]
    getter? sets_should_build : Bool = false
    @[YAML::Field(ignore: true)]
    getter? sets_colorize : Bool = false
    @[YAML::Field(ignore: true)]
    getter? sets_watch : Bool = false

    property src_path : String?

    getter display_name : String { self.class.shard_name.to_s }

    getter build_command : String = "crystal"
    getter build_args : String? { "build #{src_path} -o #{run_command}" }

    getter run_command : String? { "#{src_path.to_s[%r(/([^/]*).cr$), 1]?}" }
    property run_args : String = ""

    getter? should_build : Bool { !build_command.blank? }

    @[YAML::Field(key: "play_audio")]
    getter? should_play_audio : Bool = true

    getter watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    getter? colorize : Bool = true

    property? info : Bool = false

    property? run_shards_install : Bool = false

    # Initializing an empty configuration provides no default values.
    def initialize
    end

    def display_name=(new : String)
      @sets_display_name = true
      @display_name = new
    end

    def build_command=(new : String)
      @sets_build_command = true
      @build_command = new
    end

    def build_args=(new : String?)
      @sets_build_args = true
      @build_args = new
    end

    def build_args_list : Array(String)
      build_args.strip.split(" ").reject(&.empty?)
    end

    def run_command=(new : String?)
      @sets_run_command = true
      @run_command = new
    end

    def should_play_audio=(new : Bool)
      @sets_should_play_audio = true
      @should_play_audio = new
    end

    def should_build=(new : Bool)
      @sets_should_build = true
      @should_build = new
    end

    def colorize=(new : Bool)
      @sets_colorize = true
      @colorize = new
    end

    def watch=(new : Array(String))
      @sets_watch = true
      @watch = new
    end

    def run_args_list : Array(String)
      run_args.strip.split(" ").reject(&.empty?)
    end

    def merge!(cli_config : self) : Nil
      self.src_path = cli_config.src_path

      self.display_name = cli_config.display_name if cli_config.sets_display_name?

      self.build_command = cli_config.build_command if cli_config.sets_build_command?
      self.build_args = cli_config.build_args if cli_config.sets_build_args?

      if cli_config.sets_build_full_command?
        self.build_command = cli_config.build_command
        self.build_args = cli_config.build_args
      end

      self.run_command = cli_config.run_command if cli_config.sets_run_command?
      self.run_args = cli_config.run_args unless cli_config.run_args.empty?

      self.should_build = cli_config.should_build? if cli_config.sets_should_build?
      self.should_play_audio = cli_config.should_play_audio? if cli_config.sets_should_play_audio?
      self.watch = cli_config.watch if cli_config.sets_watch?
      self.colorize = cli_config.colorize? if cli_config.sets_colorize?

      # following properties default value is false in cli_config, so it's work.
      self.info = cli_config.info? if cli_config.info?
      self.run_shards_install = cli_config.run_shards_install? if cli_config.run_shards_install?
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name:           #{display_name}
            shard name:             #{self.class.shard_name}
            src_path:               #{src_path}
            build_command:          #{build_command}
            build_args:             #{build_args}
            run_command:            #{run_command}
            run_args:               #{run_args}
            watched files:          #{watch}
            colorize:               #{colorize?}
            run shards install:     #{run_shards_install?}
            should play audio:      #{should_play_audio?}
            should build:           #{should_build?}
            should print info:      #{info?}
      CONFIG
    end
  end
end
