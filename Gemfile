# encoding: utf-8

source 'https://rubygems.org'
source 'https://geminst:943662ea7d0fad349eeae9f69adb521d@nextgem.engineyard.com/'

##
# Gemfile.lock controls the dependencies used when running the specs in `spec/`.
#
# backup.gemspec controls the dependencies that will be installed and used by
# the released version of backup. It also controls the dependencies used when
# running the specs in `vagrant/spec`, which are run on the VM.
#
# Whenever Gemfile.lock is updated, `rake gemspec` must be run to sync
# backup.gemspec with Gemfile.lock. All gems in the :production group
# (and their dependencies) will be added to backup.gemspec.
##

# Specify version requirements to control `bundle update` if needed.
group :production do
  gem 'thor'
  gem 'open4'
  # waiting until this is resolved:
  # https://github.com/fog/fog/commit/f6d361b2e2e#L46R201
  # https://github.com/fog/fog/pull/1815
  gem 'fog', '= 1.10.1'
  gem 'excon'
  gem 'dropbox-sdk', '= 1.5.1' # patched
  gem 'net-ssh'
  gem 'net-scp'
  gem 'net-sftp'
  gem 'parallel'
  gem 'mail'
  gem 'twitter'
  gem 'hipchat'
  gem 'json'
  gem 'ey-core', '~> 0.1.5'
end

gem 'rspec'
gem 'mocha'
gem 'timecop'

# Omitted from Travis CI Environment
group :no_ci do
  gem 'guard'
  gem 'guard-rspec'
  gem 'fuubar'

  gem 'rb-fsevent' # Mac OS X
  gem 'rb-inotify' # Linux

  gem 'yard'
  gem 'redcarpet'
end

