#!/usr/bin/env bash
###########################
#                         #
#  Saint @ Shardbyte.com  #
#                         #
###########################
# Copyright (c) 2023-2024 Shardbyte
# Author: Shardbyte (Saint) <shard@shardbyte.com>
# License: MIT
# https://github.com/Shardbyte/dactyl-installer/raw/master/LICENSE
######  BEGIN FILE  ###### ######  BEGIN FILE  ###### ######  BEGIN FILE  ######
# This script is NOT associated with the Official Pterodactyl Project.
# Project "dactyl-installer" (https://github.com/Shardbyte/dactyl-installer)
#
#

set -e

# Check if script is loaded, load if not or fail otherwise.
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERROR: Could not load lib script" && exit 1
fi

# ------------------ Variables ----------------- #

RM_PANEL="${RM_PANEL:-true}"
RM_WINGS="${RM_WINGS:-true}"

# ---------- Uninstallation functions ---------- #

rm_panel_files() {
  output "Removing panel files..."
  rm -rf /var/www/pterodactyl /usr/local/bin/composer
  [ "$OS" != "centos" ] && [ "$OS" != "fedora" ] && unlink /etc/nginx/sites-enabled/pterodactyl.conf
  [ "$OS" != "centos" ] && [ "$OS" != "fedora" ] && rm -f /etc/nginx/sites-available/pterodactyl.conf
  [ "$OS" != "centos" ] && [ "$OS" != "fedora" ] && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
  [ "$OS" == "centos" ] || [ "$OS" == "fedora" ] && rm -f /etc/nginx/conf.d/pterodactyl.conf
  systemctl restart nginx
  success "Removed panel files."
}

rm_docker_containers() {
  output "Removing docker containers and images..."

  docker system prune -a -f

  success "Removed docker containers and images."
}

rm_wings_files() {
  output "Removing wings files..."

  # stop and remove wings service
  systemctl disable --now wings
  rm -rf /etc/systemd/system/wings.service

  rm -rf /etc/pterodactyl /usr/local/bin/wings /var/lib/pterodactyl
  success "Removed wings files."
}

rm_services() {
  output "Removing services..."
  systemctl disable --now pteroq
  rm -rf /etc/systemd/system/pteroq.service
  case "$OS" in
  debian | ubuntu)
    systemctl disable --now redis-server
    ;;
  centos | fedora)
    systemctl disable --now redis
    systemctl disable --now php-fpm
    rm -rf /etc/php-fpm.d/www-pterodactyl.conf
    ;;
  esac
  success "Removed services."
}

rm_cron() {
  output "Removing cron jobs..."
  crontab -l | grep -vF "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" | crontab -
  success "Removed cron jobs."
}

rm_database() {
  output "Removing database..."
  valid_db=$(mariadb -u root -e "SELECT schema_name FROM information_schema.schemata;" | grep -v -E -- 'schema_name|information_schema|performance_schema|mysql')
  warning "Be careful! This database will be deleted!"
  if [[ "$valid_db" == *"panel"* ]]; then
    echo -n "* Database called panel has been detected. Is it the pterodactyl database? (y/N): "
    read -r is_panel
    if [[ "$is_panel" =~ [Yy] ]]; then
      DATABASE=panel
    else
      print_list "$valid_db"
    fi
  else
    print_list "$valid_db"
  fi
  while [ -z "$DATABASE" ] || [[ $valid_db != *"$database_input"* ]]; do
    echo -n "* Choose the panel database (to skip don't input anything): "
    read -r database_input
    if [[ -n "$database_input" ]]; then
      DATABASE="$database_input"
    else
      break
    fi
  done
  [[ -n "$DATABASE" ]] && mariadb -u root -e "DROP DATABASE $DATABASE;"
  # Exclude usernames User and root (Hope no one uses username User)
  output "Removing database user..."
  valid_users=$(mariadb -u root -e "SELECT user FROM mysql.user;" | grep -v -E -- 'user|root')
  warning "Be careful! This user will be deleted!"
  if [[ "$valid_users" == *"pterodactyl"* ]]; then
    echo -n "* User called pterodactyl has been detected. Is it the pterodactyl user? (y/N): "
    read -r is_user
    if [[ "$is_user" =~ [Yy] ]]; then
      DB_USER=pterodactyl
    else
      print_list "$valid_users"
    fi
  else
    print_list "$valid_users"
  fi
  while [ -z "$DB_USER" ] || [[ $valid_users != *"$user_input"* ]]; do
    echo -n "* Choose the panel user (to skip don't input anything): "
    read -r user_input
    if [[ -n "$user_input" ]]; then
      DB_USER=$user_input
    else
      break
    fi
  done
  [[ -n "$DB_USER" ]] && mariadb -u root -e "DROP USER $DB_USER@'127.0.0.1';"
  mariadb -u root -e "FLUSH PRIVILEGES;"
  success "Removed database and database user."
}

# --------------- Main functions --------------- #

perform_uninstall() {
  [ "$RM_PANEL" == true ] && rm_panel_files
  [ "$RM_PANEL" == true ] && rm_cron
  [ "$RM_PANEL" == true ] && rm_database
  [ "$RM_PANEL" == true ] && rm_services
  [ "$RM_WINGS" == true ] && rm_docker_containers
  [ "$RM_WINGS" == true ] && rm_wings_files

  return 0
}

# ------------------ Uninstall ----------------- #

perform_uninstall
