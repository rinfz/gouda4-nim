# Package

version       = "4.0.0"
author        = "fxcqz"
description   = "A dotty cheesebot"
license       = "BSD-3-Clause"
srcDir        = "src"
bin           = @["gouda"]
binDir        = "bin"


# Dependencies

requires "nim >= 0.19.0"


# Tasks

task run, "Build and run Gouda":
  exec "nimble build -d:ssl && bin/gouda"

task build_release, "Build a release binary":
  exec "nimble build -d:ssl -d:release --opt:speed && strip bin/gouda"
