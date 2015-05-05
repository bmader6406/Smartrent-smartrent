Smartrent::Engine.routes.draw do

  resources :homes do
    collection do
      get "import", :to => "homes#import_page"
      post "import", :to => "homes#import"
    end
  end


  resources :floor_plan_images do
    collection do
      get "import", :to => "floor_plan_images#import_page"
      post "import", :to => "floor_plan_images#import"
    end
  end


  resources :apartments


  resources :properties do
    collection do
      get "import", :to => "properties#import_page"
      post "import", :to => "properties#import"
    end
  end

  resource :residents do
    collection do
      get "change_password"
      put "update_password"
    end
  end


  root :to => "pages#home"
  get "/faq", :to => "pages#faq", :as => "faq"
  get "/find-a-smartrent-apartment", :to => "apartments#index", :as => "find_apartments"
  post "/find-a-smartrent-apartment", :to => "apartments#index"
  get "/find-a-new-home", :to => "properties#index", :as => "find_a_new_home"
  get "/smartrent-quick-program-rules", :to => "pages#program_rules", :as => "program_rules"
  get "/official-rules", :to => "pages#official_rules", :as => "official_rules"
  get "/privacy-policy", :to => "pages#privacy_policy", :as => "privacy_policy"
  get "/website-disclaimer", :to => "pages#website_disclaimer", :as => "website_disclaimer"
  get "/contact", :to => "contacts#new", :as => "new_contact"
  post "/contact", :to => "contacts#create", :as => "submit_contact"
  get "/460-new-york-avenue", :to => "pages#ny_avenue", :as => "ny_avenue"
  get "/member-profile", :to => "residents#profile", :as => "member_profile"
  get "/member-statement", :to => "residents#statement", :as => "member_statement"
  devise_for :users, {
                       class_name: 'Smartrent::User',
                       module: :devise,
  :controllers => { :sessions => "smartrent/sessions" }
                   }
  devise_for :residents, {
                       class_name: 'Smartrent::Resident',
                       module: :devise,
  :controllers => { :sessions => "smartrent/sessions" }
                   }

  namespace :admin do
    root :to => "residents#index"
    resources :residents do
      collection do
        get "archive/:id", :to => "residents#archive", :as => "archive"
        get "send-password-reset-information/:id", :to => "residents#send_password_reset_information", :as => "send_password_reset_information"
      end
    end
  end


end
