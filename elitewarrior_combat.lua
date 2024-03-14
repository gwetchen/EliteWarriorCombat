if UnitClass("player") == "Warrior" then
    local lastCheckTime = 0
    local checkInterval = 0.1 -- Check interval in seconds (how often to check for sunder armor)
    EliteWarrior.BSA = CreateFrame("Frame", nil, UIParent);
    local BSA_Texture = "Interface\\Icons\\Ability_Warrior_BattleShout";
    local sunderArmor_Texture = "Interface\\Icons\\Ability_Warrior_Sunder";

    local hasBS = false;
    local inCombat = false;
    local foundSunder = false;
    local sunderStackCount = 0;

    local battleShoutIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    battleShoutIcon:SetWidth(60)
    battleShoutIcon:SetHeight(60)
    battleShoutIcon:SetTexture(BSA_Texture)

    local sunderArmorIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    sunderArmorIcon:SetWidth(60)
    sunderArmorIcon:SetHeight(60)
    sunderArmorIcon:SetTexture(sunderArmor_Texture)

    local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
    local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

    local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
    local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

    local sunderStackCountText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    sunderStackCountText:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")

    local function BSA_Show()
        if (inCombat and not hasBS) then
            battleShoutIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.4), math.floor(GetScreenHeight()*.5))
            textTimeTillDeath:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.475), math.floor(GetScreenHeight()*.11))
            textTimeTillDeathText:SetText("Time Till Death:");
            local point, relativeTo, relativePoint, xOfs, yOfs = textTimeTillDeath:GetPoint()
            textTimeTillDeathText:SetPoint("BOTTOMLEFT", xOfs, yOfs+28)
        end
    end

    local function BSA_Hide()
        battleShoutIcon:SetPoint("BOTTOMLEFT", -100, 100)
        --textTimeTillDeath:SetPoint("TOPLEFT", -100, 100)
        textTimeTillDeath:SetText("-.--");
    end

    local function sunderArmor_Show()
        if (inCombat) then
            sunderArmorIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.35), math.floor(GetScreenHeight()*.5))
            sunderStackCountText:SetText(sunderStackCount);
            local point, relativeTo, relativePoint, xOfs, yOfs = sunderArmorIcon:GetPoint()
            sunderStackCountText:SetPoint("BOTTOMLEFT", xOfs+24, yOfs+14)
        end
    end

    local function sunderArmor_Hide()
        sunderArmorIcon:SetPoint("BOTTOMLEFT", -100, 100)
        sunderStackCountText:SetText("");
    end

    -- Globals Section
    local timeSinceLastUpdate = 0;
    local combatStart = GetTime();
    function onUpdate(sinceLastUpdate)
        timeSinceLastUpdate = GetTime();

        -- this if doesn't seem to do anything unfortunately revisit
        --if (inCombat and !hasBS) then -- and BSTimer-GetTime() > 110) then
            --print("BSTimer: "..BSTimer);
            --print("GetTime(): "..GetTime());
            --print("BSTimer-GetTime(): "..BSTimer-GetTime());
        --    BSA_Show()
        --end

        -- Todo:
        -- P1. While Accurate needs to be smarter to reduce seconds till death.
        -- P2. in an attempt to make it smarter.
        --     multiplied the time by .91 hopes that the 9% will be made up in execute phase
        if GetTime()-lastCheckTime >= checkInterval then
            if UnitIsEnemy("player","target") or UnitReaction("player","target") == 4 then
                local EHealthPercent = UnitHealth("target")/UnitHealthMax("target")*100;
                if EHealthPercent == 100 then
                    if targetName ~= 'Spore' and targetName ~= 'Fallout Slime' and targetName ~= 'Plagued Champion'then
                        combatStart = GetTime();
                    end
                end;
                if EHealthPercent then
                    if (lastCheckTime == 0) then
                        lastCheckTime = GetTime();
                    end
                    local target = "target"
                    for i = 1, 40 do
                        local icon, stackCount = UnitDebuff(target, i)
                        if icon == sunderArmor_Texture then
                            sunderStackCount = stackCount;
                            -- Sunder Armor debuff found
                            if sunderStackCount < 5 then
                                sunderArmor_Show()
                            else
                                sunderArmor_Hide()
                            end
                            foundSunder = true;
                            break
                        elseif not icon then
                            break
                        end
                    end
                    if (foundSunder == false) then
                        sunderArmor_Show()
                    end
                    lastCheckTime = 0 -- Reset the timer
                    foundSunder = false;

                    local maxHP     = UnitHealthMax("target");
                    local targetName = UnitName("target");
                    if targetName == 'Vaelastrasz the Corrupt' then
                        maxHP = UnitHealthMax("target")*0.3;
                    end;
                    local curHP     = UnitHealth("target");
                    local missingHP = maxHP - curHP;
                    local seconds   = timeSinceLastUpdate - combatStart; -- current length of the fight
                    local remainingSeconds = (maxHP/(missingHP/seconds)-seconds)*0.91; -- Should prob make it count the number of warriors in the raid
                    if (remainingSeconds ~= remainingSeconds) then
                        textTimeTillDeath:SetText("-.--")
                    else
                        if (remainingSeconds) then
                            textTimeTillDeath:SetText(string.format("%.2f",remainingSeconds));
                        end
                    end
                end
            end
        end
    end
    EliteWarrior.BSA:SetScript("OnUpdate", function(self) if inCombat then onUpdate(timeSinceLastUpdate); end; end);

    function hasItem(itemName)
        for bag = 0, 4, 1 do
            for slot = 1, GetContainerNumSlots(bag), 1 do
                local name = GetContainerItemLink(bag,slot);
                if name and string.find(name,itemName) then
                    return true;
                end;
            end;
        end;
        return false;
    end

    -- When the frame is shown, reset the update timer
    EliteWarrior.BSA:SetScript("OnShow", function(self)
        timeSinceLastUpdate = 0
    end)


    EliteWarrior.BSA:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            combatStart = GetTime();
            inCombat = true;
            BSA_Show();
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false;
            combatStart = GetTime();
            BSA_Hide();
            sunderArmor_Hide();
            textTimeTillDeathText:SetText("");
        elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
            local playerName = UnitName("player");
            if arg1 == "You gain Battle Shout." or arg1 == playerName.." gains Battle Shout (1)." then
                hasBS = true;
                BSTimer = GetTime();
                BSA_Hide();
            end
        elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
            local playerName = UnitName("player");
            if arg1 == "Battle Shout fades from you." or arg1 == "Battle Shout fades from "..playerName.."." then
                hasBS = false;
                BSA_Show();
            end
        elseif event == "PLAYER_LOGIN" then
            BSA_Hide();

            for n = 1, 40 do
                local texture = UnitBuff("player", n);
                if texture and texture == BSA_Texture then
                    hasBS = true;
                end
            end
        elseif event == "PLAYER_DEAD" then
            inCombat = false;
            hasBS = false;
            BSA_Hide();
        end
    end);
    EliteWarrior.BSA:RegisterEvent("UNIT_AURA")
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_ENABLED");
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_DISABLED");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS");
    EliteWarrior.BSA:RegisterEvent("PLAYER_LOGIN");
    EliteWarrior.BSA:RegisterEvent("PLAYER_DEAD");
    
end