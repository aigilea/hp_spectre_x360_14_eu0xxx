Linux on HP Spectre x360 14-eu0xxx
=====
The latest and greatest Spectre x360 iteration offers new Core Ultra 155H with new ARC GPU which is at least twice as fast compared to the Xe graphics found in a few last generations, VPU for AI acceleration and many other cool features.

But can it run Linux?

Hardware
--------
Laptop is assembled by Quanta Computer, platform code name is DA0X3DMBAG0. If you happen to have boardview and/or schematic for the motherboard or know where to buy one please file an issue to contact me (please note that widely available DA0X3**A**MBAG0 schematics are for 2020 Spectre, not for this one).

You can find some photos of the motherboard in the [board][12] subfolder.

Should you buy it?
--------
Linux won't boot without ACPI overlay and Secure Boot thus won't be usable until HP fixes the ACPI (probably never).

Synaptics releases Linux-compatible firmware only if requested by the vendor so fingerprint reader won't work without HP say-so (none of previous generations got one working).

Camera has two sensors connected to IPU6 via MIPI. Main sensor (ov08x40) has a linux driver but it's neither int3472-aware nor libcamera-compatible, IR sensor (og0va1b) doesn't have a driver at all. Neither of sensors is supported by Intel IPU6 stack (although it looks like support for ov08x40 may be coming), the same with libcamera (but this one can at least be patched) so it's unlikely either of this sensors will work without patching for at least another year.

Otherwise it's a solid laptop, but think twice.

How to install?
--------
If you're using Fedora see [Issue #4][13].

1. Trackpad and touchscreen won't work during the setup so find a way to plug in both USB stick and a mouse at the same time if you need a mouse for the installation.
2. Disable Secure Boot in the BIOS.
3. Boot with `modprobe.blacklist=intel_lpss_pci` (press `e` in the grub menu, add parameter to the end of `linux` line, press `ctrl+x` to boot).
4. Run the installation as usual.
5. Add the same kernel parameter when rebooting to the installed system.
6. Install IASL (usually package is named acpi-tools or acpica-tools or acpica).
7. Download [SSDT patch][1] and compile it with `iasl -tc hp-spectre-x360-14-eu0xxx-f5a.dsl`.
8. There's a number of ways to apply the resulting AML file. The easiest one is to put it to the `/boot` and add `acpi /boot/filename.aml` line to the grub config, you can do it manually via `e` for the first time and then switch to using some [helper scripts][2]. There're kernel [means][3], [manuals][9] and [helper scripts][4] of loading additional ACPI tables as well.
9. With SSDT patch applied you no longer need `modprobe.blacklist` workaround so previously disabled devices like trackpad and touchscreen should work at this point.
10. Update your kernel to at least 6.7.

How to fix the sound?
--------
1. Kernel:
    * These fixes have been submitted and accepted so you don't have to patch if you're using kernel 6.9 or later (-rc3 looks usable, older ones have known problems).
    * If you want to use 6.8 or older, you have to apply [these][5] [two][6] patches (`patch -p1 < filename.patch` in the kernel source directory) and rebuild the kernel, consult your distribution documentation on how to do it.
2. If you have `Falling back to default firmware.` messages from `cs35l41-hda` in dmesg, your linux-firmware is outdated. You may either wait for your distribution to update the package or download the firmware from the [Cirrus repository][7] to /lib/firmware/cirrus manually. You will need following files:
    * cs35l41-dsp1-spk-cali-103c8c15-spkid0-l0.bin
    * cs35l41-dsp1-spk-cali-103c8c15-spkid0-r0.bin
    * cs35l41-dsp1-spk-cali-103c8c15-spkid1-l0.bin
    * cs35l41-dsp1-spk-cali-103c8c15-spkid1-r0.bin
    * cs35l41-dsp1-spk-cali-103c8c15.wmfw symlink to cs35l41/v6.78.0/halo_cspl_RAM_revB2_29.80.0.wmfw
    * cs35l41-dsp1-spk-prot-103c8c15-spkid0-l0.bin
    * cs35l41-dsp1-spk-prot-103c8c15-spkid0-r0.bin
    * cs35l41-dsp1-spk-prot-103c8c15-spkid1-l0.bin
    * cs35l41-dsp1-spk-prot-103c8c15-spkid1-r0.bin
    * cs35l41-dsp1-spk-prot-103c8c15.wmfw symlink to cs35l41/v6.78.0/halo_cspl_RAM_revB2_29.80.0.wmfw
3. If you have mic mute LED constantly on, your linux-firmware is outdated. You may manually update `/lib/firmware/intel/sof-ace-tplg/sof-hda-generic-2ch.tplg` from the latest [sof-bin release][8].
4. Sometimes function buttons like micmute doesn't work on the first boot of the kernel, rebooting usually fixes this issue.

How to fix the camera?
--------
This section is Proof-of-Concept for the time being, it might work for some use cases but it's doesn't result in a 100% functional camera. It's mostly here to show the camera will work at some point in future.
1. Download kernel patches:
    * `wget -O int3472.patch https://lore.kernel.org/linux-media/20231007021225.9240-1-hao.yao@intel.com/raw`
    * `wget -O ipu6-01.patch https://lore.kernel.org/linux-media/20240111065531.2418836-2-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-02.patch https://lore.kernel.org/linux-media/20240111065531.2418836-3-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-03.patch https://lore.kernel.org/linux-media/20240111065531.2418836-4-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-04.patch https://lore.kernel.org/linux-media/20240111065531.2418836-5-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-05.patch https://lore.kernel.org/linux-media/20240111065531.2418836-6-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-06.patch https://lore.kernel.org/linux-media/20240111065531.2418836-7-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-07.patch https://lore.kernel.org/linux-media/20240111065531.2418836-8-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-08.patch https://lore.kernel.org/linux-media/20240111065531.2418836-9-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-09.patch https://lore.kernel.org/linux-media/20240111065531.2418836-10-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-10.patch https://lore.kernel.org/linux-media/20240111065531.2418836-11-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-11.patch https://lore.kernel.org/linux-media/20240111065531.2418836-12-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-12.patch https://lore.kernel.org/linux-media/20240111065531.2418836-13-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-13.patch https://lore.kernel.org/linux-media/20240111065531.2418836-14-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-14.patch https://lore.kernel.org/linux-media/20240111065531.2418836-15-bingbu.cao@intel.com/raw`
    * `wget -O ipu6-15.patch https://lore.kernel.org/linux-media/20240111065531.2418836-16-bingbu.cao@intel.com/raw`
    * (ipu6-16.patch is missing intentionally)
    * `wget -O ipu6-17.patch https://lore.kernel.org/linux-media/20240111065531.2418836-18-bingbu.cao@intel.com/raw`
    * `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/ipu6-fw.patch`
    * (for 6.8) `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/ipu-bridge.patch`
    * (for 6.8) `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/ov08x40.patch`
    * (for 6.9) `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/ipu-bridge-69.patch`
    * (for 6.9) `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/ov08x40-69.patch`
2. Apply patches in the order of download.
3. Ensure you have `CONFIG_VIDEO_OV08X40=m`, `CONFIG_INTEL_SKL_INT3472=m` and `CONFIG_VIDEO_INTEL_IPU6=m` in your kernel config file.
4. Build & install the kernel.
5. Ensure `/lib/firmware/intel/ipu/ipu6epmtl_fw.bin` file exists, update your `linux-firmware` package if not.
6. Reboot and check your `dmesg` if `ipu6` has successfully initialized and found the `ov08x40` sensor.
7. Build and install libcamera
    * `git clone https://gitlab.freedesktop.org/camera/libcamera-softisp.git`
    * `cd libcamera-softisp`
    * `git checkout SoftwareISP-v09`
    * `wget https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/libcamera.patch`
    * `patch -p1 < ./libcamera.patch`
    * `meson setup -Dpipelines=simple -Dipas=simple --prefix=/usr build`
    * `ninja -C build install`
8. Now you should be able to view the camera by launching `sudo qcam -s "width=1928,height=1208"`
9. To allow other apps to use camera you have to make pipewire to use the new libcamera, this step depends on your distribution. You can test using [webrtc test page][11] in Firefox.

Don't disable keyboard and trackpad when tilted
--------
See [Issue #5][14].

Enable trackpad palm rejection
--------
The spectre has a very nice touchpad, but Linux doesn't set the correct quirks to enable the hardware palm rejection. You can install the [palm-rejection](palm-rejection.service) systemd service to automatically set the quirks until the hid-multitouch kernel module is updated.

```sh
sudo cp palm-rejection.service /etc/systemd/system
sudo systemctl enable palm-rejection.service
sudo systemctl start palm-rejection.service
```

[1]: https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/hp-spectre-x360-14-eu0xxx-f5a.dsl
[2]: https://github.com/thor2002ro/asus_zenbook_ux3402za/tree/main/Sound
[3]: https://docs.kernel.org/admin-guide/acpi/ssdt-overlays.html
[4]: https://github.com/thesofproject/acpi-scripts
[5]: https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/kernel-cs35l41.patch
[6]: https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/kernel-realtek.patch
[7]: https://github.com/CirrusLogic/linux-firmware/tree/main/cirrus
[8]: https://github.com/thesofproject/sof-bin/releases
[9]: https://gist.github.com/lamperez/d5b385bc0c0c04928211e297a69f32d7
[10]: https://raw.githubusercontent.com/aigilea/hp_spectre_x360_14_eu0xxx/main/kernel-realtek-69.patch
[11]: https://mozilla.github.io/webrtc-landing/gum_test.html
[12]: https://github.com/aigilea/hp_spectre_x360_14_eu0xxx/tree/master/board
[13]: https://github.com/aigilea/hp_spectre_x360_14_eu0xxx/issues/4
[14]: https://github.com/aigilea/hp_spectre_x360_14_eu0xxx/issues/5
[15]: https://github.com/aigilea/hp_spectre_x360_14_eu0xxx/issues/6
