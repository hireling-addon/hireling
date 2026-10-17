local ADDON, ns = ...
if type(ns) ~= "table" then
  return
end

ns.ADDON = ADDON
ns.PREFIX = "Hireling"
ns.VERSION = "0.1.0"
ns.WEEK = 7 * 24 * 60 * 60
ns.MAX_FEE = 5000 * 10000

local POINT = {
  CENTER = true,
  TOPLEFT = true,
  TOPRIGHT = true,
  BOTTOMLEFT = true,
  BOTTOMRIGHT = true,
  TOP = true,
  BOTTOM = true,
  LEFT = true,
  RIGHT = true,
}

function ns.Print(text)
  local line = "|cffffd200Hireling:|r " .. tostring(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(line)
  end
end

function ns.Trim(text)
  return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function ns.Safe(text)
  text = tostring(text or "")
  text = text:gsub("|", "/")
  text = text:gsub("[\r\n%z]", " ")
  return text
end

function ns.MyName()
  local name = UnitName and UnitName("player") or nil
  if type(name) ~= "string" or name == "" or name == "Unknown" then
    return nil
  end
  return name
end

function ns.FactionCode()
  local fac = UnitFactionGroup and UnitFactionGroup("player") or nil
  if fac == "Horde" then
    return "h"
  end
  return "a"
end

function ns.FactionName(code)
  if code == "h" then
    return "Horde"
  end
  return "Alliance"
end

function ns.Ruleset()
  local override = ns.db and ns.db.rulesetOverride or nil
  if override == "PvP" or override == "Roleplaying" or override == "Normal" then
    return override
  end
  return "Normal"
end

function ns.ChannelName()
  local ruleset = ns.Ruleset()
  if ruleset == "PvP" then
    return "HirelingP"
  end
  if ruleset == "Roleplaying" then
    return "HirelingR"
  end
  return "HirelingN"
end

function ns.NewId()
  local alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
  local chars = {}
  for index = 1, 6 do
    local pick = math.random(1, #alphabet)
    chars[index] = string.sub(alphabet, pick, pick)
  end
  return table.concat(chars)
end

function ns.Key(owner, id)
  return tostring(owner or "") .. ":" .. tostring(id or "")
end

function ns.FormatCoin(copper)
  copper = math.floor(tonumber(copper) or 0)
  if copper < 0 then
    copper = 0
  end
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper - gold * 10000) / 100)
  local rest = copper - gold * 10000 - silver * 100
  if gold > 0 and silver > 0 then
    return gold .. "g " .. silver .. "s"
  end
  if gold > 0 then
    return gold .. "g"
  end
  if silver > 0 then
    return silver .. "s"
  end
  return rest .. "c"
end

function ns.InitDB()
  if type(HirelingDB) ~= "table" then
    HirelingDB = {}
  end
  ns.db = HirelingDB
  if type(ns.db.listings) ~= "table" then
    ns.db.listings = {}
  end
  if type(ns.db.reviews) ~= "table" then
    ns.db.reviews = {}
  end
  if type(ns.db.jobs) ~= "table" then
    ns.db.jobs = {}
  end
  if type(ns.db.log) ~= "table" then
    ns.db.log = {}
  end
  if type(ns.db.seen) ~= "table" then
    ns.db.seen = {}
  end
  if type(ns.db.inbox) ~= "table" then
    ns.db.inbox = {}
  end
  if type(ns.db.scale) ~= "number" then
    ns.db.scale = 1
  end
  if ns.db.theme ~= "acid" and ns.db.theme ~= "ice" and ns.db.theme ~= "flare" then
    ns.db.theme = "acid"
  end
  if ns.db.testMode ~= true then
    ns.db.testMode = false
  end
  if ns.db.sound ~= false then
    ns.db.sound = true
  end
  if ns.db.openOnLogin ~= true then
    ns.db.openOnLogin = false
  end
  ns.Repair()
end

function ns.Repair()
  local now = time()
  for key, listing in pairs(ns.db.listings) do
    local bad = type(listing) ~= "table"
      or type(listing.id) ~= "string"
      or type(listing.owner) ~= "string"
      or (listing.kind ~= "offer" and listing.kind ~= "task")
    if bad then
      ns.db.listings[key] = nil
    else
      listing.feeCopper = math.floor(tonumber(listing.feeCopper) or 0)
      if listing.feeCopper < 0 then
        listing.feeCopper = 0
      end
      if listing.feeCopper > ns.MAX_FEE then
        listing.feeCopper = ns.MAX_FEE
      end
      if type(listing.updated) ~= "number" then
        listing.updated = now
      end
      if listing.ruleset ~= "PvP" and listing.ruleset ~= "Roleplaying" and listing.ruleset ~= "Normal" then
        listing.ruleset = "Normal"
      end
    end
  end
  for i = #ns.db.reviews, 1, -1 do
    local review = ns.db.reviews[i]
    local bad = type(review) ~= "table"
      or type(review.listingKey) ~= "string"
      or (review.side ~= "buyer" and review.side ~= "seller")
      or type(review.stars) ~= "number"
    if bad or review.stars < 1 or review.stars > 5 then
      table.remove(ns.db.reviews, i)
    end
  end
end

function ns.Prune()
  local now = time()
  for key, listing in pairs(ns.db.listings) do
    if listing.localOnly ~= true and listing.standing ~= true and type(listing.updated) == "number" and now - listing.updated > ns.WEEK then
      ns.db.listings[key] = nil
    end
  end
  for i = #ns.db.reviews, 1, -1 do
    local review = ns.db.reviews[i]
    if type(review.updated) == "number" and now - review.updated > ns.WEEK then
      table.remove(ns.db.reviews, i)
    end
  end
  while #ns.db.log > 30 do
    table.remove(ns.db.log, 1)
  end
end

function ns.Log(line)
  if not ns.db then
    return
  end
  ns.db.log[#ns.db.log + 1] = date("%H:%M") .. "  " .. ns.Safe(line)
  while #ns.db.log > 30 do
    table.remove(ns.db.log, 1)
  end
  if ns.RefreshChannel and ns.page == "channel" then
    ns.RefreshChannel()
  end
end

function ns.PosterStats(owner)
  local sum, count, orders = 0, 0, 0
  local seen = {}
  if not ns.db or type(owner) ~= "string" or owner == "" then
    return nil, 0
  end
  for i = 1, #ns.db.reviews do
    local review = ns.db.reviews[i]
    if review.about == owner then
      sum = sum + (tonumber(review.stars) or 0)
      count = count + 1
      local key = review.listingKey or ""
      if key ~= "" and not seen[key] then
        seen[key] = true
        orders = orders + 1
      end
    end
  end
  if count == 0 then
    return nil, 0
  end
  if orders < 1 then
    orders = count
  end
  return sum / count, orders
end

function ns.Averages(key)
  local workSum, workN, buyerSum, buyerN = 0, 0, 0, 0
  for i = 1, #ns.db.reviews do
    local review = ns.db.reviews[i]
    if review.listingKey == key then
      if review.side == "buyer" then
        workSum = workSum + review.stars
        workN = workN + 1
      elseif review.side == "seller" then
        buyerSum = buyerSum + review.stars
        buyerN = buyerN + 1
      end
    end
  end
  local work = nil
  local buyer = nil
  if workN > 0 then
    work = workSum / workN
  end
  if buyerN > 0 then
    buyer = buyerSum / buyerN
  end
  return work, workN, buyer, buyerN
end

function ns.HasReview(key, side, author)
  for i = 1, #ns.db.reviews do
    local review = ns.db.reviews[i]
    if review.listingKey == key and review.side == side and review.author == author then
      return true
    end
  end
  return false
end

function ns.UpsertListing(listing)
  if type(listing) ~= "table" or not ns.db then
    return
  end
  ns.db.listings[ns.Key(listing.owner, listing.id)] = listing
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.AddReview(review)
  if not ns.db or type(review) ~= "table" then
    return
  end
  review.stars = math.floor(tonumber(review.stars) or 0)
  if review.stars < 1 or review.stars > 5 then
    return
  end
  for i = 1, #ns.db.reviews do
    local old = ns.db.reviews[i]
    if old.listingKey == review.listingKey and old.side == review.side and old.author == review.author then
      ns.db.reviews[i] = review
      if ns.Refresh then
        ns.Refresh()
      end
      return
    end
  end
  if #ns.db.reviews >= 400 then
    table.remove(ns.db.reviews, 1)
  end
  ns.db.reviews[#ns.db.reviews + 1] = review
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.NoteSeen(name)
  if not ns.db or type(name) ~= "string" or name == "" then
    return
  end
  ns.db.seen[name] = time()
end

function ns.IsHere(name)
  local seen = ns.db and ns.db.seen and ns.db.seen[name]
  return type(seen) == "number" and time() - seen < 300
end

function ns.PushInbox(who, title, id)
  if not ns.db then
    return
  end
  ns.db.inbox[#ns.db.inbox + 1] = {
    who = who,
    title = title or "this job",
    id = id or "",
    at = time(),
  }
  while #ns.db.inbox > 20 do
    table.remove(ns.db.inbox, 1)
  end
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.DropInbox(who, title)
  if not ns.db or type(ns.db.inbox) ~= "table" then
    return
  end
  for index = #ns.db.inbox, 1, -1 do
    local item = ns.db.inbox[index]
    if item.who == who and item.title == title then
      table.remove(ns.db.inbox, index)
      break
    end
  end
end

function ns.ClaimListing(owner, id, by)
  if not ns.db or not owner or not id or id == "" then
    return
  end
  local listing = ns.db.listings[ns.Key(owner, id)]
  if listing then
    listing.claimed = by or ""
    if ns.Refresh then
      ns.Refresh()
    end
  end
end

function ns.MarkDone(key, fromOther)
  local job = ns.db and ns.db.jobs[key]
  if not job then
    return
  end
  if fromOther then
    job.theirDone = true
  else
    job.mineDone = true
  end
  if job.mineDone and job.theirDone and not job.counted then
    job.counted = true
    local listing = ns.db.listings[key]
    if listing then
      listing.ordersCompleted = math.floor(tonumber(listing.ordersCompleted) or 0) + 1
    end
  end
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.RememberJob(key, role, other)
  ns.db.jobs[key] = {
    role = role,
    with = other,
    at = time(),
  }
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.ApplyPosition()
  if not ns.frame then
    return
  end
  ns.frame:ClearAllPoints()
  local window = ns.db and ns.db.window or nil
  if type(window) == "table" and POINT[window.point] and type(window.x) == "number" and type(window.y) == "number" then
    ns.frame:SetPoint(window.point, UIParent, window.point, window.x, window.y)
  else
    ns.frame:SetPoint("CENTER")
  end
end

function ns.SavePosition()
  if not ns.frame or not ns.db then
    return
  end
  local point, _, _, x, y = ns.frame:GetPoint(1)
  if not POINT[point] or type(x) ~= "number" or type(y) ~= "number" then
    return
  end
  ns.db.window = { point = point, x = x, y = y }
end

function ns.ApplyScale()
  if not ns.db then
    return
  end
  local scale = tonumber(ns.db.scale) or 1
  if scale < 0.7 then
    scale = 0.7
  end
  if scale > 1.4 then
    scale = 1.4
  end
  ns.db.scale = scale
  if ns.frame then
    ns.frame:SetScale(scale)
  end
end

function ns.ResetPosition()
  if ns.db then
    ns.db.window = nil
  end
  ns.ApplyPosition()
  ns.Print("Window position reset.")
end

local function AddSampleReview(key, side, author, about, stars, note)
  ns.AddReview({
    listingKey = key,
    side = side,
    author = author,
    about = about,
    stars = stars,
    note = note,
    updated = time(),
    localOnly = true,
  })
end

function ns.LoadSample(quiet)
  local ruleset = ns.Ruleset()
  local function add(listing)
    listing.ruleset = ruleset
    listing.updated = time()
    listing.localOnly = true
    ns.UpsertListing(listing)
  end
  add({
    id = "helm01",
    owner = "Maela",
    kind = "offer",
    faction = ns.FactionCode(),
    category = "Craft",
    title = "Lionheart Helm",
    note = "I craft it. You bring the materials and the fee.",
    feeCopper = 8 * 10000,
    zone = "Ironforge",
    meet = "The Great Forge",
    ordersCompleted = 28,
  })
  add({
    id = "bracer",
    owner = "BrotherCald",
    kind = "offer",
    faction = ns.FactionCode(),
    category = "Enchant",
    title = "Healing on bracers",
    note = "Say the enchant before you hand them over.",
    feeCopper = 2 * 10000,
    zone = "Stormwind",
    meet = "Trade District",
    ordersCompleted = 16,
  })
  add({
    id = "port01",
    owner = "Hest",
    kind = "task",
    faction = ns.FactionCode(),
    category = "Portal",
    title = "Portal four of us to Ironforge",
    note = "Fee in trade before the first portal.",
    feeCopper = 1 * 10000,
    zone = "Stormwind",
    meet = "Trade District",
    ordersCompleted = 4,
  })
  add({
    id = "stock1",
    owner = "Bryn",
    kind = "task",
    faction = ns.FactionCode(),
    category = "Group",
    title = "Tank Stockades, one clear",
    note = "Healer and two damage are already here.",
    feeCopper = 4 * 10000,
    zone = "Westfall",
    meet = "Stormwind gates",
    ordersCompleted = 6,
  })
  AddSampleReview("Maela:helm01", "buyer", "Senn", "Maela", 5, "Helm was right. Paid, then mailed.")
  AddSampleReview("Maela:helm01", "seller", "Maela", "Senn", 5, "Materials were complete.")
  AddSampleReview("BrotherCald:bracer", "buyer", "Jori", "BrotherCald", 2, "Wrong enchant the first time.")
  AddSampleReview("BrotherCald:bracer", "seller", "BrotherCald", "Jori", 2, "Would not name the enchant.")
  AddSampleReview("Hest:port01", "buyer", "Hest", "Ysabel", 5, "Portals were instant.")
  AddSampleReview("Hest:port01", "seller", "Ysabel", "Hest", 5, "Paid before the first portal.")
  AddSampleReview("Bryn:stock1", "buyer", "Bryn", "Pellin", 4, "One wipe, then the clear.")
  AddSampleReview("Bryn:stock1", "seller", "Pellin", "Bryn", 2, "The group was short a healer.")
  ns.NoteSeen("Maela")
  ns.NoteSeen("Hest")
  ns.db.testMode = true
  if quiet then
    if ns.Refresh then
      ns.Refresh()
    end
    return
  end
  ns.Print("Test mode is on. Sample cards stay on this computer.")
  if ns.frame and not ns.frame:IsShown() then
    ns.frame:Show()
  end
  if ns.ShowPage then
    ns.ShowPage("board")
  end
end

function ns.ClearSample()
  ns.db.testMode = false
  for key, listing in pairs(ns.db.listings) do
    if listing.localOnly then
      ns.db.listings[key] = nil
    end
  end
  for i = #ns.db.reviews, 1, -1 do
    if ns.db.reviews[i].localOnly then
      table.remove(ns.db.reviews, i)
    end
  end
  if ns.Refresh then
    ns.Refresh()
  end
  ns.Print("Test mode is off. Sample cards removed.")
end

function ns.SetTestMode(on)
  if on then
    ns.LoadSample(false)
  else
    ns.ClearSample()
  end
  if ns.UpdateStatus then
    ns.UpdateStatus()
  end
end

function ns.Toggle()
  if not ns.frame then
    ns.Print("Hireling is still loading.")
    return
  end
  if ns.frame:IsShown() then
    ns.frame:Hide()
  else
    ns.frame:Show()
  end
end

function Hireling_CompartmentClick()
  ns.Toggle()
end

function Hireling_CompartmentEnter(owner)
  if not GameTooltip or not owner then
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText("Hireling", 1, 0.82, 0.45)
  GameTooltip:AddLine("Open the commission board", 0.93, 0.88, 0.78)
  GameTooltip:Show()
end

function Hireling_CompartmentLeave()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

function ns.Slash(raw)
  local msg = ns.Trim(raw or ""):lower()
  local cmd, rest = msg:match("^(%S*)%s*(.*)$")
  if cmd == "" or cmd == "show" or cmd == "toggle" then
    ns.Toggle()
  elseif cmd == "sync" then
    if ns.Announce then
      ns.Announce()
    end
  elseif cmd == "check" then
    if ns.RunCheck then
      ns.RunCheck()
    end
  elseif cmd == "reset" then
    ns.ResetPosition()
  elseif cmd == "sample" or cmd == "test" then
    ns.SetTestMode(not ns.db.testMode)
  elseif cmd == "scale" then
    local value = tonumber(rest)
    if not value then
      ns.Print("Usage: /hireling scale 0.7-1.4")
      return
    end
    ns.db.scale = value
    ns.ApplyScale()
    ns.Print("Scale set to " .. ns.db.scale .. ".")
  elseif cmd == "ruleset" then
    local name = ns.Trim(rest or "")
    local picked = nil
    local lower = name:lower()
    if lower == "normal" or lower == "n" then
      picked = "Normal"
    elseif lower == "pvp" or lower == "p" then
      picked = "PvP"
    elseif lower == "roleplaying" or lower == "rp" or lower == "r" then
      picked = "Roleplaying"
    end
    if not picked then
      ns.Print("Usage: /hireling ruleset Normal, PvP, or Roleplaying")
      return
    end
    ns.db.rulesetOverride = picked
    ns.Print("Ruleset set to " .. picked .. ". Syncing.")
    if ns.Join then
      ns.Join()
    end
    if ns.Announce then
      if C_Timer and C_Timer.After then
        C_Timer.After(2, ns.Announce)
      else
        ns.Announce()
      end
    end
    if ns.Refresh then
      ns.Refresh()
    end
  else
    ns.Print("Commands: show, sync, check, test, reset, scale 1, ruleset Normal")
  end
end

SLASH_HIRELING1 = "/hireling"
SLASH_HIRELING2 = "/hl"
SlashCmdList.HIRELING = function(msg)
  ns.Slash(msg)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "PLAYER_REGEN_DISABLED" then
    if ns.StashPopupsForCombat then
      ns.StashPopupsForCombat()
    end
    return
  end
  if event == "PLAYER_REGEN_ENABLED" then
    if ns.ReleasePopups then
      ns.ReleasePopups()
    end
    return
  end
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then
      return
    end
    ns.InitDB()
    ns.Prune()
    if ns.BuildUI then
      local ok, err = pcall(ns.BuildUI)
      if not ok then
        ns.Print("The window failed to build: " .. tostring(err))
        ns.Log("UI build error: " .. tostring(err))
      end
    end
    if ns.db.testMode and ns.LoadSample then
      ns.LoadSample(true)
    end
    return
  end
  if event == "PLAYER_ENTERING_WORLD" then
    if ns.Join and (not ns.ChannelId or not ns.ChannelId()) then
      ns.Join()
    end
    local first = not ns.seenWorld
    ns.seenWorld = true
    local isLogin = arg1 == true
    local isReload = arg2 == true
    if first or isLogin or isReload then
      if ns.db and ns.db.openOnLogin and ns.frame and not ns.frame:IsShown() then
        ns.frame:Show()
      end
      local function announce()
        if ns.Announce then
          ns.Announce()
        end
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(3, announce)
      else
        announce()
      end
    elseif ns.UpdateStatus then
      ns.UpdateStatus()
    end
  end
end)
