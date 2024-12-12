require "./spec_helper"

describe Sentry do
  # TODO: Write tests

  context "no .sentry.yml" do
    it "should return default config inferred from shard.yml in a shards manager project" do
      Dir.cd "./spec/apps/with_shard_yml" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry"
        )

        cli_config = cli.cli_config

        cli_config.sets_build_full_command?.should be_false
        cli_config.sets_run_command?.should be_false
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

        config = cli.config

        config.sets_build_full_command?.should be_false
        config.sets_run_command?.should be_true
        config.sets_display_name?.should be_false
        config.sets_build_command?.should be_false
        config.sets_build_args?.should be_false
        config.sets_should_play_audio?.should be_false
        config.sets_should_build?.should be_false
        config.sets_colorize?.should be_false
        config.sets_watch?.should be_false

        config.display_name.should eq "sentry"
        config.src_path.should eq "./src/sentry_cli.cr"
        config.build_command.should eq "crystal"
        config.build_args.should eq "build ./src/sentry_cli.cr -o bin/sentry"
        config.run_command.should eq "bin/sentry"
        config.run_args.should eq ""
        config.should_build?.should be_true
        config.should_play_audio?.should be_true
        config.watch.should eq ["./src/**/*.cr", "./src/**/*.ecr"]
        config.colorize?.should be_true
        config.info?.should be_false
        config.run_shards_install?.should be_false
      end
    end

    it "should return default config inferred from src_path in a non-shards project" do
      Dir.cd "./spec/apps/empty" do
        cli = SentryCli.new(
          shard_src_path: "./src/foo.cr",
          shard_run_command: "bin/foo"
        )

        cli_config = cli.cli_config

        Dir.exists?("./bin").should be_true

        cli_config.sets_build_full_command?.should be_false
        cli_config.sets_run_command?.should be_false
        cli_config.sets_display_name?.should be_false
        cli_config.sets_build_command?.should be_false
        cli_config.sets_build_args?.should be_false
        cli_config.sets_should_play_audio?.should be_false
        cli_config.sets_should_build?.should be_false
        cli_config.sets_colorize?.should be_false
        cli_config.sets_watch?.should be_false

        cli_config.display_name.should eq "sentry"
        cli_config.src_path.should eq "./src/foo.cr"
        cli_config.build_command.should eq "crystal"
        cli_config.build_args.should eq "build ./src/foo.cr -o bin/foo"
        cli_config.run_command.should eq "bin/foo"
        cli_config.run_args.should eq ""
        cli_config.should_build?.should be_true
        cli_config.should_play_audio?.should be_true
        cli_config.watch.should eq ["./src/**/*.cr", "./src/**/*.ecr"]
        cli_config.colorize?.should be_true
        cli_config.info?.should be_false
        cli_config.run_shards_install?.should be_false

        config = cli.config

        config.sets_build_full_command?.should be_false
        config.sets_run_command?.should be_true
        config.sets_display_name?.should be_false
        config.sets_build_command?.should be_false
        config.sets_build_args?.should be_false
        config.sets_should_play_audio?.should be_false
        config.sets_should_build?.should be_false
        config.sets_colorize?.should be_false
        config.sets_watch?.should be_false

        config.display_name.should eq "sentry"
        config.src_path.should eq "./src/foo.cr"
        config.build_command.should eq "crystal"
        config.build_args.should eq "build ./src/foo.cr -o bin/foo"
        config.run_command.should eq "bin/foo"
        config.run_args.should eq ""
        config.should_build?.should be_true
        config.should_play_audio?.should be_true
        config.watch.should eq ["./src/**/*.cr", "./src/**/*.ecr"]
        config.colorize?.should be_true
        config.info?.should be_false
        config.run_shards_install?.should be_false
      end
    end
  end

  context "with a default .sentry.yml" do
    it "should return config from .sentry.yml" do
      Dir.cd "./spec/apps/with_config" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry"
        )

        cli_config = cli.cli_config

        cli_config.sets_build_full_command?.should be_false
        cli_config.sets_run_command?.should be_false
        # cli_config.sets_run_args?.should be_false
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

        config = cli.config

        config.sets_build_full_command?.should be_false
        config.sets_run_command?.should be_false
        config.sets_display_name?.should be_false
        config.sets_build_command?.should be_false
        config.sets_build_args?.should be_false
        config.sets_should_play_audio?.should be_false
        config.sets_should_build?.should be_false
        config.sets_colorize?.should be_false
        config.sets_watch?.should be_false

        config.display_name.should eq "sentry"
        config.src_path.should eq "./src/sentry_cli.cr"
        config.build_command.should eq "crystal"
        config.build_args.should eq "build ./src/sentry_cli.cr -o ./bin/sentry"
        config.run_command.should eq "./bin/sentry"
        config.run_args.should eq "-p 3288"
        config.should_build?.should be_false
        config.should_play_audio?.should be_false
        config.watch.should eq ["./src/**/*.cr", "./src/**/*.ecr"]
        config.colorize?.should be_false
        config.info?.should be_true
        config.run_shards_install?.should be_true
      end
    end
  end
end
