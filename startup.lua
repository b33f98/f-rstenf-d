local dfpwm = require("cc.audio.dfpwm")
local url = "https://github.com/b33f98/f-rstenf-d/raw/refs/heads/main/S.T.S%20F%C3%BCrstenfeld%20HD.dfpwm"
local volume = 3
local speakers = { peripheral.find("speaker") }
peripheral.find("modem", rednet.open)

local function paused()
  for _, side in ipairs(rs.getSides()) do
    if rs.getInput(side) then return true end
  end
  return false
end

local function resetAll()
  rednet.broadcast("reset", "music")
  for _, s in ipairs(speakers) do s.stop() end
end

print("Downloading...")
local h = assert(http.get(url, nil, true))
local data = h.readAll()
h.close()
print("Playing")

while true do
  local decoder = dfpwm.make_decoder()
  resetAll()
  for pos = 1, #data, 4096 do
    if paused() then
      resetAll()
      while paused() do os.pullEvent("redstone") end
    end
    local chunk = data:sub(pos, pos + 4095)
    rednet.broadcast(chunk, "music")
    local buffer = decoder(chunk)
    local jobs = {}
    for _, s in ipairs(speakers) do
      jobs[#jobs + 1] = function()
        while not s.playAudio(buffer, volume) do
          os.pullEvent("speaker_audio_empty")
        end
      end
    end
    parallel.waitForAll(table.unpack(jobs))
  end
  sleep(3) -- let the end of the song finish before looping
end
