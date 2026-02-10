#!/bin/bash
################################################################################
# Script de gestion des comptes élèves pour Proxmox VE
# 
# Fonctionnalités :
#  - Création de comptes utilisateurs à partir d'une liste
#  - Suppression de comptes utilisateurs
#  - Attribution de droits sudo pour commandes Proxmox (pveum, qm, virt-customize)
#  - Gestion des groupes et affichage de l'état
#
# Auteur : Formateur Proxmox
# Version : 2.0
################################################################################

set -euo pipefail

#===============================================================================
# CONFIGURATION
#===============================================================================

LISTE="eleves.txt"
BASE_HOME="/home/eleves"
GROUPE="eleves"
SHELL="/bin/bash"
SUDOERS_FILE="/etc/sudoers.d/eleves-proxmox"

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

#===============================================================================
# GESTION DES SIGNAUX
#===============================================================================

# Fonction appelée lors d'une interruption (Ctrl+C)
cleanup() {
  echo ""
  echo ""
  warning "⚡ Interruption détectée !"
  info "Nettoyage en cours..."
  echo ""
  exit 130
}

# Intercepter les signaux d'interruption
trap cleanup SIGINT SIGTERM

#===============================================================================
# FONCTIONS UTILITAIRES
#===============================================================================

# Affiche un message d'information
info() {
  echo -e "${BLUE}ℹ️  $*${NC}"
}

# Affiche un message de succès
success() {
  echo -e "${GREEN}✅ $*${NC}"
}

# Affiche un message d'avertissement
warning() {
  echo -e "${YELLOW}⚠️  $*${NC}"
}

# Affiche un message d'erreur
error() {
  echo -e "${RED}❌ $*${NC}"
}

# Affiche une bannière colorée
banner() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}$*${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Affiche un séparateur
separator() {
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
}

# Convertit une chaîne UTF-8 en ASCII (supprime les accents) et met en minuscules
to_ascii() {
  iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Nettoie une chaîne en conservant les tirets
# Supprime : espaces, underscores, points, apostrophes et caractères spéciaux
sanitize_part_keep_hyphen() {
  local s
  s=$(printf "%s" "$1" | to_ascii)
  s=${s// /}; s=${s//_/}; s=${s//./}; s=${s//\'/}
  printf "%s" "$s" | sed 's/[^a-z0-9-]//g'
}

# Génère un nom d'utilisateur à partir d'une ligne "NOM Prénom"
# Format : prenom.nom (en minuscules, sans accents)
username_from_line() {
  local line="$1"
  local nom prenom
  
  # Extraction du nom et prénom
  nom="${line%% *}"
  prenom="${line#* }"
  [[ "$prenom" == "$nom" ]] && prenom=""

  # Nettoyage et normalisation
  local nom_s prenom_s
  nom_s=$(sanitize_part_keep_hyphen "$nom")
  prenom_s=$(sanitize_part_keep_hyphen "$prenom")
  
  # Construction du nom d'utilisateur
  local username
  username=$(printf "%s.%s" "$prenom_s" "$nom_s")
  
  # Validation : le nom d'utilisateur ne doit pas être vide
  if [[ -z "$username" || "$username" == "." ]]; then
    echo ""
    return 1
  fi
  
  printf "%s" "$username"
}

# Génère le nom d'affichage (GECOS) au format "Prénom Nom"
display_name_from_line() {
  local line="$1"
  local nom prenom
  nom="${line%% *}"
  prenom="${line#* }"
  printf "%s %s" "$prenom" "$nom"
}

# Vérifie que le script est exécuté avec les privilèges sudo
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo ""
    error "Ce script doit être exécuté avec sudo ou en tant que root."
    echo ""
    echo -e "  ${BOLD}Utilisation :${NC} sudo $0"
    echo ""
    exit 1
  fi
}

# Vérifie que le fichier de liste des élèves existe
check_liste_file() {
  if [[ ! -f "$LISTE" ]]; then
    error "Le fichier '${BOLD}${LISTE}${NC}' est introuvable."
    echo ""
    echo "Veuillez créer ce fichier avec la liste des élèves au format :"
    echo -e "  ${CYAN}NOM Prénom${NC}"
    echo -e "  ${CYAN}NOM Prénom${NC}"
    echo -e "  ${CYAN}...${NC}"
    echo ""
    exit 1
  fi
  
  # Vérifier que le fichier n'est pas vide
  if [[ ! -s "$LISTE" ]]; then
    error "Le fichier '${BOLD}${LISTE}${NC}' est vide."
    echo ""
    exit 1
  fi
}

# Pause avec message personnalisable
pause() {
  echo ""
  read -p "$(echo -e ${CYAN}▶ Appuyez sur Entrée pour continuer...${NC}) " -r
  echo ""
}

# Demande de confirmation avec message personnalisé
confirm() {
  local message="$1"
  local response
  read -p "$(echo -e ${YELLOW}❓ ${message}${NC}) " -r response
  [[ "$response" =~ ^[oO]$ ]]
}

#===============================================================================
# FONCTION 1 : CRÉATION DES COMPTES
#===============================================================================

creer_comptes() {
  banner "📝 CRÉATION DES COMPTES ÉLÈVES"
  
  check_liste_file
  
  info "Lecture du fichier : ${BOLD}${LISTE}${NC}"
  local nb_lignes
  nb_lignes=$(grep -cv '^$' "$LISTE" 2>/dev/null || echo "0")
  
  if [[ $nb_lignes -eq 0 ]]; then
    error "Aucune ligne valide trouvée dans le fichier."
    return
  fi
  
  echo -e "  ${BOLD}→${NC} Nombre d'élèves à traiter : ${BOLD}${nb_lignes}${NC}"
  echo ""
  
  # Demande de confirmation
  if ! confirm "Voulez-vous continuer ? (o/N) : "; then
    warning "Opération annulée par l'utilisateur."
    return
  fi
  
  echo ""
  separator
  info "⚙️  Préparation de l'environnement..."
  separator
  echo ""
  
  # Créer le répertoire parent si nécessaire
  if [[ ! -d "$BASE_HOME" ]]; then
    mkdir -p "$BASE_HOME"
    success "Répertoire ${BOLD}${BASE_HOME}${NC} créé."
  else
    info "Répertoire ${BOLD}${BASE_HOME}${NC} existe déjà."
  fi
  
  # Créer le groupe si nécessaire
  if ! getent group "$GROUPE" >/dev/null; then
    groupadd "$GROUPE"
    success "Groupe '${BOLD}${GROUPE}${NC}' créé."
  else
    info "Groupe '${BOLD}${GROUPE}${NC}' existe déjà."
  fi
  
  echo ""
  separator
  info "👥 Traitement des comptes..."
  separator
  echo ""
  
  local compte_crees=0
  local compte_existants=0
  local compte_erreurs=0
  
  # Lecture du fichier ligne par ligne
  # Utilisation du descripteur de fichier 3 pour éviter les conflits avec stdin
  while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    # Ignorer les lignes vides et les commentaires
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Générer le nom d'utilisateur et le nom d'affichage
    local u gecos
    
    if ! u="$(username_from_line "$line")"; then
      warning "Ligne invalide ignorée : ${BOLD}${line}${NC}"
      compte_erreurs=$((compte_erreurs + 1))
      continue
    fi
    
    gecos="$(display_name_from_line "$line")"
    
    # Générer le mot de passe initial : prenom123
    local prenom_raw pass
    prenom_raw="${line#* }"
    pass="$(sanitize_part_keep_hyphen "$prenom_raw")123"
    
    # Vérifier si l'utilisateur existe déjà
    if id -u "$u" >/dev/null 2>&1; then
      echo -e "  ${YELLOW}⊘${NC} ${BOLD}$u${NC} existe déjà — compte ignoré."
      compte_existants=$((compte_existants + 1))
      continue
    fi
    
    # Création du compte
    echo -e "  ${CYAN}➜${NC} Création de l'utilisateur : ${BOLD}$u${NC} (${gecos})"
    
    if useradd \
      -m -d "$BASE_HOME/$u" \
      -s "$SHELL" \
      -g "$GROUPE" \
      -G "$GROUPE" \
      -c "$gecos" \
      "$u" < /dev/null 2>/dev/null; then
      
      # Définir le mot de passe
      if echo "$u:$pass" | chpasswd 2>/dev/null; then
        # Forcer le changement de mot de passe au premier login
        passwd -e "$u" < /dev/null >/dev/null 2>&1
        
        echo -e "    ${GREEN}✓${NC} Compte créé avec succès ${CYAN}(mot de passe initial : ${BOLD}$pass${NC}${CYAN})${NC}"
        compte_crees=$((compte_crees + 1))
      else
        error "    Échec de la définition du mot de passe pour $u"
        # Supprimer le compte créé partiellement
        userdel -r "$u" 2>/dev/null || true
        compte_erreurs=$((compte_erreurs + 1))
      fi
    else
      error "    Échec de la création du compte $u"
      compte_erreurs=$((compte_erreurs + 1))
    fi
    
  done 3< "$LISTE"
  
  # Affichage du résumé
  echo ""
  separator
  echo -e "  ${BOLD}📊 RÉSUMÉ DE L'OPÉRATION${NC}"
  separator
  echo ""
  echo -e "  ${GREEN}✅ Comptes créés${NC}        : ${BOLD}$compte_crees${NC}"
  echo -e "  ${YELLOW}⊘  Comptes existants${NC}   : ${BOLD}$compte_existants${NC}"
  if [[ $compte_erreurs -gt 0 ]]; then
    echo -e "  ${RED}❌ Erreurs rencontrées${NC}  : ${BOLD}$compte_erreurs${NC}"
  fi
  echo ""
  separator
  
  if [[ $compte_crees -gt 0 ]]; then
    success "Tous les nouveaux comptes ont été ajoutés au groupe '${BOLD}${GROUPE}${NC}'."
    info "Les utilisateurs devront changer leur mot de passe à la première connexion."
  elif [[ $compte_existants -gt 0 && $compte_crees -eq 0 ]]; then
    info "Aucun nouveau compte à créer."
  fi
}

#===============================================================================
# FONCTION 2 : SUPPRESSION DES COMPTES
#===============================================================================

supprimer_comptes() {
  banner "🗑️  SUPPRESSION DES COMPTES ÉLÈVES"
  
  check_liste_file
  
  info "Lecture du fichier : ${BOLD}${LISTE}${NC}"
  local nb_lignes
  nb_lignes=$(grep -cv '^$' "$LISTE" 2>/dev/null || echo "0")
  
  if [[ $nb_lignes -eq 0 ]]; then
    error "Aucune ligne valide trouvée dans le fichier."
    return
  fi
  
  echo -e "  ${BOLD}→${NC} Nombre d'élèves à traiter : ${BOLD}${nb_lignes}${NC}"
  echo ""
  
  separator
  echo -e "${RED}${BOLD}⚠️  ATTENTION : OPÉRATION IRRÉVERSIBLE !${NC}"
  separator
  echo ""
  warning "Cette opération va supprimer définitivement :"
  echo "  • Les comptes utilisateurs"
  echo "  • Les répertoires personnels et leur contenu"
  echo "  • Toutes les données associées"
  echo ""
  
  local confirm
  read -p "$(echo -e ${RED}${BOLD}Êtes-vous CERTAIN de vouloir continuer ? ${NC}${RED}Tapez 'OUI' en majuscules : ${NC}) " -r confirm
  
  if [[ "$confirm" != "OUI" ]]; then
    warning "Opération annulée par sécurité."
    return
  fi
  
  echo ""
  separator
  info "🔄 Traitement des suppressions..."
  separator
  echo ""
  
  local compte_supprimes=0
  local compte_absents=0
  local compte_erreurs=0
  
  # Lecture du fichier ligne par ligne
  while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    # Ignorer les lignes vides et les commentaires
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    local u
    if ! u="$(username_from_line "$line")"; then
      warning "Ligne invalide ignorée : ${BOLD}${line}${NC}"
      continue
    fi
    
    # Vérifier si l'utilisateur existe
    if id -u "$u" >/dev/null 2>&1; then
      echo -e "  ${CYAN}➜${NC} Suppression de l'utilisateur : ${BOLD}$u${NC}"
      
      # Supprimer l'utilisateur et son répertoire personnel
      if userdel -r "$u" < /dev/null 2>/dev/null || userdel "$u" < /dev/null 2>/dev/null; then
        echo -e "    ${GREEN}✓${NC} Compte supprimé avec succès."
        compte_supprimes=$((compte_supprimes + 1))
      else
        error "    Échec de la suppression du compte"
        compte_erreurs=$((compte_erreurs + 1))
      fi
    else
      echo -e "  ${YELLOW}⊘${NC} L'utilisateur ${BOLD}$u${NC} n'existe pas — ignoré."
      compte_absents=$((compte_absents + 1))
    fi
    
  done 3< "$LISTE"
  
  # Affichage du résumé
  echo ""
  separator
  echo -e "  ${BOLD}📊 RÉSUMÉ DE L'OPÉRATION${NC}"
  separator
  echo ""
  echo -e "  ${GREEN}✅ Comptes supprimés${NC}     : ${BOLD}$compte_supprimes${NC}"
  echo -e "  ${YELLOW}⊘  Comptes absents${NC}       : ${BOLD}$compte_absents${NC}"
  if [[ $compte_erreurs -gt 0 ]]; then
    echo -e "  ${RED}❌ Erreurs rencontrées${NC}   : ${BOLD}$compte_erreurs${NC}"
  fi
  echo ""
  separator
  
  if [[ $compte_supprimes -gt 0 ]]; then
    success "Suppression terminée avec succès."
  fi
}

#===============================================================================
# FONCTION 3 : CONFIGURATION DES DROITS SUDO
#===============================================================================

configurer_sudo() {
  banner "🔐 CONFIGURATION DES DROITS SUDO"
  
  info "Cette fonction va autoriser les membres du groupe '${BOLD}${GROUPE}${NC}' à exécuter"
  info "les commandes Proxmox suivantes ${BOLD}avec sudo (sans mot de passe)${NC} :"
  echo ""
  echo -e "  ${CYAN}•${NC} ${BOLD}pveum${NC}           → Proxmox VE User Manager"
  echo -e "  ${CYAN}•${NC} ${BOLD}qm${NC}              → QEMU/KVM Virtual Machine Manager"
  echo -e "  ${CYAN}•${NC} ${BOLD}virt-customize${NC}  → Customisation de VM (libguestfs)"
  echo ""
  
  # Vérifier que le groupe existe
  if ! getent group "$GROUPE" >/dev/null; then
    error "Le groupe '${BOLD}${GROUPE}${NC}' n'existe pas."
    echo ""
    info "Veuillez d'abord créer les comptes avec l'option 1 du menu."
    return
  fi
  
  if ! confirm "Voulez-vous continuer ? (o/N) : "; then
    warning "Opération annulée."
    return
  fi
  
  echo ""
  separator
  info "📝 Création du fichier de configuration sudoers..."
  separator
  echo ""
  
  info "Fichier : ${BOLD}${SUDOERS_FILE}${NC}"
  
  # Créer le fichier sudoers dans /etc/sudoers.d/
  cat > "$SUDOERS_FILE" << 'EOF'
# Configuration sudo pour les élèves Proxmox
# Permet aux membres du groupe 'eleves' d'exécuter certaines commandes Proxmox
# sans avoir besoin de saisir leur mot de passe

# Commandes Proxmox autorisées
Cmnd_Alias PROXMOX_CMDS = /usr/bin/pveum, /usr/sbin/pveum, /usr/sbin/qm, /usr/bin/virt-customize

# Autorisation pour le groupe eleves
%eleves ALL=(ALL) NOPASSWD: PROXMOX_CMDS
EOF
  
  # Définir les bonnes permissions (lecture seule pour root)
  chmod 0440 "$SUDOERS_FILE"
  
  # Vérifier la syntaxe du fichier sudoers
  if visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
    success "Fichier sudoers créé et validé avec succès !"
    echo ""
    separator
    info "Les membres du groupe '${BOLD}${GROUPE}${NC}' peuvent maintenant exécuter :"
    echo ""
    echo -e "  ${GREEN}→${NC} ${BOLD}sudo pveum${NC} [options]"
    echo -e "  ${GREEN}→${NC} ${BOLD}sudo qm${NC} [options]"
    echo -e "  ${GREEN}→${NC} ${BOLD}sudo virt-customize${NC} [options]"
    echo ""
    separator
    success "Configuration terminée avec succès !"
  else
    error "Erreur de syntaxe détectée dans le fichier sudoers !"
    rm -f "$SUDOERS_FILE"
    error "Le fichier a été supprimé pour éviter des problèmes de sécurité."
    return 1
  fi
}

#===============================================================================
# FONCTION 4 : AJOUTER LES UTILISATEURS AU GROUPE ELEVES
#===============================================================================

ajouter_au_groupe() {
  banner "👥 AJOUT DES UTILISATEURS AU GROUPE '${GROUPE}'"
  
  check_liste_file
  
  # Vérifier que le groupe existe
  if ! getent group "$GROUPE" >/dev/null; then
    error "Le groupe '${BOLD}${GROUPE}${NC}' n'existe pas."
    echo ""
    info "Veuillez d'abord créer les comptes avec l'option 1 du menu."
    return
  fi
  
  info "Lecture du fichier : ${BOLD}${LISTE}${NC}"
  local nb_lignes
  nb_lignes=$(grep -cv '^$' "$LISTE" 2>/dev/null || echo "0")
  
  if [[ $nb_lignes -eq 0 ]]; then
    error "Aucune ligne valide trouvée dans le fichier."
    return
  fi
  
  echo -e "  ${BOLD}→${NC} Nombre d'élèves à traiter : ${BOLD}${nb_lignes}${NC}"
  echo ""
  
  if ! confirm "Voulez-vous continuer ? (o/N) : "; then
    warning "Opération annulée."
    return
  fi
  
  echo ""
  separator
  info "🔄 Ajout des utilisateurs au groupe '${BOLD}${GROUPE}${NC}'..."
  separator
  echo ""
  
  local ajoutes=0
  local deja_membres=0
  local inexistants=0
  
  # Lecture du fichier ligne par ligne
  while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    # Ignorer les lignes vides et les commentaires
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    local u
    if ! u="$(username_from_line "$line")"; then
      warning "Ligne invalide ignorée : ${BOLD}${line}${NC}"
      continue
    fi
    
    # Vérifier si l'utilisateur existe
    if ! id -u "$u" >/dev/null 2>&1; then
      echo -e "  ${YELLOW}⊘${NC} L'utilisateur ${BOLD}$u${NC} n'existe pas — ignoré."
      inexistants=$((inexistants + 1))
      continue
    fi
    
    # Vérifier si l'utilisateur est déjà membre du groupe (membre secondaire)
    if getent group "$GROUPE" | grep -q "\b$u\b"; then
      echo -e "  ${BLUE}ℹ${NC}  ${BOLD}$u${NC} est déjà membre du groupe '${GROUPE}'."
      deja_membres=$((deja_membres + 1))
    else
      echo -e "  ${CYAN}➜${NC} Ajout de ${BOLD}$u${NC} au groupe '${GROUPE}'"
      if usermod -aG "$GROUPE" "$u" < /dev/null 2>/dev/null; then
        echo -e "    ${GREEN}✓${NC} Ajouté avec succès."
        ajoutes=$((ajoutes + 1))
      else
        error "    Échec de l'ajout au groupe."
      fi
    fi
    
  done 3< "$LISTE"
  
  # Affichage du résumé
  echo ""
  separator
  echo -e "  ${BOLD}📊 RÉSUMÉ DE L'OPÉRATION${NC}"
  separator
  echo ""
  echo -e "  ${GREEN}✅ Utilisateurs ajoutés${NC}      : ${BOLD}$ajoutes${NC}"
  echo -e "  ${BLUE}ℹ  Déjà membres du groupe${NC}   : ${BOLD}$deja_membres${NC}"
  echo -e "  ${YELLOW}⊘  Utilisateurs inexistants${NC} : ${BOLD}$inexistants${NC}"
  echo ""
  separator
  
  if [[ $ajoutes -gt 0 ]]; then
    success "Les utilisateurs ont été ajoutés au groupe '${BOLD}${GROUPE}${NC}'."
  elif [[ $deja_membres -gt 0 && $ajoutes -eq 0 ]]; then
    info "Tous les utilisateurs sont déjà membres du groupe."
  fi
}

#===============================================================================
# FONCTION 5 : RÉVOCATION DES DROITS SUDO
#===============================================================================

revoquer_sudo() {
  banner "🔒 RÉVOCATION DES DROITS SUDO"
  
  if [[ ! -f "$SUDOERS_FILE" ]]; then
    warning "Le fichier de configuration sudo n'existe pas."
    info "Les droits sudo ne sont pas configurés."
    return
  fi
  
  info "Fichier actuel : ${BOLD}${SUDOERS_FILE}${NC}"
  echo ""
  warning "Cette action va supprimer les droits sudo pour les commandes Proxmox."
  echo ""
  
  if ! confirm "Voulez-vous continuer ? (o/N) : "; then
    warning "Opération annulée."
    return
  fi
  
  echo ""
  
  if rm -f "$SUDOERS_FILE" 2>/dev/null; then
    success "Fichier ${BOLD}${SUDOERS_FILE}${NC} supprimé."
    success "Les droits sudo ont été révoqués avec succès."
  else
    error "Impossible de supprimer le fichier."
    return 1
  fi
}

#===============================================================================
# FONCTION 6 : AFFICHER L'ÉTAT ACTUEL
#===============================================================================

afficher_etat() {
  banner "📋 ÉTAT ACTUEL DU SYSTÈME"
  
  # Vérifier le groupe
  echo -e "${CYAN}${BOLD}━━━ GROUPE '${GROUPE}' ━━━${NC}"
  echo ""
  
  if getent group "$GROUPE" >/dev/null; then
    success "Le groupe '${BOLD}${GROUPE}${NC}' existe."
    
    local membres nb_membres
    membres=$(getent group "$GROUPE" | cut -d: -f4)
    
    if [[ -n "$membres" ]]; then
      nb_membres=$(echo "$membres" | tr ',' '\n' | wc -l)
      echo -e "  ${BOLD}→${NC} Nombre de membres : ${BOLD}${nb_membres}${NC}"
      echo -e "  ${BOLD}→${NC} Liste des membres :"
      echo ""
      echo "$membres" | tr ',' '\n' | while read -r membre; do
        [[ -n "$membre" ]] && echo -e "      ${GREEN}•${NC} $membre"
      done
    else
      info "Aucun membre secondaire dans le groupe."
    fi
  else
    warning "Le groupe '${BOLD}${GROUPE}${NC}' n'existe pas."
  fi
  
  echo ""
  
  # Vérifier les comptes de la liste
  if [[ -f "$LISTE" ]]; then
    echo -e "${CYAN}${BOLD}━━━ COMPTES ÉLÈVES (basés sur ${LISTE}) ━━━${NC}"
    echo ""
    
    local total=0
    local existants=0
    
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      total=$((total + 1))
      
      local u
      if ! u="$(username_from_line "$line")"; then
        continue
      fi
      
      if id -u "$u" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} ${BOLD}$u${NC}"
        existants=$((existants + 1))
      else
        echo -e "  ${RED}✗${NC} ${BOLD}$u${NC} ${YELLOW}(n'existe pas)${NC}"
      fi
    done 3< "$LISTE"
    
    echo ""
    separator
    echo -e "  ${BOLD}Comptes existants : ${GREEN}$existants${NC} / ${BOLD}$total${NC}"
    separator
  else
    warning "Fichier ${BOLD}${LISTE}${NC} introuvable."
  fi
  
  echo ""
  
  # Vérifier la configuration sudo
  echo -e "${CYAN}${BOLD}━━━ CONFIGURATION SUDO ━━━${NC}"
  echo ""
  
  if [[ -f "$SUDOERS_FILE" ]]; then
    success "Configuration sudo active : ${BOLD}${SUDOERS_FILE}${NC}"
    echo ""
    echo -e "  ${BOLD}Contenu :${NC}"
    echo ""
    grep -v '^#' "$SUDOERS_FILE" | grep -v '^$' | while read -r line; do
      echo -e "    ${CYAN}→${NC} $line"
    done || true
  else
    warning "Aucune configuration sudo trouvée."
    info "Utilisez l'option 3 du menu pour configurer les droits sudo."
  fi
  
  echo ""
}

#===============================================================================
# MENU PRINCIPAL
#===============================================================================

afficher_menu() {
  clear
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}                                                                ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}║${NC}     ${BOLD}${CYAN}GESTION DES COMPTES ÉLÈVES - PROXMOX VE${NC}                   ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}║${NC}                                                                ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${CYAN}📝${NC} ${BOLD}1)${NC} Créer les comptes élèves"
  echo -e "  ${RED}🗑️${NC}  ${BOLD}2)${NC} Supprimer les comptes élèves"
  echo -e "  ${GREEN}🔐${NC} ${BOLD}3)${NC} Configurer les droits sudo ${YELLOW}(pveum, qm, virt-customize)${NC}"
  echo -e "  ${BLUE}👥${NC} ${BOLD}4)${NC} Ajouter les utilisateurs au groupe '${CYAN}eleves${NC}'"
  echo -e "  ${YELLOW}🔒${NC} ${BOLD}5)${NC} Révoquer les droits sudo"
  echo -e "  ${MAGENTA}📋${NC} ${BOLD}6)${NC} Afficher l'état actuel du système"
  echo -e "  ${RED}🚪${NC} ${BOLD}7)${NC} Quitter"
  echo ""
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  echo ""
}

#===============================================================================
# POINT D'ENTRÉE PRINCIPAL
#===============================================================================

main() {
  # Vérifier les privilèges root
  check_root
  
  # Afficher un message de bienvenue
  clear
  echo ""
  echo -e "${GREEN}${BOLD}✨ Bienvenue dans le gestionnaire de comptes Proxmox VE ✨${NC}"
  echo ""
  sleep 1
  
  # Boucle principale du menu
  while true; do
    afficher_menu
    read -p "$(echo -e ${BOLD}Votre choix : ${NC}) " -r choix
    echo ""
    
    case "$choix" in
      1)
        creer_comptes
        pause
        ;;
      2)
        supprimer_comptes
        pause
        ;;
      3)
        configurer_sudo
        pause
        ;;
      4)
        ajouter_au_groupe
        pause
        ;;
      5)
        revoquer_sudo
        pause
        ;;
      6)
        afficher_etat
        pause
        ;;
      7)
        clear
        echo ""
        echo -e "${GREEN}${BOLD}👋 Merci d'avoir utilisé ce script !${NC}"
        echo ""
        echo -e "${CYAN}Au revoir et à bientôt ! 🚀${NC}"
        echo ""
        exit 0
        ;;
      *)
        error "Choix invalide ! Veuillez saisir un nombre entre 1 et 7."
        sleep 2
        ;;
    esac
  done
}

# Lancement du script
main "$@"
