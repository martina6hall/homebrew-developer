#: `test-bot-docker` <formulae>...
#:
#:  Build a bottle for the specified formulae using a Docker container.
#:  See `test-bot` for further options accepted by this command.

module Homebrew
  module_function

  def test_bot_docker
    if ENV["HOMEBREW_BINTRAY_USER"].nil? || ENV["HOMEBREW_BINTRAY_KEY"].nil?
      raise "Missing HOMEBREW_BINTRAY_USER or HOMEBREW_BINTRAY_KEY variables!"
    end

    argv = ARGV.join(" ")
    safe_system "docker", "run", "--name=linuxbrew-test-bot",
      "-e", "HOMEBREW_BINTRAY_USER", "-e", "HOMEBREW_BINTRAY_KEY",
      "linuxbrew/linuxbrew",
      "sh", "-c", <<-EOS.undent
        git config --global user.name LinuxbrewTestBot
        git config --global user.email testbot@linuxbrew.sh
        sudo apt-get install -y python
        brew tap linuxbrew/xorg
        mkdir linuxbrew-test-bot
        cd linuxbrew-test-bot
        brew test-bot #{argv}
        status=$?
        ls
        brew test-bot --ci-upload
        head *.json
        exit $status
        EOS

    safe_system "docker", "cp", "linuxbrew-test-bot:/home/linuxbrew/linuxbrew-test-bot", "."
    cd "linuxbrew-test-bot" do
      safe_system HOMEBREW_BREW_FILE, "bottle", "--merge", "--write", *Dir["*.json"]
    end

    oh1 "Done!"
    puts <<-EOS.undent
      To clean up, run
        docker rm linuxbrew-test-bot
        rm -rf linuxbrew-test-bot
    EOS
  end
end

Homebrew.test_bot_docker
