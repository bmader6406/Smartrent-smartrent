Smartrent::Engine.routes.draw do

  resources :apartments


  resources :properties


  resources :articles


 # devise_for :users, class_name: "Smartrent::User", module: :devise, mounted: true#,  :controllers => { :registrations => "devise/registrations" }, :skip => [:sessions]



   # devise_for :residents, class_name: "Smartrent::Resident", mounted: true


  # devise_for :residents, class_name: "Smartrent::Resident", :path => '', path_names: {sign_in: "login", sign_out: "logout"},
  #            controllers: {omniauth_callbacks: "authentications", registrations: "registrations"}

  # resource :users

  resource :contacts

  root :to => "pages#home"
  get "/faq", :to => "pages#faq", :as => "faq"
  get "/find-a-smartrent-apartment", :to => "apartments#index", :as => "find_apartments"
  post "/find-a-smartrent-apartment", :to => "apartments#index"
  get "/find-a-new-home", :to => "properties#index", :as => "new_home"
  post "/find-a-new-home", :to => "properties#index"
  get "/smartrent-quick-program-rules", :to => "pages#program_rules", :as => "program_rules"
  get "/official-rules", :to => "pages#official_rules", :as => "official_rules"
  get "/privacy-policy", :to => "pages#privacy_policy", :as => "privacy_policy"
  get "/website-disclaimer", :to => "pages#website_disclaimer", :as => "website_disclaimer"
  get "/contact", :to => "contacts#new", :as => "new_contact"
  post "/contact", :to => "contacts#create", :as => "submit_contact"
  get "/460-new-york-avenue", :to => "pages#ny_avenue", :as => "ny_avenue"
  get "/member-profile", :to => "users#profile", :as => "member_profile"
  get "/member-statement", :to => "users#statement", :as => "member_statement"
  devise_for :users, {
                       class_name: 'Smartrent::User',
                       module: :devise,
  :controllers => { :sessions => "smartrent/sessions" }
                   }


end
