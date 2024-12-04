require "option_parser"
require "colorize"
require "./sentry"

begin
  shard_yml = YAML.parse File.read("shard.yml")
  name = shard_yml["name"]?
  Sentry::Config.shard_name = name.as_s if name
rescue e
end

# Set the default entry src path and build output binary name from shard.yml
if shard_yml && (targets = shard_yml["targets"]?)
  # use targets[<shard_name>]["main"] if exists
  if name && (main_path = targets.dig?(name, "main"))
    run_command = "./bin/#{name.as_s}"
    src_path = main_path.as_s
  elsif (raw = targets.raw) && raw.is_a?(Hash)
    # otherwise, use the first key you find targets[<first_key>]["main"]
    if (first_key = raw.keys[0]?) && (main_path = targets.dig?(first_key, "main"))
      run_command = "./bin/#{first_key.as_s}"
      src_path = main_path.as_s
    end
  end
end

cli_config = Sentry::Config.new

if name.nil? || run_command.nil? || src_path.nil?
  cli_config.src_path = nil
  cli_config.run_command = nil
else
  cli_config.src_path = src_path
  cli_config.run_command = run_command
end

cli_config.sets_run_command = false

cli_config_file_name = ".sentry.yml"

OptionParser.parse do |parser|
  parser.banner = "Usage: ./sentry [options]"
  parser.on(
    "-n NAME",
    "--name=NAME",
    "Sets the display name of the app process  (default: #{cli_config.display_name})"
  ) do |opt|
    cli_config.display_name = opt
  end

  parser.on(
    "--src=PATH",
    "Sets the entry path for the main crystal file inferred from shard.yml, (\
default: #{cli_config.src_path})"
  ) do |opt|
    cli_config.src_path = opt
  end

  parser.on(
    "--build-command=COMMAND",
    "Overrides the default build command (default: #{cli_config.build_command})"
  ) do |command|
    cli_config.build_command = command
  end

  parser.on(
    "--build-args=ARGS",
    "Specifies arguments for the build command, (default: #{cli_config.build_args})"
  ) do |args|
    cli_config.build_args = args
  end

  parser.on(
    "--no-build",
    "Skips the build step"
  ) do
    cli_config.should_build = false
  end

  parser.on(
    "-r COMMAND",
    "--run=COMMAND",
    "Overrides the default run command, (default: #{cli_config.run_command})"
  ) do |opt|
    cli_config.run_command = opt
  end

  parser.on(
    "--run-args=ARGS",
    "Specifies arguments for the run command, (default: #{cli_config.run_args})"
  ) do |opt|
    cli_config.run_args = opt
  end

  parser.on(
    "-w FILE",
    "--watch=FILE",
    "Appends to list of watched files, (will overrides default: #{cli_config.watch})"
  ) do |file|
    cli_config.watch = [] of String unless cli_config.sets_watch?

    cli_config.watch << file
  end

  parser.on(
    "-c FILE",
    "--config=FILE",
    "Specifies a file to load for automatic configuration (default: #{cli_config_file_name})"
  ) do |opt|
    cli_config_file_name = opt
  end

  parser.on(
    "--install",
    "Run `shards install' once before running Sentry build and run commands"
  ) do
    cli_config.run_shards_install = true
  end

  parser.on(
    "--no-color",
    "Removes colorization from output"
  ) do
    cli_config.colorize = false
  end

  parser.on(
    "--not-play-audio",
    "Skips the attempt to play audio file with `aplay' from `alsa-utils' package \
when building on Linux succeeds or fails"
  ) do
    cli_config.should_play_audio = false
  end

  parser.on(
    "-i",
    "--info",
    "Shows the configuration informations"
  ) do
    cli_config.info = true
  end

  parser.on(
    "-V",
    "--version",
    "Shows version"
  ) do
    puts Sentry::VERSION
    exit
  end

  parser.on(
    "-h",
    "--help",
    "Show this help"
  ) do
    puts parser
    exit
  end
end

if cli_config.src_path.nil?
  puts "🤖  Sentry error: please set the entry path for the main crystal file use \
  --src or create a valid shard.yml"

  exit 1
end

if File.exists?(cli_config_file_name)
  config_yaml = File.read(cli_config_file_name)
else
  config_yaml = ""
end

# 这里配置文件的顺序是:
# 1. 如果配置文件中有, 使用它
# 2. 如果配置文件中没有, 使用 propety 的默认值, 1, 2 的行为就是反序列化的默认行为
# 3. 如果通过某种方式判断, cli_config 中手动设定了某个值, 总是使用该值 (见 merge! 方法定义)

# configurations deserialized from yaml use default values settings in getter/property.
config = Sentry::Config.from_yaml(config_yaml)

config.merge!(cli_config)

if config.info?
  if config.colorize?
    puts config.to_s.colorize.fore(:yellow)
  else
    puts config
  end
end

process_runner = Sentry::ProcessRunner.new(
  display_name: config.display_name,
  build_command: config.build_command,
  run_command: config.run_command,
  build_args_list: config.build_args_list,
  run_args_list: config.run_args_list,
  should_build: config.should_build?,
  files: config.watch,
  run_shards_install: config.run_shards_install?,
  should_play_audio: config.should_play_audio?,
  colorize: config.colorize?
)

process_runner.run
