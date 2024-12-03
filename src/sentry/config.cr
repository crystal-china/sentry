module Sentry
  class Config
    include YAML::Serializable

    @display_name : String?
    @build_command : String?
    @run_command : String?

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
    setter should_build : Bool = true

    property src_path : String?
    property watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    property? should_install_shards : Bool = false
    property? colorize : Bool = true
    property? info : Bool = false

    setter build_args_str : String?
    property run_args_str : String = ""

    # Initializing an empty configuration provides no default values.
    def initialize
    end

    def display_name=(new_display_name : String)
      @sets_display_name = true
      @display_name = new_display_name
    end

    def display_name! : String
      display_name.not_nil!
    end

    def build_command : String
      @build_command ||= "crystal"
    end

    def build_command=(new_command : String)
      @sets_build_command = true
      @build_command = new_command
    end

    def build_args_str : String
      @build_args_str ||= "build #{src_path} -o #{run_command}"
    end

    def build_args : Array(String)
      build_args_str.strip.split(" ").reject(&.empty?)
    end

    def run_command : String
      @run_command ||= "./bin/#{self.class.shard_name}"
    end

    def run_command=(new_command : String)
      @sets_run_command = true
      @run_command = new_command
    end

    def run_args : Array(String)
      @run_args_str.strip.split(" ").reject(&.empty?)
    end

    def should_build? : Bool
      @should_build ||=
        if (build_command = @build_command)
          build_command.empty?
        else
          false
        end
    end

    def merge!(other : self) : Nil
      self.display_name = other.display_name! if other.sets_display_name?
      self.build_command = other.build_command if other.sets_build_command?
      self.run_command = other.run_command if other.sets_run_command?

      self.build_args_str = other.build_args_str unless other.build_args_str.empty?
      self.run_args_str = other.run_args_str unless other.run_args_str.empty?

      self.info = other.info? if other.info?
      self.watch = other.watch unless other.watch.empty?
      self.should_install_shards = other.should_install_shards?
      self.colorize = other.colorize?
      self.src_path = other.src_path
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name:   #{display_name}
            shard name:     #{self.class.shard_name}
            install shards: #{should_install_shards?}
            info:           #{info?}
            build_command:  #{build_command}
            build_args:     #{build_args}
            src_path:       #{src_path}
            run_command:    #{run_command}
            run_args:       #{run_args}
            watch:          #{watch}
            colorize:       #{colorize?}
      CONFIG
    end

    private def display_name : String?
      @display_name ||= self.class.shard_name
    end
  end
end
