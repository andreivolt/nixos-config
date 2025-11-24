# NixOS Impermanence Setup Guide

This configuration implements an impermanent root filesystem with persistent storage for important data using tmpfs, LUKS encryption, and Btrfs subvolumes.

## System Architecture

### Filesystem Layout
- **Root (`/`)**: tmpfs (3GB) - Wiped on every reboot
- **Home (`/home`)**: Persistent Btrfs subvolume
- **Nix Store (`/nix`)**: Persistent Btrfs subvolume
- **Persistent Data (`/persist`)**: Persistent Btrfs subvolume for system state
- **Logs (`/var/log`)**: Persistent Btrfs subvolume
- **Swap**: Btrfs swapfile (8GB default)
- **Boot (`/boot`)**: EFI System Partition (512MB)

### Encryption
- Full disk encryption using LUKS2
- Performance optimizations for SSDs enabled

## Installation Instructions

### Prerequisites
- **IMPORTANT**: This setup requires a fresh installation and will **wipe your disk**
- Back up all important data before proceeding
- Boot from a NixOS installation ISO

### Step 1: Configure Your Disk Device

Edit `flake.nix` and set the correct disk device for your machine:

```nix
nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
  modules = [
    {
      # Change this to match your disk
      nixos.diskDevice = "/dev/nvme0n1";  # or "/dev/sda" for SATA drives
    }
    # ...
  ];
};
```

### Step 2: Prepare the Installation Environment

Boot the NixOS installer and run:

```bash
# Install git and other tools
nix-shell -p git

# Clone your configuration
git clone https://github.com/yourusername/nixos-config /mnt/config
cd /mnt/config

# Enable flakes in the installer
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### Step 3: Partition and Format the Disk

The disko module will handle partitioning automatically:

```bash
# This will partition and format your disk according to the configuration
# WARNING: This will ERASE your disk!
sudo nix run github:nix-community/disko -- --mode disko --flake .#nixos
```

You will be prompted to enter a LUKS encryption password. Choose a strong password and remember it!

### Step 4: Install NixOS

```bash
# Mount the filesystems (if not already mounted by disko)
sudo mount /dev/mapper/cryptroot /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot  # Adjust device name

# Copy your configuration
sudo cp -r /mnt/config /mnt/etc/nixos

# Set up user password
sudo mkdir -p /mnt/persist/passwords
echo -n "your-password-hash" | sudo tee /mnt/persist/passwords/andrei
sudo chmod 600 /mnt/persist/passwords/andrei

# Or use the helper script after installation:
# sudo init-user-password

# Install NixOS
sudo nixos-install --flake /mnt/etc/nixos#nixos
```

### Step 5: Post-Installation

After rebooting into your new system:

1. **Set User Password** (if not done during installation):
   ```bash
   sudo init-user-password
   ```

2. **Configure Git** (will persist in /persist):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. **SSH Keys**: Place in `~/.ssh/` (will be symlinked to `/persist`)

## Persistence Configuration

### What Persists Automatically

**System State** (`/persist`):
- Network connections
- Bluetooth devices
- SSH host keys
- Machine ID
- NixOS configuration (`/etc/nixos`)
- Docker/container data
- System logs

**User Data** (`/home/andrei` - entire home is persistent):
- All user files and directories
- Application configurations
- Development projects
- Downloads, Documents, etc.

### Adding More Persistent Paths

Edit `linux/users-persist.nix` to add more directories or files:

```nix
environment.persistence."/persist".users.andrei = {
  directories = [
    ".new-app-config"
    "my-important-directory"
  ];
  files = [
    ".important-file"
  ];
};
```

## Maintenance

### Checking Disk Usage

```bash
# Check tmpfs root usage
df -h /

# Check Btrfs usage
sudo btrfs filesystem usage /

# Check compression ratio
sudo compsize /
```

### BTRFS Maintenance

Automatic monthly scrubs are configured. Manual scrub:

```bash
sudo btrfs scrub start /
sudo btrfs scrub status /
```

### System Cleanup

Since root is tmpfs, temporary files are automatically cleaned on reboot. To clean persistent data:

```bash
# Clean old NixOS generations
sudo nix-collect-garbage -d

# Clean user cache (be careful)
rm -rf ~/.cache/*
```

## Troubleshooting

### Forgot LUKS Password
Unfortunately, there's no recovery. You'll need to reinstall.

### Running Out of tmpfs Space
The root tmpfs is set to 3GB. If you need more:
1. Edit `linux/impermanence.nix`
2. Change `size=3G` to a larger value
3. Rebuild: `sudo nixos-rebuild switch`

### Password File Issues
If you can't log in:
1. Boot from installer ISO
2. Mount and unlock your encrypted disk
3. Create password file manually in `/persist/passwords/andrei`

## Benefits of This Setup

1. **Security**: Malware can't persist across reboots
2. **Reproducibility**: System state is always clean
3. **Performance**: tmpfs root is very fast
4. **Clarity**: Explicitly declared what should persist
5. **Rollback**: Easy to revert to previous configurations

## Important Notes

- Always test configuration changes in a VM first if possible
- Keep backups of `/persist` data
- Document any machine-specific settings
- The swap file size (8GB) can be adjusted in `disk-config.nix`