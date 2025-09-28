Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  #devise_for :users
  devise_for :users, :controllers => {
   :sessions      => "users/sessions",
   :registrations => "users/registrations",
  }
  
  resources :users
  post 'users/add' => 'users#add'
  resources :m_customs
  resources :m_combo_bigs
  resources :m_combos
  resources :m_cars
  resources :m_routes
  resources :t_carruns
  resources :t_carrun_lists
  resources :admins
  resources :gyoshas
  resources :m_mail_settings
  resources :t_change_shinseis
  resources :t_change_shinsei_admins
  resources :t_carrun_summarys
  resources :m_drivers
  resources :unloads
  resources :infomations

  get 'm_route_points' => 'm_route_points#index'
  post 'm_route_points' => 'm_route_points#ajax'
  get 'm_route_points/:id' => 'm_route_points#show'
  get 'm_route_areas' => 'm_route_areas#index'
  post 'm_route_areas' => 'm_route_areas#edit'
  delete 'm_route_areas/:id' => 'm_route_areas#destroy'
  get 'm_route_recommends' => 'm_route_recommends#index'
  post 'm_route_recommends' => 'm_route_recommends#edit'
  delete 'm_route_recommends/:id' => 'm_route_recommends#destroy'
  get 'm_route_roads' => 'm_route_roads#index'
  get 'general' => 'general#index'
  post 'general' => 'general#ajax'
  #get 't_carrun_lists' => 't_carrun_lists#index'
  #post 't_carrun_lists' => 't_carrun_lists#ajax'
  #get 't_carrun_lists/:id' => 't_carrun_lists#show'
  #delete 't_carrun_lists/:id' => 't_carrun_lists#destroy'
  get 't_collect_lists' => 't_collect_lists#index'
  post 't_collect_lists' => 't_collect_lists#ajax'
  get 't_collect_lists/:id' => 't_collect_lists#show'
  get 'm_custom_add' => 'm_custom_add#index'
  post 'm_custom_add' => 'm_custom_add#ajax'
  get 'unload_add' => 'unload_add#index'
  post 'unload_add' => 'unload_add#ajax'
  get 'm_custom_mail' => 'm_custom_mail#index'
  post 'm_custom_mail' => 'm_custom_mail#mail'
  get 'm_custom_mail/:id' => 'm_custom_mail#show'
  get 'm_custom_csv' => 'm_custom_csv#index'
  post 'm_custom_csv' => 'm_custom_csv#csv'
  get 'admin_move' => 'admin_move#index'
  post 'admin_move' => 'admin_move#move'
  get 'admin_excel' => 'admin_excel#index'
  post 'admin_excel' => 'admin_excel#excel'
  get 'm_custom_excel' => 'm_custom_excel#index'
  post 'm_custom_excel' => 'm_custom_excel#excel'
  post 't_change_confirms' => 't_change_confirms#confirm'
  post 't_change_confirm_admins' => 't_change_confirm_admins#confirm'
  get 'search_maps' => 'search_maps#index'
  get 'search_maps/:id' => 'search_maps#show', :as => :search_map
  post 'search_maps' => 'search_maps#ajax'
  get 'output_maps' => 'output_maps#index'
  post 'output_maps' => 'output_maps#output'
  get 't_log_hists' => 't_log_hists#index'
  get 'collect_uncomp' => 'collect_uncomp#index'
  post 'collect_uncomp' => 'collect_uncomp#excel'
  get 'uncollect' => 'uncollect#index'
  get 'uncollect/:id' => 'uncollect#show'
  post 'uncollect' => 'uncollect#excel'
  delete 'uncollect/:id' => 'uncollect#destroy'
  get 'zenrin_map' => 'zenrin_map#index'
  post 'zenrin_map' => 'zenrin_map#ajax'
  get 't_custom_memos' => 't_custom_memos#index'
  post 't_custom_memos' => 't_custom_memos#create'
  get 't_custom_carruns' => 't_custom_carruns#index'
  get 't_fee_gasses' => 't_fee_gasses#index'
  post 't_fee_gasses' => 't_fee_gasses#create'
  get 't_operations' => 't_operations#index'
  post 't_operations' => 't_operations#create'
  
  get 'ippan_unpan_report001' => 'ippan_unpan_report001#index'
  post 'ippan_unpan_report001' => 'ippan_unpan_report001#excel'
  get 'nippo_report001' => 'nippo_report001#index'
  post 'nippo_report001' => 'nippo_report001#excel'
  get 'nippo_report002' => 'nippo_report002#index'
  post 'nippo_report002' => 'nippo_report002#excel'
  get 'm_custom_excel001' => 'm_custom_excel001#index'
  post 'm_custom_excel001' => 'm_custom_excel001#excel'

  post "mpc" => "mpc#index"
  post "picture" => "pictures#index"

  get 'mpc/users' => 'mpc#users'     # search users
  get 'mpc/mcars' => 'mpc#mcars'
  get 'mpc/mdrivers' => 'mpc#mdrivers'
  get 'mpc/mroutes/:car_code' => 'mpc#mroutes'
  get 'mpc/mcustoms' => 'mpc#mcustoms'
  get 'mpc/mcombobigs' => 'mpc#mcombobigs'
  get 'mpc/mcombos' => 'mpc#mcombos'
  get 'mpc/mitakus' => 'mpc#mitakus'
  get 'mpc/unloads' => 'mpc#unloads'

  get 'mpc/mroutepoints/:route_code' => 'mpc#mroutepoints'
  get 'mpc/mrouterundates/:route_code' => 'mpc#mrouterundates'

  get 'mpc/route_areas/:route_code' => 'mpc#route_areas', format:'json'  # get search route_areas
  get 'mpc/route_recommends/:route_code' => 'mpc#route_recommends', format:'json'  # get search route_recommends

  get 'mpc/tcarruns/:date/:route_code' => 'mpc#tcarruns'
  get 'mpc/tcollectlists/:date/:car_code/:route_code' => 'mpc#tcollectlists'

  get 'mpc/t_car_messages/:car_id' => 'mpc#t_car_messages', format:'json'  # get search t_car_messages
  put 'mpc/t_car_messages/:id' => 'mpc#update_t_car_message', format:'json' # update t_car_message

  get 'manual' => 'manual#index'

  get 'converts' => 'converts#index'
  post 'converts' => 'converts#csv'
  get 'home' => 'home#index'
  post 'ajax2' => 'home#ajax2'

  #root :to => "search_maps#index"
  root :to => "search_maps#index"

  get "home/test" => "home#test"
end
