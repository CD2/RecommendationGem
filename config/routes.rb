# frozen_string_literal: true

Recommendation::Engine.routes.draw do
  root 'pages#root'
  get '/:model/', to: 'pages#index'
  get '/:model/:id', to: 'pages#show'
  post '/:model/:id/recalculate', to: 'pages#recalculate'
  post '/:model/:id/bounce', to: 'pages#show_bounce'
  post '/:model/bounce', to: 'pages#index_bounce'
end
