-- Data.lua

ChatManager = ChatManager or {}
ChatManager.playerName = UnitName("player")

ChatManagerDB = ChatManagerDB or {
    contacts = {},
    chats = {},
    presets = {
        ["问候"] = "你好！",
        ["在吗"] = "你现在有空吗？",
        ["稍后联系"] = "稍后再联系你。"
    },
    autoReplies = {
        -- ["帮忙"] = "我现在不方便，稍后联系你。",
        -- ["组队"] = "好的，我马上来。"
    },
    currentContact = nil
}
ChatManager.currentContact = ChatManagerDB.currentContact
