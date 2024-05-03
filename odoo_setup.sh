#!/bin/bash

# Update system packages
sudo apt update

# Install Git
sudo apt install git -y

# Install Pip
sudo apt install python3-pip -y

# Install other required dependencies
sudo apt install -y build-essential wget python3-dev python3-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev

# Create a new odoo user
sudo adduser odoo

# Download and add PostgreSQL Repositories
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Start the database server
sudo systemctl start postgresql

# Enable the database server to start automatically on system boot
sudo systemctl enable postgresql

# Change the default PostgreSQL password
sudo passwd postgres

# Switch to the postgres user
su - postgres <<EOF
createuser odoo
psql -c "ALTER USER odoo WITH CREATEDB;"
exit
EOF

# Download and install Wkhtmltopdf
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt install ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb

# Create directory for Odoo and set permissions
sudo mkdir -p /opt/odoo/odoo
sudo chown -R odoo /opt/odoo
sudo chgrp -R odoo /opt/odoo

# Switch to the odoo user
sudo su - odoo <<EOF
git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo/odoo
cd /opt/odoo
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip3 install wheel
pip3 install -r odoo/requirements.txt
deactivate
mkdir /opt/odoo/odoo-custom-addons
exit
EOF

# Create Odoo configuration file
sudo tee /etc/odoo.conf > /dev/null <<EOF
[options]
admin_passwd = StrongMasterPassword
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo/addons,/opt/odoo/odoo-custom-addons
EOF

# Create Odoo service unit file
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo17
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-venv/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Reload system daemon for changes to take effect
sudo systemctl daemon-reload

# Start the Odoo service
sudo systemctl start odoo

# Enable the service to start on system boot
sudo systemctl enable odoo

# Check the service status
sudo systemctl status odoo
