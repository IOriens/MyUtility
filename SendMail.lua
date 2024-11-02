-- /run SendMailWithMoney()
function SendMailWithMoney()
  if not MailFrame:IsVisible() then
    print("请打开邮箱")
    return
  end

  MailFrameTab_OnClick(nil, 2)
  SendMailSubjectEditBox:SetText("1");
  SendMailNameEditBox:SetText("夜间漫游");
  local money = GetMoney() / 10000 - 10000;
  -- 取整
  money = math.floor(money);
  SendMailMoneyGold:SetText(tostring(money));
end
