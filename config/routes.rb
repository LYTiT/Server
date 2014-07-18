#What is the difference between resource/ resources/ and controller?
#do they all do the same thing?

LytitServer::Application.routes.draw do

  resources :tests

  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  namespace :api, :defaults => {:format => 'json'}  do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        get '/posts', :action => :get_comments
        get '/groups', :action => :get_groups
      end

      #why are these not undera resources tag?
      post '/register_push_token' => 'users#register_push_token'
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


      #post/delete/get are all determined in the methods defined in LTServer.m
      #for example postJson would translate to post request.
      #delete in LTServer translates to delete
      #getJsonArray LT Server translates to get request

      #as an aside I don't think you're supposed to use resources 
      #to do routing for things that are NOT actually resources
      #NOT a resource: events, groups,
      #DEFINIETELY a resource: photos

      #user resource or contoller?
      resources :accesscodes, only:[] do
       get '/accesscode/:access_code/kvalue', to: 'accesscode#get_accesscode_from_table'
      end


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

  resources :venues, only: [:show, :update]

  resources :users, only: [] do 
    get 'confirm_account/:token' => 'users#set_password', as: 'venue_manager_set_password'
    put 'confirm_account/:token' => 'users#confirm_account', as: 'venue_manager_confirm_account'
  end

  get 'about-us' => 'pages#about_us'
  get 'terms-and-conditions' => 'pages#tnc'
  
  root :to => 'sessions#new'


end
