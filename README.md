**1. ADB:** Please run the following lines as root, otherwise termux home is not accessible

```sh
su -c "
  cd /data/local/tmp
  T_CURL='/data/data/com.termux/files/usr/bin/curl'
  
  \$T_CURL -LO https://raw.githubusercontent.com/pengchengz30/ota_kernel_migrator/refs/heads/main/kernel_migrator.sh
  
  chmod +x kernel_migrator.sh
  ./kernel_migrator.sh
"
```

**2. Termux:**

```sh
curl -LO https://raw.githubusercontent.com/pengchengz30/ota_kernel_migrator/refs/heads/main/kernel_migrator.sh
chmod +x kernel_migrator.sh
su -c './kernel_migrator.sh'
```
