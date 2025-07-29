#!/bin/bash
echo "Checking DNS status for jonathon.candlefish.ai..."
echo
echo "1. DNS Resolution:"
dig +short CNAME jonathon.candlefish.ai
echo
echo "2. Full DNS Query:"
dig jonathon.candlefish.ai
echo
echo "3. HTTPS Status:"
curl -I https://jonathon.candlefish.ai 2>&1 | head -10
echo
echo "4. Direct Netlify Access:"
curl -I https://zippy-macaron-c28bbf.netlify.app 2>&1 | head -5
