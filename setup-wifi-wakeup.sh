#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for dry-run mode or help
DRY_RUN=0
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [--dry-run|-n]"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n    Run in dry-run mode (show what would be done without making changes)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "This script sets up the WiFi wake-up workaround for immutable distros by:"
    echo "  1. Detecting your WiFi PCI device"
    echo "  2. Creating /usr/local/bin/wifi-pci-reset.sh"
    echo "  3. Creating /etc/systemd/system/pci-reset.service"
    echo "  4. Enabling the systemd service"
    exit 0
fi

if [[ "$1" == "--dry-run" ]] || [[ "$1" == "-n" ]]; then
    DRY_RUN=1
    echo -e "${BLUE}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

echo "WiFi wake-up workaround setup for immutable distros"
echo "===================================================="
echo ""

# Check if running as root (skip in dry-run mode)
if [ "$DRY_RUN" -eq 0 ] && [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Find network adapters
echo "Detecting network adapters..."
NETWORK_DEVICES=$(lspci | grep -iE "network|ethernet|wireless" || true)

if [ -z "$NETWORK_DEVICES" ]; then
    echo -e "${RED}Error: No network adapters found${NC}"
    exit 1
fi

# Count devices and extract PCI IDs
DEVICE_COUNT=$(echo "$NETWORK_DEVICES" | wc -l)
PCI_IDS=()
DEVICE_DESCRIPTIONS=()

while IFS= read -r line; do
    # Extract PCI ID (format: 0000:XX:XX.X or XX:XX.X)
    # Try full format first, then short format
    PCI_ID=$(echo "$line" | grep -oE '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' || true)
    if [ -z "$PCI_ID" ]; then
        # Try short format without domain
        PCI_ID=$(echo "$line" | grep -oE '[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]' || true)
    fi
    if [ -n "$PCI_ID" ]; then
        # Normalize to full format (add 0000: prefix if missing)
        if [[ ! "$PCI_ID" =~ ^0000: ]]; then
            PCI_ID="0000:$PCI_ID"
        fi
        PCI_IDS+=("$PCI_ID")
        # Get device description (everything after the PCI ID)
        # Remove the PCI ID part (handle both formats)
        if [[ "$line" =~ ^[0-9a-f]{4}: ]]; then
            DESC=$(echo "$line" | sed -E "s/^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f] //")
        else
            DESC=$(echo "$line" | sed -E "s/^[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f] //")
        fi
        DEVICE_DESCRIPTIONS+=("$DESC")
    fi
done <<< "$NETWORK_DEVICES"

if [ ${#PCI_IDS[@]} -eq 0 ]; then
    echo -e "${RED}Error: Could not extract PCI IDs from network devices${NC}"
    exit 1
fi

# If multiple devices found, prompt user to choose
SELECTED_PCI=""
if [ ${#PCI_IDS[@]} -eq 1 ]; then
    SELECTED_PCI="${PCI_IDS[0]}"
    echo -e "${GREEN}Found network adapter:${NC}"
    echo "  PCI ID: $SELECTED_PCI"
    echo "  Description: ${DEVICE_DESCRIPTIONS[0]}"
    echo ""
else
    echo -e "${YELLOW}Multiple network adapters found. Please select one:${NC}"
    echo ""
    for i in "${!PCI_IDS[@]}"; do
        echo "  $((i+1)). ${PCI_IDS[$i]} - ${DEVICE_DESCRIPTIONS[$i]}"
    done
    echo ""
    
    while true; do
        read -p "Enter number (1-${#PCI_IDS[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#PCI_IDS[@]} ]; then
            SELECTED_PCI="${PCI_IDS[$((choice-1))]}"
            echo ""
            echo -e "${GREEN}Selected: $SELECTED_PCI - ${DEVICE_DESCRIPTIONS[$((choice-1))]}${NC}"
            echo ""
            break
        else
            echo -e "${RED}Invalid choice. Please enter a number between 1 and ${#PCI_IDS[@]}.${NC}"
        fi
    done
fi

# Verify the PCI device exists
if [ ! -e "/sys/bus/pci/devices/$SELECTED_PCI" ]; then
    echo -e "${RED}Error: PCI device $SELECTED_PCI not found in /sys/bus/pci/devices/${NC}"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p /usr/local/bin
else
    echo -e "${BLUE}[DRY RUN] Would create /usr/local/bin if it doesn't exist${NC}"
fi

# Create the reset script
if [ "$DRY_RUN" -eq 0 ]; then
    echo "Creating /usr/local/bin/wifi-pci-reset.sh..."
    cat > /usr/local/bin/wifi-pci-reset.sh << 'SCRIPT_EOF'
#!/bin/sh
PCI="PCI_PLACEHOLDER"
ACTION="$1"

# Use logger instead of file writes—journal is always writable
logger -t pci-reset "Running $ACTION hook"

case "$ACTION" in
  pre)
    [ -e "/sys/bus/pci/devices/$PCI" ] && echo 1 > "/sys/bus/pci/devices/$PCI/remove"
    ;;
  post)
    sleep 3
    echo 1 > /sys/bus/pci/rescan
    ;;
esac
SCRIPT_EOF

    # Replace the placeholder with the actual PCI ID
    sed -i "s/PCI_PLACEHOLDER/$SELECTED_PCI/" /usr/local/bin/wifi-pci-reset.sh

    # Make the script executable
    chmod +x /usr/local/bin/wifi-pci-reset.sh
    echo -e "${GREEN}✓ Created and made executable: /usr/local/bin/wifi-pci-reset.sh${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would create /usr/local/bin/wifi-pci-reset.sh with:${NC}"
    echo -e "${BLUE}  PCI=\"$SELECTED_PCI\"${NC}"
    echo -e "${BLUE}  (script content would be written as shown above)${NC}"
fi

# Create the systemd service
if [ "$DRY_RUN" -eq 0 ]; then
    echo "Creating /etc/systemd/system/pci-reset.service..."
    cat > /etc/systemd/system/pci-reset.service << 'SERVICE_EOF'
[Unit]
Description=Reset Wi-Fi PCI on suspend/resume
Before=suspend.target hibernate.target hybrid-sleep.target
StopWhenUnneeded=yes

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/wifi-pci-reset.sh pre
ExecStop=/usr/local/bin/wifi-pci-reset.sh post

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target
SERVICE_EOF

    echo -e "${GREEN}✓ Created: /etc/systemd/system/pci-reset.service${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would create /etc/systemd/system/pci-reset.service${NC}"
    echo -e "${BLUE}  (systemd service file content would be written as shown above)${NC}"
fi

# Reload systemd and enable the service
if [ "$DRY_RUN" -eq 0 ]; then
    echo ""
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"

    echo "Enabling pci-reset.service..."
    systemctl enable pci-reset.service
    echo -e "${GREEN}✓ Service enabled${NC}"

    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "The WiFi wake-up workaround is now configured and will automatically"
    echo "reset the WiFi PCI device on suspend/resume."
    echo ""
    echo "To test, you can manually run:"
    echo "  sudo /usr/local/bin/wifi-pci-reset.sh pre"
    echo "  sudo /usr/local/bin/wifi-pci-reset.sh post"
    echo ""
    echo "To check service status:"
    echo "  sudo systemctl status pci-reset.service"
else
    echo ""
    echo -e "${BLUE}[DRY RUN] Would run: systemctl daemon-reload${NC}"
    echo -e "${BLUE}[DRY RUN] Would run: systemctl enable pci-reset.service${NC}"
    echo ""
    echo -e "${YELLOW}Dry run complete! No changes were made.${NC}"
    echo ""
    echo "To actually apply these changes, run the script without --dry-run:"
    echo "  sudo ./setup-wifi-wakeup.sh"
fi

