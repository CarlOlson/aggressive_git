require 'fileutils'
require 'open3'
require 'spec_helper.rb'

def system *cmds
  Open3.capture3(*cmds)
end

def commit_new_file filename
  system 'touch', filename
  system 'git', 'add', filename
  system 'git', 'commit', '-m', filename
end

describe AggressiveGit do
  it 'has a version number' do
    expect(AggressiveGit::VERSION).not_to be nil
  end

  context 'command line' do
    it 'has a command reference' do
      result = `ruby -Ilib bin/aggressive_git --help`
      expect(result).to match /^Usage/
    end

    it 'shows the version number' do
      result = `ruby -Ilib bin/aggressive_git --version`
      expect(result).to match AggressiveGit::VERSION
    end
  end

  context 'git projects' do
    temp_folder = 'temp_git'

    before(:each) do
      FileUtils.mkdir temp_folder
      Dir.chdir temp_folder
      system 'git', 'init'
      commit_new_file 'first_file'
    end

    after(:each) do
      Dir.chdir '..'
      FileUtils.rm_r temp_folder
    end

    describe '#last_commit_time' do
      it 'returns a UNIX timestamp' do
        result = AggressiveGit.last_commit_time
        expect(result).to be_within(10).of(Time.now.to_i)
      end
    end

    describe '#remove_tracked_changes' do
      it 'does not remove files' do
        system 'touch', 'new_file'
        AggressiveGit.remove_tracked_changes
        expect(Dir.glob('*')).to include 'new_file'
      end

      it 'removes changes to commited files' do
        commit_new_file 'new_file'
        File.open('new_file', 'w') { |f| f.write 'hello' }
        AggressiveGit.remove_tracked_changes
        data = File.open('new_file', 'r') { |f| f.read }
        expect(data).to eq ''
      end

      it 'removes uncommited, but staged files' do
        stage_new_file 'new_file'
        AggressiveGit.remove_tracked_changes
        expect(Dir.glob('*').size).to eq 1
      end
    end
    end
  end
end
