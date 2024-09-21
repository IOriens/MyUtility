-- 创建切换显示按钮
local toggleButton = CreateFrame("Button", "ChatManagerToggleButton", UIParent, "UIPanelButtonTemplate")
toggleButton:SetSize(120, 30)
toggleButton:SetText("切换私聊管理")
toggleButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20) -- 调整位置根据需要

-- 设置按钮的外观（可选）
toggleButton:SetNormalFontObject("GameFontNormal")
toggleButton:SetHighlightFontObject("GameFontHighlight")

-- 使按钮可拖动
toggleButton:SetMovable(true)
toggleButton:EnableMouse(true)
toggleButton:RegisterForDrag("LeftButton")
toggleButton:SetScript("OnDragStart", function(self)
  self:StartMoving()
end)
toggleButton:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  -- 保存按钮位置到数据库
  local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
  ChatManagerDB.toggleButtonPosition = { point, relativePoint, xOfs, yOfs }
end)

-- 初始化按钮位置
if ChatManagerDB.toggleButtonPosition then
  toggleButton:ClearAllPoints()
  toggleButton:SetPoint(unpack(ChatManagerDB.toggleButtonPosition))
else
  toggleButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
end

-- 设置按钮点击事件
toggleButton:SetScript("OnClick", function()
  if ChatManager.frame:IsShown() then
    ChatManager.frame:Hide()
  else
    ChatManager.frame:Show()
  end
end)
