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

  desc "build new docker image"
  task :build , ['tag']  do |task, args|
    tag=args[:tag] || "0.0.1"
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

  desc "run 'pry' in docker"
  task :pry do
    sh("#{docker_run} bundle exec pry")
  end

end
