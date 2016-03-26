include_recipe 'build-essential'

%w(gcc libxml2 libxml2-devel libxslt libxslt-devel libffi-devel openssl-devel zlib-devel zlib).each do |lib|
  package lib do
    action :install
  end
end

include_recipe 'python'
include_recipe 'supervisor'

include_recipe 'mercury-crawler::default'

app = nil

search("aws_opsworks_app").each do |result|
  if result['shortname'] != node['mercury-crawler']['app_name']
    Chef::Log.info("Skipping application #{result['shortname']} as it is not the app #{node['mercury-crawler']['app_name']}")
  else
    app = result
    break
  end
end

if app.nil?
  Chef::Log.info("Skipping mercury::crawler as there is no app #{node['mercury-crawler']['app_name']}")
  return
end

Chef::Log.info("application #{app['shortname']}")

sys_path = "/opt/mercury"
app_path = "#{sys_path}/#{app['shortname']}"
env_path = "#{sys_path}/env"

package 'git' do
  # workaround for:
  # WARNING: The following packages cannot be authenticated!
  # liberror-perl
  # STDERR: E: There are problems and -y was used without --force-yes
  options '--force-yes' if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
end

git app_path do
  repository app['app_source']['url']
  action :sync
end

python_runtime '27' do
  version '2.7'
  options :system, dev_package: true
end

python_virtualenv env_path do
  python '27'
  user "mercury"
  group "mercury"
  action :create
end

execute 'pip install requirements' do
  command                    "source #{env_path}/bin/activate; pip install -r #{app_path}/doubanMovieUpdate/requirements.txt"
  group                      'mercury'
  user                       'mercury'
end

supervisor_service app['shortname'] do
  user "root"
  action [:enable, :start]
  autostart true
  directory "#{app_path}/doubanMovieUpdate/"
  command "#{env_path}/bin/python #{app_path}/doubanMovieUpdate/application.py"
end
