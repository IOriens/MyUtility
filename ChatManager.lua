-- ChatManager.lua

-- 创建主插件表
ChatManager = {}
-- 获取当前玩家的名称
ChatManager.playerName = UnitName("player")

-- 初始化SavedVariables数据库
ChatManagerDB = ChatManagerDB or {
  contacts = {},
  chats = {},
  presets = {

  },
  autoReplies = {

  },
  currentContact = nil
}






-- 设置当前联系人为SavedVariables中的值
ChatManager.currentContact = ChatManagerDB.currentContact

-- 创建UI框架
local frame = CreateFrame("Frame", "ChatManagerFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("私聊管理窗口")
frame:Hide()

-- 创建左侧联系人列表
local contactsScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
contactsScrollFrame:SetSize(200, 350)
contactsScrollFrame:SetPoint("TOPLEFT", 10, -30)

local contactsFrame = CreateFrame("Frame", nil, contactsScrollFrame)
contactsFrame:SetSize(200, 350)
contactsScrollFrame:SetScrollChild(contactsFrame)

-- 创建右侧聊天记录
local chatScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
chatScrollFrame:SetSize(370, 300)
chatScrollFrame:SetPoint("TOPRIGHT", -30, -30)

local chatFrame = CreateFrame("Frame", nil, chatScrollFrame)
chatFrame:SetSize(370, 300)
chatScrollFrame:SetScrollChild(chatFrame)

-- 当前选中的联系人高亮颜色
local highlightColor = { 0, 1, 0, 0.5 }     -- 绿色半透明
local defaultBackdropColor = { 0, 0, 0, 0 } -- 无背景

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
    msg:SetPoint("TOPLEFT", 0, -20 * (i - 1))
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
    button:SetSize(180, 30)
    button:SetPoint("TOPLEFT", 0, -35 * (i - 1))
    button:SetText(contact.name .. (contact.unread > 0 and (" (" .. contact.unread .. ")") or ""))

    -- 设置背景以便高亮显示
    if not button.backdrop then
      button:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
      button:SetBackdropColor(unpack(defaultBackdropColor))
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
  for keyword, reply in pairs(ChatManagerDB.autoReplies) do
    print("keyword: " .. keyword)
    print("reply: " .. reply)
    if string.find(message, keyword) then
      SendChatMessage(reply, "WHISPER", nil, sender)
      RecordChat(ChatManager.playerName, sender, reply)
      break
    end
  end
end

-- 创建预设回复按钮
local function CreatePresetReplyButtons()
  for i, preset in ipairs(ChatManagerDB.presets) do
    local replyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    replyButton:SetSize(100, 25)
    replyButton:SetPoint("BOTTOMRIGHT", -10, 10 + (i - 1) * 35)
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
  -- 创建消息输入框
  local messageInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  messageInput:SetSize(300, 25)
  messageInput:SetPoint("BOTTOMLEFT", 10, 10)
  messageInput:SetAutoFocus(false)
  messageInput:SetMaxLetters(255)

  -- 创建发送按钮
  local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  sendButton:SetSize(80, 25)
  sendButton:SetPoint("BOTTOMLEFT", messageInput, "BOTTOMRIGHT", 10, 0)
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
end

-- 创建删除记录按钮
local function CreateDeleteButton()
  local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  deleteButton:SetSize(100, 25)
  deleteButton:SetPoint("BOTTOMLEFT", 400, 10)
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

  ChatManagerDB.presets = {
    { name = "问候", message = "你好！" },
    { name = "在吗", message = "你现在有空吗？" },
    { name = "稍后联系", message = "稍后再联系你。" }
  }
  
  ChatManagerDB.autoReplies = {
    ["挺好"] = "在的",
    ["帮忙"] = "我现在不方便，稍后联系你。",
    ["组队"] = "好的，我马上来。"
  }

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
    print("1")
    local message, sender = ...
    print("2")
    RecordChat(sender, ChatManager.playerName, message)
    print("3")
    CheckAutoReply(sender, message)
    print("4")
  elseif event == "CHAT_MSG_WHISPER_INFORM" then
    local message, receiver = ...
    RecordChat(ChatManager.playerName, receiver, message)
  end
end)

-- 显示/隐藏插件窗口
SLASH_CHATMANAGER1 = "/chatmanager"
SlashCmdList["CHATMANAGER"] = function()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
