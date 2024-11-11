--
-- Combat overrides
-- Defenses (barrier, tech armor, shields)
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
local originalMsgOOB;
local originalApplyDamage;
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
end

function handleApplyDamage(msgOOB)

    originalMsgOOB = msgOOB;

    ActionDamage.applyDamage = applyDamage;
    ActionDamage.handleApplyDamage(msgOOB);
end

function applyDamage(rSource, rTarget, rRoll)
    if rRoll.sType ~= "damage" then
        sendBackTo5e();
        return ;
    end

    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    if not nodeTarget then
        sendBackTo5e();
        return ;
    end

    -- Set the global roll to the damage roll.
    aDamageRoll = rRoll;
    aSource = rSource;
    aTarget = rTarget;

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

    -- Barrier has to be handled uniquely since it requires a roll.
    --local bBypassBarrier = hasEffect("BYPBARRIER");
    --
    --if bBypassBarrier then
    --    sendBypassMessage("Barrier");
    --    removeEffect("BYPBARRIER");
    --end

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
    if nShields > 0 and aDamageRoll.nTotal > 0 and aDamageRoll.range == "R" then
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
        fixOriginalMsg(remainingDamage);
    end

    sendBackTo5e();
end

function sendBackTo5e()
    ActionDamage.applyDamage = originalApplyDamage;
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
    local msgShort = { font = "msgfont" };
    local msgLong = { font = "msgfont" };

    if sType == "Barrier" then
        msgShort.icon = "roll_barrier";
        msgLong.icon = "roll_barrier";
    elseif sType == "Tech Armor" then
        msgShort.icon = "roll_tech_armor";
        msgLong.icon = "roll_tech_armor";
    else
        msgShort.icon = "roll_shields";
        msgLong.icon = "roll_shields";
    end

    msgShort.text = string.format("[Defense] %s BYPASSED", sType);
    msgLong.text = string.format("[Defense] %s BYPASSED", sType);

    ActionsManager.outputResult(aDamageRoll.bSecret, aSource, aTarget, msgLong, msgShort);
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
    local msgShort = { font = "msgfont", icon = "roll_tech_armor" };
    local msgLong = { font = "msgfont", icon = "roll_tech_armor" };

    msgShort.text = string.format("[Defense] %s [%s] -> [from %s]", "Tech Armor", nBlocked, rTarget.sName);
    msgLong.text = string.format("[Defense] %s [%s] -> [from %s]", "Tech Armor", nBlocked, rTarget.sName);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

function sendShieldMessage(nBlocked, rSource, rTarget, nLightningBlocked)
    local msgShort = { font = "msgfont", icon = "roll_shields" };
    local msgLong = { font = "msgfont", icon = "roll_shields" };

    msgShort.text = string.format("[Defense] %s [%s] -> [from %s]", "Kinetic Shields", nBlocked, rTarget.sName);
    msgLong.text = string.format("[Defense] %s [%s] -> [from %s]", "Kinetic Shields", nBlocked, rTarget.sName);

    if nLightningBlocked > 0 then
        msgShort.text = string.format("%s [Lightning Damage: %s]", msgShort.text, nLightningBlocked);
        msgLong.text = string.format("%s [Lightning Damage: %s]", msgLong.text, nLightningBlocked);
    end

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

function sendRemainingDamageMessage()
    local msgShort = { font = "msgfont" };
    local msgLong = { font = "msgfont" };

    msgShort.text = string.format("Remaining damage: %s", aDamageRoll.nTotal);
    msgLong.text = string.format("Remaining damage: %s", aDamageRoll.nTotal);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

function sendNoDamageMessage()
    local msgShort = { font = "msgfont", icon = "roll_damage" };
    local msgLong = { font = "msgfont", icon = "roll_damage" };

    msgShort.text = string.format("[Damage (%s)] %s [0] -> [to %s][ABSORBED]", aDamageRoll.sRange, aDamageRoll.sLabel, aTarget.sName);
    msgLong.text = string.format("[Damage (%s)] %s [0] -> [to %s][ABSORBED]", aDamageRoll.sRange, aDamageRoll.sLabel, aTarget.sName);

    ActionsManager.outputResult(aDamageRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end