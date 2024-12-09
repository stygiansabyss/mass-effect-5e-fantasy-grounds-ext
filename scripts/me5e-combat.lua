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

    ActionDamage.messageDamage = messageDamage;
    ActionDamage.handleApplyDamage(msgOOB);
end

function messageDamage(rSource, rTarget, rRoll)
    -- Set the global roll to the damage roll.
    aDamageRoll = rRoll;
    aSource = rSource;
    aTarget = rTarget;
    
    Debug.console(rRoll);
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
        rollBarrier(rTarget);
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
    if nTechArmor > 0 and aDamageRoll.nTotal > 0 then
        handleTechArmor(aDamageRoll, rSource, rTarget);
    end

    -- Shields do not work on melee damage.
    if nShields > 0 and aDamageRoll.nTotal > 0 and aDamageRoll.range ~= "M" then
        handleShields(aDamageRoll, rSource, rTarget);
    end

    if aDamageRoll.nTotal == 0 then
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
    ActionDamage.messageDamage = originalMessageDamage;
    ActionDamage.messageDamage(aSource, aTarget, aDamageRoll);

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

function rollBarrier(rTarget)
    local rRoll = { sType = "barrier_d8", sDesc = "Barrier Defense", aDice = { "d8" }, nMod = 0 };
    ActionsManager.performAction(nil, rTarget, rRoll);
end

function handleBarrier(rSource, rTarget, rRoll)
    local nDamage = aDamageRoll.nTotal;
    local nBarrierHp = rRoll.nTotal;
    local nBarrierTicks = nBarrier - 1;
    local sBarrierStatus;

    if nBarrierTicks > 0 then
        sBarrierStatus = "Yes";
    end

    remainingDamage = nDamage - nBarrierHp;
    nBarrierHp = nBarrierHp - nDamage;

    -- Track the amount reduced
    nDamageReduction = nDamageReduction + rRoll.nTotal;

    if remainingDamage < 0 then
        remainingDamage = 0;
    end

    sendBarrierMessage(nDamage, rRoll.nTotal, rSource, rRoll);

    nBarrier = nBarrierTicks;
    DB.setValue(aCTNode, "barrier", "number", nBarrierTicks);
    DB.setValue(aCTNode, "barrier_status", "string", sBarrierStatus);
    aDamageRoll.nTotal = remainingDamage;

    checkShields(aSource, rSource);
end

function handleTechArmor(rRoll, rSource, rTarget)
    local nDamage = rRoll.nTotal;
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
    aDamageRoll.nTotal = remainingDamage;
end

function handleShields(rRoll, rSource, rTarget)
    local nDamage = rRoll.nTotal;
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
            -- Lighting does double damage to shields
            -- To handle this, we will half the remaining shields.
            local nTempDamage = nRollDamage * 2;
            if nTempDamage >= nShieldHP then
                remainingDamage = remainingDamage - nShieldHP;
                nBlocked = nBlocked + nShieldHP;
                nLightningBlocked = nLightningBlocked + nShieldHP;
                nDamageReduction = nDamageReduction + nShieldHP;
            else
                remainingDamage = remainingDamage - (nTempDamage / 2);
                nBlocked = nBlocked + nTempDamage;
                nLightningBlocked = nLightningBlocked + nTempDamage;
                nDamageReduction = nDamageReduction + nRollDamage;
            end
            nShieldHP = nShieldHP - nTempDamage;
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
    aDamageRoll.nTotal = remainingDamage;
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

function sendBarrierMessage(rDamage, rDefenseHP, rTarget, rRoll)
    local nBlocked;
    local rMessage = ActionsManager.createActionMessage(rTarget, rRoll);

    if rDamage >= rDefenseHP then
        nBlocked = rDefenseHP;
    else
        nBlocked = rDamage;
    end

    rMessage.icon = "roll_barrier";
    rMessage.text = string.format("[Defense] %s [1d8=%s]", "Biotic Barrier", nBlocked);

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
    local isHalf = aDamageRoll.sResults:match("%[HALF%]");
    local sHalf = " ";

    if isHalf then
        sHalf = '[HALF] ';
    end

    msg.text = string.format("Defending against %sdamage: %s", sHalf, aDamageRoll.nTotal);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msg, msg);
end

function sendRemainingDamageMessage()
    local msg = { font = "msgfont" };

    msg.text = string.format("Remaining damage: %s", aDamageRoll.nTotal);

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