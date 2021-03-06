ActionController::Routing::Routes.draw do |map|
  map.resources :users

  map.resource :session

  map.resources :exams

  map.resources :books

  map.resources :lists

  map.resources :bookmarks

  map.resources :selections
  map.resources :questions
  map.resource :session
  map.resource :error
  map.resources :top


  # Named Root設定
  # (Controller上から、login_path, new_session_pathのように参照できる)
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.index '/', :controller => 'top', :action => 'index'
  map.send_mail '/send_mail', :controller => 'users', :action => 'send_mail'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'
  map.activate_all '/activate_all/', :controller => 'users', :action => 'activate_all'
  map.edit '/edit', :controller => 'users', :action => 'edit'
  map.secession '/secession', :controller => 'users', :action => 'secession'


  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect 'quiz/:question_id', :controller => 'qa', :action => 'quiz'

end
