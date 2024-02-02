require 'simplecov-cobertura'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])
SimpleCov.start do
  add_filter "libexec"
  add_filter "bin"
  add_filter "tests/test_helper"
  add_filter "templates"
  Dir["tests/*"].select { File.file?(_1) }.each do |path|
    add_filter path
  end
end
