-- pantheon/bios.entry
-- Entrypoint for the bootloader
-- By daelvn

term.clear!
term.setCursorPos 1, 1
PA_PRINT "pantheon/entry #{PA_VERSION}"

-- List images in /boot/
images = {}
for i, image in ipairs fs.list "/boot"
  unless fs.isDir "/boot/"..image
    PA_PRINT "#{i}. #{image}"
    images[i] = "/boot/"..image

-- see if /etc/entry.conf exists
if fs.exists "/etc/entry.conf"
  local content
  with fs.open "/etc/entry.conf", "r"
    content = .readAll!
    .close!
  for img in *images
    if img == content
      term.clear!
      dofile img

-- Boot directly if only one exists
if #images == 1
  term.clear!
  -- Run image
  dofile images[1]

-- Let the user choose an image to boot
-- We don't have print or read, so we have to use primitives
PA_PRINT "Please use the number row"
PA_PRINT "Choose an image to boot (number)"
local choice
while true
  event, param = os.pullEvent!
  if event == "char"
    if tonumber param
      choice = tonumber param
      if images[choice]
        break
      else continue
    else continue
  else continue

term.clear!

-- Run image
dofile images[choice]