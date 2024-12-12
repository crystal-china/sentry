require "./spec_helper"

describe OptionParser do
  context "cli config default" do
    it "should set project name" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--name=foo"]
        )

        config = cli.config

        config.display_name.should eq "foo"
      end
    end

    it "should set src path" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--src=./src/foo.cr"]
        )

        config = cli.config

        config.src_path.should eq "./src/foo.cr"
        config.build_args.should eq "build ./src/foo.cr -o foo"
        config.run_command.should eq "foo"
        config.sets_build_args?.should be_true
        config.sets_run_command?.should be_true
      end
    end

    it "should set build command" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--build-command=cr"]
        )

        config = cli.config

        config.build_command.should eq "cr"
        config.sets_build_command?.should be_true
      end
    end

    it "should set build args" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--build-args=build src/foo.cr -o foo"]
        )

        config = cli.config

        config.build_args.should eq "build src/foo.cr -o foo"
        config.sets_build_args?.should be_true
      end
    end

    it "should set full build command" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["-b cr build src/bar.cr -o bar"]
        )

        config = cli.config

        config.build_command.should eq "cr"
        config.build_args.should eq "build src/bar.cr -o bar"
        cli.cli_config.sets_build_full_command?.should be_true
      end
    end

    it "should not build before respawn process" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--no-build"]
        )

        config = cli.config

        config.should_build?.should be_false
        config.sets_should_build?.should be_true
      end
    end

    it "should set run command and run args" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--run=crystal", "--run-args=spec --debug"]
        )

        config = cli.config

        config.run_command.should eq "crystal"
        config.run_args.should eq "spec --debug"
        config.sets_run_command?.should be_true
      end
    end

    it "should watched folders" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--watch=spec/*.cr", "--watch=src/*.cr"]
        )

        config = cli.config

        config.watch.should eq ["spec/*.cr", "src/*.cr"]
        config.sets_watch?.should be_true
      end
    end

    it "run shards install after the first time start sentry" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--install"]
        )

        config = cli.config

        config.run_shards_install?.should be_true
      end
    end

    it "run shards install after the first time start sentry" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--no-color"]
        )

        config = cli.config

        config.colorize?.should be_false
        config.sets_colorize?.should be_true
      end
    end

    it "not play audio" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--not-play-audio"]
        )

        config = cli.config

        config.should_play_audio?.should be_false
        config.sets_should_play_audio?.should be_true
      end
    end

    it "not play audio" do
      Dir.cd "./spec/apps/full" do
        cli = SentryCli.new(
          shard_src_path: "./src/sentry_cli.cr",
          shard_run_command: "bin/sentry",
          opts: ["--info"]
        )

        config = cli.config

        config.info?.should be_true
      end
    end
  end
end
