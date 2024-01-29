#!/usr/bin/bash

PORT=10032
IMG=$1
KERNEL=$2

debug_str=""
if [[ ! -z $DEBUG ]];
then
    debug_str="-s -S"
fi

[ -f linux-$KERNEL/arch/x86/boot/bzImage ] || {
    echo "[-] No kernel image: linux-$KERNEL/arch/x86/boot/bzImage"
    exit 1
}

[ -f linux-$KERNEL/initrd.img-$KERNEL ] || {
    echo "[-] No initrd image: linux-$KERNEL/initrd.img-$KERNEL"
    exit 1
}

[ -f debian/$IMG.img ] || {
    echo "[-] No root image: debian/$IMG.img"
    exit 1
}

sudo qemu-system-x86_64 \
    -cpu host \
    -enable-kvm \
    -m 16384 \
    -smp 6 \
    -drive format=raw,file=debian/$IMG.img \
    -netdev user,id=net0,host=10.0.2.10,hostfwd=tcp::$PORT-:22 \
    -device e1000,netdev=net0 \
    -device virtio-serial-pci,disable-modern=false,id=serial0 \
    -device virtconsole,chardev=charconsole0,id=console0 \
    -chardev socket,id=charconsole0,path=virtconsole.sock,server,nowait \
    -kernel linux-$KERNEL/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda rw earlyprintk=serial net.ifnames=0 pci=earlydump debug" \
    -initrd linux-$KERNEL/initrd.img-$KERNEL \
    -nographic \
    ${debug_str}

