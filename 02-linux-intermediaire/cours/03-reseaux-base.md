# Réseau : les bases sous Linux

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
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15
```

La route `default via …` est la **passerelle** : par où part tout ce qui n'est pas dans un réseau local.

Configuration **temporaire** (perdue au redémarrage) :

```bash
sudo ip addr add 192.168.50.10/24 dev enp0s3
sudo ip link set enp0s3 down
sudo ip link set enp0s3 up
sudo ip addr del 192.168.50.10/24 dev enp0s3
```

### Configuration permanente : Netplan

Ubuntu utilise **Netplan** : des fichiers YAML dans `/etc/netplan/` traduits vers `systemd-networkd` (serveur) ou NetworkManager (bureau).

```yaml
# /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses: [192.168.56.10/24]
      routes:
        - to: default
          via: 192.168.56.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

```bash
sudo netplan try        # applique avec retour automatique si vous perdez la connexion
sudo netplan apply      # applique définitivement
```

> ⚠️ **Attention** : le YAML est sensible à l'indentation (espaces, jamais de tabulations). Utilisez `netplan try` : si la nouvelle configuration vous coupe l'accès, elle est annulée automatiquement au bout de 120 s.

## 4. Tester la connectivité

```bash
ping -c 4 8.8.8.8            # connectivité IP (ICMP) sans dépendre du DNS
ping -c 4 ubuntu.com         # teste aussi la résolution de noms
traceroute ubuntu.com        # chemin saut par saut
tracepath ubuntu.com         # variante sans droits root
mtr -rw -c 10 ubuntu.com     # (apt install mtr-tiny) ping + traceroute continus
```

| Résultat | Diagnostic probable |
|---|---|
| `ping 8.8.8.8` OK mais `ping ubuntu.com` KO | Problème de **DNS** |
| `ping 192.168.x.1` (passerelle) KO | Problème de **lien local** |
| `ping` KO partout, interface sans IP | Problème de **DHCP / configuration** |

## 5. DNS : de nom à adresse

```text
Application → resolver local (systemd-resolved, 127.0.0.53) → serveur DNS (1.1.1.1) → serveurs racine/TLD/autoritaires
```

```bash
cat /etc/resolv.conf                  # 127.0.0.53 : le résolveur local
resolvectl status                     # serveurs DNS réellement utilisés
dig ubuntu.com                        # requête DNS détaillée (paquet dnsutils)
dig +short A ubuntu.com               # seulement les adresses IPv4
dig +short MX gmail.com               # enregistrement de messagerie
dig @1.1.1.1 ubuntu.com               # interroger un serveur précis
getent hosts ubuntu.com               # résolution telle que la voit le système
cat /etc/hosts                        # table statique, consultée en priorité
cat /etc/nsswitch.conf | grep hosts   # ordre de résolution
```

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
nc -zv 192.168.1.20 22          # le port 22 est-il ouvert ? (paquet netcat-openbsd)
nc -zv ubuntu.com 80 443
curl -I https://ubuntu.com      # en-têtes HTTP
curl -s -o /dev/null -w "%{http_code}\n" https://ubuntu.com   # seulement le code HTTP
wget https://exemple.org/fichier.zip
```

## 7. TCP et UDP

| | TCP | UDP |
|---|---|---|
| Connexion | Oui (poignée de main SYN, SYN-ACK, ACK) | Non |
| Fiabilité | Retransmission, ordre garanti | Aucune garantie |
| Usage | Web, SSH, e-mail | DNS, streaming, VoIP |

## 8. Pare-feu : première approche avec `ufw`

Le noyau filtre les paquets via **netfilter** (présenté plus en détail au [module de durcissement](../../03-linux-avance/cours/04-securite-durcissement.md)). `ufw` (*Uncomplicated Firewall*) en est une interface simple.

```bash
sudo ufw status verbose
sudo ufw allow OpenSSH             # AVANT d'activer !
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw deny 23
sudo ufw delete allow 80/tcp
```

> ⚠️ **Attention** : activer `ufw` sans règle SSH vous coupe d'une machine distante. Autorisez toujours SSH en premier.

## 9. Nom d'hôte

```bash
hostnamectl                          # informations
sudo hostnamectl set-hostname web01  # change le nom
```

## Résumé

- Diagnostic par **couches** : lien → IP → passerelle → DNS → port → application.
- `ip a`, `ip route`, `ip neigh` pour l'état local ; Netplan (YAML) pour la persistance, `netplan try` pour tester.
- `ping`, `traceroute`/`mtr` pour la connectivité ; `dig`/`resolvectl` pour le DNS.
- `ss -tulpn` montre qui écoute ; `nc -zv` et `curl` testent depuis l'extérieur.
- `ufw` : autoriser SSH **avant** d'activer.

## Pour aller plus loin

- `man ip`, `man ss`, `man netplan`, `man resolvectl`.
- `tcpdump` pour capturer le trafic (`sudo tcpdump -i any port 53 -n`).
- IPv6, VLAN, ponts (`bridge`), NAT.
- Atelier associé : [Diagnostic réseau](../ateliers/atelier-03-diagnostic-reseau.md).
- Cours suivant : [SSH et clés](04-ssh-cles.md).
