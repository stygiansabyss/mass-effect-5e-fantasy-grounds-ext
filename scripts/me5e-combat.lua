--
-- Combat overrides
-- Defenses (barrier, tech armor, shields)
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
local originalMsgOOB;
local originalApplyDamage;
local originalMessageDamage;
local aDamageRoll;
local aSource;
local aTarget;
local nBarrier = 0;
local nTechArmor = 0;
local nShields = 0;
local nDamageReduction = 0;
local aCTNode;

function onInit()
    ActionsManager.registerResultHandler("barrier_d8", handleBarrier);

    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);

    -- Store this for later.
    originalApplyDamage = ActionDamage.applyDamage;
    originalMessageDamage = ActionDamage.messageDamage;
end

function handleApplyDamage(msgOOB)

    originalMsgOOB = msgOOB;
    originalMsgOOB.nTotal = tonumber(originalMsgOOB.nTotal);
    Debug.console("Message");
    Debug.console(msgOOB);

    local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
    local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
    if rTarget then
        rTarget.nOrder = msgOOB.nTargetOrder;
    end

    local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);

    messageDamage(rSource, rTarget, rRoll);

    --ActionDamage.messageDamage = messageDamage;
    --ActionDamage.handleApplyDamage(msgOOB);
end

function messageDamage(rSource, rTarget, rRoll)
    -- Set the global roll to the damage roll.
    aDamageRoll = rRoll;
    aSource = rSource;
    aTarget = rTarget;

    if rRoll.sType == nil or rRoll.sType ~= "damage" then
        sendBackTo5e();
        return ;
    end

    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    if not nodeTarget then
        sendBackTo5e();
        return ;
    end

    if sTargetNodeType == "pc" then
        aCTNode = ActorManager.getCTNode(rTarget);

        nShields = DB.getValue(aCTNode, "shields", 0);
        nTechArmor = DB.getValue(aCTNode, "tech_armor_hp", 0);
        nBarrier = DB.getValue(aCTNode, "barrier", 0);
    elseif sTargetNodeType == "ct" and ActorManager.isRecordType(rTarget, "npc") then
        -- HANDLE THIS AFTER PC WORKS.
        aCTNode = nodeTarget;
        nShields = DB.getValue(nodeTarget, "shields", 0);
        nTechArmor = DB.getValue(nodeTarget, "tech_armor_hp", 0);
        nBarrier = DB.getValue(nodeTarget, "barrier", 0);
    else
        sendBackTo5e();
        return ;
    end

    -- TODO: Get bypass working
    -- Barrier has to be handled uniquely since it requires a roll.
    --local bBypassBarrier = hasEffect("BYPBARRIER");
    --
    --if bBypassBarrier then
    --    sendBypassMessage("Barrier");
    --    removeEffect("BYPBARRIER");
    --end
    sendStartingDamageMessage();

    if nBarrier > 0 then
        showBarrierChoiceDialog(rTarget);
    else
        checkShields(rSource, rTarget);
    end
end

function hasEffect(sEffect)
    return ActorManager5E.hasRollTrait(rSource, sEffect);
end

function removeEffect(sEffect)
    EffectManager5E.removeEffectByType(aCTNode, sEffect);
end

function checkShields(rSource, rTarget)
    if nTechArmor > 0 and originalMsgOOB.nTotal > 0 then
        handleTechArmor(aDamageRoll, rSource, rTarget);
    end

    -- Shields do not work on melee damage.
    if nShields > 0 and originalMsgOOB.nTotal > 0 and originalMsgOOB.range ~= "M" then
        handleShields(aDamageRoll, rSource, rTarget);
    end

    if originalMsgOOB.nTotal == 0 then
        Debug.console("All damage removed by defenses");
        sendNoDamageMessage();

        return ;
    end

    local remainingDamage = tostring(aDamageRoll.nTotal);

    if originalMsgOOB.nTotal ~= remainingDamage then
        sendRemainingDamageMessage();
        --fixOriginalMsg(remainingDamage);
    end

    sendBackTo5e();
end

function sendBackTo5e()
    --ActionDamage.messageDamage = originalMessageDamage;
    --ActionDamage.messageDamage(aSource, aTarget, aDamageRoll);
    originalMsgOOB.nTotal = tostring(originalMsgOOB.nTotal);
    Debug.console("Message");
    Debug.console(originalMsgOOB);
    ActionDamage.handleApplyDamage(originalMsgOOB);

    aCTNode = nil;
    originalMsgOOB = nil;
    nDamageReduction = 0;
end

--
-- This function is used to stop the Total mismatch damage message.
--
function fixOriginalMsg(remainingDamage)
    -- Change the mod to be a proper negative.
    originalMsgOOB.nMod = tostring(tonumber(originalMsgOOB.nMod) - nDamageReduction);

    -- Get one of the totals
    local bReduced = false;
    local nFirstTotal;

    -- Get the first damage amount.  This is what we will apply our defense to.
    for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(originalMsgOOB.sDesc, "%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]") do
        if not bReduced then
            nFirstTotal = sDamageSubTotal;
            bReduced = true;
        end
    end

    -- Change the description to match the actual damage we are sending.
    originalMsgOOB.sDesc = string.gsub(originalMsgOOB.sDesc, nFirstTotal, nFirstTotal - remainingDamage);

    -- Set the roll total to our reduced number.
    originalMsgOOB.nTotal = remainingDamage;
end

function showBarrierChoiceDialog(rTarget)    
    -- Get character info to determine if they can choose ticks
    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    

    local vanguardNode = getVanguardNode(nodeTarget);
    local nDicePerTick = getBarrierDicePerTick(vanguardNode);
    local bCanChooseTicks = canChooseBarrierTicks(vanguardNode);
    
    local nTicksToSpend;
    
    if bCanChooseTicks then
        -- Level 3+ Vanguards get to choose
        showBarrierInputDialog(rTarget, nBarrier, nDicePerTick);
    else
        -- Everyone else automatically uses 1 tick
        Debug.console("Non-Vanguard or level < 3, automatically using 1 barrier tick");
        ChatManager.SystemMessage("Barrier Defense: Using 1 barrier tick (" .. (nDicePerTick == 2 and "2d8" or "1d8") .. ")");
        rollBarrier(rTarget, 1, nDicePerTick);
    end
end

function showBarrierInputDialog(rTarget, nBarrier, nDicePerTick)
    Debug.console("Showing barrier input dialog");
    
    -- Create selection dialog using DialogManager
    local sMessage = string.format("How many barrier ticks do you want to spend?\n\nYou have %d barrier ticks available.\nEach tick provides %s damage reduction.", 
                                   nBarrier, 
                                   nDicePerTick == 2 and "2d8" or "1d8");
    
    local tOptions = {};
    -- Add options for each barrier amount from 0 to nBarrier
    for i = 0, nBarrier do
        if i == 0 then
            table.insert(tOptions, { text = "No Barrier (0 ticks)", value = i });
        elseif i == 1 then
            table.insert(tOptions, { text = "1 Tick", value = i });
        else
            table.insert(tOptions, { text = i .. " Ticks", value = i });
        end
    end
    
    local tDialogData = {
        title = "Barrier Defense",
        msg = sMessage,
        options = tOptions,
        callback = function(selection, data)
            handleBarrierSelection(selection, data, rTarget, nBarrier, nDicePerTick);
        end,
        showmodule = false,
    };
    
    DialogManager.requestSelectionDialog(tDialogData);
end

function handleBarrierSelection(selection, data, rTarget, nBarrier, nDicePerTick)
	local value = selection[1];
    
    -- Parse the selected text to get the number of ticks
    local nTicksSpent = 0;
    
    if value == "No Barrier (0 ticks)" then
        nTicksSpent = 0;
    elseif value == "1 Tick" then
        nTicksSpent = 1;
    else
        -- Extract number from "X Ticks" format
        local nTicks = tonumber(string.match(value, "(%d+) Ticks"));
        if nTicks then
            nTicksSpent = nTicks;
        end
    end
    
    if nTicksSpent == 0 then
        -- No barrier
        Debug.console("No barrier spent");
        ChatManager.SystemMessage("Barrier Defense: No barrier spent");
        checkShields(aSource, rTarget);
    else
        -- Use selected amount
        Debug.console("Using " .. nTicksSpent .. " barrier ticks");
        rollBarrier(rTarget, nTicksSpent, nDicePerTick);
    end
end


function canChooseBarrierTicks(vanguardNode)
    if vanguardNode == nil then
        return false;
    end

    -- Check if this is a Vanguard at level 3+
    local nLevel = DB.getValue(vanguardNode, "level", 0);
    
    -- Only level 3+ Vanguards can choose barrier ticks
    return nLevel >= 3;
end

function getBarrierDicePerTick(vanguardNode)
    if vanguardNode == nil then
        return 1;
    end

    -- Check if this is a Vanguard at level 11+
    local nLevel = DB.getValue(vanguardNode, "level", 0);
    
    -- Vanguards get 2d8 per tick at level 11+
    if nLevel >= 11 then
        return 2;
    end
    
    -- Everyone else gets 1d8 per tick
    return 1;
end

function getVanguardNode(nodeTarget)
    -- Try to get from the character sheet classes section (array of classes)
    local sNodePath = DB.getPath(nodeTarget);
    local nodeClasses = DB.findNode(sNodePath .. ".classes");
    
    if nodeClasses then
        -- Check all classes to find if any are Vanguard (or other ME5e classes)
        local nClassCount = DB.getChildCount(nodeClasses);
        local sFirstClass = nil;
        Debug.console("Found " .. nClassCount .. " classes");
        
        for i = 1, nClassCount do
            local nodeClass = DB.getChild(nodeClasses, "id-0000" .. i);
            if nodeClass then
                local sClass = DB.getValue(nodeClass, "name", "");
                Debug.console("Class " .. i .. " name: '" .. sClass .. "'");
                
                -- Check if this is a ME5e class (prioritize Vanguard for barrier mechanics)
                if sClass == "Vanguard" then
                    Debug.console("Found Vanguard class!");
                    return nodeClass;
                elseif sClass ~= "" then
                    -- Store the first non-empty class as fallback
                    if not sFirstClass then
                        sFirstClass = nodeClass;
                    end
                end
            end
        end
        
        -- If we found a class but no Vanguard, return the first class
        if sFirstClass then
            Debug.console("Character class found: '" .. sFirstClass .. "' (no Vanguard)");
            return sFirstClass;
        end
    end
    
    Debug.console("No Vanguard class found");
    return nil;
end

function rollBarrier(rTarget, nTicksSpent, nDicePerTick)
    Debug.console("Rolling barrier - Ticks: " .. nTicksSpent .. ", Dice per tick: " .. nDicePerTick);
    
    if nTicksSpent <= 0 then
        Debug.console("No ticks spent, skipping barrier");
        checkShields(aSource, rTarget);
        return;
    end
    
    -- Calculate total dice to roll
    local nTotalDice = nTicksSpent * nDicePerTick;
    local sDiceNotation = nTotalDice .. "d8";
    
    -- Create the roll
    local rRoll = { 
        sType = "barrier_d8", 
        sDesc = "Barrier Defense (" .. nTicksSpent .. " ticks)", 
        aDice = { expr = sDiceNotation }, 
        nMod = 0,
        nTicksSpent = nTicksSpent,
        nDicePerTick = nDicePerTick
    };
    
    ActionsManager.performAction(nil, aTarget, rRoll);
end

function handleBarrier(rSource, rTarget, rRoll, msg)
    Debug.console(originalMsgOOB);
    Debug.console(msg);
    
    local nDamage = originalMsgOOB.nTotal;
    local nBarrierHp = rRoll.nTotal;
    local nTicksSpent = rRoll.nTicksSpent or 1; -- Fallback for old rolls
    local nBarrierTicks = nBarrier - nTicksSpent;
    local sBarrierStatus;

    if nBarrierTicks > 0 then
        sBarrierStatus = "Yes";
    end

    remainingDamage = nDamage - nBarrierHp;
    
    -- Track the amount reduced
    nDamageReduction = nDamageReduction + rRoll.nTotal;

    if remainingDamage < 0 then
        remainingDamage = 0;
    end

    sendBarrierMessage(nDamage, rRoll.nTotal, rSource, rRoll, nTicksSpent);

    nBarrier = nBarrierTicks;
    DB.setValue(aCTNode, "barrier", "number", nBarrierTicks);
    DB.setValue(aCTNode, "barrier_status", "string", sBarrierStatus);
    originalMsgOOB.nTotal = remainingDamage;

    checkShields(aSource, rTarget);
end

function handleTechArmor(rRoll, rSource, rTarget)
    local nDamage = originalMsgOOB.nTotal;
    local nTechHP = nTechArmor;
    local nBlocked;
    local sTechArmorStatus;

    remainingDamage = nDamage - nTechArmor;
    nTechHP = nTechHP - nDamage;

    -- Track the amount reduced
    if nDamage <= nTechArmor then
        nBlocked = nDamage;
    else
        nBlocked = nTechArmor;
    end

    nDamageReduction = nDamageReduction + nBlocked;

    if remainingDamage < 0 then
        remainingDamage = 0;
    end
    if nTechHP < 0 then
        nTechHP = 0;
    end

    if nTechHP > 0 then
        sTechArmorStatus = "Yes";
    end

    sendTechArmorMessage(nBlocked, rSource, rTarget, rRoll);

    nTechArmor = nTechHP;
    DB.setValue(aCTNode, "tech_armor_hp", "number", nTechHP);
    DB.setValue(aCTNode, "tech_armor_status", "string", sTechArmorStatus);
    originalMsgOOB.nTotal = remainingDamage;
end

function handleShields(rRoll, rSource, rTarget)
    local nDamage = originalMsgOOB.nTotal;
    local nShieldHP = nShields;
    local nBlocked = 0;
    local sShieldsStatus;
    local nLightningBlocked = 0;
    local remainingDamage = nDamage;

    for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]") do
        local nRollDamage = tonumber(sDamageSubTotal);

        if nRollDamage > remainingDamage then
            nRollDamage = remainingDamage;
        end

        if sDamageType ~= "lightning" and nShieldHP > 0 then
            if nRollDamage >= nShieldHP then
                remainingDamage = remainingDamage - nShieldHP;
                nBlocked = nBlocked + nShieldHP;
                nDamageReduction = nDamageReduction + nShieldHP;
            else
                remainingDamage = remainingDamage - nRollDamage;
                nBlocked = nBlocked + nRollDamage;
                nDamageReduction = nDamageReduction + nRollDamage;
            end
            nShieldHP = nShieldHP - nRollDamage;
        elseif sDamageType == "lightning" and nShieldHP > 0 then
            -- Lightning does double damage to shields, so we drop them by half.
            nShieldHP = nShieldHP / 2;
            nShieldHP = math.floor(nShieldHP+0.49999999999999994);

            if nRollDamage >= nShieldHP then
                remainingDamage = remainingDamage - nShieldHP;
                nBlocked = nBlocked + (nShieldHP * 2);
                nDamageReduction = nDamageReduction + nShieldHP;
                nLightningBlocked = nShieldHP;
            else
                remainingDamage = remainingDamage - nRollDamage;
                nBlocked = nBlocked + nRollDamage;
                nDamageReduction = nDamageReduction + nRollDamage;
                nLightningBlocked = nRollDamage;
            end
            nShieldHP = nShieldHP - nRollDamage;

            -- Set the shields back in case there are other damage types.
            if nShieldHP > 0 then
                nShieldHP = nShieldHP * 2;
            end

        end
    end

    if remainingDamage < 0 then
        remainingDamage = 0;
    end
    if nShieldHP < 0 then
        nShieldHP = 0;
    end

    if nShieldHP > 0 then
        sShieldsStatus = "Yes";
    end

    sendShieldMessage(nBlocked, rSource, rTarget, nLightningBlocked);

    nShields = nShieldHP;
    DB.setValue(aCTNode, "shields", "number", nShieldHP);
    DB.setValue(aCTNode, "shields_status", "string", sShieldsStatus);
    originalMsgOOB.nTotal = remainingDamage;
end

function sendBypassMessage(sType)
    local msg = { font = "msgfont" };

    if sType == "Barrier" then
        msg.icon = "roll_barrier";
    elseif sType == "Tech Armor" then
        msg.icon = "roll_tech_armor";
    else
        msg.icon = "roll_shields";
    end

    msg.text = string.format("[Defense] %s BYPASSED", sType);

    ActionsManager.outputResult(aDamageRoll.bSecret, aSource, aTarget, msg, msg);
end

function sendBarrierMessage(rDamage, rDefenseHP, rTarget, rRoll, nTicksSpent)
    local nBlocked;
    local rMessage = ActionsManager.createActionMessage(rTarget, rRoll);

    if rDamage >= rDefenseHP then
        nBlocked = rDefenseHP;
    else
        nBlocked = rDamage;
    end

    -- Create dynamic dice notation based on ticks spent and dice per tick
    local nDicePerTick = rRoll.nDicePerTick or 1;
    local nTotalDice = (nTicksSpent or 1) * nDicePerTick;
    local sDiceNotation = nTotalDice .. "d8";
    
    rMessage.icon = "roll_barrier";
    rMessage.text = string.format("[Defense] %s [%s=%s] (%d ticks)", "Biotic Barrier", sDiceNotation, nBlocked, nTicksSpent or 1);

    Comm.deliverChatMessage(rMessage);
end

function sendTechArmorMessage(nBlocked, rSource, rTarget, rRoll)
    local msg = { font = "msgfont", icon = "roll_tech_armor" };

    msg.text = string.format("[Defense] %s [%s] -> [from %s]", "Tech Armor", nBlocked, rTarget.sName);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendShieldMessage(nBlocked, rSource, rTarget, nLightningBlocked)
    local msg = { font = "msgfont", icon = "roll_shields" };

    msg.text = string.format("[Defense] %s [%s] -> [from %s]", "Kinetic Shields", nBlocked, rTarget.sName);

    if nLightningBlocked > 0 then
        msg.text = string.format("%s [Lightning Damage: %s]", msg.text, nLightningBlocked);
    end

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendStartingDamageMessage()
    local msg = { font = "msgfont" };
    local isHalf = false;
    local sHalf = " ";

    if aDamageRoll.sResults then
        isHalf = aDamageRoll.sResults:match("%[HALF%]");
    end

    if isHalf then
        sHalf = '[HALF] ';
    end

    msg.text = string.format("Defending against %sdamage: %s", sHalf, aDamageRoll.nTotal);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendRemainingDamageMessage()
    local msg = { font = "msgfont" };

    msg.text = string.format("Remaining damage: %s", originalMsgOOB.nTotal);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendNoDamageMessage()
    local msg = { font = "msgfont", icon = "roll_damage" };
    local sRange = "";

    if aDamageRoll.sRange then
        sRange = " (" .. aDamageRoll.sRange .. ")";
    end

    msg.text = string.format("[Damage%s] %s [0] -> [to %s][ABSORBED]", sRange, aDamageRoll.sLabel, aTarget.sName);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end