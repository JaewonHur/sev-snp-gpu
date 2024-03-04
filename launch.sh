#!/usr/bin/bash

PORT=10032
IMG=$1
KERNEL=$2

debug_str=""
if [[ ! -z $DEBUG ]];
then
    debug_str="-s -S"
fi

[ -z ${qemu_path} ] && {
    echo "[-] Please specify the path for qemu-system-x86_64 that can launch SNP VM"
    exit 1
}

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

snp_str=""
[ -z $SNP ] || {
    snp_str="""
-no-reboot \
-object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1 \
-machine memory-encryption=sev0,vmport=off \
"""
}

gpu_str=""
[ -z $GPU ] || {
    bdfs=($(lspci | grep NVIDIA | cut -d' ' -f1))
    [ ${#bdfs[@]} -eq 0 ] && {
        echo "[-] Cannot find NVIDIA devices"
        exit 1
    }

    for bdf in ${bdfs[@]}
    do
        gpu_str+="""
-device vfio-pci,host=${bdf} \
"""
    done
}

sudo ${qemu_path} \
    -cpu EPYC-v4 \
    -machine q35 \
    ${snp_str} \
    -enable-kvm \
    -m 16384 \
    -smp 6 \
    -drive if=pflash,format=raw,unit=0,file=ovmf/OVMF_CODE.fd,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=ovmf/OVMF_VARS.fd \
    -drive format=raw,file=debian/$IMG.img \
    -netdev user,id=net0,host=10.0.2.10,hostfwd=tcp::$PORT-:22 \
    -device e1000,netdev=net0 \
    -device virtio-serial-pci,disable-modern=false,id=serial0 \
    -device virtconsole,chardev=charconsole0,id=console0 \
    -chardev socket,id=charconsole0,path=virtconsole.sock,server,nowait \
    ${gpu_str} \
    -kernel linux-$KERNEL/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda rw earlyprintk=serial net.ifnames=0 pci=earlydump debug" \
    -initrd linux-$KERNEL/initrd.img-$KERNEL \
    -nographic \
    ${debug_str}

