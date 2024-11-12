
local function ShowThirdAttribute(row, itemID)
  if not itemID then return end

  -- 异步获取物品信息
  local item = Item:CreateFromItemID(itemID)
  item:ContinueOnItemLoad(function()
      local itemLink = item:GetItemLink()
      if not itemLink then return end

      -- 获取物品的属性
      local stats =  C_Item.GetItemStats(itemLink)
      if not stats then return end

      local attributes = {}

      -- 遍历获取第三属性
      for stat, value in pairs(stats) do
          if value > 0 then
              print(stat, value)
              table.insert(attributes, _G[stat] .. ": " .. value)
          end
      end

      -- 显示第三属性（仅显示前三个属性）
      if #attributes > 0 then
          local thirdAttrText = table.concat(attributes, ", ", 1, 3)
          row.ThirdAttribute:SetText(thirdAttrText)
          row.ThirdAttribute:Show()
      else
          row.ThirdAttribute:Hide()
      end
  end)
end

local function OnEvent(self, event)
  print(event)
  if event == "AUCTION_HOUSE_SHOW" then
    hooksecurefunc(AuctionHouseFrame.ItemBuyFrame.ItemList.ScrollBox, "Update", function(self)
      for _, row in ipairs(self:GetFrames()) do
        if row.rowData then
          local itemID = row.rowData.itemKey.itemID
          -- 如果第三属性标签不存在，则创建
          if not row.ThirdAttribute then
            row.ThirdAttribute = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.ThirdAttribute:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 200, 4)
            row.ThirdAttribute:SetTextColor(0.5, 0.8, 0.5)
          end


          -- 显示第三属性
          ShowThirdAttribute(row, itemID)
        end
      end
    end)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:SetScript("OnEvent", OnEvent)
