function PrintTalent()
  local a = C_ClassTalents
  for i, id in ipairs(a.GetConfigIDsBySpecID()) do
    local c = C_Traits.GetConfigInfo(id)
    if c then print(c.name .. " " .. "/script C_ClassTalents.LoadConfig(" .. id .. ", true)") end
  end
end

local activeConfigID = null


function SwitchToOtherTalent()
  local currentSpecIndex = GetSpecialization() -- 返回当前专精的索引 (1, 2, 3, 4)
  local currentSpecID = GetSpecializationInfo(currentSpecIndex)
  if not activeConfigID then
    activeConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(currentSpecID)
  end

  local a = C_ClassTalents



  for i, id in ipairs(a.GetConfigIDsBySpecID()) do
    local c = C_Traits.GetConfigInfo(id)

    if c then
      print("遍历到：" .. id)
      print("当前ID：" .. activeConfigID)
      local isCurrent = tostring(activeConfigID) == tostring(id)

      if not isCurrent then
        C_ClassTalents.LoadConfig(id, true)
        activeConfigID = id
        -- C_ClassTalents.UpdateLastSelectedSavedConfigID(currentSpecID, id)
        print("切换到：" .. c.name)
        return
      end
    end
  end
end

-- /run PrintTalent()
-- /run SwitchToOtherTalent()
