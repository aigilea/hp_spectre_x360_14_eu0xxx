DefinitionBlock ("", "SSDT", 5, "aigi  ", "x360-eu0", 0x02000000)
{
    External(PNVA, OpRegionObj)
    External (_SB_.PC00.I2C3, DeviceObj)
    External (_SB_.PC00.RP10.PXSX, DeviceObj)

    //
    // Problem: Kernel Panic during boot.
    //
    // IC03 integer is declared in the root namespace and is supposed to be used in I2C3._PS3.
    // Issue is caused by _SB.PC00.IC03 device which is declared in one of SSDTs and comes first during name evaluation.
    // Providing a shorter path to the correct value by declaring it right inside I2C3 solves the issue.
    //
    Scope (_SB.PC00.I2C3)
    {
        Field (PNVA, AnyAcc, Lock, Preserve)
        {
            Offset (0x17F),
            IC03, 64,
        }
    }

    //
    // Problem: WiFi adapter doesn't resume after suspend.
    //
    // RP10.PXSX looks like it was initially supposed to be a storage device and wasn't updated after the port repurpose.
    // Power source pin PWRG{S3PG, S3PP} is zero and reset pin RSTG{S3RG, S3RP} (0x140414) is readonly so device is
    // neither powered down nor reset during D3cold transitions causing LTSSM to fail establishing PCIE link.
    //
    // Proper solution is to find real power and reset pins but it's not feasible until schematics/boardview is leaked.
    // For now 'good enough' solution is to just disable D3cold and go with D3hot.
    //
    Name (_SB.PC00.RP10.PXSX._S0W, 3)
}
