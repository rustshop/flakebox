{ runCommand
, config
}:
runCommand "flakebox-share-dir" { } ''
  cp -rT ${../share} $out
''
