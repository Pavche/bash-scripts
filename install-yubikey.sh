clear
echo 'Install YubiKeys tools under Fedora'
sleep 2
dnf install -y yubico-piv-tool opensc
echo
echo 'Status of YubiKey'
yubico-piv-tool -a status
sleep 5
echo
echo 'Public key stored in YubiKey'
if [ -r /usr/lib64/opensc-pkcs11.so ];
    ssh-keygen -D /usr/lib64/opensc-pkcs11.so
else
    echo 'Cannot find needed Library for YubiKey.' >&2
    echo '/usr/lib64/opensc-pkcs11.so'
    exit 1
done
