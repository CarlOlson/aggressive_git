require 'fileutils'
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

  describe '#last_commit_time' do
    temp_folder = 'temp_git'

    before(:each) do
      FileUtils.mkdir temp_folder
      Dir.chdir temp_folder
      `git init`
      `touch only_file`
      `git add only_file`
      `git commit -m only_commit`
    end

    after(:each) do
      Dir.chdir '..'
      FileUtils.rm_r temp_folder
    end

    it 'returns a UNIX timestamp' do
      result = AggressiveGit.last_commit_time
      expect(result).to be_within(10).of(Time.now.to_i)
    end
  end

end
