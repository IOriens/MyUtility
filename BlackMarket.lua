function GetLeilong()
  C_BlackMarket.RequestItems()
  N = C_BlackMarket.GetNumItems()


  if not N then
    -- print("无法获取商品数量 " .. currentTime)
    return
  end

  for i = 1, N do
    M = select(1, C_BlackMarket.GetItemInfoByIndex(i))
    D = select(16, C_BlackMarket.GetItemInfoByIndex(i))
    if M == "雄壮商队雷龙的缰绳" then
      C_BlackMarket.ItemPlaceBid(D, 99999990000)
    end
  end

  if N > 0 then
    local currentTime = date("%H:%M:%S") -- 获取当前的时:分:秒
    -- print("Current time:", currentTime)
    print("-------- " .. currentTime .. " --------")
  end

  for i = 1, N do
    M = select(1, C_BlackMarket.GetItemInfoByIndex(i))
    D = select(16, C_BlackMarket.GetItemInfoByIndex(i))
    print(M)
  end
end

local function printCurrentTime()
  local currentTime = date("%H:%M:%S") -- 获取当前的时:分:秒
  local serverTime = date("%H:%M:%S", GetServerTime())


  print("Local:", currentTime, "  Server:",serverTime)
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    -- GetLeilong()
    -- if UnitName("player") == "星耀之辉" then
    --   -- GetLeilong()
    --   -- 每秒输出一次当前时间
    --   C_Timer.NewTicker(1, printCurrentTime)
    -- end
  end
end)



--/run C_BlackMarket.RequestItems()N=C_BlackMarket.GetNumItems()for i=1,N do M=select(1, C_BlackMarket.GetItemInfoByIndex(i))D=select(16, C_BlackMarket.GetItemInfoByIndex(i))if M=="雄壮商队雷龙的缰绳" then C_BlackMarket.ItemPlaceBid(D, 99999990000)end end
