require 'thread'
require "aggressive_git/version"

module AggressiveGit

  WAIT = 0.1

  def self.last_commit_time
    unix_time = `git log -1 --pretty=format:%ct`
    unix_time.to_i
  end

  def self.remove_tracked_changes
    `git reset --hard`
  end

  def self.remove_untracked_changes
    `git clean -f -d`
  end

  def self.wipe_after seconds
    Thread.new do
      end_time = AggressiveGit.last_commit_time + seconds

      until Time.now.to_f >= end_time
        sleep WAIT
      end

      end_time = AggressiveGit.last_commit_time + seconds
      if Time.now.to_f >= end_time
        remove_tracked_changes
        remove_untracked_changes
      end
    end
  end

end
