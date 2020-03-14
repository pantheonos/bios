tasks:
  always: => get "ms-compile"
  clone:  => clone "MCJack123/craftos2-rom", "reference/"
  unpack: => sh "cosrun image unpack project.yml"
  run:    => sh "cosrun run bios"
