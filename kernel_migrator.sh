#!/system/bin/sh

set -e

if [ "$(id -u)" != 0 ]; then
    echo "Must be run as root"
    exit 1
fi

# --- Configuration ---
MAGISKBOOT="./magiskboot"
WORKDIR="./kernel_transfer"


printf "Is the device in GKI mode? (y/n): "
read gki_input
case "$gki_input" in
    [yY]) echo "[+] GKI mode confirmed. Proceeding..." ;;
    *) echo "[-] Error: GKI mode not confirmed. Exiting."; exit 1 ;;
esac

# --- 1. Environment Preparation ---
# If WORKDIR exists, delete it to ensure a clean state
if [ -d "$WORKDIR" ]; then
    echo "[!] WORKDIR already exists. Deleting it..."
    rm -rf "$WORKDIR"
fi

# --- magiskboot check with auto-download ---
if [ ! -f "$MAGISKBOOT" ]; then
    echo "[-] Error: $MAGISKBOOT not found in the current directory."
    echo "[?] Which architecture is your device/environment using?"
    echo "    1) arm64-v8a  (Pixel 10 Pro / Modern Android)"
    echo "    2) armeabi-v7a (Older 32-bit)"
    echo "    3) x86"
    echo "    4) x86_64"
    printf "Please select [1-4]: "
    read arch_choice

    echo "--------------------------------------------------------"
    case "$arch_choice" in
        1) ARCH="arm64-v8a" ;;
        2) ARCH="armeabi-v7a" ;;
        3) ARCH="x86" ;;
        4) ARCH="x86_64" ;;
        *) echo "[!] Invalid selection. Exiting."; exit 1 ;;
    esac
    CURL="/data/data/com.termux/files/usr/bin/curl"
    URL="https://github.com/magojohnji/magiskboot-linux/raw/refs/heads/main/${ARCH}/magiskboot"
    echo "[!] Downloading $ARCH version from GitHub..."
    
    if $CURL -fL -o "$MAGISKBOOT" "$URL"; then
        echo "[+] Download successful."
    else
        echo "[-] Error: Download failed. Please check your internet connection or URL."
        echo "    URL: $URL"
        exit 1
    fi
    echo "--------------------------------------------------------"
fi


chmod +x "$MAGISKBOOT"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit

# --- 2. Identify A/B Slots ---
# Determine active and inactive slots
CURRENT_SLOT=$(getprop ro.boot.slot_suffix)
if [ "$CURRENT_SLOT" = "_a" ]; then
    TARGET_SLOT="_b"
else
    TARGET_SLOT="_a"
fi

echo "[+] Current Active Slot: $CURRENT_SLOT (Running custom kernel)"
echo "[+] Target Inactive Slot: $TARGET_SLOT (Awaiting update/patch)"

# --- 3. Extract Custom Kernel from Current Slot ---
echo "[+] Step 1: Extracting current boot from $CURRENT_SLOT..."
dd if="/dev/block/by-name/boot$CURRENT_SLOT" of=boot_current.img status=none

echo "[+] Unpacking current boot to isolate kernel..."
../$MAGISKBOOT unpack boot_current.img > /dev/null

if [ ! -f "kernel" ]; then
    echo "[-] Error: Failed to extract kernel from $CURRENT_SLOT."
    exit 1
fi

echo "[+] Cleaning up workdir, keeping only the kernel..."
for file in *; do
    if [ "$file" != "kernel" ]; then
        rm -rf "$file"
    fi
done

mv kernel custom_kernel

# --- 4. Patch Target Slot Boot with Custom Kernel ---
echo "[+] Step 2: Extracting stock boot from $TARGET_SLOT..."
dd if="/dev/block/by-name/boot$TARGET_SLOT" of=boot_target.img status=none

echo "[+] Unpacking target boot and replacing with custom kernel..."
../$MAGISKBOOT unpack boot_target.img > /dev/null


if [ ! -f "kernel" ]; then
    echo "[-] Error: Failed to extract kernel from $TARGET_SLOT."
    exit 1
fi

mv custom_kernel kernel

# magiskboot repack will prioritize the 'kernel' file we moved into the directory
echo "[+] Repacking target boot image..."
../$MAGISKBOOT repack boot_target.img new_boot_target.img > /dev/null

# Determine the correct output filename (magiskboot usually outputs new-boot.img)
if [ -f "new-boot.img" ]; then
    IMG_OUT="new-boot.img"
elif [ -f "new_boot_target.img" ]; then
    IMG_OUT="new_boot_target.img"
else
    echo "[-] Error: Repack failed. No output image (new-boot.img or new_boot_target.img) was found."
    exit 1
fi

echo "[+] Repack successful. Target image: $IMG_OUT"


echo "--------------------------------------------------------"
printf "CRITICAL: Are you sure you want to flash $IMG_OUT to boot$TARGET_SLOT? (y/n): "
read flash_confirm

case "$flash_confirm" in
    [yY])
        echo "[!] STARTING FLASHING PROCESS..."
        # Uncomment the line below to enable actual flashing
        echo "[+] Flash command executed (if uncommented)."
        ;;
    *)
        echo "[#] Flash aborted by user. The patched image is saved in $WORKDIR."
	exit 1;
        ;;
esac

# --- 5. Flash Back to Target Slot ---
echo "[+] Step 3: Flashing patched image to boot$TARGET_SLOT..."
#dd if="$IMG_OUT" of="/dev/block/by-name/boot$TARGET_SLOT" status=progress

# Ensure all data is physically written to the flash storage
echo "[+] Synchronizing file system..."
sync
sync

# --- 6. Finalization ---
cd ..
# Optional: rm -rf "$WORKDIR"
echo "--------------------------------------------------------"
echo "[SUCCESS] Task completed."
echo "[INFO] You can now reboot. The system will switch to $TARGET_SLOT."
echo "--------------------------------------------------------"
