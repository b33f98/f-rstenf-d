local dfpwm = require("cc.audio.dfpwm")
local url = "https://github.com/b33f98/f-rstenf-d/raw/refs/heads/main/S.T.S%20F%C3%BCrstenfeld%20HD.dfpwm"
local volume = 3
local speaker = peripheral.find("speaker")
peripheral.find("modem", rednet.open)

local CHUNK = 1024
local d = CHUNK * 8 / 48000 -- seconds of audio per chunk
local LEAD = 0.5            -- chunks are sent this long before they play
local queue, gen, playEnd = {}, 0, 0
local decoder = dfpwm.make_decoder()

local function now() return os.epoch("utc") / 1000 end

local function paused()
  for _, side in ipairs(rs.getSides()) do
    if rs.getInput(side) then return true end
  end
  return false
end

local function resetAll()
  rednet.broadcast("reset", "music")
  queue, gen, playEnd = {}, gen + 1, 0
  decoder = dfpwm.make_decoder()
  if speaker then speaker.stop() end
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

print("Downloading...")
local h = assert(http.get(url, nil, true))
local data = h.readAll()
h.close()
print("Playing")

local function send()
  resetAll()
  local nextSend = now()
  while true do
    for pos = 1, #data, CHUNK do
      if paused() then
        resetAll()
        while paused() do os.pullEvent("redstone") end
        nextSend = now()
      end
      local wait = nextSend - now()
      if wait > 0 then sleep(wait) elseif wait < -1 then nextSend = now() end
      local msg = { t = nextSend + LEAD, d = data:sub(pos, pos + CHUNK - 1) }
      rednet.broadcast(msg, "music")
      if speaker then
        queue[#queue + 1] = msg
        os.queueEvent("music_chunk")
      end
      nextSend = nextSend + d
    end
  end
end

if speaker then parallel.waitForAny(send, play) else send() end
