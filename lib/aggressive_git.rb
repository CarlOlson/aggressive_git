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
      last_wipe_time = 0
      wipe_after_core seconds, last_wipe_time, resume

      loop do
        last_wipe_time = Time.now.to_f
        wipe_after_core seconds, last_wipe_time, true
      end
    end
  end

  private
  def self.past_time? time
    Time.now.to_f >= time
  end

  def self.wipe_after_core seconds, last_wipe_time, resume
    if resume
      if last_wipe_time + seconds > Time.now.to_f
        end_time = last_wipe_time + seconds
      else
        end_time = last_commit_time + seconds
      end
    else
      end_time = Time.now.to_f + seconds
    end

    until past_time?(end_time)
      sleep WAIT
    end

    if past_time?(last_commit_time + seconds)
      wipe
    end
  end

  def wipe
    remove_tracked_changes
    remove_untracked_changes
  end

end
