Rails.application.routes.draw do
  get 'admin_companies/index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :admin_companies
  root 'admin_companies#index'
end