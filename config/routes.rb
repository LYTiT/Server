
LytitServer::Application.routes.draw do


  resources :tests

  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  namespace :api, :defaults => {:format => 'json'}  do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
        resources :notifications, only: [:index, :destroy] do
          post 'mark_as_read'
        end
        get 'following'
        get 'followers'
        get 'is_following_user'
        get 'vfollowing'
        get 'is_following_venue'
        get 'get_feed'
        get 'get_lumens'
        get 'get_daily_lumens'
        post 'posting_kill_request'
      end

      resources :featured do
        get '/today', :action => :today
        get '/allTime', :action => :allTime
        get '/profile_comments', :action => :profile_comments
        get '/allUsers', :action => :allUsers
        collection do
          get 'search'
        end
      end

      resources :relationships do
        post 'create'
        delete 'destroy'
        post 'v_create'
        delete 'v_destroy'
      end

      resources :accesscodes, only: [:show] do #accesscodes call to show made here
      end

      post '/register_push_token' => 'users#register_push_token'
      post '/register_gcm_token' => 'users#register_gcm_token'
      post '/change_password' => 'users#change_password'
      post '/toggle_group_notification/:group_id' => 'users#toggle_group_notification'
      post '/forgot_password' => 'users#forgot_password'

      resources :sessions, only: :create
      resources :venues, only: [:index, :show] do
        #resources :venue_ratings, only: [:create]
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
        post '/posts/:post_id/mark_as_viewed', :action => :mark_comment_as_viewed

        

        collection do
          get 'search'
        end
        collection do
          get 'get_suggested_venues'
        end
        collection do 
          get 'get_recommendations'
        end
        post 'vote'
      end

      controller :lytit_bar do
        get '/bar/position', :action => 'position'
      end

      #why does this route appear in the middle of nowhere?
      #why is it not under a controller or a resources tag?
      post '/venues/rate_venue' => 'venues#rate_venue'

      resources :groups, only: [:create, :update] do
        post 'join', :action => :join
        delete 'leave', :action => :leave
        post 'toggle_admin', :action => :toggle_admin
        delete 'remove_user'
        get 'users'
        get 'venues'
        post 'delete'
        post 'report'
        collection do
          get 'search'
        end
        post 'add_venues/:venue_id', :action => :add_venue, :as => :add_venue
        delete 'add_venues/:venue_id', :action => :remove_venue, :as => :remove_venue
      end

      #we don't need to put an end here because there is no "do" we 
      #put end on "do"
      resources :events, only: [:index, :create, :show]

      controller :venues, :defaults => {:format => 'json'} do
        post '/venues/addComment', :action => :add_comment
        delete '/venues/delete_comment', :action => :delete_comment
      end

      #are the next three post get post under the "resources :events"
      post '/venues/report_comment/:comment_id' => 'venues#report_comment'
      get '/group_venue_details/:id' => 'groups#group_venue_details'
      post '/report_event/:event_id' => 'events#report'
    end
  end

  get 'reported_comments' => 'venues#reported_comments'

  controller :system, :defaults => {:format => 'json'}  do
    get 'system/status', :action => 'status', :as => :system_status
  end

  resource :session, controller: 'sessions', only: [:destroy, :new, :create]
  resources :passwords, controller: 'passwords', only: [:create, :new, :update]

  get 'session', to: redirect('/sign_in')
  get 'sign_out' => 'sessions#destroy', :as => nil
  get 'sign_in' => 'sessions#new', :as => nil

  resources :venues, only: [:show, :update]

  resources :users, only: [] do 
    get 'confirm_account/:token' => 'users#set_password', as: 'venue_manager_set_password'
    put 'confirm_account/:token' => 'users#confirm_account', as: 'venue_manager_confirm_account'
    resource :password, controller: 'passwords', only: [:create, :edit, :update]
  end

  get 'about-us' => 'pages#about_us'
  get 'about' => 'pages#about_us'
  get 'terms-and-conditions' => 'pages#tnc'
  get 'privacy' => 'pages#privacy'
  
  root :to => 'pages#home'

end
