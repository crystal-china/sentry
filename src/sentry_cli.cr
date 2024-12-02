require "option_parser"
require "colorize"
require "./sentry"

begin
  shard_yml = YAML.parse File.read("shard.yml")
  name = shard_yml["name"]?
  Sentry::Config.shard_name = name.as_s if name
rescue e
end

cli_config = Sentry::Config.new
cli_config_file_name = ".sentry.yml"

# Set the default entry src path and build output binary name from shard.yml
if shard_yml && (targets = shard_yml["targets"]?)
  # use targets[<shard_name>]["main"] if exists
  if name && (main_path = targets.dig?(name, "main"))
    shard_build_output_binary_name = name.as_s
    cli_config.src_path = main_path.as_s
  elsif (raw = targets.raw) && raw.is_a?(Hash)
    # otherwise, use the first key you find targets[<first_key>]["main"]
    if (first_key = raw.keys[0]?) && (main_path = targets.dig?(first_key, "main"))
      shard_build_output_binary_name = first_key.as_s
      cli_config.src_path = main_path.as_s
    end
  end
end

if shard_build_output_binary_name
  cli_config.run = "./bin/#{shard_build_output_binary_name}"
  cli_config.build_args_str = "build #{cli_config.src_path} -o ./bin/#{shard_build_output_binary_name}"
end

OptionParser.parse do |parser|
  parser.banner = "Usage: ./sentry [options]"
  parser.on(
    "-n NAME",
    "--name=NAME",
    "Sets the display name of the app process (default name: #{Sentry::Config.shard_name})"
  ) do |opt|
    cli_config.display_name = opt
  end

  parser.on(
    "--src=PATH",
    "Sets the entry path for the main crystal file (default inferred from shard.yaml)"
  ) do |opt|
    cli_config.src_path = opt
  end

  parser.on(
    "-b COMMAND",
    "--build=COMMAND",
    "Overrides the default build command (will override --src flag)"
  ) do |command|
    cli_config.build = command
  end

  parser.on(
    "--build-args=ARGS",
    "Specifies arguments for the build command"
  ) do |args|
    cli_config.build_args_str = args
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
    "Overrides the default run command"
  ) do |opt|
    cli_config.run = opt
  end

  parser.on(
    "--run-args=ARGS",
    "Specifies arguments for the run command"
  ) do |opt|
    cli_config.run_args = opt
  end

  parser.on(
    "-w FILE",
    "--watch=FILE",
    "Overrides default files and appends to list of watched files"
  ) do |opt|
    cli_config.watch << opt
  end

  parser.on(
    "-c FILE",
    "--config=FILE",
    "Specifies a file to load for automatic configuration (default: '.sentry.yml')"
  ) do |opt|
    cli_config_file_name = opt
  end

  parser.on(
    "--install",
    "Run 'shards install' once before running Sentry build and run commands"
  ) do
    cli_config.install_shards = true
  end

  parser.on(
    "--no-color",
    "Removes colorization from output"
  ) do
    cli_config.colorize = false
  end

  parser.on(
    "-i",
    "--info",
    "Shows the values for build/run commands, build/run args, and watched files"
  ) do
    cli_config.info = true
  end

  parser.on(
    "-h",
    "--help",
    "Show this help"
  ) do
    puts parser
    exit 0
  end
end

if File.exists?(cli_config_file_name)
  config_yaml = File.read(cli_config_file_name)
else
  config_yaml = ""
end

config = Sentry::Config.from_yaml(config_yaml)
config.merge!(cli_config)

if config.info
  if config.colorize?
    puts config.to_s.colorize.fore(:yellow)
  else
    puts config
  end
end

if Sentry::Config.shard_name
  process_runner = Sentry::ProcessRunner.new(
    display_name: config.display_name!,
    build_command: config.build,
    run_command: config.run,
    build_args: config.build_args,
    run_args: config.run_args,
    should_build: config.should_build?,
    files: config.watch,
    install_shards: config.install_shards?,
    colorize: config.colorize?
  )

  process_runner.run
else
  puts "🤖  Sentry error: please set the entry path for the main crystal file"
  exit 1
end
