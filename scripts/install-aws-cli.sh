#!/usr/bin/env bash
set -euo pipefail

if command -v aws &>/dev/null; then
    echo "  [skip] aws cli already installed ($(aws --version))"
    exit 0
fi

echo "  [install] aws cli v2"
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/awscliv2
sudo /tmp/awscliv2/aws/install
rm -rf /tmp/awscliv2.zip /tmp/awscliv2
echo "  [done] $(aws --version)"
