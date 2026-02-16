namespace :db do
  desc "Setup database for deployment"
  task deploy_setup: :environment do
    Rake::Task['db:schema:load'].invoke
    Rake::Task['db:seed'].invoke
    
    # Verify tables were created
    tables = ActiveRecord::Base.connection.tables
    puts "✓ Database ready with #{tables.count} tables: #{tables.join(', ')}"
  end
end
