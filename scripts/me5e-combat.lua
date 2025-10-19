--
-- Combat overrides
-- Defenses (barrier, tech armor, shields)
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
OOB_MSGTYPE_BARRIER_CHOICE = "barrier_choice";
OOB_MSGTYPE_BARRIER_RESPONSE = "barrier_response";
OOB_MSGTYPE_DEFENSE_UPDATE = "defense_update";
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
-- Store message data for barrier rolls by target node
local barrierMsgLookup = {};

-- Venting system - track weapon ammo usage per character
local weaponAmmoTracker = {};


function onInit()
    ActionsManager.registerResultHandler("barrier_d8", handleBarrier);

    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_BARRIER_CHOICE, handleBarrierChoiceRequest);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_BARRIER_RESPONSE, handleBarrierChoiceResponse);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DEFENSE_UPDATE, handleDefenseUpdate);

    -- Store this for later.
    originalApplyDamage = ActionDamage.applyDamage;
    originalMessageDamage = ActionDamage.messageDamage;
    
    -- Hook into combat turn management for venting system
    CombatManager.setCustomTurnStart(onTurnStart);
end

function handleApplyDamage(msgOOB)
    -- Make a local copy of the message to avoid global variable conflicts
    local localMsgOOB = UtilityManager.copyDeep(msgOOB);
    localMsgOOB.nTotal = tonumber(localMsgOOB.nTotal);
    
    Debug.console("Message");
    Debug.console(localMsgOOB);

    local rSource = ActorManager.resolveActor(localMsgOOB.sSourceNode);
    local rTarget = ActorManager.resolveActor(localMsgOOB.sTargetNode);
    if rTarget then
        rTarget.nOrder = localMsgOOB.nTargetOrder;
    end

    local rRoll = UtilityManager.decodeRollFromOOB(localMsgOOB);

    messageDamage(rSource, rTarget, rRoll, localMsgOOB);

    --ActionDamage.messageDamage = messageDamage;
    --ActionDamage.handleApplyDamage(localMsgOOB);
end

function messageDamage(rSource, rTarget, rRoll, msgOOB)
    -- Set the global roll to the damage roll.
    aDamageRoll = rRoll;
    aSource = rSource;
    aTarget = rTarget;
    -- Store the message locally for this target
    originalMsgOOB = msgOOB;

    Debug.console("Original damage roll");
    Debug.console(aDamageRoll);

    if rRoll.sType == nil or rRoll.sType ~= "damage" then
        sendBackTo5e(msgOOB);
        return ;
    end

    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    if not nodeTarget then
        sendBackTo5e(msgOOB);
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
        sendBackTo5e(msgOOB);
        return ;
    end

    sendStartingDamageMessage();
    
    local bBypassBarrier = hasWarpAmmoEffect(rSource, rRoll);

    if nBarrier > 0 then
        if bBypassBarrier then
            handleWarpAmmo(aDamageRoll.nTotal, rTarget, rRoll);
            checkShields(rSource, rTarget, msgOOB);
            return ;
        end

        showBarrierChoiceDialog(rTarget);
    else
        checkShields(rSource, rTarget, msgOOB);
    end
end

function hasEffect(sEffect)
    return ActorManager5E.hasRollTrait(rSource, sEffect);
end

function removeEffect(sEffect)
    EffectManager5E.removeEffectByType(aCTNode, sEffect);
end

function checkShields(rSource, rTarget, msgOOB)
    -- Use the passed message or fall back to global
    local localMsgOOB = msgOOB or originalMsgOOB;
    
    -- Defensive check: ensure localMsgOOB is not nil
    if not localMsgOOB then
        Debug.console("ERROR: msgOOB is nil in checkShields");
        return;
    end
    
    if nTechArmor > 0 and localMsgOOB.nTotal > 0 then
        handleTechArmor(aDamageRoll, rSource, rTarget);
    end

    -- Shields do not work on melee damage.
    if nShields > 0 and localMsgOOB.nTotal > 0 and localMsgOOB.range ~= "M" then
        handleShields(aDamageRoll, rSource, rTarget);
    end

    if localMsgOOB.nTotal == 0 then
        Debug.console("All damage removed by defenses");
        sendNoDamageMessage();

        return ;
    end

    local remainingDamage = tostring(aDamageRoll.nTotal);

    if localMsgOOB.nTotal ~= remainingDamage then
        sendRemainingDamageMessage(localMsgOOB);
        --fixOriginalMsg(remainingDamage);
    end

    sendBackTo5e(localMsgOOB);
end

function sendBackTo5e(msgOOB)
    -- Use the passed message or fall back to global
    local localMsgOOB = msgOOB or originalMsgOOB;
    
    -- Defensive check: ensure localMsgOOB is not nil
    if not localMsgOOB then
        Debug.console("ERROR: msgOOB is nil in sendBackTo5e");
        return;
    end
    
    --ActionDamage.messageDamage = originalMessageDamage;
    --ActionDamage.messageDamage(aSource, aTarget, aDamageRoll);
    localMsgOOB.nTotal = tostring(localMsgOOB.nTotal);
    Debug.console("Message");
    Debug.console(localMsgOOB);
    ActionDamage.handleApplyDamage(localMsgOOB);

    aCTNode = nil;
    -- Reset global variables for this target
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
    local nBarrierDie = getBarrierDie(vanguardNode);
    
    if bCanChooseTicks then
        -- Level 3+ Vanguards get to choose
        showBarrierInputDialog(rTarget, nBarrier, nDicePerTick, nBarrierDie);
    else
        -- Everyone else automatically uses 1 tick
        rollBarrier(rTarget, 1, nDicePerTick, 8);
    end
end

function showBarrierInputDialog(rTarget, nBarrier, nDicePerTick, nBarrierDie)
    
    -- Get the character sheet node to determine ownership
    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    local bIsPC = (sTargetNodeType == "pc");
    
    if bIsPC then
        -- For PCs, send OOB message to the specific player
        local sTargetIdentity = DB.getOwner(nodeTarget);
        if sTargetIdentity and User.getCurrentIdentity() ~= sTargetIdentity then
            -- Check if the target user is in the user list (meaning they're connected)
            local userList = User.getActiveUsers();
            local bUserConnected = false;
            for _, user in ipairs(userList) do
                if user == sTargetIdentity then
                    bUserConnected = true;
                    break;
                end
            end
            
            if bUserConnected then
                local msgOOB = {
                    type = OOB_MSGTYPE_BARRIER_CHOICE,
                    target = nodeTarget.getNodeName(),
                    barrier = nBarrier,
                    dicePerTick = nDicePerTick,
                    barrierDie = nBarrierDie,
                    message = string.format("How many barrier ticks do you want to spend?\n\nYou have %d barrier ticks available.\nEach tick provides %s damage reduction.", 
                                           nBarrier, 
                                           nDicePerTick == 2 and "2d".. nBarrierDie or "1d" .. nBarrierDie)
                };
                Comm.deliverOOBMessage(msgOOB, sTargetIdentity);
                return;
            end
            -- If user not connected, fall through to GM dialog
        end
        -- If player not connected or no owner, fall through to show to GM
    end
    
    -- For NPCs or if we can't get the player identity, show to GM
    local sMessage = string.format("How many barrier ticks do you want to spend?\n\nYou have %d barrier ticks available.\nEach tick provides %s damage reduction.", 
                                   nBarrier, 
                                   nDicePerTick == 2 and "2d".. nBarrierDie or "1d" .. nBarrierDie);
    
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
            handleBarrierSelection(selection, data, rTarget, nBarrier, nDicePerTick, nBarrierDie);
        end,
        showmodule = false,
    };
    
    DialogManager.requestSelectionDialog(tDialogData);
end

function handleBarrierSelection(selection, data, rTarget, nBarrier, nDicePerTick, nBarrierDie)
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
        checkShields(aSource, rTarget, originalMsgOOB);
    else
        -- Use selected amount
        rollBarrier(rTarget, nTicksSpent, nDicePerTick, nBarrierDie);
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

function getBarrierDie(vanguardNode)
    if vanguardNode == nil then
        return 8;
    end

    -- Check if this is a Vanguard at level 11+
    local nLevel = DB.getValue(vanguardNode, "level", 0);
    local nSubClass = DB.getValue(vanguardNode, "specialization", nil);

    if nSubClass ~= "Battle Master" then
        return 8;
    end
    
    -- Vanguards get 2d8 per tick at level 11+
    if nLevel >= 10 then
        return 10;
    elseif nLevel >= 18 then
        return 12;
    end
    
    -- Everyone else gets 1d8 per tick
    return 1;
end

-- Functions for character sheet integration
function activateBarrier(nodeChar, nBarrierTicks)
    -- This function can be called from the character sheet
    local nUses = DB.getValue(nodeChar, "barrier_uses", 0);
    if nUses <= 0 then
        return false;
    end
    
    -- Reduce uses by 1
    local nNewUses = nUses - 1;
    DB.setValue(nodeChar, "barrier_uses", "number", nNewUses);
    
    -- Set current barrier ticks on character sheet
    DB.setValue(nodeChar, "barrier", "number", nBarrierTicks);
    
    -- Also update combat tracker if character is in combat
    local nodeCT = ActorManager.getCTNode(nodeChar);
    if nodeCT then
        DB.setValue(nodeCT, "barrier", "number", nBarrierTicks);
        DB.setValue(nodeCT, "barrier_status", "string", nBarrierTicks > 0 and "Yes" or "No");
        
        -- Send OOB message to sync combat tracker updates to all clients
        local msgOOB = {
            type = OOB_MSGTYPE_DEFENSE_UPDATE,
            action = "barrier",
            target = nodeCT.getNodeName(),
            value = nBarrierTicks,
            status = nBarrierTicks > 0 and "Yes" or "No"
        };
        Comm.deliverOOBMessage(msgOOB);
    end
    
    return true;
end

function activateTechArmor(nodeChar, nTechArmorHP)
    -- This function can be called from the character sheet
    local nUses = tonumber(DB.getValue(nodeChar, "techarmor_uses", 0));
    if nUses <= 0 then
        return false;
    end
    
    -- Reduce uses by 1
    local nNewUses = nUses - 1;
    DB.setValue(nodeChar, "techarmor_uses", "number", nNewUses);
    
    -- Use the provided tech armor HP value
    local nTechArmorValue = nTechArmorHP or ((getSentinelLevel(nodeChar) + getAbilityModifier(nodeChar, "intelligence")) * 2);
    
    -- Set current tech armor on character node
    DB.setValue(nodeChar, "tech_armor_hp", "number", nTechArmorValue);
    
    -- Also set on combat tracker node
    local nodeCT = ActorManager.getCTNode(nodeChar);
    if nodeCT then
        DB.setValue(nodeCT, "tech_armor_hp", "number", nTechArmorValue);
        
        -- Send OOB message to sync combat tracker updates to all clients
        local msgOOB = {
            type = OOB_MSGTYPE_DEFENSE_UPDATE,
            action = "techarmor",
            target = nodeCT.getNodeName(),
            value = nTechArmorValue
        };
        Comm.deliverOOBMessage(msgOOB);
    end
    
    return true;
end

function getSentinelLevel(nodeChar)
    -- Get Sentinel class level from the character sheet
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if nodeClasses then
        local aChildren = DB.getChildren(nodeClasses);
        for _, nodeClass in pairs(aChildren) do
            local sClass = DB.getValue(nodeClass, "name", "");
            if sClass == "Sentinel" then
                return DB.getValue(nodeClass, "level", 0);
            end
        end
    end
    
    return 0;
end

function getVanguardNode(nodeTarget)
    -- Try to get from the character sheet classes section (array of classes)
    local sNodePath = DB.getPath(nodeTarget);
    local nodeClasses = DB.findNode(sNodePath .. ".classes");
    
    if nodeClasses then
        -- Check all classes to find if any are Vanguard (or other ME5e classes)
        local nClassCount = DB.getChildCount(nodeClasses);
        local sFirstClass = nil;
        
        -- Get all child nodes and iterate through them (don't assume sequential IDs)
        local aChildren = DB.getChildren(nodeClasses);
        for _, nodeClass in pairs(aChildren) do
            if nodeClass then
                local sClass = DB.getValue(nodeClass, "name", "");
                
                if sClass == "Vanguard" then
                    return nodeClass;
                end
            end
        end
    end
    
    return nil;
end

function rollBarrier(rTarget, nTicksSpent, nDicePerTick, nBarrierDie)
    
    if nTicksSpent <= 0 then
        checkShields(aSource, rTarget, originalMsgOOB);
        return;
    end
    
    -- Calculate total dice to roll
    local nTotalDice = nTicksSpent * nDicePerTick;
    local sDiceNotation = nTotalDice .. "d" .. nBarrierDie;
    
    -- Store the message data for this target
    local targetNodePath;
    if rTarget and rTarget.getNodeName then
        targetNodePath = rTarget.getNodeName();
    elseif rTarget and rTarget.sName then
        targetNodePath = rTarget.sName;
    else
        targetNodePath = "unknown_target_" .. tostring(rTarget);
    end
    
    barrierMsgLookup[targetNodePath] = UtilityManager.copyDeep(originalMsgOOB);
    
    -- Create the roll
    local rRoll = { 
        sType = "barrier_d8", 
        sDesc = "Barrier Defense (" .. nTicksSpent .. " ticks)", 
        aDice = { expr = sDiceNotation }, 
        nMod = 0,
        nTicksSpent = nTicksSpent,
        nDicePerTick = nDicePerTick,
        nBarrierDie = nBarrierDie
    };
    
    ActionsManager.performAction(nil, rTarget, rRoll);
end

function hasWarpAmmoEffect(rSource, rRoll)
    -- Check if the source has an active effect with "Warp Ammo" text (legacy support)
    if not rSource then
        return false;
    end
    
    -- First check for weapon-specific Warp Ammo if we have roll data
    if rRoll and rRoll.sLabel then
        if hasWarpAmmoWeapon(rSource, rRoll.sLabel) then
            return true;
        end
    end
    
    -- Fallback to checking for global Warp Ammo effect (legacy)
    local nodeCT = ActorManager.getCTNode(rSource);
    if not nodeCT then
        return false;
    end
    
    local nodeEffects = nodeCT.getChild("effects");
    if not nodeEffects then
        return false;
    end
    
    local aEffects = DB.getChildren(nodeEffects);
    for _, nodeEffect in pairs(aEffects) do
        local sEffectName = DB.getValue(nodeEffect, "label", "");
        if string.find(string.lower(sEffectName), "warp ammo") then
            return true;
        end
    end
    
    return false;
end

function hasWarpAmmoWeapon(rSource, sWeaponName)
    -- Check if the specific weapon has Warp Ammo property
    if not rSource or not sWeaponName then
        return false;
    end
    
    -- Get the character's weapon list
    local nodeSource = ActorManager.getCreatureNode(rSource);
    if not nodeSource then
        return false;
    end
    
    local nodeWeaponList = nodeSource.getChild("weaponlist");
    if not nodeWeaponList then
        return false;
    end
    
    -- Search through weapons for one matching the name
    local aWeapons = DB.getChildren(nodeWeaponList);
    
    for _, nodeWeapon in pairs(aWeapons) do
        local sWeaponNameFromList = DB.getValue(nodeWeapon, "name", "");
        if sWeaponNameFromList == sWeaponName then
            -- Check if this weapon has Warp Ammo enabled (checkbox)
            local bWarpAmmo = DB.getValue(nodeWeapon, "warpammo", 0) == 1;
            
            -- If checkbox not set, check properties text field as fallback
            if not bWarpAmmo then
                local sProperties = DB.getValue(nodeWeapon, "properties", "");
                bWarpAmmo = string.find(string.lower(sProperties), "warp ammo") ~= nil;
            end
            
            return bWarpAmmo;
        end
    end
    
    return false;
end

function handleWarpAmmo(nDamage, rTarget, rRoll)
    -- Warp Ammo: Remove 2 barrier ticks, no damage reduction
    local nTicksSpent = math.min(2, nBarrier);
    local nBarrierTicks = nBarrier - nTicksSpent;
    local sBarrierStatus;
    
    if nBarrierTicks > 0 then
        sBarrierStatus = "Yes";
    end

    DB.setValue(aCTNode, "barrier", "number", nBarrierTicks);
    DB.setValue(aCTNode, "barrier_status", "string", sBarrierStatus);
    
    -- Send Warp Ammo message
    sendWarpAmmoBarrierMessage(nDamage, rTarget, rRoll, nTicksSpent);
end

function sendWarpAmmoBarrierMessage(nDamage, rSource, rRoll, nTicksSpent)
    
    local msg = { font = "msgfont", icon = "roll_barrier" };

    msg.text = string.format("[Warp Ammo] Barrier bypassed - " .. nTicksSpent .. " barrier ticks removed, no damage reduction.");

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);

    -- Send a special message for Warp Ammo barrier interaction
    --local rMessage = ActionsManager.createActionMessage(rSource, nil);
    
    --rMessage.text = "[WARP AMMO] Barrier bypassed - " .. nTicksSpent .. " barrier ticks removed, no damage reduction.";
    
    --Comm.deliverChatMessage(rMessage);
end

function handleBarrier(rSource, rTarget, rRoll, msg)
    -- Get the message data from the lookup table
    -- Try multiple approaches to find the right key
    local localMsgOOB = nil;
    local localCTNode = aCTNode;
    local foundKey = nil;
    
    -- First, try the same approach as rollBarrier
    local sourceNodePath;
    if rSource and rSource.getNodeName then
        sourceNodePath = rSource.getNodeName();
    elseif rSource and rSource.sName then
        sourceNodePath = rSource.sName;
    else
        sourceNodePath = "unknown_target_" .. tostring(rSource);
    end

    localMsgOOB = barrierMsgLookup[sourceNodePath];
    
    -- Defensive check: ensure we have message data
    if not localMsgOOB then
        Debug.console("ERROR: msgOOB is nil in handleBarrier for target:", sourceNodePath);
        Debug.console("Available keys in barrierMsgLookup:");
        for k, v in pairs(barrierMsgLookup) do
            Debug.console("  Key:", k, "Value:", v);
        end
        Debug.console("Tried key:", sourceNodePath);
        return;
    end
    
    local nDamage = localMsgOOB.nTotal;
    local nBarrierHp = rRoll.nTotal;
    local nTicksSpent = rRoll.nTicksSpent or 1; -- Fallback for old rolls
    local nBarrierTicks = nBarrier - nTicksSpent;
    local sBarrierStatus;
    
    remainingDamage = nDamage - nBarrierHp;
    
    -- Track the amount reduced
    nDamageReduction = nDamageReduction + rRoll.nTotal;

    if remainingDamage < 0 then
        remainingDamage = 0;
    end

    sendBarrierMessage(nDamage, rRoll.nTotal, rSource, rRoll, nTicksSpent);

    if nBarrierTicks > 0 then
        sBarrierStatus = "Yes";
    end

    
    local sSourceNodeType, nodeSource = ActorManager.getTypeAndNode(rSource);
    if nodeSource then
        if sSourceNodeType == "pc" then
            localCTNode = ActorManager.getCTNode(rSource);
        else
            localCTNode = nodeSource;
        end
    end

    

    nBarrier = nBarrierTicks;
    DB.setValue(localCTNode, "barrier", "number", nBarrierTicks);
    DB.setValue(localCTNode, "barrier_status", "string", sBarrierStatus);
    localMsgOOB.nTotal = remainingDamage;

    checkShields(aSource, aTarget, localMsgOOB);
    
    barrierMsgLookup[sourceNodePath] = nil;
end

-- Handle barrier choice request from server (client-side)
function handleBarrierChoiceRequest(msgOOB)
    local sMessage = msgOOB.message;
    local nBarrier = msgOOB.barrier;
    local nDicePerTick = msgOOB.dicePerTick;
    local nBarrierDie = msgOOB.barrierDie;
    local sTarget = msgOOB.target;
    
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
            local value = selection[1];
            local nTicksSpent = 0;
            
            if value == "No Barrier (0 ticks)" then
                nTicksSpent = 0;
            elseif value == "1 Tick" then
                nTicksSpent = 1;
            else
                local nTicks = tonumber(string.match(value, "(%d+) Ticks"));
                if nTicks then
                    nTicksSpent = nTicks;
                end
            end
            
            -- Send response back to server
            local msgResponse = {
                type = OOB_MSGTYPE_BARRIER_RESPONSE,
                target = sTarget,
                ticks = nTicksSpent,
                dicePerTick = nDicePerTick,
                barrierDie = nBarrierDie
            };
            Comm.deliverOOBMessage(msgResponse);
        end,
        showmodule = false,
    };
    
    DialogManager.requestSelectionDialog(tDialogData);
end

-- Handle barrier choice response from client (server-side)
function handleBarrierChoiceResponse(msgOOB)
    local sTarget = msgOOB.target;
    local nTicksSpent = tonumber(msgOOB.ticks);
    local nDicePerTick = tonumber(msgOOB.dicePerTick);
    local nBarrierDie = tonumber(msgOOB.barrierDie);
    
    local rTarget = ActorManager.resolveActor(sTarget);
    if not rTarget then
        return;
    end
    
    if nTicksSpent == 0 then
        -- No barrier
        checkShields(aSource, rTarget, originalMsgOOB);
    else
        -- Use selected amount
        rollBarrier(rTarget, nTicksSpent, nDicePerTick, nBarrierDie);
    end
end

-- Handle defense updates from other clients
function handleDefenseUpdate(msgOOB)
    local sAction = msgOOB.action;
    local sTarget = msgOOB.target;
    local nValue = tonumber(msgOOB.value);
    local sStatus = msgOOB.status;
    
    -- Find the combat tracker node
    local nodeCT = DB.findNode(sTarget);
    if not nodeCT then
        return;
    end
    
    if sAction == "barrier" then
        DB.setValue(nodeCT, "barrier", "number", nValue);
        if sStatus then
            DB.setValue(nodeCT, "barrier_status", "string", sStatus);
        end
    elseif sAction == "techarmor" then
        DB.setValue(nodeCT, "tech_armor_hp", "number", nValue);
    end
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

function hasShieldLightningImmunity(nodeCT)
    -- Check if character has shields immune to lightning vulnerability
    -- Look for the specific effect "Tough Shields"
    if not nodeCT then
        return false;
    end
    
    -- Check for specific effect name that indicates lightning immunity
    local nodeEffects = nodeCT.getChild("effects");
    if nodeEffects then
        local aEffects = DB.getChildren(nodeEffects);
        for _, nodeEffect in pairs(aEffects) do
            local sEffectName = DB.getValue(nodeEffect, "label", "");
            local sEffectActive = DB.getValue(nodeEffect, "isactive", "");
            
            -- Check for "Tough Shields" effect
            if sEffectActive == 1 and sEffectName == "Tough Shields" then
                return true;
            end
        end
    end
    
    return false;
end

function applyShieldDamage(nShieldHP, nRollDamage, remainingDamage, nBlocked, nDamageReduction)
    -- Common shield damage application logic
    local nNewShieldHP = nShieldHP;
    local nNewRemainingDamage = remainingDamage;
    local nNewBlocked = nBlocked;
    local nNewDamageReduction = nDamageReduction;
    
    if nRollDamage >= nShieldHP then
        nNewRemainingDamage = nNewRemainingDamage - nShieldHP;
        nNewBlocked = nNewBlocked + nShieldHP;
        nNewDamageReduction = nNewDamageReduction + nShieldHP;
    else
        nNewRemainingDamage = nNewRemainingDamage - nRollDamage;
        nNewBlocked = nNewBlocked + nRollDamage;
        nNewDamageReduction = nNewDamageReduction + nRollDamage;
    end
    nNewShieldHP = nNewShieldHP - nRollDamage;
    
    return nNewShieldHP, nNewRemainingDamage, nNewBlocked, nNewDamageReduction;
end

function handleShields(rRoll, rSource, rTarget)
    local nDamage = originalMsgOOB.nTotal;
    local nShieldHP = nShields;
    local nBlocked = 0;
    local sShieldsStatus;
    local nLightningBlocked = 0;
    local remainingDamage = nDamage;
    local bLightningImmune = hasShieldLightningImmunity(aCTNode);

    for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]") do
        local nRollDamage = tonumber(sDamageSubTotal);

        if nRollDamage > remainingDamage then
            nRollDamage = remainingDamage;
        end

        if sDamageType ~= "lightning" and nShieldHP > 0 then
            -- Normal damage types - apply standard shield damage
            nShieldHP, remainingDamage, nBlocked, nDamageReduction = applyShieldDamage(nShieldHP, nRollDamage, remainingDamage, nBlocked, nDamageReduction);
            
        elseif sDamageType == "lightning" and nShieldHP > 0 then
            if bLightningImmune then
                -- Shields are immune to lightning vulnerability - treat as normal damage
                nShieldHP, remainingDamage, nBlocked, nDamageReduction = applyShieldDamage(nShieldHP, nRollDamage, remainingDamage, nBlocked, nDamageReduction);
            else
                -- Lightning does double damage to shields - double the effective damage
                local nEffectiveDamage = nRollDamage * 2;
                local nHalfShielsHP = math.ceil(nShieldHP / 2);
                
                if nEffectiveDamage >= nShieldHP then
                    -- Lightning destroys all shields
                    remainingDamage = remainingDamage - nHalfShielsHP;
                    nBlocked = nBlocked + nShieldHP;
                    nDamageReduction = nDamageReduction + nHalfShielsHP;
                    nLightningBlocked = nLightningBlocked + nHalfShielsHP;
                    nShieldHP = 0;
                else
                    -- Lightning partially damages shields
                    remainingDamage = remainingDamage - nHalfShielsHP;
                    nBlocked = nBlocked + nEffectiveDamage;
                    nDamageReduction = nDamageReduction + nHalfShielsHP;
                    nLightningBlocked = nLightningBlocked + nRollDamage;
                    nShieldHP = nShieldHP - nEffectiveDamage;
                end
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

    sendShieldMessage(nBlocked, rSource, rTarget, nLightningBlocked, bLightningImmune);

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
    local nBarrierDie = rRoll.nBarrierDie or 8;
    local nTotalDice = (nTicksSpent or 1) * nDicePerTick;
    local sDiceNotation = nTotalDice .. "d" .. nBarrierDie;
    
    rMessage.icon = "roll_barrier";
    rMessage.text = "[Defense] Biotic Barrier";
    
    if nTicksSpent > 1 then
        rMessage.text = string.format("%s  (%d ticks)", rMessage.text, nTicksSpent);
    end

    Comm.deliverChatMessage(rMessage);
end

function sendTechArmorMessage(nBlocked, rSource, rTarget, rRoll)
    Debug.console("Tech Armor Message");
    Debug.console(rTarget);
    local msg = { font = "msgfont", icon = "roll_tech_armor" };

    msg.text = string.format("[Defense] Tech Armor [%s] -> [from %s]", nBlocked, rTarget.sName);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendShieldMessage(nBlocked, rSource, rTarget, nLightningBlocked, bLightningImmune)
    local msg = { font = "msgfont", icon = "roll_shields" };
    local sTitle = "Kinetic Shields";

    if bLightningImmune then
        sTitle = "Lightning Resistant Shields";
    end

    msg.text = string.format("[Defense] %s [%s] -> [from %s]", sTitle, nBlocked, rTarget.sName);

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

function sendRemainingDamageMessage(localMsgOOB)
    local msg = { font = "msgfont" };

    msg.text = string.format("Remaining damage: %s", localMsgOOB.nTotal);

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

-- ========================================
-- VENTING SYSTEM FUNCTIONS
-- ========================================

-- Initialize ammo tracking for a character
function initializeAmmoTracking(charNode)
    if not charNode then return end;
    
    -- Use the character sheet path as the ID for tracking
    local charId = charNode.getNodeName();
    if not weaponAmmoTracker[charId] then
        weaponAmmoTracker[charId] = {};
    end
    
    -- Get all weapons from the character's weaponlist
    local nodeWeaponList = DB.findNode(charNode.getPath() .. ".weaponlist");
    if nodeWeaponList then
        local weaponList = DB.getChildList(nodeWeaponList);
        for _, weaponNode in ipairs(weaponList) do
            if weaponNode then
                local weaponName = DB.getValue(weaponNode, "name", "");
                local usedAmmo = DB.getValue(weaponNode, "ammo", 0);
                local maxAmmo = DB.getValue(weaponNode, "maxammo", 0);
                local carried = DB.getValue(weaponNode, "carried", 0);
                
                -- Initialize tracking for equipped weapons with ammo capacity
                if carried == 2 and maxAmmo > 0 then
                    if not weaponAmmoTracker[charId][weaponName] then
                        weaponAmmoTracker[charId][weaponName] = {
                            lastUsedAmmo = usedAmmo,
                            firedThisRound = false
                        };
                    else
                        -- Update the used ammo count
                        weaponAmmoTracker[charId][weaponName].lastUsedAmmo = usedAmmo;
                    end
                end
            end
        end
    end
end

-- Track weapon firing (called when a weapon is used)
function trackWeaponFiring(actorNode, weaponName)
    if not actorNode or not weaponName then return end;
    
    local actorId = actorNode.getNodeName();
    if weaponAmmoTracker[actorId] and weaponAmmoTracker[actorId][weaponName] then
        weaponAmmoTracker[actorId][weaponName].firedThisRound = true;
    end
end

-- Process venting at the start of each character's turn
function processVenting(actorNode)
    -- Only process if venting is enabled
    if OptionsManager.getOption("ME5E_HEAT_HANDLING") ~= "venting" then return end;

    if not actorNode then 
        return;
    end
    
    -- Get the actual character sheet from the combat tracker entry
    local sClass, sRecord = DB.getValue(actorNode, "link");
    if not sClass or not sRecord or sClass ~= "charsheet" then
        return;
    end
    
    local charNode = DB.findNode(sRecord);
    if not charNode then
        return;
    end
    
    -- Use character sheet ID for tracking (more reliable than combat tracker ID)
    local charId = charNode.getNodeName();
    if not weaponAmmoTracker[charId] then
        initializeAmmoTracking(charNode);
        return;
    end
    
    -- Get all weapons from the character's weaponlist
    local nodeWeaponList = DB.findNode(charNode.getPath() .. ".weaponlist");
    if not nodeWeaponList then 
        return;
    end
    
    local weaponList = DB.getChildList(nodeWeaponList);
    
    for _, weaponNode in ipairs(weaponList) do
        if weaponNode then
            local weaponName = DB.getValue(weaponNode, "name", "");
            local usedAmmo = DB.getValue(weaponNode, "ammo", 0);
            local maxAmmo = DB.getValue(weaponNode, "maxammo", 0);
            local carried = DB.getValue(weaponNode, "carried", 0);
            
            -- Only process equipped weapons that have ammo capacity (carried = 2 and maxAmmo > 0)
            if carried == 2 and maxAmmo > 0 then
                -- Initialize tracking if this weapon isn't being tracked yet
                if not weaponAmmoTracker[charId][weaponName] then
                    weaponAmmoTracker[charId][weaponName] = {
                        lastUsedAmmo = usedAmmo,
                        firedThisRound = false
                    };
                end
                
                local tracking = weaponAmmoTracker[charId][weaponName];
                
                -- Check if weapon was fired this round (compare current vs last known ammo)
                local wasFired = (usedAmmo > tracking.lastUsedAmmo);
                
                if not wasFired then
                    -- Weapon wasn't fired, regenerate 1 ammo (reduce used ammo by 1)
                    if usedAmmo > 0 then
                        local newUsedAmmo = math.max(usedAmmo - 1, 0);
                        DB.setValue(weaponNode, "ammo", "number", newUsedAmmo);
                        
                        -- Send individual message for each weapon that vents
                        ChatManager.SystemMessage("[Venting] " .. weaponName .. " vented 1 heat");
                    end
                end
                
                -- Always update tracking to current ammo count for next round
                tracking.lastUsedAmmo = DB.getValue(weaponNode, "ammo", 0);
                tracking.firedThisRound = false;
            end
        end
    end
    
end

-- Hook into Fantasy Grounds turn start events
function onTurnStart(nodeEntry)
    if not nodeEntry then
        return;
    end
    
    -- Process venting for this character
    processVenting(nodeEntry);
end