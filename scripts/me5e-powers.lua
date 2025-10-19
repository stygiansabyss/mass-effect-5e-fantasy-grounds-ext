--
-- ME5e Power Management
-- Handles power parsing extensions and primed condition recognition
--

local originalParseEffects = nil;

function onInit()
    -- Try to override the global parseEffects function directly
    -- Following the pattern from me5e-ps2.lua and me5e-combat.lua
    setupPowerOverrides();
end

function setupPowerOverrides()
    -- Check if parseEffects function exists in global scope
    if parseEffects then
        originalParseEffects = parseEffects;
        parseEffects = parseEffectsWithPrimed;
        return true;
    else
        -- Try alternative approaches - maybe it's in a different namespace
        if PowerManager and PowerManager.parseEffects then
            originalParseEffects = PowerManager.parseEffects;
            PowerManager.parseEffects = parseEffectsWithPrimed;
            return true;
        end
        
        -- Try to use a more direct approach - set up multiple retry attempts
        setupRetryMechanism();
        return false;
    end
end

function setupRetryMechanism()
    -- Create a retry counter
    local retryCount = 0;
    local maxRetries = 10;
    
    -- Try immediate retry first
    local function tryRetry()
        retryCount = retryCount + 1;
        
        if parseEffects then
            originalParseEffects = parseEffects;
            parseEffects = parseEffectsWithPrimed;
            return true;
        elseif retryCount < maxRetries then
            -- Register another retry
            if TimerManager then
                TimerManager.registerCallback(tryRetry, 500); -- Try every 500ms
            end
        end
        return false;
    end
    
    -- Start the retry process
    if TimerManager then
        TimerManager.registerCallback(tryRetry, 500);
    end
end

function parseEffectsWithPrimed(sPowerName, aWords)
    -- Call the original function first to handle normal condition parsing
    local effects = {};
    if originalParseEffects then
        effects = originalParseEffects(sPowerName, aWords);
    end
    
    -- Look for primed conditions in the text
    parsePrimedConditions(aWords, effects);
    
    return effects;
end


function parsePrimedConditions(aWords, effects)
    
    -- Look for primed conditions that might not have been caught by the original parser
    for i = 1, #aWords do
        if StringManager.isWord(aWords[i], "primed") and i < #aWords then
            local nextWord = aWords[i + 1];
            if StringManager.isWord(nextWord, {"cold", "fire", "force", "lightning", "necrotic", "radiant"}) then
                -- Check if there's an appropriate trigger word before "primed"
                local bValidCondition = false;
                local nConditionStart = i;
                
                -- Look backwards for trigger words like "is", "becomes", etc.
                local j = i - 1;
                while j > 0 do
                    if StringManager.isWord(aWords[j], {"is", "becomes", "target", "creature"}) then
                        bValidCondition = true;
                        nConditionStart = j;
                        break;
                    elseif StringManager.isWord(aWords[j], {"the", "a", "an"}) and j > 1 then
                        -- Continue looking back for the actual trigger word
                        -- This handles cases like "the target is primed"
                    elseif StringManager.isWord(aWords[j], {"if", "unless", "while", "when", "not"}) then
                        break; -- Don't process conditional statements
                    end
                    j = j - 1;
                end
                
                if bValidCondition then
                    -- Use the space format that maps to proper condition names in condcomps
                    local conditionKey = "primed " .. string.lower(nextWord);
                    local displayName = conditionKey; -- Default to the key name
                    
                    -- Get the proper display name from condcomps table
                    if DataCommon and DataCommon.condcomps and DataCommon.condcomps[conditionKey] then
                        displayName = DataCommon.condcomps[conditionKey];
                    end
                    
                    local effect = {};
                    effect.sName = displayName; -- Use the properly formatted display name
                    effect.startindex = nConditionStart;
                    effect.endindex = i + 1;
                    
                    -- Use PowerManager.parseEffectsAdd to properly process the effect
                    -- This ensures it gets the correct properties for applying to targets
                    if PowerManager and PowerManager.parseEffectsAdd then
                        PowerManager.parseEffectsAdd(aWords, i, effect, effects);
                        
                        -- Check if the effect was added and ensure it has the right properties for database storage
                        local lastEffect = effects[#effects];
                        if lastEffect and (lastEffect.sName == displayName or string.find(lastEffect.sName, conditionKey)) then
                            -- Try to prevent [EACH] from appearing in display by removing targeting property
                            if lastEffect.sTargeting == "each" then
                                lastEffect.sTargeting = nil;
                            end
                            if not lastEffect.sApply then
                                lastEffect.sApply = "";
                            end
                        end
                    else
                        -- Fallback: manually add the effect if PowerManager isn't available
                        table.insert(effects, effect);
                    end
                end
            end
        end
    end
end

-- Helper function to check if text contains primed condition keywords
function containsPrimedCondition(sText)
    if not sText then
        return false;
    end
    
    local aWords = StringManager.split(sText, " ");
    for i = 1, #aWords do
        if StringManager.isWord(aWords[i], "primed") and i < #aWords then
            local nextWord = aWords[i + 1];
            if StringManager.isWord(nextWord, {"cold", "fire", "force", "lightning", "necrotic", "radiant"}) then
                return true;
            end
        end
    end
    
    return false;
end

-- Simple manual retry function for testing
function ME5eRetryInit()
    setupPowerOverrides();
end