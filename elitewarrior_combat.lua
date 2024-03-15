if UnitClass("player") == "Warrior" then
    local lastCheckTime = 0;
    local checkInterval = 0.2;
    if not EliteWarrior then
        EliteWarrior = {};
    end;
    EliteWarrior.BSA = CreateFrame("Frame", nil, UIParent);
    local BSA_Texture = "Interface\\Icons\\Ability_Warrior_BattleShout";
    local sunderArmor_Texture = "Interface\\Icons\\Ability_Warrior_Sunder";
    local mightyRage_Texture = "Interface\\Icons\\INV_Potion_41";
    local deathWish_Texture = "Interface\\Icons\\Spell_Shadow_DeathPact";


    local hasBS = false;
    local inCombat = false;
    local foundSunder = false;
    local sunderStackCount = 0;
    local remainingSeconds = 0;

    local battleShoutIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    battleShoutIcon:SetWidth(120)
    battleShoutIcon:SetHeight(120)
    battleShoutIcon:SetTexture(BSA_Texture)
    battleShoutIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.6), math.floor(GetScreenHeight()*.91))

    local sunderArmorIcon = UIParent:CreateTexture(nil,"BACKGROUND",nil,-8)
    sunderArmorIcon:SetWidth(120)
    sunderArmorIcon:SetHeight(120)
    sunderArmorIcon:SetTexture(sunderArmor_Texture)
    sunderArmorIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.51), math.floor(GetScreenHeight()*.91))

    local deathWishIcon = UIParent:CreateTexture(nil,"OVERLAY",nil,-8)
    deathWishIcon:SetWidth(120)
    deathWishIcon:SetHeight(120)
    deathWishIcon:SetTexture(deathWish_Texture)
    deathWishIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.6), math.floor(GetScreenHeight()*.75))

    local mightyRageIcon = UIParent:CreateTexture(nil,"OVERLAY",nil,-8)
    mightyRageIcon:SetWidth(120)
    mightyRageIcon:SetHeight(120)
    mightyRageIcon:SetTexture(mightyRage_Texture)
    mightyRageIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.51), math.floor(GetScreenHeight()*.75))


    local trinketIcon = UIParent:CreateTexture(nil,"OVERLAY",nil,-8)
    trinketIcon:SetWidth(120)
    trinketIcon:SetHeight(120)
    trinketIcon:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.6), math.floor(GetScreenHeight()*.59))
    trinketIcon:SetTexture(mightyRage_Texture)


    local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
    local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

    local sunderStackCountText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
    sunderStackCountText:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")

    -- Globals Section
    local timeSinceLastUpdate = 0;
    local combatStart = GetTime();

    local function BSA_Show()
        if (inCombat and not hasBS) then
            battleShoutIcon:Show();
            textTimeTillDeath:SetPoint("BOTTOMLEFT", math.floor(GetScreenWidth()*.475), math.floor(GetScreenHeight()*.11));
            textTimeTillDeathText:SetText("Time Till Death:");
            local point, relativeTo, relativePoint, xOfs, yOfs = textTimeTillDeath:GetPoint();
            textTimeTillDeathText:SetPoint("BOTTOMLEFT", xOfs, yOfs+28);
        end
    end

    local function BSA_Hide()
        battleShoutIcon:Hide();
        --textTimeTillDeath:SetPoint("TOPLEFT", -100, 100)
        textTimeTillDeath:SetText("-.--");
    end

    local function sunderArmor_Show()
        if (inCombat) then
            sunderArmorIcon:Show()
            sunderStackCountText:SetText(sunderStackCount);
            local point, relativeTo, relativePoint, xOfs, yOfs = sunderArmorIcon:GetPoint()
            sunderStackCountText:SetPoint("BOTTOMLEFT", xOfs+54, yOfs+52)
        end
    end

    local function sunderArmor_Hide()
        sunderArmorIcon:Hide()
        sunderStackCountText:SetText("");
        sunderStackCount = 0;
    end

    function sunderLogic()
        if UnitIsEnemy("player","target") or UnitReaction("player","target") == 4 then
            for i = 1, 40 do
                local icon, stackCount = UnitDebuff("target", i)
                sunderStackCount = 0;
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
            foundSunder = false;
        else
            sunderArmor_Hide()
        end
    end

    -- TTD stands for Time Till Death
    local function TTDLogic()
        if UnitIsEnemy("player","target") or UnitReaction("player","target") == 4 then
            local EHealthPercent = UnitHealth("target")/UnitHealthMax("target")*100;
            if EHealthPercent == 100 then
                if targetName ~= 'Spore' and targetName ~= 'Fallout Slime' and targetName ~= 'Plagued Champion' then
                    -- may not want to restart combat if you tab to one of these monsters
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
                remainingSeconds = (maxHP/(missingHP/seconds)-seconds)*0.90; -- Should prob make it count the number of warriors in the raid
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

    function rememberToX()
        if (inCombat and remainingSeconds) then
            if (UnitLevel("target") == -1) then
                if remainingSeconds <= 32 and remainingSeconds >= 27 then
                    deathWishIcon:Show();
                else
                    deathWishIcon:Hide();
                end
                if remainingSeconds <= 22 and remainingSeconds >= 18 then
                    mightyRageIcon:Show();
                else
                    mightyRageIcon:Hide();
                end


                local trinket1 = GetInventoryItemLink("player", 13)
                local trinket2 = GetInventoryItemLink("player", 14)
                local trinketLinks = {trinket1, trinket2}
                
                local trinketTimers = {
                    ["Kiss of the Spider"] = {13, 17, },
                    ["Slayer's Crest"] = {18, 22},
                    ["Earth Strike"] = {18, 22},
                    ["Jom Gabbar"] = {18, 22},
                    ["Badge of the Swarmguard"] = {27, 32},
                    ["Diamond Flask"] = {55, 65},
                };
                
                local foundAtLeastOneTrinket = false;
                for _, link in ipairs(trinketLinks) do
                    if link then
                        for trinketName, timers in pairs(trinketTimers) do
                            if string.find(link, trinketName) then
                                local minTimer = timers[1]
                                local maxTimer = timers[2]
                                local slotNumber = 13 -- Default to slot 13
                                if _ == 2 then
                                    slotNumber = 14 -- If it's the second trinket, use slot 14
                                end
                                if remainingSeconds >= minTimer and remainingSeconds <= maxTimer then
                                    -- Get the texture path for the equipped trinket
                                    local texture = GetInventoryItemTexture("player", slotNumber)
                                    trinketIcon:SetTexture(texture)
                                    trinketIcon:Show()
                                    foundAtLeastOneTrinket = true;
                                else
                                    if (foundAtLeastOneTrinket == false) then
                                        trinketIcon:Hide()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end


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
        --     multiplied the time by .90 hopes that the 10% will be made up in execute phase
        -- only run once every 0.2 seconds
        if GetTime()-lastCheckTime >= checkInterval then
            if (lastCheckTime == 0) then
                lastCheckTime = GetTime();
            end
            sunderLogic();
            TTDLogic();
            rememberToX();

            lastCheckTime = 0 -- Reset the timer
        end
    end
    EliteWarrior.BSA:SetScript("OnUpdate", function(self) if inCombat then onUpdate(timeSinceLastUpdate); end; end);

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
            mightyRageIcon:Hide();
            deathWishIcon:Hide();
            trinketIcon:Hide();
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
            sunderArmor_Hide()
            mightyRageIcon:Hide();
            deathWishIcon:Hide();
            trinketIcon:Hide();

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
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_ENABLED");
    EliteWarrior.BSA:RegisterEvent("PLAYER_REGEN_DISABLED");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF");
    EliteWarrior.BSA:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS");
    EliteWarrior.BSA:RegisterEvent("PLAYER_LOGIN");
    EliteWarrior.BSA:RegisterEvent("PLAYER_DEAD");
    
end