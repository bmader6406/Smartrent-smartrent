Smartrent::Engine.routes.draw do

  resources :articles


 # devise_for :users, class_name: "Smartrent::User", module: :devise, mounted: true#,  :controllers => { :registrations => "devise/registrations" }, :skip => [:sessions]



  devise_for :users, {
                       class_name:		'Smartrent::User',
                       module: :devise,
  :controllers => { :sessions => "smartrent/sessions" }
                   }
   # devise_for :residents, class_name: "Smartrent::Resident", mounted: true


  # devise_for :residents, class_name: "Smartrent::Resident", :path => '', path_names: {sign_in: "login", sign_out: "logout"},
  #            controllers: {omniauth_callbacks: "authentications", registrations: "registrations"}

  # resource :users

  root :to => "articles#index"

end
