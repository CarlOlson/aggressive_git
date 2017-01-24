$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "aggressive_git"

def system *cmds
  Open3.capture3(*cmds)
end

def touch_file filename
  system 'touch', filename
end

def stage_new_file filename
  touch_file filename
  system 'git', 'add', filename
end

def commit_new_file filename
  stage_new_file filename
  system 'git', 'commit', '-m', filename
end

def dir_size
  Dir.glob('*').size
end

def mock_time &block
  allow(Time).to receive_message_chain(:now, :to_f, &block)
end

def mock_last_commit_time &block
  allow(AggressiveGit).to receive(:last_commit_time, &block)
end

def double_wait
  sleep AggressiveGit::WAIT * 2
end
