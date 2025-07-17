# Updating the instance manager
sudo su -l
getamp update

sudo apt upgrade ampinstmgr

# Updating your AMP instances
su -l amp
ampinstmgr upgradeall
ampinstmgr upgrade ADS
