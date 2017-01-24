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

  def self.wipe_after seconds, resume: false
    Thread.new do
      wipe_after_core seconds, resume
      loop do
        wipe_after_core seconds, true
      end
    end
  end

  private
  def self.past_time? time
    Time.now.to_f >= time
  end

  def self.wipe_after_core seconds, resume
    if resume
      end_time = last_commit_time + seconds
    else
      end_time = Time.now.to_f + seconds
    end

    until past_time?(end_time)
      sleep WAIT
    end

    if past_time?(last_commit_time + seconds)
      remove_tracked_changes
      remove_untracked_changes
    end
  end

end
