WEB_IP       = '192.168.56.10'
DB_IP        = '192.168.56.20'
DB_HOST_PORT = '3307'   # Port hôte pour accéder à MySQL

Vagrant.configure('2') do |config|
  # --- Web Server ---
  config.vm.define 'web-server' do |web|
    web.vm.box = 'ubuntu/jammy64'
    web.vm.hostname = 'web-server'
    web.vm.network 'public_network'
    web.vm.network 'private_network', ip: WEB_IP
    web.vm.synced_folder './website', '/var/www/html', create: true
    web.vm.provision 'shell', path: 'scripts/provision-web-ubuntu.sh'
    web.vm.provider 'virtualbox' do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  # --- Database Server ---
  config.vm.define 'db-server' do |db|
    db.vm.box = 'generic/centos9s'
    db.vm.hostname = 'db-server'
    db.vm.network 'private_network', ip: DB_IP
    db.vm.network 'forwarded_port', guest: 3306, host: DB_HOST_PORT, auto_correct: true
    db.vm.provision 'shell', path: 'scripts/provision-db-centos.sh'
    db.vm.provider 'virtualbox' do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end
end
