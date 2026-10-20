local _, ns = ...
if type(ns) ~= "table" then
  return
end

local SEP = "\031"
local CATEGORIES = {
  Craft = true,
  Enchant = true,
  Gather = true,
  Group = true,
  Portal = true,
  Other = true,
}

function ns.Clean(text, maxLen)
  text = tostring(text or "")
  text = text:gsub("[%z\1-\31|]", " ")
  text = text:gsub("%s+", " ")
  text = ns.Trim(text)
  if maxLen and #text > maxLen then
    text = text:sub(1, maxLen)
  end
  return text
end

local function Split(text)
  local out = {}
  local startAt = 1
  while true do
    local from, to = string.find(text, SEP, startAt, true)
    if not from then
      out[#out + 1] = string.sub(text, startAt)
      break
    end
    out[#out + 1] = string.sub(text, startAt, from - 1)
    startAt = to + 1
  end
  return out
end

function ns.PackListing(listing)
  local fee = math.floor(tonumber(listing.feeCopper) or 0)
  if fee < 0 then
    fee = 0
  end
  if fee > ns.MAX_FEE then
    fee = ns.MAX_FEE
  end
  local note = ns.Clean(listing.note, 90)
  local parts = {
    "L",
    ns.Clean(listing.id, 6),
    listing.kind == "task" and "t" or "o",
    listing.faction == "h" and "h" or "a",
    CATEGORIES[listing.category] and listing.category or "Other",
    tostring(fee),
    ns.Clean(listing.zone, 18),
    ns.Clean(listing.meet, 24),
    ns.Clean(listing.title, 42),
    note,
  }
  local message = table.concat(parts, SEP)
  if #message > ns.MAX_MSG then
    local over = #message - ns.MAX_MSG
    parts[10] = string.sub(parts[10], 1, math.max(0, #parts[10] - over))
    message = table.concat(parts, SEP)
  end
  return message
end

function ns.UnpackListing(message, sender)
  local parts = Split(message)
  if parts[1] ~= "L" then
    return nil
  end
  local id = parts[2] or ""
  if not string.match(id, "^[a-z0-9]+$") or #id > 6 or #id < 4 then
    return nil
  end
  local kind = parts[3] == "t" and "task" or (parts[3] == "o" and "offer" or nil)
  local faction = parts[4] == "h" and "h" or (parts[4] == "a" and "a" or nil)
  if not kind or not faction then
    return nil
  end
  local fee = tonumber(parts[6])
  if not fee then
    return nil
  end
  fee = math.floor(fee)
  if fee < 0 or fee > ns.MAX_FEE then
    return nil
  end
  local category = parts[5] or "Other"
  if not CATEGORIES[category] then
    category = "Other"
  end
  return {
    id = id,
    owner = sender,
    kind = kind,
    faction = faction,
    category = category,
    feeCopper = fee,
    zone = ns.Clean(parts[7], 18),
    meet = ns.Clean(parts[8], 24),
    title = ns.Clean(parts[9], 42),
    note = ns.Clean(parts[10], 90),
    ruleset = ns.Ruleset(),
    updated = time(),
  }
end

function ns.PackReview(review)
  local owner, id = string.match(review.listingKey or "", "^([^:]+):([a-z0-9]+)$")
  if not owner or not id then
    return nil
  end
  local stars = math.floor(tonumber(review.stars) or 0)
  if stars < 1 or stars > 5 then
    return nil
  end
  local side = review.side == "seller" and "s" or (review.side == "buyer" and "b" or nil)
  if not side then
    return nil
  end
  return table.concat({
    "R",
    ns.Clean(owner, ns.NAME_MAX or 48),
    ns.Clean(id, 6),
    side,
    tostring(stars),
    ns.Clean(review.about, ns.NAME_MAX or 48),
    ns.Clean(review.note, 80),
  }, SEP)
end

function ns.PackJob(owner, id, role)
  local code = role == "seller" and "s" or "b"
  return table.concat({
    "T",
    ns.Clean(owner, ns.NAME_MAX or 48),
    ns.Clean(id, 6),
    code,
  }, SEP)
end

function ns.ChannelId()
  local want = ns.ChannelName()
  local function usableNumber(value)
    if ns.IsSecret(value) or type(value) ~= "number" or value <= 0 then
      return nil
    end
    return value
  end
  if type(GetChannelName) == "function" then
    local id = usableNumber(GetChannelName(want))
    if id then
      return id
    end
  end
  if type(GetChannelList) == "function" then
    local ok, list = pcall(function()
      return { GetChannelList() }
    end)
    if ok and type(list) == "table" then
      local index = 1
      while index <= #list do
        local id = usableNumber(list[index])
        local name = ns.Plain(list[index + 1])
        if id and type(name) == "string" and string.lower(name) == string.lower(want) then
          return id
        end
        index = index + 3
      end
    end
  end
  return nil
end

function ns.TradeChannelId()
  local function isTrade(name)
    name = ns.Plain(name)
    if type(name) ~= "string" then
      return false
    end
    name = string.lower(name)
    return name == "trade" or string.find(name, "trade", 1, true) == 1
  end
  if type(GetChannelName) == "function" then
    local guesses = { "Trade", "Trade - City" }
    for index = 1, #guesses do
      local id = GetChannelName(guesses[index])
      if not ns.IsSecret(id) and type(id) == "number" and id > 0 then
        return id
      end
    end
  end
  if type(GetChannelList) == "function" then
    local ok, list = pcall(function()
      return { GetChannelList() }
    end)
    if ok and type(list) == "table" then
      local index = 1
      while index <= #list do
        local id = list[index]
        if not ns.IsSecret(id) and type(id) == "number" and id > 0 and isTrade(list[index + 1]) then
          return id
        end
        index = index + 3
      end
    end
  end
  return nil
end

ns.TRADE_AD = "Post a job. Name the fee. Hireling is the commission board. On CurseForge."

function ns.Advertise()
  if not ns.db then
    return
  end
  local now = time()
  local last = ns.db.lastTradeAd
  if type(last) == "number" and now - last < 120 then
    local wait = 120 - (now - last)
    if ns.SetStatus then
      ns.SetStatus("Wait " .. wait .. "s before advertising again.")
    end
    return
  end
  local id = ns.TradeChannelId()
  if not id then
    if ns.SetStatus then
      ns.SetStatus("Trade is not joined. Stand in a city and try again.")
    end
    return
  end
  local sent = false
  if C_ChatInfo and C_ChatInfo.SendChatMessage then
    sent = pcall(C_ChatInfo.SendChatMessage, ns.TRADE_AD, "CHANNEL", nil, id)
    if not sent then
      sent = pcall(C_ChatInfo.SendChatMessage, ns.TRADE_AD, "CHANNEL", nil, tostring(id))
    end
  end
  if not sent and SendChatMessage then
    sent = pcall(SendChatMessage, ns.TRADE_AD, "CHANNEL", nil, id)
    if not sent then
      sent = pcall(SendChatMessage, ns.TRADE_AD, "CHANNEL", nil, tostring(id))
    end
  end
  if sent then
    ns.db.lastTradeAd = now
    if ns.SetStatus then
      ns.SetStatus("Said it in trade.")
    end
    ns.Log("Advertised in trade.")
  elseif ns.SetStatus then
    ns.SetStatus("Trade did not take the message.")
  end
end

function ns.Join()
  local name = ns.ChannelName()
  if ns.joinedName and ns.joinedName ~= name and LeaveChannelByName then
    pcall(LeaveChannelByName, ns.joinedName)
  end
  local joined = false
  local function try(fn)
    if joined or not fn then
      return
    end
    local ok = pcall(fn)
    if ok then
      joined = true
    end
  end
  try(function()
    if not C_ChatInfo or not C_ChatInfo.JoinPermanentChannel then
      error("skip")
    end
    C_ChatInfo.JoinPermanentChannel(name)
  end)
  try(function()
    if not JoinPermanentChannel then
      error("skip")
    end
    JoinPermanentChannel(name)
  end)
  try(function()
    if not JoinChannelByName then
      error("skip")
    end
    JoinChannelByName(name)
  end)
  ns.joinedName = name
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok, result = pcall(C_ChatInfo.RegisterAddonMessagePrefix, ns.PREFIX)
    ns.prefixRegistered = ok
    ns.prefixResult = result
    if not ok then
      ns.Log("Prefix registration failed: " .. tostring(result))
    end
  else
    ns.prefixRegistered = false
  end
  if not joined then
    ns.Log("No channel join API answered for " .. name)
  end
  if ns.UpdateStatus then
    ns.UpdateStatus()
  end
  if joined and ns.SchedulePark then
    ns.SchedulePark()
  end
end

ns.CHANNEL_SLOT = 6

function ns.HasDefaultChannel()
  if type(GetChannelList) ~= "function" then
    return false
  end
  local ok, list = pcall(function()
    return { GetChannelList() }
  end)
  if not ok or type(list) ~= "table" then
    return false
  end
  local index = 1
  while index <= #list do
    local name = ns.Plain(list[index + 1])
    if type(name) == "string" then
      name = string.lower(name)
      if string.find(name, "general", 1, true) == 1 or string.find(name, "trade", 1, true) == 1 then
        return true
      end
    end
    index = index + 3
  end
  return false
end

function ns.ParkChannel()
  local swap = C_ChatInfo and C_ChatInfo.SwapChatChannelsByChannelIndex
  if type(swap) ~= "function" then
    return
  end
  local index = ns.ChannelId()
  if not index or index >= ns.CHANNEL_SLOT then
    return
  end
  local guard = 0
  while index < ns.CHANNEL_SLOT and guard < 8 do
    guard = guard + 1
    local ok = pcall(swap, index, index + 1)
    if not ok then
      break
    end
    local nextIndex = ns.ChannelId()
    if not nextIndex or nextIndex <= index then
      break
    end
    index = nextIndex
  end
  if ns.UpdateStatus then
    ns.UpdateStatus()
  end
end

function ns.SchedulePark()
  if ns.parkTimer then
    return
  end
  ns.parkTimer = true
  local function run()
    ns.parkTimer = false
    ns.ParkChannel()
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0.4, run)
  else
    run()
  end
end

function ns.JoinAfterDefaults()
  if ns.ChannelId and ns.ChannelId() then
    ns.SchedulePark()
    return
  end
  if ns.waitingForDefaults then
    return
  end
  ns.waitingForDefaults = true
  ns.defaultWaits = 0
  local function attempt()
    ns.defaultWaits = (ns.defaultWaits or 0) + 1
    if ns.HasDefaultChannel() or ns.defaultWaits >= 6 then
      ns.waitingForDefaults = false
      ns.Join()
      return
    end
    if C_Timer and C_Timer.After then
      C_Timer.After(1.5, attempt)
    else
      ns.waitingForDefaults = false
      ns.Join()
    end
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(1.5, attempt)
  else
    ns.waitingForDefaults = false
    ns.Join()
  end
end

local queue = {}
local pumping = false

local function ResultThrottled(result)
  result = ns.Plain(result)
  if Enum and Enum.SendAddonMessageResult and result == Enum.SendAddonMessageResult.AddonMessageThrottle then
    return true
  end
  return tostring(result or "") == "AddonMessageThrottle"
end

local function Pump()
  if pumping then
    return
  end
  pumping = true
  local function step()
    if #queue == 0 then
      pumping = false
      return
    end
    local function again(delay, putBack)
      if putBack then
        table.insert(queue, 1, putBack)
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(delay, step)
      else
        pumping = false
      end
    end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
      pumping = false
      ns.Log("SendAddonMessage is missing. The queue was kept.")
      return
    end
    local channelId = ns.ChannelId()
    if not channelId then
      ns.pumpWaits = (ns.pumpWaits or 0) + 1
      if ns.pumpWaits > 8 then
        pumping = false
        ns.Log("Not on the channel yet. Saved posts go out on the next sync.")
        if ns.SetStatus then
          ns.SetStatus("Not on " .. ns.ChannelName() .. " yet. Use /hireling sync.")
        end
        return
      end
      again(1, nil)
      return
    end
    ns.pumpWaits = 0
    local message = table.remove(queue, 1)
    local ok, first, second = pcall(C_ChatInfo.SendAddonMessage, ns.PREFIX, message, "CHANNEL", tostring(channelId))
    if not ok then
      ok, first, second = pcall(C_ChatInfo.SendAddonMessage, ns.PREFIX, message, "CHANNEL", channelId)
    end
    if not ok then
      ns.Log("Send failed: " .. tostring(first))
      again(2, message)
      return
    end
    local result = ns.Plain(second)
    if result == nil then
      result = ns.Plain(first)
    end
    if ResultThrottled(result) then
      again(1, message)
      return
    end
    if type(result) == "number" and result ~= 0 and not ns.toldSendFail then
      ns.toldSendFail = true
      ns.Log("The channel refused a message, code " .. tostring(result) .. ".")
    end
    again(0.25, nil)
  end
  step()
end

function ns.SendTo(name, message)
  if type(name) ~= "string" or name == "" or type(message) ~= "string" or message == "" or #message > ns.MAX_MSG then
    return false
  end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    local ok, first, second = pcall(C_ChatInfo.SendAddonMessage, ns.PREFIX, message, "WHISPER", name)
    if ok then
      local result = second
      if result == nil then
        result = first
      end
      if not ResultThrottled(result) then
        return true
      end
    end
  end
  return ns.Send(message)
end

function ns.Send(message)
  ns.pumpWaits = 0
  if type(message) ~= "string" or message == "" then
    return false
  end
  if #message > ns.MAX_MSG then
    ns.Log("Blocked a " .. #message .. "-byte message.")
    return false
  end
  if #queue >= 60 then
    table.remove(queue, 1)
  end
  queue[#queue + 1] = message
  Pump()
  return true
end

function ns.QueueCount()
  return #queue
end

local function SendOwn(skipHello)
  local mine = ns.MyName()
  if not mine then
    return
  end
  if not skipHello then
    ns.Send("H")
  end
  local listingsSent = 0
  for _, listing in pairs(ns.db.listings) do
    if listing.owner == mine and listing.localOnly ~= true and listing.ruleset == ns.Ruleset() and listingsSent < 12 then
      ns.Send(ns.PackListing(listing))
      listingsSent = listingsSent + 1
    end
  end
  local reviewsSent = 0
  for i = 1, #ns.db.reviews do
    local review = ns.db.reviews[i]
    if review.author == mine and review.localOnly ~= true and reviewsSent < 12 then
      local packed = ns.PackReview(review)
      if packed and #packed <= ns.MAX_MSG then
        ns.Send(packed)
        reviewsSent = reviewsSent + 1
      end
    end
  end
  local versionPacket = "U\031" .. (ns.VERSION or "0")
  if #versionPacket <= ns.MAX_MSG then
    ns.Send(versionPacket)
  end
end

function ns.Announce()
  if not ns.db then
    return
  end
  if not ns.ChannelId() then
    ns.joinTries = (ns.joinTries or 0) + 1
    ns.JoinAfterDefaults()
    if ns.joinTries <= 5 and C_Timer and C_Timer.After then
      C_Timer.After(2, ns.Announce)
      if ns.UpdateStatus then
        ns.UpdateStatus()
      end
      return
    end
    ns.Log("Could not join " .. ns.ChannelName() .. " yet.")
    if ns.SetStatus then
      ns.SetStatus("Not on " .. ns.ChannelName() .. " yet. Use /hireling sync.")
    end
    return
  end
  ns.joinTries = 0
  SendOwn(false)
  ns.Log("Announced on " .. ns.ChannelName() .. ".")
  if ns.UpdateStatus then
    ns.UpdateStatus()
  end
end

function ns.ReplyHello(sender)
  local mine = ns.MyName()
  if not mine or sender == mine or not ns.db then
    return
  end
  ns.replied = ns.replied or {}
  local now = time()
  if ns.replied[sender] and now - ns.replied[sender] < 60 then
    return
  end
  ns.replied[sender] = now
  SendOwn(true)
end

local function ShortName(sender)
  return ns.PlayerName(sender)
end

local function OnAddonMessage(prefix, message, distribution, sender, _, _, _, channelName)
  if ns.IsSecret(prefix) or ns.IsSecret(message) or ns.IsSecret(sender) then
    return
  end
  prefix = ns.Plain(prefix)
  message = ns.Plain(message)
  distribution = ns.Plain(distribution)
  channelName = ns.Plain(channelName)
  if prefix ~= ns.PREFIX or type(message) ~= "string" or not ns.db then
    return
  end
  ns.lastDist = tostring(distribution)
  ns.lastChannelName = tostring(channelName)
  local direct = distribution == "WHISPER"
  if not direct and distribution ~= "CHANNEL" then
    return
  end
  if not direct and type(channelName) == "string" and channelName ~= "" and string.lower(channelName) ~= string.lower(ns.ChannelName()) then
    return
  end
  local who = ShortName(sender)
  if not who then
    return
  end
  if ns.NoteSeen then
    ns.NoteSeen(who)
  end
  local opcode = string.sub(message, 1, 1)
  if opcode == "Q" or opcode == "A" then
    local parts = Split(message)
    local target = parts[2] or ""
    if not direct and target ~= ns.MyName() then
      return
    end
    if who == ns.MyName() then
      return
    end
    if opcode == "Q" and ns.ShowReply then
      if ns.PushInbox then
        ns.PushInbox(who, parts[4] or "this job", parts[3] or "")
      end
      ns.ShowReply(who, parts[4] or "this job", parts[3] or "")
    elseif opcode == "A" and ns.ShowAnswer then
      ns.ShowAnswer(who, parts[3] or "this job", parts[4] or "y", parts[5] or "")
    end
    return
  end
  if not direct and opcode == "H" then
    ns.Log(who .. " asked for a sync.")
    ns.ReplyHello(who)
    return
  end
  if opcode == "L" then
    local listing = ns.UnpackListing(message, who)
    if not listing then
      return
    end
    if listing.owner == ns.MyName() then
      listing.localOnly = false
    end
    local count = 0
    for _ in pairs(ns.db.listings) do
      count = count + 1
    end
    local key = ns.Key(listing.owner, listing.id)
    if count >= 200 and not ns.db.listings[key] then
      return
    end
    ns.UpsertListing(listing)
    return
  end
  if opcode == "R" then
    local parts = Split(message)
    local owner = ns.Clean(parts[2], ns.NAME_MAX or 48)
    local id = parts[3] or ""
    if owner == "" or not string.match(id, "^[a-z0-9]+$") then
      return
    end
    local side = parts[4] == "s" and "seller" or (parts[4] == "b" and "buyer" or nil)
    local stars = tonumber(parts[5])
    if not side or not stars then
      return
    end
    ns.AddReview({
      listingKey = ns.Key(owner, id),
      side = side,
      author = who,
      about = ns.Clean(parts[6], ns.NAME_MAX or 48),
      note = ns.Clean(parts[7], 80),
      stars = math.floor(stars),
      updated = time(),
    })
    return
  end
  if opcode == "T" then
    local parts = Split(message)
    local owner = ns.Clean(parts[2], ns.NAME_MAX or 48)
    local id = parts[3] or ""
    if owner == "" or not string.match(id, "^[a-z0-9]+$") then
      return
    end
    local role = parts[4] == "s" and "seller" or (parts[4] == "b" and "buyer" or nil)
    if not role then
      return
    end
    local key = ns.Key(owner, id)
    local mine = ns.MyName()
    local listing = ns.db.listings[key]
    if who == mine then
      ns.RememberJob(key, role, owner)
      if listing then
        listing.claimed = mine
      end
    elseif owner == mine then
      if listing and listing.claimed and listing.claimed ~= "" and listing.claimed ~= who then
        local refuse = "N\031" .. id .. "\031" .. who
        ns.Send(refuse)
        if ns.SendTo then
          ns.SendTo(who, refuse)
        end
        return
      end
      local myRole = role == "buyer" and "seller" or "buyer"
      ns.RememberJob(key, myRole, who)
      if listing then
        listing.claimed = who
      end
      local title = listing and listing.title or "this job"
      local stamp = key .. "\031" .. who .. "\031" .. role
      ns.claimPinged = ns.claimPinged or {}
      if not ns.claimPinged[stamp] and ns.ShowClaim then
        ns.claimPinged[stamp] = true
        ns.ShowClaim(who, title, role, id, owner)
      end
    elseif listing and (not listing.claimed or listing.claimed == "" or listing.claimed == who) then
      listing.claimed = who
      if ns.Refresh then
        ns.Refresh()
      end
    end
    return
  end
  if opcode == "C" then
    local parts = Split(message)
    local id = parts[2] or ""
    if string.match(id, "^[a-z0-9]+$") and ns.ClaimListing then
      ns.ClaimListing(who, id, ns.Clean(parts[3], ns.NAME_MAX or 48))
    end
    return
  end
  if opcode == "D" then
    local parts = Split(message)
    local owner = ns.Clean(parts[2], ns.NAME_MAX or 48)
    local id = parts[3] or ""
    if owner ~= "" and string.match(id, "^[a-z0-9]+$") and ns.MarkDone then
      local key = ns.Key(owner, id)
      ns.MarkDone(key, true)
      local mine = ns.MyName()
      if who ~= mine and ns.ShowDone then
        ns.donePinged = ns.donePinged or {}
        local stamp = key .. "\031" .. who
        if not ns.donePinged[stamp] then
          ns.donePinged[stamp] = true
          local listing = ns.db.listings[key]
          local job = ns.db.jobs and ns.db.jobs[key]
          local both = job and job.mineDone and job.theirDone
          ns.ShowDone(who, listing and listing.title or "this job", both)
        end
      end
      if ns.Refresh then
        ns.Refresh()
      end
    end
    return
  end
  if opcode == "N" then
    local parts = Split(message)
    local id = parts[2] or ""
    local claimer = ns.Clean(parts[3], ns.NAME_MAX or 48)
    if not string.match(id, "^[a-z0-9]+$") or claimer == "" then
      return
    end
    local owner = who
    local key = ns.Key(owner, id)
    local listing = ns.db.listings[key]
    if listing then
      listing.claimed = nil
    end
    local mine = ns.MyName()
    if mine == claimer or mine == owner then
      ns.db.jobs[key] = nil
    end
    ns.claimPinged = nil
    if mine == claimer and mine ~= owner and ns.ShowDecline then
      ns.ShowDecline(owner, listing and listing.title or "this job")
    end
    if ns.Refresh then
      ns.Refresh()
    end
    return
  end
  if opcode == "U" then
    local parts = Split(message)
    if ns.NoteVersion then
      ns.NoteVersion(parts[2])
    end
    return
  end
  if opcode == "X" then
    local parts = Split(message)
    local id = parts[2] or ""
    if string.match(id, "^[a-z0-9]+$") then
      ns.db.listings[ns.Key(who, id)] = nil
      if ns.Refresh then
        ns.Refresh()
      end
    end
  end
end

if CreateFrame then
  local listener = CreateFrame("Frame")
  listener:RegisterEvent("CHAT_MSG_ADDON")
  listener:SetScript("OnEvent", function(_, _, ...)
    local ok, err = pcall(OnAddonMessage, ...)
    if not ok then
      ns.Log("Message error: " .. tostring(ns.Plain(err) or "sealed"))
    end
  end)
  local function leaked(_, _, ...)
    local first = ns.Plain(select(1, ...))
    if type(first) == "string" and (first == ns.PREFIX or string.find(first, SEP, 1, true)) then
      return true
    end
    return false
  end
  local function leakedAddon(_, _, prefix, message)
    if ns.Plain(prefix) == ns.PREFIX then
      return true
    end
    message = ns.Plain(message)
    return type(message) == "string" and string.find(message, SEP, 1, true) ~= nil
  end
  local add = ChatFrame_AddMessageEventFilter
  if type(add) ~= "function" and type(ChatFrameUtil) == "table" then
    add = ChatFrameUtil.AddMessageEventFilter
  end
  if type(add) == "function" then
    local events = {
      "CHAT_MSG_CHANNEL",
      "CHAT_MSG_SAY",
      "CHAT_MSG_YELL",
      "CHAT_MSG_SYSTEM",
      "CHAT_MSG_WHISPER",
    }
    for index = 1, #events do
      pcall(add, events[index], leaked)
    end
    pcall(add, "CHAT_MSG_ADDON", leakedAddon)
  end
end

function ns.SelfTest()
  local issues = {}
  local function add(text)
    issues[#issues + 1] = text
  end
  local listing = {
    id = "abc123",
    kind = "task",
    faction = "a",
    category = "Enchant",
    feeCopper = ns.MAX_FEE,
    zone = string.rep("Z", 40),
    meet = string.rep("M", 40),
    title = string.rep("T", 80),
    note = string.rep("N", 200) .. "|cffff0000|Hitem:123|h[x]|h|r",
  }
  local packed = ns.PackListing(listing)
  if type(packed) ~= "string" or #packed > ns.MAX_MSG then
    add("listing packet is " .. tostring(packed and #packed or "nil") .. " bytes")
  end
  if packed and string.find(packed, "|", 1, true) then
    add("listing packet still contains a color code")
  end
  local back = packed and ns.UnpackListing(packed, "Tester") or nil
  if not back or back.title ~= string.rep("T", 42) or back.zone ~= string.rep("Z", 18) or back.kind ~= "task" then
    add("listing packet did not round-trip")
  end
  local review = ns.PackReview({
    listingKey = "Tester:abc123",
    side = "buyer",
    stars = 2,
    about = "LongerThanTwelve",
    note = string.rep("R", 120),
  })
  if not review or #review > ns.MAX_MSG then
    add("review packet is too large")
  end
  local bad = ns.UnpackListing("L\031no\031o\031a\031Craft\0311\031Zone\031Meet\031Title\031Note", "Tester")
  if bad then
    add("a bad listing id was accepted")
  end
  if ns.PlayerName("Maela Copperwhistle-Area52") ~= "Maela Copperwhistle" then
    add("a two-word name lost the last name")
  end
  if ns.PlayerName("Maela") == nil then
    add("a one-word name was rejected")
  end
  local claim = ns.PackJob("Maela Copperwhistle", "abc123", "buyer")
  if not claim or not string.find(claim, "Maela Copperwhistle", 1, true) or #claim > ns.MAX_MSG then
    add("a claim packet dropped the last name")
  end
  if type(ns.ShowClaim) ~= "function" then
    add("a claim does not open a box")
  end
  if type(ns.Greet) ~= "function" or type(ns.CreateMinimapButton) ~= "function" then
    add("version line or minimap button is missing")
  end
  return issues
end
