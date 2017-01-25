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
      if Dir.exists? temp_folder
        FileUtils.rm_rf temp_folder
      end
      FileUtils.mkdir temp_folder
      Dir.chdir temp_folder
      system 'git', 'init'
      commit_new_file 'first_file'

      stub_const 'AggressiveGit::WAIT', 0.01
    end

    after(:each) do
      Dir.chdir '..'
      FileUtils.rm_rf temp_folder
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
  end

  context 'mock git project' do
    before do
      stub_const 'AggressiveGit::WAIT', 0.01
    end

    describe '#wipe_after' do
      it 'wipes uncommited changes after set time' do
        tick = mock_sleep

        wipe_count = 0
        mock_wipe { wipe_count += 1 }

        now = Time.now.to_f
        thread = AggressiveGit.wipe_after 60

        mock_time { now + 59 }
        tick.call

        expect(wipe_count).to eq 0

        mock_time { now + 61 }
        tick.call

        expect(wipe_count).to eq 1

        thread.kill
        thread.join
      end

      it 'resets after each commit' do
        tick = mock_sleep

        wipe_count = 0
        mock_wipe { wipe_count += 1 }

        now = Time.now.to_f
        mock_last_commit_time { now }
        thread = AggressiveGit.wipe_after 60

        mock_last_commit_time { now + 10 }
        mock_time { now + 61 }
        tick.call

        expect(wipe_count).to eq 0

        thread.kill
        thread.join
      end

      it 'can resume after being restarted' do
        tick = mock_sleep

        wipe_count = 0
        mock_wipe { wipe_count += 1 }

        now = Time.now.to_f
        mock_last_commit_time { now - 10 }
        thread = AggressiveGit.wipe_after 60, resume: true

        tick.call
        mock_time { now + 51 }
        tick.call

        expect(wipe_count).to eq 1

        thread.kill
        thread.join
      end

      it 'starts over after being restarted' do
        tick = mock_sleep

        wipe_count = 0
        mock_wipe { wipe_count += 1 }

        now = Time.now.to_f
        mock_last_commit_time { now - 10 }
        thread = AggressiveGit.wipe_after 60

        mock_time { now + 51 }
        tick.call

        expect(wipe_count).to eq 0

        thread.kill
        thread.join
      end

      it 'wipes files repeatedly' do
        tick = mock_sleep

        wipe_count = 0
        mock_wipe { wipe_count += 1 }

        now = Time.now.to_f
        thread = AggressiveGit.wipe_after 60, resume: true
        tick.call

        mock_time { now + 61 }
        tick.call

        mock_time { now + 122 }
        tick.call

        expect(wipe_count).to eq 3

        thread.kill
        thread.join
      end
    end
  end
end
