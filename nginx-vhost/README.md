## Setup Steps

## Installing Ngnix

### Update server and install Ngnix
```
sudo apt update
sudo apt install nginx -y
sudo systemctl status nginx
```
---

### 1. Create the config file

```
sudo nano /etc/nginx/sites-available/devops-demo
```

Paste the config above (replace `YOUR_EC2_PUBLIC_IP` with your actual IP or DuckDNS subdomain).

### 2. Enable the site by creating a symlink

```
sudo ln -s /etc/nginx/sites-available/devops-demo /etc/nginx/sites-enabled/
```

### 3. Remove the default config to avoid conflicts

```
sudo rm /etc/nginx/sites-enabled/default
```

### 4. Make sure your web root exists

```
sudo mkdir -p /var/www/devops-demo/html
```

### 5. Test the Nginx configuration

```
sudo nginx -t
```

### 6. Reload Nginx to apply changes

```
sudo systemctl reload nginx
```

---
### Removing Ngnix server
```
sudo systemctl stop nginx
sudo apt purge nginx nginx-common -y
sudo apt autoremove -y
```

### Verify Gone
```
sudo ss -tlnp | grep :80
```