Param(
    [ValidateSet('new', 'install', 'publish', 'cleanup', 'help')]
    [String[]]$Command = @('new', 'install'),
    [String]$ModuleName = 'STSHelper',
    [Version]$ModuleVersion = [Version]::New(1, 0, 0, 0),
    [String]$ModulePath = $PWD,
    [String]$Repository = 'combackup01'
)

Function New-ThisManifest {
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module $ScriptFile -Force
    $s = Get-Module $ModuleName -ErrorAction Stop
    $param = @{
        GUID              = 'eed0d62d-7f26-4c6a-93c2-b155957d8605'
        Path              = $ManifestFile
        Author            = (git config --get user.name)
        RootModule        = $ScriptFile
        ModuleVersion     = $ModuleVersion
        Description       = "STSHelper"
        FileList          = @($ManifestFile, $ScriptFile)
        FunctionsToExport = @($s.ExportedFunctions.Keys)
        CmdletsToExport   = @($s.ExportedCmdlets.Keys)
        VariablesToExport = @($s.ExportedVariables.Keys)
        AliasesToExport   = @($s.ExportedAliases.Keys)
    }
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    New-ModuleManifest @param
}

Function Install-ThisModule {
    $TargetModulePath = ($env:PSModulePath -split ('; '))[0]
    $ModulePath = New-Item -Path $TargetModulePath -Name $ModuleName -ItemType Directory -Force
    @($ManifestFile, $ScriptFile) | Copy-Item -Destination $ModulePath
}

Function Publish-ThisModule {
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module $ManifestFile -Force
    $m = Get-Module $ModuleName -ErrorAction Stop
    $param = @{
        Name            = $m.Name
        Repository      = $Repository
        RequiredVersion = $m.Version
    }
    Get-PSRepository -Name $Repository -ErrorAction Stop
    Test-ModuleManifest -Path $ManifestFile -ErrorAction Stop
    Publish-Module @param
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
}

Function Remove-ThisModule {
    $TargetModulePath = ($env:PSModulePath -split ('; '))[0]
    Join-Path $TargetModulePath $ModuleName -Resolve | Remove-Item -Recurse -Force
}

$ManifestFile = "{0}.psd1" -f $ModuleName
$ScriptFile = "{0}.psm1" -f $ModuleName

$Command | ForEach-Object {
    switch ($_) {
        'new' { New-ThisManifest }
        'install' { Install-ThisModule }
        'publish' { Publish-ThisModule }
        'cleanup' { Remove-ThisModule }
        default {
            $s = Split-Path -Leaf $PSCommandPath
            write-host "./$s コマンド0個以上"
            write-host "./$s new | マニフェスト作成・更新"
            write-host "./$s install | モジュールを仮インストール"
            write-host "./$s publish | モジュールを作成してリポジトリにアップロード"
            write-host "./$s cleanup | 仮インストールしたモジュール削除"
            write-host "./$s help | これを表示"
            write-host "./$s | デフォルトでは new と install を実行"
        }
    }
}
