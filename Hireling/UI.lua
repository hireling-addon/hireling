local _, ns = ...
if type(ns) ~= "table" then
  return
end

local GOLD = { 0.894, 1.000, 0.290 }
local INK = { 0.035, 0.035, 0.043 }
local PAPER = { 0.957, 0.957, 0.965 }
local MUTED = { 0.557, 0.557, 0.588 }
local RUST = { 1.000, 0.302, 0.180 }
local PANEL = { 0.063, 0.063, 0.071 }
local PANEL_HOT = { 0.110, 0.110, 0.122 }
local LINE = { 0.173, 0.173, 0.192 }
local BG = { 0.027, 0.027, 0.031 }
local DIM = { 0.220, 0.220, 0.250 }
local FONT_PATH = "Interface\\AddOns\\Hireling\\Fonts\\IBMPlexSans-Regular.ttf"
local CATEGORY_LIST = { "Craft", "Enchant", "Gather", "Group", "Portal", "Other" }
local THEME_ORDER = { "acid", "ice", "flare" }
local THEME_LABEL = { acid = "Acid", ice = "Ice", flare = "Flare" }
local PALETTES = {
  acid = {
    gold = { 0.894, 1.000, 0.290 },
    ink = { 0.035, 0.035, 0.043 },
    paper = { 0.957, 0.957, 0.965 },
    muted = { 0.557, 0.557, 0.588 },
    rust = { 1.000, 0.302, 0.180 },
    panel = { 0.063, 0.063, 0.071 },
    hot = { 0.110, 0.110, 0.122 },
    line = { 0.173, 0.173, 0.192 },
    bg = { 0.027, 0.027, 0.031 },
    dim = { 0.220, 0.220, 0.250 },
  },
  ice = {
    gold = { 0.243, 0.878, 1.000 },
    ink = { 0.016, 0.063, 0.094 },
    paper = { 0.933, 0.969, 1.000 },
    muted = { 0.557, 0.671, 0.749 },
    rust = { 1.000, 0.302, 0.416 },
    panel = { 0.063, 0.094, 0.125 },
    hot = { 0.090, 0.141, 0.188 },
    line = { 0.173, 0.259, 0.329 },
    bg = { 0.024, 0.035, 0.051 },
    dim = { 0.180, 0.240, 0.290 },
  },
  flare = {
    gold = { 1.000, 0.416, 0.165 },
    ink = { 0.078, 0.031, 0.016 },
    paper = { 1.000, 0.953, 0.925 },
    muted = { 0.769, 0.635, 0.580 },
    rust = { 1.000, 0.200, 0.333 },
    panel = { 0.110, 0.075, 0.063 },
    hot = { 0.165, 0.110, 0.086 },
    line = { 0.290, 0.196, 0.157 },
    bg = { 0.051, 0.035, 0.027 },
    dim = { 0.290, 0.200, 0.170 },
  },
}

local function CopyRGB(dest, src)
  dest[1] = src[1]
  dest[2] = src[2]
  dest[3] = src[3]
end

function ns.ThemeName()
  local name = ns.db and ns.db.theme or nil
  if not PALETTES[name] then
    return "acid"
  end
  return name
end

function ns.ApplyPalette(name)
  local pal = PALETTES[name] or PALETTES.acid
  CopyRGB(GOLD, pal.gold)
  CopyRGB(INK, pal.ink)
  CopyRGB(PAPER, pal.paper)
  CopyRGB(MUTED, pal.muted)
  CopyRGB(RUST, pal.rust)
  CopyRGB(PANEL, pal.panel)
  CopyRGB(PANEL_HOT, pal.hot)
  CopyRGB(LINE, pal.line)
  CopyRGB(BG, pal.bg)
  CopyRGB(DIM, pal.dim)
end

local function Color(fs, color)
  fs.hirelingColor = color
  fs:SetTextColor(color[1], color[2], color[3], 1)
end

local function Paint(frame, fill, border)
  frame.hirelingFill = fill
  frame.hirelingBorder = border or LINE
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  frame:SetBackdropColor(fill[1], fill[2], fill[3], 1)
  local edge = frame.hirelingBorder
  frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
end

local function ApplyFont(fs, small)
  if not fs or not fs.SetFont then
    return
  end
  local size = small and 11 or 13
  local ok = pcall(fs.SetFont, fs, FONT_PATH, size, "")
  if not ok or not fs:GetFont() then
    pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", size, "")
  end
end

local function Font(parent, small)
  local inherit = small and "GameFontHighlightSmall" or "GameFontHighlight"
  local ok, fs = pcall(parent.CreateFontString, parent, nil, "OVERLAY", inherit)
  if not ok or not fs then
    fs = parent:CreateFontString(nil, "OVERLAY")
  end
  ApplyFont(fs, small)
  Color(fs, PAPER)
  return fs
end

local function ClickButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(width or 80, height or 22)
  Paint(button, PANEL)
  button.enabled = true
  button.active = false
  local label = Font(button, true)
  label:SetPoint("CENTER")
  button.label = label
  button.SetLabel = function(self, value)
    self.label:SetText(value or "")
  end
  button:SetLabel(text or "")
  button.SetActive = function(self, on)
    self.active = on and true or false
    if self.active then
      self.hirelingFill = GOLD
      self:SetBackdropColor(GOLD[1], GOLD[2], GOLD[3], 1)
      Color(self.label, INK)
    else
      self.hirelingFill = PANEL
      self:SetBackdropColor(PANEL[1], PANEL[2], PANEL[3], 1)
      Color(self.label, self.enabled and PAPER or MUTED)
    end
  end
  button.SetEnabledState = function(self, on)
    self.enabled = on and true or false
    self:SetActive(self.active)
  end
  button:SetScript("OnEnter", function(self)
    if self.enabled and not self.active then
      self.hirelingBorder = GOLD
      self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    end
  end)
  button:SetScript("OnLeave", function(self)
    self.hirelingBorder = LINE
    self:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
  end)
  button:SetScript("OnClick", function(self)
    if self.enabled and self.onClick then
      self.onClick(self)
    end
  end)
  button:RegisterForClicks("LeftButtonUp")
  return button
end

local function EditBox(parent, width, height, multi, maxLetters)
  local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
  edit:SetSize(width or 120, height or 24)
  edit:SetAutoFocus(false)
  local fontOk = pcall(edit.SetFont, edit, FONT_PATH, 12, "")
  if not fontOk or not edit:GetFont() then
    edit:SetFontObject("GameFontHighlight")
    if not edit:GetFont() then
      edit:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    end
  end
  edit:SetTextInsets(8, 8, 4, 4)
  edit:SetMaxLetters(maxLetters or 40)
  if multi then
    edit:SetMultiLine(true)
  else
    edit:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
    end)
  end
  edit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  Paint(edit, INK, LINE)
  Color(edit, PAPER)
  edit:SetScript("OnEditFocusGained", function(self)
    self.hirelingBorder = GOLD
    self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
  end)
  edit:SetScript("OnEditFocusLost", function(self)
    self.hirelingBorder = LINE
    self:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
  end)
  ns.edits[#ns.edits + 1] = edit
  return edit
end

local function MakeStars(parent)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(46, 8)
  local icons = {}
  for index = 1, 5 do
    local tex = holder:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetSize(8, 8)
    tex:SetPoint("LEFT", (index - 1) * 9, 0)
    icons[index] = tex
  end
  function holder:SetAverage(avg)
    self.lastAvg = avg
    local rounded = 0
    if type(avg) == "number" then
      rounded = math.floor(avg + 0.5)
    end
    for index = 1, 5 do
      if avg and index <= rounded then
        icons[index]:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
      else
        icons[index]:SetVertexColor(DIM[1], DIM[2], DIM[3], 1)
      end
    end
  end
  holder.hirelingStars = true
  holder:SetAverage(nil)
  return holder
end

local function FieldLabel(parent, text)
  local label = Font(parent, true)
  Color(label, MUTED)
  label:SetText(text)
  return label
end

function ns.ClearFocus()
  if not ns.edits then
    return
  end
  for index = 1, #ns.edits do
    local edit = ns.edits[index]
    if edit.HasFocus and edit:HasFocus() then
      edit:ClearFocus()
    end
  end
end

function ns.SetStatus(text)
  if ns.status then
    ns.status:SetText(ns.Safe(text))
    Color(ns.status, MUTED)
  end
end

function ns.UpdateStatus()
  local where = ns.ChannelName() .. " · " .. ns.FactionName(ns.FactionCode()) .. " · " .. ns.Ruleset()
  local id = ns.ChannelId and ns.ChannelId() or nil
  if id then
    ns.SetStatus(where .. " · channel " .. id .. ". Pay in the trade window.")
  else
    ns.SetStatus(where .. " · not joined yet. Pay in the trade window.")
  end
  if ns.db and ns.db.testMode and ns.status then
    ns.SetStatus("Test mode. Sample cards stay on this computer.")
  end
  if ns.testButton then
    ns.testButton:SetActive(ns.db and ns.db.testMode == true)
  end
  if ns.optionsButton then
    ns.optionsButton:SetActive(ns.page == "options")
  end
end

local function AverageText(avg, count)
  if not avg then
    return "No stars yet", false
  end
  local low = avg <= 2
  return string.format("%.1f", avg) .. " · " .. count, low
end

local function Matches(listing, needle)
  if needle == "" then
    return true
  end
  local kind = listing.kind == "task" and "bid" or "offer"
  local hay = string.lower(table.concat({
    listing.title or "",
    listing.owner or "",
    listing.category or "",
    listing.zone or "",
    listing.note or "",
    listing.meet or "",
    kind,
  }, " "))
  return string.find(hay, needle, 1, true) ~= nil
end

function ns.Filtered(includeJobs)
  local out = {}
  if not ns.db then
    return out
  end
  local needle = string.lower(ns.Trim(ns.searchText or ""))
  local ruleset = ns.Ruleset()
  local faction = ns.FactionCode()
  local mine = ns.MyName()
  for _, listing in pairs(ns.db.listings) do
    if type(listing) == "table" and listing.ruleset == ruleset and listing.faction == faction then
      local key = ns.Key(listing.owner, listing.id)
      local job = ns.db.jobs[key]
      local mineRow = listing.owner == mine or job ~= nil
      local kindOk = ns.filterKind == "all" or listing.kind == ns.filterKind
      local categoryOk = not ns.filterCategory or ns.filterCategory == "all" or listing.category == ns.filterCategory
      local claimed = listing.claimed and listing.claimed ~= ""
      local hidden = claimed and listing.owner ~= mine and listing.claimed ~= mine
      if Matches(listing, needle) and kindOk and categoryOk and (includeJobs or not hidden) then
        if not includeJobs or mineRow then
          out[#out + 1] = listing
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if ns.sortMode == "payout" then
      local leftFee = a.feeCopper or 0
      local rightFee = b.feeCopper or 0
      if leftFee ~= rightFee then
        return leftFee > rightFee
      end
    end
    local left = a.updated or 0
    local right = b.updated or 0
    if left ~= right then
      return left > right
    end
    return tostring(a.title or "") < tostring(b.title or "")
  end)
  return out
end

local function FillRow(row, listing)
  local key = ns.Key(listing.owner, listing.id)
  row.key = key
  local place = ns.Safe(listing.meet)
  if place == "" then
    place = ns.Safe(listing.zone)
  end
  if place == "" then
    place = "Unknown"
  end
  row.kind:SetText(place)
  row.fee:SetText(ns.FormatCoin(listing.feeCopper))
  row.title:SetText(ns.Safe(listing.title))
  local poster = ns.Safe(listing.owner)
  if ns.IsHere and ns.IsHere(listing.owner) then
    poster = poster .. " · Here"
  end
  if listing.standing then
    poster = poster .. " · Standing"
  end
  if listing.claimed and listing.claimed ~= "" then
    poster = poster .. " · Claimed"
  end
  row.meta:SetText(poster)
  local avg, orders = ns.PosterStats(listing.owner)
  if type(listing.ordersCompleted) == "number" and listing.ordersCompleted > orders then
    orders = math.floor(listing.ordersCompleted)
  end
  if avg then
    row.workText:SetText(string.format("%.1f", avg))
    Color(row.workText, avg <= 2 and RUST or PAPER)
  else
    row.workText:SetText("No rating")
    Color(row.workText, MUTED)
  end
  row.workStars:SetAverage(avg)
  row.workLabel:SetText("")
  row.buyerStars:Hide()
  row.buyerLabel:ClearAllPoints()
  row.buyerLabel:SetPoint("LEFT", row.workText, "RIGHT", 10, 0)
  row.buyerLabel:SetText(orders .. (orders == 1 and " order" or " orders"))
  row.buyerText:SetText("")
  if listing.owner == ns.MyName() then
    row.whisper:Hide()
  else
    row.whisper:Show()
  end
  local selected = ns.selectedKey == key
  if selected then
    row.hirelingFill = PANEL_HOT
    row.hirelingBorder = GOLD
  else
    row.hirelingFill = PANEL
    row.hirelingBorder = LINE
  end
  row:SetBackdropColor(row.hirelingFill[1], row.hirelingFill[2], row.hirelingFill[3], 1)
  row:SetBackdropBorderColor(row.hirelingBorder[1], row.hirelingBorder[2], row.hirelingBorder[3], 1)
end

local function CreateRow(parent, scroll)
  local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
  row:SetHeight(108)
  Paint(row, PANEL)
  if row.SetClipsChildren then
    row:SetClipsChildren(true)
  end
  row:RegisterForClicks("LeftButtonUp")
  row:EnableMouseWheel(true)
  row:SetScript("OnClick", function(self)
    if self.key then
      ns.OpenListing(self.key)
    end
  end)
  row:SetScript("OnMouseWheel", function(_, delta)
    ns.Wheel(scroll, delta)
  end)
  row.kind = Font(row, true)
  Color(row.kind, MUTED)
  row.kind:SetPoint("TOPLEFT", 8, -6)
  row.fee = Font(row, true)
  Color(row.fee, GOLD)
  row.fee:SetPoint("TOPRIGHT", -8, -6)
  row.title = Font(row, false)
  row.title:SetPoint("TOPLEFT", 8, -22)
  row.title:SetPoint("TOPRIGHT", -8, -22)
  row.title:SetJustifyH("LEFT")
  row.title:SetWordWrap(false)
  if row.title.SetMaxLines then
    row.title:SetMaxLines(1)
  end
  row.meta = Font(row, true)
  Color(row.meta, MUTED)
  row.meta:SetPoint("TOPLEFT", 8, -42)
  row.meta:SetPoint("TOPRIGHT", -8, -42)
  row.meta:SetJustifyH("LEFT")
  row.meta:SetWordWrap(false)
  row.workStars = MakeStars(row)
  row.workStars:SetPoint("TOPLEFT", 8, -58)
  row.workLabel = Font(row, true)
  Color(row.workLabel, MUTED)
  row.workLabel:SetText("")
  row.workLabel:SetPoint("LEFT", row.workStars, "RIGHT", 6, 0)
  row.workText = Font(row, true)
  row.workText:SetPoint("LEFT", row.workLabel, "RIGHT", 6, 0)
  row.buyerStars = MakeStars(row)
  row.buyerStars:SetPoint("LEFT", row.workText, "RIGHT", 16, 0)
  row.buyerLabel = Font(row, true)
  Color(row.buyerLabel, MUTED)
  row.buyerLabel:SetText("")
  row.buyerLabel:SetPoint("LEFT", row.buyerStars, "RIGHT", 6, 0)
  row.buyerText = Font(row, true)
  row.buyerText:SetPoint("LEFT", row.buyerLabel, "RIGHT", 6, 0)
  row.whisper = ClickButton(row, "Ask", 72, 18)
  row.whisper:SetPoint("BOTTOMLEFT", 8, 6)
  row.whisper.onClick = function(self)
    local parent = self:GetParent()
    local listing = parent and parent.key and ns.db.listings[parent.key] or nil
    if listing then
      ns.AskListing(listing)
    end
  end
  return row
end

function ns.Wheel(scroll, delta)
  if not scroll or not scroll:GetScrollChild() then
    return
  end
  local child = scroll:GetScrollChild()
  local maxScroll = child:GetHeight() - scroll:GetHeight()
  if maxScroll < 0 then
    maxScroll = 0
  end
  local nextScroll = scroll:GetVerticalScroll() - (delta or 0) * 48
  if nextScroll < 0 then
    nextScroll = 0
  end
  if nextScroll > maxScroll then
    nextScroll = maxScroll
  end
  scroll:SetVerticalScroll(nextScroll)
end

local function LayoutRows(scroll, pool, listings)
  local child = scroll:GetScrollChild()
  local width = scroll:GetWidth()
  if width and width > 40 then
    child:SetWidth(width)
  end
  local y = 0
  local shown = #listings
  if shown > 80 then
    shown = 80
  end
  for index = 1, shown do
    local row = pool[index]
    if not row then
      row = CreateRow(child, scroll)
      pool[index] = row
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
    row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
    FillRow(row, listings[index])
    row:Show()
    y = y + 88
  end
  for index = shown + 1, #pool do
    pool[index]:Hide()
  end
  if y < 1 then
    y = 1
  end
  child:SetHeight(y)
  ns.Wheel(scroll, 0)
end

function ns.RefreshBoard()
  if not ns.board then
    return
  end
  local listings = ns.Filtered(false)
  local offers, bids = 0, 0
  local ruleset = ns.Ruleset()
  local faction = ns.FactionCode()
  local needle = string.lower(ns.Trim(ns.searchText or ""))
  for _, listing in pairs(ns.db.listings) do
    if listing.ruleset == ruleset and listing.faction == faction and Matches(listing, needle) then
      if listing.kind == "task" then
        bids = bids + 1
      else
        offers = offers + 1
      end
    end
  end
  ns.board.all:SetLabel("All " .. (offers + bids))
  ns.board.offers:SetLabel("Offers " .. offers)
  ns.board.bids:SetLabel("Bids " .. bids)
  ns.board.all:SetActive(ns.filterKind == "all")
  ns.board.offers:SetActive(ns.filterKind == "offer")
  ns.board.bids:SetActive(ns.filterKind == "task")
  ns.board.recent:SetActive(ns.sortMode ~= "payout")
  ns.board.payout:SetActive(ns.sortMode == "payout")
  if ns.board.category then
    local label = ns.filterCategory or "all"
    ns.board.category:SetLabel(label == "all" and "All crafts" or label)
    ns.board.category:SetActive(label ~= "all")
  end
  LayoutRows(ns.board.scroll, ns.board.rows, listings)
  if #listings == 0 then
    ns.board.empty:Show()
    if needle ~= "" then
      ns.board.empty.text:SetText("Nothing matches that search.")
    else
      ns.board.empty.text:SetText("No listings on " .. ns.ChannelName() .. " yet.")
    end
  else
    ns.board.empty:Hide()
  end
end

function ns.RefreshYours()
  if not ns.yours then
    return
  end
  local previous = ns.filterKind
  local previousSearch = ns.searchText
  ns.filterKind = "all"
  ns.searchText = ""
  local listings = ns.Filtered(true)
  ns.filterKind = previous
  ns.searchText = previousSearch
  LayoutRows(ns.yours.scroll, ns.yours.rows, listings)
  if ns.yours.inbox then
    local lines = {}
    local inbox = ns.db and ns.db.inbox or {}
    for index = 1, #inbox do
      local item = inbox[index]
      lines[#lines + 1] = (item.who or "Someone") .. " asked about " .. (item.title or "a job")
    end
    if #lines == 0 then
      ns.yours.inbox:SetText("Inbox is empty.")
    else
      ns.yours.inbox:SetText(table.concat(lines, "\n"))
    end
    if ns.yours.openInbox then
      ns.yours.openInbox:SetEnabledState(#inbox > 0)
    end
  end
  if #listings == 0 then
    ns.yours.empty:Show()
  else
    ns.yours.empty:Hide()
  end
end

function ns.OpenListing(key)
  ns.selectedKey = key
  ns.reviewStars = ns.reviewStars or 5
  if ns.detail and ns.detail.noteEdit then
    ns.detail.noteEdit:SetText("")
  end
  ns.ShowPage("detail")
end

local function PaintStarPicker()
  local value = ns.reviewStars or 5
  for index = 1, 5 do
    local button = ns.detail.stars[index]
    if index <= value then
      button.hirelingFill = GOLD
    else
      button.hirelingFill = PANEL
    end
    button:SetBackdropColor(button.hirelingFill[1], button.hirelingFill[2], button.hirelingFill[3], 1)
  end
end

function ns.RefreshDetail()
  if not ns.detail then
    return
  end
  local listing = ns.selectedKey and ns.db.listings[ns.selectedKey] or nil
  if not listing then
    ns.detail.title:SetText("That listing is gone.")
    ns.detail.meta:SetText("")
    ns.detail.note:SetText("")
    ns.detail.action:Hide()
    if ns.detail.whisper then
      ns.detail.whisper:Hide()
    end
    ns.detail.form:Hide()
    ns.detail.body:SetText("")
    return
  end
  local bid = listing.kind == "task"
  local mine = ns.MyName()
  local key = ns.Key(listing.owner, listing.id)
  local job = ns.db.jobs[key]
  ns.detail.title:SetText(ns.Safe(listing.title))
  ns.detail.meta:SetText((bid and "Bid · pays " or "Offer · asks ") .. ns.FormatCoin(listing.feeCopper) .. "\n" .. ns.Safe(listing.owner) .. " · " .. ns.Safe(listing.zone) .. " · " .. ns.Safe(listing.category))
  local note = ns.Safe(listing.note)
  if listing.meet and listing.meet ~= "" then
    note = note .. "\nMeet: " .. ns.Safe(listing.meet)
  end
  ns.detail.note:SetText(note)
  ns.detail.action:Show()
  if listing.owner == mine and not job then
    ns.detail.action:SetLabel("Withdraw this listing")
    ns.detail.action.enabled = true
    ns.detail.action.onClick = function()
      ns.Withdraw(listing)
    end
  elseif job and not (job.mineDone and job.theirDone) then
    ns.detail.action:SetLabel(job.mineDone and "Waiting on them" or "Mark done")
    ns.detail.action.enabled = not job.mineDone
    ns.detail.action.onClick = function()
      if not job.mineDone then
        ns.MarkDone(key, false)
        if listing.localOnly == true then
          ns.MarkDone(key, true)
          ns.ShowDone(mine, listing.title, true)
        else
          local packet = "D\031" .. ns.Clean(listing.owner, ns.NAME_MAX or 48) .. "\031" .. ns.Clean(listing.id, 12)
          ns.Send(packet)
          local other = listing.owner == mine and (listing.claimed or (job and job.with)) or listing.owner
          if other and other ~= mine and ns.SendTo then
            ns.SendTo(other, packet)
          end
        end
        if listing.owner == mine then
          ns.AskRemove(listing)
        end
      end
    end
  elseif job then
    ns.detail.action:SetLabel(job.role == "seller" and "You are doing this" or "You took this")
    ns.detail.action.enabled = false
    ns.detail.action.onClick = nil
  elseif listing.claimed and listing.claimed ~= "" and listing.claimed ~= mine then
    ns.detail.action:SetLabel("Taken by " .. ns.Safe(listing.claimed))
    ns.detail.action.enabled = false
    ns.detail.action.onClick = nil
  elseif bid then
    ns.detail.action:SetLabel("I'll do this")
    ns.detail.action.enabled = true
    ns.detail.action.onClick = function()
      ns.TakeListing(listing, "seller")
    end
  else
    ns.detail.action:SetLabel("Take this offer")
    ns.detail.action.enabled = true
    ns.detail.action.onClick = function()
      ns.TakeListing(listing, "buyer")
    end
  end
  ns.detail.action:SetEnabledState(ns.detail.action.enabled)
  if ns.detail.whisper then
    if listing.owner == mine then
      ns.detail.whisper:Hide()
    else
      ns.detail.whisper:Show()
      ns.detail.whisper:SetEnabledState(true)
    end
  end
  local side = job and job.role or nil
  local already = side and mine and ns.HasReview(key, side, mine)
  local finished = job and job.mineDone and job.theirDone
  if finished and job and mine and not already then
    ns.detail.form:Show()
    ns.detail.formLabel:SetText(side == "seller" and "Your stars for the buyer" or "Your stars for the work")
    PaintStarPicker()
  else
    ns.detail.form:Hide()
  end
  local lines = {}
  local shown = 0
  for index = 1, #ns.db.reviews do
    local review = ns.db.reviews[index]
    if review.listingKey == key then
      shown = shown + 1
      if shown <= 20 then
        local which = review.side == "seller" and "On the buyer" or "On the work"
        lines[#lines + 1] = which .. "  " .. review.stars .. "/5  " .. ns.Safe(review.author) .. " on " .. ns.Safe(review.about)
        if review.note and review.note ~= "" then
          lines[#lines + 1] = ns.Safe(review.note)
        end
        lines[#lines + 1] = " "
      end
    end
  end
  if shown == 0 then
    lines[1] = "No written reviews yet."
  elseif job and already then
    lines[#lines + 1] = "You already left stars on this one."
  elseif not job and listing.owner ~= mine then
    lines[#lines + 1] = "Take it before you leave stars. Gold still moves in the trade window."
  end
  ns.detail.body:SetText(table.concat(lines, "\n"))
  local scroll = ns.detail.scroll
  local child = scroll:GetScrollChild()
  local width = scroll:GetWidth()
  if width and width > 40 then
    child:SetWidth(width)
    ns.detail.body:SetWidth(width - 4)
  end
  local height = ns.detail.body:GetStringHeight()
  if not height or height < #lines * 14 then
    height = math.max(20, #lines * 14)
  end
  child:SetHeight(height + 8)
  if ns.detail.form:IsShown() then
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", ns.detail.note, "BOTTOMLEFT", 0, -40)
    scroll:SetPoint("BOTTOMRIGHT", ns.detail.form, "TOPRIGHT", 0, 6)
  else
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", ns.detail.note, "BOTTOMLEFT", 0, -40)
    scroll:SetPoint("BOTTOMRIGHT", ns.detail.page, "BOTTOMRIGHT", 0, 0)
  end
end

function ns.AskListing(listing)
  if type(listing) ~= "table" then
    return
  end
  local who = ns.PlayerName(listing.owner) or ""
  if who == "" or who == ns.MyName() then
    ns.SetStatus("No one to ask.")
    return
  end
  local title = ns.Clean(listing.title or "", 42)
  if title == "" then
    title = "this job"
  end
  if listing.localOnly == true then
    if ns.PushInbox then
      ns.PushInbox(who, title, listing.id)
    end
    ns.ShowReply(who, title, listing.id)
    if ns.reply and ns.reply:IsShown() then
      ns.reply.localTest = true
      ns.reply.from:SetText(who .. " asked (test)")
    end
    ns.SetStatus("Test ask. Nothing was sent on the channel.")
    return
  end
  local id = ns.Clean(listing.id or "job", 12)
  local packet = "Q\031" .. who .. "\031" .. id .. "\031" .. title
  if ns.SendTo then
    ns.SendTo(who, packet)
  elseif ns.Send then
    ns.Send(packet)
  end
  ns.SetStatus("Asked " .. who .. ". Their addon will pop a box if they are online.")
end

local function ReplyLine(choice, job, other)
  if choice == "no" then
    return "HIRELING: no, I do not want " .. job .. "."
  end
  if choice == "other" then
    other = ns.Clean(other or "", 160)
    if other == "" then
      return nil
    end
    return "HIRELING: " .. other
  end
  return "HIRELING: yes, I still want " .. job .. "."
end

local function PaintReplyChoice(reply)
  local buttons = reply.choices
  for index = 1, 3 do
    local button = buttons[index]
    local on = button.choiceId == reply.choice
    button:SetActive(on)
  end
  local line = ReplyLine(reply.choice, reply.job, reply.edit:GetText())
  if reply.choice == "other" then
    reply.edit:Show()
    reply.preview:SetText(line or "Type a reply, then press enter.")
  else
    reply.edit:Hide()
    reply.preview:SetText(line or "")
  end
end

function ns.CommitReply()
  local reply = ns.reply
  if not reply or not reply:IsShown() then
    return
  end
  local line = ReplyLine(reply.choice, reply.job, reply.edit:GetText())
  if not line then
    ns.SetStatus("Type a reply first.")
    return
  end
  local choice = "y"
  local extra = ""
  if reply.choice == "no" then
    choice = "n"
  elseif reply.choice == "other" then
    choice = "o"
    extra = ns.Clean(reply.edit:GetText(), 80)
  end
  local packet = "A\031" .. reply.who .. "\031" .. reply.job .. "\031" .. choice .. "\031" .. extra
  if reply.localTest then
    local who = reply.who
    local job = reply.job
    local listingId = reply.listingId
    reply.localTest = nil
    reply:Hide()
    if choice == "y" and ns.ClaimListing then
      ns.ClaimListing(who, listingId, ns.MyName() or "You")
    end
    if ns.DropInbox then
      ns.DropInbox(who, job)
    end
    ns.ShowAnswer(who, job, choice, extra)
    ns.SetStatus("Test answer. Nothing was sent on the channel.")
    return
  end
  if choice == "y" and reply.listingId and reply.listingId ~= "" then
    ns.Send("C\031" .. ns.Clean(reply.listingId, 12) .. "\031" .. ns.Clean(reply.who, ns.NAME_MAX or 48))
    if ns.ClaimListing then
      ns.ClaimListing(ns.MyName(), reply.listingId, reply.who)
    end
  end
  if ns.DropInbox then
    ns.DropInbox(reply.who, reply.job)
  end
  if ns.SendTo then
    ns.SendTo(reply.who, packet)
  elseif ns.Send then
    ns.Send(packet)
  end
  ns.SetStatus("Answer sent to " .. reply.who .. ".")
  reply:Hide()
end

function ns.InCombat()
  if type(InCombatLockdown) == "function" then
    local locked = InCombatLockdown()
    if ns.IsSecret(locked) then
      return true
    end
    if locked then
      return true
    end
  end
  if type(UnitAffectingCombat) == "function" then
    local fighting = UnitAffectingCombat("player")
    if ns.IsSecret(fighting) then
      return true
    end
    if fighting then
      return true
    end
  end
  return false
end

ns.DISCORD = "https://discord.gg/xJ8H2uDejT"

function ns.ShowChangelog()
  if not ns.changelog then
    local frame = CreateFrame("Frame", "HirelingChangelog", UIParent, "BackdropTemplate")
    frame:SetSize(420, 280)
    frame:SetPoint("CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(240)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    Paint(frame, BG, LINE)
    local title = Font(frame, true)
    Color(title, GOLD)
    title:SetPoint("TOPLEFT", 10, -12)
    title:SetText("Changelog")
    local close = ClickButton(frame, "Close", 64, 22)
    close:SetPoint("TOPRIGHT", -8, -8)
    close.onClick = function()
      frame:Hide()
    end
    local body = Font(frame, true)
    Color(body, PAPER)
    body:SetPoint("TOPLEFT", 10, -40)
    body:SetPoint("BOTTOMRIGHT", -10, 10)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    frame.body = body
    ns.changelog = frame
  end
  ns.changelog.body:SetText(ns.CHANGELOG or "No changelog yet.")
  ns.changelog:Show()
end

function ns.ShowDiscord()
  local url = ns.DISCORD
  if StaticPopupDialogs and StaticPopup_Show then
    if not StaticPopupDialogs.HIRELING_DISCORD then
      StaticPopupDialogs.HIRELING_DISCORD = {
        text = "Hireling Discord. Copy this link.",
        button1 = "Close",
        hasEditBox = true,
        editBoxWidth = 280,
        OnShow = function(self)
          local box = self.editBox or self.EditBox
          if box then
            box:SetText(ns.DISCORD)
            box:HighlightText()
            if box.SetFocus then
              box:SetFocus()
            end
          end
        end,
        EditBoxOnEscapePressed = function(self)
          self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
    end
    StaticPopup_Show("HIRELING_DISCORD")
  end
  if ns.Print then
    ns.Print("Discord: " .. url)
  end
end

ns.SOUNDS = {
  { id = "tell", label = "Tell", kit = "TELL_MESSAGE", file = "Sound\\Interface\\iTellMessage.ogg" },
  { id = "click", label = "Click", kit = "IG_MAINMENU_OPTION_CHECKBOX_ON", file = "Sound\\Interface\\igMainMenuOptionCheckBoxOn.ogg" },
  { id = "ready", label = "Ready", kit = "READY_CHECK", file = "Sound\\Interface\\ReadyCheck.ogg" },
  { id = "auction", label = "Auction", kit = "AUCTION_WINDOW_OPEN", file = "Sound\\Interface\\AuctionWindowOpen.ogg" },
  { id = "coins", label = "Coins", kit = "LOOT_WINDOW_COIN_SOUND", file = "Sound\\Interface\\LootCoinSmall.ogg" },
  { id = "level", label = "Level", kit = "LEVELUP", file = "Sound\\Interface\\LevelUp.ogg" },
  { id = "warning", label = "Warning", kit = "RAID_WARNING", file = "Sound\\Interface\\RaidWarning.ogg" },
  { id = "ping", label = "Ping", kit = "MAP_PING", file = "Sound\\Interface\\MapPing.ogg" },
  { id = "quest", label = "Quest", kit = "IG_QUEST_LIST_OPEN", file = "Sound\\Interface\\iQuestLogOpenA.ogg" },
}

function ns.SoundById(id)
  for index = 1, #ns.SOUNDS do
    if ns.SOUNDS[index].id == id then
      return ns.SOUNDS[index]
    end
  end
  return ns.SOUNDS[1]
end

function ns.PlayTell()
  if not ns.db or ns.db.sound == false then
    return false
  end
  local sound = ns.SoundById(ns.db.soundId)
  if PlaySound and SOUNDKIT and sound.kit and SOUNDKIT[sound.kit] then
    if pcall(PlaySound, SOUNDKIT[sound.kit], "Master") then
      return true
    end
  end
  if PlaySoundFile and sound.file and pcall(PlaySoundFile, sound.file, "Master") then
    return true
  end
  if PlaySound and pcall(PlaySound, "TellMessage") then
    return true
  end
  return false
end

function ns.PreviewSound(id)
  if not ns.db then
    return
  end
  ns.db.sound = true
  ns.db.soundId = id
  if not ns.PlayTell() then
    ns.SetStatus("That sound is not in this client.")
  end
  if ns.RefreshOptions then
    ns.RefreshOptions()
  end
end

function ns.OpenChoices(anchor, choices, current, onPick)
  if not ns.choices then
    local frame = CreateFrame("Frame", "HirelingChoices", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(220)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    Paint(frame, BG, LINE)
    frame.buttons = {}
    ns.choices = frame
  end
  local frame = ns.choices
  if frame:IsShown() and frame.anchor == anchor then
    frame:Hide()
    return
  end
  frame.anchor = anchor
  local width = 124
  local cols = #choices > 4 and 4 or #choices
  if cols < 1 then
    cols = 1
  end
  local rows = math.ceil(#choices / cols)
  frame:SetSize(cols * (width + 4) + 8, rows * 26 + 8)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
  for index = 1, #frame.buttons do
    frame.buttons[index]:Hide()
  end
  for index = 1, #choices do
    local choice = choices[index]
    local button = frame.buttons[index]
    if not button then
      button = ClickButton(frame, choice.label, width, 22)
      frame.buttons[index] = button
    end
    button:SetLabel(choice.label)
    button:Show()
    button:SetActive(choice.id == current)
    local col = (index - 1) % cols
    local row = math.floor((index - 1) / cols)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 4 + col * (width + 4), -4 - row * 26)
    button.onClick = function()
      onPick(choice.id)
      frame:Hide()
    end
  end
  frame:Show()
end

function ns.AskRemove(listing)
  if not listing or listing.owner ~= ns.MyName() then
    return
  end
  if not ns.removePrompt then
    local prompt = CreateFrame("Frame", "HirelingRemove", UIParent, "BackdropTemplate")
    prompt:SetSize(340, 120)
    prompt:SetPoint("CENTER", 0, 40)
    prompt:SetFrameStrata("DIALOG")
    prompt:SetFrameLevel(230)
    prompt:SetClampedToScreen(true)
    prompt:EnableMouse(true)
    Paint(prompt, BG, LINE)
    local title = Font(prompt, true)
    Color(title, GOLD)
    title:SetPoint("TOPLEFT", 10, -12)
    title:SetPoint("TOPRIGHT", -10, -12)
    title:SetJustifyH("LEFT")
    title:SetText("Remove this post?")
    local body = Font(prompt, true)
    Color(body, PAPER)
    body:SetPoint("TOPLEFT", 10, -34)
    body:SetPoint("TOPRIGHT", -10, -34)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetHeight(32)
    prompt.body = body
    local remove = ClickButton(prompt, "Remove", 90, 22)
    remove:SetPoint("BOTTOMLEFT", 10, 10)
    remove.onClick = function()
      local current = prompt.listing
      prompt:Hide()
      if current and ns.Withdraw then
        ns.Withdraw(current)
      end
    end
    local keep = ClickButton(prompt, "Keep", 70, 22)
    keep:SetPoint("LEFT", remove, "RIGHT", 6, 0)
    keep.onClick = function()
      prompt:Hide()
    end
    ns.removePrompt = prompt
  end
  ns.removePrompt.listing = listing
  ns.removePrompt.body:SetText(ns.Safe(listing.title) .. " stays on the board unless you take it down.")
  ns.removePrompt:Show()
end

function ns.CreateMinimapButton()
  if ns.minimapButton or not Minimap or not ns.db then
    return
  end
  local launcher
  if LibStub then
    local ok, ldb = pcall(LibStub, "LibDataBroker-1.1", true)
    if ok and type(ldb) == "table" and type(ldb.NewDataObject) == "function" then
      launcher = ldb:NewDataObject("Hireling", {
        type = "launcher",
        text = "Hireling",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        OnClick = function(_, button)
          if button == "RightButton" then
            if ns.frame and not ns.frame:IsShown() then
              ns.frame:Show()
            end
            if ns.ShowPage then
              ns.ShowPage("options")
            end
          elseif ns.Toggle then
            ns.Toggle()
          end
        end,
        OnTooltipShow = function(tip)
          if not tip then
            return
          end
          tip:AddLine("Hireling")
          tip:AddLine("Left-click to open the board.", 1, 1, 1)
          tip:AddLine("Button addons can grab this.", 0.7, 0.7, 0.7)
        end,
      })
      ns.launcher = launcher
    end
    local iconOk, iconLib = pcall(LibStub, "LibDBIcon-1.0", true)
    if launcher and iconOk and type(iconLib) == "table" and type(iconLib.Register) == "function" then
      local registered = pcall(iconLib.Register, iconLib, "Hireling", launcher, ns.db.minimap)
      if registered then
        ns.minimapButton = true
        return
      end
    end
  end
  local button = CreateFrame("Button", "HirelingMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button.dataObject = launcher
  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local ring = button:CreateTexture(nil, "OVERLAY")
  ring:SetSize(53, 53)
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  ring:SetPoint("TOPLEFT")
  local dragging = false
  local function Angle()
    local saved = ns.db and ns.db.minimap and ns.db.minimap.angle
    if type(saved) ~= "number" then
      return 225
    end
    return saved
  end
  local function Place()
    if button:GetParent() ~= Minimap then
      return
    end
    local radius = (Minimap:GetWidth() / 2) + 5
    local rad = math.rad(Angle())
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
  end
  local function SaveAngle()
    if type(ns.db.minimap) ~= "table" then
      ns.db.minimap = {}
    end
    local scale = Minimap:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    if not scale or not mx or not my or scale == 0 then
      return
    end
    cx, cy = cx / scale, cy / scale
    ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
  end
  button:SetScript("OnDragStart", function(self)
    if self:GetParent() ~= Minimap then
      return
    end
    dragging = true
    self:SetScript("OnUpdate", function()
      SaveAngle()
      Place()
    end)
  end)
  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    SaveAngle()
    Place()
  end)
  button:SetScript("OnClick", function(_, which)
    if dragging then
      dragging = false
      return
    end
    if which == "RightButton" then
      if ns.frame and not ns.frame:IsShown() then
        ns.frame:Show()
      end
      if ns.ShowPage then
        ns.ShowPage("options")
      end
      return
    end
    if ns.Toggle then
      ns.Toggle()
    end
  end)
  button:SetScript("OnEnter", function(self)
    if not GameTooltip then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Hireling")
    GameTooltip:AddLine("Left-click to open the board.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move. Button addons can grab this.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
  Place()
  ns.minimapButton = button
end

function ns.AlertCombat(text)
  if ns.PlayTell() then
    ns.SetStatus(text)
    return
  end
  local mine = ns.MyName and ns.MyName() or nil
  if mine and SendChatMessage then
    local ok = pcall(SendChatMessage, "HIRELING: " .. text, "WHISPER", nil, mine)
    if ok then
      return
    end
  end
  ns.Print("HIRELING: " .. text)
end

function ns.HoldPopup(kind, a, b, c, d, e)
  ns.held = ns.held or {}
  ns.held[#ns.held + 1] = { kind = kind, a = a, b = b, c = c, d = d, e = e }
  if #ns.held > 8 then
    table.remove(ns.held, 1)
  end
  local text
  if kind == "ask" then
    text = (a or "Someone") .. " asked about " .. (b or "a job") .. ". The box opens when combat ends."
  elseif kind == "claim" then
    text = (a or "Someone") .. " claimed " .. (b or "a job") .. ". The box opens when combat ends."
  elseif kind == "done" then
    text = (a or "Someone") .. " marked " .. (b or "a job") .. " done. The box opens when combat ends."
  elseif kind == "decline" then
    text = (a or "Someone") .. " said no. The box opens when combat ends."
  else
    text = "Answer from " .. (a or "someone") .. ". The box opens when combat ends."
  end
  ns.AlertCombat(text)
end

function ns.ReleasePopups()
  if ns.InCombat() then
    return
  end
  local held = ns.held or {}
  ns.held = {}
  local lastAsk = nil
  local lastAnswer = nil
  local lastClaim = nil
  local lastDone = nil
  local lastDecline = nil
  for index = 1, #held do
    if held[index].kind == "ask" then
      lastAsk = held[index]
    elseif held[index].kind == "claim" then
      lastClaim = held[index]
    elseif held[index].kind == "done" then
      lastDone = held[index]
    elseif held[index].kind == "decline" then
      lastDecline = held[index]
    else
      lastAnswer = held[index]
    end
  end
  if lastAsk then
    ns.ShowReply(lastAsk.a, lastAsk.b, lastAsk.c)
  end
  if lastClaim then
    ns.ShowClaim(lastClaim.a, lastClaim.b, lastClaim.c, lastClaim.d, lastClaim.e)
  end
  if lastDone then
    ns.ShowNotice("done", lastDone.a, lastDone.b, lastDone.c)
  end
  if lastDecline then
    ns.ShowNotice("decline", lastDecline.a, lastDecline.b, lastDecline.c)
  end
  if lastAnswer then
    ns.ShowAnswer(lastAnswer.a, lastAnswer.b, lastAnswer.c, lastAnswer.d)
  end
end

function ns.StashPopupsForCombat()
  if ns.reply and ns.reply:IsShown() then
    ns.held = ns.held or {}
    ns.held[#ns.held + 1] = { kind = "ask", a = ns.reply.who, b = ns.reply.job }
    ns.reply:Hide()
  end
  if ns.claim and ns.claim:IsShown() and ns.claim.payload then
    local payload = ns.claim.payload
    ns.held = ns.held or {}
    ns.held[#ns.held + 1] = { kind = "claim", a = payload[1], b = payload[2], c = payload[3], d = payload[4], e = payload[5] }
    ns.claim:Hide()
  end
  if ns.notice and ns.notice:IsShown() and ns.notice.payload then
    local payload = ns.notice.payload
    ns.held = ns.held or {}
    ns.held[#ns.held + 1] = { kind = payload[1], a = payload[2], b = payload[3], c = payload[4] }
    ns.notice:Hide()
  end
  if ns.answer and ns.answer:IsShown() and ns.answer.payload then
    local payload = ns.answer.payload
    ns.held = ns.held or {}
    ns.held[#ns.held + 1] = { kind = "answer", a = payload[1], b = payload[2], c = payload[3], d = payload[4] }
    ns.answer:Hide()
  end
end

function ns.ShowReply(who, title, listingId)
  if ns.InCombat() then
    ns.HoldPopup("ask", who, title or "this job", listingId)
    return
  end
  if not ns.reply then
    local reply = CreateFrame("Frame", "HirelingReply", UIParent, "BackdropTemplate")
    reply:SetSize(340, 210)
    reply:SetPoint("CENTER")
    reply:SetFrameStrata("DIALOG")
    reply:SetFrameLevel(80)
    reply:SetClampedToScreen(true)
    reply:SetMovable(true)
    reply:EnableMouse(true)
    if reply.EnableKeyboard then
      reply:EnableKeyboard(true)
    end
    Paint(reply, BG, LINE)
    reply:SetScript("OnKeyDown", function(self, key)
      local typing = self.edit and self.edit.HasFocus and self.edit:HasFocus()
      if key == "ESCAPE" then
        self:Hide()
        if self.SetPropagateKeyboardInput then
          self:SetPropagateKeyboardInput(false)
        end
        return
      end
      if key == "ENTER" and not typing then
        ns.CommitReply()
        if self.SetPropagateKeyboardInput then
          self:SetPropagateKeyboardInput(false)
        end
        return
      end
      if self.SetPropagateKeyboardInput then
        self:SetPropagateKeyboardInput(true)
      end
    end)
    local close = ClickButton(reply, "X", 22, 22)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.onClick = function()
      reply:Hide()
    end
    local drag = CreateFrame("Frame", nil, reply)
    drag:SetPoint("TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, 0)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
      reply:StartMoving()
    end)
    drag:SetScript("OnDragStop", function()
      reply:StopMovingOrSizing()
    end)
    local title = Font(drag, false)
    title:SetPoint("LEFT", 10, 0)
    title:SetText("Hireling")
    Color(title, GOLD)
    local from = Font(reply, true)
    from:SetPoint("TOPLEFT", 10, -34)
    from:SetPoint("TOPRIGHT", -10, -34)
    from:SetJustifyH("LEFT")
    from:SetWordWrap(false)
    reply.from = from
    local body = Font(reply, true)
    Color(body, PAPER)
    body:SetPoint("TOPLEFT", 10, -50)
    body:SetPoint("TOPRIGHT", -10, -50)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetHeight(28)
    reply.body = body
    local names = { "Yes", "No", "Other" }
    local ids = { "yes", "no", "other" }
    local choices = {}
    local previous = nil
    for index = 1, 3 do
      local button = ClickButton(reply, names[index], 100, 22)
      button.choiceId = ids[index]
      if index == 1 then
        button:SetPoint("TOPLEFT", 10, -84)
      else
        button:SetPoint("TOPLEFT", previous, "TOPRIGHT", 6, 0)
      end
      button.onClick = function(self)
        reply.choice = self.choiceId
        PaintReplyChoice(reply)
        if self.choiceId == "other" then
          reply.edit:SetFocus()
        elseif reply.edit.ClearFocus then
          reply.edit:ClearFocus()
        end
      end
      choices[index] = button
      previous = button
    end
    reply.choices = choices
    local edit = EditBox(reply, 320, 22, false, 160)
    edit:SetPoint("TOPLEFT", 10, -114)
    edit:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
      ns.CommitReply()
    end)
    edit:SetScript("OnTextChanged", function()
      if reply.choice == "other" then
        PaintReplyChoice(reply)
      end
    end)
    reply.edit = edit
    local preview = Font(reply, true)
    Color(preview, PAPER)
    preview:SetPoint("TOPLEFT", 10, -146)
    preview:SetPoint("TOPRIGHT", -10, -146)
    preview:SetJustifyH("LEFT")
    preview:SetWordWrap(true)
    preview:SetHeight(28)
    reply.preview = preview
    local hint = Font(reply, true)
    Color(hint, MUTED)
    hint:SetPoint("BOTTOMLEFT", 10, 6)
    hint:SetText("Enter pops this answer on their addon.")
    ns.reply = reply
  end
  local reply = ns.reply
  reply.who = who
  reply.job = title or "this job"
  reply.listingId = listingId or ""
  if reply.job == "" then
    reply.job = "this job"
  end
  reply.choice = "yes"
  reply.edit:SetText("")
  reply.from:SetText(who .. " asked")
  reply.body:SetText("Do you still want " .. reply.job .. "?")
  PaintReplyChoice(reply)
  reply:Show()
  ns.PlayTell()
end

function ns.ShowAnswer(who, job, choice, other)
  if ns.InCombat() then
    ns.HoldPopup("answer", who, job, choice, other)
    return
  end
  if not ns.answer then
    local answer = CreateFrame("Frame", "HirelingAnswer", UIParent, "BackdropTemplate")
    answer:SetSize(340, 120)
    answer:SetPoint("CENTER", 0, 80)
    answer:SetFrameStrata("DIALOG")
    answer:SetFrameLevel(90)
    answer:SetClampedToScreen(true)
    answer:EnableMouse(true)
    Paint(answer, BG, LINE)
    local close = ClickButton(answer, "X", 22, 22)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.onClick = function()
      answer:Hide()
    end
    local from = Font(answer, true)
    Color(from, GOLD)
    from:SetPoint("TOPLEFT", 10, -12)
    from:SetPoint("TOPRIGHT", -32, -12)
    from:SetJustifyH("LEFT")
    answer.from = from
    local body = Font(answer, true)
    Color(body, PAPER)
    body:SetPoint("TOPLEFT", 10, -36)
    body:SetPoint("TOPRIGHT", -10, -36)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetHeight(48)
    answer.body = body
    ns.answer = answer
  end
  local line = ReplyLine(choice == "n" and "no" or (choice == "o" and "other" or "yes"), job or "this job", other)
  ns.answer.payload = { who, job, choice, other }
  ns.answer.from:SetText("Answer from " .. who)
  ns.answer.body:SetText(line or "They replied.")
  ns.answer:Show()
  ns.PlayTell()
end

function ns.ShowClaim(who, title, role, id, owner)
  if ns.InCombat() then
    ns.HoldPopup("claim", who, title or "this job", role, id, owner)
    return
  end
  if not ns.claim then
    local claim = CreateFrame("Frame", "HirelingClaim", UIParent, "BackdropTemplate")
    claim:SetSize(340, 148)
    claim:SetPoint("CENTER", 0, 40)
    claim:SetFrameStrata("DIALOG")
    claim:SetFrameLevel(90)
    claim:SetClampedToScreen(true)
    claim:EnableMouse(true)
    Paint(claim, BG, LINE)
    local close = ClickButton(claim, "X", 22, 22)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.onClick = function()
      claim:Hide()
    end
    local from = Font(claim, true)
    Color(from, GOLD)
    from:SetPoint("TOPLEFT", 10, -12)
    from:SetPoint("TOPRIGHT", -32, -12)
    from:SetJustifyH("LEFT")
    claim.from = from
    local body = Font(claim, true)
    Color(body, PAPER)
    body:SetPoint("TOPLEFT", 10, -36)
    body:SetPoint("TOPRIGHT", -10, -36)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetHeight(48)
    claim.body = body
    local no = ClickButton(claim, "No", 64, 22)
    no:SetPoint("BOTTOMLEFT", 10, 10)
    no.onClick = function()
      local claimer = claim.claimer
      local listingId = claim.listingId
      local listingOwner = claim.owner
      claim:Hide()
      ns.DeclineClaim(claimer, listingId, listingOwner)
    end
    local ok = ClickButton(claim, "OK", 64, 22)
    ok:SetPoint("LEFT", no, "RIGHT", 6, 0)
    ok.onClick = function()
      claim:Hide()
    end
    ns.claim = claim
  end
  local name = ns.PlayerName(who) or who or "Someone"
  local job = title or "this job"
  local line
  if role == "seller" then
    line = name .. " will do " .. job .. "."
  else
    line = name .. " took your offer: " .. job .. "."
  end
  ns.claim.claimer = who
  ns.claim.listingId = id
  ns.claim.owner = owner
  ns.claim.payload = { name, job, role, id, owner }
  ns.claim.from:SetText(role == "seller" and "A seller claimed this" or "Your offer was taken")
  ns.claim.body:SetText(line)
  ns.claim:Show()
  ns.PlayTell()
end

function ns.ShowNotice(kind, title, body, flag)
  if ns.InCombat() then
    ns.HoldPopup(kind, title, body, flag)
    return
  end
  if not ns.notice then
    local notice = CreateFrame("Frame", "HirelingNotice", UIParent, "BackdropTemplate")
    notice:SetSize(340, 120)
    notice:SetPoint("CENTER", 0, -20)
    notice:SetFrameStrata("DIALOG")
    notice:SetFrameLevel(90)
    notice:SetClampedToScreen(true)
    notice:EnableMouse(true)
    Paint(notice, BG, LINE)
    local close = ClickButton(notice, "X", 22, 22)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.onClick = function()
      notice:Hide()
    end
    local from = Font(notice, true)
    Color(from, GOLD)
    from:SetPoint("TOPLEFT", 10, -12)
    from:SetPoint("TOPRIGHT", -32, -12)
    from:SetJustifyH("LEFT")
    notice.from = from
    local text = Font(notice, true)
    Color(text, PAPER)
    text:SetPoint("TOPLEFT", 10, -36)
    text:SetPoint("TOPRIGHT", -10, -36)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    text:SetHeight(48)
    notice.body = text
    ns.notice = notice
  end
  ns.notice.payload = { kind, title, body, flag }
  ns.notice.from:SetText(title or "Hireling")
  ns.notice.body:SetText(body or "")
  ns.notice:Show()
  ns.PlayTell()
end

function ns.ShowDone(who, title, both)
  local name = ns.PlayerName(who) or who or "Someone"
  local job = title or "this job"
  local line = name .. " marked " .. job .. " done."
  if both then
    line = line .. " Stars are open."
  end
  ns.ShowNotice("done", "Marked done", line, both)
end

function ns.ShowDecline(who, title)
  local name = ns.PlayerName(who) or who or "They"
  ns.ShowNotice("decline", "Claim declined", name .. " said no to " .. (title or "this job") .. ".")
end

function ns.DeclineClaim(claimer, id, owner)
  if not claimer or not id or not ns.db then
    return
  end
  local mine = ns.MyName()
  owner = owner or mine
  local key = ns.Key(owner, id)
  local listing = ns.db.listings[key]
  local title = listing and listing.title or "this job"
  if listing then
    listing.claimed = nil
  end
  ns.db.jobs[key] = nil
  ns.claimPinged = nil
  if listing and listing.localOnly == true then
    ns.ShowDecline("the poster", title)
    ns.SetStatus("Test decline. The job is open again.")
    if ns.Refresh then
      ns.Refresh()
    end
    return
  end
  local packet = "N\031" .. ns.Clean(id, 12) .. "\031" .. ns.Clean(claimer, ns.NAME_MAX or 48)
  ns.Send(packet)
  if ns.SendTo then
    ns.SendTo(claimer, packet)
  end
  ns.SetStatus("Told " .. claimer .. " no.")
  if ns.Refresh then
    ns.Refresh()
  end
end

function ns.TakeListing(listing, role)
  local mine = ns.MyName()
  if not mine or not listing or listing.owner == mine then
    return
  end
  if listing.claimed and listing.claimed ~= "" and listing.claimed ~= mine then
    ns.SetStatus("Already taken by " .. listing.claimed .. ".")
    return
  end
  local key = ns.Key(listing.owner, listing.id)
  if ns.db.jobs[key] then
    ns.SetStatus("You already have this one.")
    return
  end
  listing.claimed = mine
  ns.RememberJob(key, role, listing.owner)
  if listing.localOnly == true then
    ns.ShowClaim(mine, listing.title, role, listing.id, listing.owner)
    ns.SetStatus("Test claim. This is the box the poster gets.")
  else
    local packet = ns.PackJob(listing.owner, listing.id, role)
    ns.Send(packet)
    if ns.SendTo then
      ns.SendTo(listing.owner, packet)
    end
    ns.SetStatus("Pinged " .. listing.owner .. ".")
  end
  ns.Log("You marked " .. listing.title .. " as " .. role .. ".")
  ns.RefreshDetail()
end

function ns.Withdraw(listing)
  if not listing or listing.owner ~= ns.MyName() then
    return
  end
  local key = ns.Key(listing.owner, listing.id)
  ns.db.listings[key] = nil
  if listing.localOnly ~= true then
    ns.Send("X\031" .. listing.id)
  end
  ns.selectedKey = nil
  ns.Log("Withdrew " .. (listing.title or "a listing") .. ".")
  ns.ShowPage("board")
end

function ns.SubmitReview()
  local listing = ns.selectedKey and ns.db.listings[ns.selectedKey] or nil
  local mine = ns.MyName()
  if not listing or not mine then
    return
  end
  local key = ns.Key(listing.owner, listing.id)
  local job = ns.db.jobs[key]
  if not job then
    ns.SetStatus("Take the listing before you review it.")
    return
  end
  local stars = math.floor(tonumber(ns.reviewStars) or 0)
  if stars < 1 or stars > 5 then
    ns.SetStatus("Pick 1 to 5 stars.")
    return
  end
  local review = {
    listingKey = key,
    side = job.role,
    author = mine,
    about = listing.owner,
    note = ns.Clean(ns.detail.noteEdit:GetText(), 80),
    stars = stars,
    updated = time(),
    localOnly = listing.localOnly == true,
  }
  ns.AddReview(review)
  if listing.localOnly ~= true then
    local packed = ns.PackReview(review)
    if packed then
      ns.Send(packed)
    end
  end
  ns.detail.noteEdit:SetText("")
  ns.detail.noteEdit:ClearFocus()
  ns.Log("Left " .. stars .. " stars on " .. listing.owner .. ".")
  ns.RefreshDetail()
end

function ns.DraftListing()
  return {
    id = "draft1",
    kind = ns.post and ns.post.kind or "offer",
    faction = ns.FactionCode(),
    category = ns.post and ns.post.category or "Craft",
    feeCopper = 100,
    zone = ns.post and ns.post.zone:GetText() or "",
    meet = ns.post and ns.post.meet:GetText() or "",
    title = ns.post and ns.post.title:GetText() or "",
    note = ns.post and ns.post.note:GetText() or "",
  }
end

function ns.UpdateDraftSize()
  if not ns.post or not ns.post.bytes then
    return
  end
  local packed = ns.PackListing(ns.DraftListing())
  local bytes = packed and #packed or 0
  ns.post.bytes:SetText(bytes .. " / " .. tostring(ns.MAX_MSG or 250))
  Color(ns.post.bytes, bytes > (ns.MAX_MSG or 250) and RUST or MUTED)
end

function ns.Publish()
  local mine = ns.MyName()
  if not mine then
    ns.SetStatus("Enter the world on a character before posting.")
    return
  end
  local title = ns.Clean(ns.post.title:GetText(), 42)
  if title == "" then
    ns.SetStatus("Give the job a title.")
    return
  end
  local gold = tonumber(ns.post.gold:GetText()) or 0
  local silver = tonumber(ns.post.silver:GetText()) or 0
  if silver > 99 then
    silver = 99
  end
  if gold < 0 then
    gold = 0
  end
  local fee = math.floor(gold) * 10000 + math.floor(silver) * 100
  if fee < 100 then
    ns.SetStatus("Set a fee of at least 1 silver.")
    return
  end
  if fee > ns.MAX_FEE then
    ns.SetStatus("The fee is capped at 5000 gold.")
    return
  end
  local id = ns.NewId()
  local guard = 0
  while ns.db.listings[ns.Key(mine, id)] and guard < 5 do
    id = ns.NewId()
    guard = guard + 1
  end
  local zone = ns.Clean(ns.post.zone:GetText(), 18)
  if zone == "" and GetZoneText then
    zone = ns.Clean(GetZoneText(), 18)
  end
  local listing = {
    id = id,
    owner = mine,
    kind = ns.post.kind == "task" and "task" or "offer",
    faction = ns.FactionCode(),
    category = ns.post.category or "Other",
    title = title,
    note = ns.Clean(ns.post.note:GetText(), 90),
    meet = ns.Clean(ns.post.meet:GetText(), 24),
    feeCopper = fee,
    zone = zone,
    ruleset = ns.Ruleset(),
    standing = ns.post.standing == true,
    updated = time(),
  }
  local packed = ns.PackListing(listing)
  if not packed or #packed > (ns.MAX_MSG or 250) then
    ns.SetStatus("That post is too long for one channel message.")
    return
  end
  ns.UpsertListing(listing)
  ns.Send(packed)
  ns.post.title:SetText("")
  ns.post.note:SetText("")
  ns.ClearFocus()
  ns.selectedKey = ns.Key(mine, id)
  ns.Log("Posted " .. title .. ".")
  ns.ShowPage("detail")
  ns.SetStatus("Posted on " .. ns.ChannelName() .. ". Pay in the trade window.")
end

function ns.RefreshChannel()
  if not ns.channel then
    return
  end
  local id = ns.ChannelId and ns.ChannelId() or nil
  ns.channel.summary:SetText(
    "Channel " .. ns.ChannelName()
      .. "\nId " .. tostring(id or "not joined")
      .. "\nSide " .. ns.FactionName(ns.FactionCode()) .. ". The other faction cannot be reached."
      .. "\nRuleset " .. ns.Ruleset()
      .. "\nPrefix " .. (ns.prefixRegistered and "registered" or "not registered")
      .. "\nQueued " .. tostring(ns.QueueCount and ns.QueueCount() or 0)
      .. "\nLast message " .. tostring(ns.lastDist or "none") .. " / " .. tostring(ns.lastChannelName or "none")
      .. "\n\nOther zones on this ruleset share the channel. /say range does not."
      .. "\nGold is never moved by Hireling."
  )
  local lines = {}
  for index = 1, #ns.db.log do
    lines[index] = ns.db.log[index]
  end
  if #lines == 0 then
    lines[1] = "No channel events yet."
  end
  ns.channel.log:SetText(table.concat(lines, "\n"))
  local width = ns.channel.scroll:GetWidth()
  if width and width > 40 then
    ns.channel.child:SetWidth(width)
    ns.channel.log:SetWidth(width - 4)
  end
  local height = ns.channel.log:GetStringHeight()
  if not height or height < #lines * 14 then
    height = #lines * 14
  end
  ns.channel.child:SetHeight(height + 8)
  for index = 1, 3 do
    local name = CATEGORY_LIST[index] and ({ "Normal", "PvP", "Roleplaying" })[index]
    ns.channel.rules[index]:SetActive(ns.Ruleset() == name)
  end
end

local function Walk(frame, fn)
  if not frame or not frame.GetChildren then
    return
  end
  fn(frame)
  local children = { frame:GetChildren() }
  for index = 1, #children do
    Walk(children[index], fn)
  end
end

function ns.RunCheck()
  local issues = {}
  local function add(text)
    if #issues < 12 then
      issues[#issues + 1] = text
    end
  end
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    add("C_ChatInfo.SendAddonMessage is missing.")
  end
  if not C_ChatInfo or not C_ChatInfo.RegisterAddonMessagePrefix then
    add("RegisterAddonMessagePrefix is missing.")
  end
  if ns.SelfTest then
    local tests = ns.SelfTest()
    for index = 1, #tests do
      add(tests[index])
    end
  end
  if not ns.frame then
    add("The window was not built.")
  else
    local strata = ns.frame:GetFrameStrata()
    if strata ~= "HIGH" then
      add("Window strata is " .. tostring(strata) .. ", expected HIGH.")
    end
    if ns.close and ns.drag and ns.close:GetFrameLevel() <= ns.drag:GetFrameLevel() then
      add("The close button is under the drag bar.")
    end
    if ns.tabBar and ns.content and ns.frame:IsShown() then
      local tabBottom = ns.tabBar:GetBottom()
      local contentTop = ns.content:GetTop()
      if tabBottom and contentTop and contentTop > tabBottom + 1 then
        add("The page overlaps the tabs.")
      end
    end
    if ns.edits then
      for index = 1, #ns.edits do
        if not ns.edits[index]:GetFont() then
          add("An edit box has no font.")
          break
        end
      end
    end
    Walk(ns.frame, function(child)
      if child.GetFrameStrata then
        local childStrata = child:GetFrameStrata()
        if childStrata == "TOOLTIP" or childStrata == "FULLSCREEN" or childStrata == "FULLSCREEN_DIALOG" or childStrata == "DIALOG" then
          add("A child frame is on the " .. childStrata .. " strata.")
        end
      end
    end)
  end
  if #issues == 0 then
    ns.Print("Check passed. " .. ns.ChannelName() .. " id " .. tostring(ns.ChannelId() or "none") .. ". A newer build is only noticed when another player has it.")
  else
    ns.Print("Check found " .. #issues .. " issue(s).")
    for index = 1, #issues do
      ns.Print(issues[index])
    end
  end
end

function ns.SetTheme(name)
  if not PALETTES[name] or not ns.db then
    return
  end
  ns.db.theme = name
  ns.ApplyPalette(name)
  local function recolor(frame)
    if not frame then
      return
    end
    if frame.hirelingFill and frame.SetBackdropColor then
      local fill = frame.hirelingFill
      frame:SetBackdropColor(fill[1], fill[2], fill[3], 1)
    end
    if frame.hirelingBorder and frame.SetBackdropBorderColor then
      local edge = frame.hirelingBorder
      frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
    end
    if frame.GetRegions then
      local regions = { frame:GetRegions() }
      for index = 1, #regions do
        local region = regions[index]
        if region and region.hirelingColor and region.SetTextColor then
          local color = region.hirelingColor
          region:SetTextColor(color[1], color[2], color[3], 1)
        end
      end
    end
    if frame.GetChildren then
      local children = { frame:GetChildren() }
      for index = 1, #children do
        recolor(children[index])
      end
    end
  end
  recolor(ns.frame)
  recolor(ns.reply)
  recolor(ns.answer)
  if ns.RefreshOptions then
    ns.RefreshOptions()
  end
end

function ns.BuildUI()
  if ns.frame then
    return
  end
  if ns.ApplyPalette and ns.ThemeName then
    ns.ApplyPalette(ns.ThemeName())
  end
  ns.edits = {}
  ns.filterKind = "all"
  ns.filterCategory = "all"
  ns.sortMode = "recent"
  ns.searchText = ""
  ns.page = "board"
  ns.reviewStars = 5

  local frame = CreateFrame("Frame", "HirelingFrame", UIParent, "BackdropTemplate")
  frame:SetSize(540, 500)
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(50)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetToplevel(true)
  if frame.SetClipsChildren then
    frame:SetClipsChildren(true)
  end
  Paint(frame, BG, LINE)
  frame:SetScript("OnHide", function()
    ns.ClearFocus()
  end)
  frame:Hide()
  ns.frame = frame

  if UISpecialFrames then
    local found = false
    for index = 1, #UISpecialFrames do
      if UISpecialFrames[index] == "HirelingFrame" then
        found = true
        break
      end
    end
    if not found then
      UISpecialFrames[#UISpecialFrames + 1] = "HirelingFrame"
    end
  end

  local close = ClickButton(frame, "X", 22, 22)
  close:SetPoint("TOPRIGHT", -6, -6)
  close.onClick = function()
    frame:Hide()
  end
  ns.close = close

  local drag = CreateFrame("Frame", nil, frame)
  drag:SetPoint("TOPLEFT", 0, 0)
  drag:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, 0)
  drag:SetHeight(32)
  drag:EnableMouse(true)
  drag:RegisterForDrag("LeftButton")
  drag:SetScript("OnDragStart", function()
    frame:StartMoving()
  end)
  drag:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    ns.SavePosition()
  end)
  local title = Font(drag, false)
  title:SetPoint("LEFT", 12, 0)
  title:SetText("Hireling")
  Color(title, GOLD)
  local optionsBtn = ClickButton(drag, "Options", 72, 18)
  optionsBtn:SetPoint("RIGHT", -4, 0)
  optionsBtn.onClick = function()
    if ns.page == "options" then
      ns.ShowPage("board")
    else
      ns.ShowPage("options")
    end
  end
  ns.optionsButton = optionsBtn
  ns.drag = drag

  local tabBar = CreateFrame("Frame", nil, frame)
  tabBar:SetPoint("TOPLEFT", 8, -36)
  tabBar:SetPoint("TOPRIGHT", -8, -36)
  tabBar:SetHeight(24)
  ns.tabBar = tabBar
  ns.tabs = {}
  local tabNames = { "board", "post", "yours", "channel" }
  local tabLabels = { "Board", "Post", "Yours", "Channel" }
  local previous = nil
  for index = 1, 4 do
    local tab = ClickButton(tabBar, tabLabels[index], 128, 24)
    if index == 1 then
      tab:SetPoint("TOPLEFT", 0, 0)
    else
      tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", 4, 0)
    end
    tab.pageName = tabNames[index]
    tab.onClick = function(self)
      ns.ShowPage(self.pageName)
    end
    ns.tabs[tabNames[index]] = tab
    previous = tab
  end

  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", 8, -66)
  content:SetPoint("BOTTOMRIGHT", -8, 26)
  ns.content = content
  ns.pages = {}

  local status = Font(frame, true)
  status:SetPoint("BOTTOMLEFT", 10, 6)
  status:SetPoint("BOTTOMRIGHT", -10, 6)
  status:SetHeight(16)
  status:SetJustifyH("LEFT")
  status:SetWordWrap(false)
  if status.SetMaxLines then
    status:SetMaxLines(1)
  end
  ns.status = status

  local function Page()
    local page = CreateFrame("Frame", nil, content)
    page:SetAllPoints(content)
    page:Hide()
    return page
  end

  local function ScrollArea(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 1)
    scroll:SetScrollChild(child)
    child:EnableMouse(true)
    child:EnableMouseWheel(true)
    local function onWheel(_, delta)
      ns.Wheel(scroll, delta)
    end
    scroll:SetScript("OnMouseWheel", onWheel)
    child:SetScript("OnMouseWheel", onWheel)
    scroll:SetScript("OnSizeChanged", function(self, width)
      if width and width > 40 then
        child:SetWidth(width)
      end
    end)
    return scroll, child
  end

  local board = Page()
  ns.pages.board = board
  local search = EditBox(board, 200, 24, false, 40)
  search:SetPoint("TOPLEFT", board, "TOPLEFT", 0, 0)
  search:SetPoint("TOPRIGHT", board, "TOPRIGHT", 0, 0)
  search:SetScript("OnTextChanged", function(self)
    ns.searchText = self:GetText() or ""
    ns.RefreshBoard()
  end)
  local all = ClickButton(board, "All", 172, 24)
  all:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -4)
  local offers = ClickButton(board, "Offers", 172, 24)
  offers:SetPoint("TOPLEFT", all, "TOPRIGHT", 4, 0)
  local bids = ClickButton(board, "Bids", 172, 24)
  bids:SetPoint("TOPLEFT", offers, "TOPRIGHT", 4, 0)
  all.onClick = function()
    ns.filterKind = "all"
    ns.RefreshBoard()
  end
  offers.onClick = function()
    ns.filterKind = "offer"
    ns.RefreshBoard()
  end
  bids.onClick = function()
    ns.filterKind = "task"
    ns.RefreshBoard()
  end
  local recent = ClickButton(board, "Recent", 260, 22)
  recent:SetPoint("TOPLEFT", all, "BOTTOMLEFT", 0, -4)
  local payout = ClickButton(board, "Payout", 260, 22)
  payout:SetPoint("TOPLEFT", recent, "TOPRIGHT", 4, 0)
  recent.onClick = function()
    ns.sortMode = "recent"
    ns.RefreshBoard()
  end
  payout.onClick = function()
    ns.sortMode = "payout"
    ns.RefreshBoard()
  end
  local category = ClickButton(board, "All crafts", 524, 22)
  category:SetPoint("TOPLEFT", recent, "BOTTOMLEFT", 0, -4)
  category.onClick = function(self)
    ns.OpenChoices(self, {
      { id = "all", label = "All crafts" },
      { id = "Craft", label = "Craft" },
      { id = "Enchant", label = "Enchant" },
      { id = "Gather", label = "Gather" },
      { id = "Group", label = "Group" },
      { id = "Portal", label = "Portal" },
      { id = "Other", label = "Other" },
    }, ns.filterCategory or "all", function(id)
      ns.filterCategory = id
      ns.RefreshBoard()
    end)
  end
  local boardScroll = ScrollArea(board)
  boardScroll:SetPoint("TOPLEFT", category, "BOTTOMLEFT", 0, -6)
  boardScroll:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT", 0, 0)
  local empty = CreateFrame("Frame", nil, board)
  empty:SetAllPoints(boardScroll)
  empty:EnableMouse(false)
  local emptyText = Font(empty, false)
  emptyText:SetPoint("CENTER")
  emptyText:SetText("No listings on this channel yet.")
  empty.text = emptyText
  empty:Hide()
  ns.board = {
    scroll = boardScroll,
    rows = {},
    all = all,
    offers = offers,
    bids = bids,
    recent = recent,
    payout = payout,
    category = category,
    empty = empty,
  }

  local post = Page()
  ns.pages.post = post
  ns.post = { kind = "offer", category = "Craft" }
  local offerBtn = ClickButton(post, "Offer", 258, 24)
  offerBtn:SetPoint("TOPLEFT", 0, 0)
  local taskBtn = ClickButton(post, "Bid", 258, 24)
  taskBtn:SetPoint("TOPLEFT", offerBtn, "TOPRIGHT", 4, 0)
  local categoryBtn = ClickButton(post, "Craft", 520, 24)
  categoryBtn:SetPoint("TOPLEFT", offerBtn, "BOTTOMLEFT", 0, -6)
  local function paintKind()
    offerBtn:SetActive(ns.post.kind == "offer")
    taskBtn:SetActive(ns.post.kind == "task")
    categoryBtn:SetLabel(ns.post.category)
    ns.UpdateDraftSize()
  end
  offerBtn.onClick = function()
    ns.post.kind = "offer"
    paintKind()
  end
  taskBtn.onClick = function()
    ns.post.kind = "task"
    paintKind()
  end
  categoryBtn.onClick = function(self)
    local choices = {}
    for index = 1, #CATEGORY_LIST do
      choices[index] = { id = CATEGORY_LIST[index], label = CATEGORY_LIST[index] }
    end
    ns.OpenChoices(self, choices, ns.post.category, function(id)
      ns.post.category = id
      paintKind()
    end)
  end
  local titleLabel = FieldLabel(post, "Title")
  titleLabel:SetPoint("TOPLEFT", categoryBtn, "BOTTOMLEFT", 0, -8)
  local titleEdit = EditBox(post, 520, 24, false, 42)
  titleEdit:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -2)
  local feeLabel = FieldLabel(post, "Gold")
  feeLabel:SetPoint("TOPLEFT", titleEdit, "BOTTOMLEFT", 0, -8)
  local gold = EditBox(post, 80, 24, false, 4)
  gold:SetPoint("TOPLEFT", feeLabel, "BOTTOMLEFT", 0, -2)
  if gold.SetNumeric then
    gold:SetNumeric(true)
  end
  local silverLabel = FieldLabel(post, "Silver")
  silverLabel:SetPoint("BOTTOMLEFT", gold, "TOPLEFT", 96, 2)
  local silver = EditBox(post, 64, 24, false, 2)
  silver:SetPoint("TOPLEFT", gold, "TOPRIGHT", 8, 0)
  if silver.SetNumeric then
    silver:SetNumeric(true)
  end
  local zoneLabel = FieldLabel(post, "Zone")
  local zone = EditBox(post, 340, 24, false, 18)
  zone:SetPoint("TOPLEFT", silver, "TOPRIGHT", 8, 0)
  zoneLabel:SetPoint("BOTTOMLEFT", zone, "TOPLEFT", 0, 2)
  local meetLabel = FieldLabel(post, "Where to meet")
  meetLabel:SetPoint("TOPLEFT", gold, "BOTTOMLEFT", 0, -8)
  local meet = EditBox(post, 520, 24, false, 24)
  meet:SetPoint("TOPLEFT", meetLabel, "BOTTOMLEFT", 0, -2)
  local noteLabel = FieldLabel(post, "Note")
  noteLabel:SetPoint("TOPLEFT", meet, "BOTTOMLEFT", 0, -8)
  local note = EditBox(post, 520, 64, true, 90)
  note:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -2)
  local postBtn = ClickButton(post, "Post on the channel", 200, 26)
  postBtn:SetPoint("BOTTOMLEFT", post, "BOTTOMLEFT", 0, 0)
  postBtn:SetPoint("BOTTOMRIGHT", post, "BOTTOMRIGHT", 0, 0)
  postBtn.onClick = function()
    ns.Publish()
  end
  local bytes = Font(post, true)
  bytes:SetPoint("BOTTOMLEFT", postBtn, "TOPLEFT", 0, 4)
  local standingBtn = ClickButton(post, "One time", 140, 22)
  standingBtn:SetPoint("BOTTOMLEFT", bytes, "TOPLEFT", 0, 4)
  standingBtn.onClick = function()
    ns.post.standing = not ns.post.standing
    standingBtn:SetLabel(ns.post.standing and "Keep this up" or "One time")
    standingBtn:SetActive(ns.post.standing == true)
  end
  ns.post.title = titleEdit
  ns.post.gold = gold
  ns.post.silver = silver
  ns.post.zone = zone
  ns.post.meet = meet
  ns.post.note = note
  ns.post.bytes = bytes
  local function draftChanged()
    ns.UpdateDraftSize()
  end
  titleEdit:SetScript("OnTextChanged", draftChanged)
  gold:SetScript("OnTextChanged", draftChanged)
  silver:SetScript("OnTextChanged", draftChanged)
  zone:SetScript("OnTextChanged", draftChanged)
  meet:SetScript("OnTextChanged", draftChanged)
  note:SetScript("OnTextChanged", draftChanged)
  post:SetScript("OnShow", function()
    if zone:GetText() == "" and GetZoneText then
      zone:SetText(GetZoneText() or "")
    end
    paintKind()
  end)

  local yours = Page()
  ns.pages.yours = yours
  local inboxText = Font(yours, true)
  inboxText:SetPoint("TOPLEFT", 0, 0)
  inboxText:SetPoint("TOPRIGHT", -96, 0)
  inboxText:SetHeight(44)
  inboxText:SetJustifyH("LEFT")
  inboxText:SetWordWrap(true)
  inboxText:SetText("Inbox is empty.")
  local openInbox = ClickButton(yours, "Open ask", 90, 22)
  openInbox:SetPoint("TOPRIGHT", 0, 0)
  openInbox.onClick = function()
    local inbox = ns.db and ns.db.inbox or {}
    local item = inbox[#inbox]
    if item and ns.ShowReply then
      ns.ShowReply(item.who, item.title, item.id)
    end
  end
  local yoursScroll = ScrollArea(yours)
  yoursScroll:SetPoint("TOPLEFT", 0, -48)
  yoursScroll:SetPoint("BOTTOMRIGHT", 0, 0)
  local yoursEmpty = CreateFrame("Frame", nil, yours)
  yoursEmpty:SetAllPoints(yoursScroll)
  yoursEmpty:EnableMouse(false)
  local yoursText = Font(yoursEmpty, false)
  yoursText:SetPoint("CENTER")
  yoursText:SetText("Nothing of yours on this ruleset yet.")
  yoursEmpty:Hide()
  ns.yours = { scroll = yoursScroll, rows = {}, empty = yoursEmpty, inbox = inboxText, openInbox = openInbox }

  local channel = Page()
  ns.pages.channel = channel
  local summary = Font(channel, true)
  summary:SetPoint("TOPLEFT", 0, 0)
  summary:SetWidth(520)
  summary:SetJustifyH("LEFT")
  summary:SetWordWrap(true)
  summary:SetHeight(110)
  local rules = {}
  local ruleNames = { "Normal", "PvP", "Roleplaying" }
  local rulePrev = nil
  for index = 1, 3 do
    local button = ClickButton(channel, ruleNames[index], 100, 22)
    if index == 1 then
      button:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -6)
    else
      button:SetPoint("TOPLEFT", rulePrev, "TOPRIGHT", 4, 0)
    end
    button.ruleName = ruleNames[index]
    button.onClick = function(self)
      ns.db.rulesetOverride = self.ruleName
      if ns.Join then
        ns.Join()
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(2, ns.Announce)
      elseif ns.Announce then
        ns.Announce()
      end
      ns.Refresh()
    end
    rules[index] = button
    rulePrev = button
  end
  local sync = ClickButton(channel, "Sync now", 120, 22)
  sync:SetPoint("TOPLEFT", rules[1], "BOTTOMLEFT", 0, -6)
  sync.onClick = function()
    if ns.Announce then
      ns.Announce()
    end
  end
  local advertise = ClickButton(channel, "Advertise in trade", 180, 22)
  advertise:SetPoint("LEFT", sync, "RIGHT", 6, 0)
  advertise.onClick = function()
    if ns.Advertise then
      ns.Advertise()
    end
  end
  local channelScroll, channelChild = ScrollArea(channel)
  channelScroll:SetPoint("TOPLEFT", sync, "BOTTOMLEFT", 0, -8)
  channelScroll:SetPoint("BOTTOMRIGHT", channel, "BOTTOMRIGHT", 0, 0)
  local log = Font(channelChild, true)
  log:SetPoint("TOPLEFT", 0, 0)
  log:SetJustifyH("LEFT")
  log:SetWordWrap(true)
  ns.channel = {
    summary = summary,
    rules = rules,
    scroll = channelScroll,
    child = channelChild,
    log = log,
  }

  local options = Page()
  ns.pages.options = options
  local optionsBack = ClickButton(options, "Back", 70, 22)
  optionsBack:SetPoint("TOPLEFT", 0, 0)
  optionsBack.onClick = function()
    ns.ShowPage("board")
  end
  local optionsTitle = Font(options, false)
  optionsTitle:SetPoint("LEFT", optionsBack, "RIGHT", 8, 0)
  optionsTitle:SetText("Options")
  Color(optionsTitle, GOLD)
  local function OptionRow(label, y, getter, setter)
    local text = Font(options, true)
    text:SetPoint("TOPLEFT", 0, y)
    text:SetWidth(400)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(label)
    Color(text, PAPER)
    local button = ClickButton(options, "Off", 72, 22)
    button:SetPoint("TOPRIGHT", 0, y)
    button.refresh = function()
      local on = getter()
      button:SetLabel(on and "On" or "Off")
      button:SetActive(on)
    end
    button.onClick = function()
      setter(not getter())
      if ns.RefreshOptions then
        ns.RefreshOptions()
      end
    end
    return button
  end
  local testRow = OptionRow("Test mode. Sample cards stay on this computer.", -36, function()
    return ns.db and ns.db.testMode == true
  end, function(on)
    ns.SetTestMode(on)
  end)
  local soundRow = OptionRow("Sound when an ask or answer arrives.", -66, function()
    return not ns.db or ns.db.sound ~= false
  end, function(on)
    ns.db.sound = on and true or false
  end)
  local soundHint = Font(options, true)
  soundHint:SetPoint("TOPLEFT", 0, -92)
  soundHint:SetText("Click a sound to preview it.")
  Color(soundHint, MUTED or PAPER)
  local soundButtons = {}
  for index = 1, #ns.SOUNDS do
    local sound = ns.SOUNDS[index]
    local button = ClickButton(options, sound.label, 98, 22)
    button.soundId = sound.id
    local col = (index - 1) % 5
    local row = math.floor((index - 1) / 5)
    button:SetPoint("TOPLEFT", col * 102, -110 - row * 26)
    button.onClick = function(self)
      ns.PreviewSound(self.soundId)
    end
    soundButtons[index] = button
  end
  local loginRow = OptionRow("Open Hireling when you log in.", -168, function()
    return ns.db and ns.db.openOnLogin == true
  end, function(on)
    ns.db.openOnLogin = on and true or false
  end)
  local themeLabel = Font(options, true)
  themeLabel:SetPoint("TOPLEFT", 0, -204)
  themeLabel:SetText("Theme")
  Color(themeLabel, PAPER)
  local themeButtons = {}
  local themePrev = nil
  for index = 1, #THEME_ORDER do
    local name = THEME_ORDER[index]
    local button = ClickButton(options, THEME_LABEL[name], 88, 22)
    button.themeName = name
    if index == 1 then
      button:SetPoint("TOPLEFT", 0, -224)
    else
      button:SetPoint("TOPLEFT", themePrev, "TOPRIGHT", 6, 0)
    end
    button.onClick = function(self)
      ns.SetTheme(self.themeName)
    end
    themeButtons[index] = button
    themePrev = button
  end
  local scaleLabel = Font(options, true)
  scaleLabel:SetPoint("TOPLEFT", 0, -258)
  scaleLabel:SetText("Window scale")
  Color(scaleLabel, PAPER)
  local scaleValue = Font(options, false)
  scaleValue:SetPoint("TOPLEFT", 110, -256)
  Color(scaleValue, GOLD)
  local scaleDown = ClickButton(options, "-", 28, 22)
  scaleDown:SetPoint("TOPLEFT", 170, -258)
  scaleDown.onClick = function()
    ns.db.scale = (tonumber(ns.db.scale) or 1) - 0.1
    ns.ApplyScale()
    ns.RefreshOptions()
  end
  local scaleUp = ClickButton(options, "+", 28, 22)
  scaleUp:SetPoint("LEFT", scaleDown, "RIGHT", 4, 0)
  scaleUp.onClick = function()
    ns.db.scale = (tonumber(ns.db.scale) or 1) + 0.1
    ns.ApplyScale()
    ns.RefreshOptions()
  end
  local discord = ClickButton(options, "Discord", 110, 22)
  discord:SetPoint("TOPLEFT", 0, -292)
  discord.onClick = function()
    ns.ShowDiscord()
  end
  local changelog = ClickButton(options, "Changelog", 110, 22)
  changelog:SetPoint("LEFT", discord, "RIGHT", 8, 0)
  changelog.onClick = function()
    ns.ShowChangelog()
  end
  local discordHint = Font(options, true)
  discordHint:SetPoint("LEFT", changelog, "RIGHT", 8, 0)
  discordHint:SetText("Copies the invite.")
  Color(discordHint, PAPER)
  ns.options = {
    test = testRow,
    sound = soundRow,
    sounds = soundButtons,
    login = loginRow,
    themes = themeButtons,
    scale = scaleValue,
  }
  function ns.RefreshOptions()
    if not ns.options then
      return
    end
    ns.options.test.refresh()
    ns.options.sound.refresh()
    local chosen = ns.db and ns.db.soundId or "tell"
    for index = 1, #ns.options.sounds do
      local button = ns.options.sounds[index]
      button:SetActive(button.soundId == chosen)
    end
    ns.options.login.refresh()
    local theme = ns.ThemeName and ns.ThemeName() or "acid"
    for index = 1, #ns.options.themes do
      local button = ns.options.themes[index]
      button:SetActive(button.themeName == theme)
    end
    local scale = tonumber(ns.db and ns.db.scale) or 1
    ns.options.scale:SetText(string.format("%.1f", scale))
  end

  local detail = Page()
  ns.pages.detail = detail
  local back = ClickButton(detail, "Back", 70, 22)
  back:SetPoint("TOPLEFT", 0, 0)
  back.onClick = function()
    ns.ShowPage("board")
  end
  local whisper = ClickButton(detail, "Ask", 90, 22)
  whisper:SetPoint("LEFT", back, "RIGHT", 6, 0)
  whisper.onClick = function()
    local listing = ns.selectedKey and ns.db.listings[ns.selectedKey] or nil
    if listing then
      ns.AskListing(listing)
    end
  end
  local detailTitle = Font(detail, false)
  detailTitle:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 0, -6)
  detailTitle:SetWidth(500)
  detailTitle:SetJustifyH("LEFT")
  detailTitle:SetWordWrap(true)
  detailTitle:SetHeight(36)
  local meta = Font(detail, true)
  Color(meta, GOLD)
  meta:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -2)
  meta:SetWidth(500)
  meta:SetJustifyH("LEFT")
  meta:SetWordWrap(true)
  meta:SetHeight(32)
  local detailNote = Font(detail, true)
  Color(detailNote, PAPER)
  detailNote:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -4)
  detailNote:SetWidth(500)
  detailNote:SetJustifyH("LEFT")
  detailNote:SetWordWrap(true)
  detailNote:SetHeight(36)
  local action = ClickButton(detail, "Take", 500, 24)
  action:SetPoint("TOPLEFT", detailNote, "BOTTOMLEFT", 0, -6)
  local form = CreateFrame("Frame", nil, detail, "BackdropTemplate")
  Paint(form, PANEL)
  form:SetPoint("BOTTOMLEFT", detail, "BOTTOMLEFT", 0, 0)
  form:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", 0, 0)
  form:SetHeight(78)
  local formLabel = Font(form, true)
  Color(formLabel, MUTED)
  formLabel:SetPoint("TOPLEFT", 8, -6)
  local starButtons = {}
  for index = 1, 5 do
    local star = ClickButton(form, tostring(index), 28, 22)
    if index == 1 then
      star:SetPoint("TOPLEFT", formLabel, "BOTTOMLEFT", 0, -4)
    else
      star:SetPoint("TOPLEFT", starButtons[index - 1], "TOPRIGHT", 4, 0)
    end
    star.starValue = index
    star.onClick = function(self)
      ns.reviewStars = self.starValue
      PaintStarPicker()
    end
    starButtons[index] = star
  end
  local reviewNote = EditBox(form, 210, 22, false, 80)
  reviewNote:SetPoint("TOPLEFT", starButtons[5], "TOPRIGHT", 6, 0)
  local reviewBtn = ClickButton(form, "Leave", 64, 22)
  reviewBtn:SetPoint("TOPLEFT", reviewNote, "TOPRIGHT", 4, 0)
  reviewBtn.onClick = function()
    ns.SubmitReview()
  end
  form:Hide()
  local detailScroll, detailChild = ScrollArea(detail)
  local body = Font(detailChild, true)
  body:SetPoint("TOPLEFT", 0, 0)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetWordWrap(true)
  ns.detail = {
    page = detail,
    title = detailTitle,
    meta = meta,
    note = detailNote,
    action = action,
    whisper = whisper,
    form = form,
    formLabel = formLabel,
    stars = starButtons,
    noteEdit = reviewNote,
    scroll = detailScroll,
    body = body,
  }

  local function RaiseChrome()
    local base = frame:GetFrameLevel()
    if base < 1 then
      base = 1
    end
    drag:SetFrameLevel(base + 2)
    content:SetFrameLevel(base + 6)
    tabBar:SetFrameLevel(base + 10)
    close:SetFrameLevel(base + 30)
    for _, page in pairs(ns.pages) do
      page:SetFrameLevel(content:GetFrameLevel() + 1)
    end
    form:SetFrameLevel(detail:GetFrameLevel() + 8)
    detailScroll:SetFrameLevel(detail:GetFrameLevel() + 2)
  end
  RaiseChrome()

  frame:SetScript("OnShow", function()
    RaiseChrome()
    ns.ApplyScale()
    ns.Refresh()
  end)

  function ns.ShowPage(name)
    if not ns.pages[name] then
      name = "board"
    end
    ns.page = name
    for key, page in pairs(ns.pages) do
      if key == name then
        page:Show()
      else
        page:Hide()
      end
    end
    if ns.choices then
      ns.choices:Hide()
    end
    for key, button in pairs(ns.tabs) do
      button:SetActive(key == name)
    end
    if ns.optionsButton then
      ns.optionsButton:SetActive(name == "options")
    end
    if frame:IsShown() then
      ns.Refresh()
    end
  end

  function ns.Refresh()
    if not frame:IsShown() then
      return
    end
    ns.UpdateStatus()
    if ns.page == "board" then
      ns.RefreshBoard()
    elseif ns.page == "yours" then
      ns.RefreshYours()
    elseif ns.page == "detail" then
      ns.RefreshDetail()
    elseif ns.page == "channel" then
      ns.RefreshChannel()
    elseif ns.page == "options" then
      ns.RefreshOptions()
    end
  end

  ns.ApplyScale()
  ns.ApplyPosition()
  ns.ShowPage("board")
  paintKind()
  ns.UpdateStatus()
  ns.CreateMinimapButton()
end
