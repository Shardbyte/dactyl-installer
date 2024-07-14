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
