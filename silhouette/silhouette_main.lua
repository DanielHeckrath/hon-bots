-- SilhouetteBot v1.0

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
object.eventsLib    = {}
object.metadata     = {}
object.behaviorLib  = {}
object.skills       = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventslib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorlib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random, sqrt
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random, _G.math.sqrt

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

local sqrtTwo = math.sqrt(2)
local gold=0

BotEcho('loading silhouette_main...')

--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_Silhouette'


--   item buy order. internal names  
behaviorLib.StartingItems  = {"Item_RunesOfTheBlight", "Item_HealthPotion", "2 Item_MinorTotem", "Item_DuckBoots"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_ManaRegen3", "Item_Regen"}
behaviorLib.MidItems  = {"Item_Steamboots", "Item_Protect"}
behaviorLib.LateItems  = {"Item_StrengthAgility", "Item_Weapon3", "Item_Immunity"}


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
    core.VerboseLog("SkillBuild()")

    local unitSelf = self.core.unitSelf
    if  skills.abilLotus == nil then
        skills.abilLotus = unitSelf:GetAbility(0)
        skills.abilGrapple = unitSelf:GetAbility(1)
        skills.abilSalvo = unitSelf:GetAbility(2)
        skills.abilShadow = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
        skills.abilGo = unitSelf:GetAbility(5)
        skills.abilPull = unitSelf:GetAbility(6)
        skills.abilSwap = unitSelf:GetAbility(7)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end
    
    
    -- automatically levels stats in the end
    -- stats have to be leveld manually if needed inbetween
    tSkills ={
                2, 0, 0, 1, 0,
                2, 0, 2, 2, 3, 
                3, 1, 1, 1, 4,
                3
            }
    
    local nLev = unitSelf:GetLevel()
    local nLevPts = unitSelf:GetAbilityPointsAvailable()
    --BotEcho(tostring(nLev + nLevPts))
    for i = nLev, nLev+nLevPts do
        local nSkill = tSkills[i]
        if nSkill == nil then nSkill = 4 end
        
        unitSelf:GetAbility(nSkill):LevelUp()

        if nSkill == 0 and unitSelf:GetAbility(nSkill):GetActualRemainingCooldownTime() == 0 then
            local nCurrentTime = HoN.GetGameTime()
            object.nLotusTime = nCurrentTime
            BotEcho("Reseting Lotus Spawn time")
            BotEcho("Current time: "..nCurrentTime.." - Lotus Respawn: "..object.nLotusTime)
        end
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
end
object.onthinkOld = object.onthink
object.onthink  = object.onthinkOverride


-- These are bonus agression points if a skill/item is available for use
object.nLotusUp = 13
object.nGrappleUp = 10 
object.nSalvoUp = 7 
object.nShadowUp = 20
 
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
object.nLotusUse = 13
object.nGrappleUse = 10
object.nShadowUse = 20
 
--These are thresholds of aggression the bot must reach to use these abilities
object.nLotusThreshold = 13
object.nGrappleThreshold = 10 
object.nSalvoThreshold = 7 
object.nShadowThreshold = 20

object.nLotusTime = HoN.GetGameTime()


----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)
    local nAddBonus = 0
    local unitSelf = core.unitSelf
    local abilLotus = skills.abilLotus
    local nCurrentTime = HoN.GetGameTime()
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Silhouette1" then
            object.nLotusTime = nCurrentTime + 12000
            nAddBonus = nAddBonus + object.nLotusUse
            BotEcho("Reseting Lotus Spawn time")
            BotEcho("Current time: "..nCurrentTime.." - Lotus Respawn: "..object.nLotusTime)
        elseif EventData.InflictorName == "Ability_Silhouette2" then
            nAddBonus = nAddBonus + object.nGrappleUse
        elseif EventData.InflictorName == "Ability_Silhouette4" then
            nAddBonus = nAddBonus + object.nShadowUse
        end
    elseif EventData.Type == "Respawn" then
        local nCooldownTime = abilLotus:GetActualRemainingCooldownTime()
            
        object.nLotusTime = nCurrentTime + nCooldownTime
        BotEcho("Reseting Lotus Spawn time to death time")
        BotEcho("Current time: "..nCurrentTime.." - Lotus Respawn: "..object.nLotusTime)
    end
 
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride



local function funcFindItemsOverride(botBrain)
    local bUpdated = object.FindItemsOld(botBrain)

    if core.itemImmunity ~= nil and not core.itemImmunity:IsValid() then
        core.itemImmunity = nil
    end

    if bUpdated then
        if core.itemImmunity then
            return
        end

        local inventory = core.unitSelf:GetInventory(true)
        for slot = 1, 12, 1 do
            local curItem = inventory[slot]
            if curItem then
                if core.itemImmunity == nil and curItem:GetName() == "Item_Immunity" then
                    core.itemImmunity = core.WrapInTable(curItem)
                end
            end
        end
    end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityOverride(enemyHero) --how much to harrass, doesn't change combo order or anything
    local nUtil = 0
    
    --BotEcho("Rethinking hass")
    
    local unitSelf = core.unitSelf

    --Death Lotus up bonus
    if skills.abilLotus:CanActivate() then
        nUtil = nUtil + object.nLotusUp
    end
 
    --Tree Grapple up bonus
    if skills.abilGrapple:CanActivate() then
        nUtil = nUtil + object.nGrappleUp
    end

    --Relentless Salvo up bonus
    if skills.abilSalvo:GetActualRemainingCooldownTime() == 0 then
        nUtil = nUtil + object.nSalvoUp
    end

    --Tree Grapple up bonus
    if skills.abilShadow:CanActivate() then
        nUtil = nUtil + object.nShadowUp
    end
 
    return nUtil -- no desire to attack AT ALL if 0.
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride  

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--
local function HarassHeroExecuteOverride(botBrain)
    local bDebugEchos = false
    local bDebugHarassUtility = false and bDebugEchos
    
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return false --can not execute, move on to the next behavior
    end
    
    local unitSelf = core.unitSelf
    
    --Positioning and distance info
    local vecMyPosition = unitSelf:GetPosition()
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
    
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    
    --Skills
    local abilLotus = skills.abilLotus
    local abilGrapple = skills.abilGrapple
    local abilShadow = abilShadow
    
    if bDebugHarassUtility then BotEcho("Silhouette HarassHero at "..nLastHarassUtility) end

    --Used to keep track of whether something has been used
    -- If so, any other action that would have taken place
    -- gets queued instead of instantly ordered
    local bActionTaken = false


    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
    local bDebugEchos = false

    --Get info about self
    local unitSelf = core.unitSelf
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
    local vecSelfPosition = unitSelf:GetPosition()
    local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()

    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
        local nTargetHealth = unitEnemyCreep:GetHealth()
        local tNearbyAllyCreeps = core.localUnits['AllyCreeps']
        local tNearbyAllyTowers = core.localUnits['AllyTowers']
        local nExpectedCreepDamage = 0
        local nExpectedTowerDamage = 0

        local vecTargetPos = unitEnemyCreep:GetPosition()
        local nProjectileTravelTime = Vector3.Distance2D(vecSelfPosition, vecTargetPos) / nProjectileSpeed
        if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end 
        
        --Determine the damage expected on the creep by other creeps
        for i, unitCreep in pairs(tNearbyAllyCreeps) do
            if unitCreep:GetAttackTarget() == unitEnemyCreep then
                local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end

        --Determine the damage expected on the creep by towers
        for i, unitTower in pairs(tNearbyAllyTowers) do
            if unitTower:GetAttackTarget() == unitEnemyCreep then
                local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
                nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
            end
        end
        
        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
            if bDebugEchos then BotEcho("Returning an enemy") end
            return unitEnemyCreep
        end
    end

    if unitAllyCreep then
        local nTargetHealth = unitAllyCreep:GetHealth()
        local tNearbyEnemyCreeps = core.localUnits['EnemyCreeps']
        local tNearbyEnemyTowers = core.localUnits['EnemyTowers']
        local nExpectedCreepDamage = 0
        local nExpectedTowerDamage = 0

        local vecTargetPos = unitAllyCreep:GetPosition()
        local nProjectileTravelTime = Vector3.Distance2D(vecSelfPosition, vecTargetPos) / nProjectileSpeed
        if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end 
        
        --Determine the damage expected on the creep by other creeps
        for i, unitCreep in pairs(tNearbyEnemyCreeps) do
            if unitCreep:GetAttackTarget() == unitAllyCreep then
                local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end

        --Determine the damage expected on the creep by towers
        for i, unitTower in pairs(tNearbyEnemyTowers) do
            if unitTower:GetAttackTarget() == unitAllyCreep then
                local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
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

function AttackCreepsExecuteOverride(botBrain)
    local unitSelf = core.unitSelf
    local unitCreepTarget = core.unitCreepTarget

    if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then      
        --Get info about the target we are about to attack
        local vecSelfPos = unitSelf:GetPosition()
        local vecTargetPos = unitCreepTarget:GetPosition()
        local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
        local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)       
        local nTargetHealth = unitCreepTarget:GetHealth()
        local nDamageMin = unitSelf:GetFinalAttackDamageMin()    

        --Get projectile info
        local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed() 
        local nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed
        if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end 
        
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
                local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
                nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
            end
        end
    
        --Determine the damage expected on the creep by other towers
        for i, unitTower in pairs(tNearbyAttackingTowers) do
            if unitTower:GetAttackTarget() == unitCreepTarget then
                local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
                nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
            end
        end

    
        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage, and we are in range and can attack right now
        if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin >= (nTargetHealth - nExpectedCreepDamage - nExpectedTowerDamage) then
            core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)

        --Otherwise get within 70% of attack range if not already
        -- This will decrease travel time for the projectile
        elseif (nDistSq > nAttackRangeSq * 0.5) then 
            local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
            core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)

        --If within a good range, just hold tight
        else
            core.OrderHoldClamp(botBrain, unitSelf, false)
        end
    else
        return false
    end
end
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride

BotEcho('finished loading soulreaper_main')
