#!/usr/bin/env bash

apt install -y \
    postgresql \
    libpq-dev \
    apache2 \
    libapache2-mod-proxy-uwsgi \
    libapache2-mod-xsendfile \
    python-dev \
    python-virtualenv \
    libxslt1-dev \
    libxml2-dev \
    libffi-dev \
    libpcre3-dev \
    libyaml-dev \
    build-essential \
    redis-server \
    uwsgi \
    uwsgi-plugin-python

apt install -y libjpeg62-turbo-dev

# make sure the services you just installed are running:
systemctl start postgresql.service redis-server.service

# Install a mail server.
apt install -y sendmail
systemctl enable sendmail
systemctl start sendmail

# 2. Create a Database
su - postgres -c 'createuser indico'
su - postgres -c 'createdb -O indico indico'
su - postgres -c 'psql indico -c "CREATE EXTENSION unaccent; CREATE EXTENSION pg_trgm;"'

# 3. Configure uWSGI & Apache
ln -s /etc/uwsgi/apps-available/indico.ini /etc/uwsgi/apps-enabled/indico.ini
cat > /etc/uwsgi/apps-available/indico.ini <<'EOF'
[uwsgi]
uid = indico
gid = www-data
umask = 027

processes = 4
enable-threads = true
socket = 127.0.0.1:8008
stats = /opt/indico/web/uwsgi-stats.sock
protocol = uwsgi

master = true
auto-procname = true
procname-prefix-spaced = indico
disable-logging = true

plugin = python
single-interpreter = true

touch-reload = /opt/indico/web/indico.wsgi
wsgi-file = /opt/indico/web/indico.wsgi
virtualenv = /opt/indico/.venv

vacuum = true
buffer-size = 20480
memory-report = true
max-requests = 2500
harakiri = 900
harakiri-verbose = true
reload-on-rss = 2048
evil-reload-on-rss = 8192
EOF

function configure_apache() {
  local YOURHOSTNAME=${1:?"Error: hostname not specified for Apache configuration."}
cat > /etc/apache2/sites-available/indico-sslredir.conf <<'EOF'
<VirtualHost *:80>
    ServerName YOURHOSTNAME
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/indico.conf <<'EOF'
<VirtualHost *:443>
    ServerName YOURHOSTNAME
    DocumentRoot "/var/empty/apache"

    SSLEngine             on
    SSLCertificateFile    /etc/ssl/indico/indico.crt
    SSLCertificateKeyFile /etc/ssl/indico/indico.key
    SSLProtocol           all -SSLv2 -SSLv3
    SSLCipherSuite        ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
    SSLHonorCipherOrder   on

    XSendFile on
    XSendFilePath /opt/indico
    CustomLog /opt/indico/log/apache/access.log combined
    ErrorLog /opt/indico/log/apache/error.log
    LogLevel error
    ServerSignature Off

    AliasMatch "^/(images|fonts)(.*)/(.+?)(__v[0-9a-f]+)?\.([^.]+)$" "/opt/indico/web/static/$1$2/$3.$5"
    AliasMatch "^/(css|dist|images|fonts)/(.*)$" "/opt/indico/web/static/$1/$2"
    Alias /robots.txt /opt/indico/web/static/robots.txt

    SetEnv UWSGI_SCHEME https
    ProxyPass / uwsgi://127.0.0.1:8008/

    <Directory /opt/indico>
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

  sed -i "s/YOURHOSTNAME/$YOURHOSTNAME/g" /etc/apache2/sites-available/indico-sslredir.conf
  sed -i "s/YOURHOSTNAME/$YOURHOSTNAME/g" /etc/apache2/sites-available/indico.conf
}

configure_apache $(hostname) || exit 1

# Enable the necessary modules and the indico site in apache
a2enmod proxy_uwsgi rewrite ssl xsendfile
a2dissite 000-default
a2ensite indico indico-sslredir

# 4. Create an SSL Certificate
mkdir /etc/ssl/indico
chown root:root /etc/ssl/indico/
chmod 700 /etc/ssl/indico

function generate_ssl_cert() {
  local YOURHOSTNAME=${1:?"Error: hostname is missing to generate a SSL certificate."}

  openssl req \
	  -x509 \
	  -nodes \
	  -newkey rsa:4096 \
	  -subj /CN=$YOURHOSTNAME \
	  -keyout /etc/ssl/indico/indico.key \
	  -out /etc/ssl/indico/indico.crt
}

generate_ssl_cert $(hostname) || exit 1

# 5. Install Indico
# Add a systemd unit file for it.
cat > /etc/systemd/system/indico-celery.service <<'EOF'
[Unit]
Description=Indico Celery
After=network.target

[Service]
ExecStart=/opt/indico/.venv/bin/indico celery worker -B
Restart=always
SyslogIdentifier=indico-celery
User=indico
Group=www-data
UMask=0027
Type=simple
KillMode=mixed
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

useradd -rm -g www-data -d /opt/indico -s /bin/bash indico
su - indico

# 8. Launch Indico
# Start Indico and set it up to start automatically when the server is rebooted.
systemctl restart uwsgi.service apache2.service indico-celery.service
systemctl enable uwsgi.service apache2.service postgresql.service redis-server.service indico-celery.service

# 9. Optional: Get a Certificate from Let’s Encrypt
# Note: You need to use at least Debian 9 (Stretch) to use certbot. If you are still using Debian 8 (Jessie), consider updating or install certbot from backports.
# Install Certbot under Debian
function get_ssl_cert() {
  local YOURHOSTNAME=${1:?"Error: hostname is not provided for obtaining SSL certificate."}
  
  apt install -y python-certbot-apache certbot
  certbot \
	  --apache \
	  --rsa-key-size 4096 \
	  --no-redirect \
	  --staple-ocsp -d $YOURHOSTNAME

  rm -rf /etc/ssl/indico
  systemctl start certbot.timer
  systemctl enable certbot.timer
}
# get_ssl_cert $(hostname)

