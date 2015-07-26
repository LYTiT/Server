
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
          post 'mark_as_responded_to'
        end
        post 'set_version'
        get 'get_lumens'
        get 'get_daily_lumens'
        post 'posting_kill_request'
        get 'get_lumen_notification_details'
        collection do
          get 'search'
        end
        get 'get_map_details'
        get 'confirm_email'
        get 'get_venue_comment'
        get 'username_availability'
        post 'register'
        post 'destroy_previous_temp_user'
        get 'validate_coupon_code'
        get 'email_availability'
        get 'is_user_confirmed'
        get 'get_comments_by_time'
        get 'get_comments_by_venue'
        get 'get_user_feeds'
        post 'add_instagram_auth_token'
        post 'update_instagram_permission'
        post 'check_instagram_token_expiration'
        post 'remove_instagram_authentication'
      end

      resources :feeds, only: [:create] do
        post 'delete'
        post 'edit_feed'
        post 'add_venue'
        post 'remove_venue'
        get 'get_venues'
        post 'add_raw_venue'
        post 'register_open'
        collection do
          get 'search'
        end
        post 'add_feed'
        post 'leave_feed'
      end

      resources :announcement do
        get 'get_announcement_details'
      end

      post '/register_push_token' => 'users#register_push_token'
      post '/register_gcm_token' => 'users#register_gcm_token'
      post '/change_password' => 'users#change_password'
      post '/toggle_group_notification/:group_id' => 'users#toggle_group_notification'
      post '/forgot_password' => 'users#forgot_password'

      resources :sessions, only: :create
      resources :venues, only: [:index, :show] do
        #resources :venue_ratings, only: [:create]
        #get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
        post '/posts/:post_id/mark_as_viewed', :action => :mark_comment_as_viewed

        collection do
          get 'refresh_map_view'
        end 
        collection do
          get 'search'
        end
        collection do
          get 'get_suggested_venues'
        end
        post 'vote'
        collection do
          get 'meta_search'
        end
        collection do
          get 'get_trending_venues'
        end
        collection do
          get 'get_trending_venues_details'
        end
        collection do
          get 'get_comments'
        end
        get 'get_comments_of_a_venue'
        get 'get_contexts'       
      end

      controller :lytit_bar do
        get '/bar/position', :action => 'position'
      end

      #why does this route appear in the middle of nowhere?
      #why is it not under a controller or a resources tag?
      post '/venues/rate_venue' => 'venues#rate_venue'

      #we don't need to put an end here because there is no "do" we 
      #put end on "do"
      resources :events, only: [:index, :create, :show]

      controller :venues, :defaults => {:format => 'json'} do
        post '/venues/addComment', :action => :add_comment
        delete '/venues/delete_comment', :action => :delete_comment
      end

      #are the next three post get post under the "resources :events"
      post '/venues/report_comment/:comment_id' => 'venues#report_comment'
      #get '/group_venue_details/:id' => 'groups#group_venue_details'
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
    #put 'confirm_account/:token' => 'users#confirm_account', as: 'venue_manager_confirm_account'
    get 'validate_email/:token' => 'users#validate_email', as: 'validate_email'
    resource :password, controller: 'passwords', only: [:create, :edit, :update]
  end

  get 'tnc' => 'pages#tnc'
  get 'privacy' => 'pages#privacy'


  root :to => 'pages#home'

end
