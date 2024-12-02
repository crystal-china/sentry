module Sentry
  class Config
    include YAML::Serializable

    @display_name : String?
    @build : String?
    @run : String?

    # `shard_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property shard_name : String?

    @[YAML::Field(ignore: true)]
    property? sets_display_name : Bool = false

    @[YAML::Field(ignore: true)]
    property? sets_build_command : Bool = false

    @[YAML::Field(ignore: true)]
    property? sets_run_command : Bool = false

    property info : Bool = false

    property? colorize : Bool = true

    property src_path : String = "./src/#{Sentry::Config.shard_name}.cr"

    property? install_shards : Bool = false

    setter build_args : String = ""
    setter run_args : String = ""

    property watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    property install_shards : Bool = false

    # Initializing an empty configuration provides no default values.
    def initialize
    end

    def display_name : String?
      @display_name ||= self.class.shard_name
    end

    def display_name=(new_display_name : String)
      @sets_display_name = true
      @display_name = new_display_name
    end

    def display_name! : String
      display_name.not_nil!
    end

    def build : String
      @build ||= "crystal"
    end

    def build=(new_command : String)
      @sets_build_command = true
      @build = new_command
    end

    def build_args : Array(String)
      @build_args.strip.split(" ").reject(&.empty?)
    end

    def run : String
      @run ||= "./bin/#{self.class.shard_name}"
    end

    def run=(new_command : String)
      @sets_run_command = true
      @run = new_command
    end

    def run_args : Array(String)
      @run_args.strip.split(" ").reject(&.empty?)
    end

    @[YAML::Field(ignore: true)]
    setter should_build : Bool = true

    def should_build? : Bool
      @should_build ||= begin
        if build_command = @build
          build_command.empty?
        else
          false
        end
      end
    end

    def merge!(other : self) : Nil
      self.display_name = other.display_name! if other.sets_display_name?
      self.info = other.info if other.info
      self.build = other.build if other.sets_build_command?
      self.build_args = other.build_args.join(" ") unless other.build_args.empty?
      self.run = other.run if other.sets_run_command?
      self.run_args = other.run_args.join(" ") unless other.run_args.empty?
      self.watch = other.watch unless other.watch.empty?
      self.install_shards = other.install_shards?
      self.colorize = other.colorize?
      self.src_path = other.src_path
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name:   #{display_name}
            shard name:     #{self.class.shard_name}
            install shards: #{install_shards?}
            info:           #{info}
            build:          #{build}
            build_args:     #{build_args}
            src_path:       #{src_path}
            run:            #{run}
            run_args:       #{run_args}
            watch:          #{watch}
            colorize:       #{colorize?}
      CONFIG
    end
  end
end
