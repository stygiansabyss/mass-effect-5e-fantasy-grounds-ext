--
-- ME5e Power Management
-- Handles power parsing extensions and primed condition recognition
--

local originalParseEffects = nil;

function onInit()
    Debug.console("ME5ePowers: Script initialized");
    Debug.console("ME5ePowers: Checking available globals...");
    Debug.console("ME5ePowers: parseEffects exists: " .. tostring(parseEffects ~= nil));
    Debug.console("ME5ePowers: PowerManager exists: " .. tostring(PowerManager ~= nil));
    Debug.console("ME5ePowers: TimerManager exists: " .. tostring(TimerManager ~= nil));
    
    -- Try to override the global parseEffects function directly
    -- Following the pattern from me5e-ps2.lua and me5e-combat.lua
    setupPowerOverrides();
end

function setupPowerOverrides()
    Debug.console("ME5ePowers: Setting up power parsing overrides");
    Debug.console("ME5ePowers: Checking if parseEffects exists: " .. tostring(parseEffects ~= nil));
    
    -- Check if parseEffects function exists in global scope
    if parseEffects then
        Debug.console("ME5ePowers: Found parseEffects function, overriding...");
        originalParseEffects = parseEffects;
        parseEffects = parseEffectsWithPrimed;
        Debug.console("ME5ePowers: parseEffects overridden successfully");
        return true;
    else
        Debug.console("ME5ePowers: parseEffects function not found yet");
        
        -- Try alternative approaches - maybe it's in a different namespace
        if PowerManager and PowerManager.parseEffects then
            Debug.console("ME5ePowers: Found PowerManager.parseEffects, overriding...");
            originalParseEffects = PowerManager.parseEffects;
            PowerManager.parseEffects = parseEffectsWithPrimed;
            Debug.console("ME5ePowers: PowerManager.parseEffects overridden successfully");
            return true;
        end
        
        -- Try to use a more direct approach - set up multiple retry attempts
        setupRetryMechanism();
        return false;
    end
end

function setupRetryMechanism()
    Debug.console("ME5ePowers: Setting up retry mechanism");
    
    -- Create a retry counter
    local retryCount = 0;
    local maxRetries = 10;
    
    -- Try immediate retry first
    local function tryRetry()
        retryCount = retryCount + 1;
        Debug.console("ME5ePowers: Retry attempt #" .. retryCount);
        
        if parseEffects then
            Debug.console("ME5ePowers: Found parseEffects on retry #" .. retryCount);
            originalParseEffects = parseEffects;
            parseEffects = parseEffectsWithPrimed;
            Debug.console("ME5ePowers: parseEffects overridden successfully on retry");
            return true;
        elseif retryCount < maxRetries then
            Debug.console("ME5ePowers: parseEffects still not found, will retry again");
            -- Register another retry
            if TimerManager then
                TimerManager.registerCallback(tryRetry, 500); -- Try every 500ms
            end
        else
            Debug.console("ME5ePowers: Max retries reached, giving up on automatic override");
        end
        return false;
    end
    
    -- Start the retry process
    if TimerManager then
        TimerManager.registerCallback(tryRetry, 500);
    end
end

function parseEffectsWithPrimed(sPowerName, aWords)
    Debug.console("ME5ePowers: parseEffectsWithPrimed called for: " .. (sPowerName or "unknown"));
    
    -- Call the original function first to handle normal condition parsing
    local effects = {};
    if originalParseEffects then
        effects = originalParseEffects(sPowerName, aWords);
    else
        Debug.console("ME5ePowers: originalParseEffects not available, skipping original parsing");
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
                    local effect = {};
                    effect.sName = "Primed: " .. StringManager.capitalize(nextWord);
                    effect.startindex = nConditionStart;
                    effect.endindex = i + 1;
                    
                    -- Check if we already have this effect to avoid duplicates
                    local bDuplicate = false;
                    for _, existingEffect in ipairs(effects) do
                        if existingEffect.sName == effect.sName then
                            bDuplicate = true;
                            break;
                        end
                    end
                    
                    if not bDuplicate then
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
    Debug.console("ME5ePowers: Manual retry requested");
    setupPowerOverrides();
end