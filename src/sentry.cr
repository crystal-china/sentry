require "./sentry/config"
require "./sentry/sound_file_storage"
require "./sentry/process_runner.cr"

module Sentry
  VERSION = {{
              `shards version "#{__DIR__}"`.chomp.stringify +
              " (rev " +
              `git rev-parse --short HEAD`.chomp.stringify +
              ")"
            }}
end
