# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'import-requirements', :to => 'import#index'
post 'import-requirements', :to => 'import#import'

get 'progress-report', :to => 'progress_report#index'
post 'progress-report', :to => 'progress_report#generate'

get 'issues-status-actions', :to => 'issues_custom_actions#settings'
post 'issues-status-actions', :to => 'issues_custom_actions#insert'
get 'issues-status-actions-delete', :to => 'issues_custom_actions#delete'
get 'issues-status-actions-run', :to => 'issues_custom_actions#run'
