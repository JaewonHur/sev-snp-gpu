# Enable NVIDIA GPU on SEV-SNP VMs

This repository includes the scripts and codes to enable Nvidia GPUs in SEV-SNP VMs.

## System Environments

* **host kernel**: `5.19.0-rc6-snp-host-c4daeffce56e`
* **ccp firmware**: `1.51 build:3`
* **`lspci` result in host**:
```
01:00.0 VGA compatible controller: NVIDIA Corporation TU102 [GeForce RTX 2080 Ti Rev. A] (rev a1) (prog-if 00 [VGA controller])
	Subsystem: NVIDIA Corporation TU102 [GeForce RTX 2080 Ti Rev. A]
	Flags: bus master, fast devsel, latency 0, IRQ 222, IOMMU group 66
	Memory at f8000000 (32-bit, non-prefetchable) [size=16M]
	Memory at 38060000000 (64-bit, prefetchable) [size=256M]
	Memory at 38070000000 (64-bit, prefetchable) [size=32M]
	I/O ports at 3000 [size=128]
	Expansion ROM at f9000000 [disabled] [size=512K]
	Capabilities: <access denied>
	Kernel driver in use: vfio-pci
	Kernel modules: nvidiafb, nouveau

01:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
	Subsystem: NVIDIA Corporation TU102 High Definition Audio Controller
	Flags: bus master, fast devsel, latency 0, IRQ 223, IOMMU group 66
	Memory at f9080000 (32-bit, non-prefetchable) [size=16K]
	Capabilities: <access denied>
	Kernel driver in use: vfio-pci
	Kernel modules: snd_hda_intel

01:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1) (prog-if 30 [XHCI])
	Subsystem: NVIDIA Corporation TU102 USB 3.1 Host Controller
	Flags: bus master, fast devsel, latency 0, IRQ 226, IOMMU group 66
	Memory at 38072000000 (64-bit, prefetchable) [size=256K]
	Memory at 38072040000 (64-bit, prefetchable) [size=64K]
	Capabilities: <access denied>
	Kernel driver in use: vfio-pci
	Kernel modules: xhci_pci

01:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
	Subsystem: NVIDIA Corporation TU102 USB Type-C UCSI Controller
	Flags: bus master, fast devsel, latency 0, IRQ 225, IOMMU group 66
	Memory at f9084000 (32-bit, non-prefetchable) [size=4K]
	Capabilities: <access denied>
	Kernel driver in use: vfio-pci
	Kernel modules: i2c_nvidia_gpu
```

## Instructions to Launch VM
```
# git clone https://github.com/JaewonHur/sev-snp-gpu
# cd sev-snp-gpu

# ./setup.sh bookworm 6.0.0
# SNP=1 GPU=1 qemu_path=<path to the qemu-system-x86_64 that can launch SEV-SNP VM> ./launch.sh bookworm 6.0.0
```

## Instructions inside VM
```
# depmod
# apt install -y python3 python3-pip
# pip3 install torch --break-system-packages
# python3 ./gpu_correct.py
```
