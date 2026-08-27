require "rake/testtask"

test_tasks = FileList["spec/**/*_spec.rb"].map do |file|
  name = "test:#{File.basename(file, "_spec.rb")}"

  Rake::TestTask.new(name) do |task|
    task.libs << "lib"
    task.test_files = [ file ]
    task.warning = false
  end

  name
end

task test: test_tasks
task default: :test
