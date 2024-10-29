function CancelAllTracked()
  -- 取消任务追踪
  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
      local questInfo = C_QuestLog.GetInfo(i)
      if questInfo and questInfo.questID then
          C_QuestLog.RemoveQuestWatch(questInfo.questID)
      end
  end

  -- 取消常规配方的追踪
  local trackedRecipes = C_TradeSkillUI.GetRecipesTracked(false)
  for _, recipeID in ipairs(trackedRecipes) do
      C_TradeSkillUI.SetRecipeTracked(recipeID, false, false)
  end
  
  -- 取消重铸配方的追踪
  local trackedRecraftRecipes = C_TradeSkillUI.GetRecipesTracked(true)
  for _, recipeID in ipairs(trackedRecraftRecipes) do
      C_TradeSkillUI.SetRecipeTracked(recipeID, false, true)
  end
end

-- 调用函数取消所有任务和专业配方的追踪
-- CancelAllTracked()
