# create group and user

group 'mercury'

user 'mercury' do
  comment                    'executes programs'
  name 'mercury'
  group 'mercury'
end

# create directories
directory '/opt/mercury' do
  owner 'mercury'
  group 'mercury'
  mode '0755'
  action :create
end

directory '/opt/mercury/env/' do
  owner 'mercury'
  group 'mercury'
  mode '0755'
  action :create
end



