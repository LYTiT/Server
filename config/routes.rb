LytitServer::Application.routes.draw do
  resources :tests

  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  namespace :api, :defaults => {:format => 'json'}  do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
      end

      post '/register_push_token' => 'users#register_push_token'
      post '/change_password' => 'users#change_password'
      post '/toggle_group_notification/:group_id' => 'users#toggle_group_notification'
      post '/forgot_password' => 'users#forgot_password'

      resources :sessions, only: :create
      resources :venues, only: [:index, :show] do
        #resources :venue_ratings, only: [:create]
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
        collection do
          get 'search'
        end
        post 'vote'
      end

      controller :lytit_bar do
        get '/bar/position', :action => 'position'
      end

      post '/venues/rate_venue' => 'venues#rate_venue'

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
        delete '/venues/delete_comment', :action => :delete_comment
      end
      post '/venues/report_comment/:comment_id' => 'venues#report_comment'
      get '/group_venue_details/:id' => 'groups#group_venue_details'
    end
  end

  get 'reported_comments' => 'venues#reported_comments'

  controller :system, :defaults => {:format => 'json'}  do
    get 'system/status', :action => 'status', :as => :system_status
  end

  resource :session, controller: 'sessions', only: [:destroy, :new, :create]

  get 'session', to: redirect('/sign_in')
  get 'sign_out' => 'sessions#destroy', :as => nil 
  get 'sign_in' => 'sessions#new', :as => nil 
  
  resources :venues, only: [:show] do
    
  end

  root :to => 'sessions#new'


end
