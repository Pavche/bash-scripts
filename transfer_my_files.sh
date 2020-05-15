echo "Transfer my files on a USB device"
set -x
USB_DEV=$(ls -1 /run/media/$USER/ | head -n1)
DATE=$(date +"%Y-%m-%d")
BACKUP_DIR="/run/media/$USER/$USB_DEV/$(hostname --short)/$DATE"
set +x

function init_backup_dir () {
    local BACKUP_DIR=${1:?"Error: backup dir not specified."}
    
    echo -e "Creating directory for backup:\n$BACKUP_DIR"
    if [ -d "$BACKUP_DIR" ]; then
        echo "Error: directory already exists." >&2
        return 1
    fi

    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: cannot create directory $BACKUP_DIR" >&2
        return 1
    fi
}

init_backup_dir "$BACKUP_DIR" || exit 1

cd $HOME
for D in bash Dokumenty Obrázky python_scripts Work
do
  echo "Back up directory: $D";   sleep 2;  
  set -x
  tar czf "$BACKUP_DIR/$D.tar.gz" "$D"; RC=$?
  set +x
  if [ $RC -eq 0 ]; then
    echo "Transferred $D. OK"
  else
    echo "Error: cannot transfer $D." >&2
    exit 1
  fi
  sleep 2
done

echo "Copy SSH keys"
if [ -d "$HOME/.ssh" ]; then
  rsync -av "$HOME/.ssh" "$BACKUP_DIR"; RC=$?
  if [ $RC -eq 0 ]; then
    echo "Transferred SSH keys. OK"
  else
    echo "Error: cannot transfer SSH keys." >&2
    exit 1
  fi
else
  echo "No SSH keys. Skipping."
fi

echo -e "\nCOPY BASH PROFILE AND RC\n"
for F in .bash_profile .bashrc
do
    cp "$HOME/$F" "$BACKUP_DIR" 
    [ $? -eq 0 ] && echo "$F copied. OK." || echo "Error: cannot copy $HOME/$F to $BACKUP_DIR" >&2
done

echo -e "\nCOPY KEYS AND PASSWORDS\n"
cp *.kdbx "$BACKUP_DIR" && echo "*.kdbx copied. OK." || echo "Error: cannot copy *.kdbx" >&2
cp fichier-cle.key "$BACKUP_DIR" && echo "key-file.key copied. OK." || echo "Error: cannot copy key-file.key" >&2

echo -e "\nTHE CERTIFICATE GAME\n"
CERT_DIR="$BACKUP_DIR/CESNET/CERTIFICATES/PERSONAL"
echo -e "Copy personal certificates to:\n$CERT_DIR"
mkdir -p "$CERT_DIR"
rsync -av $HOME/Work/CESNET/Certificates/Personal/* "$CERT_DIR"
if [ $? -eq 0 ]; then
    echo "Certificates copied. OK."
else
    echo "Error: failed to copy personal certificates." >&2
    exit 1
fi
