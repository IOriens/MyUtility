
local function ShowThirdAttribute(row, itemLink)

  -- 获取物品的属性
  local stats =  C_Item.GetItemStats(itemLink)
  if not stats then return end

  local attributes = {}

  -- 指定要显示的属性
  local desiredStats = {
    ["ITEM_MOD_CR_SPEED_SHORT"] = true,     -- 加速
    -- ["ITEM_MOD_CR_AVOIDANCE_SHORT"] = true,  -- 闪避
    -- ["ITEM_MOD_CR_LIFESTEAL_SHORT"] = true,  -- 吸血
  }

  DevTools_Dump(stats)

  -- 遍历获取指定的属性
  for stat, value in pairs(stats) do
    if value > 0 and desiredStats[stat] then
      table.insert(attributes, _G[stat] .. ": " .. value)
    end
  end

  -- 显示属性（仅显示前三个）
  if #attributes > 0 then
    local thirdAttrText = table.concat(attributes, ", ")
    row.ThirdAttribute:SetText(thirdAttrText)
    row.ThirdAttribute:Show()
  else
    row.ThirdAttribute:Hide()
  end
end

local function OnEvent(self, event)
  print(event)
  if event == "AUCTION_HOUSE_SHOW" then
    hooksecurefunc(AuctionHouseFrame.ItemBuyFrame.ItemList.ScrollBox, "Update", function(self)
      for _, row in ipairs(self:GetFrames()) do
        if row.rowData then
          local itemLink = row.rowData.itemLink
          -- 如果第三属性标签不存在，则创建
          if not row.ThirdAttribute then
            row.ThirdAttribute = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.ThirdAttribute:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 4)
            row.ThirdAttribute:SetTextColor(0.5, 0.8, 0.5)
          end


          -- 显示第三属性
          ShowThirdAttribute(row, itemLink)
        end
      end
    end)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:SetScript("OnEvent", OnEvent)
