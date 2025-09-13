# Projet Infra – VirtualBox & Vagrant (Brief S0)

Infrastructure pédagogique multi‑machines pour illustrer :
1. Provisionnement automatisé (shell scripts)
2. Séparation Web statique / Base MySQL
3. Publication d’images (boxes) sur HashiCorp Cloud (Vagrant Cloud)

## Boxes Cloud publiées
Version initiale : `0.1.0`

| Rôle | Box | Provider | Architecture | Contenu principal | Lien |
|------|-----|----------|--------------|------------------|------|
| Web  | `S0_Brief_Projet_VirtualBox_Vagrant/ubuntu-web-server` | virtualbox | amd64 | Ubuntu 22.04 + Nginx + docroot `/var/www/html` | [Vagrant Cloud](https://portal.cloud.hashicorp.com/vagrant/discover/S0_Brief_Projet_VirtualBox_Vagrant/ubuntu-web-server) |
| DB   | `S0_Brief_Projet_VirtualBox_Vagrant/centos-mysql-db`   | virtualbox | amd64 | CentOS 9 Stream + MySQL 8 (`demo_db.users`) | [Vagrant Cloud](https://portal.cloud.hashicorp.com/vagrant/discover/S0_Brief_Projet_VirtualBox_Vagrant/centos-mysql-db) |

Pour consommer directement (sans cloner ce repo) :
```ruby
Vagrant.configure("2") do |c|
  c.vm.define "web" do |w|
    w.vm.box = "S0_Brief_Projet_VirtualBox_Vagrant/ubuntu-web-server"
  end
  c.vm.define "db" do |d|
    d.vm.box = "S0_Brief_Projet_VirtualBox_Vagrant/centos-mysql-db"
  end
end
```

## Architecture Logique
```
Navigateur/Host
   │ (HTTP via IP publique DHCP)
   ▼
Ubuntu Web (192.168.56.10) -- réseau privé 192.168.56.0/24 -- CentOS DB (192.168.56.20)
                                             │
                            Port forward host 3307 -> guest 3306
```

## Contenu & Fonctionnalités
- Web : Nginx sert ce qui est placé dans `website/` (placeholder créé si vide).
- DB : MySQL 8, base `demo_db`, table `users` + données démo (5 entrées).
- Utilisateur MySQL applicatif : `devuser` / `devpass` (host `%`).
- Accès root MySQL: mot de passe défini dans script (`RootPass123!` si inchangé).

## Structure du dépôt
```
Vagrantfile
scripts/
  provision-web-ubuntu.sh
  provision-db-centos.sh
database/
  create-table.sql
  insert-demo-data.sql
website/   (vos fichiers statiques)
```

## Lancer localement depuis ce repo
```bash
vagrant up
vagrant ssh web-server
vagrant ssh db-server
```
Site : visiter l’IP publique attribuée (affichée pendant `vagrant up`).

Test MySQL depuis l’hôte (port forward) :
```bash
mysql -h 127.0.0.1 -P 3307 -u root -p -e "SELECT COUNT(*) FROM demo_db.users;"
```

Test depuis web-server :
```bash
mysql -h 192.168.56.20 -u devuser -pdevpass -D demo_db -e "SELECT * FROM users LIMIT 3;"
```

## IPs / Ports (fixes)
- Web VM privée : 192.168.56.10
- DB VM privée : 192.168.56.20
- MySQL host forward : 3307 -> 3306
Changer : éditer directement le `Vagrantfile`.

## Packaging Manuel (rappel)
```bash
vagrant halt
vagrant package web-server --output ubuntu-web.box
vagrant package db-server  --output centos-db.box
```
Publication CLI (exemple générique – ici remplacé par vos boxes réelles déjà publiées) :
```bash
vagrant cloud auth login
vagrant cloud publish NAMESPACE/ubuntu-web-server 0.1.0 virtualbox ubuntu-web.box --release -d "Ubuntu 22.04 Nginx"
vagrant cloud publish NAMESPACE/centos-mysql-db 0.1.0 virtualbox centos-db.box --release -d "CentOS9 MySQL 8"
```

## Mise à jour (exemple)
1. Modifier scripts / contenu
2. `vagrant destroy -f && vagrant up && vagrant halt`
3. `vagrant package ...`
4. Publier nouvelle version `0.1.1` (SemVer : incrément patch si correctif, minor si fonctionnalité).

## Dépannage rapide
| Problème | Cause probable | Commande / Solution |
|----------|----------------|---------------------|
| Pas de connexion MySQL depuis web | Firewall ou bind | Vérifier `firewall-cmd --list-services` + bind-address=0.0.0.0 |
| ERREUR 1045 root | Mauvais mot de passe | Reprovision DB ou détruire/recréer | 
| Site 403 | Pas d'`index.html` | Ajouter `website/index.html` puis `vagrant provision web-server` |
| Port 3307 occupé | Conflit local | Changer dans `Vagrantfile` et `vagrant reload` |

## Sécurité (avertissement)
Configuration simplifiée : pas destinée à la production. User MySQL ouvert (`%`), pas de TLS, Nginx basique.

## Licence
Usage pédagogique interne / démonstration.

## Changelog
- 0.1.0 : Première version publiée (web + db boxes). 

---
Pour toute amélioration souhaitée (multi-arch, chiffrement, Ansible, tests), ouvrez une issue ou itérez une nouvelle version.
