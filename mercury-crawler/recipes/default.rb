include_recipe 'build-essential'
include_recipe 'supervisor'

app = search(:aws_opsworks_app).first

if app['shortname'] != 'python'
    Chef::Log.debug("Skipping mercury-crawler::default for application #{app['shortname']} as it is not a python app")
    return
end

app_path = "/srv/#{app['shortname']}"

package 'git' do
  # workaround for:
  # WARNING: The following packages cannot be authenticated!
  # liberror-perl
  # STDERR: E: There are problems and -y was used without --force-yes
  options '--force-yes' if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
end

application app_path do
  git app_path do
    repository app['app_source']['url']
    action :sync
  end

  python '2'
  virtualenv
  pip_requirements

  supervisor_service app['sortname'] do
    action :enable
    autostart true
    command "python application.py"
  end
end