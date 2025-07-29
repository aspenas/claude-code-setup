#!/bin/bash
echo "Checking DNS propagation..."
dig +short jonathon.candlefish.ai
echo
echo "Testing HTTPS access..."
curl -I https://jonathon.candlefish.ai 2>/dev/null | head -n 1
