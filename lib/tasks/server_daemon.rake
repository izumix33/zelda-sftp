namespace :server_daemon do
  desc 'start server daemon'
  task :start => :environment do
    puts `bundle exec rails s -d --bind=0.0.0.0 -e production`
  end

  desc 'stop server daemon'
  task :stop  => :environment do
    pid_file = 'tmp/pids/server.pid'
    pid = File.read(pid_file).to_i
    Process.kill 9, pid
    File.delete pid_file
  end
end
