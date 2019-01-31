module FaaStRuby
  module Command
    module Function
      class New < FunctionBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @function_name = @args.shift
          @base_dir = "./#{@function_name}"
          parse_options
          @options['template_path'] ||= 'templates/ruby'
          @options['template'] ||= 'example'
          @options['runtime_name'] ||= 'ruby'
          @options['runtime_version'] ||= '2.5.3'
          @yaml_content = yaml_for(@options['runtime_name'])
        end

        def run
          dir_exists? unless @options['force']
          copy_template
          write_yaml
          post_tasks(@options['runtime_name'])
        end

        def self.help
          "new".light_cyan + " FUNCTION_NAME [--blank] [--force] [--runtime]" +
          <<-EOS

    --blank              # Create a blank function
    --force              # Continue if directory already exists and overwrite files
    --runtime            # Choose the runtime. Options are: #{SUPPORTED_RUNTIMES.join(', ')}
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
            when '--runtime'
              @options['runtime'] = @args.shift
              @options['runtime_name'], @options['runtime_version'] = @options['runtime'].split(':')
              @options['template_path'] = "templates/#{@options['runtime_name']}"
              FaaStRuby::CLI.error(["Unsupported runtime: #{@options['runtime']}".red, "Supported values are #{SUPPORTED_RUNTIMES.join(", ")}"], color: nil) unless SUPPORTED_RUNTIMES.include?(@options['runtime'])
            when '-f', '--force'
              @options['force'] = true
            when '--blank'
              @options['template'] = 'example-blank'
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def dir_exists?
          return unless File.directory?(@base_dir)
          print "The folder '#{@function_name}' already exists. Overwrite files? [y/N] "
          response = STDIN.gets.chomp
          FaaStRuby::CLI.error("Cancelled", color: nil) unless response == 'y'
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: FUNCTION_NAME".red
            @missing_args << usage
          end
          @missing_args
        end

        def copy_template
          source = "#{Gem::Specification.find_by_name("faastruby").gem_dir}/#{@options['template_path']}/#{@options['template']}"
          FileUtils.mkdir_p(@base_dir)
          FileUtils.cp_r("#{source}/.", "#{@base_dir}/")
          case @options['runtime_name']
          when 'ruby'
            puts "+ d #{@base_dir}".green
            puts "+ d #{@base_dir}/spec".green
            puts "+ f #{@base_dir}/spec/handler_spec.rb".green
            puts "+ f #{@base_dir}/spec/spec_helper.rb".green
            puts "+ f #{@base_dir}/Gemfile".green
            puts "+ f #{@base_dir}/handler.rb".green
          when 'crystal'
            puts "+ d #{@base_dir}".green
            puts "+ d #{@base_dir}/spec".green
            puts "+ d #{@base_dir}/spec/helpers".green
            puts "+ f #{@base_dir}/spec/helpers/faastruby.cr".green
            puts "+ f #{@base_dir}/spec/handler_spec.cr".green
            puts "+ f #{@base_dir}/spec/spec_helper.cr".green
            puts "+ d #{@base_dir}/src".green
            puts "+ f #{@base_dir}/src/handler.cr".green
          end
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
            'name' => @function_name,
            'runtime' => @options['runtime'] || 'ruby:2.5.3',
            'test_command' => test_command,
            'abort_build_when_tests_fail' => true,
            'abort_deploy_when_tests_fail' => true
          }
        end

        def write_yaml
          write_file("#{@base_dir}/faastruby.yml", @yaml_content.to_yaml)
        end

        def post_tasks(runtime_name)
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
