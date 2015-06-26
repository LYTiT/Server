
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
        get 'get_bounties'
        post 'can_claim_bounties'
        collection do
          get 'search'
        end
        get 'get_bounty_feed'
        get 'get_surrounding_bounties'
        get 'get_map_details'
        get 'confirm_email'
        get 'get_bounty_claims'
        get 'get_venue_comment'
        get 'username_availability'
        post 'register'
        post 'destroy_previous_temp_user'
        get 'validate_coupon_code'
        get 'email_availability'
        get 'is_user_confirmed'
        get 'get_surprise_image'
        get 'search_for_bounties'
        get 'get_comments_by_time'
        get 'get_comments_by_venue'
        get 'get_feeds'
      end

      resources :feed, only: [:create] do
        post 'delete'
        post 'edit_name'
        post 'add_venue'
        post 'remove_venue'
        get 'get_comments' 
      end

      resources :announcement do
        get 'get_announcement_details'
      end

      resources :lumen_game_winners do
        post 'update_winner_paypal_info'
      end

      resources :bounties do
        get 'create'
        get 'get_claims'
        post 'viewed_claim'
        get 'get_pricing_constants'
        get 'get_bounty_claim_notification_details'
        get 'get_bounty_claim_accept_notification_details'
        get 'get_bounty_claim_rejection_notification_details'
        post 'accept_bounty_claim'
        post 'reject_bounty_claim'
        post 'subscribe_to_bounty'
        post 'update_bounty_details'
        post 'remove_bounty'
        post 'unsubscribe_from_bounty'
        get 'get_claims_for_global_feed'
        get 'get_response_index'
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
          get 'refresh_map_view'
        end 
        collection do
          get 'search'
        end
        collection do
          get 'get_suggested_venues'
        end
        get 'get_bounties'
        post 'vote'
        get 'get_area_bounty_feed'
        collection do
          get 'meta_search'
        end
        collection do
          get 'get_trending_venues'
        end
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
