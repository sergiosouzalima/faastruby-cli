module FaaStRuby
  module Command
    module Function
      class New < FunctionBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @function_name = @args.shift
          parse_options
          @base_dir ||= @function_name
          @options['runtime_name'] ||= 'ruby'
          @options['runtime_version'] ||= '2.5.3'
          @options['template'] ||= FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example', runtime: @options['runtime_name']))
        end

        def run
          @options['template'].install(to: @base_dir, force: @options['force'])
          faastruby_yaml = "#{@base_dir}/faastruby.yml"
          if File.file?(faastruby_yaml)
            @yaml_content = YAML.load(File.read(faastruby_yaml))
            @yaml_content['name'] = @function_name
            @options['runtime_name'], @options['runtime_version'] = @yaml_content['runtime']&.split(':')
            @options['runtime_name'] ||= 'ruby'
            @options['runtime_version'] ||= '2.5.3'
          else
            @yaml_content = yaml_for(@options['runtime_name'])
          end
          write_yaml
          post_tasks(@options['runtime_name'])
        end

        def self.help
          "new".light_cyan + " FUNCTION_NAME [--blank] [--force] [--runtime]" +
          <<-EOS

    --blank
        Create a blank function
    --force
        Continue if directory already exists and overwrite files
    -g
        Initialize a Git repository.
    --runtime
        Choose the runtime. Options are: #{SUPPORTED_RUNTIMES.join(', ')}
    --template TYPE(local|git|github):SOURCE
        Use another function as template. Examples:
          --template local:/path/to/folder
          --template git:git@github.com:user/repo.git
          --template github:user/repo
EOS
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-g'
              @options['git_init'] = true
            when '--template'
              FaaStRuby::CLI.error("Option '--template' can't be used with '--blank' or '--runtime'.".red) if @options['runtime'] || @options['blank_template']
              template = @args.shift
              type, source = template.split(':')
              @options['template'] = FaaStRuby::Template.new(type: type, source: source)
            when '--runtime'
              FaaStRuby::CLI.error("Option '--template' can't be used with '--blank' or '--runtime'.".red) if @options['template']
              @options['runtime'] = @args.shift
              @options['runtime_name'], @options['runtime_version'] = @options['runtime'].split(':')
              template_name = @options['blank_template'] ? 'example-blank' : 'example'
              @options['template'] = FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example', runtime: @options['runtime_name']))
              FaaStRuby::CLI.error(["Unsupported runtime: #{@options['runtime']}".red, "Supported values are #{SUPPORTED_RUNTIMES.join(", ")}"], color: nil) unless SUPPORTED_RUNTIMES.include?(@options['runtime'])
            when '-f', '--force'
              @options['force'] = true
            when '--blank'
              FaaStRuby::CLI.error("Option '--template' can't be used with '--blank' or '--runtime'.".red) if @options['template']
              @options['blank_template'] = true
              @options['template'] = FaaStRuby::Template.new(type: 'local', source: Template.gem_template_path_for('example-blank', runtime: @options['runtime_name'] || 'ruby'))
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: FUNCTION_NAME".red
            @missing_args << usage
          end
          @missing_args
        end

        def yaml_for(runtime_name)
          case runtime_name
          when 'crystal'
            test_command = 'crystal spec --no-color'
          when 'ruby'
            test_command = 'rspec'
          else
            test_command = 'rspec'
          end
          {
            'cli_version' => FaaStRuby::VERSION,
            'name' => @function_name,
            'runtime' => @options['runtime'] || 'ruby:2.5.3',
            'test_command' => test_command,
            'abort_build_when_tests_fail' => true,
            'abort_deploy_when_tests_fail' => true
          }
        end

        def write_yaml
          write_file("#{@function_name}/faastruby.yml", @yaml_content.to_yaml)
        end

        def post_tasks(runtime_name)
          update_readme
          puts `git init #{@base_dir}` if @options['git_init']
          case runtime_name
          when 'ruby'
            bundle_install
          when 'crystal'
            write_shards_file
            shards_install
          else
            bundle_install
          end
        end

        def update_readme
          file_path = "#{@base_dir}/README.md"
          return false unless File.file?(file_path)
          readme = File.read(file_path)
          File.write(file_path, ERB.new(readme).result(binding))
        end

        def bundle_install
          spinner = spin("Installing gems...")
          system("bundle install --gemfile=#{@base_dir}/Gemfile > /dev/null")
          spinner.stop('Done!')
        end

        def write_shards_file
          shards = {
            'name' => @function_name,
            'version' => '0.1.0',
            'crystal' => @options['runtime_version'],
            'targets' => {
              @function_name => {
                'main' => 'src/handler.cr'
              }
            },
            'development_dependencies' => {
              'faastruby-spec-helper' => {
                'github' => 'faastruby/faastruby-spec-helper.cr',
                'version' => '~> 0.1.0'
              }
            }
          }.to_yaml
          write_file("#{@base_dir}/shard.yml", shards)
        end

        def shards_install
          spinner = spin("Installing shards...")
          system("cd #{@base_dir} && shards install > /dev/null")
          spinner.stop('Done!')
        end
      end
    end
  end
end
