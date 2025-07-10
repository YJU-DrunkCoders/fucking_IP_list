#!/bin/bash
# UFW IP DENY SCRIPT

LIST_FILE="list.txt"

# Check if the list file exists
if [[ ! -f "$LIST_FILE" ]]; then
    echo "Error: $LIST_FILE is not found."
    exit 1
fi

# Check UFW status
if ! command -v ufw &> /dev/null; then
    echo "Error: UFW is not installed."
    exit 1
fi

# Get existing UFW rules (for caching)
echo "Checking existing UFW rules..."
existing_rules=$(sudo ufw status numbered | grep -E "DENY IN.*Anywhere" | awk '{print $4}' | sort | uniq)

counter=0
skipped=0
added=0

echo "========================================="
echo "Starting UFW IP deny script..."
echo "========================================="

# Read IP addresses from list.txt
while IFS= read -r line; do
    # Skip empty lines, comments (#), and lines with only whitespace
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
        continue
    fi

    # Remove leading and trailing whitespace
    ip=$(echo "$line" | xargs)

    # IP address format validation (IPv4 or CIDR notation)
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        echo "Warning: Invalid IP format skipped : $ip"
        continue
    fi
    
    counter=$((counter+1))
    
    echo "---------------"
    echo "$counter - $ip"

    # Check if the IP is already denied
    if echo "$existing_rules" | grep -q "^$ip$"; then
        echo "IP $ip is already denied. (skipped)"
        skipped=$((skipped+1))
    else
        # Apply UFW rule
        if sudo ufw deny from "$ip"; then
            echo "IP $ip is successfully denied."
            added=$((added+1))
            # Add newly added rule to cache
            existing_rules="$existing_rules"$'\n'"$ip"
        else
            echo "Error: IP $ip deny failed."
        fi
    fi
    
    echo "---------------"
    
done < "$LIST_FILE"

echo "========================================="
echo "Processing complete!"
echo "Total processed IPs: $counter"
echo "Newly added rules: $added"
echo "Skipped rules: $skipped"
echo "========================================="

# Check UFW status
echo ""
echo "Current UFW status:"
sudo ufw status numbered