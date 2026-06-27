## Apache Setup
## Setup Steps
### Insatall Apache VHOST
```
sudo apt update
sudo apt install apache2 -y
sudo systemctl status apache2
```
### 1. Create the config file

```
sudo nano /etc/apache2/sites-available/devops-demo-apache.conf
```

### 2. Create the web root directory

```
sudo mkdir -p /var/www/devops-demo-apache/html
```

### 3. Enable the site

```
sudo a2ensite devops-demo-apache.conf
```

### 4. Disable the default site to avoid conflicts

```
sudo a2dissite 000-default.conf
```

### 5. Make sure mod_rewrite is enabled (needed for AllowOverride All)

```
sudo a2enmod rewrit
```

### 6. Test the Apache configuration

```
sudo apache2ctl configtest
```

### 7. Reload Apache to apply changes

```
sudo systemctl reload apache2
```
---
### Removing Apache
```
sudo systemctl stop apache2
sudo apt purge apache2 apache2-utils apache2-bin -y
sudo apt autoremove -y
```
### Verify Removed
```
sudo ss -tlnp | grep :80
```