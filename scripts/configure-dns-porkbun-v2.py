#!/usr/bin/env python3
"""
Robust DNS Configuration for jonathon.candlefish.ai using Porkbun API
Author: Patrick Smith (patrick@candlefish.ai)
"""

import json
import sys
import time
import subprocess
import requests
from typing import Dict, Optional, Tuple

# Colors for terminal output
class Colors:
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'

def log(msg: str, color: str = Colors.GREEN):
    """Log message with timestamp and color"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    print(f"{color}[{timestamp}]{Colors.NC} {msg}")

def error(msg: str):
    """Log error and exit"""
    log(f"ERROR: {msg}", Colors.RED)
    sys.exit(1)

def info(msg: str):
    """Log info message"""
    log(msg, Colors.BLUE)

def warning(msg: str):
    """Log warning message"""
    log(msg, Colors.YELLOW)

def get_porkbun_credentials() -> Tuple[str, str]:
    """Retrieve Porkbun API credentials from AWS Secrets Manager"""
    try:
        result = subprocess.run(
            ['aws', 'secretsmanager', 'get-secret-value', 
             '--secret-id', 'porkbun/api-credentials',
             '--query', 'SecretString', '--output', 'text'],
            capture_output=True, text=True, check=True
        )
        
        creds = json.loads(result.stdout)
        api_key = creds.get('api_key', '').strip()
        secret_key = creds.get('secret_key', '').strip()
        
        if not api_key or not secret_key:
            error("Missing API credentials in AWS Secrets")
            
        return api_key, secret_key
        
    except subprocess.CalledProcessError as e:
        error(f"Failed to retrieve credentials from AWS: {e}")
    except json.JSONDecodeError as e:
        error(f"Failed to parse credentials: {e}")

class PorkbunDNS:
    """Porkbun DNS API Client"""
    
    BASE_URL = "https://api.porkbun.com/api/json/v3"
    
    def __init__(self, api_key: str, secret_key: str):
        self.api_key = api_key
        self.secret_key = secret_key
        self.domain = "candlefish.ai"
        self.subdomain = "jonathon"
        self.target = "zippy-macaron-c28bbf.netlify.app"
        
    def _make_request(self, endpoint: str, data: Dict) -> Dict:
        """Make API request with proper error handling"""
        url = f"{self.BASE_URL}/{endpoint}"
        
        # Add authentication to data
        data.update({
            "apikey": self.api_key,
            "secretapikey": self.secret_key
        })
        
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        try:
            response = requests.post(url, json=data, headers=headers, timeout=30)
            result = response.json()
            
            # Check for API-level errors
            if result.get('status') == 'ERROR':
                return {'status': 'ERROR', 'message': result.get('message', 'Unknown error')}
                
            return result
            
        except requests.exceptions.RequestException as e:
            return {'status': 'ERROR', 'message': f"Request failed: {str(e)}"}
        except json.JSONDecodeError:
            return {'status': 'ERROR', 'message': f"Invalid JSON response: {response.text}"}
    
    def test_authentication(self) -> bool:
        """Test if credentials are valid"""
        info("Testing Porkbun API authentication...")
        
        result = self._make_request("ping", {})
        
        if result.get('status') == 'SUCCESS':
            log("✅ Authentication successful!")
            return True
        else:
            warning(f"Authentication test failed: {result.get('message', 'Unknown error')}")
            return False
    
    def get_dns_records(self) -> Optional[list]:
        """Retrieve all DNS records for the domain"""
        info(f"Fetching DNS records for {self.domain}...")
        
        result = self._make_request(f"dns/retrieve/{self.domain}", {})
        
        if result.get('status') == 'SUCCESS':
            records = result.get('records', [])
            log(f"Found {len(records)} DNS records")
            return records
        else:
            warning(f"Failed to retrieve records: {result.get('message')}")
            return None
    
    def find_existing_record(self, records: list) -> Optional[Dict]:
        """Find existing CNAME record for subdomain"""
        full_name = f"{self.subdomain}.{self.domain}"
        
        for record in records:
            if (record.get('name') == full_name and 
                record.get('type') == 'CNAME'):
                return record
        return None
    
    def create_cname_record(self) -> bool:
        """Create new CNAME record"""
        log(f"Creating CNAME record: {self.subdomain}.{self.domain} -> {self.target}")
        
        data = {
            "name": self.subdomain,
            "type": "CNAME",
            "content": self.target,
            "ttl": "300"
        }
        
        result = self._make_request(f"dns/create/{self.domain}", data)
        
        if result.get('status') == 'SUCCESS':
            log("✅ CNAME record created successfully!")
            return True
        else:
            warning(f"Failed to create record: {result.get('message')}")
            return False
    
    def update_cname_record(self, record_id: str) -> bool:
        """Update existing CNAME record"""
        log(f"Updating existing CNAME record (ID: {record_id})")
        
        data = {
            "name": self.subdomain,
            "type": "CNAME",
            "content": self.target,
            "ttl": "300"
        }
        
        result = self._make_request(f"dns/edit/{self.domain}/{record_id}", data)
        
        if result.get('status') == 'SUCCESS':
            log("✅ CNAME record updated successfully!")
            return True
        else:
            warning(f"Failed to update record: {result.get('message')}")
            return False
    
    def delete_record(self, record_id: str) -> bool:
        """Delete a DNS record"""
        log(f"Deleting record ID: {record_id}")
        
        result = self._make_request(f"dns/delete/{self.domain}/{record_id}", {})
        
        if result.get('status') == 'SUCCESS':
            log("✅ Record deleted successfully!")
            return True
        else:
            warning(f"Failed to delete record: {result.get('message')}")
            return False
    
    def configure_dns(self) -> bool:
        """Main method to configure DNS"""
        info(f"Configuring DNS for {self.subdomain}.{self.domain}")
        print("=" * 50)
        
        # Test authentication first
        if not self.test_authentication():
            error("Authentication failed. Please check your API credentials.")
        
        # Get existing records
        records = self.get_dns_records()
        if records is None:
            error("Failed to retrieve DNS records")
        
        # Check for existing record
        existing = self.find_existing_record(records)
        
        if existing:
            info(f"Found existing CNAME record pointing to: {existing.get('content')}")
            
            if existing.get('content') == self.target:
                log("✅ DNS is already correctly configured!")
                return True
            else:
                # Update the existing record
                record_id = existing.get('id')
                if record_id:
                    return self.update_cname_record(record_id)
                else:
                    warning("No record ID found, creating new record...")
                    return self.create_cname_record()
        else:
            # Create new record
            return self.create_cname_record()
    
    def verify_dns_propagation(self):
        """Verify DNS propagation"""
        info("\nVerifying DNS configuration...")
        
        full_domain = f"{self.subdomain}.{self.domain}"
        
        # Use dig to check DNS
        try:
            result = subprocess.run(
                ['dig', '+short', 'CNAME', full_domain],
                capture_output=True, text=True, check=True
            )
            
            cname_result = result.stdout.strip()
            
            if cname_result:
                log(f"✅ DNS Query Result: {full_domain} -> {cname_result}")
                
                if self.target in cname_result:
                    log("✅ DNS is correctly configured and propagating!")
                else:
                    warning(f"DNS points to different target: {cname_result}")
            else:
                warning("DNS record not yet propagated. This is normal - propagation can take 5-30 minutes.")
                
        except subprocess.CalledProcessError:
            warning("Failed to query DNS. This might be normal if the record was just created.")

def main():
    """Main execution"""
    print(f"{Colors.BLUE}Porkbun DNS Configuration for jonathon.candlefish.ai{Colors.NC}")
    print("=" * 60)
    print()
    
    # Get credentials
    log("Loading Porkbun API credentials from AWS Secrets...")
    api_key, secret_key = get_porkbun_credentials()
    info("Credentials loaded successfully")
    
    # Initialize client
    client = PorkbunDNS(api_key, secret_key)
    
    # Configure DNS
    success = client.configure_dns()
    
    if success:
        print()
        print(f"{Colors.GREEN}✅ DNS Configuration Complete!{Colors.NC}")
        print()
        print("Your documentation will be available at:")
        print(f"  https://jonathon.candlefish.ai")
        print()
        print("Current status:")
        print(f"  https://zippy-macaron-c28bbf.netlify.app (available now)")
        print()
        
        # Verify propagation
        client.verify_dns_propagation()
        
        print()
        print("DNS propagation usually takes 5-30 minutes.")
        print("You can check the status with:")
        print(f"  dig jonathon.candlefish.ai")
        print(f"  curl -I https://jonathon.candlefish.ai")
        
        # Create verification script
        with open('verify-dns-status.sh', 'w') as f:
            f.write('''#!/bin/bash
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
''')
        
        subprocess.run(['chmod', '+x', 'verify-dns-status.sh'])
        print()
        print("Run ./verify-dns-status.sh to check DNS propagation status")
        
    else:
        error("DNS configuration failed. Please check the logs above.")

if __name__ == "__main__":
    main()