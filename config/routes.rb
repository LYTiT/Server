LytitServer::Application.routes.draw do
  namespace :api, :defaults => {:format => 'json'}  do
    namespace :v1 do
      resources :users, only: :create
    end
  end

  controller :system, :defaults => {:format => 'json'}  do
    get 'system/status', :action => 'status', :as => :system_status
  end

  #TODO will change this later if got any thing to show on home page!
  root :to => 'system#status'
end
