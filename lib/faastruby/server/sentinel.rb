require 'open3'
require 'tempfile'
require 'pathname'
module FaaStRuby
  module Sentinel
    def self.threads
      @@threads ||= {}
    end
    def self.start!
      find_crystal_projects.each do |path|
        project_folder = File.expand_path path
        threads[project_folder] = {}
        threads[project_folder]['watcher'] = start_watcher_for(project_folder)
      end
    end
    def self.start_watcher_for(project_folder)
      Thread.new do
        handler_path = "#{project_folder}/src/handler"
        Filewatcher.new("#{project_folder}/", exclude: ["#{project_folder}/handler", "#{project_folder}/handler.dwarf"]).watch do |filename, event|
          puts "[WatchDog] Previous Job for '#{project_folder}' aborted".yellow if (Thread.kill(threads[project_folder]['running']) rescue nil)
          threads[project_folder]['running'] = Thread.new {CrystalBuild.new(project_folder, handler_path).start}
        end
      end
      puts "[Watchdog] Watching function '#{project_folder}' for changes.".yellow
    end

    def self.find_crystal_projects
      directories = Dir.glob('**/faastruby.yml').map do |yaml_file|
        base_dir = yaml_file.split(File::SEPARATOR)[0..1].join('/')
        yaml = YAML.load(File.read yaml_file)
        base_dir if yaml['runtime']&.match(/^crystal:/)
      end
      directories.compact
    end
  end
  class CrystalBuild
    def initialize(directory, handler_path)
      @directory = directory
      @runtime_path = Pathname.new "#{Gem::Specification.find_by_name("faastruby").gem_dir}/lib/faastruby/server/crystal_runtime.cr"
      h_path = Pathname.new(handler_path)
      @handler_path = h_path.relative_path_from @runtime_path
      @env = {'HANDLER_PATH' => @handler_path.to_s}
      @cmd = "crystal build #{@runtime_path} -o handler"
    end
    def start
      Thread.report_on_exception = false
      Dir.chdir(@directory)
      job_id = SecureRandom.uuid
      puts "[WatchDog] Job #{job_id} started: ".yellow + "Compiling function #{@directory}"
      output, status = Open3.capture2e(@env, @cmd)
      puts output unless status.exitstatus == 0
      puts "[WatchDog] Job #{job_id} completed: ".yellow + status.to_s   
    end
  end
end