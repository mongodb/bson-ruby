# vim:set filetype=ruby:
guard 'rspec', :all_after_pass => false, :cmd => 'bundle exec rspec -t ~style' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
end
