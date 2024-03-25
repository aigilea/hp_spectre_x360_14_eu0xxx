Linux on HP Spectre x360 14-eu0xxx
=====
The latest and greatest Spectre x360 iteration offers new Core Ultra 155H with new ARC GPU which is at least twice as fast compared to the Xe graphics found in a few last generations, VPU for AI acceleration and many other cool features.

But can it run Linux?

Should you buy it?
--------
Linux won't boot without ACPI overlay and Secure Boot thus won't be usable until HP fixes the ACPI (probably never).

Synaptics releases Linux-compatible firmware only if requested by the vendor so fingerprint reader won't work without HP say-so (none of previous generations got one working).

Camera has two sensors connected to IPU6 via MIPI. Main sensor (ov08x40) has a linux driver but it's neither int3472-aware nor libcamera-compatible, IR sensor (og0va1b) doesn't have a driver at all. Neither of sensors is supported by Intel VPU6 stack (although it looks like support for ov08x40 may be coming), the same with libcamera (but this one can at least be patched) so it's unlikely either of this sensors will work without patching for at least another year.

Otherwise it's a solid laptop, but think twice.

How to install?
--------
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
    * These fixes have been submitted and accepted so you don't have to patch the kernel if you're using 6.9 or later.
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
