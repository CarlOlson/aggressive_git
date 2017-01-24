require "aggressive_git/version"

module AggressiveGit

  def self.last_commit_time
    unix_time = `git log -1 --pretty=format:%ct`
    unix_time.to_i
  end

end
