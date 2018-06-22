if ENV['RACK_ENV']
#in docker

  require 'sinatra/activerecord/rake'
  namespace :db do
    task :load_config do
      require "./app"
    end
  end

else
#in host

  name=File.basename(Dir.pwd)
  docker_run=%(docker run --rm -it -v "#{Dir.pwd}":/myapp -e RACK_ENV=development #{ENV['DOCKER_OPT']} #{name})
  def get_images(name) `docker images #{name}`.scan(/^#{name}\s+(\S+)\s+(\S+)/).map{|v| v[0]}; end
  def get_new_version(name) (get_images(name).delete_if{|v| v=='latest'}.map{|v| Gem::Version.create(v)}.max || Gem::Version.create('0.0.0')).segments.tap{|v| v[-1]+=1}.join('.'); end

  desc "build new docker image"
  task :build , ['tag']  do |task, args|
    tag=args[:tag] || get_new_version(name)
    touch('Gemfile.lock') unless File.exists?('Gemfile.lock')
    sh("docker build -t #{name}:#{tag} .")
    sh("docker tag #{name}:#{tag} #{name}:latest")
    sh("#{docker_run} cp -pf /tmp/Gemfile.lock /myapp")
  end

  desc "run 'db:migrate' in docker"
  task :migrate do
    sh("#{docker_run} bundle exec rake db:migrate")
  end

  desc "run 'bash' in docker"
  task :bash  do |task, args|
    sh("#{docker_run} /bin/bash")
  end

  desc "run docker"
  task :run do
    sh(docker_run.sub('-it','-p 3000:3000 -it'))
  end

  desc "run 'pry' in docker"
  task :pry do
    sh("#{docker_run} bundle exec pry")
  end

end
