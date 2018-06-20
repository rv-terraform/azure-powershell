param(
    [Parameter(Mandatory = $false)]
    [string] $BuildConfig = "Debug",
    [Parameter(Mandatory = $false)]
    [string] $OutputFile = "$PSScriptRoot/outputtypes.json"
)

# Get all psd1 files
$psd1Files = Get-Childitem C:\azure-powershell\src\Package\$BuildConfig\ResourceManager -Recurse | where {$_.Name -like "*.psd1" }
$psd1Files += Get-Childitem C:\azure-powershell\src\Package\$BuildConfig\Storage -Recurse | where {$_.Name -like "*.psd1" }

$outputTypes = New-Object System.Collections.Generic.HashSet[string]

$psd1Files | ForEach {
    Import-LocalizedData -BindingVariable "psd1File" -BaseDirectory $_.DirectoryName -FileName $_.Name
    foreach ($nestedModule in $psd1File.NestedModules)
    {
        $dllPath = Join-Path -Path $_.DirectoryName -ChildPath $nestedModule
        $Assembly = [Reflection.Assembly]::LoadFrom($dllPath)
        $exportedTypes = $Assembly.GetTypes()
        foreach ($exportedType in $exportedTypes)
        {
            foreach ($attribute in $exportedType.CustomAttributes)
            {
                if ($attribute.AttributeType.Name -eq "OutputTypeAttribute")
                {
                    $outputTypes.Add($attribute.ConstructorArguments.Value.Value.FullName) | Out-Null
                }
            }
        }
    }
}

$json = ConvertTo-Json $outputTypes
$json | Out-File "$OutputFile"