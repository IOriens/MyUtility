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
-- "制作材料点这个查询 |cffffd000|Htrade:Player-707-06A25B60:45357:773|h[铭文]|h|r |cffffd000|Htrade:Player-707-068F7148:3908:197|h[裁缝]|h|r，做法杖要3星材料2星公函2星美化，做论述用最便宜的材料"
-- （想放2星公函和美化需加钱至4k）
"制作材料点这个查询 |cffffd000|Htrade:Player-707-06A25B60:45357:773|h[铭文]|h|r ，做法杖要3星材料3星公函3星美化方便再造，做论述用最便宜的材料"


local treiesString =
"论述一星材料即可，全专业的都能免费做。注意：每个专业一周只能吃一个，可以多做几个屯着~。制作材料点这个查询 |cffffd000|Htrade:Player-707-06A25B60:45357:773|h[铭文]|h|r"
-- 可跨服制作，
local fazhangString = "双手法杖(智力/敏捷)免费包五星636、619、606、590，再造也是免费，自己买3星材料3星公函3星美化，做好纹章，法杖指定5星下个人单给" ..
    meOrHim("雪中曲")


-- local gonghuiString =
-- "暂停接跨服单～跨服订单需要加我的公会|cffffd200|HclubFinder:ClubFinder-1-203805-707-59782982|h[公会: 夜间漫游]|h|r，搜不到可以加我战网“夜间漫游#5845”，我拉你进公会，申请通过后要按J键查看左上角邀请函进会"
local gonghuiString = "暂时不跨服单哈～"

local byPassStrings = {
  "好的",
  "ok",
  "OK",
  "感谢",
  "谢谢",
  "3q",
  "3Q",
  "谢谢你",
  "多谢",
  "DBM",
  "好吧"
}

local itsMeString = "下单给我就行（雪中曲）"

local tutString = "自备材料工商联盟下单就行，免费做，回复“材料”查看所需材料，具体怎么操作，用什么美化，需要自己去搜，我这边消息太多回不过来～"

local replyPresets = {

  -- 常用
  { keyword = "马上发", reply = "好的" },
  { keyword = "好的", reply = "好的" },
  { keyword = "对的", reply = "对的" },
  { keyword = "是的", reply = "是的" },
  { keyword = "可以", reply = "可以" },
  { keyword = "在的", reply = "在的，下单就行～" },
  { keyword = "不会", reply = "不会做哈～" },
  { keyword = "都行", reply = "都行" },
  { keyword = "做啥", reply = "做啥来着~" },
  -- { keyword = "done", reply = "做好了，请在邮箱查收~ （如有再造需求可以加我战网“夜间漫游#5845”）" },
  { keyword = "不客气", reply = "~" },
  { keyword = "发我", reply = itsMeString },
  -- 介绍
  { keyword = "三星", reply = "要三星材料三星公函三星美化哈～" },
  { keyword = "材料", reply = materialString },
  { keyword = "联盟下单", reply = "需要您自己去工匠联盟下个人订单哈～" },
  { keyword = "不包材料", reply = "不包材料哈，需要自己去拍卖行买～" },

  -- { keyword = "锻造下单", reply = "锻造下单给圣焰之辉，下单后给我说我去换号~" },
  -- { keyword = "制皮下单", reply = "制皮下单给Reducer，下单后给我说我去换号~" },
  -- { keyword = "法杖布甲", reply = "双手法杖5k包619，8k包636，免费做606和590，自己买3星材料2星公函2星美化，做好纹章，法杖和布甲指定5星下单给" .. meOrHim("雪中曲") },
  -- （想放2星公函和美化需加钱至4k）
  { keyword = "法杖", reply = fazhangString },
  { keyword = "论述", reply = treiesString },
  { keyword = "教学", reply = tutString },
  { keyword = "免费", reply = "免费做，直接下单给我就行，人在秒做～" },
  { keyword = "公会", reply = gonghuiString },
  { keyword = "公开订单", reply = "每人每天只能接4个公开订单。。" },
}

local canMakeString = "只会做智力和敏捷双手法杖、PVP法杖、PVP长柄、炼金棒、各专业论述，其它都做不了哈～"
local fiveStarString = "法杖全等级带美化免费稳5，接再造，也是免费，三星材料三星公函三星美化直接下单就行，人在秒做～"

-- 雪中曲
local autoReplies = {
  { keyword = "火炬", reply = "副手不会做哈～" },
  { keyword = "副手", reply = "副手不会做哈～" },
  { keyword = "面杖", reply = "专业工具不接哈，不能稳5～" },
  { keyword = "羽毛", reply = "专业工具不接哈，不能稳5～" },
  { keyword = "饰品", reply = "不会做哈～" },
  { keyword = "布甲", reply = "不会做哈～" },
  { keyword = "徽记", reply = "不会做哈～" },
  { keyword = "剑", reply = canMakeString },
  { keyword = "斧", reply = canMakeString },
  { keyword = "盾", reply = canMakeString },
  { keyword = "长", reply = canMakeString },
  { keyword = "枪", reply = canMakeString },
  { keyword = "布甲", reply = canMakeString },
  -- 按优先级顺序排列
  { keyword = "小号", reply = gonghuiString },
  { keyword = "搜索", reply = gonghuiString },
  { keyword = "搜不到", reply = gonghuiString },
  { keyword = "跨服", reply = gonghuiString },
  { keyword = "公会", reply = gonghuiString },
  { keyword = "发布了", reply = "好的" },
  { keyword = "发给你了", reply = "好的" },
  { keyword = "发了", reply = "好的" },
  { keyword = "发你了", reply = "好的" },
  { keyword = "已发", reply = "好的" },
  { keyword = "下单了", reply = "好的" },
  { keyword = "发过", reply = "好的" },
  { keyword = "下了", reply = "好的" },

  { keyword = "再造", reply = fiveStarString },

  { keyword = "稳", reply = fiveStarString },
  { keyword = "包5", reply = fiveStarString },
  { keyword = "保5", reply = fiveStarString },
  { keyword = "包五", reply = fiveStarString },
  { keyword = "保五", reply = fiveStarString },
  { keyword = "5星", reply = fiveStarString },
  { keyword = "五星", reply = fiveStarString },


  { keyword = "包材料", reply = "不包材料哈，需要自己去拍卖行买～" },
  { keyword = "全包", reply = "不包材料哈，需要自己去拍卖行买～" },
  { keyword = "价格", reply = "免费做，直接下单给我就行～" },
  { keyword = "佣金", reply = "免费做，直接下单给我就行～" },
  { keyword = "钱", reply = "免费做，直接下单给我就行～" },
  { keyword = "费", reply = "免费做，直接下单给我就行～" },
  { keyword = "nga", reply = "在的，下单就行～" },
  { keyword = "NGA", reply = "在的，下单就行～" },
  { keyword = "在", reply = "在的，下单就行～" },
  { keyword = "怎么做", reply = tutString },
  { keyword = "啥是", reply = tutString },
  { keyword = "是什么", reply = tutString },

  { keyword = "免费", reply = "对的，直接下单就行～" },
  { keyword = "副手", reply = "不会做哈～" },
  { keyword = "发谁", reply = "直接给这个号（雪中曲）下单就行" },
  { keyword = "id", reply = "直接给这个号下单就行" },
  { keyword = "发给谁", reply = "直接给这个号（雪中曲）下单就行" },
  { keyword = "名字", reply = "直接给这个号（雪中曲）下单就行" },
  { keyword = "这个号", reply = "直接给这个号（雪中曲）下单就行" },
  { keyword = "这号", reply = "直接给这个号（雪中曲）下单就行" },
  { keyword = "三星", reply = "要三星材料三星公函三星美化哈～" },
  { keyword = "3星", reply = "要三星材料三星公函三星美化哈～" },
  { keyword = "619", reply = fazhangString },
  { keyword = "公函", reply = fazhangString },
  { keyword = "美化", reply = fazhangString },
  { keyword = "法杖", reply = fazhangString },
  { keyword = "几个", reply = treiesString },
  { keyword = "论述", reply = treiesString },
  { keyword = "采矿", reply = treiesString },
  { keyword = "炼金", reply = treiesString },
  { keyword = "工程", reply = treiesString },
  { keyword = "裁缝", reply = treiesString },
  { keyword = "珠宝", reply = treiesString },
  { keyword = "附魔", reply = treiesString },
  { keyword = "制皮", reply = treiesString },
  { keyword = "剥皮", reply = treiesString },
  { keyword = "铭文", reply = treiesString },
  { keyword = "挖草", reply = treiesString },
  { keyword = "锻造", reply = treiesString },
  { keyword = "无限", reply = treiesString },
  { keyword = "一周", reply = treiesString },
  { keyword = "每周", reply = treiesString },
  { keyword = "吃", reply = treiesString },
  { keyword = "材料", reply = materialString },

  { keyword = "会吗", reply = canMakeString },
  { keyword = "会么", reply = canMakeString },
  { keyword = "做吗", reply = canMakeString },
  { keyword = "能做", reply = canMakeString },
  { keyword = "会做", reply = canMakeString },
  { keyword = "会不", reply = canMakeString },
}

if UnitName("player") == "圣焰之辉" then
  canMakeString = "只会做智力单手斧、力量敏捷双手斧、力量敏捷长柄武器，其它都做不了哈～"
  autoReplies = {
    { keyword = "切斧", reply = "充能切斧还不会做哈～" },
    { keyword = "卡", reply = "不接卡bug单～" },
    { keyword = "剑", reply = "不会做剑哈～" },
    { keyword = "锤", reply = "不会做锤哈～" },
    { keyword = "拳套", reply = "不会做拳套哈～" },
    { keyword = "战刃", reply = "不会做战刃哈～" },
    { keyword = "匕首", reply = "不会做匕首哈～" },
    { keyword = "发布了", reply = "好的" },
    { keyword = "发给你了", reply = "好的" },
    { keyword = "发了", reply = "好的" },
    { keyword = "发你了", reply = "好的" },
    { keyword = "已发", reply = "好的" },
    { keyword = "发过", reply = "好的" },
    { keyword = "下了", reply = "好的" },
    { keyword = "免费", reply = "对的，直接下单就行～" },
    { keyword = "副手", reply = "不会做哈～" },
    { keyword = "发谁", reply = "直接给这个号下单就行" },
    { keyword = "发给谁", reply = "直接给这个号下单就行" },
    { keyword = "名字", reply = "直接给这个号下单就行" },
    { keyword = "这个号", reply = "直接给这个号下单就行" },
    { keyword = "这号", reply = "直接给这个号下单就行" },
    { keyword = "id", reply = "直接给这个号下单就行" },
    { keyword = "三星", reply = "要三星材料三星公函三星美化哈～" },
    { keyword = "3星", reply = "要三星材料三星公函三星美化哈～" },
    { keyword = "会吗", reply = canMakeString },
    { keyword = "会么", reply = canMakeString },
    { keyword = "做吗", reply = canMakeString },
    { keyword = "能做", reply = canMakeString },
    { keyword = "会做", reply = canMakeString },
    { keyword = "会不", reply = canMakeString },
  }
end

-- 设置当前联系人为SavedVariables中的值
ChatManager.currentContact = ChatManagerDB.currentContact

-- 创建UI框架，使用更美观的模板
local frame = CreateFrame("Frame", "ChatManagerFrame", UIParent, "UIPanelDialogTemplate, BackdropTemplate")
ChatManager.frame = frame

frame:SetSize(1000, 600)
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
chatBg:SetPoint("TOPRIGHT", -220, -50)
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
local MAX_CONTACTS = 4000

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
    if i > 1000 then
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
  if string.find(sender, UnitName("player")) then
    print("自己发的消息，不回复：" .. message)
    return
  end

  if string.find(message, "1") and string.len(message) < 4 then
    print("短消息直接回复在的：" .. message)
    SendChatMessage("在的，直接下单给我就行，人在秒做～", "WHISPER", nil, sender)
    return
  end
  for _, ar in ipairs(autoReplies) do
    if string.find(message, ar.keyword) then
      SendChatMessage(ar.reply, "WHISPER", nil, sender)
      return
    end
  end

  for _, ar in ipairs(byPassStrings) do
    if string.find(message, ar) then
      print("跳过自动回复：" .. message)
      return
    end
  end

  print("默认回复")

  if UnitName("player") == "雪中曲" then
    -- 确保只发送一次默认回复
    ChatManager.autoReplySent = ChatManager.autoReplySent or {}
    if not ChatManager.autoReplySent[sender] then
      SendChatMessage("直接给我下单就行，法杖、PVP长柄全等级稳5，可再造，可加美化，全免费，三星材料三星公函三星美化秒做，不对自动退单，消息太多不教学～", "WHISPER", nil, sender)
      ChatManager.autoReplySent[sender] = true
    else
      print("已发送默认回复，不再重复发送。")
    end
  end

  if UnitName("player") == "圣焰之辉" then
    -- 确保只发送一次默认回复
    ChatManager.autoReplySent = ChatManager.autoReplySent or {}
    if not ChatManager.autoReplySent[sender] then
      -- 双手斧
      SendChatMessage("直接给我下单就行，可再造，可加美化，免代工费，三星材料三星公函三星美化秒做，不对自动退单，消息太多不教学～", "WHISPER", nil, sender)
      ChatManager.autoReplySent[sender] = true
    else
      print("已发送默认回复，不再重复发送。")
    end
  end
end

-- 创建预设回复按钮
local function CreatePresetReplyButtons()
  for i, preset in ipairs(replyPresets) do
    local replyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    replyButton:SetSize(80, 30)
    replyButton:SetPoint("BOTTOMRIGHT", -20 - ((i - 1) % 2) * 90, 60 + math.floor((i - 1) / 2) * 40)
    replyButton:SetText(preset.keyword)
    replyButton:SetScript("OnClick", function()
      local contactName = ChatManager.currentContact
      if contactName then
        SendChatMessage(preset.reply, "WHISPER", nil, contactName)
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
    -- PlaySound(SOUNDKIT.TELL_MESSAGE)
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
