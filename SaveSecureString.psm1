
function Save-SecureStringToFile {

<#
.SYNOPSIS
Saves secure string to disk as string encrypted with Windows DPAPI.

.DESCRIPTION
Implements guidance in the technet article Working with Passwords, Secure Strings and Credentials in Windows PowerShell (see link).

.LINK
https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx

.LINK
https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Security/ConvertFrom-SecureString?view=powershell-5.1

.LINK
https://blogs.technet.microsoft.com/robcost/2008/05/01/powershell-tip-storing-and-using-password-credentials/

#>

#Cmdlet Binding Attributes
[CmdletBinding(DefaultParameterSetName ="Default",PositionalBinding=$false <#True auto-enables positional. If false, [Parameter(Position=n)] overrides for those params.#>
)]
[OutputType('System.IO.FileInfo', ParameterSetName = 'PassThru')]
PARAM(
    [Parameter(
    Mandatory                         = $true
,    Position                          = 0
)][ValidateNotNullorEmpty()][ValidateScript({<#Confirm that a proposed file path is in a directory and is valid#>
              IF (Test-Path -PathType Leaf -Path $_) 
                  {Throw "$_ exists already - please redirect destination or remove file."}
              ELSE {$true}
              IF (Test-Path -PathType Container -Path (Split-Path $_ -Parent) ) 
                  {$true}
              ELSE {
                  Throw "$_ is not in a Directory - please create directory or redirect destination."
              } 
              IF (Test-Path -Path $_ -IsValid) {$true}
              ELSE {
                  Throw "File name $_ is not valid."
              }
        })][String]$OutFilePath
    ,[Parameter(ParameterSetName = 'PassThru')][SWITCH]$PassThru
    ,[Parameter(Mandatory= $false)][System.Security.SecureString]$SecureString
)

BEGIN{Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState}<#End Begin#>
PROCESS{

    IF (-not $PSBoundParameters.ContainsKey('SecureString'))     {[System.Security.SecureString]$SecureString = Read-Host -Prompt 'Save-SecureStringToFile: Enter Secret to Save:' -AsSecureString }

    ConvertFrom-SecureString -SecureString $SecureString | Out-File $OutFilePath

    $outFile = Get-ChildItem $OutFilePath

    Write-Verbose $outFile

    IF ($PassThru.IsPresent) {
        RETURN $OutFilePath
    }

}<#End Process#>
END{}<#End End#>

} <#END FUNCTION Save-SecureStringToFile #>

FUNCTION Get-SecureStringFromFile{

<#
.SYNOPSIS
Retrieves a securestring stored as an encrypted string in a file.
Can optionally unwrap the string in plain text.

.DESCRIPTION
Implements guidance in the technet article Working with Passwords, Secure Strings and Credentials in Windows PowerShell (see link).

.LINK
https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx

.LINK
https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Security/ConvertFrom-SecureString?view=powershell-5.1

.LINK
https://blogs.technet.microsoft.com/robcost/2008/05/01/powershell-tip-storing-and-using-password-credentials/

#>

#Cmdlet Binding Attributes
[CmdletBinding(DefaultParameterSetName ="Default",PositionalBinding=$false <#True auto-enables positional. If false, [Parameter(Position=n)] overrides for those params.#>
)]
[OutputType('System.Security.SecureString',ParameterSetName='Default')]
[OutputType('System.String',ParameterSetName='InPlainText')]
PARAM(
    [Parameter(
     Mandatory                         = $true
    ,    Position                          = 0
    )][ValidateNotNullorEmpty()][ValidateNotNullorEmpty()][ValidateScript({
        IF (Test-Path -PathType leaf -Path $_ ) 
            {$True}
        ELSE {
            Throw "$_ is not a file."
        } 
    })][String]$FullName
    ,[Parameter(ParameterSetName = "InPlainText")][Switch]$InPlainText
)

BEGIN{Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState}<#End Begin#>
PROCESS{
    [System.Security.SecureString]$SecureString = Get-Content $FullName | ConvertTo-SecureString

    IF($PSCmdlet.ParameterSetName -eq 'Default') {Return $SecureString}

    If($PSCmdlet.ParameterSetName -eq 'InPlainText') {Return $([System.Management.Automation.PSCredential]::New('username',$SecureString).GetNetworkCredential().Password )}

}<#End Process#>
END{}<#End End#>

}<#End Function Get-SecureStringFromFile#>


Export-ModuleMember -Function 'Get-SecureStringFromFile'
Export-ModuleMember -Function 'Save-SecureStringToFile'
