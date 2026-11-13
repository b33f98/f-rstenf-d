local dfpwm = require("cc.audio.dfpwm")
local volume = 3
local speaker = peripheral.find("speaker")
peripheral.find("modem", rednet.open)

local d = 1024 * 8 / 48000
local queue, gen, playEnd = {}, 0, 0
local decoder = dfpwm.make_decoder()

local function now() return os.epoch("utc") / 1000 end

local function receive()
  while true do
    local _, msg = rednet.receive("music")
    if msg == "reset" then
      queue, gen, playEnd = {}, gen + 1, 0
      decoder = dfpwm.make_decoder()
      speaker.stop()
    elseif type(msg) == "table" then
      queue[#queue + 1] = msg
      os.queueEvent("music_chunk")
    end
  end
end

local function play()
  while true do
    local msg = table.remove(queue, 1)
    if not msg then
      os.pullEvent("music_chunk")
    else
      local g = gen
      local late = math.max(now(), playEnd) - msg.t
      if late < d then
        if late < -0.05 then sleep(msg.t - now()) end
        local buffer = decoder(msg.d)
        if late > 0.08 then
          local trimmed = {}
          for i = math.floor(late * 48000) + 1, #buffer do
            trimmed[#trimmed + 1] = buffer[i]
          end
          buffer = trimmed
        end
        while g == gen and not speaker.playAudio(buffer, volume) do sleep(0.05) end
        if g == gen then playEnd = math.max(now(), playEnd) + #buffer / 48000 end
      end
    end
  end
end

parallel.waitForAny(receive, play)
