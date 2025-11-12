# Zabbix Installer

This repository contains scripts to install, configure, and uninstall Zabbix server and agent on **Debian 12** and **Ubuntu 22.04**. It also includes a script to manage hosts via the Zabbix API, supporting both interactive and automated CLI usage.

---

## Quick Start Example

Install Zabbix 7.4, set admin password, and add a host in one go:

```bash
# Make scripts executable
chmod +x install.sh uninstall.sh zabbix_api.sh
chmod +x lib/*.sh

# Run installer interactively
sudo ./install.sh

# Add a host non-interactively (replace with your IP/template IDs)
sudo ./zabbix_api.sh add-host \
  --host-name "web01" \
  --visible-name "Web Server 01" \
  --group-id 2 \
  --interface '[{"type":1,"main":1,"useip":1,"ip":"192.168.1.10","dns":"","port":"10050"}]' \
  --template '[{"templateid":10001}]'
```

This example installs Zabbix server + agent, Apache + PHP, configures MariaDB, and adds a host with a template automatically.

---

## 1. Clone or Create the Repository

### If you already have files locally:

```bash
mkdir ~/zabbix-installer
cd ~/zabbix-installer
```

Ensure the directory structure matches:

```
zabbix-installer/
├─ install.sh
├─ uninstall.sh
├─ zabbix_api.sh
├─ lib/
│   ├─ colors.sh
│   ├─ utils.sh
│   ├─ system.sh
│   └─ db.sh
└─ config/
    └─ zabbix_api.conf   # generated automatically after install
```

### If using GitHub:

```bash
git clone https://github.com/Nix556/Zabbix-Installer.git zabbix-installer
cd zabbix-installer
```

---

## 2. Make Scripts Executable

```bash
chmod +x install.sh uninstall.sh zabbix_api.sh
chmod +x lib/*.sh
```

---

## 3. Run the Installer

```bash
sudo ./install.sh
```

Interactive prompts include:

* MariaDB root password
* Zabbix database name, user, and password
* Zabbix server IP
* Zabbix admin password

Everything else is automated:

* MariaDB database and user for Zabbix
* Apache + PHP 8.2
* Zabbix server and agent
* Zabbix API configuration (`config/zabbix_api.conf`)

After installation, the script shows:

```
Frontend URL: http://<ZABBIX_IP>/zabbix
Admin user: Admin
Admin password: <your-chosen-password>
```

---

## 4. Run the Zabbix API Script

### Interactive Mode

```bash
sudo ./zabbix_api.sh
```

Follow prompts to:

* List hosts
* Add hosts (supports multiple interfaces and templates)
* Remove hosts

The script validates:

* IP addresses
* Group IDs
* Template IDs

### Automated CLI Mode

**List hosts:**

```bash
sudo ./zabbix_api.sh list-hosts
```

**Add host with multiple interfaces/templates:**

```bash
sudo ./zabbix_api.sh add-host \
  --host-name "web01" \
  --visible-name "Web Server 01" \
  --group-id 2 \
  --interface '[{"type":1,"main":1,"useip":1,"ip":"192.168.1.10","dns":"","port":"10050"},{"type":1,"main":1,"useip":1,"ip":"10.0.0.10","dns":"","port":"10050"}]' \
  --template '[{"templateid":10001},{"templateid":10002}]'
```

| Argument         | Description                                      |
| ---------------- | ------------------------------------------------ |
| `--host-name`    | Required host name                               |
| `--visible-name` | Optional, defaults to host name                  |
| `--group-id`     | Zabbix host group ID (default 2 = Linux servers) |
| `--interface`    | JSON array of interfaces (IP + port)             |
| `--template`     | JSON array of template IDs                       |

**Remove a host:**

```bash
sudo ./zabbix_api.sh remove-host
```

Lists hosts and prompts for host ID.

---

## 5. Uninstallation

```bash
sudo ./uninstall.sh
```

Removes:

* Zabbix server
* Zabbix agent
* MariaDB
* Apache + PHP
* All configuration files, logs, and API cache

The uninstaller automatically detects the Zabbix database and user from `/etc/zabbix/zabbix_server.conf`.

---

## 6. Notes

* Supports **Debian 12** and **Ubuntu 22.04**
* API script works interactively or via CLI for automation
* Multiple interfaces and templates supported when adding hosts
* `jq` is required and installed automatically
