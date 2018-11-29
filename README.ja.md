# STSHelper
STS Credential Helper for AWSPowerShell

# AWS PowerShell で MFA入力を減らしてみる

AWS PowerShell 使ってますか？

awscliはMFA対応がちゃんとしていて、一度MFA入力したらしばらく大丈夫ですが、AWSPowerShellだと入力の都度求められて嫌になりますよね。

PowerShellでもスクリプトスコープの変数にSessionTokenを突っ込めばイケそうなきがしたので実装してみました。

# インストール方法1

モジュール内部からAWSPowerShellを使うのでインストールしておいてください。
msi版でもよいですが、PowerShell v5.x(Windows10)なら`install-module awspowershell`でもインストールできます。

スクリプトモジュールとして実装したので、 [STSHelper.psm1](https://gist.github.com/ktsugita/acbc2f92210ea2e06d2f2cf4fbf32d39/raw/870d9df3c2488a7ec51413d8dd13399628fa2bc8/STSHelper.psm1) をダウンロードして、BOM付きUTF-8で保存して、下記の要領でインストールしてください。


```PowerShell:install.ps1
$destdir = Join-Path $env:PSModulePath.split(';')[0] "STSHelper"
if (Test-Path $destdir) {} else { mkdir $destdir }
copy-item STSHelper.psm1 $destdir
```

この方法でインストールした時は `$env:PSModulePath` の最初のフォルダにある `STSHelper` フォルダを削除するとアンインストールできます。

# インストール方法2

`git clone` したリポジトリで、`install.ps1` を実行してください。

この方法でインストールした時は `$env:PSModulePath` の最初のフォルダにある `STSHelper` というシンボリックリンクを削除するとアンインストールできます。


# 使用方法

## 準備

認証情報をプロファイルに保存します

* <ソースプロファイル> IAMアカウントのアクセスキーを指定したプロファイル

	```PowerShell
	Set-AWSCredential -StoreAs <ソースプロファイル> -AccessKey <アクセスキー> -SecretKey <シークレットキー>
	```

* <ターゲットプロファイル> AssumeRole先を指定したプロファイル

	```PowerShell
	Set-AWSCredential -StoreAs <ターゲットプロファイル> -SourceProfile <ソースプロファイル> -RoleArn <ロールのARN> -MfaSerial <MFAのARN>
	```

毎回起動時に設定するのは大変なので下記の`profile.ps1`に書いておくのがおすすめ

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1
```

`profile.ps1`について詳しく知りたい場合は [PowerShell で Profile を利用して スクリプトの自動読み込みをしてみよう](http://tech.guitarrapc.com/entry/2013/09/23/164357) が詳しいです。


## 利用

```PowerShell
import-module STSHelper
New-STSCredential <ターゲットプロファイル> <ソースプロファイル>
iex (Update-STSCredential)
```

以降は`iex `... だけで更新されます。

```PowerShell
iex (Update-STSCredential)
```

プロセス起動毎に初回利用時または期限切れのときはMFA入力が求められます。
それ以外は新たなMFA入力無しで1時間延長です。
メモリ(スクリプトスコープの変数)に保存しているのでランタイム毎に必要です。
スクリプト内でプロファイル保存しても呼び出し元に反映されないので`iex`してます。

## 期限の確認

```PowerShell
Get-STSCredential
```

# 課題

ファイルに保存すればランタイムをまたげると思うのですが、生で保存したくないので実装していません。

awscliみたいに無効時に必要に応じて自動的に呼び出せるようにしたいかな。
