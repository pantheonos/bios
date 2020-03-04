term.clear()
term.setCursorPos(1, 1)
PA_PRINT("pantheon/entry " .. tostring(PA_VERSION))
local images = { }
for i, image in ipairs(fs.list("/boot")) do
  if not (fs.isDir("/boot/" .. image)) then
    PA_PRINT(tostring(i) .. ". " .. tostring(image))
    images[i] = "/boot/" .. image
  end
end
if #images == 1 then
  term.clear()
  dofile(images[1])
end
PA_PRINT("Please use the number row")
PA_PRINT("Choose an image to boot (number)")
local choice
while true do
  local _continue_0 = false
  repeat
    local event, param = os.pullEvent()
    if event == "char" then
      if tonumber(param) then
        choice = tonumber(param)
        if images[choice] then
          break
        else
          _continue_0 = true
          break
        end
      else
        _continue_0 = true
        break
      end
    else
      _continue_0 = true
      break
    end
    _continue_0 = true
  until true
  if not _continue_0 then
    break
  end
end
term.clear()
return dofile(images[choice])
