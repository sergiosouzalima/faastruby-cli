module FaaStRuby
  class Template
    TYPES = ['local', 'git', 'github']
    def self.gem_template_path_for(name, runtime:)
      "#{Gem::Specification.find_by_name("faastruby").gem_dir}/templates/#{runtime}/#{name}"
    end

    attr_accessor :type, :source, :target
    def initialize(type:, source:)
      FaaStRuby::CLI.error(["Unknown template type: '#{type}'. Valid types are:", TYPES], color: nil) unless TYPES.include?(type)
      @type = type
      @source = source
    end

    def install(to:, force: false)
      @target = to
      @force = force
      FaaStRuby::CLI.error("Could not determine the target path for template '#{type}:#{source}'. Please report this bug at https://github.com/FaaStRuby/faastruby-cli/issues", color: nil) unless target
      return install_from_folder(source) if local?
      return install_from_git(source) if git?
      return install_from_github if github?
    end

    def install_from_github
      repo = "git@github.com:/#{source}.git"
      install_from_git(repo)
    end

    def install_from_git(repo)
      local_dir = Dir.mktmpdir
      git_pull(repo, local_dir)
      install_from_folder(local_dir)
    ensure
      FileUtils.remove_entry local_dir
    end

    def git_pull(repo, local_dir)
      FaaStRuby::CLI.error("Could not clone repository #{repo} into #{local_dir}") unless
        system("git clone #{repo} #{local_dir}")
    end

    def install_from_folder(folder)
      # puts "installing from folder #{folder}"
      if File.directory?(target)
        puts "! d #{target}".yellow
      else
        FileUtils.mkdir_p(target)
        puts "+ d #{target}".green
      end
      Dir.glob("**/*", base: folder).each do |entry|
        full_source_path = "#{folder}/#{entry}"
        full_target_path = "#{target}/#{entry}"
        create_dir(full_target_path) if File.directory?(full_source_path)
        copy_file(source: full_source_path, destination: full_target_path) if File.file?(full_source_path)
      end
      
    end

    def create_dir(dir)
      if File.directory?(dir)
        puts "! d #{dir}".yellow
      else
        FileUtils.mkdir_p(dir)
        puts "+ d #{dir}".green
      end
    end

    def copy_file(source:, destination:)
      if File.file?(destination) && !@force
        print "File '#{destination}' already exists. Overwrite? [y/N] "
        answer = STDIN.gets.chomp
        return(puts "[skipped] #{destination}") unless ['y', 'Y'].include?(answer)
      end
      FileUtils.cp(source, destination)
      puts "+ f #{destination}".green
    end

    def local?
      type == 'local'
    end

    def git?
      type == 'git'
    end

    def github?
      type == 'github'
    end
  end
end