module FaaStRuby
  module Command
    module Function
      class RemoveFrom < FunctionBaseCommand
        def initialize(args)
          @args = args
          @missing_args = []
          FaaStRuby::CLI.error(@missing_args, color: nil) if missing_args.any?
          @workspace_name = @args.shift
          load_yaml
          @function_name = @yaml_config['name']
          FaaStRuby::Credentials.load_for(@workspace_name)
          parse_options
        end

        def run
          warning unless @options['force']
          FaaStRuby::CLI.error("Cancelled") unless @options['force'] == 'y'
          spinner = spin("Removing function from workspace '#{@workspace_name}'...")
          workspace = FaaStRuby::Workspace.new(name: @workspace_name)
          function = FaaStRuby::Function.new(name: @function_name, workspace: workspace)
          function.destroy
          if function.errors.any?
            spinner.stop('Failed :(')
            FaaStRuby::CLI.error(function.errors)
          end
          spinner.stop('Done!')
        end

        def self.help
          "remove-from".light_cyan + " WORKSPACE_NAME [-y, --yes]"
        end

        def usage
          "Usage: faastruby #{self.class.help}"
        end

        private

        def warning
          print "WARNING: ".red
          puts "This action will permanently remove the function '#{@function_name}' from the workspace '#{@workspace_name}'."
          print "Are you sure? [y/N] "
          @options['force'] = STDIN.gets.chomp
        end

        def parse_options
          @options = {}
          while @args.any?
            option = @args.shift
            case option
            when '-y', '--yes'
              @options['force'] = 'y'
            else
              FaaStRuby::CLI.error(["Unknown argument: #{option}".red, usage], color: nil)
            end
          end
        end

        def missing_args
          if @args.empty?
            @missing_args << "Missing argument: WORKSPACE_NAME".red
            @missing_args << usage
          end
          FaaStRuby::CLI.error(["'#{@args.first}' is not a valid workspace name.".red, usage], color: nil) if @args.first =~ /^-.*/
          @missing_args
        end
      end
    end
  end
end
