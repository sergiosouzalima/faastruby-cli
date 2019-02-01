module FaaStRuby
  module Command
    module Function
      class Build < FunctionBaseCommand

        def self.build(source, output_file, quiet = false)
          spinner = spin("Building package...")
          FaaStRuby::Package.new(source, output_file).build
          spinner.stop('Done!')
          puts "+ f #{output_file}".green unless quiet
        end

        def initialize(args)
          @args = args
          load_yaml
          @function_name = @yaml_config['name']
          @abort_when_tests_fail = @yaml_config['abort_build_when_tests_fail']
          parse_options
          @options['source'] ||= '.'
          @options['output_file'] ||= "#{@function_name}.zip"
        end

        def ruby_runtime?
          @yaml_config['runtime'].nil? || @yaml_config['runtime'].match(/^ruby/)
        end

        def crystal_runtime?
          @yaml_config['runtime'].match(/^crystal/)
        end

        def run
          if ruby_runtime?
            FaaStRuby::CLI.error('Please fix the problems above and try again') unless bundle_install
          end
          if crystal_runtime?
            FaaStRuby::CLI.error('Please fix the problems above and try again') unless shards_install
          end
          tests_passed = run_tests
          FaaStRuby::CLI.error("Build aborted because tests failed and you have 'abort_build_when_tests_fail: true' in 'faastruby.yml'") unless tests_passed || !@abort_when_tests_fail
          puts "Warning: Ignoring failed tests because you have 'abort_build_when_tests_fail: false' in 'faastruby.yml'".yellow if !tests_passed && !@abort_when_tests_fail
          build(@options['source'], @options['output_file'])
        end

        def self.help
          "build".light_cyan + " [-s, --source SOURCE_DIR] [-o, --output-file OUTPUT_FILE]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def build(source, output_file)
          self.class.build(source, output_file)
        end

        def shards_install
          puts '[build] Verifying dependencies'
          return true unless File.file?('shard.yml')
          system('shards check') || system('shards install')
        end

        def bundle_install
          puts '[build] Verifying dependencies'
          return true unless File.file?('Gemfile')
          system('bundle check') || system('bundle install')
        end

        def run_tests
          FaaStRuby::Command::Function::Test.new(true).run(do_not_exit: true)
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-s', '--source-dir'
              @options['source'] = @args.shift
            when '-o', '--output-file'
              @options['output_file'] = @args.shift
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end
      end
    end
  end
end
