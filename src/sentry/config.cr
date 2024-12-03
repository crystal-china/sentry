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

    getter display_name : String { self.class.shard_name.to_s }
    property src_path : String?
    property watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    getter build_command : String = "crystal"
    property build_args_str : String { "build #{src_path} -o #{run_command}" }

    property run_args_str : String = ""
    getter run_command : String { "./bin/#{self.class.shard_name}" }

    property? should_install_shards : Bool = false
    property? colorize : Bool = true
    property? info : Bool = false
    property? should_build : Bool { !build_command.blank? }

    getter build_args : Array(String) { build_args_str.strip.split(" ").reject(&.empty?) }
    getter run_args : Array(String) { run_args_str.strip.split(" ").reject(&.empty?) }

    # Initializing an empty configuration provides no default values.
    def initialize
    end

    def display_name=(new_display_name : String)
      @sets_display_name = true
      @display_name = new_display_name
    end

    def build_command=(new_command : String)
      @sets_build_command = true
      @build_command = new_command
    end

    def run_command=(new_command : String)
      @sets_run_command = true
      @run_command = new_command
    end

    def merge!(other : self) : Nil
      self.display_name = other.display_name if other.sets_display_name?
      self.build_command = other.build_command if other.sets_build_command?
      self.run_command = other.run_command if other.sets_run_command?

      self.build_args_str = other.build_args_str unless other.build_args_str.empty?
      self.run_args_str = other.run_args_str unless other.run_args_str.empty?

      self.should_build = other.should_build?

      self.info = other.info? if other.info?
      self.watch = other.watch unless other.watch.empty?
      self.should_install_shards = other.should_install_shards?
      self.colorize = other.colorize?
      self.src_path = other.src_path
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
            should build:            #{should_build?}
            should print info:       #{info?}
      CONFIG
    end
  end
end
