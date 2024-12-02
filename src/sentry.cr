require "yaml"
require "colorize"
require "./sentry/*"
require "./sound_file_storage"

module Sentry
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
