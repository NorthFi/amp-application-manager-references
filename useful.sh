# Updating the instance manager
sudo su -l
getamp update

sudo apt upgrade ampinstmgr

# Updating your AMP instances
su -l amp
ampinstmgr upgradeall
ampinstmgr upgrade ADS


#!/bin/bash
# /usr/local/bin/update_amp.sh
# Script to update system and AMP cleanly

set -e  # Exit immediately if a command fails

echo "=== Updating system packages ==="
apt update && apt upgrade -y
apt dist-upgrade -y

echo "=== System upgrade done ==="

echo "=== Updating AMP core (requires root) ==="
getamp update

echo "=== Updating ampinstmgr (root required) ==="
apt upgrade ampinstmgr -y

echo "=== Checking AMP instances ==="
sudo -u amp ampinstmgr status

echo "=== Upgrading all AMP instances ==="
sudo -u amp ampinstmgr upgradeall

echo "=== AMP update complete! ==="
