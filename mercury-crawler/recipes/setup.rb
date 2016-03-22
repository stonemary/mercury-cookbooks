include_recipe 'build-essential'

include_recipe 'python'
include_recipe 'supervisor'

app = search("aws_opsworks_app").first

Chef::Log.info("application #{app['shortname']}")

if app['shortname'] != 'doubanMovie'
    Chef::Log.debug("Skipping mercury-crawler::default for application #{app['shortname']} as it is not a python app")
    return
end

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

python_runtime '2'

python_virtualenv env_path do
  user "mercury"
  group "mercury"
  action :create
end

pip_requirements "#{app_path}requirements.txt" do
  group "mercury"
  user "mercury"
  virtualenv env_path
end

supervisor_service app['sortname'] do
  user "root"
  group "root"
  action [:enable, :start]
  autostart true
  command "#{env_path}/bin/python #{app_path}/application.py"
end