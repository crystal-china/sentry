require "./spec_helper"

describe Sentry do
  # TODO: Write tests

  it "should return default config when there is a empty .sentry.yml" do
    config = SentryCli.new(
      shard_src_path: "./src/sentry_cli.cr",
      shard_run_command: "bin/sentry"
    )


  end
end
