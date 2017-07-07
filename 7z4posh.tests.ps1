using module ..\7z4posh;

function test1 {
	Write-Host "Test 1: default benchmark";
	$z = Create-7zipper;
	Benchmark-7z -zipper $z -verbouse;
	$z;
}

function test2 {
	Write-Host "Test 2: List archive";
	$z = Create-7zipper;
	List-7z -zipper $z -path '../../7ztest.7z';
	$z.process;
}

function test3 {
	Write-Host "Test 3: List encrypt archive";
	$z = Create-7zipper;
	List-7z -zipper $z -path '../../7zptest.7z' -password "Qq123456";
	$z.process;
}

function test4 {
	Write-Host "Test 4: Test archive's files";
	$z = Create-7zipper;
	Test-7z -zipper $z -archive '../../7ztest.7z';
}

function test5 {
	Write-Host "Test 5: Extract archive";
	$z = Create-7zipper;
	Extract-7z -zipper $z -archive '../../7ztest.7z' -out '../../';
}

function test6 {
  Write-Host "Test 6: Create default archive";
  $archName = 'temp.7z';
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName;
  $z;
}

function test7 {
  Write-Host "Test 7: Create default zip archive";
  $archName = 'temp.zip';
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName;
  $z;
  $z.Clean();
  List-7z -zipper $z -archive $archName;
  $z
}

function test8 {
  Write-Host "Test 8: Create default 7zip archive with -files";
  $archName = 'temp.7z'
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1';
  $z;
}

function test9 {
  $type = '_7z';
  Write-Host "Test 9: Create archive with -types $type";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type;
}

function test10 {
  $type = 'tar';
  Write-Host "Test 10: Create archive with -types 7z";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type;
}

function test11 {
  $type = 'GZip';
  Write-Host "Test 11: Create archive with -types $type";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter 'temp.tar' -type $type;
}

function test12 {
  $type = 'BZip2';
  Write-Host "Test 12: Create archive with -types $type";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter 'temp.tar' -type $type;
}

function test13 {
  $type = 'XZ';
  Write-Host "Test 13: Create archive with -types $type";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter 'temp.tar' -type $type;
}

function test14 {
  $type = 'WIM';
  Write-Host "Test 14: Create archive with -types $type";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type;
}

function test15 {
  $type = '_7z';
  Write-Host "Test 15: Create archive with compression";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type -compression Ultra;
  $z.process.args;
  $z.toString();
}

function test16 {
  $type = '_7z';
  Write-Host "Test 16: Create archive with -method";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type -method Copy ;
  $z.process.args;
  $z.toString();
  $z.Clean();
  List-7z -zipper $z -archive $archName;
}

function test17 {
  $type = '_7z';
  Write-Host "Test 17: Create archive with -multithread";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type -multithread 5;
  $z.process.args;
  $z.toString();
  $z.Clean();
  List-7z -zipper $z -archive $archName;
}

function test18 {
  $type = '_7z';
  Write-Host "Test 18: Create archive with -solid";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type -solid on ;
  $z.process.args;
  $z.toString();
  $z.Clean();
  List-7z -zipper $z -archive $archName;
}

function test19 {
  $type = '_7z';
  Write-Host "Test 19: Create archive with -password";
  $archName = "temp.$type";
  $z = Create-7zipper;
  Set-Location ~\temp;
  Add-7z -zipper $z -archive $archName -filter '*.ps1' -type $type -password '123';
  $z.process.args;
  $z.toString();
  $z.Clean();
  List-7z -zipper $z -archive $archName;
}

#test1;
#test2;
#test3;
#test4;
#test5;
#test6;
#test7;
#test8;
#test9;
#test10;
#test11;
#test12;
#test13;
#test14;
#test15;
#test16;
test17;
#test18;
#test19;
