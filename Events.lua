-- Events.lua

ChatManager = ChatManager or {}

-- 记录聊天函数
function ChatManager.RecordChat(sender, receiver, message)
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
        contact = {name = contactName, lastContact = time(), unread = sender ~= ChatManager.playerName and 1 or 0}
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
        ChatManager.ShowChatWith(contactName)
    else
        ChatManager.UpdateContacts()
    end
end

-- 自动回复函数
function ChatManager.CheckAutoReply(sender, message)
    for keyword, reply in pairs(ChatManagerDB.autoReplies) do
        if string.find(message, keyword) then
            SendChatMessage(reply, "WHISPER", nil, sender)
            ChatManager.RecordChat(ChatManager.playerName, sender, reply)
            break
        end
    end
end

-- 初始化函数
function ChatManager.Initialize()
    -- 创建UI元素
    ChatManager.CreateMessageInput()
    ChatManager.CreatePresetReplyButtons()
    ChatManager.CreateDeleteButton()

    -- 显示当前联系人聊天记录（如果有）
    if ChatManager.currentContact then
        ChatManager.ShowChatWith(ChatManager.currentContact)
    else
        ChatManager.UpdateContacts()
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
            ChatManager.Initialize()
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        ChatManager.RecordChat(sender, ChatManager.playerName, message)
        ChatManager.CheckAutoReply(sender, message)
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message, receiver = ...
        ChatManager.RecordChat(ChatManager.playerName, receiver, message)
    end
end)
