# Réseau : les bases sous Linux

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.
> Pour le réseau : Ubuntu Server utilise **Netplan** + `systemd-resolved`, Rocky utilise **NetworkManager** (`nmcli`, `nmtui`).

## Pourquoi ce cours ?

Un serveur est inutile s'il n'est pas joignable. La majorité des incidents en production ont une
composante réseau : « le site ne répond plus », « la base est injoignable », « la résolution de nom échoue ».
Savoir diagnostiquer **couche par couche** avec les bons outils fait gagner des heures.

## 1. Le modèle en couches

| Couche (simplifiée) | Rôle | Exemples | Outil de diagnostic |
|---|---|---|---|
| Liaison | Câble/Wi-Fi, adresses MAC | Ethernet | `ip link` |
| Réseau | Adressage et routage | IPv4, IPv6, ICMP | `ip a`, `ip route`, `ping`, `traceroute` |
| Transport | Connexions et ports | TCP, UDP | `ss`, `nc` |
| Application | Protocoles métier | HTTP, DNS, SSH | `curl`, `dig`, `ssh` |

> 💡 **Conseil** : en cas de panne, remontez les couches depuis le bas : lien → IP → passerelle → DNS → port → application.

## 2. Adresses IP et masques

Une adresse **IPv4** est composée de 32 bits notés en 4 octets : `192.168.1.25`. Le **masque** (ou préfixe CIDR) sépare la partie *réseau* de la partie *machine*.

```text
192.168.1.25/24
└── réseau ──┘└ machine
Masque /24 = 255.255.255.0 → 256 adresses (254 utilisables) : 192.168.1.0 à 192.168.1.255
```

| CIDR | Masque | Adresses utilisables |
|---|---|---|
| /8 | 255.0.0.0 | 16 777 214 |
| /16 | 255.255.0.0 | 65 534 |
| /24 | 255.255.255.0 | 254 |
| /30 | 255.255.255.252 | 2 |

**Plages privées** (non routées sur Internet, RFC 1918) : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. Adresse de boucle locale : `127.0.0.1` (`localhost`).

## 3. Voir et configurer ses interfaces : `ip`

La commande `ip` (paquet `iproute2`) remplace `ifconfig` (obsolète).

```bash
ip a                      # adresses de toutes les interfaces (ip address)
ip -br a                  # vue condensée
ip link                   # état des interfaces (UP/DOWN, adresse MAC)
ip route                  # table de routage
ip route get 8.8.8.8      # quelle route sera utilisée pour cette destination ?
ip neigh                  # table ARP (voisins du réseau local)
```

```text
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
192.168.56.0/24 dev enp0s8 proto kernel scope link src 192.168.56.10 metric 101
```

La route `default via …` est la **passerelle** : par où part tout ce qui n'est pas dans un réseau local. Dans la VM du cours, `enp0s3` est l'interface **NAT** (Internet, et SSH de Vagrant) et `enp0s8` le **réseau privé** `192.168.56.10` (accessible depuis votre ordinateur).

> ⚠️ **Attention** : ne modifiez **pas** `enp0s3` ni `enp0s8` dans les exercices : vous couperiez votre propre connexion `vagrant ssh`. Les manipulations d'adresses se font sur une **interface factice** `dummy0`.

Configuration **temporaire** (perdue au redémarrage), sur une interface factice :

```bash
sudo ip link add dummy0 type dummy
sudo ip link set dummy0 up
sudo ip addr add 192.168.50.10/24 dev dummy0
ip -br a show dummy0
sudo ip addr del 192.168.50.10/24 dev dummy0
sudo ip link del dummy0
```

### Configuration permanente : NetworkManager (`nmcli`)

Ubuntu Server utilise **Netplan** (fichiers YAML dans `/etc/netplan/`). **Rocky Linux et RHEL utilisent NetworkManager** : chaque interface a un **profil de connexion** (fichier `/etc/NetworkManager/system-connections/*.nmconnection`), qu'on pilote avec `nmcli` (ligne de commande) ou `nmtui` (menus en mode texte).

```bash
nmcli device status                     # interfaces et connexion active de chacune
nmcli connection show                   # profils enregistrés
nmcli -p connection show "Wired connection 1" | head -n 20   # détail d'un profil (adaptez le nom)
nmcli device show enp0s3 | grep -E 'IP4|DNS'                 # adresses, passerelle, DNS d'une interface
sudo nmtui                              # assistant en mode texte
```

Créer un profil à adresse fixe (sur l'interface factice) puis le supprimer :

```bash
sudo nmcli connection add type dummy ifname dummy0 con-name lab-dummy \
  ipv4.method manual ipv4.addresses 192.168.50.10/24 ipv4.dns "1.1.1.1 8.8.8.8"
sudo nmcli connection up lab-dummy
ip -br a show dummy0
nmcli connection show lab-dummy | grep -E 'ipv4\.(method|addresses|dns)'
sudo nmcli connection delete lab-dummy
```

Modifier un profil existant (exemple, à ne **pas** exécuter sur `enp0s3`) :

```bash
sudo nmcli connection modify "<profil>" ipv4.method manual \
  ipv4.addresses 192.168.56.20/24 ipv4.gateway 192.168.56.1 ipv4.dns "1.1.1.1 8.8.8.8"
sudo nmcli connection up "<profil>"     # applique (réactive le profil)
```

| Netplan (Ubuntu) | NetworkManager (Rocky / RHEL) |
|---|---|
| `addresses: [192.168.56.10/24]` | `ipv4.addresses 192.168.56.10/24` |
| `dhcp4: false` | `ipv4.method manual` (ou `auto` pour DHCP) |
| `routes: to: default via: …` | `ipv4.gateway …` |
| `nameservers: addresses: […]` | `ipv4.dns "1.1.1.1 8.8.8.8"` |
| `netplan try` / `netplan apply` | `nmcli connection up` / `nmcli connection reload` |

> ⚠️ **Attention** : il n'y a **pas d'équivalent de `netplan try`** : un profil erroné appliqué sur une machine distante vous coupe l'accès sans retour automatique. Gardez une seconde session ouverte, ou utilisez la console de la VM (fenêtre VirtualBox) pour corriger.

## 4. Tester la connectivité

```bash
ping -c 4 8.8.8.8            # connectivité IP (ICMP) sans dépendre du DNS
ping -c 4 rockylinux.org         # teste aussi la résolution de noms
traceroute rockylinux.org        # chemin saut par saut
tracepath rockylinux.org         # variante sans droits root
mtr -rw -c 10 rockylinux.org     # (sudo dnf install -y mtr) ping + traceroute continus
```

| Résultat | Diagnostic probable |
|---|---|
| `ping 8.8.8.8` OK mais `ping rockylinux.org` KO | Problème de **DNS** |
| `ping 192.168.x.1` (passerelle) KO | Problème de **lien local** |
| `ping` KO partout, interface sans IP | Problème de **DHCP / configuration** |

## 5. DNS : de nom à adresse

```text
Application → /etc/resolv.conf (rempli par NetworkManager) → serveur DNS (1.1.1.1) → serveurs racine/TLD/autoritaires
```

```bash
cat /etc/resolv.conf                  # serveurs DNS utilisés (écrit par NetworkManager)
nmcli device show enp0s3 | grep DNS   # serveurs DNS reçus par l'interface
dig rockylinux.org                    # requête DNS détaillée (paquet bind-utils)
dig +short A rockylinux.org           # seulement les adresses IPv4
dig +short MX gmail.com               # enregistrement de messagerie
dig @1.1.1.1 rockylinux.org           # interroger un serveur précis
getent hosts rockylinux.org           # résolution telle que la voit le système
cat /etc/hosts                        # table statique, consultée en priorité
grep hosts /etc/nsswitch.conf         # ordre de résolution
```

> 🐧 **Ubuntu vs Rocky** : Ubuntu place un résolveur local (`systemd-resolved`, `127.0.0.53`) et se pilote avec `resolvectl`. Sur Rocky, **`/etc/resolv.conf` est géré par NetworkManager** et contient directement les serveurs DNS (sous VirtualBox NAT : `10.0.2.3`). Pour changer de DNS de façon durable, on modifie le profil (`nmcli connection modify … ipv4.dns "1.1.1.1"`) puis on réactive la connexion ; une modification manuelle de `/etc/resolv.conf` est **écrasée** au prochain renouvellement.

| Enregistrement | Rôle |
|---|---|
| A / AAAA | Nom → adresse IPv4 / IPv6 |
| CNAME | Alias vers un autre nom |
| MX | Serveur de messagerie |
| TXT | Texte libre (SPF, vérifications) |
| NS | Serveurs de noms de la zone |

## 6. Ports et connexions : `ss`

Un **port** (0–65535) identifie un service sur une machine : 22 SSH, 80 HTTP, 443 HTTPS, 53 DNS.

```bash
ss -tulpn          # t=TCP u=UDP l=en écoute p=processus n=numérique
ss -tn state established   # connexions actives
ss -s              # résumé statistique
sudo ss -tlnp | grep :22   # qui écoute sur le port 22 ?
```

```text
State   Local Address:Port   Process
LISTEN  0.0.0.0:22           users:(("sshd",pid=812,fd=3))
LISTEN  127.0.0.1:5432       users:(("postgres",pid=900,fd=5))
```

> 📌 **À retenir** : `0.0.0.0:22` signifie « écoute sur **toutes** les interfaces » (joignable de l'extérieur). `127.0.0.1:5432` signifie « local uniquement ». Réduire l'exposition passe d'abord par là.

### Tester un port à distance

```bash
nc -zv 192.168.1.20 22          # le port 22 est-il ouvert ? (paquet nmap-ncat)
nc -zv rockylinux.org 80 443
curl -I https://rockylinux.org      # en-têtes HTTP
curl -s -o /dev/null -w "%{http_code}\n" https://rockylinux.org   # seulement le code HTTP
wget https://exemple.org/fichier.zip
```

## 7. TCP et UDP

| | TCP | UDP |
|---|---|---|
| Connexion | Oui (poignée de main SYN, SYN-ACK, ACK) | Non |
| Fiabilité | Retransmission, ordre garanti | Aucune garantie |
| Usage | Web, SSH, e-mail | DNS, streaming, VoIP |

## 8. Pare-feu : `firewalld`

Le noyau filtre les paquets via **netfilter** (présenté plus en détail au [module de durcissement](../../03-linux-avance/cours/04-securite-durcissement.md)). Sous Ubuntu, `ufw` en est l'interface simple. **Sous Rocky Linux et RHEL, c'est `firewalld`** : un service qui gère des **zones**, des **services** et des **ports**, et se pilote avec `firewall-cmd`.

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --state                  # running
sudo firewall-cmd --get-default-zone       # public
sudo firewall-cmd --get-active-zones       # zones utilisées et leurs interfaces
sudo firewall-cmd --list-all               # configuration de la zone par défaut
```

### Zones

Une **zone** est un niveau de confiance auquel on rattache des interfaces ou des adresses sources.

| Zone | Usage |
|---|---|
| `drop` | Tout est rejeté **sans réponse** |
| `block` | Tout est rejeté avec un message ICMP |
| `public` | **Défaut** : réseau non fiable, seuls les services autorisés passent (SSH, DHCPv6 client) |
| `internal` / `home` / `work` | Réseaux de confiance croissante |
| `trusted` | Tout est accepté |

```bash
sudo firewall-cmd --get-zones
sudo firewall-cmd --zone=internal --change-interface=enp0s8 --permanent
sudo firewall-cmd --zone=internal --list-all
```

### Services et ports

```bash
sudo firewall-cmd --get-services | tr ' ' '\n' | grep -E '^(ssh|http|https|dns)$'
sudo firewall-cmd --add-service=http                      # temporaire (runtime)
sudo firewall-cmd --permanent --add-service=http          # persistant (après --reload ou redémarrage)
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload                                # applique la configuration permanente
sudo firewall-cmd --list-services --list-ports
sudo firewall-cmd --permanent --remove-port=8080/tcp && sudo firewall-cmd --reload
```

> 📌 **À retenir** : `firewalld` a **deux configurations** : *runtime* (active maintenant, perdue au rechargement) et *permanent* (conservée). Sans `--permanent`, une règle disparaît au prochain `--reload` ; avec `--permanent`, elle n'est active qu'**après** `--reload`. Pour tout enregistrer d'un coup : `sudo firewall-cmd --runtime-to-permanent`.

> 💡 **Conseil** : l'équivalent de « tester sans se couper » est l'option `--timeout` : `sudo firewall-cmd --add-port=9000/tcp --timeout=60` ouvre le port **60 secondes** puis le referme tout seul.

### Règles riches (*rich rules*)

Quand un service ou un port ne suffit pas (filtrer par adresse source, journaliser, limiter le débit) :

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" service name="ssh" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="203.0.113.0/24" port port="8080" protocol="tcp" reject'
sudo firewall-cmd --permanent --add-rich-rule='rule service name="http" log prefix="HTTP " level="info" limit value="5/m" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
```

### Équivalences `ufw` ↔ `firewalld`

| Objectif | Ubuntu (`ufw`) | Rocky / RHEL (`firewalld`) |
|---|---|---|
| Activer | `ufw enable` | `systemctl enable --now firewalld` |
| État | `ufw status verbose` | `firewall-cmd --list-all` |
| Autoriser SSH | `ufw allow OpenSSH` | `firewall-cmd --permanent --add-service=ssh` |
| Autoriser un port | `ufw allow 80/tcp` | `firewall-cmd --permanent --add-port=80/tcp` |
| Refuser | `ufw deny 23` | rich rule `reject` ou ne pas ouvrir (zone `public` = refus par défaut) |
| Supprimer une règle | `ufw delete allow 80/tcp` | `firewall-cmd --permanent --remove-port=80/tcp` |
| Appliquer | immédiat | `firewall-cmd --reload` |

> ⚠️ **Attention** : le service `ssh` est autorisé par défaut dans la zone `public`. **Ne le retirez pas** sur une machine distante, et vérifiez `firewall-cmd --list-services` **avant** tout `--reload` : une erreur vous coupe l'accès. Sur la VM du cours, la console VirtualBox reste utilisable en secours.

## 9. Nom d'hôte

```bash
hostnamectl                          # informations
sudo hostnamectl set-hostname web01  # change le nom
```

## Résumé

- Diagnostic par **couches** : lien → IP → passerelle → DNS → port → application.
- `ip a`, `ip route`, `ip neigh` pour l'état local ; **NetworkManager** (`nmcli`, `nmtui`) pour la persistance.
- `ping`, `traceroute`/`mtr` pour la connectivité ; `dig` pour le DNS (`/etc/resolv.conf` est géré par NetworkManager).
- `ss -tulpn` montre qui écoute ; `nc -zv` et `curl` testent depuis l'extérieur.
- `firewalld` : zones, services, ports ; `--permanent` puis `--reload` ; SSH autorisé **avant** tout changement risqué.

## Pour aller plus loin

- `man ip`, `man ss`, `man nmcli`, `man firewall-cmd`, `man firewalld.richlanguage`.
- `tcpdump` pour capturer le trafic (`sudo tcpdump -i any port 53 -n`).
- IPv6, VLAN, ponts (`bridge`), NAT.
- Atelier associé : [Diagnostic réseau](../ateliers/atelier-03-diagnostic-reseau.md).
- Cours suivant : [SSH et clés](04-ssh-cles.md).
