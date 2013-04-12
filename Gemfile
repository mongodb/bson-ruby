source "https://rubygems.org"

gem "json", :platforms => :mri_18
gem "rake"

group :development, :test do
  gem "cucumber"
  gem "rspec"

  unless ENV["CI"]
    gem "guard-rspec"
    gem "pry"
    gem "rb-fsevent"
    gem "terminal-notifier-guard"
    gem "json"
    gem "ruby-prof", :platforms => :mri
  end
end
