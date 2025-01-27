
POWERCASTING_SLOT_LEVELS = 5;
TECH_SLOT_LEVELS = 6;

function onInit()
    CharClassManager.SPELLCASTING_SLOT_LEVELS = POWERCASTING_SLOT_LEVELS;
    CharClassManager.PACTMAGIC_SLOT_LEVELS = TECH_SLOT_LEVELS;
    CharClassManager.helperAddClassAdjustSpellSlots = helperAddClassAdjustSpellSlots;
end

function helperAddClassAdjustSpellSlots(rAdd)
    Debug.console("Successfully hijacked.");
    Debug.console(rAdd);
    -- TODO: Give spell levels by class.  ME5e doesnt seem to use a formal system.  So by class may be necessary
end