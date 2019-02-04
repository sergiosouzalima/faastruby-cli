# Changelog

## 0.4.16 - Feb 4 2019
- Add support for function templates
- Add cli_version to `faastruby.yml`

## 0.4.15 - Feb 2 2019
- Add support for Crystal 0.27.1 and Ruby 2.6.1

## 0.4.14 - Feb 1 2019
- Ruby functions now use a spec helper from `faastruby` gem.
- Crystal functions now use the shard `faastruby-spec-helper` to assist on tests.
- Mock `publish` method on tests.
- Wrap functions in anonymous module to avoid concurrency problems.
- Read all STDIN when updating context with --stdin [PR-5](https://github.com/FaaStRuby/faastruby-cli/pull/5) | Thanks [Justin](https://github.com/presidentbeef)!
- `shards install` runs when building crystal function before deploy
- Better message when updating the function context
- Fixed output when creating a function with `faastruby new`

A new version of the platform API was released in tandem to address the issue that would erase contexts when a function is redeployed. Thanks [Justin](https://github.com/presidentbeef) again for pointing that out. 

## 0.4.12 - Jan 26 2019
Special thanks to [Sean Earle](https://github.com/HellRok) for fixing those bugs!
- FaaStRuby Server: Respond with css content type [PR-4](https://github.com/FaaStRuby/faastruby-cli/pull/4)
- Setup the server to respond to HEAD requests [PR-3](https://github.com/FaaStRuby/faastruby-cli/pull/3)

## 0.4.11 - Jan 19 2019
- Fix wrong working directory when running functions locally with `faastruby server`

## 0.4.10 - Jan 14 2019
- Fix command `faastruby server`

## 0.4.9 - Jan 13 2019
- Changes in `faastruby server` 
  - Cleaned up code
  - Logs are easier to read
  - Function responses show up in the log
  - Support for events with `publish`

## 0.4.8 - Jan 8 2019
- Use the actual param rather than the Sinatra::Params object

## 0.4.7 - Jan 8 2019
- `create-workspace` will not create a folder on current dir, unless specified with `--create-local-dir`

## 0.4.6 - Jan 5 2019
- Default value when no runtime is provided to `new`

## 0.4.5 - Jan 5 2019
- Change help terminal colors for better readability
- Add png, jpeg, css, svg, gif and icon mime-types to `render`

## 0.4.4 - Jan 3 2019
- Update faastruby-rpc to 0.2.1

## 0.4.3 - Dec 31 2018
- Updated `faastruby-rpc` dependency to 0.2.0.
- Improved FaaStRuby Server.

## 0.4.2 - Dec 30 2018
- Simplified Crystal Hello World example.

## 0.4.1 - Dec 30 2018
- Updated ruby templates.

## 0.4.0 - Dec 29 2018
- Faster hello-world Ruby template.
- Ruby 2.6.0 and Crystal (beta) 0.27.0 released.

## 0.3.8 - Dec 29 2018
- Crystal template runs a lot faster.

## 0.3.7 - Dec 29 2018
- Error when unsupported runtimes are passed to `new`

## 0.3.6 - Dec 29 2018
- Add support for different runtimes with `--runtime` to `new` command. Example: `faastruby new hello-world --runtime ruby:2.6.0`
- Add runtime `ruby:2.6.0`
- Add runtime `crystal:0.27.0`

## 0.3.5 - Dec 27 2018
- Clean up credentials file when listing or saving it to remove nulls.
- Raise error when trying to save null credentials to file.
- Ignore null entries from credentials hash.

## 0.3.4 - Dec 27 2018
- Use `JSON.pretty_generate` when writing to credentials file, so it is more human readable.
- Fix bug: when creating a workspace from `deploy-to` command, if the workspace existed it would not error, but the deploy would fail and a null entry would go in the credentials file.

## 0.3.3 - Dec 21 2018
- `deploy-to` will try to create the workspace if it doesn't exist.
- Changed template to add a carriage return.

## 0.3.2 - Dec 15 2018
- Better output for tests
- `bundle check && bundle install` runs before building a package to make sure Gemfile.lock is updated.
- New command: `faastruby deploy`. This command is meant to be run in a FaaStRuby Project folder, and will deploy all workspaces and their functions.
- Updated spec templates with new helper that stubs calls to FaaStRuby server when using `faastruby-rpc`.
- `render` is now the preferred method to set the return value of functions.
- Upgraded dependency `faastruby-rpc` to version 0.1.3.
- Removed region SFO2 (sorry, but the usage was minimal.)

## 0.3.1 - Dec 9 2018
- Add faastruby-rpc to Gemfile template and runtime dependencies

## 0.3.0 - Dec 9 2018
- Add spinner feedback when destroying workspace
- Better error handling when response is not JSON
- New command `faastruby server` will start a development environment.

## 0.2.6 - Nov 20 2018
- Change Ruby minimum version to 2.5.0
- Disable timeout on HTTP requests.
- Handle CTRL+C interruptions gracefully
- Add `--region` to help

## 0.2.5 - Nov 18 2018
- Support for multiple regions with `faastruby --region [REGION] ...`

## 0.2.4 - Skipped

## 0.2.3 - Oct 20 2018
- Added #status_code to Workspace class to hold the API response code after a request
- Added refresh_credentials endpoint
- Fix the request headers
- Fix bug with `faastruby help`

## 0.2.2 - Oct 20 2018
### New
- Functions can be scheduled via faastruby.yml
### Fixed
- Some API errors were not being properly displayed

## 0.2.1 - Oct 16 2018
- New command: `add-credentials` - add credentials to a credentials file
- New command: `list-credentials` - list current credentials in a credentials file
Run `faastruby help` for usage details.

## 0.2.0 - Oct 12 2018
- Full rewrite of the gem. All command line parameters have changed. Please see the [documentation](https://faastruby.io/tutorial.html).
- No more git repositories.
- Functions are packaged, deployed and managed individually.
- Functions have a YAML configuration file.
- Functions can have tests and they can be configured to run before each deploy, aborting if a failure happens.
- Added option to print or save the workspace credentials into a different file upon creation, instead of saving it to ~/.faastruby
- Read a different credentials file via FAASTRUBY_CREDENTIALS environment variable.
- Read credentials via environment variables: FAASTRUBY_API_KEY and FAASTRUBY_API_SECRET.
