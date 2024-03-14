if UnitClass("player") == "Warrior" then
    EliteWarrior.BSA = CreateFrame("Frame", nil, UIParent);
    local ChronoBoon_Texture = "Interface\\Icons\\inv_misc_enggizmos_24";

    local BSA_Texture = "Interface\\Icons\\Ability_Warrior_BattleShout";
    local hasBS = false;
    local inCombat = false;

    local battleShoutIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    battleShoutIcon:SetWidth(60)
    battleShoutIcon:SetHeight(60)
    battleShoutIcon:SetTexture(BSA_Texture)

    local chronoBoonIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    chronoBoonIcon:SetWidth(160)
    chronoBoonIcon:SetHeight(160)
    chronoBoonIcon:SetTexture(ChronoBoon_Texture)
    chronoBoonIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.725), math.floor(GetScreenHeight()*.8))
    chronoBoonIcon:Hide();

    local t2 = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
    local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

    local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
    local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

    -- Globals Section
    local ONUPDATE_INTERVAL = 1.0; -- How often the OnUpdate code will run (in seconds)
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
        if UnitIsEnemy("player","target") or UnitReaction("player","target") == 4 then
            local EHealthPercent = UnitHealth("target")/UnitHealthMax("target")*100;
            if EHealthPercent == 100 then
                if targetName ~= 'Spore' and targetName ~= 'Fallout Slime' and targetName ~= 'Plagued Champion'then
                    combatStart = GetTime();
                end
            end;
            if EHealthPercent then
                local maxHP     = UnitHealthMax("target");
                local targetName = UnitName("target");
                if targetName == 'Vaelastrasz the Corrupt' then
                    maxHP = UnitHealthMax("target")*0.3;
                end;
                local curHP     = UnitHealth("target");
                local missingHP = maxHP - curHP;
                local seconds   = timeSinceLastUpdate - combatStart; -- current length of the fight
                local remainingSeconds = (maxHP/(missingHP/seconds)-seconds)*0.91;
                if (remainingSeconds ~= remainingSeconds) then
                    textTimeTillDeath:SetText("-.--")
                    --combatLengthSeconds:SetText("-.--");
                else
                    if (remainingSeconds) then
                        textTimeTillDeath:SetText(string.format("%.2f",remainingSeconds));
                    end
                    --if (seconds and combatLengthSeconds) then
                        --combatLengthSeconds:setText(seconds)
                    --end
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
    
    EliteWarrior.BSA:SetScript("OnEvent", function() 
        if event == "PLAYER_REGEN_DISABLED" then
            combatStart = GetTime();
            inCombat = true;
            chronoBoonIcon:Hide()
            BSA_Show();
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false;
            combatStart = GetTime();
            BSA_Hide();
            textTimeTillDeathText:SetText("");
        elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
            local playerName = UnitName("player");
            if arg1 == "You gain Battle Shout." or arg1 == playerName.." gains Battle Shout (1)." then
                hasBS = true;
                BSTimer = GetTime();
                BSA_Hide();
            end
            --if arg1 == playerName.." gains Flurry (1)." then
            --if arg1 == playerName.." gains Fury of Forgewrite (1)." then
            --if arg1 == playerName.." gains Haste (1)." then
            --    tracked[buff] = tracked[buff]+1;
            --end
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
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- Add a check to see if I am Lead, if so check to see if we're on masterloot.
            if (not inCombat) then
                local targetName = UnitName("target");
                local bosses = {};
                --test
                bosses["Giant Ember Worg"] = 1;

                --mc
                bosses["Lucifron"] = 1;
                bosses["Magmadar"] = 1;
                bosses["Gehennas"] = 1;
                bosses["Garr"] = 1;
                bosses["Shazzrah"] = 1;
                bosses["Baron Geddon"] = 1;
                bosses["Golemagg the Incinerator"] = 1;
                bosses["Sulfuron Harbinger"] = 1;
                bosses["Majordomo Executus"] = 1;
                bosses["Ragnaros"] = 1;
                --bwl
                bosses["Razorgore the Untamed"] = 1;
                bosses["Vaelastrasz the Corrupt"] = 1;
                bosses["Broodlord Lashlayer"] = 1;
                bosses["Firemaw"] = 1;
                bosses["Ebonroc"] = 1;
                bosses["Flamegor"] = 1;
                bosses["Chromaggus"] = 1;
                bosses["Nefarian"] = 1;
                --aq40
                bosses["The Prophet Skeram"] = 1;
                bosses["Battleguard Sartura"] = 1;
                bosses["Fankriss the Unyielding"] = 1;
                bosses["Princess Huhuran"] = 1;
                bosses["Emperor Vek'lor"] = 1;
                bosses["Emperor Vek'nilash"] = 1;
                bosses["Ouro"] = 1;
                bosses["C'thun"] = 1;
                --naxxramas
                bosses["Patchwerk"] = 1;
                bosses["Anub'Rekhan"] = 1;
                bosses["Noth the Plaguebringer"] = 1;
                bosses["Instructor Razuvious"] = 1;
                bosses["Sapphiron"] = 1;
                bosses["Kel'Thuzad"] = 1;
                if (bosses[targetName]) then
                    --if (hasItem("Supercharged Chronoboon Displacer")) then
                        --chronoBoonIcon:Show()
                    --end
                else
                    --chronoBoonIcon:Hide()
                end
            end
        end
    end);
    EliteWarrior.BSA:RegisterEvent("UNIT_AURA")
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_ENABLED");
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_DISABLED");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS");
    EliteWarrior.BSA:RegisterEvent("PLAYER_LOGIN");
    EliteWarrior.BSA:RegisterEvent("PLAYER_DEAD");
    EliteWarrior.BSA:RegisterEvent("PLAYER_TARGET_CHANGED");
    
end