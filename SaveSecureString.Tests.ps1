<#SDS Modified Pester Test file header to handle modules.#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = ( (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.' ) -replace '.ps1', '.psd1'
$scriptBody = "using module $here\$sut"
$script = [ScriptBlock]::Create($scriptBody)
. $script

Describe "SaveSecureString" {
    BEFOREALL {[Char[]]$chars = "Lorem Ipsem 1234567890~!@#$%^&`*()-_=+{}`"|''"
        $string = $chars -join ''
        Get-ChildItem $testdrive -filter SampleSavedSecret.txt | Remove-Item
    }
    AFTEREACH {Get-ChildItem $testdrive -filter SampleSavedSecret.txt | Remove-Item}
    

    IT "Confirming that my strings match" { $string | Should Be "Lorem Ipsem 1234567890~!@#$%^&`*()-_=+{}`"|''" }

    
    foreach ($i in (1,10,100,1000) ) {
        <#10000 iterations of that 43 character string will crash the secure string, but that gives lots of headroom.#>
        <#I cannot confirm that this appendchar method is a SECURE way to make things, so I advise against doing this. 
        Use Read-Host, which is what Save-SecureStringToFile does unless you pass it a SecureString.
        But I need to test it somehow. #>
        $s = [System.Security.SecureString]::NEW()
        foreach ($n in 1..$i) {
            foreach ($c in $chars) {
                $s.AppendChar($c)
            }
        }

        CONTEXT "For a string of $i repetitions of the 43 character (no [] and ``, which gave me trouble from a testing perspective) string: $string" {

            It "Save-SecureStringToFile fails when targeting an existing file name." {
            New-item -itemtype file $testdrive\SampleSavedSecret.txt -Value 'sample'
            $result = TRY { Save-SecureStringToFile -SecureString $s -OutFilePath $testdrive\SampleSavedSecret.txt } CATCH {$error[0].Exception | Out-String}
            $result | Should Be "Cannot validate argument on parameter 'OutFilePath'. 
$testdrive\SampleSavedSecret.txt exists already 
- please redirect destination or remove file.
" }

            It "Save-SecureStringToFile produces a file that does NOT contain the string $string" {
            $content = Get-Content  ( Save-SecureStringToFile -SecureString $s -OutFilePath $testdrive\SampleSavedSecret.txt -PassThru ) | Out-String
            $content -notlike "*$string*" | Should Be $true }

            It "Get-SecureStringFromFile -InPlainText produces the string $string" {
            Save-SecureStringToFile -SecureString $s -OutFilePath $testdrive\SampleSavedSecret.txt
            $content = Get-SecureStringFromFile -InPlainText -FullName $testdrive\SampleSavedSecret.txt
            [String]$testcondition = ''
            Foreach ($n in 1..$i) {$testcondition += $string}
            $content | SHOULD BE "$testcondition"  }
    
            It "Get-SecureStringFromFile produces a SecureString" {
            Save-SecureStringToFile -SecureString $s -OutFilePath $testdrive\SampleSavedSecret.txt
            (Get-SecureStringFromFile -FullName $testdrive\SampleSavedSecret.txt).GetType() | SHOULD BE 'SecureString' }

        }<#End CONTEXT #>

    }<#End Foreach 1,10,100,1000#>    
            
}<#END Describe "SaveSecureString" #>
