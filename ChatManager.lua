-- ChatManager.lua

-- 创建主插件表
ChatManager = {}
-- 获取当前玩家的名称
ChatManager.playerName = UnitName("player")

-- 初始化SavedVariables数据库
ChatManagerDB = ChatManagerDB or {
  contacts = {},
  chats = {},
  presets = {},
  autoReplies = {},
  currentContact = nil,
  framePosition = nil
}

local function meOrHim(name)
  if name == UnitName("player") then
    return "我"
  else
    return name .. "后，给我说下我去换号~"
  end
end

local materialString =
"制作材料点这个查询 |cffffd000|Htrade:Player-707-068F7148:45357:773|h[铭文]|h|r |cffffd000|Htrade:Player-707-068F7148:3908:197|h[裁缝]|h|r，做法杖要3星材料2星公函2星美化，做论述用最便宜的材料"

local replyPresets = {
  { name = "好的", message = "好的" },
  { name = "对的", message = "对的" },
  { name = "可以", message = "可以" },
  { name = "材料", message = materialString },
  { name = "不会", message = "不会做哈～" },
  { name = "都行", message = "都行" },
  { name = "done", message = "做好了，请在邮箱查收~" },
  { name = "不客气", message = "~" },
  { name = "做啥", message = "做啥来着~" },
  { name = "锻造下单", message = "锻造下单给圣焰之辉，下单后给我说我去换号~" },
  { name = "制皮下单", message = "制皮下单给Reducer，下单后给我说我去换号~" },
  { name = "法杖布甲", message = "法杖5k包619，8k包636，免费做606和590，自己买3星材料2星公函2星美化，做好纹章，法杖和布甲指定5星下单给" .. meOrHim("霜魄寒") },
  { name = "论述", message = "论述一星材料即可，全专业的都能免费做。注意：每个专业一周只能吃一个，可以多做几个屯着~" },
}



local autoReplies = {
  ["1"] = "在的（自动回复～）",
  ["材料"] = materialString,

  -- ["帮忙"] = "我现在不方便，稍后联系你。",
  -- ["组队"] = "好的，我马上来。"
}

-- 设置当前联系人为SavedVariables中的值
ChatManager.currentContact = ChatManagerDB.currentContact

-- 创建UI框架，使用更美观的模板
local frame = CreateFrame("Frame", "ChatManagerFrame", UIParent, "UIPanelDialogTemplate, BackdropTemplate")
ChatManager.frame = frame

frame:SetSize(800, 600)
frame:SetPoint("CENTER")
frame:SetFrameStrata("FULLSCREEN_DIALOG") -- 设置UI层级为最高
frame:SetToplevel(true)                   -- 确保窗口在最上层
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
  self:StartMoving()
end)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  -- 保存窗口位置到数据库
  local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
  ChatManagerDB.framePosition = { point, relativePoint, xOfs, yOfs }
end)


-- 注册 GLOBAL_MOUSE_DOWN 事件
frame:RegisterEvent("GLOBAL_MOUSE_DOWN")

-- 设置点击事件处理函数
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "GLOBAL_MOUSE_DOWN" then
    local button, mouseFocus = ...
    if mouseFocus and (mouseFocus == self or self:IsChild(mouseFocus)) then
      -- 点击在窗口内，提升层级
      if self:GetFrameStrata() ~= "FULLSCREEN_DIALOG" then
        self:SetFrameStrata("FULLSCREEN_DIALOG")
      end
    else
      -- 点击在窗口外，降低层级
      if self:GetFrameStrata() ~= "MEDIUM" then
        self:SetFrameStrata("MEDIUM")
      end
    end
  end
end)

-- 当窗口被点击时，提升层级
frame:SetScript("OnMouseDown", function(self)
  if self:GetFrameStrata() ~= "FULLSCREEN_DIALOG" then
    self:SetFrameStrata("FULLSCREEN_DIALOG")
  end
end)

-- 恢复窗口位置
if ChatManagerDB.framePosition then
  frame:ClearAllPoints()
  frame:SetPoint(ChatManagerDB.framePosition[1], UIParent, ChatManagerDB.framePosition[2], ChatManagerDB.framePosition
    [3], ChatManagerDB.framePosition[4])
end

-- 添加背景纹理
local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints()
bgTexture:SetColorTexture(0, 0, 0, 0.7) -- 半透明黑色背景

-- 创建窗口标题
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlightLarge")
frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
frame.title:SetText("私聊管理窗口")

-- 创建左侧联系人列表的背景框架
local contactsBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
contactsBg:SetSize(250, 500)
contactsBg:SetPoint("TOPLEFT", 20, -50)
contactsBg:SetBackdrop({
  bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
contactsBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
contactsBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

-- 创建联系人列表标题
local contactsTitle = contactsBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
contactsTitle:SetPoint("TOPLEFT", 10, -10)
contactsTitle:SetText("联系人")

-- 创建左侧联系人列表
local contactsScrollFrame = CreateFrame("ScrollFrame", "ContactsScrollFrame", contactsBg, "UIPanelScrollFrameTemplate")
contactsScrollFrame:SetSize(220, 420)
contactsScrollFrame:SetPoint("TOPLEFT", 10, -40)

local contactsFrame = CreateFrame("Frame", nil, contactsScrollFrame)
contactsFrame:SetSize(220, 420)
contactsScrollFrame:SetScrollChild(contactsFrame)

-- 创建右侧聊天记录的背景框架
local chatBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
chatBg:SetSize(500, 500)
chatBg:SetPoint("TOPRIGHT", -20, -50)
chatBg:SetBackdrop({
  bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
chatBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
chatBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

-- 创建聊天记录标题
local chatTitle = chatBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
chatTitle:SetPoint("TOPLEFT", 10, -10)
chatTitle:SetText("聊天记录")

-- 创建右侧聊天记录
local chatScrollFrame = CreateFrame("ScrollFrame", "ChatScrollFrame", chatBg, "UIPanelScrollFrameTemplate")
chatScrollFrame:SetSize(480, 420)
chatScrollFrame:SetPoint("TOPLEFT", 10, -40)

local chatFrame = CreateFrame("Frame", nil, chatScrollFrame)
chatFrame:SetSize(480, 420)
chatScrollFrame:SetScrollChild(chatFrame)

-- 当前选中的联系人高亮颜色
local highlightColor = { 0.2, 0.6, 0.8, 0.5 } -- 调整为更柔和的蓝色

-- 无背景颜色
local defaultBackdropColor = { 0, 0, 0, 0 }

-- 定义消息颜色
local playerMessageColor = { 0.9, 0.9, 0.9, 1 }     -- 亮灰色
local contactMessageColor = { 0.46, 0.71, 0.77, 1 } -- 浅黄色

-- 最大联系人数
local MAX_CONTACTS = 40

-- 限制联系人数量并删除过时的联系人和聊天记录
local function LimitContacts()
  local contacts = ChatManagerDB.contacts
  table.sort(contacts, function(a, b)
    return a.lastContact > b.lastContact
  end)

  while #contacts > MAX_CONTACTS do
    local removed = table.remove(contacts)
    if removed then
      ChatManagerDB.chats[removed.name] = nil
      -- 如果被移除的联系人是当前联系人，则清除当前联系人
      if ChatManager.currentContact == removed.name then
        ChatManager.currentContact = nil
        ChatManagerDB.currentContact = nil
      end
    end
  end
end

-- 显示聊天记录函数
function ShowChatWith(contactName)
  if not contactName then
    ChatManager.currentContact = nil
    ChatManagerDB.currentContact = nil
    -- 清除聊天显示
    if chatFrame.messages then
      for _, msg in pairs(chatFrame.messages) do
        msg:Hide()
      end
    end
    UpdateContacts()
    return
  end

  -- 设置当前联系人
  ChatManager.currentContact = contactName
  ChatManagerDB.currentContact = contactName

  -- 清除旧的聊天内容
  if chatFrame.messages then
    for _, msg in pairs(chatFrame.messages) do
      msg:Hide()
    end
  else
    chatFrame.messages = {}
  end

  -- 获取聊天记录
  local chats = ChatManagerDB.chats[contactName] or {}
  local offsetY = -10
  for i, chat in ipairs(chats) do
    local msg = chatFrame.messages[i] or chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatFrame.messages[i] = msg
    msg:SetWidth(460)
    msg:SetJustifyH("LEFT")
    msg:SetPoint("TOPLEFT", 10, offsetY)

    -- 根据发送者设置颜色
    if chat.sender == ChatManager.playerName then
      msg:SetTextColor(unpack(playerMessageColor))
    else
      msg:SetTextColor(unpack(contactMessageColor))
    end

    msg:SetText(chat.sender .. " [" .. date("%H:%M:%S", chat.time) .. "]: " .. chat.message)
    msg:Show()

    offsetY = offsetY - msg:GetHeight() - 5
  end

  -- 更新滚动范围
  chatFrame:SetHeight(-offsetY)

  -- 重置未读计数
  local contacts = ChatManagerDB.contacts
  for _, contact in ipairs(contacts) do
    if contact.name == contactName then
      contact.unread = 0
      break
    end
  end

  -- 更新联系人列表UI
  UpdateContacts()
end

-- 更新联系人列表函数
function UpdateContacts()
  -- 清除旧的联系人按钮
  if contactsFrame.buttons then
    for _, button in pairs(contactsFrame.buttons) do
      button:Hide()
    end
  else
    contactsFrame.buttons = {}
  end

  -- 获取联系人并排序（按最近沟通时间降序）
  local contacts = ChatManagerDB.contacts
  table.sort(contacts, function(a, b)
    return a.lastContact > b.lastContact
  end)

  -- 创建新的联系人按钮，只显示前十个联系人
  for i, contact in ipairs(contacts) do
    if i > 10 then
      break
    end
    local button = contactsFrame.buttons[i] or
        CreateFrame("Button", nil, contactsFrame, "UIPanelButtonTemplate, BackdropTemplate")
    contactsFrame.buttons[i] = button
    button:SetSize(200, 30)
    button:SetPoint("TOPLEFT", 10, -5 - 35 * (i - 1))
    button:SetText(contact.name .. (contact.unread > 0 and (" (" .. contact.unread .. ")") or ""))

    button:GetFontString():SetFontObject("GameFontNormal")

    -- 设置背景以便高亮显示
    if not button.backdropSet then
      button:SetBackdrop({
        bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
      })
      button:SetBackdropColor(unpack(defaultBackdropColor))
      button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
      button.backdropSet = true
    end

    -- 高亮显示当前联系人
    if contact.name == ChatManager.currentContact then
      button:SetBackdropColor(unpack(highlightColor))
    else
      button:SetBackdropColor(unpack(defaultBackdropColor))
    end

    -- 设置按钮点击事件
    button:SetScript("OnClick", function()
      -- 显示与该联系人的聊天记录
      ShowChatWith(contact.name)
    end)
    button:Show()
  end

  -- 更新滚动范围
  contactsFrame:SetHeight(math.min(#contacts, 10) * 35 + 10)
end

-- 记录聊天函数
function RecordChat(sender, receiver, message)
  -- 使用当前角色名替代“你”
  local contactName = sender == ChatManager.playerName and receiver or sender

  -- 更新联系人列表
  local contacts = ChatManagerDB.contacts
  local contact = nil
  for _, c in ipairs(contacts) do
    if c.name == contactName then
      contact = c
      break
    end
  end
  if not contact then
    contact = { name = contactName, lastContact = time(), unread = sender ~= ChatManager.playerName and 1 or 0 }
    table.insert(contacts, contact)
  else
    contact.lastContact = time()
    if sender ~= ChatManager.playerName then
      contact.unread = (contact.unread or 0) + 1
    end
  end

  -- 限制联系人数量
  LimitContacts()

  -- 记录聊天消息
  ChatManagerDB.chats[contactName] = ChatManagerDB.chats[contactName] or {}
  table.insert(ChatManagerDB.chats[contactName], {
    sender = sender,
    message = message,
    time = time()
  })

  -- 如果当前聊天对象是该联系人，则重置未读计数并更新聊天显示
  if contactName == ChatManager.currentContact and sender ~= ChatManager.playerName then
    contact.unread = 0
    ShowChatWith(contactName)
  elseif contactName == ChatManager.currentContact then
    ShowChatWith(contactName)
  else
    UpdateContacts()
  end
end

-- 自动回复函数
function CheckAutoReply(sender, message)
  for keyword, reply in pairs(autoReplies) do
    if string.find(message, keyword) then
      -- 如果 message 包含 1，且 message 长度大于 5，则不回复
      if keyword == "1" and string.len(message) > 5 then
        break
      end
      SendChatMessage(reply, "WHISPER", nil, sender)
      -- RecordChat(ChatManager.playerName, sender, reply)
      break
    end
  end
end

-- 创建预设回复按钮
local function CreatePresetReplyButtons()
  for i, preset in ipairs(replyPresets) do
    local replyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    replyButton:SetSize(80, 30)
    replyButton:SetPoint("BOTTOMRIGHT", -20 - ((i - 1) % 2) * 90, 60 + math.floor((i - 1) / 2) * 40)
    replyButton:SetText(preset.name)
    replyButton:SetScript("OnClick", function()
      local contactName = ChatManager.currentContact
      if contactName then
        SendChatMessage(preset.message, "WHISPER", nil, contactName)
        -- RecordChat(ChatManager.playerName, contactName, preset.message)
        ShowChatWith(contactName)
      else
        print("请选择一个联系人进行回复。")
      end
    end)
  end
end

-- 创建消息输入框和发送按钮
local function CreateMessageInput()
  -- 创建消息输入框，包含 BackdropTemplate
  local messageInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate, BackdropTemplate")
  messageInput:SetSize(600, 30)
  messageInput:SetPoint("BOTTOMLEFT", 20, 20)
  messageInput:SetAutoFocus(false)
  messageInput:SetMaxLetters(255)
  messageInput:SetTextInsets(10, 10, 5, 5)
  messageInput:SetBackdrop({
    bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  messageInput:SetBackdropColor(0, 0, 0, 0.7)
  messageInput:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  messageInput:SetFontObject("ChatFontNormal")

  -- 创建发送按钮
  local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  sendButton:SetSize(80, 30)
  sendButton:SetPoint("LEFT", messageInput, "RIGHT", 10, 0)
  sendButton:SetText("发送")
  sendButton:SetScript("OnClick", function()
    local message = messageInput:GetText()
    if message and message ~= "" then
      local contactName = ChatManager.currentContact
      if contactName then
        SendChatMessage(message, "WHISPER", nil, contactName)
        -- RecordChat(ChatManager.playerName, contactName, message)
        ShowChatWith(contactName)
        messageInput:SetText("")
      else
        print("请选择一个联系人发送消息。")
      end
    end
  end)

  -- 按下回车键发送消息
  messageInput:SetScript("OnEnterPressed", function()
    sendButton:Click()
  end)
end

-- 创建删除记录按钮
local function CreateDeleteButton()
  local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  deleteButton:SetSize(50, 30)
  deleteButton:SetPoint("BOTTOMRIGHT", -20, 20)
  deleteButton:SetText("删")
  deleteButton:SetScript("OnClick", function()
    if not ChatManager.currentContact then
      print("请选择一个联系人删除记录。")
      return
    end

    StaticPopupDialogs["CHATMANAGER_CONFIRM_DELETE"] = {
      text = "确定要删除此聊天记录吗？",
      button1 = "是",
      button2 = "否",
      OnAccept = function()
        local contactName = ChatManager.currentContact
        if contactName then
          ChatManagerDB.chats[contactName] = nil
          -- 从联系人列表中移除
          for i, c in ipairs(ChatManagerDB.contacts) do
            if c.name == contactName then
              table.remove(ChatManagerDB.contacts, i)
              break
            end
          end
          ShowChatWith(nil)
          UpdateContacts()
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
    }
    StaticPopup_Show("CHATMANAGER_CONFIRM_DELETE")
  end)
end

-- 初始化函数
local function Initialize()
  -- 将窗口添加到 UISpecialFrames 以支持ESC 关闭
  table.insert(UISpecialFrames, "ChatManagerFrame")

  -- 创建消息输入框和发送按钮
  CreateMessageInput()

  -- 创建预设回复按钮
  CreatePresetReplyButtons()

  -- 创建删除记录按钮
  -- 如果需要启用删除按钮，请取消以下行的注释
  -- CreateDeleteButton()

  -- 限制联系人数量
  LimitContacts()

  -- 显示当前联系人聊天记录（如果有）
  if ChatManager.currentContact then
    ShowChatWith(ChatManager.currentContact)
  else
    UpdateContacts()
  end

  -- 创建关闭按钮以支持ESC键关闭窗口
  -- 这部分已通过 UISpecialFrames 实现，因此无需额外处理

  C_Timer.After(3, function()
    --
    -- 默认显示窗口
    frame:Show()
  end)
end

-- 处理聊天事件
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName == "ChatManager" then
      Initialize()
    end
  elseif event == "CHAT_MSG_WHISPER" then
    local message, sender = ...
    RecordChat(sender, ChatManager.playerName, message)
    CheckAutoReply(sender, message)
    PlaySound(SOUNDKIT.TELL_MESSAGE)
  elseif event == "CHAT_MSG_WHISPER_INFORM" then
    local message, receiver = ...
    RecordChat(ChatManager.playerName, receiver, message)
  end
end)

-- 显示/隐藏插件窗口
SLASH_CM1 = "/cm"
SlashCmdList["CM"] = function()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
