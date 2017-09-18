module Smartrent
  class Engine < ::Rails::Engine
    isolate_namespace Smartrent
    
    initializer :assets do |config|
      Rails.application.config.assets.precompile += %w( smartrent/application.js smartrent/application.css smartrent/admin.js smartrent/admin.css smartrent/_footer.css )
    end
    
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
    
  end
end
