default['kibana']['nginx']['template'] = 'kibana-nginx.conf.erb'
default['kibana']['nginx']['template_cookbook'] = 'kibana'
default['kibana']['nginx']['enable_default_site'] = false


# Try to load data bag item 'kibana/users' ------------------
#
users = Chef::DataBagItem.load('kibana', 'users')[node.chef_environment]['users'] rescue []

default[:kibana][:nginx][:users]          = users
default[:kibana][:nginx][:passwords_file] = "#{node['kibana']['installdir']}/passwords"
  