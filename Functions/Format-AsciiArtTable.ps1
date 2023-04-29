
function Format-AsciiArtTable {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PsObject]
        $InputObject,

        [Parameter()]
        [string]
        $Delimiter = " | ",

        [Parameter()]
        [ValidateSet('Array','Scalar')]
        [string]
        $As = 'Scalar',

        [Parameter()]
        [ValidateRange('Positive')]
        [int]
        $LeftPad,

        [Parameter()]
        [ValidateSet('Default','None')]
        [Alias('LPad')]
        [string]
        $Header = 'None',

        [Parameter()]
        [Alias('LastDelimiter','TrailingDelimiter')]
        [switch]
        $IncludeTrailingDelimiter
    )

    $Columns = $InputObject[0] | ConvertTo-Json | jq keys_unsorted | ConvertFrom-Json | ForEach-Object {
        $i++
        $MaxLength = ($InputObject.$_ | ForEach-Object { $_.ToString().Length } | Measure-Object -Maximum).Maximum

        if($Header -eq 'Default'){
            if($_.Length -gt $MaxLength){
                $MaxLength = $_.Length
            }
        }

        [PsCustomObject]@{
            Ordinal   = $i
            Name      = $_
            MaxLength = [int]$MaxLength
            IsNotLast = $true
        }
    }

    $Columns[$(($Columns | Measure-Object).Count - 1)].IsNotLast = $IncludeTrailingDelimiter

    $HeaderRow = " "*$LeftPad
    foreach($column in $Columns){
        $whitespace = " " * $column.MaxLength
        $HeaderRow += "$($column.Name)${whitespace}".Substring(0,$column.MaxLength)
        $HeaderRow += if($column.IsNotLast){$Delimiter}
    }

    $SpacerRow = "-"*$LeftPad
    foreach($column in $Columns){
        $SpacerRow += "-" * $column.MaxLength
        $SpacerRow += if($column.IsNotLast){$Delimiter}
    }

    $OutputObject = @()

    if($Header -eq 'Default'){
        $OutputObject = @(
            $SpacerRow
            $HeaderRow
            $SpacerRow
        )
    }

    foreach($row in $InputObject) {
        $OutString = " "*$LeftPad
        foreach($column in $Columns){
            $whitespace = " " * $column.MaxLength
            $OutString += "$($row."$($column.Name)")${whitespace}".Substring(0,$column.MaxLength)
            $OutString += if($column.IsNotLast){$Delimiter}
        }
        $OutputObject += $OutString
    }

    switch($As){
        "Array"  { $OutputObject }
        "Scalar" { $OutputObject -join [Environment]::NewLine }
    }
}
