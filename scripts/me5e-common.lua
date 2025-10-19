--
-- Overriding common items from 5e
-- Creature types, creature sub types, conditions, classes, currencies, skills
--

local testingVariable = nil;

function onInit()
    --Debug.console(GameSystem.languages);

    creaturesubtype = {
        "synth-Organic",
        "organic",
        "synthetic",
    };
    -- NOTE: Multi-word types must come before single word types
    creaturetype = {
        "blood pack",
        "blue suns",
        "tracker beast",
        "alien",
        "cerberus",
        "collectors",
        "eclipse",
        "geth",
        "kett",
        "mech",
        "n7",
        "rachni",
        "reaper",
        "red army",
        "thorian",
    };

    conditions = {
        "blinded",
        "charmed",
        "deafened",
        "encumbered",
        "frightened",
        "frozen",
        "grappled",
        "incapacitated",
        "intoxicated",
        "invisible",
        "lifted",
        "paralyzed",
        "poisoned",
        "primed cold",
        "primed fire",
        "primed force",
        "primed lightning",
        "primed necrotic",
        "primed radiant",
        "primed: cold",
        "primed: fire",
        "primed: force",
        "primed: lightning",
        "primed: necrotic",
        "primed: radiant",
        "prone",
        "restrained",
        "stable",
        "stunned",
        "targeting",
        "unconscious",
    };

    condcomps = {
        ["blinded"] = "cond_blinded",
        ["charmed"] = "cond_charmed",
        ["deafened"] = "cond_deafened",
        ["encumbered"] = "cond_encumbered",
        ["frightened"] = "cond_frightened",
        ["frozen"] = "cond_slowed",
        ["grappled"] = "cond_grappled",
        ["incapacitated"] = "cond_paralyzed",
        ["invisible"] = "cond_invisible",
        ["lifted"] = "cond_lifted",
        ["paralyzed"] = "cond_paralyzed",
        ["primed cold"] = "Primed: Cold",
        ["primed fire"] = "Primed: Fire", 
        ["primed force"] = "Primed: Force",
        ["primed lightning"] = "Primed: Lightning",
        ["primed necrotic"] = "Primed: Necrotic",
        ["primed radiant"] = "Primed: Radiant",
        ["primed: cold"] = "cond_dazed",
        ["primed: fire"] = "cond_dazed",
        ["primed: force"] = "cond_dazed",
        ["primed: lightning"] = "cond_dazed",
        ["primed: necrotic"] = "cond_dazed",
        ["primed: radiant"] = "cond_dazed",
        ["Primed: Cold"] = "cond_dazed",
        ["Primed: Fire"] = "cond_dazed",
        ["Primed: Force"] = "cond_dazed", 
        ["Primed: Lightning"] = "cond_dazed",
        ["Primed: Necrotic"] = "cond_dazed",
        ["Primed: Radiant"] = "cond_dazed",
        ["prone"] = "cond_prone",
        ["restrained"] = "cond_restrained",
        ["stunned"] = "cond_stunned",
        ["targeting"] = "cond_targeting",
        ["unconscious"] = "cond_unconscious",
        -- Similar to conditions
        ["cover"] = "cond_cover",
        ["scover"] = "cond_cover",
        -- ADV
        ["advatk"] = "cond_advantage",
        ["advchk"] = "cond_advantage",
        ["advskill"] = "cond_advantage",
        ["advinit"] = "cond_advantage",
        ["advsav"] = "cond_advantage",
        ["advdeath"] = "cond_advantage",
        ["grantdisatk"] = "cond_advantage",
        -- DIS
        ["disatk"] = "cond_disadvantage",
        ["dischk"] = "cond_disadvantage",
        ["disskill"] = "cond_disadvantage",
        ["disinit"] = "cond_disadvantage",
        ["dissav"] = "cond_disadvantage",
        ["disdeath"] = "cond_disadvantage",
        ["grantadvatk"] = "cond_disadvantage",
        -- Mass Effect
        ["bypbarrier"] = "cond_bypass_barrier",
    };

    -- Skills
    -- Added: Electronics, Engineering, Science, Vehicle Handling
    -- Removed: Animal Handling, Arcana, Nature, Religion
    skilldata = {
        [Interface.getString("skill_value_acrobatics")] = { lookup = "acrobatics", stat = 'dexterity' },
        [Interface.getString("skill_value_athletics")] = { lookup = "athletics", stat = 'strength' },
        [Interface.getString("skill_value_deception")] = { lookup = "deception", stat = 'charisma' },
        [Interface.getString("skill_value_electronics")] = { lookup = "electronics", stat = 'intelligence' },
        [Interface.getString("skill_value_engineering")] = { lookup = "engineering", stat = 'intelligence' },
        [Interface.getString("skill_value_history")] = { lookup = "history", stat = 'intelligence' },
        [Interface.getString("skill_value_insight")] = { lookup = "insight", stat = 'wisdom' },
        [Interface.getString("skill_value_intimidation")] = { lookup = "intimidation", stat = 'charisma' },
        [Interface.getString("skill_value_investigation")] = { lookup = "investigation", stat = 'intelligence' },
        [Interface.getString("skill_value_medicine")] = { lookup = "medicine", stat = 'wisdom' },
        [Interface.getString("skill_value_perception")] = { lookup = "perception", stat = 'wisdom' },
        [Interface.getString("skill_value_performance")] = { lookup = "performance", stat = 'charisma' },
        [Interface.getString("skill_value_persuasion")] = { lookup = "persuasion", stat = 'charisma' },
        [Interface.getString("skill_value_science")] = { lookup = "science", stat = 'intelligence' },
        [Interface.getString("skill_value_sleightofhand")] = { lookup = "sleightofhand", stat = 'dexterity' },
        [Interface.getString("skill_value_stealth")] = { lookup = "stealth", stat = 'dexterity', disarmorstealth = 1 },
        [Interface.getString("skill_value_survival")] = { lookup = "survival", stat = 'wisdom' },
        [Interface.getString("skill_value_vehiclehandling")] = { lookup = "vehiclehandling", stat = 'dexterity' },
    };

    psskilldata = {
        Interface.getString("skill_value_acrobatics"),
        Interface.getString("skill_value_athletics"),
        Interface.getString("skill_value_deception"),
        Interface.getString("skill_value_electronics"),
        Interface.getString("skill_value_engineering"),
        Interface.getString("skill_value_history"),
        Interface.getString("skill_value_insight"),
        Interface.getString("skill_value_intimidation"),
        Interface.getString("skill_value_investigation"),
        Interface.getString("skill_value_medicine"),
        Interface.getString("skill_value_perception"),
        Interface.getString("skill_value_performance"),
        Interface.getString("skill_value_persuasion"),
        Interface.getString("skill_value_science"),
        Interface.getString("skill_value_sleightofhand"),
        Interface.getString("skill_value_stealth"),
        Interface.getString("skill_value_survival"),
        Interface.getString("skill_value_vehiclehandling"),
    };

    classes = {
        "adept",
        "engineer",
        "experiment",
        "explorer",
        "infiltrator",
        "musician",
        "sentinel",
        "soldier",
        "tracker",
        "vanguard",
    };

    class_nametovalue = {
        [Interface.getString("class_value_adept")] = "adept",
        [Interface.getString("class_value_engineer")] = "engineer",
        [Interface.getString("class_value_experiment")] = "experiment",
        [Interface.getString("class_value_explorer")] = "explorer",
        [Interface.getString("class_value_infiltrator")] = "infiltrator",
        [Interface.getString("class_value_musician")] = "musician",
        [Interface.getString("class_value_sentinel")] = "sentinel",
        [Interface.getString("class_value_soldier")] = "soldier",
        [Interface.getString("class_value_tracker")] = "tracker",
        [Interface.getString("class_value_vanguard")] = "vanguard",
    };

    class_valuetoname = {
        ["adept"] = Interface.getString("class_value_adept"),
        ["engineer"] = Interface.getString("class_value_engineer"),
        ["experiment"] = Interface.getString("class_value_experiment"),
        ["explorer"] = Interface.getString("class_value_explorer"),
        ["infiltrator"] = Interface.getString("class_value_infiltrator"),
        ["musician"] = Interface.getString("class_value_musician"),
        ["sentinel"] = Interface.getString("class_value_sentinel"),
        ["soldier"] = Interface.getString("class_value_soldier"),
        ["tracker"] = Interface.getString("class_value_tracker"),
        ["vanguard"] = Interface.getString("class_value_vanguard"),
    };

    currencies = {
        { name = Interface.getString("currency_value_credits"), weight = 0.00, value = 1 },
        { name = Interface.getString("currency_value_omnigel"), weight = 0.01, value = 1 },
    };

    -- Item Filters
    itemFilters = LibraryData5E.aRecordOverrides;
    itemFilters["item"]["aCustomFilters"]["Sub Type"] = { sField = "subtype" };
    itemFilters["npc"]["aCustomFilters"]["Language"] = { sField = "languages" };

    -- Conditions
    conditions = DataCommon.conditions;
    table.insert(conditions, "frozen");
    table.insert(conditions, "lifted");
    table.insert(conditions, "indoctrinated");
    table.insert(conditions, "targeting");
    table.insert(conditions, "primed cold");
    table.insert(conditions, "primed fire");
    table.insert(conditions, "primed force");
    table.insert(conditions, "primed lightning");
    table.insert(conditions, "primed necrotic");
    table.insert(conditions, "primed radiant");
    table.insert(conditions, "primed: cold");
    table.insert(conditions, "primed: fire");
    table.insert(conditions, "primed: force");
    table.insert(conditions, "primed: lightning");
    table.insert(conditions, "primed: necrotic");
    table.insert(conditions, "primed: radiant");

    -- "Push" data changes in this file to the packages - overwriting the original base data.
    DataCommon.skilldata = skilldata;
    DataCommon.psskilldata = psskilldata;
    DataCommon.creaturetype = creaturetype;
    DataCommon.creaturesubtype = creaturesubtype;
    --DataCommon.conditions = conditions;
    DataCommon.condcomps = condcomps;
    DataCommon.classes = classes;
    DataCommon.class_nametovalue = class_nametovalue;
    DataCommon.class_valuetoname = class_valuetoname;
    GameSystem.currencies = currencies;
    GameSystem.currencyDefault = Interface.getString("currency_value_credits");
    --GameSystem.currencies = { Interface.getString("currency_value_cr") };
    --GameSystem.currencyDefault = Interface.getString("currency_value_cr");

    ImageDeathMarkerManager.registerStandardDeathMarkersDnD();
end