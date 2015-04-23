
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
        get 'following'
        get 'followers'
        get 'is_following_user'
        get 'vfollowing'
        get 'is_following_venue'
        get 'get_feed'
        get 'get_lumens'
        get 'get_daily_lumens'
        post 'posting_kill_request'
        get 'get_lumen_notification_details'
        get 'get_followers_for_invite'
        get 'get_following_for_invite'
        get 'get_linkable_groups'
        get 'is_member'
        get 'get_bounties'
        post 'can_claim_bounties'
        get 'get_recommended_users'
        collection do
          get 'search'
        end
        get 'get_list_of_places_mapped'
        get 'get_venue_comments_from_venue'
        get 'get_a_users_profile'
        get 'get_surrounding_feed'
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
      end

      resources :announcement do
        get 'get_announcement_details'
      end

      resources :lumen_game_winners do
        post 'update_winner_paypal_info'
      end

      resources :relationships do
        post 'create'
        delete 'destroy'
        post 'v_create'
        delete 'v_destroy'
        get 'get_follower'
      end

      resources :bounties do
        get 'create'
        get 'get_claims'
        post 'viewed_claim'
        get 'get_pricing_constants'
        get 'get_bounty_claim_notification_details'
        get 'get_bounty_claim_acceptance_notification_details'
        get 'get_bounty_claim_rejection_notification_details'
        post 'accept_bounty_claim'
        post 'reject_bounty_claim'
        post 'subscribe_to_bounty'
        post 'update_bounty_details'
        post 'remove_bounty'
      end

      resources :group_invitations do
        get 'get_group_invite_notification_details'
        get 'validate_invitation'
        post 'destroy'
      end

      resources :at_group_relationships do
        get 'get_at_group_notification_details'
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

        collection do 
          get 'get_recommendations'
        end

        collection do 
          get 'search_to_follow'
        end

        collection do 
          get 'get_geo_spotlyt'
        end

        get 'get_bounties'
        post 'vote'
      end

      controller :lytit_bar do
        get '/bar/position', :action => 'position'
      end

      #why does this route appear in the middle of nowhere?
      #why is it not under a controller or a resources tag?
      post '/venues/rate_venue' => 'venues#rate_venue'

      resources :groups, only: [:create] do
        post 'join', :action => :join
        delete 'leave', :action => :leave
        post 'toggle_admin', :action => :toggle_admin
        post 'update'
        delete 'remove_user'
        get 'users'
        get 'venues'
        post 'delete'
        post 'report'
        get 'group_venue_details'
        post 'invite_users'
        get 'get_groupfeed'
        get 'get_group_details'
        collection do
          get 'search'
        end
        collection do
          get 'get_popular_groups'
        end
        get 'get_past_events'
        get 'get_upcoming_events'
        get 'get_all_events'
        post 'add_venues/:venue_id', :action => :add_venue, :as => :add_venue
        delete 'add_venues/:venue_id', :action => :remove_venue, :as => :remove_venue
        post 'add_cover'
        get 'get_hashtag_notification_details'
        get 'name_availability'
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

  get 'about-us' => 'pages#about_us'
  get 'about' => 'pages#about_us'
  get 'terms-and-conditions' => 'pages#tnc'
  get 'privacy' => 'pages#privacy'
  
  root :to => 'pages#home'

end
