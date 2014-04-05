# create binstubs
class Heroku::Command::Binstubs < Heroku::Command::Base

  # binstubs [BASENAME]
  #
  # create binstubs for BASENAME and each of BASENAME-*
  #
  # Binstubs will be named after the * part of BASENAME-*.  If the application
  # BASENAME exists, its binstub will be named production.
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  # -f, --full          # use full app name as binstub name
  def index
    create
  end

  # binstubs:create APP --as STUB
  #
  # create a binstub
  #
  # Without the --as argument, this command is identical to heroku binstubs.
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  # -f, --full          # use full app name as binstub name
  # --as STUB           # create a single one-off binstub named STUB
  def create
    if options[:as]
      app_name = shift_argument || app
      validate_arguments!
      [write_binstub(app_name, options[:as])]
    elsif args.any?
      basename = shift_argument
      validate_arguments!
      write_binstubs_for_basename(basename)
    elsif options[:app]
      write_binstubs_for_basename(options[:app])
    else
      basename = File.basename(Dir.pwd).tr('_', '-').split('.').first
      write_binstubs_for_basename(basename, basename.gsub(/-/, ''))
    end
  end

  # binstubs:setup ...
  #
  # create binstubs and set up remotes
  #
  # This calls binstub:create and then sets up Git remotes for each app.
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  # -f, --full          # use full app name as binstub name
  # --as STUB           # create a single one-off binstub named STUB
  def setup
    create.each do |(app, name)|
      create_git_remote(name, "git@heroku.com:#{app}.git")
    end
  end

  # binstubs:list
  #
  # list binstubs
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  def list
    options[:directory] = shift_argument || options[:directory]
    validate_arguments!
    each_binstub do |path, app|
      display_binstub(path, app)
    end
  end

  # binstubs:clean
  #
  # delete all Heroku binstubs
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  def clean
    validate_arguments!
    each_binstub do |path, app|
      File.unlink(path)
      display "#{path} deleted"
    end
  end

  # binstubs:remotes
  #
  # create a binstub for each Git remote
  #
  # The binstub will be named after the remote itself.
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  # -f, --full          # use full app name as binstub name
  def remotes
    validate_arguments!
    if all_git_remotes.empty?
      error 'No Git remotes found.'
    end
    all_git_remotes.each do |name, app|
      if name == 'heroku'
        display "#{bin_path(name)} would be recursive: skipping"
      else
        write_binstub(app, name)
      end
    end
  end

  # binstubs:all [PREFIX]
  #
  # create a binstub for every app you have access to
  #
  # The binstub will be named after the remote itself.  If PREFIX is given,
  # only apps starting with PREFIX will be selected.
  #
  # -d, --directory DIR # use directory DIR (default: ./bin)
  def all
    options[:full] = true
    app_names.grep(/^#{shift_argument}/).each do |app|
      write_binstub(app, nil)
    end
  end

  private

  def app_for_binstub(path)
    if File.file?(path) && File.readable?(path) && File.read(path, 512) =~ /\A#!.*\n+HEROKU_APP=['"]?(.*?)['"]? .*?heroku.*\n*\z/
      $1
    end
  end

  def each_binstub
    found = false
    Dir[bin_path('*')].sort.each do |stub|
      if app = app_for_binstub(stub)
        found = true
        yield stub, app
      end
    end
    error 'No binstubs found.' unless found
  end

  def bin_path(*args)
    File.join(options[:directory] || 'bin', *args)
  end

  def display_binstub(path, app)
    display "#{path} -> #{app}"
  end

  def write_binstub(app, short_name)
    Dir.mkdir(bin_path) unless File.directory?(bin_path)

    name = options[:full] ? app : short_name
    path = bin_path(name)
    if File.exist?(path) && !app_for_binstub(path)
      display("#{path} exists: not overwriting")
    else
      File.open(path, 'w', 0777) do |f|
        f.write(<<-SH)
#!/bin/sh
HEROKU_APP=#{app} HKAPP=#{app} exec "${HEROKU_COMMAND:-heroku}" "$@"
        SH
      end
      display_binstub(path, app)
    end
    [app, short_name]
  rescue SystemCallError => e
    error e.message
  end

  def write_binstubs_for_basename(*candidates)
    basename = candidates.detect do |b|
      app_names.grep(/^#{b}(-|$)/).any?
    end
    if basename.nil?
      error("Couldn't find any apps named #{candidates.first} or #{candidates.first}-*.")
    end
    app_names.grep(/^#{basename}(-|$)/).map do |app|
      name = options[:full] ? app : app[basename.length+1..-1] || 'production'
      write_binstub(app, name)
      [app, name]
    end
  end

  def app_names
    @app_names ||= api.get_apps.body.map {|a| a['name']}.sort
  end

  def all_git_remotes
    @git_remotes ||= git_remotes || {}
  end

end
