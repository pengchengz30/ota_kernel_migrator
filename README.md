# 📱 Android GKI Kernel Migrator

A utility for **GKI (Generic Kernel Image)** devices to safely migrate a running custom kernel from the active slot to the inactive slot.

---

## 📋 Prerequisites

Before running the script, ensure your environment meets the following requirements:

1. **Root Access:** Your device must be rooted via KernelSU in **KernelSU in GKI mode ONLY**.
2. **Termux App:** This is the primary environment for execution. You can download it from:
   - [F-Droid](https://f-droid.org/en/packages/com.termux/) (Recommended for latest updates)
   - [Google Play Store](https://play.google.com/store/apps/details?id=com.termux)
3. **Storage Permission:** Ensure Termux has access to your internal storage.

---

## 🚀 Installation & Execution

Choose the method based on your current connection environment.

### **Option 1: Via ADB Shell**
> **Note:** This method uses Termux's `curl` binary to bypass the lack of downloaders in native Android shells. Root access is required to access the Termux environment.

```sh
su -c "
  cd /data/local/tmp
  T_CURL='/data/data/com.termux/files/usr/bin/curl'
  
  \$T_CURL -LOsS https://raw.githubusercontent.com/pengchengz30/ota_kernel_migrator/refs/heads/main/kernel_migrator.sh
  
  chmod +x kernel_migrator.sh
  ./kernel_migrator.sh
"
```

### **Option 2: Via Termux (On-Device)**
> **Note:** Recommended for a smoother experience. Ensure you have granted Storage and Root permissions to Termux first.

```sh
curl -LOsS https://raw.githubusercontent.com/pengchengz30/ota_kernel_migrator/refs/heads/main/kernel_migrator.sh
chmod +x kernel_migrator.sh
su -c './kernel_migrator.sh'
```

## 🛠 Dependencies & Credits

This project relies heavily on the **magiskboot** binary for boot image unpacking and repacking.

* **Binary Source:** [magiskboot-linux](https://github.com/magojohnji/magiskboot-linux) by magojohnji.

---

## ⚠️ Important Safety Notices

* **GKI Only:** This script is specifically tuned for **GKI-compliant** kernels.
* **Directory Constraint**: For security and binary execution support, this script **must** be run from `/data/local/tmp` or the **Termux** home directory.
* **Non-Active Slot**: By default, this script patches and flashes the **inactive slot**. This provides a safety net: if the new kernel fails to boot, the system will automatically rollback to your current working slot after a few failed boot attempts.
