module Sentry
  class Config
    include YAML::Serializable

    # `shard_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property shard_name : String?

    @[YAML::Field(ignore: true)]
    property? sets_display_name : Bool = false
    @[YAML::Field(ignore: true)]
    property? sets_build_command : Bool = false
    @[YAML::Field(ignore: true)]
    property? sets_run_command : Bool = false
    @[YAML::Field(ignore: true)]
    property? sets_build_args : Bool = false

    getter display_name : String { self.class.shard_name.to_s }
    property src_path : String?
    property watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    getter build_command : String = "crystal"
    @build_args : String?

    getter run_command : String? { self.class.shard_name ? "./bin/#{self.class.shard_name}" : "bin/app" }
    property run_args : String = ""

    property? colorize : Bool = true
    property? info : Bool = false
    property? should_install_shards : Bool = false
    property? should_build : Bool { !build_command.blank? }
    property? should_play_sound : Bool = true

    # Initializing an empty configuration provides no default values.
    def initialize
      @watch = [] of String
    end

    def display_name=(new_display_name : String)
      @sets_display_name = true
      @display_name = new_display_name
    end

    def build_command=(new_command : String)
      @sets_build_command = true
      @build_command = new_command
    end

    def build_args=(new_build_args : String)
      @sets_build_args = true
      @build_args = new_build_args
    end

    def build_args : String?
      @build_args ||= "build #{src_path} -o #{run_command}"
    end

    def build_args_list : Array(String)
      build_args.strip.split(" ").reject(&.empty?)
    end

    def run_command=(new_command : String?)
      @sets_run_command = true
      @run_command = new_command
    end

    def run_args_list : Array(String)
      run_args.strip.split(" ").reject(&.empty?)
    end

    def merge!(cli_config : self) : Nil
      self.display_name = cli_config.display_name if cli_config.sets_display_name?
      self.build_command = cli_config.build_command if cli_config.sets_build_command?
      self.run_command = cli_config.run_command if cli_config.sets_run_command?

      self.build_args = cli_config.build_args if cli_config.sets_build_args?
      self.run_args = cli_config.run_args unless cli_config.run_args.empty?

      self.info = cli_config.info? if cli_config.info?
      self.watch = cli_config.watch unless cli_config.watch.empty?

      # following always use default
      self.should_build = cli_config.should_build?
      self.colorize = cli_config.colorize?
      self.src_path = cli_config.src_path
      self.should_play_sound = cli_config.should_play_sound?
      self.should_install_shards = cli_config.should_install_shards?
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name:            #{display_name}
            shard name:              #{self.class.shard_name}
            src_path:                #{src_path}
            build_command:           #{build_command}
            build_args:              #{build_args}
            run_command:             #{run_command}
            run_args:                #{run_args}
            watched files:           #{watch}
            colorize:                #{colorize?}
            should install shards:   #{should_install_shards?}
            should play sound:       #{should_play_sound?}
            should build:            #{should_build?}
            should print info:       #{info?}
      CONFIG
    end
  end
end
