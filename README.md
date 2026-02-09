# 🎓 Script de Gestion des Élèves sur Proxmox VE Pédagogique

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Proxmox](https://img.shields.io/badge/Proxmox-8.4.1-orange.svg)](https://www.proxmox.com/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/graphs/commit-activity)

> **Script interactif tout-en-un pour gérer facilement les comptes élèves sur un serveur Proxmox VE utilisé dans un contexte pédagogique.**

Conçu par des formateurs pour des formateurs, ce script automatise la création, la suppression et la gestion des droits des comptes élèves, tout en garantissant la sécurité et la simplicité d'utilisation.

---

## 📋 Table des matières

- [✨ Fonctionnalités](#-fonctionnalités)
- [🚀 Installation rapide](#-installation-rapide)
- [📦 Installation manuelle](#-installation-manuelle)
- [🎯 Utilisation](#-utilisation)
- [📖 Guide détaillé](#-guide-détaillé)
- [🔒 Sécurité](#-sécurité)
- [🛠️ Configuration](#️-configuration)
- [📝 Format du fichier eleves.txt](#-format-du-fichier-elevestxt)
- [💡 Exemples](#-exemples)
- [❓ FAQ](#-faq)
- [🤝 Contribution](#-contribution)
- [📄 Licence](#-licence)
- [👨‍💻 Auteur](#-auteur)

---

## ✨ Fonctionnalités

### 🎯 Gestion complète des comptes

- **📝 Création automatique** : Création de comptes à partir d'une simple liste (nom prénom)
- **🗑️ Suppression sécurisée** : Suppression avec confirmation et nettoyage complet
- **👥 Gestion de groupe** : Ajout/retrait automatique du groupe "eleves"
- **🔐 Droits sudo** : Attribution de droits ciblés pour les commandes Proxmox

### 🛡️ Sécurité et robustesse

- ✅ Mots de passe initiaux automatiques avec changement obligatoire au premier login
- ✅ Validation des entrées et gestion des erreurs
- ✅ Gestion propre des interruptions (Ctrl+C)
- ✅ Configuration sudoers validée automatiquement
- ✅ Permissions strictes et audit trail

### 🎨 Interface moderne

- 🌈 Menu interactif coloré avec emojis
- 📊 Résumés détaillés après chaque opération
- ⚡ Messages d'information clairs et contextuels
- 🎭 Progression visible pour chaque étape

### ⚙️ Commandes Proxmox autorisées

Le script configure l'accès sudo pour ces commandes Proxmox :

| Commande | Description | Exemple d'utilisation |
|----------|-------------|----------------------|
| `pveum` | Proxmox VE User Manager | Gestion des utilisateurs et permissions Proxmox |
| `qm` | QEMU/KVM Manager | Création, gestion et clonage de VMs |
| `virt-customize` | Customisation de VMs | Modification d'images de VMs (libguestfs) |

---

## 🚀 Installation rapide

### Installation et exécution en une seule commande

```bash
sudo -E bash -c 'f=$(mktemp) && curl -fsSL https://raw.githubusercontent.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/main/gestion_eleves_proxmox_v2.sh -o "$f" && chmod +x "$f" && "$f" && rm -f "$f"'
```

**📌 Note importante** : Cette commande télécharge, exécute puis supprime automatiquement le script. Assurez-vous d'avoir créé votre fichier `eleves.txt` dans le répertoire courant avant de lancer la commande.

### 🔍 Détail de la commande

Voici ce que fait cette commande, étape par étape :

1. **`sudo -E`** : Exécute avec les privilèges root en préservant l'environnement
2. **`bash -c '...'`** : Lance un nouveau shell bash pour exécuter la séquence
3. **`f=$(mktemp)`** : Crée un fichier temporaire sécurisé
4. **`curl -fsSL https://...`** : Télécharge le script depuis GitHub
   - `-f` : Échoue silencieusement en cas d'erreur HTTP
   - `-s` : Mode silencieux (pas de barre de progression)
   - `-S` : Affiche les erreurs malgré `-s`
   - `-L` : Suit les redirections
5. **`chmod +x "$f"`** : Rend le script exécutable
6. **`"$f"`** : Exécute le script
7. **`rm -f "$f"`** : Supprime le fichier temporaire

---

## 📦 Installation manuelle

Si vous préférez télécharger et conserver le script :

```bash
# 1. Cloner le dépôt
git clone https://github.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique.git

# 2. Se déplacer dans le répertoire
cd Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique

# 3. Rendre le script exécutable
chmod +x gestion_eleves_proxmox_v2.sh

# 4. Créer votre fichier de liste d'élèves
nano eleves.txt

# 5. Exécuter le script
sudo ./gestion_eleves_proxmox_v2.sh
```

### Alternative : Téléchargement direct

```bash
# Télécharger uniquement le script
curl -fsSL https://raw.githubusercontent.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/main/gestion_eleves_proxmox_v2.sh -o gestion_eleves_proxmox.sh

# Rendre exécutable
chmod +x gestion_eleves_proxmox.sh

# Lancer
sudo ./gestion_eleves_proxmox.sh
```

---

## 🎯 Utilisation

### Menu principal

Une fois lancé, le script affiche un menu interactif :

```
╔════════════════════════════════════════════════════════════════╗
║     GESTION DES COMPTES ÉLÈVES - PROXMOX VE                   ║
╚════════════════════════════════════════════════════════════════╝

  📝 1) Créer les comptes élèves
  🗑️  2) Supprimer les comptes élèves
  🔐 3) Configurer les droits sudo (pveum, qm, virt-customize)
  👥 4) Ajouter les utilisateurs au groupe 'eleves'
  🔒 5) Révoquer les droits sudo
  📋 6) Afficher l'état actuel du système
  🚪 7) Quitter

────────────────────────────────────────────────────────────────

Votre choix :
```

### Workflow typique

#### 🎓 Début de formation

```bash
# 1. Créer le fichier eleves.txt avec la liste des élèves
# 2. Lancer le script
sudo ./gestion_eleves_proxmox.sh

# 3. Dans le menu, choisir option 1 (Créer les comptes)
# 4. Puis option 3 (Configurer les droits sudo)
# 5. Vérifier avec option 6 (Afficher l'état)
```

#### 🎯 Fin de formation

```bash
# 1. Lancer le script
sudo ./gestion_eleves_proxmox.sh

# 2. Option 2 (Supprimer les comptes)
# 3. Confirmer en tapant "OUI"
```

---

## 📖 Guide détaillé

### Option 1 : Créer les comptes élèves

**Ce qui se passe :**

1. ✅ Lecture et validation du fichier `eleves.txt`
2. ✅ Création du groupe "eleves" (si nécessaire)
3. ✅ Pour chaque élève :
   - Création du compte utilisateur
   - Attribution du répertoire `/home/eleves/prenom.nom`
   - Définition du mot de passe initial : `prenom123`
   - Ajout au groupe "eleves"
   - Obligation de changer le mot de passe au premier login

**Exemple de sortie :**

```
╔════════════════════════════════════════════════════════════════╗
║  📝 CRÉATION DES COMPTES ÉLÈVES
╚════════════════════════════════════════════════════════════════╝

ℹ️  Lecture du fichier : eleves.txt
  → Nombre d'élèves à traiter : 13

❓ Voulez-vous continuer ? (o/N) : o

────────────────────────────────────────────────────────────────
⚙️  Préparation de l'environnement...
────────────────────────────────────────────────────────────────

✅ Groupe 'eleves' créé.

────────────────────────────────────────────────────────────────
👥 Traitement des comptes...
────────────────────────────────────────────────────────────────

  ➜ Création de l'utilisateur : linus.torvalds (Linus TORVALDS)
    ✓ Compte créé avec succès (mot de passe initial : linus123)
  ➜ Création de l'utilisateur : alan.turing (Alan TURING)
    ✓ Compte créé avec succès (mot de passe initial : alan123)
  ...

────────────────────────────────────────────────────────────────
  📊 RÉSUMÉ DE L'OPÉRATION
────────────────────────────────────────────────────────────────

  ✅ Comptes créés        : 13
  ⊘  Comptes existants   : 0
  ❌ Erreurs rencontrées  : 0

────────────────────────────────────────────────────────────────

✅ Tous les nouveaux comptes ont été ajoutés au groupe 'eleves'.
ℹ️  Les utilisateurs devront changer leur mot de passe à la première connexion.
```

### Option 2 : Supprimer les comptes élèves

**⚠️ ATTENTION** : Cette opération est **irréversible** et supprime :
- Les comptes utilisateurs
- Les répertoires personnels (`/home/eleves/...`)
- Toutes les données associées

**Confirmation requise** : Vous devez taper `OUI` en majuscules.

### Option 3 : Configurer les droits sudo

Configure le fichier `/etc/sudoers.d/eleves-proxmox` pour autoriser les membres du groupe "eleves" à exécuter les commandes Proxmox sans mot de passe.

**Commandes autorisées :**
- `sudo pveum` : Gestion des utilisateurs Proxmox
- `sudo qm` : Gestion des machines virtuelles
- `sudo virt-customize` : Personnalisation des images VM

**Sécurité :**
- ✅ Validation automatique avec `visudo`
- ✅ Permissions strictes (0440)
- ✅ Rollback automatique en cas d'erreur

### Option 4 : Ajouter les utilisateurs au groupe

Ajoute manuellement des utilisateurs existants au groupe "eleves" en tant que membres secondaires.

**Utilité :**
- Corriger des comptes créés manuellement
- Ajouter des utilisateurs existants au groupe
- Réparer des problèmes d'appartenance au groupe

### Option 5 : Révoquer les droits sudo

Supprime le fichier `/etc/sudoers.d/eleves-proxmox`, révoquant ainsi tous les droits sudo spéciaux.

### Option 6 : Afficher l'état actuel

Affiche un rapport complet :
- 📊 État du groupe "eleves" et liste des membres
- 📋 Liste des comptes de `eleves.txt` (existants ou non)
- 🔐 Configuration sudo active

**Exemple de sortie :**

```
╔════════════════════════════════════════════════════════════════╗
║  📋 ÉTAT ACTUEL DU SYSTÈME
╚════════════════════════════════════════════════════════════════╝

━━━ GROUPE 'eleves' ━━━

✅ Le groupe 'eleves' existe.
  → Nombre de membres : 13
  → Liste des membres :

      • linus.torvalds
      • alan.turing
      • bill.gates
      ...

━━━ COMPTES ÉLÈVES (basés sur eleves.txt) ━━━

  ✓ linus.torvalds
  ✓ alan.turing
  ✓ bill.gates
  ...

────────────────────────────────────────────────────────────────
  Comptes existants : 13 / 13
────────────────────────────────────────────────────────────────

━━━ CONFIGURATION SUDO ━━━

✅ Configuration sudo active : /etc/sudoers.d/eleves-proxmox

  Contenu :

    → Cmnd_Alias PROXMOX_CMDS = /usr/bin/pveum, /usr/sbin/qm, /usr/bin/virt-customize
    → %eleves ALL=(ALL) NOPASSWD: PROXMOX_CMDS
```

---

## 🔒 Sécurité

### Mots de passe

- **Format initial** : `prenom123` (prénom sans accents + "123")
- **Changement obligatoire** au premier login via `passwd -e`
- Les élèves doivent définir un mot de passe personnel robuste

**Exemple :**
- `Jean-François DUPONT` → mot de passe initial : `jean-francois123`
- À la première connexion, l'utilisateur doit choisir un nouveau mot de passe

### Permissions

- **Fichier sudoers** : `0440` (lecture seule pour root)
- **Répertoires home** : Propriété de l'utilisateur
- **Validation** : Syntaxe sudoers vérifiée avec `visudo -c`

### Principe du moindre privilège

Les élèves ont accès uniquement aux commandes Proxmox nécessaires :
- ❌ Pas d'accès root complet
- ❌ Pas d'accès aux commandes système sensibles
- ✅ Uniquement `pveum`, `qm`, et `virt-customize`

### Audit et traçabilité

- Tous les comptes créés sont tracés dans `/etc/passwd`
- Configuration sudo dans `/etc/sudoers.d/eleves-proxmox`
- Logs système via `syslog` pour toutes les actions

---

## 🛠️ Configuration

### Variables configurables

En haut du script, vous pouvez modifier ces paramètres :

```bash
LISTE="eleves.txt"                          # Fichier de liste
BASE_HOME="/home/eleves"                    # Répertoire parent
GROUPE="eleves"                             # Nom du groupe
SHELL="/bin/bash"                           # Shell par défaut
SUDOERS_FILE="/etc/sudoers.d/eleves-proxmox" # Fichier sudo
```

### Personnalisation des commandes sudo

Pour autoriser d'autres commandes, éditez la section dans la fonction `configurer_sudo()` :

```bash
Cmnd_Alias PROXMOX_CMDS = /usr/bin/pveum, /usr/sbin/qm, /usr/bin/virt-customize, /chemin/vers/autre/commande
```

**Exemple** : Ajouter `pct` pour la gestion des conteneurs LXC :

```bash
Cmnd_Alias PROXMOX_CMDS = /usr/bin/pveum, /usr/sbin/qm, /usr/bin/virt-customize, /usr/sbin/pct
```

---

## 📝 Format du fichier eleves.txt

### Format de base

Le fichier `eleves.txt` doit contenir une ligne par élève au format :

```
NOM Prénom
```

### Exemple complet

```
# Promotion 2026 - Groupe A
TORVALDS Linus
TURING Alan
GATES Bill

# Promotion 2026 - Groupe B
JOBS Steve
BERNERS-LEE Tim
STALLMAN Richard

# Nouveaux arrivants
ZUCKERBERG Mark
PAGE Larry
```

### Règles importantes

✅ **Accepté :**
- Lignes vides (ignorées)
- Commentaires commençant par `#` (ignorés)
- Noms avec tirets : `BERNERS-LEE Tim`
- Noms avec accents : `FRANÇOIS Jean`
- Prénoms composés : `Jean-Pierre DUPONT`

❌ **Rejeté :**
- Lignes avec un seul mot
- Format inverse (Prénom NOM)
- Caractères spéciaux (excepté tirets et apostrophes)

### Transformation des noms

Le script convertit automatiquement :

| Format fichier | Nom d'utilisateur | Mot de passe initial |
|----------------|-------------------|----------------------|
| `TORVALDS Linus` | `linus.torvalds` | `linus123` |
| `BERNERS-LEE Tim` | `tim.berners-lee` | `tim123` |
| `FRANÇOIS Jean` | `jean.francois` | `jean123` |
| `DUPONT Jean-Pierre` | `jean-pierre.dupont` | `jean-pierre123` |

**Règles de transformation :**
- Conversion en minuscules
- Suppression des accents
- Conservation des tirets
- Format : `prenom.nom`

---

## 💡 Exemples

### Exemple 1 : Nouvelle promotion

```bash
# 1. Créer le fichier eleves.txt
cat > eleves.txt << EOF
TORVALDS Linus
TURING Alan
GATES Bill
JOBS Steve
EOF

# 2. Lancer le script
sudo ./gestion_eleves_proxmox.sh

# 3. Choisir option 1 (Créer les comptes)
# 4. Choisir option 3 (Configurer sudo)
# 5. Choisir option 6 (Vérifier l'état)
```

**Résultat :**
- 4 comptes créés : `linus.torvalds`, `alan.turing`, `bill.gates`, `steve.jobs`
- Tous dans le groupe "eleves"
- Droits sudo configurés
- Mots de passe : `linus123`, `alan123`, `bill123`, `steve123`

### Exemple 2 : Test avec un seul élève

```bash
# Créer un fichier de test
echo "TEST Utilisateur" > eleves.txt

# Lancer le script et créer le compte
sudo ./gestion_eleves_proxmox.sh
# Choisir option 1

# Tester la connexion
su - utilisateur.test
# Mot de passe : utilisateur123
# Le système demande de changer le mot de passe

# Tester sudo
sudo qm list

# Supprimer le compte de test
exit
sudo ./gestion_eleves_proxmox.sh
# Choisir option 2
```

### Exemple 3 : Ajout d'utilisateurs existants au groupe

```bash
# Situation : Des comptes existent mais ne sont pas dans le groupe

# 1. Créer eleves.txt avec les noms
cat > eleves.txt << EOF
MARTIN Alice
BERNARD Bob
EOF

# 2. Lancer le script
sudo ./gestion_eleves_proxmox.sh

# 3. Choisir option 4 (Ajouter au groupe)
# Les comptes existants sont ajoutés au groupe "eleves"
```

### Exemple 4 : Installation rapide avant une session

```bash
# Créer d'abord le fichier eleves.txt
cat > eleves.txt << EOF
MARTIN Alice
BERNARD Bob
DURAND Claire
EOF

# Puis lancer l'installation en une ligne
sudo -E bash -c 'f=$(mktemp) && curl -fsSL https://raw.githubusercontent.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/main/gestion_eleves_proxmox_v2.sh -o "$f" && chmod +x "$f" && "$f" && rm -f "$f"'

# Le script se lance automatiquement
# Choisir option 1 puis 3 dans le menu
```

---

## ❓ FAQ

### Questions générales

<details>
<summary><b>Q : Le script fonctionne-t-il sur d'autres distributions que Proxmox ?</b></summary>

**R :** Oui, le script fonctionne sur toute distribution basée sur Debian/Ubuntu (où `useradd`, `groupadd`, `sudoers.d` sont disponibles). Cependant, les commandes sudo configurées (`pveum`, `qm`, `virt-customize`) sont spécifiques à Proxmox.
</details>

<details>
<summary><b>Q : Puis-je utiliser le script plusieurs fois sur le même serveur ?</b></summary>

**R :** Oui, absolument. Le script détecte les comptes existants et les ignore. Vous pouvez ajouter de nouveaux élèves à `eleves.txt` et relancer le script.
</details>

<details>
<summary><b>Q : Les mots de passe sont-ils sécurisés ?</b></summary>

**R :** Les mots de passe initiaux (`prenom123`) sont temporaires et faibles **par conception**. Les utilisateurs sont **obligés** de les changer à la première connexion grâce à `passwd -e`. C'est une pratique standard en environnement pédagogique.
</details>

<details>
<summary><b>Q : Que se passe-t-il si j'interromps le script (Ctrl+C) ?</b></summary>

**R :** Le script gère proprement les interruptions. Il affiche un message et se termine correctement sans corrompre le système.
</details>

### Questions techniques

<details>
<summary><b>Q : Pourquoi les utilisateurs n'apparaissent pas dans `getent group eleves` ?</b></summary>

**R :** Il faut distinguer **groupe primaire** et **groupe secondaire**. Pour apparaître dans `getent group`, un utilisateur doit être membre **secondaire**. Le script ajoute automatiquement les utilisateurs comme membres secondaires (option `-G`). Si nécessaire, utilisez l'option 4 du menu pour corriger.
</details>

<details>
<summary><b>Q : Puis-je personnaliser le format des noms d'utilisateur ?</b></summary>

**R :** Oui, en modifiant la fonction `username_from_line()` dans le script. Par défaut : `prenom.nom`. Vous pourriez changer en `pnom` (première lettre + nom) ou autre format.
</details>

<details>
<summary><b>Q : Comment ajouter d'autres commandes sudo autorisées ?</b></summary>

**R :** Modifiez la ligne `Cmnd_Alias PROXMOX_CMDS` dans la fonction `configurer_sudo()`. Exemple pour ajouter `pct` :
```bash
Cmnd_Alias PROXMOX_CMDS = /usr/bin/pveum, /usr/sbin/qm, /usr/bin/virt-customize, /usr/sbin/pct
```
</details>

<details>
<summary><b>Q : Le script conserve-t-il un historique des opérations ?</b></summary>

**R :** Les opérations système (création/suppression utilisateurs, modifications sudoers) sont enregistrées dans les logs système (`/var/log/auth.log`, `/var/log/syslog`). Le script lui-même n'écrit pas de log dédié.
</details>

### Problèmes courants

<details>
<summary><b>Q : Erreur "Ce script doit être exécuté avec sudo"</b></summary>

**R :** Le script nécessite les privilèges root. Lancez-le avec `sudo ./script.sh`.
</details>

<details>
<summary><b>Q : Erreur "Le fichier eleves.txt est introuvable"</b></summary>

**R :** Assurez-vous que `eleves.txt` est dans le même répertoire que le script. Utilisez `pwd` pour vérifier votre emplacement et `ls` pour lister les fichiers.
</details>

<details>
<summary><b>Q : Un nom avec accent ne fonctionne pas correctement</b></summary>

**R :** Le script utilise `iconv` pour convertir les accents. Assurez-vous que votre fichier `eleves.txt` est en UTF-8. Vérifiez avec :
```bash
file -i eleves.txt
# Devrait afficher : charset=utf-8
```
</details>

<details>
<summary><b>Q : Les comptes sont créés mais je ne peux pas me connecter en SSH</b></summary>

**R :** Vérifiez la configuration SSH dans `/etc/ssh/sshd_config`. Par défaut, SSH peut être configuré pour n'autoriser que certains utilisateurs. Ajoutez si nécessaire :
```bash
AllowGroups eleves
```
Puis redémarrez SSH : `systemctl restart sshd`
</details>

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment participer :

### Signaler un bug

1. Vérifiez que le bug n'est pas déjà signalé dans les [Issues](https://github.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/issues)
2. Créez une nouvelle issue avec :
   - Description claire du problème
   - Étapes pour reproduire
   - Version de Proxmox
   - Logs pertinents

### Proposer une amélioration

1. Forkez le dépôt
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Pushez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

### Standards de code

- ✅ Code bash conforme à [ShellCheck](https://www.shellcheck.net/)
- ✅ Commentaires clairs en français
- ✅ Fonctions modulaires et réutilisables
- ✅ Gestion des erreurs systématique
- ✅ Messages utilisateur informatifs

---

## 🧪 Tests

### Environnement de test

Le script a été testé sur :

- ✅ **Proxmox VE 8.4.1** (environnement de production pédagogique)
- ✅ Debian 12 (Bookworm)
- ✅ Ubuntu Server 22.04 LTS
- ✅ Bash 5.0+

### Tests recommandés avant déploiement

```bash
# 1. Test avec un seul utilisateur
echo "TEST Utilisateur" > eleves.txt
sudo ./gestion_eleves_proxmox.sh
# Option 1, puis vérifier

# 2. Test de connexion
su - utilisateur.test
# Vérifier le changement de mot de passe obligatoire

# 3. Test sudo
sudo qm list
sudo pveum user list

# 4. Test de suppression
exit
sudo ./gestion_eleves_proxmox.sh
# Option 2 pour supprimer

# 5. Test avec noms spéciaux
cat > eleves.txt << EOF
FRANÇOIS Jean
MÜLLER Hans
O'BRIEN Patrick
BERNERS-LEE Tim
EOF
# Relancer les tests
```

---

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

### En résumé

✅ **Vous pouvez** :
- Utiliser ce script à des fins commerciales ou personnelles
- Modifier le code selon vos besoins
- Distribuer le script original ou modifié
- Utiliser en privé sans partager les modifications

✅ **Vous devez** :
- Inclure une copie de la licence MIT
- Inclure l'avis de copyright

❌ **Limitations** :
- Aucune garantie fournie
- Les auteurs ne sont pas responsables des dommages

---

## 👨‍💻 Auteur

**Nicolas BODAINE**
- 🏢 Organisation : [TutoTech](https://github.com/TutoTech)
- 📧 Contact : [Via GitHub Issues](https://github.com/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique/issues)
- 🎓 Contexte : Formateur chez Simplon Campus Distanciel

### Remerciements

- 🙏 **Simplon Campus Distanciel** pour le Proxmox VE 8.4.1 pédagogique de test
- 🙏 **L'équipe TutoTech** pour le support et les retours
- 🙏 **La communauté Proxmox** pour la documentation

---

## 📚 Ressources complémentaires

### Documentation officielle

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Linux User Management](https://www.debian.org/doc/manuals/debian-reference/ch04.en.html)

### Tutoriels recommandés

- [Gestion des utilisateurs Linux](https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-ubuntu-20-04)
- [Configuration sudo](https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file)
- [Bonnes pratiques Bash](https://google.github.io/styleguide/shellguide.html)

---

## 📊 Statistiques

![GitHub stars](https://img.shields.io/github/stars/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique?style=social)
![GitHub forks](https://img.shields.io/github/forks/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique?style=social)
![GitHub issues](https://img.shields.io/github/issues/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique)
![GitHub pull requests](https://img.shields.io/github/issues-pr/TutoTech/Script-de-gestion-des-eleves-sur-un-Proxmox-pedagogique)

---

## 🌟 Support

Si ce script vous a été utile, n'hésitez pas à :

- ⭐ Mettre une étoile au projet
- 🐛 Signaler des bugs
- 💡 Proposer des améliorations
- 📣 Partager avec d'autres formateurs

---

<div align="center">

**Fait avec ❤️ par la communauté TutoTech**

[⬆ Retour en haut](#-script-de-gestion-des-élèves-sur-proxmox-ve-pédagogique)

</div>
