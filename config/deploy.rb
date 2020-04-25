# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "APP_NAME" # Your application name e.g my_drupal_site should respect machine name convention
set :repo_url, "REPO_URL" # like git@bitbucket.org:user_name/repo.git or git@github.com:user_name/repo.git
set :linked_files, fetch(:linked_files, []).push('sites/default/settings.local.php') # Change this if you use settings.php directly to sites/default/settings.php
set :linked_dirs, fetch(:linked_dirs, []).push('sites/default/files') # Change this to your file directory
set :keep_releases, 5
set :app_path, '.'
set :deploy_via, :remote_cache

# @todo: use full path or "#{shared_path.join("composer.phar")}" > shared_path gives wrong path
SSHKit.config.command_map[:composer] = "/usr/local/bin/composer.phar" # Change this with your composer.phar path

namespace :deploy do
  after :starting, 'composer:install_executable'
end

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :drupal8 do
  desc 'Drupal 8 deploy process'
  task :deploy do
    on roles(:app) do

      # Create database folder backup.
      execute :mkdir, "-p ~/databases-backup"
      within release_path.join(fetch(:app_path)) do
       info "Backup Database"
       execute :drush, "sql-dump > ~/db-backup/db-#{Time.now.strftime("%m-%d-%Y--%H-%M-%S")}.sql"
      end

      info "Clear Drush Cache"
      invoke "drupal:drush_clear_cache"

      info "Update Database"
      invoke "drupal:update:updatedb"

      info "Puts site offline "
     invoke "drupal:site_offline"

      # If you have advagg module enabled uncomment following lines.
#       within release_path.join(fetch(:app_path)) do
#         info "Advagg Remove all generated files."
#         execute :drush, 'advagg-caf'
#         info "Advagg Force the creation of all new files by incrementing a global counter."
#         execute :drush, 'advagg-fna'
#       end

      info "Puts site on line "
      invoke "drupal:site_online"

      info "Clear cache"
      invoke "drupal:cache:clear"

    end
  end

  desc 'Set permissions on old releases before cleanup'
   task :cleanup_settings_permission do
       on release_roles :all do |host|
       releases = capture(:ls, "-x", releases_path).split
       valid, invalid = releases.partition { |e| /^\d{14}$/ =~ e }

       warn t(:skip_cleanup, host: host.to_s) if invalid.any?

       if valid.count >= fetch(:keep_releases)
         info t(:keeping_releases, host: host.to_s, keep_releases: fetch(:keep_releases), releases: valid.count)
         directories = (valid - valid.last(fetch(:keep_releases))).map do |release|
           releases_path.join(release).to_s
         end
         if test("[ -d #{current_path} ]")
           current_release = capture(:readlink, current_path).to_s
           if directories.include?(current_release)
             warn t(:wont_delete_current_release, host: host.to_s)
             directories.delete(current_release)
           end
         else
           debug t(:no_current_release, host: host.to_s)
         end
         if directories.any?
           directories.each  do |dir_str|
             execute :chmod, "-R 755", dir_str
           end
         else
           info t(:no_old_releases, host: host.to_s, keep_releases: fetch(:keep_releases))
         end
       end
     end
   end

   desc 'Apply Permissions'
   task :apply_permissions do
       on roles(:app) do
           info "Apply Permissions -d 755 -f 644"
           within release_path.join(fetch(:app_path)) do
               info "#{release_path}/"
               execute :find, "#{release_path}/", " -type d -exec chmod u=rwx,g=rx,o=rx '{}' ';'"
               execute :find, "#{release_path}/", " -type f -exec chmod u=rw,g=r,o=r '{}' ';'"
           end
       end
   end

  after 'deploy:updated', 'drupal8:deploy'
  before 'deploy:finishing', 'drupal8:cleanup_settings_permission'
  after 'deploy:finished', 'drupal8:apply_permissions'
end
