#
# Cookbook Name:: kibana
# Recipe:: nginx
#
# Copyright 2013, John E. Vincent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ruby_block "add users to passwords file" do
  block do
    require 'webrick/httpauth/htpasswd'
    @htpasswd = WEBrick::HTTPAuth::Htpasswd.new(node[:kibana][:nginx][:passwords_file])

    node[:kibana][:nginx][:users].each do |u|
      Chef::Log.debug "Adding user '#{u['username']}' to #{node[:kibana][:nginx][:passwords_file]}\n"
      @htpasswd.set_passwd( 'Kibana', u['username'], u['password'] )
    end

    @htpasswd.flush
  end

  not_if { node[:kibana][:nginx][:users].empty? }
end

if node['kibana']['user'].empty?
  unless node['kibana']['webserver'].empty?
    webserver = node['kibana']['webserver']
    kibana_user = node[webserver]['user']
  else
    kibana_user = "nobody"
  end
else
  kibana_user = node['kibana']['user']
end

# Ensure proper permissions and existence of the passwords file
#
file node[:kibana][:nginx][:passwords_file] do
  owner kibana_user and mode 0755
  action :touch
end

node.set['nginx']['default_site_enabled'] = node['kibana']['nginx']['enable_default_site']

include_recipe "nginx"

template "/etc/nginx/sites-available/kibana" do
  source node['kibana']['nginx']['template']
  cookbook node['kibana']['nginx']['template_cookbook']
  notifies :reload, "service[nginx]"
  variables(
    :es_server => node['kibana']['es_server'],
    :es_port   => node['kibana']['es_port'],
    :server_name => node['kibana']['webserver_hostname'],
    :server_aliases => node['kibana']['webserver_aliases'],
    :kibana_dir => node['kibana']['installdir'],
    :listen_address => node['kibana']['webserver_listen'],
    :listen_port => node['kibana']['webserver_port']
  )
end

nginx_site "kibana"
