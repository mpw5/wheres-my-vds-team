namespace :db do
  desc "Setup database for deployment"
  task deploy_setup: :environment do
    puts "RAILS_ENV: #{Rails.env}"
    puts "Database config: #{ActiveRecord::Base.connection_db_config.configuration_hash}"
    
    Rake::Task['db:prepare'].invoke
    Rake::Task['db:seed'].invoke

    # Verify tables were created
    tables = ActiveRecord::Base.connection.tables
    puts "✓ Database ready with #{tables.count} tables: #{tables.join(', ')}"
  end
end
