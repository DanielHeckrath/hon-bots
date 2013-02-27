----------------------------------------------------------------------
----------------------------------------------------------------------
--  ____                             __                                                        __                    
-- /\  _`\                          /\ \                           /'\_/`\                    /\ \__                 
-- \ \ \/\ \   _ __   __  __    ___ \ \ \/'\       __     ___     /\      \      __       ____\ \ ,_\     __   _ __  
--  \ \ \ \ \ /\`'__\/\ \/\ \ /' _ `\\ \ , <     /'__`\ /' _ `\   \ \ \__\ \   /'__`\    /',__\\ \ \/   /'__`\/\`'__\
--   \ \ \_\ \\ \ \/ \ \ \_\ \/\ \/\ \\ \ \\`\  /\  __/ /\ \/\ \   \ \ \_/\ \ /\ \L\.\_ /\__, `\\ \ \_ /\  __/\ \ \/ 
--    \ \____/ \ \_\  \ \____/\ \_\ \_\\ \_\ \_\\ \____\\ \_\ \_\   \ \_\\ \_\\ \__/.\_\\/\____/ \ \__\\ \____\\ \_\ 
--     \/___/   \/_/   \/___/  \/_/\/_/ \/_/\/_/ \/____/ \/_/\/_/    \/_/ \/_/ \/__/\/_/ \/___/   \/__/ \/____/ \/_/ 
----------------------------------------------------------------------
----------------------------------------------------------------------
-- DrunkenmBot v0.1

--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################

local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true

object.bReportBehavior = false
object.bDebugUtility = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core         = {}
object.eventsLib     = {}
object.metadata     = {}
object.behaviorLib     = {}
object.skills         = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, min, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.min, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

local ravenor = {}


BotEcho(object:GetName()..' DrunkenBot is starting up ...')




--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_DrunkenMaster'


--   item buy order. internal names  
behaviorLib.StartingItems  = {"Item_LoggersHatchet", "Item_RunesOfTheBlight", "Item_IronBuckler"}
behaviorLib.LaneItems  = {"Item_BloodChalice", "Item_Marchers", "Item_ManaBattery"}
behaviorLib.MidItems  = {"Item_EnhancedMarchers", "Item_Pierce 3", "Item_SolsBulwark"}
behaviorLib.LateItems  = {"Item_Protect", "Item_DaemonicBreastplate", "Item_Immunity"}


-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills = {
    0, 2, 1, 1, 1,
    2, 2, 2, 3, 1, 
    3, 0, 0, 0, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4,
}

--melee weight overrides
behaviorLib.nCreepPushbackMul = 0.5
behaviorLib.nTargetPositioningMul = 0.6

-- bonus agression points if a skill/item is available for use

object.nLungeUp = 10
object.nDrinkUp = 10
object.nStaggerUp = 13
object.nUntouchableUp = 20

-- bonus agression points that are applied to the bot upon successfully using a skill/item

object.nLungeUse = 10
object.nStaggerUse = 10
object.nUntouchableUse = 20

-- thresholds of aggression the bot must reach to use these abilities

object.nLungeThreshold = 33
object.nStaggerThreshold = 27
object.nUntouchableThreshold = 40


--####################################################################
--####################################################################
--#                                                                 ##
--#   bot function overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################

------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
    core.VerboseLog("skillbuild()")

-- takes care at load/reload, <name_#> to be replaced by some convinient name.
    local unitSelf = self.core.unitSelf
    if  skills.abilLunge == nil then
        skills.abilLunge = unitSelf:GetAbility(0)
        skills.abilDrink = unitSelf:GetAbility(1)
        skills.abilStagger = unitSelf:GetAbility(2)
        skills.abilUntouchable = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end
    
   
    local nlev = unitSelf:GetLevel()
    local nlevpts = unitSelf:GetAbilityPointsAvailable()
    for i = nlev, nlev+nlevpts do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)

    -- custom code here
end
object.onthinkOld = object.onthink
object.onthink  = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)
 
    local nAddBonus = 0
    
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_DrunkenMaster1" then
            nAddBonus = nAddBonus + object.nLungeUse
        elseif EventData.InflictorName == "Ability_DrunkenMaster3" then
            nAddBonus = nAddBonus + object.nStaggerUse
        elseif EventData.InflictorName == "Ability_DrunkenMaster4" then
            nAddBonus = nAddBonus + object.nUntouchableUse
        end
    end

    if EventData.Type == "Killed" then
        eventsLib.printCombatEvent(EventData)
    end
 
    if nAddBonus > 0 then
        -- BotEcho ("Total nAddBonus = ".. nAddBonus) 
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride

------------------------------------------------------
--            calculate utility Values              --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @tparam IUnitEntity hero
-- @treturn number
local function AbilitiesUpUtilityFn(hero)
    local bDebugEchos = false
    local unitSelf = core.unitSelf
    
    local nUtil = 0
    local unitSelf = core.unitSelf

    if skills.abilLunge:CanActivate() then
        nUtil = nUtil + object.nLungeUp
    end
 
    if skills.abilStagger:CanActivate() then
        nUtil = nUtil + object.nStaggerUp
    end
    
    if skills.abilUntouchable:CanActivate() then
        nUtil = nUtil + object.nUntouchableUp
    end

    if unitSelf:HasState("State_Drunkenmaster_Ability2") then
        nUtil = nUtil + object.nDrinkUp
    end
    
    if bDebugEchos then BotEcho(" HARASS - abilitiesUp: "..nUtil) end
    
    return nUtil
end

------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @tparam IUnitEntity hero
-- @treturn number
local function CustomHarassUtilityOverride(hero)
    local nUtility = AbilitiesUpUtilityFn(hero)
    --return 0
    return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride  

object.nFlickAirTime = HoN.GetGameTime()

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--

local function HarassHeroExecuteOverride(botBrain)
    local bDebugEchos = false
    local bUseOldHarass = false

    if bDebugEchos then BotEcho("Executing custom harras behavior") end
    
    local unitTarget = behaviorLib.heroTarget
    local unitSelf = core.unitSelf

    if unitTarget == nil then
        return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
    end

    if bUseOldHarass then
        return object.harassExecuteOld(botBrain)
    end
    
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
    
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)   
    local bTargetRooted = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:GetMoveSpeed() < 200
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget, true)
    
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false
    
    --- Insert abilities code here, set bActionTaken to true 
    --- if an ability command has been given successfully
    
    --since we are using an old pointer, ensure we can still see the target for entity targeting
    if core.CanSeeUnit(botBrain, unitTarget) and not unitSelf:HasState("State_DrunkenMaster_Ability1_CircleDisarm") then
        -- Stagger
        if not bActionTaken and nLastHarassUtility > botBrain.nStaggerThreshold then
            local abilStagger = skills.abilStagger
            if abilStagger:CanActivate() then
                bActionTaken = core.OrderAbilityPosition(botBrain, abilStagger, vecTargetPosition, false)
            end
        end

        -- Lunge
        if not bActionTaken and nLastHarassUtility > botBrain.nLungeThreshold then
            local abilLunge = skills.abilLunge
            if abilLunge:CanActivate() then
                local nRange = abilLunge:GetRange()
                if nTargetDistanceSq < (nRange * nRange) then
                    bActionTaken = core.OrderAbilityEntity(botBrain, abilLunge, unitTarget, false)
                end
            end
        end
    end

    
    if not bActionTaken then
        if bDebugEchos then BotEcho("No action taken, fall back to default harras execute") end
        return object.harassExecuteOld(botBrain)
    end 
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

----------------------------------------------------
-- function: IsInBag
-- Checks if the IEntityItem is in the Bot's Inventory
-- Takes IEntityItem, Returns Boolean
----------------------------------------------------
local function IsInBag(item)
    local unitSelf = core.unitSelf
    local sItemName = item:GetName()
    if unitSelf then
        local unitInventory = unitSelf:GetInventory(true)
        if unitInventory then
            for slot = 1, 6, 1 do
                local curItem = unitInventory[slot]
                if curItem then
                    if curItem:GetName() == sItemName and not curItem:IsRecipe() then
                        return true
                    end
                end
            end
        end
    end
    return false
end

----------------------------------------------------
-- function: DrinkUtility
-- @treturn Number number from 0-100 indicating if we want to use blood chalice
----------------------------------------------------
function behaviorLib.DrinkUtility(botBrain)
    local nUtil = 0

    local abilDrink = skills.abilDrink
    local unitSelf = core.unitSelf

    if abilDrink:CanActivate() and not unitSelf:HasState("State_Drunkenmaster_Ability2") then
        nUtil = nUtil + 50
    end

    return nUtil
end

----------------------------------------------------
-- function: ManaBatteryExecute
----------------------------------------------------
function behaviorLib.DrinkExecute(botBrain)
    local unitSelf = core.unitSelf

    local bActionTaken = false

    local abilDrink = skills.abilDrink
    local unitSelf = core.unitSelf

    if abilDrink:CanActivate() and not unitSelf:HasState("State_Drunkenmaster_Ability2") then
        bActionTaken = core.OrderAbility(botBrain, abilDrink, false)
    end

    return bActionTaken
end

behaviorLib.DrinkBehavior = {}
behaviorLib.DrinkBehavior["Utility"] = behaviorLib.DrinkUtility
behaviorLib.DrinkBehavior["Execute"] = behaviorLib.DrinkExecute
behaviorLib.DrinkBehavior["Name"] = "DrinkBehavior"
tinsert(behaviorLib.tBehaviors, behaviorLib.DrinkBehavior)


----------------------------------------------------
-- function: ManaBatteryUtility
-- @treturn Number number from 0-100 indicating if we want to use blood chalice
----------------------------------------------------
function behaviorLib.ManaBatteryUtility(botBrain)
    local nUtil = 0

    core.FindItems(botBrain)
    local itemBattery = core.itemBattery
    if itemBattery and itemBattery:CanActivate() and IsInBag(itemBattery) and itemBattery:GetCharges() > 0 then
        --BotEcho("ManaBattery: "..tostring(itemBattery))
        local tLocalEnemies = core.localUnits["EnemyHeroes"]
        local unitSelf = core.unitSelf
        local nMissingHealth = unitSelf:GetMaxHealth() - unitSelf:GetHealth()
        local nMissingMana = unitSelf:GetMaxMana() - unitSelf:GetMana()
        local nBatteryCharges = itemBattery:GetCharges()
        local nHealthPercent = unitSelf:GetHealthPercent()

        --if #tLocalEnemies > 0 then
            if nHealthPercent < 0.33 then
                nUtil = nUtil + 100
            elseif nMissingMana > nBatteryCharges * 15 and nMissingHealth > nBatteryCharges * 10 then
                nUtil = nUtil + core.ParabolicDecayFn(nHealthPercent, 100, 0.33, false)
            end
        --end

        --BotEcho("Last ManaBatteryUtility: "..nUtil)
    end

    return nUtil
end

----------------------------------------------------
-- function: ManaBatteryExecute
----------------------------------------------------
function behaviorLib.ManaBatteryExecute(botBrain)
    local unitSelf = core.unitSelf

    local bActionTaken = false

    core.FindItems(botBrain)
    local itemBattery = core.itemBattery

    if itemBattery and itemBattery:CanActivate() and IsInBag(itemBattery) and itemBattery:GetCharges() > 0 then
        local tLocalEnemies = core.localUnits["EnemyHeroes"]
        local unitSelf = core.unitSelf
        local nMissingHealth = unitSelf:GetMaxHealth() - unitSelf:GetHealth()
        local nMissingMana = unitSelf:GetMaxMana() - unitSelf:GetMana()
        local nBatteryCharges = itemBattery:GetCharges()
        local nHealthPercent = unitSelf:GetHealthPercent()

        --if #tLocalEnemies > 0 then
            if nHealthPercent < 0.33 then
                bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBattery, false)
            elseif nMissingMana > nBatteryCharges * 15 and nMissingHealth > nBatteryCharges * 10 then
                bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBattery, false)
            end
        --end
    end

    return bActionTaken
end

behaviorLib.ManaBatteryBehavior = {}
behaviorLib.ManaBatteryBehavior["Utility"] = behaviorLib.ManaBatteryUtility
behaviorLib.ManaBatteryBehavior["Execute"] = behaviorLib.ManaBatteryExecute
behaviorLib.ManaBatteryBehavior["Name"] = "ManaBatteryBehavior"
tinsert(behaviorLib.tBehaviors, behaviorLib.ManaBatteryBehavior)

----------------------------------------------------
-- function: BloodChaliceUtility
-- @treturn Number number from 0-100 indicating if we want to use blood chalice
----------------------------------------------------
function behaviorLib.BloodChaliceUtility(botBrain)
    local nUtil = 0

    core.FindItems(botBrain)
    local itemChalice = core.itemChalice

    if itemChalice and itemChalice:CanActivate() and IsInBag(itemChalice) then
        local unitSelf = core.unitSelf
        local nHealth = unitSelf:GetHealth()
        local nHealthPercent = unitSelf:GetHealthPercent()
        local nManaPercent = unitSelf:GetManaPercent()
        local nMissingMana = unitSelf:GetMaxMana() - unitSelf:GetMana()

        if nHealthPercent > nManaPercent and nMissingMana > 85 and nHealth > 300 then
            nUtil = nUtil + 33
        end
    end

    return nUtil
end

----------------------------------------------------
-- function: BloodChaliceExecute
----------------------------------------------------
function behaviorLib.BloodChaliceExecute(botBrain)
    local unitSelf = core.unitSelf

    local bActionTaken = false

    core.FindItems(botBrain)
    local itemChalice = core.itemChalice

    if itemChalice and itemChalice:CanActivate() and IsInBag(itemChalice) then
        local unitSelf = core.unitSelf
        local nHealth = unitSelf:GetHealth()
        local nHealthPercent = unitSelf:GetHealthPercent()
        local nManaPercent = unitSelf:GetManaPercent()
        local nMissingMana = unitSelf:GetMaxMana() - unitSelf:GetMana()

        if nHealthPercent > nManaPercent and nMissingMana > 85 and nHealth > 300 then
            bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemChalice, false)
        end
    end

    return bActionTaken
end

behaviorLib.BloodChaliceBehavior = {}
behaviorLib.BloodChaliceBehavior["Utility"] = behaviorLib.BloodChaliceUtility
behaviorLib.BloodChaliceBehavior["Execute"] = behaviorLib.BloodChaliceExecute
behaviorLib.BloodChaliceBehavior["Name"] = "BloodChaliceBehavior"
tinsert(behaviorLib.tBehaviors, behaviorLib.BloodChaliceBehavior)

----------------------------------
--  AttackCreeps behavior
--
--  Utility: 21 if deny, 24 if ck, only if it predicts it can kill in one hit
--  Execute: Attacks target
----------------------------------

function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep)
    local bDebugEchos = false
    -- no predictive last hitting, just wait and react when they have 1 hit left
    -- prefers LH over deny

    local unitSelf = core.unitSelf
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
    local vecSelfPosition = unitSelf:GetPosition()
    local nMoveSpeed = unitSelf:GetMoveSpeed()
    --local nDamageAverage = core.GetFinalAttackDamageAverage(unitSelf)
    
    core.FindItems(botBrain)
    if core.itemHatchet then
        nDamageMin = nDamageMin * core.itemHatchet.creepDamageMul
    end 
    
    -- [Difficulty: Easy] Make bots worse at last hitting
    if core.nDifficulty == core.nEASY_DIFFICULTY then
        nDamageMin = nDamageMin * 1.35
    end

    local nDamageHatchet = nDamageMin

    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then

        local nTargetHealth = unitEnemyCreep:GetHealth()
        local tNearbyAllyCreeps = core.localUnits['AllyCreeps']
        local tNearbyAllyTowers = core.localUnits['AllyTowers']
        local nExpectedCreepDamage = 0
        local nExpectedTowerDamage = 0

        local vecTargetPos = unitEnemyCreep:GetPosition()

        -- Calculate our travel time to the creep
        local nTravelTime = core.TimeToPosition(vecSelfPosition, vecTargetPos, nMoveSpeed)
        local nTimeToAttack = (nTravelTime + unitSelf:GetAdjustedAttackActionTime()) / 1000
        if bDebugEchos then BotEcho ("Time to attack: " .. nTimeToAttack ) end 

        --Determine the damage expected on the creep by other creeps
        for i, unitCreep in pairs(tNearbyAllyCreeps) do
            if unitCreep:GetAttackTarget() == unitEnemyCreep then
                local nCreepAttacks = math.floor(nTimeToAttack / unitCreep:GetAttackSpeed())
                if not unitCreep:IsAttackReady() and nCreepAttacks > 0 then nCreepAttacks = nCreepAttacks - 1 end
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end

        --Determine the damage expected on the creep by towers
        for i, unitTower in pairs(tNearbyAllyTowers) do
            if unitTower:GetAttackTarget() == unitEnemyCreep then
                local nTowerAttacks = math.floor(nTimeToAttack / unitTower:GetAttackSpeed())
                if not unitTower:IsAttackReady() and nTowerAttacks > 0 then nTowerAttacks = nTowerAttacks - 1 end
                nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
            end
        end
        
        -- Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
            if bDebugEchos then BotEcho("Returning an enemy") end
            return unitEnemyCreep
        else
            -- Check if we can kill the target with loggers hatchet
            core.FindItems(botBrain)
            local itemHatchet = core.itemHatchet
            if (itemHatchet and itemHatchet:CanActivate() and IsInBag(itemHatchet)) then
                -- Loggers Hatchet can be used. Since we are a melee hero this might be the safer choice
                local nProjectileSpeed = 900
                local nProjectileTravelTime = Vector3.Distance2D(vecSelfPosition, vecTargetPos) / nProjectileSpeed
                if bDebugEchos then BotEcho ("Hatchet projectile travel time: " .. nProjectileTravelTime ) end 
                
                --Determine the damage expected on the creep by other creeps
                for i, unitCreep in pairs(tNearbyAllyCreeps) do
                    if unitCreep:GetAttackTarget() == unitEnemyCreep then
                        local nCreepAttacks = math.floor(nProjectileTravelTime / unitCreep:GetAttackSpeed())
                        if not unitCreep:IsAttackReady() and nCreepAttacks > 0 then nCreepAttacks = nCreepAttacks - 1 end
                        nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
                    end
                end

                --Determine the damage expected on the creep by towers
                for i, unitTower in pairs(tNearbyAllyTowers) do
                    if unitTower:GetAttackTarget() == unitEnemyCreep then
                        local nTowerAttacks = math.floor(nProjectileTravelTime / unitTower:GetAttackSpeed())
                        if not unitTower:IsAttackReady() and nTowerAttacks > 0 then nTowerAttacks = nTowerAttacks - 1 end
                        nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
                    end
                end
                
                --Only attack if, by the time our attack reaches the target
                -- the damage done by other sources brings the target's health
                -- below our minimum damage
                if nDamageHatchet >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
                    if bDebugEchos then BotEcho("Returning an enemy") end
                    return unitEnemyCreep
                end
            end
        end        
    end

    if unitAllyCreep then
        local nTargetHealth = unitAllyCreep:GetHealth()
        local tNearbyEnemyCreeps = core.localUnits['EnemyCreeps']
        local tNearbyEnemyTowers = core.localUnits['EnemyTowers']
        local nExpectedCreepDamage = 0
        local nExpectedTowerDamage = 0

        local sName = core.GetCurrentBehaviorName(botBrain)
        if core.teamBotBrain.nPushState == 2 then
            return nil
        end

        local vecTargetPos = unitAllyCreep:GetPosition()
        local nTravelTime = core.TimeToPosition(vecSelfPosition, vecTargetPos, nMoveSpeed)
        local nTimeToAttack = (nTravelTime + unitSelf:GetAdjustedAttackActionTime()) / 1000
        if bDebugEchos then BotEcho ("Time to attack: " .. nTimeToAttack ) end 
        
        --Determine the damage expected on the creep by other creeps
        for i, unitCreep in pairs(tNearbyEnemyCreeps) do
            if unitCreep:GetAttackTarget() == unitAllyCreep then
                local nCreepAttacks = math.floor(nTimeToAttack / unitCreep:GetAttackSpeed())
                if not unitCreep:IsAttackReady() and nCreepAttacks > 0 then nCreepAttacks = nCreepAttacks - 1 end
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end

        --Determine the damage expected on the creep by towers
        for i, unitTower in pairs(tNearbyEnemyTowers) do
            if unitTower:GetAttackTarget() == unitAllyCreep then
                local nTowerAttacks = math.floor(nTimeToAttack / unitTower:GetAttackSpeed())
                if not unitTower:IsAttackReady() and nTowerAttacks > 0 then nTowerAttacks = nTowerAttacks - 1 end
                nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
            end
        end
        
        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
            local bActuallyDeny = true
            
            --[Difficulty: Easy] Don't deny
            if core.nDifficulty == core.nEASY_DIFFICULTY then
                bActuallyDeny = false
            end         
            
            -- [Tutorial] Hellbourne *will* deny creeps after shit gets real
            if core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam() then
                bActuallyDeny = true
            end
            
            if bActuallyDeny then
                if bDebugEchos then BotEcho("Returning an ally") end
                return unitAllyCreep
            end
        end
    end

    return nil
end

---------------------------------------------
-- Attack Creeps Override
---------------------------------------------

local function AttackCreepsExecuteCustom(botBrain)
    local bDebugEchos = false

    local unitSelf = core.unitSelf
    local unitCreepTarget = core.unitCreepTarget
    local bActionTaken = false
    local nMoveSpeed = unitSelf:GetMoveSpeed()
    local bActionTaken = false

    if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then      
        --Get info about the target we are about to attack

        local vecSelfPos = unitSelf:GetPosition()
        local vecTargetPos = unitCreepTarget:GetPosition()
        local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
        local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)       
        local nTargetHealth = unitCreepTarget:GetHealth()
        local nDamageMin = unitSelf:GetFinalAttackDamageMin()
        local bUseHatchet = false

        local sName = core.GetCurrentBehaviorName(botBrain)
        local bIsPushing = false

        if core.teamBotBrain.nPushState == 2 then
            bIsPushing = true
            nDamageMin = nDamageMin * 3
        end

        core.FindItems(botBrain)
        local itemHatchet = core.itemHatchet
        if core.itemHatchet then
            nDamageMin = nDamageMin * core.itemHatchet.creepDamageMul
        end 
        local nDamageHatchet = nDamageMin

        local nProjectileTravelTime = 0
        local nTravelTime = core.TimeToPosition(vecSelfPos, vecTargetPos, nMoveSpeed)
        nProjectileTravelTime = (nTravelTime + unitSelf:GetAdjustedAttackActionTime()) / 1000

        --Get projectile info
        if bDebugEchos then BotEcho ("Time to attack: " .. nProjectileTravelTime ) end 
        
        local nExpectedCreepDamage = 0
        local nExpectedTowerDamage = 0
        local tNearbyAttackingCreeps = nil
        local tNearbyAttackingTowers = nil

        --Get the creeps and towers on the opposite team
        -- of our target
        if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
            tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
            tNearbyAttackingTowers = core.localUnits['EnemyTowers']
        else
            tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
            tNearbyAttackingTowers = core.localUnits['AllyTowers']
        end
    
        --Determine the damage expected on the creep by other creeps
        for i, unitCreep in pairs(tNearbyAttackingCreeps) do
            if unitCreep:GetAttackTarget() == unitCreepTarget then
                local nCreepAttacks = math.floor(nProjectileTravelTime / unitCreep:GetAttackSpeed())
                if not unitCreep:IsAttackReady() and nCreepAttacks > 0 then nCreepAttacks = nCreepAttacks - 1 end
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end
    
        --Determine the damage expected on the creep by other towers
        for i, unitTower in pairs(tNearbyAttackingTowers) do
            if unitTower:GetAttackTarget() == unitCreepTarget then
                local nTowerAttacks = math.floor(nProjectileTravelTime / unitTower:GetAttackSpeed())
                    if not unitTower:IsAttackReady() and nTowerAttacks > 0 then nTowerAttacks = nTowerAttacks - 1 end
                nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
            end
        end

        --BotEcho(format("nExpectedCreepDamage: %i - nExpectedTowerDamage: %i", nExpectedCreepDamage, nExpectedTowerDamage))
    
        -- Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage, and we are in range and can attack right now
        if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and (nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) or bIsPushing) then
            if bDebugEchos then BotEcho ("Attacking target") end
            bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)
        elseif (itemHatchet and itemHatchet:CanActivate() and IsInBag(itemHatchet)) then
            -- maybe we can kill the target with hatchet
            local nProjectileSpeed = 900
            nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed

            --Get projectile info
            if bDebugEchos then BotEcho ("Hatchet Projectile travel time: " .. nProjectileTravelTime ) end 
            
            local nExpectedCreepDamage = 0
            local nExpectedTowerDamage = 0
            local tNearbyAttackingCreeps = nil
            local tNearbyAttackingTowers = nil

            --Get the creeps and towers on the opposite team
            -- of our target
            if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
                tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
                tNearbyAttackingTowers = core.localUnits['EnemyTowers']
            else
                tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
                tNearbyAttackingTowers = core.localUnits['AllyTowers']
            end
        
            --Determine the damage expected on the creep by other creeps
            for i, unitCreep in pairs(tNearbyAttackingCreeps) do
                if unitCreep:GetAttackTarget() == unitCreepTarget then
                    local nCreepAttacks = math.floor(nProjectileTravelTime / unitCreep:GetAttackSpeed())
                    if not unitCreep:IsAttackReady() and nCreepAttacks > 0 then nCreepAttacks = nCreepAttacks - 1 end
                    nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
                end
            end
        
            --Determine the damage expected on the creep by other towers
            for i, unitTower in pairs(tNearbyAttackingTowers) do
                if unitTower:GetAttackTarget() == unitCreepTarget then
                    local nTowerAttacks = math.floor(nProjectileTravelTime / unitTower:GetAttackSpeed())
                    if not unitTower:IsAttackReady() and nTowerAttacks > 0 then nTowerAttacks = nTowerAttacks - 1 end
                    nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
                end
            end

            nAttackRangeSq = 600 * 600

            -- Only attack if, by the time our attack reaches the target
            -- the damage done by other sources brings the target's health
            -- below our minimum damage, and we are in range and can attack right now
            if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and (nDamageHatchet >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) or bIsPushing) then
                if bDebugEchos then BotEcho ("Attacking target with hatchet") end
                bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemHatchet, unitCreepTarget)
            end
        else
            --BotEcho("MOVIN OUT")
            local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
            bActionTaken = core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecDesiredPos, false)
        end
    else
        return false
    end

    if not bActionTaken then
        --BotEcho("No action yet, trying old behavior")
        return object.AttackCreepsExecuteOld(botBrain)
    end 
end

object.AttackCreepsExecuteOld = behaviorLib.AttackCreepsBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteCustom

-- attetntion:
--[[
x               x
 x       -
              x
              
    Imagine x are creeps, and - is their center
    this will be correctly calculated, however
    it does not state that creeps are in range
    of certain abilities
]]
local function groupCenter(tGroup, nMinCount)
    if nMinCount == nil then nMinCount = 1 end
    
    if tGroup ~= nil then
        local nGroupCount = 0 
        for id, creep in pairs(tGroup) do
            if creep:GetAttackType() == "melee" then
                if vGroupCenter == nil then
                    vGroupCenter = creep:GetPosition()
                    nGroupCount = nGroupCount + 1
                else
                    vGroupCenter = vGroupCenter + creep:GetPosition()
                    nGroupCount = nGroupCount + 1
                end
            end
        end
        
        if nGroupCount < nMinCount then 
            return nil
        else
            return vGroupCenter/nGroupCount-- center vector
        end
    else
        return nil  
    end
end

-- This function allowes ra to use his ability while pushing
-- Has prediction, however it might need some repositioning so he is in correct range more often
local function abilityPush(botBrain, unitSelf)
    local debugAbilityPush = false

    local abilLunge = skills.abilLunge
    local abilStagger = skills.abilStagger
    local abilUntouchable = skills.abilUntouchable

    local nMinMana = abilLunge:GetManaCost() + abilStagger:GetManaCost()

    if abilUntouchable:GetActualRemainingCooldownTime() < 30000 then
        nMinMana = nMinMana + abilUntouchable:GetManaCost()
    end


    local tNearbyEnemyCreeps = core.localUnits["EnemyCreeps"]

    local vCreepCenter = groupCenter(tNearbyEnemyCreeps, 3) -- the 3 basicly wont allow abilities under 3 creeps
    
    -- Be conservative with mana, so we can cast our combo afterwards
    if  abilStagger:CanActivate() and unitSelf:GetMana() > nMinMana and vCreepCenter ~= nil then 
        --Get judgement info
        local nRange = abilStagger:GetRange()

        --Get info about surroundings
        local nDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vCreepCenter)

        if nDistanceSq < nRange * nRange then
            bActionTaken = core.OrderAbilityPosition(botBrain, abilStagger, vCreepCenter, false)
        else
            --move in when we aren't attacking
            core.OrderMoveToPosClamp(botBrain, unitSelf, vCreepCenter, false)
            bActionTaken = true
        end
    end

    if unitSelf:IsAttackReady() then
        if #tNearbyEnemyCreeps > 0 then
            local unitClosestCreep = nil
            local nClosestDistanceSq = 99999 * 99999
            local vecMyPosition = unitSelf:GetPosition()
            for i,creep in pairs(tNearbyEnemyCreeps) do
                local nDistanceSq = Vector3.Distance2DSq(vecMyPosition. creep:GetPosition())
                if nDistanceSq > nClosestDistanceSq then
                    unitClosestCreep = creep
                end
            end

            if unitClosestCreep ~= nil then
                local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitClosestCreep, true)

                if nClosestDistanceSq < nAttackRangeSq and unitSelf:IsAttackReady() then
                    if bDebugEchos then BotEcho ("Attacking target") end
                    bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)
                else  
                    --BotEcho("MOVIN OUT")
                    local vecDesiredPos = core.AdjustMovementForTowerLogic(unitClosestCreep:GetPosition())
                    bActionTaken = core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecDesiredPos, false)
                end
            end
        end
    end
    
    return false
end


function object.CreepPush(botBrain)
    VerboseLog("PushExecute("..tostring(botBrain)..")")
    local debugPushLines = false
    if debugPushLines then BotEcho('^yGotta execute em *greedy*') end
    
    local bSuccess = false
        
    local unitSelf = core.unitSelf
    if unitSelf:IsChanneling() then 
        return
    end

    local unitTarget = core.unitEnemyCreepTarget
    if unitTarget then
        bSuccess = abilityPush(botBrain, unitSelf)
        if debugPushLines then 
            BotEcho('^p-----------------------------Got em')
            if bSuccess then BotEcho('Gotemhard') else BotEcho('at least i tried') end
        end
    end
    
    return bSuccess
end

-- both functions below call for the creep push, however 
function object.PushExecuteOverride(botBrain)
    if not object.CreepPush(botBrain) then 
        object.PushExecuteOld(botBrain)
    end
end
object.PushExecuteOld = behaviorLib.PushBehavior["Execute"]
behaviorLib.PushBehavior["Execute"] = object.PushExecuteOverride


local function TeamGroupBehaviorOverride(botBrain)
    object.TeamGroupBehaviorOld(botBrain)
    object.CreepPush(botBrain)
end
object.TeamGroupBehaviorOld = behaviorLib.TeamGroupBehavior["Execute"]
behaviorLib.TeamGroupBehavior["Execute"] = TeamGroupBehaviorOverride

----------------------------------
--  FindItems Override
----------------------------------
local function funcFindItemsOverride(botBrain)
    local bUpdated = object.FindItemsOld(botBrain)

    if core.itemBattery ~= nil and not core.itemBattery:IsValid() then
        core.itemBattery = nil
    end

    if core.itemChalice ~= nil and not core.itemChalice:IsValid() then
        core.itemChalice = nil
    end
    
    if bUpdated then
        --only update if we need to
        if core.itemBattery and core.itemChalice then
            return
        end
        
        local inventory = core.unitSelf:GetInventory(true)
        for slot = 1, 12, 1 do
            local curItem = inventory[slot]
            if curItem then
                if core.itemBattery == nil and (curItem:GetName() == "Item_ManaBattery" or curItem:GetName() == "Item_PowerSupply") then
                    core.itemBattery = core.WrapInTable(curItem)
                end
                if core.itemChalice == nil and (curItem:GetName() == "Item_BloodChalice") then
                    core.itemChalice = core.WrapInTable(curItem)
                end
            end
        end
    end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride