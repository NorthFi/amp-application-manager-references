# AMP Application Manager - Complete Guide

![AMP Logo](https://cubecoders.com/assets/images/CubeCoders_White.webp)

A comprehensive guide and reference for managing AMP (Application Management Panel) instances from [CubeCoders](https://cubecoders.com/).

## 🚀 Quick Reference

### Essential Commands Cheat Sheet

```bash
# Switch to root user
sudo su -l

# Switch to AMP user
su -l amp

# Check AMP status
ampinstmgr status

# List all instances
ampinstmgr list

# Start/Stop/Restart instance
ampinstmgr start [instance_name]
ampinstmgr stop [instance_name]
ampinstmgr restart [instance_name]
```

## 🔧 Installation

### Prerequisites
- Ubuntu/Debian Linux system
- Root access
- Valid AMP license from [CubeCoders](https://cubecoders.com/)

### Installation Steps

1. **Download and run the installer:**
   ```bash
   wget -O getamp.sh https://cubecoders.com/getamp.sh
   bash getamp.sh
   ```

2. **Follow the installation wizard**
   - Accept license agreement
   - Choose installation directory (default: `/opt/cubecoders/amp`)
   - Set up the `amp` user account
   - Configure firewall settings

3. **Initial setup:**
   ```bash
   # Switch to AMP user
   su -l amp
   
   # Create your first instance (ADS - Application Data Service)
   ampinstmgr CreateInstance ADS01 ADS "Your ADS Instance"
   
   # Start the instance
   ampinstmgr start ADS01
   ```

## 📅 Daily Operations

### Starting Your Day
```bash
# Check system status
sudo su -l
systemctl status ampinstmgr

# Switch to AMP user and check instances
su -l amp
ampinstmgr status
```

### Common Tasks
- **View running instances:** `ampinstmgr list`
- **Check instance logs:** `ampinstmgr logs [instance_name]`
- **Monitor resource usage:** `ampinstmgr show [instance_name]`

## 🔄 Update Procedures

### Updating the Instance Manager

```bash
# Switch to root user
sudo su -l

# Update AMP core
getamp update

# Update the instance manager package
sudo apt upgrade ampinstmgr
```

### Updating AMP Instances

```bash
# Switch to AMP user
su -l amp

# Update all instances
ampinstmgr upgradeall

# Update specific instance (like ADS)
ampinstmgr upgrade ADS

# Update specific named instance
ampinstmgr upgrade [instance_name]
```

### Post-Update Checklist
- [ ] Verify all instances are running
- [ ] Check instance logs for errors
- [ ] Test web panel access
- [ ] Verify game server connectivity (if applicable)

## 🎮 Instance Management

### Creating New Instances

```bash
# Generic syntax
ampinstmgr CreateInstance [friendly_name] [module] [display_name] [host_ip] [port]

# Examples
ampinstmgr CreateInstance Minecraft01 Minecraft "My Minecraft Server"
ampinstmgr CreateInstance Valheim01 Valheim "Valheim Server"
ampinstmgr CreateInstance Steam01 steamcmdds "Steam Game Server"
```

### Instance Operations

```bash
# Start instance
ampinstmgr start [instance_name]

# Stop instance
ampinstmgr stop [instance_name]

# Restart instance
ampinstmgr restart [instance_name]

# Delete instance (careful!)
ampinstmgr DeleteInstance [instance_name]

# Show instance info
ampinstmgr show [instance_name]
```

## 🔍 Troubleshooting

### Common Issues

#### Instance Won't Start
```bash
# Check logs
ampinstmgr logs [instance_name]

# Check system resources
free -h
df -h

# Verify permissions
ls -la /opt/cubecoders/amp/instances/
```

#### Web Panel Not Accessible
```bash
# Check if instance is running
ampinstmgr status

# Verify firewall settings
sudo ufw status
sudo iptables -L

# Check port bindings
netstat -tlnp | grep [port_number]
```

#### Performance Issues
```bash
# Check system load
top
htop

# Check disk usage
df -h
du -sh /opt/cubecoders/amp/instances/*

# Monitor memory usage
free -h
```

### Log Locations

- **Instance logs:** `/opt/cubecoders/amp/instances/[instance_name]/logs/`
- **AMP system logs:** `/opt/cubecoders/amp/logs/`
- **System logs:** `/var/log/syslog`

## 📚 Useful Resources

### Official Documentation
- [CubeCoders AMP Documentation](https://github.com/CubeCoders/AMP/wiki)
- [AMP Command Reference](https://github.com/CubeCoders/AMP/wiki/Command-Reference)
- [Module Documentation](https://github.com/CubeCoders/AMP/wiki/Module-Documentation)

### Community Resources
- [AMP Discord Server](https://discord.gg/cubecoders)
- [Reddit r/AMP](https://reddit.com/r/AMP)
- [Support Portal](https://support.cubecoders.com/)

### Helpful Tools
- [AMP Instance Manager GUI](https://github.com/CubeCoders/AMP/wiki/Web-Interface)
- [AMP API Documentation](https://github.com/CubeCoders/AMP/wiki/API-Documentation)

## 📁 Configuration Files

### Important File Locations

```bash
# Main AMP configuration
/opt/cubecoders/amp/ampinstmgr.conf

# Instance configurations
/opt/cubecoders/amp/instances/[instance_name]/

# User data
/home/amp/

# Service files
/etc/systemd/system/ampinstmgr.service
```

### Key Configuration Options

```ini
# ampinstmgr.conf example settings
[General]
DataPath=/opt/cubecoders/amp/instances/
LogPath=/opt/cubecoders/amp/logs/
BackupPath=/opt/cubecoders/amp/backups/

[Security]
EnableSSL=true
SSLCertPath=/path/to/cert.pem
SSLKeyPath=/path/to/key.pem
```

## 🔒 Security

### Best Practices

1. **Keep AMP Updated**
   ```bash
   # Regular update schedule
   sudo su -l && getamp update
   su -l amp && ampinstmgr upgradeall
   ```

2. **Firewall Configuration**
   ```bash
   # Allow only necessary ports
   sudo ufw allow 8080/tcp  # AMP web panel
   sudo ufw allow 25565/tcp # Minecraft (example)
   ```

3. **User Management**
   ```bash
   # Don't run as root
   # Always use the 'amp' user for operations
   su -l amp
   ```

4. **Regular Backups**
   ```bash
   # Backup instance data
   ampinstmgr backup [instance_name]
   ```

## 💾 Backup Procedures

### Manual Backup

```bash
# Switch to AMP user
su -l amp

# Backup specific instance
ampinstmgr backup [instance_name]

# Backup all instances
ampinstmgr backupall

# List available backups
ampinstmgr listbackups [instance_name]
```

### Automated Backup Script

```bash
#!/bin/bash
# Save as /home/amp/backup_script.sh

# Switch to AMP user context
su -l amp -c "
    echo 'Starting daily backup...'
    ampinstmgr backupall
    echo 'Backup completed at $(date)'
"
```

### Restore from Backup

```bash
# List available backups
ampinstmgr listbackups [instance_name]

# Restore from backup
ampinstmgr restore [instance_name] [backup_file]
```

## 🛠️ Advanced Usage

### API Integration

```bash
# Get instance status via API
curl -X GET "http://your-server:8080/API/Core/GetStatus" \
  -H "accept: application/json" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN"
```

### Custom Scripts

```bash
# Example: Auto-restart script
#!/bin/bash
# Place in /home/amp/scripts/auto_restart.sh

INSTANCE_NAME="Minecraft01"
su -l amp -c "
    ampinstmgr stop $INSTANCE_NAME
    sleep 10
    ampinstmgr start $INSTANCE_NAME
"
```

## 📞 Support

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Review instance logs
3. Visit the [CubeCoders Support Portal](https://support.cubecoders.com/)
4. Join the [Discord community](https://discord.gg/cubecoders)

## 📜 License

This guide is for use with your licensed AMP software from [CubeCoders](https://cubecoders.com/).

---

**Remember:** Always backup your instances before making major changes!

> 💡 **Pro Tip:** Bookmark this README and keep your AMP license information handy for quick reference.

## 🔖 Quick Command Reference Card

| Task | Command |
|------|---------|
| Switch to root | `sudo su -l` |
| Switch to AMP user | `su -l amp` |
| Update AMP core | `getamp update` |
| Update instance manager | `sudo apt upgrade ampinstmgr` |
| Update all instances | `ampinstmgr upgradeall` |
| Update ADS | `ampinstmgr upgrade ADS` |
| List instances | `ampinstmgr list` |
| Check status | `ampinstmgr status` |
| Start instance | `ampinstmgr start [name]` |
| Stop instance | `ampinstmgr stop [name]` |
| View logs | `ampinstmgr logs [name]` |
| Backup instance | `ampinstmgr backup [name]` |

**Last Updated:** $(date)
