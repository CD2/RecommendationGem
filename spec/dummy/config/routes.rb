Rails.application.routes.draw do
  mount Recommendation::Engine => "/recommendation"
end
