LytitServer::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  namespace :api, :defaults => {:format => 'json'}  do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
      end

      post '/register_push_token' => 'users#register_push_token'

      resources :sessions, only: :create
      resources :venues, only: [:index, :show] do
        resources :venue_ratings, only: [:create]
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
        collection do
          get 'search'
        end
      end
      resources :groups, only: [:create, :update] do
        post 'join', :action => :join
        delete 'leave', :action => :leave
        post 'toggle_admin', :action => :toggle_admin
        delete 'remove_user'
        get 'users'
        get 'venues'
        post 'delete'
        collection do
          get 'search'
        end
        post 'add_venues/:venue_id', :action => :add_venue, :as => :add_venue
        delete 'add_venues/:venue_id', :action => :remove_venue, :as => :remove_venue
      end

      resources :events, only: [:index, :create, :show]
      controller :venues, :defaults => {:format => 'json'} do
        post '/venues/addComment', :action => :add_comment
      end
    end
  end

  controller :system, :defaults => {:format => 'json'}  do
    get 'system/status', :action => 'status', :as => :system_status
  end

  #TODO will change this later if got any thing to show on home page!
  root :to => 'system#status'
end
