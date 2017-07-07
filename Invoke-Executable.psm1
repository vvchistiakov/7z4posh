<#
.SYNOPSIS
Invoke executable binary programm
.DESCRIPTION
Execute program with args.
.PARAMETER fileName
Name of executable file.
.PARAMETER arg
Arguments to run exe file.
.PARAMETER verb
//TODO
.PARAMETER workDir
Working directory (workspace).
.PARAMETER verbouse
Switch to show output text to console.
.PARAMETER priority
Priority running process
.INPUTS
You can`t pipe objects to this cmdlet
.OUTPUTS
Object. Returns stdOut and stdErr stream. Also return start/stop process time,
exit code and startup args.
.EXAMPLE
Invoke-Executable -fileName 'c:\example.exe' -arg '-v -h' -workDir (Get-Item -Path '.\').FullName -verbouse;

#>
function Invoke-Executable {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$fileName,

    [parameter()]
    [string]$arg,

    [parameter()]
    [string]$verb,

    [parameter()]
    [string]$workDir,

    [parameter()]
    [switch]$verbouse,

    [parameter()]
    [ValidateSet('Idle', 'Normal', 'High', 'RealTime')]
    [string]$priority = 'Normal',

    [parameter()]
    [System.Text.Encoding]$encoding = [System.Text.Encoding]::UTF8
  )
  process {
    # Setting process invocation parameters
    $psi = New-Object -TypeName System.Diagnostics.ProcessStartInfo;
    $psi.FileName = $fileName;
    switch ($true) {
      {![string]::IsNullOrEmpty($arg)} {
        $psi.Arguments = $arg;
      }
      {![string]::IsNullOrEmpty($verb)} {
        $psi.Verb = $verb;
      }
      {![string]::IsNullOrEmpty($workDir)} {
        $psi.WorkingDirectory = $workDir;
      }
    }
    $psi.CreateNoWindow = $true;
    $psi.UseShellExecute = $false;
    $psi.RedirectStandardOutput = $true;
    $psi.StandardOutputEncoding = $encoding;
    $psi.RedirectStandardError = $true;
    $psi.StandardErrorEncoding = $encoding;

    # Creating process object
    $p = New-Object -TypeName System.Diagnostics.Process;
    $p.StartInfo = $psi;
    switch ($priority) {
      'Idle' { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle; }
      'Normal' { [System.Diagnostics.ProcessPriorityClass]::Normal; }
      'High' { [System.Diagnostics.ProcessPriorityClass]::High; }
      'RealTime' { [System.Diagnostics.ProcessPriorityClass]::RealTime; }
    }

    # Creating string builders to store stdout and stderr
    $stdOutBuilder = New-Object -TypeName System.Text.StringBuilder;
    $stdErrBuilder = New-object -TypeName System.Text.StringBuilder;

    # Adding event handers for stdout and stderr
    $stdHandler = {
      if (! [String]::IsNullOrEmpty($EventArgs.Data)) {
        $Event.MessageData[0].AppendLine($EventArgs.Data);
        # Check -verbouse
        if ($Event.Messagedata[1].IsPresent) {
          Write-Host $EventArgs.Data;
        }
      }
    }

    $stdOutEvent = Register-ObjectEvent -InputObject $p -Action $stdHandler -EventName 'OutputDataReceived' -MessageData $stdOutBuilder, $verbouse;
    $stdErrEvent = Register-ObjectEvent -InputObject $p -Action $stdHandler -EventName 'ErrorDataReceived' -MessageData $stdErrBuilder, $verbouse;

    # Starting process
    [void]$p.Start();
    $p.BeginOutputReadLine();
    $p.BeginErrorReadLine();
    while (!$p.HasExited) {
      $p.Refresh();
      Start-Sleep -Seconds 1;
    }

    $p.CancelOutputRead();
    $p.CancelErrorRead();

    # Unregistering events to retrieve process output.
    Unregister-Event -SourceIdentifier $stdOutEvent.Name;
    Unregister-Event -SourceIdentifier $stdErrEvent.Name;

    $result = New-Object -TypeName psobject -Property (
      @{
        'FileName' = $p.StartInfo.FileName;
        'Args' = $p.StartInfo.Arguments;
        'WorkingDirectory' = $p.StartInfo.WorkingDirectory;
        'StartTime' = $p.StartTime;
        'ExitTime' = $p.ExitTime;
        'ExitCode' = $p.ExitCode;
        'StdOut' = $stdOutBuilder.ToString();
        'StdErr' = $stdErrBuilder.ToString();
        'Verbouse' = $verbouse;
      }
    );

    return $result;
  }
}
