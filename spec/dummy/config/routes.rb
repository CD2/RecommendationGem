Rails.application.routes.draw do
  mount Recommendation::Engine => "/recommendation"
  get '/', to: 'pages#root'
  get '/:model/', to: 'pages#index'
  get '/:model/:id', to: 'pages#show'
  post '/:model/:id/recalculate', to: 'pages#recalculate'
end
