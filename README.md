### Для установки введите эти команды в терминал пошагово.

```bash
apt -y update && apt -y upgrade
```
```bash
apt install wget
```
```bash
wget -qO- wget -qO- $(curl -s https://api.github.com/repos/Taskov1ch/TeaRCON-installer/releases/latest | grep "browser_download_url.*installer.sh" | cut -d '"' -f 4) | sudo bash
```
___
**или же**
___
```bash
apt -y update && apt -y upgrade
```

*(установите скрипт **installer.sh** локально в нужный вам каталог сервера)*

```bash
chmod +x installer.sh
```
```bash
./installer.sh
```
