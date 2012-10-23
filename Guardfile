guard :bundler do
  watch('Gemfile')
end

guard :rspec, :cli => '--color --format doc' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})         { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/models/.+\.rb$})   { ["spec/models", "spec/acceptance"] }
  watch(%r{^spec/.+\.rb$})          { `say hello` }
  watch('spec/spec_helper.rb')      { "spec" }
end