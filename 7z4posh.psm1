New-Variable -Name zbin -Scope script;


$script:root = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$script:mtCountMax = [int](Get-Item Env:NUMBER_OF_PROCESSORS).value;
switch ([Environment]::Is64BitOperatingSystem) {
  ($true) {
    $script:zbin = Join-Path -Path ($script:root) -ChildPath '7z\x64\7z.exe';
  }
  default {
    $script:zbin = Join-Path -Path ($script:root) -ChildPath '7z\7z.exe';
  }
}

class ZipperProcess {
  $fileName;
  $workingDirectory;
  $args;
  $stdOut;
  $stdErr;
  $startTime;
  $exitTime;
  $exitCode;
  $verbouse;

  ZipperProcess() {
  }

  [void] Clean() {
    $this.fileName = $null;
    $this.workingDirectory = $null;
    $this.args = $null;
    $this.stdOut = $null;
    $this.stdErr = $null;
    $this.startTime = $null;
    $this.exitTime = $null;
    $this.exitCode = $null;
  }

  [string] ToString() {
    return $this.exitCode;
  }
}

class Zipper {
  [ZipperProcess]$process;
  [System.IO.FileInfo]$item;

  Zipper() {
    $this.process = [ZipperProcess]::New();
    $this.item = Get-Item -Path $script:zbin;
  }

  Zipper([string]$path) {
    $this.process = [ZipperProcess]::New();
    if (!(Test-Path $path)) {
      trow New-Object System.IO.FileNotFoundException('Archiver bin file not found', $path);
    }
    $this.item = Get-Item -Path $path;
  }

  [void] Run() {
    $p = Invoke-Executable -fileName $this.item.FullName -arg $this.process.args -workDir (Get-Item -Path '.\').FullName -verbouse:$this.process.verbouse -encoding ([System.Text.Encoding]::GetEncoding(866));

    $this.process.fileName = $p.fileName;
    $this.process.workingDirectory = $p.workingDirectory;
    $this.process.stdOut = $p.stdout;
    $this.process.stdErr = $p.stdErr;
    $this.process.startTime = $p.startTime;
    $this.process.exitTime = $p.exitTime;
    $this.process.exitCode = $p.exitCode;
  }

  [void] Clean() {
    $this.process.Clean();
  }

  [void] AddSwitch([string]$switch) {
    $this.process.args += " $switch";
  }

  [string] ToString() {
    return $this.process.ToString();
  }
}

enum ZipperAddType {
  Zip;
  Tar;
  GZip;
  BZip2;
  _7z;
  XZ;
  WIM;
}

enum ZipperCompression {
  Store = 0;
  Fastest = 1;
  Fast = 3;
  Normal = 5;
  Maximum = 7;
  Ultra = 9;
}

enum ZipperZipMethod {
  Copy;
  Deflate;
  Deflate64;
  BZip2;
  LZMA;
  PPMd;
}

enum Zipper7zMethod {
  LZMA;
  LZMA2;
  PPMd;
  BZip2;
  Deflate;
  Delta;
  BCJ;
  BCJ2;
  Copy;
}

enum ZipperMultithread {
  On;
  Off;
}

enum ZipperSolid {
  On;
  Off;
}

<#
.SYNOPSIS
Create 7z object.
.DESCRIPTION
Creating an object that handles the file.
.PARAMETER path
Path to binary file.
.INPUTS
You can`t pipe object to cmdlets
.OUTPUTS
Zipper
.EXAMPLE
Create-7zipper -path c:\7za.exe
#>
function Create-7zipper {
  [cmdletbinding()]
  param(
    [parameter()]
    [string]$path = $script:zbin
  )

  process {
    return [Zipper]::New($path);
  }
}

<#
.SYNOPSIS
Benchmark on computer.
.DESCRIPTION
Test speed archive on computer.
.PARAMETER zipper
Zip object, created of cmdlet Create-7zipper.
.PARAMETER iterations
Number of iterations.
.PARAMETER quiet
Don't show stdout after run.
.INPUTS
You can`t pipe object to cmdlets
.OUTPUTS
Object with args, exit and out stream $_.process.out
Fill $zipper.process.
.EXAMPLE
Benchmark-7z -zipper $7z
#>
function Benchmark-7z {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true)]
    [psobject]$zipper,

    [parameter()]
    [int]$iterations = 1,

    [parameter()]
    [switch]$quiet
  )
  process {
    $zipper.process.verbouse = !$quiet;
    $zipper.process.args = "b $iterations";
    $zipper.Run();
    return $zipper;
  }
}

<#
.SYNOPSIS
List archive
.DESCRIPTION
List archive file.
.PARAMETER zipper
Zip object, created of cmdlet Create-7zipper.
.PARAMETER archive
Path to archive file.
.PARAMETER quiet
Don't show stdout after run.
.INPUTS
String. You can use pipeline from path to archive.
.OUTPUTS
Object with args, exit and out stream $_.process.out
Fill $zipper.process.
#>
function List-7z {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true)]
    [psobject]$zipper,

    [parameter(ValueFromPipeline = $true)]
    [Alias('path')]
    [string]$archive,

    [Parameter()]
    [string]$password,

    [Parameter()]
    [switch]$quiet
  )
  process {
    $zipper.process.verbouse = !$quiet;
    $zipper.AddSwitch("l $archive");
    switch ($true) {
      {$password.Length -ne 0} {
        $zipper.AddSwitch("-p$password");
      }
    }

    $zipper.Run();
    return $zipper;
  }
}

<#
.SYNOPSIS
Test archive file.
.DESCRIPTION
Simple test archive files.
.PARAMETER zipper
Zip object, created of cmdlet Create-7zipper.
.PARAMETER archive
Path to archive file.
.PARAMETER files
wildcard of files in archive for testing. By default use all files '*' wildcard.
.PARAMETER password
Specifies password.
.PARAMETER quiet
Don't show stdout after run.
.INPUTS
String. You can use pipeline from path to archive.
.OUTPUTS
Object with args, exit and out stream $_.process.out
Fill $zipper.process.
#>
function Test-7z {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true)]
    [psobject]$zipper,

    [parameter(ValueFromPipeline = $true)]
    [Alias('path')]
    [string]$archive,

    [parameter()]
    [string]$files = '*',

    [parameter()]
    [string]$password
  )

  process {
    $zipper.process.verbouse = !$quiet;
    $zipper.AddSwitch("t $archive $files");
    switch ($true) {
      {$password.Length -ne 0} {
        $zipper.AddSwitch("-p$password");
      }
    }
    $zipper.Run();
    return $zipper;
  }
}

<#
.SYNOPSIS
Extract archive file.
.DESCRIPTION
Extracts files from an archive to the current directory or to the output directory.
The output directory can be specified by -out (Set Output Directory) parameter.
This cmdlet copies all extracted files to one directory.
.PARAMETER zipper
Zip object, created of cmdlet Create-7zipper.
.PARAMETER archive
Path to archive file.
.PARAMETER fullPath
If you want extract files with full paths, you must use this parameter.
.PARAMETER out
Specifies a destination directory where files are to be extracted.
.PARAMETER password
Specifies password.
.PARAMETER quiet
Don't show stdout after run.
.PARAMETER overwrite
Specifies the overwrite mode during extraction, to overwrite files already present on disk.
.PARAMETER type
Specifies the type of archive.
.INPUTS
String. You can use pipeline from path to archive.
.OUTPUTS
Object with args, return $zipper and out stream $zipper.process.out
Fill $zipper.process
#>
function Extract-7z {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true)]
    [psobject]$zipper,

    [parameter(ValueFromPipeline = $true)]
    [Alias('path')]
    [string]$archive,

    [parameter()]
    [switch]$fullPath,

    [parameter()]
    [Alias('destination')]
    [string]$out,

    [parameter()]
    [string]$password,

    [parameter()]
    [switch]$quiet,

    [parameter()]
    [ValidateSet('All', 'Skip', 'RenameExtracting', 'RenameExisting')]
    [string]$overwrite = 'Skip',

    [parameter()]
    [string]$type
  )
  process {
    #fullpath param
    switch ($fullPath.IsPresent) {
      $true {
        $zipper.AddSwitch("x -y $archive");
      }
      default {
        $zipper.AddSwitch("e -y $archive");
      }
    }

    #advanced parameters
    switch ($true) {
      {$out.Length -ne 0} {
        $zipper.AddSwitch("-o$out");
      }
      {$password.Length -ne 0} {
        $zipper.AddSwitch("-p$password");
      }
      {$type.Length -ne 0} {
        $zipper.AddSwitch("-t$type");
      }
    }

    #overwrite mode
    switch ($overwrite) {
      'All' {
        $zipper.AddSwitch('-oao');
        break;
      }
      'Skip' {
        $zipper.AddSwitch('-aos');
        break;
      }
      'RenameExtracting' {
        $zipper.AddSwitch('-aou');
        break;
      }
      'RenameExisting' {
        $zipper.AddSwitch('-aot');
        break;
      }
    }

    $zipper.Run();
    return $zipper;
  }
}

<#
.SYNOPSIS
Create archive
.DESCRIPTION
Add files to arhive.
.PARAMETER zipper
Zip object, created of cmdlet Create-7zipper.
.PARAMETER archive
Path to archive file.
.PARAMETER filter
Wildacrd to mark files.
.PARAMETER out
Specifies a destination directory where files are to be extracted.
7-Zip treats *.* as matching the name of any file that has an extension. To process all files, you must use a * wildcard.
.PARAMETER type
Specifies the type of archive.
.PARAMETER password
Specifies password.
.PARAMETER quiet
Switch to not show process output to console
.PARAMETER deleteFilesAfterArchiving
If switch is specified, 7-Zip deletes files after including to archive. So it works like moving files to archive.
7-Zip deletes files at the end of operation and only if archive was successfully created.
.PARAMETER method
Sets a compress method.
.PARAMETER compression
Sets level of compression.
.PARAMETER multithread
Sets multithreading mode.
.PARAMETER solid
Sets solid mode.
.INPUTS
.OUTPUTS
Zipper
#>
function Add-7z {
  param(
    [Parameter(mandatory = $true)]
    [Zipper]$zipper,

    [Parameter(valueFromPipeline = $true, mandatory = $true)]
    [Alias('path')]
    [string]$archive,

    [Parameter()]
    [string]$filter,

    [Parameter()]
    [ZipperAddType]$type,

    [Parameter()]
    [string]$password,

    [Parameter()]
    [switch]$quiet,

    [Parameter()]
    [switch]$deleteFilesAfterArchiving
  )

  dynamicParam {
    # method
    $methodAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute;
    $methodAttribute.mandatory = $false;
    $methodAttribute.helpMessage = 'Enter method:';
    $methodAttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute];
    $methodAttributeCollection.Add($methodAttribute);

    # compression
    $compressionAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute;
    $compressionAttribute.mandatory = $false;
    $compressionAttribute.HelpMessage = 'Enter compression type:';
    $compressionAttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute];
    $compressionAttributeCollection.Add($compressionAttribute);
    $compressionParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('compression', [ZipperCompression], $compressionAttributeCollection);

    # multithread
    $multithreadAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute;
    $multithreadAttribute.mandatory = $false;
    $multithreadAttribute.HelpMessage = 'Switch multitread mode:';
    $multithreadAttributeValidateRange = New-Object -TypeName System.Management.Automation.ValidateRangeAttribute(0, $script:mtCountMax);
    $multithreadAttributeDefaultValue = New-Object -TypeName System.Management.Automation.PSDefaultValueAttribute;
    $multithreadAttributeDefaultValue.Value = 0;
    $multithreadAttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute];
    $multithreadAttributeCollection.Add($multithreadAttribute);
    $multithreadAttributeCollection.Add($multithreadAttributeValidateRange);
    $multithreadAttributeCollection.Add($multithreadAttributeDefaultValue);
    $multithreadParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('multithread', [int], $multithreadAttributeCollection);

    # solid
    $solidAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute;
    $solidAttribute.Mandatory = $false;
    $solidAttribute.HelpMessage = 'Switch solid mode:';
    $solidAttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute];
    $solidAttributeCollection.Add($solidAttribute);

    switch ($type) {
      '_7z' {
        $methodParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('method', [Zipper7zMethod], $methodAttributeCollection);
        $solidParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('solid', [ZipperSolid], $solidAttributeCollection);
        break;
      }
      'Zip' {
        $methodParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter('method', [ZipperZipMethod], $methodAttributeCollection);
        $solidParameter = $null;
        break;
      }
      'GZip' {
        $multithreadParameter = $null;
      }
      'Tar' {
        $compressionParameter = $null;
        $multithreadParameter = $null;
      }
      default {
        $methodParameter = $null;
        $solidParameter = $null;
        break;
      }
    }

    $parametersDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary;
    $parametersDictionary.Add('method', $methodParameter);
    $parametersDictionary.Add('compression', $compressionParameter);
    $parametersDictionary.Add('multithread', $multithreadParameter);
    $parametersDictionary.Add('solid', $solidParameter);
    return $parametersDictionary;
  }

  begin {
    # quiet mode
    $zipper.process.verbouse = !$quiet;
  }
  process {
    # add operation
    $zipper.AddSwitch("a $archive");
    # filter
    if ($filter) {
      $zipper.AddSwitch("$filter");
    }
    switch ($type) {
      # type
      {$type -ne $null} {
        # trim start '_'
        $zipper.AddSwitch("-t$($_.ToString().TrimStart('_'))");
      }
      '_7z' {
        # method
        if ($PSBoundParameters.method -ne $null) {
          $zipper.AddSwitch("-m0=$($PSBoundParameters.method)");
        }
      }
      'Zip' {
        # method
        if ($PSBoundParameters.method -ne $null) {
          $zipper.AddSwitch("-m=$($PSBoundParameters.method)");
        }
      }
      {$true} {
        # compression
        if ($PSBoundParameters.compression -ne $null) {
          $zipper.AddSwitch("-mx=$([int]$PSBoundParameters.compression)");
        }

        # multithread
        if ($PSBoundParameters.multithread -ne $null) {
          $zipper.AddSwitch("-mmt=$($PSBoundParameters.multithread)");
        }

        # solid
        if ($PSBoundParameters.solid -ne $null) {
          $zipper.AddSwitch("-ms=$($PSBoundParameters.solid)");
        }
      }
    }
    # password
    if ($password) {
      $zipper.AddSwitch("-pass=$password");
    }

    # delete files
    if ($deleteFilesAfterArchiving.IsPresent) {
      $zipper.AddSwitch('-sdel');
    }

    #start process
    $zipper.Run();
    return $zipper;
  }
}
