local dfpwm = require("cc.audio.dfpwm")
local volume = 3
local speaker = peripheral.find("speaker")
peripheral.find("modem", rednet.open)
local queue = {}
local decoder = dfpwm.make_decoder()

local function receive()
  while true do
    local _, msg = rednet.receive("music")
    if msg == "reset" then
      queue = {}
      speaker.stop()
      decoder = dfpwm.make_decoder()
    else
      queue[#queue + 1] = msg
      os.queueEvent("music_chunk")
    end
  end
end

local function play()
  while true do
    local chunk = table.remove(queue, 1)
    if chunk then
      local buffer = decoder(chunk)
      while not speaker.playAudio(buffer, volume) do
        sleep(0.05)
      end
    else
      os.pullEvent("music_chunk")
    end
  end
end

parallel.waitForAny(receive, play)
