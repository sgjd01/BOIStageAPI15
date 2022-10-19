local shared = require("scripts.stageapi.shared")
local mod = require("scripts.stageapi.mod")
local getEntities2 = require("scripts.stageapi.reimpl.entities2")

local entities2Functions = {getEntities2}

function StageAPI.AddEntities2Function(func)
    entities2Functions[#entities2Functions + 1] = func
end

local Entities2AccessMode = {
    List = 1,
    ByName = 2,
    ByType = 3
}

function StageAPI.GetEntityConfig(id, var, sub)
    if type(id) == "string" then -- get by name
        for _, func in ipairs(entities2Functions) do
            local byName = func(Entities2AccessMode.ByName)
            if byName[id] then
                return byName[id]
            end
        end

        return nil
    elseif id then
        var, sub = var or 0, sub or 0

        local mostSpecific
        local specificVariant = false
        for _, func in ipairs(entities2Functions) do
            local byType = func(Entities2AccessMode.ByType)
            if byType[id] then
                if byType[id][var] then
                    if byType[id][var][sub] then
                        return byType[id][var][sub]
                    else
                        mostSpecific = byType[id][var][0]
                        specificVariant = true
                    end
                else
                    if not specificVariant then
                        mostSpecific = byType[id][0][0]
                    end
                end
            end
        end

        return mostSpecific
    end

    return nil
end

function StageAPI.GetEntityConfigDefaults(id, var, sub)
    local config = StageAPI.GetEntityConfig(id, var, sub)
    if not config then
        return nil
    end

    config.Type = config.Type or 0
    config.Variant = config.Variant or 0
    config.Subtype = config.Subtype or 0
    config.Boss = config.Boss == true
    config.Champion = config.Champion == true
    config.CollisionDamage = config.CollisionDamage or 0
    config.CollisionRadius = config.CollisionRadius or 0
    config.NumGridCollisionPoints = config.NumGridCollisionPoints or 1
    config.ShadowSize = config.ShadowSize or 0
    config.HP = config.HP or 0
    config.StageHP = config.StageHP or 0
    config.Friction = config.Friction or 1
    return config
end

function StageAPI.GetChampionChance() --Values taken from Isaac Wiki
    local chance = 0.05
    if shared.Game.Difficulty % 2 == 1 then --Hard Mode
        chance = 0.2
    end
    for i = 0, shared.Game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(CollectibleType.COLLECTIBLE_CHAMPION_BELT) then --Champion Belt
            chance = chance + 0.2
        end
        chance = chance + (0.1 * player:GetTrinketMultiplier(TrinketType.TRINKET_PURPLE_HEART)) --Purple Heart
    end
    return chance
end

StageAPI.CantBeChampions = {}
function StageAPI.AddEnemyToChampionBlacklist(type, var, sub)
    local entry = type
    if var then
        entry = entry.." "..var
        if sub then
            entry = entry.." "..sub
        end
    end
    StageAPI.CantBeChampions[entry] = true
end

function StageAPI.CanBeChampion(id, var, sub)
    local config = StageAPI.GetEntityConfig(id, var, sub)
    if config then
        return config.Champion
    else
        return not (StageAPI.CantBeChampions[id] 
        or StageAPI.CantBeChampions[id.." "..var] 
        or StageAPI.CantBeChampions[id.." "..var.." "..sub])
    end
end

function StageAPI.CalculateStageHP(stageHP, stage)
    if not stage then
        local currentStage = StageAPI.GetCurrentStage()
        if currentStage and (currentStage.StageNumber or currentStage.StageHPNumber) then
            stage = currentStage.StageNumber or currentStage.StageHPNumber
        else
            stage = shared.Level:GetStage()
        end
    end

    if stage < LevelStage.STAGE3_1 then
        return stageHP * stage
    else
        return stageHP * stage * 0.8
    end
end

function StageAPI.RecalculateEntityStageHP(entity, config)
    config = config or StageAPI.GetEntityConfig(entity.Type, entity.Variant, entity.SubType)
    if config and config.StageHP then
        local base = StageAPI.CalculateStageHP(config.StageHP, shared.Level:GetStage())
        local new = StageAPI.CalculateStageHP(config.StageHP)

        if base ~= new then
            entity.HitPoints = entity.HitPoints + (new - base)
            entity.MaxHitPoints = entity.MaxHitPoints + (new - base)
        end
    end
end