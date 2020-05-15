virt-install \
--name RHEL-7.6 \
--memory 2048 \
--vcpus 1 \
--disk size=10 \
--network default \
--location http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.6/Workstation/x86_64/os/ \
--os-variant rhel7 \
--initrd-inject /home/pgeorgie/VM/kickstart/rhel7/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
