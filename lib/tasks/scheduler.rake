desc "This task awards the residents which are active and have still rented the property"
task :monthly_awards => :environment do
  Smartrent::Resident.monthly_awards_job
end
