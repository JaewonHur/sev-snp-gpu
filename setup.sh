#!/usr/bin/bash

run_cmd()
{
    echo "$*"

    eval "$*" || {
        echo "ERROR: $*"
        exit 1
    }
}

run_chroot()
{
    root=$1
    script=$2

    sudo chroot ${root} /bin/bash -c """
set -ex
${script}
exit
"""
    [[ $? -ne 0 ]] && {
        echo "ERROR: chroot failed"
        exit 1
    }
}

build_image()
{
    local image=$1
    local size=$2

    pushd debian > /dev/null

    run_cmd chmod +x create-image.sh

    echo "[+] Build ${image} image ..."

    run_cmd ./create-image.sh --distribution ${image} ${size}

    popd > /dev/null
}


build_kernel()
{
    local version=$1
    major=${version%%.*}

    [ -d linux-${version} ] || {
        run_cmd wget https://cdn.kernel.org/pub/linux/kernel/v${major}.x/linux-${version}.tar.gz
        run_cmd tar xvf linux-${version}.tar.gz linux-${version}

        run_cmd rm linux-${version}.tar.gz
    }

    MAKE="make -C linux-${version} -j $(getconf _NPROCESSORS_ONLN) LOCALVERSION="

    run_cmd $MAKE distclean
    [ -d linux-${version} ] && {
        pushd linux-${version} > /dev/null

        run_cmd make defconfig
        run_cmd make kvm_guest.config

        run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO_DWARF5
        run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO
        run_cmd ./scripts/config --disable CONFIG_RANDOMIZE_BASE
        run_cmd ./scripts/config --enable CONFIG_GDB_SCRIPTS

        popd > /dev/null
    }
    run_cmd $MAKE olddefconfig

    echo "[+] Build linux kernel ..."
    run_cmd $MAKE
}

update_image()
{
    local image=$1
    local version=$2

    echo "[+] Update ${image} image for kernel ${version} ..."

    [ -d tmp ] || {
        mkdir -p tmp
    }
    rm -rf tmp/*

    tmp=$(realpath tmp)

    run_cmd sudo mount debian/${image}.img ${tmp}
    sleep 1

    [ -d linux-${version} ] || {
        echo "[-] Cannot find linux-${version}"
        exit 1
    }

    pushd linux-${version} > /dev/null

    run_cmd sudo rm -rf ${tmp}/usr/src/linux-headers-*
    [ -d ${tmp}/usr/src/linux-headers-$version/arch/x86 ] || {
        run_cmd sudo mkdir -p ${tmp}/usr/src/linux-headers-$version/arch/x86
    }

    [ -d ${tmp}/usr/src/linux-headers-${version}/arch/x86 ] && {
        run_cmd sudo cp arch/x86/Makefile* ${tmp}/usr/src/linux-headers-${version}/arch/x86
        run_cmd sudo cp -r arch/x86/include ${tmp}/usr/src/linux-headers-${version}/arch/x86
    }
    run_cmd sudo cp -r include ${tmp}/usr/src/linux-headers-${version}
    run_cmd sudo cp -r scripts ${tmp}/usr/src/linux-headers-${version}

    [ -d ${tmp}/usr/src/linux-headers-${version}/tools/objtool ] || {
        run_cmd sudo mkdir -p ${tmp}/usr/src/linux-headers-${version}/tools/objtool
    }

    [ -d ${tmp}/usr/src/linux-headers-${version}/tools/objtool ] && {
        run_cmd sudo cp tools/objtool/objtool ${tmp}/usr/src/linux-headers-${version}/tools/objtool
    }

    run_cmd sudo rm -rf ${tmp}/lib/modules/*

    run_cmd sudo make INSTALL_MOD_PATH=${tmp} modules_install
    run_cmd sudo make INSTALL_HDR_PATH=${tmp} headers_install

    run_cmd sudo rm -rf ${tmp}/usr/lib/modules/${version}/source
    run_cmd sudo ln -s /usr/src/linux-headers-${version} ${tmp}/usr/lib/modules/${version}/source
    run_cmd sudo rm -rf ${tmp}/usr/lib/modules/${version}/build
    run_cmd sudo ln -s /usr/src/linux-headers-${version} ${tmp}/usr/lib/modules/${version}/build

    run_cmd sudo cp Module.symvers ${tmp}/usr/src/linux-headers-${version}/Module.symvers
    run_cmd sudo cp Makefile ${tmp}/usr/src/linux-headers-${version}/Makefile

    popd > /dev/null

    run_cmd sudo umount ${tmp}
    sleep 1

    rm -rf ${tmp}
}

build_initrd()
{
    local image=$1
    local version=$2

    [ -d tmp ] || {
        mkdir -p tmp
    }
    rm -rf tmp/*
    tmp=$(realpath tmp)

    sudo mount debian/${image}.img ${tmp}

    [ -d linux-${version} ] || {
        echo "[-] Cannot find linux-${version}"
        exit 1
    }

    [ -f linux-${version}/.config ] || {
        echo "[-] Cannot find linux-${version}/.config"
        exit 1
    }

    run_cmd sudo cp linux-${version}/.config ${tmp}/boot/config-${version}

    run_chroot ${tmp} """
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
apt update

export DEBIAN_FRONTEND=noninteractive
apt install -y initramfs-tools

PATH=/usr/sbin/:\$PATH update-initramfs -k ${version} -c -b /boot/
"""
    run_cmd sudo cp ${tmp}/boot/initrd.img-${version} linux-${version}/initrd.img-${version}

    run_cmd sudo umount ${tmp}
}

image=$1
version=$2
size=${3:-32768}

build_image ${image} ${size}
build_kernel ${version}
update_image ${image} ${version}
build_initrd ${image} ${version}
