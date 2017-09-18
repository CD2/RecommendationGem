# frozen_string_literal: true

Rails.application.routes.draw do
  mount Recommendation::Engine => "/recommendation"
  root 'application#root'
end
