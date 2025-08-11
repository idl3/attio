require "bundler/gem_tasks"
require "rspec/core/rake_task"

begin
  require "yard"
  require "yard/rake/yardoc_task"
  
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb']
    t.options = ['--output-dir', 'docs']
  end
rescue LoadError
  # YARD is not available
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :coverage do
  desc "Run tests with coverage report"
  task :report do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
  end
end

namespace :docs do
  desc "Generate YARD documentation"
  task :generate do
    if defined?(YARD)
      Rake::Task["yard"].execute
    else
      puts "YARD is not available. Please install it with: gem install yard"
    end
  end

  desc "Generate and open documentation"
  task :open => :generate do
    if File.exist?("docs/index.html")
      system("open docs/index.html")
    else
      puts "Documentation not found. Run 'rake docs:generate' first."
    end
  end

  desc "Clean generated documentation"
  task :clean do
    FileUtils.rm_rf("docs") if File.exist?("docs")
    puts "Documentation cleaned."
  end

  desc "Serve documentation locally (requires 'gem install yard')"
  task :serve do
    system("yard server --reload")
  end
end
