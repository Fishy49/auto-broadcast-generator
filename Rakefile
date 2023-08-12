# frozen_string_literal: true

# Rakefile
require 'fileutils'
require 'sequel'

namespace :db do
  # https://stackoverflow.com/a/73059220/1867759
  desc 'generates a migration file with a timestamp and name'
  task :generate_migration, [:name, :migrations_dir] do |_, args|
    args.with_defaults(name: 'migration', migrations_dir: 'db/migrations')

    migration_template = <<~MIGRATION
      Sequel.migration do
        up do
        end

        down do
        end
      end
    MIGRATION

    file_name = "#{Time.now.strftime('%Y%m%d%H%M%S')}_#{args.name}.rb"
    FileUtils.mkdir_p(args.migrations_dir)

    File.write(File.join(args.migrations_dir, file_name), migration_template)
  end

  desc 'runs migrations'
  task :migrate, :path_to_migrations do |_, args|
    args.with_defaults(path_to_migrations: 'db/migrations')
    db = Sequel.connect ENV.fetch('DATABASE_CONNECTION_STRING', 'sqlite://db.sqlite3')
    Sequel.extension :migration
    Sequel::Migrator.run(db, args.path_to_migrations)
  end

  desc 'runs rollback for ALL migrations'
  task :hard_rollback, [:path_to_migrations] do |_, args|
    args.with_defaults(path_to_migrations: 'db/migrations')
    db = Sequel.connect ENV.fetch('DATABASE_CONNECTION_STRING', 'sqlite://db.sqlite3')
    Sequel.extension :migration
    Sequel::Migrator.run(db, args.path_to_migrations, target: 0)
  end
end
