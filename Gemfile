source "https://rubygems.org"

gem "json", :platforms => :mri_18
gem "rake"

group :development, :test do
  gem "rspec"

  unless ENV["CI"]
    gem "pry"
    gem "guard-rspec"
    gem "rb-inotify", :require => false # Linux
    gem "rb-fsevent", :require => false # OS X
    gem "rb-fchange", :require => false # Windows
    gem "terminal-notifier-guard"
    gem "ruby-prof", :platforms => :mri
  end
end
