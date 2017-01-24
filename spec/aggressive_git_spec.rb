require 'fileutils'
require 'open3'
require 'spec_helper.rb'

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
        system 'touch', 'second_file'
        AggressiveGit.remove_tracked_changes
        expect(dir_size).to eq 2
      end

      it 'removes changes to commited files' do
        commit_new_file 'second_file'
        File.open('second_file', 'w') { |f| f.write 'hello' }
        AggressiveGit.remove_tracked_changes
        data = File.open('second_file', 'r') { |f| f.read }
        expect(data).to eq ''
      end

      it 'removes uncommited, but staged files' do
        stage_new_file 'second_file'
        AggressiveGit.remove_tracked_changes
        expect(dir_size).to eq 1
      end
    end

    describe '#remove_untracked_changes' do
      it 'removes unstaged files' do
        touch_file 'second_file'
        AggressiveGit.remove_untracked_changes
        expect(dir_size).to eq 1
      end

      it 'removes directories' do
        FileUtils.mkdir 'new_dir'
        touch_file 'new_dir/new_file'
        AggressiveGit.remove_untracked_changes
        expect(dir_size).to eq 1
      end
    end

    describe '#wipe_after' do
      it 'wipes uncommited changes after set time' do
        now = Time.now.to_f
        thread = AggressiveGit.wipe_after 60
        touch_file 'second_file'

        mock_time { now + 59 }
        double_wait
        expect(dir_size).to eq 2

        mock_time { now + 61 }
        double_wait
        expect(dir_size).to eq 1

        thread.kill
      end

      it 'resets after each commit' do
        now = Time.now.to_f
        mock_last_commit_time { now }
        thread = AggressiveGit.wipe_after 60
        touch_file 'second_file'

        mock_last_commit_time { now + 10 }
        mock_time { now + 61 }

        double_wait
        expect(dir_size).to eq 2

        thread.kill
      end

      it 'can resume after being restarted' do
        now = Time.now.to_f
        mock_last_commit_time { now - 10 }
        thread = AggressiveGit.wipe_after 60
        touch_file 'second_file'

        mock_time { now + 51 }

        double_wait
        expect(dir_size).to eq 1

        thread.kill
      end
    end
  end
end
