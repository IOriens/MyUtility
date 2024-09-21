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
  framePosition = nil -- 添加用于保存窗口位置的字段
}

local replyPresets = {
  { name = "好的", message = "好的" },
  { name = "论述", message = "一星材料即可，一周只能吃一个，可以多做几个屯着~" },
  { name = "done", message = "做好了~" },
  { name = "不客气", message = "~" }
}

local autoReplies = {
  ["1"] = "在的",
  ["帮忙"] = "我现在不方便，稍后联系你。",
  ["组队"] = "好的，我马上来。"
}

-- 设置当前联系人为SavedVariables中的值
ChatManager.currentContact = ChatManagerDB.currentContact

-- 创建UI框架
local frame = CreateFrame("Frame", "ChatManagerFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(750, 600) -- 增加窗口大小以适应新布局
frame:SetPoint("CENTER")
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("私聊管理窗口")

-- 使窗口可拖动
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

-- 恢复窗口位置
if ChatManagerDB.framePosition then
  frame:ClearAllPoints()
  frame:SetPoint(ChatManagerDB.framePosition[1], UIParent, ChatManagerDB.framePosition[2], ChatManagerDB.framePosition[3], ChatManagerDB.framePosition[4])
end

-- 创建左侧联系人列表
local contactsScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
contactsScrollFrame:SetSize(220, 450)
contactsScrollFrame:SetPoint("TOPLEFT", 20, -60)

local contactsFrame = CreateFrame("Frame", nil, contactsScrollFrame)
contactsFrame:SetSize(220, 450)
contactsScrollFrame:SetScrollChild(contactsFrame)

-- 创建右侧聊天记录
local chatScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
chatScrollFrame:SetSize(500, 400)
chatScrollFrame:SetPoint("TOPRIGHT", -20, -60)

local chatFrame = CreateFrame("Frame", nil, chatScrollFrame)
chatFrame:SetSize(500, 400)
chatScrollFrame:SetScrollChild(chatFrame)

-- 当前选中的联系人高亮颜色
local highlightColor = { 0.46, 0.71, 0.77, 0.8 }     -- 绿色半透明调整为指定颜色
local defaultBackdropColor = { 0, 0, 0, 0 } -- 无背景

-- 定义消息颜色
local playerMessageColor = {  0.5, 0.8, 0.5, 1  }    -- #76b5c5
local contactMessageColor = { 0.46, 0.71, 0.77, 1 } -- rgb(118,181,197)

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
  for i, chat in ipairs(chats) do
    local msg = chatFrame.messages[i] or chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatFrame.messages[i] = msg
    msg:SetWidth(480) -- 设置消息宽度以适应新布局
    msg:SetJustifyH("LEFT")
    msg:SetPoint("TOPLEFT", 10, -10 - (i - 1) * 22) -- 增加消息间距

    -- 根据发送者设置颜色
    if chat.sender == ChatManager.playerName then
      msg:SetTextColor(unpack(playerMessageColor))
    else
      msg:SetTextColor(unpack(contactMessageColor))
    end

    msg:SetText(chat.sender .. " [" .. date("%H:%M:%S", chat.time) .. "]: " .. chat.message)
    msg:Show()
  end

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

  -- 创建新的联系人按钮
  for i, contact in ipairs(contacts) do
    local button = contactsFrame.buttons[i] or
        CreateFrame("Button", nil, contactsFrame, "UIPanelButtonTemplate, BackdropTemplate")
    contactsFrame.buttons[i] = button
    button:SetSize(200, 25)
    button:SetPoint("TOPLEFT", 10, -5 - 30 * (i - 1))
    button:SetText(contact.name .. (contact.unread > 0 and (" (" .. contact.unread .. ")") or ""))

    -- 设置背景以便高亮显示
    if not button.backdropSet then
      button:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
      button:SetBackdropColor(unpack(defaultBackdropColor))
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
  else
    UpdateContacts()
  end
end

-- 自动回复函数
function CheckAutoReply(sender, message)
  for keyword, reply in pairs(autoReplies) do
    if string.find(message, keyword) then
      SendChatMessage(reply, "WHISPER", nil, sender)
      RecordChat(ChatManager.playerName, sender, reply)
      break
    end
  end
end

-- 创建预设回复按钮
local function CreatePresetReplyButtons()
  for i, preset in ipairs(replyPresets) do
    local replyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    replyButton:SetSize(120, 30)
    replyButton:SetPoint("BOTTOMRIGHT", -10, 80 + (i - 1) * 40) -- 调整位置以适应新布局
    replyButton:SetText(preset.name)
    replyButton:SetScript("OnClick", function()
      local contactName = ChatManager.currentContact
      if contactName then
        SendChatMessage(preset.message, "WHISPER", nil, contactName)
        RecordChat(ChatManager.playerName, contactName, preset.message)
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
  messageInput:SetSize(500, 30)
  messageInput:SetPoint("BOTTOMLEFT", 20, 20)
  messageInput:SetAutoFocus(false)
  messageInput:SetMaxLetters(255)
  messageInput:SetTextInsets(10, 10, 10, 10)
  messageInput:SetBackdrop({
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  messageInput:SetBackdropColor(0, 0, 0, 0.7) -- 增加透明度
  messageInput:SetFontObject("ChatFontNormal")

  -- 创建发送按钮
  local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  sendButton:SetSize(100, 30)
  sendButton:SetPoint("LEFT", messageInput, "RIGHT", 10, 0)
  sendButton:SetText("发送")
  sendButton:SetScript("OnClick", function()
    local message = messageInput:GetText()
    if message and message ~= "" then
      local contactName = ChatManager.currentContact
      if contactName then
        SendChatMessage(message, "WHISPER", nil, contactName)
        RecordChat(ChatManager.playerName, contactName, message)
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
  deleteButton:SetSize(140, 30)
  deleteButton:SetPoint("BOTTOMRIGHT", -20, 20)
  deleteButton:SetText("删除记录")
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
  -- 创建消息输入框和发送按钮
  CreateMessageInput()

  -- 创建预设回复按钮
  CreatePresetReplyButtons()

  -- 创建删除记录按钮
  CreateDeleteButton()

  -- 显示当前联系人聊天记录（如果有）
  if ChatManager.currentContact then
    ShowChatWith(ChatManager.currentContact)
  else
    UpdateContacts()
  end

  -- 默认显示窗口
  frame:Show()
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
