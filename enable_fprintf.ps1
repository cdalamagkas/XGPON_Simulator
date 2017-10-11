$MyFile = (gc Event1.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Event1.m', $MyFile)

$MyFile = (gc Event2.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Event2.m', $MyFile)

$MyFile = (gc Event3.m) -replace '%fprintf', 'fprintf' 
[System.IO.File]::WriteAllLines('Event3.m', $MyFile)

$MyFile = (gc Event4.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Event4.m', $MyFile)

$MyFile = (gc Event5.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Event5.m', $MyFile)

$MyFile = (gc Event6.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Event6.m', $MyFile)

$MyFile = (gc DBA.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('DBA.m', $MyFile)

$MyFile = (gc Guaranteed_BA.m) -replace '%fprintf', 'fprintf'
[System.IO.File]::WriteAllLines('Guaranteed_BA.m', $MyFile)