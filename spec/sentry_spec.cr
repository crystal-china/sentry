require "./spec_helper"

describe Sentry do
  # TODO: Write tests

  it "should return default config when there is a empty .sentry.yml" do
    cli_config = SentryCli.new(
      shard_src_path: "./src/sentry_cli.cr",
      shard_run_command: "bin/sentry"
    ).cli_config

    cli_config.sets_build_full_command?.should be_false
    cli_config.sets_run_command?.should be_false
    # cli_config.sets_args?.should be_false
    cli_config.sets_display_name?.should be_false
    cli_config.sets_build_command?.should be_false
    cli_config.sets_build_args?.should be_false
    cli_config.sets_should_play_audio?.should be_false
    cli_config.sets_should_build?.should be_false
    cli_config.sets_colorize?.should be_false
    cli_config.sets_watch?.should be_false

    cli_config.display_name.should eq "sentry"
    cli_config.src_path.should eq "./src/sentry_cli.cr"
    cli_config.build_command.should eq "crystal"
    cli_config.build_args.should eq "build ./src/sentry_cli.cr -o bin/sentry"
    cli_config.run_command.should eq "bin/sentry"
    cli_config.run_args.should eq ""
    cli_config.should_build?.should be_true
    cli_config.should_play_audio?.should be_true
    cli_config.watch.should eq ["./src/**/*.cr", "./src/**/*.ecr"]
    cli_config.colorize?.should be_true
    cli_config.info?.should be_false
    cli_config.run_shards_install?.should be_false
  end
end
