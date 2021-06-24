# Gemfile
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'net-ssh' # needed for Ruby SSH commands
gem 'ed25519' # needed for SSH auth via keys
gem 'bcrypt_pbkdf' # needed for SSH auth via keys
