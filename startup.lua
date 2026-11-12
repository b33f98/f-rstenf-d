local dfpwm = require("cc.audio.dfpwm")
local url = "https://github.com/b33f98/f-rstenf-d/raw/refs/heads/main/S.T.S%20F%C3%BCrstenfeld%20HD.dfpwm"
local volume = 3 -- 0 to 3, default is 1
local speakers = { peripheral.find("speaker") }

local function paused()
  for _, side in ipairs(rs.getSides()) do
    if rs.getInput(side) then return true end
  end
  return false
end

print("Downloading...")
local h = assert(http.get(url, nil, true))
local data = h.readAll()
h.close()
print("Playing")

while true do
  local decoder = dfpwm.make_decoder()
  for pos = 1, #data, 4096 do
    if paused() then
      for _, s in ipairs(speakers) do s.stop() end
      while paused() do os.pullEvent("redstone") end
    end
    local buffer = decoder(data:sub(pos, pos + 4095))
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
end
