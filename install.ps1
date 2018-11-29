#Requires -Version 5.0
#Requires -RunAsAdministrator

Function Deploy-Script {
    param (
        [parameter(mandatory = $true)][string]$ScriptName,
        [string]$ModulePath = $null
    )
    if ($PSVersionTable.OS) {
        if ($PSVersionTable.OS -Match "Windows") {$delimiter = ';' } else { $delimiter = ':'}
    }
    else { $delimiter = ';' }
    if ( ! $ModulePath ) { $ModulePath = ($env:PSModulePath -split ($delimiter))[0] }
    $srcpath = join-path $ModulePath $ScriptName
    New-Item -ItemType SymbolicLink -Path $srcpath -Value $PSScriptRoot -Force
}

Deploy-Script (Split-Path $PSScriptRoot -Leaf)
