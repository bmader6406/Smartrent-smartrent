Smartrent::Engine.routes.draw do
  
  # website content management
  namespace :admin do
    root :to => "properties#index"
    
    resources :properties do
      collection do
        get "import", :to => "properties#import_page"
        post "import"
      end
    end
    
    resources :features do
      collection do
        get "import", :to => "features#import_page"
        post "import"
      end
    end
    resources :property_features do
      collection do
        get "import", :to => "property_features#import_page"
        post "import"
      end
    end
    
    resources :homes do
      collection do
        get "import", :to => "homes#import_page"
        post "import"
      end
    end
    
    resources :more_homes do
      collection do
        get "import", :to => "more_homes#import_page"
        post "import"
      end
    end
    
    resources :floor_plans do
      collection do
        get "import", :to => "floor_plans#import_page"
        post "import"
      end
    end
    
    resources :floor_plan_images do
      collection do
        get "import", :to => "floor_plan_images#import_page"
        post "import"
      end
    end
    
    resources :rewards do
      collection do
        get "import", :to => "rewards#import_page"
        post "import"
      end
    end
    
    resources :settings
  end
  
  # smartrent website
  resources :homes
  resources :properties
  
  devise_for :residents, {
     class_name: 'Smartrent::Resident',
     module: :devise,
     :controllers => { :sessions => "smartrent/sessions" },
     :path_names => {
    #sign_in: 'member-login'
     }
   }
    devise_scope :resident do
      get "/member-login" => "sessions#new", :as => :new_member_login
      post "/member-login" => "sessions#create", :as => :member_login
      get '/reset-password', to: 'devise/passwords#new', as: 'new_member_password'
      get '/password/change', to: 'devise/passwords#edit', as: 'edit_member_password'
      put  '/reset-password', to: 'devise/passwords#update', as: 'member_password'
      post '/reset-password', to: 'devise/passwords#create'
      #get "/reset-password"   => 'devise/passwords#new', :as => :forgot_password
      get "/activation"   => 'devise/confirmations#new', :as => "new_member_confirmation"
      post "/activation"   => 'devise/confirmations#create', :as => "member_confirmation"
    end
   
  resource :residents do
    collection do
      get "change_password"
      put "update_password"
      patch "update_password"
    end
  end

  get "/faq", :to => "pages#faq", :as => "faq"
  get "/find-a-smartrent-apartment", :to => "properties#index", :as => "find_apartments"
  get "/find-a-new-home", :to => "homes#index", :as => "find_a_new_home"
  get "/smartrent-quick-program-rules", :to => "pages#program_rules", :as => "program_rules"
  get "/official-rules", :to => "pages#official_rules", :as => "official_rules"
  get "/privacy-policy", :to => "pages#privacy_policy", :as => "privacy_policy"
  get "/website-disclaimer", :to => "pages#website_disclaimer", :as => "website_disclaimer"
  get "/contact", :to => "contacts#new", :as => "new_contact"
  post "/contact", :to => "contacts#create", :as => "submit_contact"
  get "/460-new-york-avenue", :to => "pages#ny_avenue", :as => "ny_avenue"
  get "/member-profile", :to => "residents#profile", :as => "member_profile"
  get "/member-statement", :to => "residents#statement", :as => "member_statement"
  
  root :to => "pages#home"
end
