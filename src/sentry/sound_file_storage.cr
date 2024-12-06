{% skip_file if flag?(:win32) %}

require "baked_file_system"

class SoundFileStorage
  extend BakedFileSystem

  bake_folder "./sounds"
end

class AudioPlayer
  @success_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("success.wav")
  @error_wav : BakedFileSystem::BakedFile = SoundFileStorage.get("error.wav")
  @player : String?

  def initialize
    @player = Process.find_executable("aplay")
  end

  def success
    if (player = @player)
      Process.new(command: player, input: @success_wav)
      @success_wav.rewind
    end
  end

  def error
    if (player = @player)
      Process.new(command: player, input: @error_wav)
      @error_wav.rewind
    end
  end
end
