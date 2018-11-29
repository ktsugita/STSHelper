#Requires -Modules AWSPowerShell

$script:STSProfileName = 'STS'
$script:ProfileName = $null
$script:TargetName = $null
$script:TargetRole = $null
$script:Role = $null

Function New-STSCredenital {
    <#
.SYNOPSIS
New-STSCredential [特権プロファイル [通常プロファイル名 [一時プロファイル名]]]
.DESCRIPTION
STSを使って特権プロファイルにAssumeRoleするためのプロファイルを指定する
.EXAMPLE
New-STSCredential NegitAdmin Negit
.PARAMETER TargetProfile
取得したい特権を指定したプロファイル
.PARAMETER SourceProfile
取得したい特権にAssumeRoleするための通常プロファイル
.PARAMETER STSProfile
取得したSTS認証情報を保存するプロファイル(デフォルトはSTS)
#>
    param (
        [parameter(mandatory = $true)][string]$TargetProfile,
        [parameter(mandatory = $true)][string]$SourceProfile,
        [string]$STSProfile = $null
    )
    $script:TargetName = $TargetProfile
    $script:TargetRole = Get-AWSCredential -ProfileName $script:TargetName
    $script:ProfileName = $SourceProfile
    $script:Role = $null
    if ( $STSProfile ) { $script:STSProfileName = $STSProfile }
    Write-Host ("SourceProfile:{0}" -f $script:ProfileName)
    Write-Host ("TargetProfile:{0}" -f $script:TargetName)
    Write-Host 'iex (Update-STSCredential) を実行してください'
}
Export-ModuleMember -Function New-STSCredenital

Function Update-STSCredential {
    <#
.SYNOPSIS
Update-STSCredential [MFAコード] [必要な残り時間]
.DESCRIPTION
STSを使って特権プロファイルにAssumeRoleする
SessionTokenの残り時間があるときはMFA入力しないで更新する
それ以外はMFAコードの入力を求められる
.EXAMPLE
iex (Update-STSCredential)
.PARAMETER Force
現在のSessionTokenを破棄して新たに取得する
MFAコードの入力を求められる
#>
    param ([switch]$Force)
    if ( ! $script:TargetName ) { Write-Error "New-STSCredential を実行してください"; return 'Write-Error "New-STSCredential を実行してください"' }
    if ( ! $script:TargetRole ) { $script:TargetRole = Get-AWSCredential -ProfileName $script:TargetName }
    if ( ! $script:ProfileName ) { Write-Error "New-STSCredential を実行してください"; return 'Write-Error "New-STSCredential を実行してください"' }
    if ($Force) { $script:Role = $null }
    if ( $script:Role -and ((Get-Date) -lt ($script:Role.Credentials.Expiration))) {
        $script:Role = Use-STSRole -RoleArn $script:TargetRole.RoleArn -RoleSessionName $script:TargetRole.RoleSessionName -ProfileName $script:STSProfileName
    }
    else {
        $script:Role = Use-STSRole -RoleArn $script:TargetRole.RoleArn -RoleSessionName $script:TargetRole.RoleSessionName -ProfileName $script:ProfileName -SerialNumber $script:TargetRole.Options.MfaSerialNumber -TokenCode (Read-Host -Prompt 'MFA Code')
    }
    if ( $script:Role ) {
        Set-AWSCredential -StoreAs $script:STSProfileName -AccessKey $script:Role.Credentials.AccessKeyId -SecretKey $script:Role.Credentials.SecretAccessKey -SessionToken $script:Role.Credentials.SessionToken
        return ("Set-AWSCredential -ProfileName {0}" -f $script:STSProfileName)
    }
}
Export-ModuleMember -Function Update-STSCredential

Function Get-STSCredential {
    <#
.SYNOPSIS
Get-STSCredential
.DESCRIPTION
SessionTokenを格納するプロファイル、AssumeRoleするためのプロファイル、SessionTokenの残り時間を得る
.EXAMPLE
Get-STSCredential
#>
    [PSCustomObject]@{
        STSProfileName = $script:STSProfileName
        SourceProfile  = $script:ProfileName
        TargetProfile  = $script:TargetName
        Expiration     = $script:Role.Credentials.Expiration
    }
}
Export-ModuleMember -Function Get-STSCredential
