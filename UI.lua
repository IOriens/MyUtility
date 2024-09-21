-- UI.lua

ChatManager = ChatManager or {}

-- 创建UI框架
local frame = CreateFrame("Frame", "ChatManagerFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("私聊管理窗口")
frame:Hide()

ChatManager.frame = frame

-- 创建左侧联系人列表
local contactsScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
contactsScrollFrame:SetSize(200, 350)
contactsScrollFrame:SetPoint("TOPLEFT", 10, -30)

local contactsFrame = CreateFrame("Frame", nil, contactsScrollFrame)
contactsFrame:SetSize(200, 350)
contactsScrollFrame:SetScrollChild(contactsFrame)

ChatManager.contactsFrame = contactsFrame

-- 创建右侧聊天记录
local chatScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
chatScrollFrame:SetSize(370, 300)
chatScrollFrame:SetPoint("TOPRIGHT", -30, -30)

local chatFrame = CreateFrame("Frame", nil, chatScrollFrame)
chatFrame:SetSize(370, 300)
chatScrollFrame:SetScrollChild(chatFrame)

ChatManager.chatFrame = chatFrame

-- 当前选中的联系人高亮颜色
local highlightColor = {0, 1, 0, 0.5} -- 绿色半透明
local defaultBackdropColor = {0, 0, 0, 0} -- 无背景

-- 更新联系人列表函数
function ChatManager.UpdateContacts()
    -- 清除旧的联系人按钮
    if ChatManager.contactsFrame.buttons then
        for _, button in pairs(ChatManager.contactsFrame.buttons) do
            button:Hide()
        end
    else
        ChatManager.contactsFrame.buttons = {}
    end

    -- 获取联系人并排序（按最近沟通时间降序）
    local contacts = ChatManagerDB.contacts
    table.sort(contacts, function(a, b)
        return a.lastContact > b.lastContact
    end)

    -- 创建新的联系人按钮
    for i, contact in ipairs(contacts) do
        local button = ChatManager.contactsFrame.buttons[i]
        if not button then
            button = CreateFrame("Button", nil, ChatManager.contactsFrame, "UIPanelButtonTemplate")
            button:SetSize(180, 30)
            button:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            ChatManager.contactsFrame.buttons[i] = button
        end
        button:SetPoint("TOPLEFT", 0, -35 * (i - 1))
        button:SetText(contact.name .. (contact.unread > 0 and (" (" .. contact.unread .. ")") or ""))

        -- 高亮显示当前联系人
        if contact.name == ChatManager.currentContact then
            button:SetBackdropColor(unpack(highlightColor))
        else
            button:SetBackdropColor(unpack(defaultBackdropColor))
        end

        -- 设置按钮点击事件
        button:SetScript("OnClick", function()
            ChatManager.ShowChatWith(contact.name)
        end)
        button:Show()
    end
end

-- 显示聊天记录函数
function ChatManager.ShowChatWith(contactName)
    if not contactName then
        ChatManager.currentContact = nil
        ChatManagerDB.currentContact = nil
        -- 清除聊天显示
        if ChatManager.chatFrame.messages then
            for _, msg in pairs(ChatManager.chatFrame.messages) do
                msg:Hide()
            end
        end
        ChatManager.UpdateContacts()
        return
    end

    -- 设置当前联系人
    ChatManager.currentContact = contactName
    ChatManagerDB.currentContact = contactName

    -- 清除旧的聊天内容
    if ChatManager.chatFrame.messages then
        for _, msg in pairs(ChatManager.chatFrame.messages) do
            msg:Hide()
        end
    else
        ChatManager.chatFrame.messages = {}
    end

    -- 获取聊天记录
    local chats = ChatManagerDB.chats[contactName] or {}
    for i, chat in ipairs(chats) do
        local msg = ChatManager.chatFrame.messages[i]
        if not msg then
            msg = ChatManager.chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ChatManager.chatFrame.messages[i] = msg
        end
        msg:SetPoint("TOPLEFT", 0, -20 * (i - 1))
        msg:SetText(chat.sender .. " [" .. date("%H:%M:%S", chat.time) .. "]: " .. chat.message)
        msg:Show()
    end

    -- 重置未读计数
    for _, contact in ipairs(ChatManagerDB.contacts) do
        if contact.name == contactName then
            contact.unread = 0
            break
        end
    end

    -- 更新联系人列表UI
    ChatManager.UpdateContacts()
end

-- 创建预设回复按钮
function ChatManager.CreatePresetReplyButtons()
    for name, message in pairs(ChatManagerDB.presets) do
        local replyButton = CreateFrame("Button", nil, ChatManager.frame, "UIPanelButtonTemplate")
        replyButton:SetSize(100, 25)
        replyButton:SetPoint("BOTTOMRIGHT", -10, 10 + (#ChatManagerDB.presets - i) * 35)
        replyButton:SetText(name)
        replyButton:SetScript("OnClick", function()
            local contactName = ChatManager.currentContact
            if contactName then
                SendChatMessage(message, "WHISPER", nil, contactName)
                ChatManager.RecordChat(ChatManager.playerName, contactName, message)
                ChatManager.ShowChatWith(contactName)
            else
                print("请选择一个联系人进行回复。")
            end
        end)
    end
end

-- 创建消息输入框和发送按钮
function ChatManager.CreateMessageInput()
    -- 创建消息输入框
    local messageInput = CreateFrame("EditBox", nil, ChatManager.frame, "InputBoxTemplate")
    messageInput:SetSize(300, 25)
    messageInput:SetPoint("BOTTOMLEFT", 10, 10)
    messageInput:SetAutoFocus(false)
    messageInput:SetMaxLetters(255)
    messageInput:SetTextInsets(5, 5, 5, 5)

    ChatManager.messageInput = messageInput

    -- 创建发送按钮
    local sendButton = CreateFrame("Button", nil, ChatManager.frame, "UIPanelButtonTemplate")
    sendButton:SetSize(80, 25)
    sendButton:SetPoint("BOTTOMLEFT", messageInput, "BOTTOMRIGHT", 10, 0)
    sendButton:SetText("发送")
    sendButton:SetScript("OnClick", function()
        local message = messageInput:GetText()
        if message and message ~= "" then
            local contactName = ChatManager.currentContact
            if contactName then
                SendChatMessage(message, "WHISPER", nil, contactName)
                ChatManager.RecordChat(ChatManager.playerName, contactName, message)
                ChatManager.ShowChatWith(contactName)
                messageInput:SetText("")
            else
                print("请选择一个联系人发送消息。")
            end
        end
    end)
end

-- 创建删除记录按钮
function ChatManager.CreateDeleteButton()
    local deleteButton = CreateFrame("Button", nil, ChatManager.frame, "UIPanelButtonTemplate")
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
                    ChatManager.ShowChatWith(nil)
                    ChatManager.UpdateContacts()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("CHATMANAGER_CONFIRM_DELETE")
    end)
end
