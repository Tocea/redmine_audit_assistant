# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'import-requirements', :to => 'import#index'
post 'import-requirements', :to => 'import#import'

get 'progress-report', :to => 'progress_report#index'
post 'progress-report', :to => 'progress_report#generate'
