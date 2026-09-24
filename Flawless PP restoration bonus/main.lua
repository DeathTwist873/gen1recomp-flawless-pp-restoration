-- ============================================================================
-- Mod: Flawless PP Restorer
-- ============================================================================

local turnStartHP = 0
local lastSelectedMoveSlot = 1

return function(mod)

  mod.log:info("[Flawless PPRestorer] MOD LOADED BY ENGINE!")

  -- Capture initial HP when a battle starts
  mod.hooks:wrap("battle.start", function(nextFn, battle, ...)
    local result = nextFn(battle, ...)
    local playerMon = battle and (battle.player_active or (battle.player and battle.player.mon) or battle.player)
    if playerMon then
      turnStartHP = playerMon.hp or playerMon.current_hp or 0
      mod.log:info("[Flawless PPRestorer] Battle Started. Initial HP set to: " .. tostring(turnStartHP))
    end
    return result
  end)

  -- Intercept KO/exp award
  mod.hooks:wrap("battle.exp_award", function(nextFn, ctx)
    local battle = ctx and ctx.battle
    local playerMon = battle and (battle.player_active or (battle.player and battle.player.mon) or battle.player)
    
    if playerMon then
      local currentHP = playerMon.hp or playerMon.current_hp or 0
      
      -- Fallback: If turnStartHP was never caught (0), initialize it to currentHP
      if turnStartHP == 0 then
        turnStartHP = currentHP
      end

      mod.log:info("[Flawless PPRestorer] Evaluating KO: Start HP = " .. tostring(turnStartHP) .. " | Current HP = " .. tostring(currentHP))

      -- Flawless condition: Current HP must equal or exceed turnStartHP
      if currentHP >= turnStartHP then
        local moves = playerMon.moves
        if moves and moves[lastSelectedMoveSlot] then
          local move = moves[lastSelectedMoveSlot]
          local moveName = move.name or ("Slot " .. tostring(lastSelectedMoveSlot))
          local currentPP = move.pp or 0
          local maxPP = move.max_pp or move.maxPP or 35
          
          local newPP = math.min(currentPP + 2, maxPP)
          
          if newPP > currentPP then
            move.pp = newPP
            
            mod.log:info("--------------------------------------------------")
            mod.log:info("[Flawless PPRestorer] FLAWLESS VICTORY DETECTED!")
            mod.log:info("[Flawless PPRestorer] Target Move: " .. tostring(moveName))
            mod.log:info("[Flawless PPRestorer] PP Restored: " .. tostring(currentPP) .. " -> " .. tostring(newPP) .. " / " .. tostring(maxPP))
            mod.log:info("--------------------------------------------------")
            
            if battle.sayNext then
              battle:sayNext("FLAWLESS VICTORY!\n+2 PP restored!")
            elseif battle.emit then
              battle:emit({ kind = "message", text = "FLAWLESS VICTORY!\n+2 PP restored!" })
            end
          else
            mod.log:info("[Flawless PPRestorer] KO landed! " .. tostring(moveName) .. " is already at max PP (" .. tostring(maxPP) .. ").")
          end
        end
      else
        mod.log:info("[Flawless PPRestorer] KO landed, but damage was taken. (Start HP: " .. tostring(turnStartHP) .. " | Current HP: " .. tostring(currentHP) .. ")")
      end

      -- Reset turnStartHP for the next enemy mon in multi-trainer fights
      turnStartHP = currentHP
    end

    return nextFn(ctx)
  end, 95)

  mod.events:on("game.ready", function(ev)
    mod.log:info("[Flawless PPRestorer] Engine ready.")
  end)

end