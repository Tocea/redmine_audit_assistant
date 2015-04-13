# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'audit', :to => 'audit#index'
post 'audit', :to => 'audit#create'

get 'import-requirements', :to => 'import#index'
post 'import-requirements', :to => 'import#import'
