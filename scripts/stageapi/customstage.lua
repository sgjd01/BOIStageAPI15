StageAPI.LogMinor("Loading CustomStage Handler")

StageAPI.CustomStages = {}

StageAPI.CustomStage = StageAPI.Class("CustomStage")
function StageAPI.CustomStage:Init(name, replaces, noSetReplaces)
    self.Name = name
    self.Alias = name

    if not noSetReplaces then
        self.Replaces = replaces or StageAPI.StageOverride.CatacombsOne
    end

    if name then
        StageAPI.CustomStages[name] = self
    end
end

function StageAPI.CustomStage:InheritInit(name, noSetAlias)
    if not noSetAlias then
        self.Alias = self.Name
    end

    self.Name = name
    if name then
        StageAPI.CustomStages[name] = self
    end
end

function StageAPI.CustomStage:SetName(name)
    self.Name = name or self.Name
    if self.Name then
        StageAPI.CustomStages[self.Name] = self
    end

end

function StageAPI.CustomStage:GetDisplayName()
    return self.DisplayName or self.Name
end

function StageAPI.CustomStage:SetDisplayName(name)
    self.DisplayName = name or self.DisplayName or self.Name
end

function StageAPI.CustomStage:SetReplace(replaces)
    self.Replaces = replaces
end

function StageAPI.CustomStage:SetNextStage(stage)
    self.NextStage = stage
end

function StageAPI.CustomStage:SetXLStage(stage)
    self.XLStage = stage
end

function StageAPI.CustomStage:SetStageNumber(num)
    self.StageNumber = num
end

function StageAPI.CustomStage:SetIsSecondStage(isSecondStage)
    self.IsSecondStage = isSecondStage
end

function StageAPI.CustomStage:SetRoomGfx(gfx, rtype)
    if not self.RoomGfx then
        self.RoomGfx = {}
    end

    if type(rtype) == "table" then
        for _, roomtype in ipairs(rtype) do
            self.RoomGfx[roomtype] = gfx
        end
    else
        self.RoomGfx[rtype] = gfx
    end
end

function StageAPI.CustomStage:SetRooms(rooms, rtype)
    if not self.Rooms then
        self.Rooms = {}
    end

    if type(rooms) == "table" and rooms.Type ~= "RoomsList" then
        for rtype, rooms in pairs(rooms) do
            self.Rooms[rtype] = rooms
        end
    else
        rtype = rtype or RoomType.ROOM_DEFAULT
        self.Rooms[rtype] = rooms
    end
end

function StageAPI.CustomStage:SetChallengeWaves(rooms, bossChallengeRooms)
    self.ChallengeWaves = {
        Normal = rooms,
        Boss = bossChallengeRooms
    }
end

function StageAPI.CustomStage:SetGreedModeWaves(rooms, bossRooms, devilRooms)
    self.GreedWaves = {
        Normal = rooms,
        Boss = bossRooms,
        Devil = devilRooms
    }
end

function StageAPI.CustomStage:SetMusic(music, rtype)
    if not self.Music then
        self.Music = {}
    end

    if type(rtype) == "table" then
        for _, roomtype in ipairs(rtype) do
            self.Music[roomtype] = music
        end
    else
        self.Music[rtype] = music
    end
end

function StageAPI.CustomStage:SetStageMusic(music)
    self:SetMusic(music, {
        RoomType.ROOM_DEFAULT,
        RoomType.ROOM_TREASURE,
        RoomType.ROOM_CURSE,
        RoomType.ROOM_CHALLENGE,
        RoomType.ROOM_BARREN,
        RoomType.ROOM_ISAACS,
        RoomType.ROOM_SACRIFICE,
        RoomType.ROOM_DICE,
        RoomType.ROOM_CHEST,
        RoomType.ROOM_DUNGEON
    })
end

function StageAPI.CustomStage:SetTransitionMusic(music)
    self.TransitionMusic = music
    StageAPI.StopOverridingMusic(music)
end

function StageAPI.CustomStage:SetBossMusic(music, clearedMusic, intro, outro)
    self.BossMusic = {
        Fight = music,
        Cleared = clearedMusic,
        Intro = intro,
        Outro = outro
    }
end

function StageAPI.CustomStage:SetRenderStartingRoomControls(doRender)
    self.RenderStartingRoomControls = doRender
end

function StageAPI.CustomStage:SetFloorTextColor(color)
    self.FloorTextColor = color
end

function StageAPI.CustomStage:SetSpots(bossSpot, playerSpot, bgColor, dirtColor)
    self.BossSpot = bossSpot
    self.PlayerSpot = playerSpot
    self.BackgroundColor = bgColor      --info: https://imgur.com/a/HFigk7d
    self.DirtColor = dirtColor
end

function StageAPI.CustomStage:SetTrueCoopSpots(twoPlayersSpot, fourPlayersSpot, threePlayersSpot) -- if a three player spot is not defined, uses four instead.
    self.CoopSpot2P = twoPlayersSpot
    self.CoopSpot3P = threePlayersSpot
    self.CoopSpot4P = fourPlayersSpot
end

function StageAPI.CustomStage:SetBosses(bosses)
    if bosses.Pool then
        self.Bosses = bosses
    else
        self.Bosses = {
            Pool = bosses
        }
    end
end

function StageAPI.CustomStage:SetSinRooms(sins)
    if type(sins) == "string" then -- allows passing in a prefix to a room list name, which all sins can be grabbed from
        self.SinRooms = {}
        for _, sin in ipairs(StageAPI.SinsSplitData) do
            self.SinRooms[sin.ListName] = StageAPI.RoomsLists[sins .. sin.ListName]
        end
    else
        self.SinRooms = sins
    end
end

function StageAPI.CustomStage:SetStartingRooms(starting)
    self.StartingRooms = starting
end

function StageAPI.CustomStage:GenerateRoom(roomDescriptor, isStartingRoom, fromLevelGenerator, roomArgs)
    StageAPI.LogMinor("Generating room for stage " .. self:GetDisplayName())

    local roomData
    if roomDescriptor then
        roomData = roomDescriptor.Data
    end

    local rtype = (roomArgs and roomArgs.RoomType) or (roomData and roomData.Type) or RoomType.ROOM_DEFAULT
    local shape = (roomArgs and roomArgs.Shape) or (roomData and roomData.Shape) or RoomShape.ROOMSHAPE_1x1

    if self.SinRooms and (rtype == RoomType.ROOM_MINIBOSS or rtype == RoomType.ROOM_SECRET or rtype == RoomType.ROOM_SHOP) then
        local usingRoomsList
        local includedSins = {}

        if roomData then
            StageAPI.ForAllSpawnEntries(roomData, function(entry, spawn)
                for i, sin in ipairs(StageAPI.SinsSplitData) do
                    if entry.Type == sin.Type and (sin.Variant and entry.Variant == sin.Variant) and ((sin.ListName and self.SinRooms[sin.ListName]) or (sin.MultipleListName and self.SinRooms[sin.MultipleListName])) then
                        if not includedSins[i] then
                            includedSins[i] = 0
                        end

                        includedSins[i] = includedSins[i] + 1
                        break
                    end
                end
            end)
        else
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                for i, sin in ipairs(StageAPI.SinsSplitData) do
                    if entity.Type == sin.Type and (sin.Variant and entity.Variant == sin.Variant) and ((sin.ListName and self.SinRooms[sin.ListName]) or (sin.MultipleListName and self.SinRooms[sin.MultipleListName])) then
                        if not includedSins[i] then
                            includedSins[i] = 0
                        end

                        includedSins[i] = includedSins[i] + 1
                        break
                    end
                end
            end
        end

        for ind, count in pairs(includedSins) do
            local sin = StageAPI.SinsSplitData[ind]
            local listName = sin.ListName
            if count > 1 and sin.MultipleListName then
                listName = sin.MultipleListName
            end

            usingRoomsList = self.SinRooms[listName]
        end

        if usingRoomsList then
            local shape = room:GetRoomShape()
            if usingRoomsList:GetRooms(shape) then
                local newRoom = StageAPI.LevelRoom(StageAPI.Merged({
                    RoomsList = usingRoomsList,
                    RoomDescriptor = roomDescriptor,
                    RequireRoomType = self.RequireRoomTypeSin
                }, roomArgs))

                return newRoom
            end
        end
    end

    if not isStartingRoom and StageAPI.CurrentStage.Rooms and StageAPI.CurrentStage.Rooms[rtype] then

        local newRoom = StageAPI.LevelRoom(StageAPI.Merged({
            RoomsList = StageAPI.CurrentStage.Rooms[rtype],
            RoomDescriptor = roomDescriptor,
            RequireRoomType = self.RequireRoomTypeMatching
        }, roomArgs))
        return newRoom
    elseif isStartingRoom and StageAPI.CurrentStage.StartingRooms then

        local newRoom = StageAPI.LevelRoom(StageAPI.Merged({
            RoomsList = StageAPI.CurrentStage.StartingRooms,
            RoomDescriptor = roomDescriptor
        }, roomArgs))
        return newRoom
    end

    if self.Bosses and rtype == RoomType.ROOM_BOSS then
        local newRoom, boss = StageAPI.GenerateBossRoom({
            Bosses = self.Bosses,
            CheckEncountered = true,
            NoPlayBossAnim = fromLevelGenerator
        }, StageAPI.Merged({
            RoomDescriptor = roomDescriptor,
            RequireRoomType = self.RequireRoomTypeBoss
        }, roomArgs))

        return newRoom, boss
    end
end

function StageAPI.CustomStage:SetPregenerationEnabled(setTo)
    self.PregenerationEnabled = setTo
end

function StageAPI.CustomStage:GenerateLevel()
    if not self.PregenerationEnabled then
        return
    end

    local startingRoomIndex = level:GetStartingRoomIndex()
    local roomsList = level:GetRooms()
    for i = 0, roomsList.Size - 1 do
        local roomDesc = roomsList:Get(i)
        if roomDesc then
            local isStartingRoom = startingRoomIndex == roomDesc.SafeGridIndex
            local newRoom = self:GenerateRoom(roomDesc, isStartingRoom, true)
            if newRoom then
                local listIndex = roomDesc.ListIndex
                StageAPI.SetLevelRoom(newRoom, listIndex)
            end
        end
    end
end

function StageAPI.CustomStage:GetPlayingMusic()
    local roomType = room:GetType()
    local id = StageAPI.Music:GetCurrentMusicID()
    if roomType == RoomType.ROOM_BOSS then
        if self.BossMusic then
            local music = self.BossMusic
            local musicID, queue, disregardNonOverride

            if (music.Outro and (id == Music.MUSIC_JINGLE_BOSS_OVER or id == Music.MUSIC_JINGLE_BOSS_OVER2 or id == music.Outro or (type(music.Outro) == "table" and StageAPI.IsIn(music.Outro, id))))
            or (music.Intro and (id == Music.MUSIC_JINGLE_BOSS or id == music.Intro or (type(music.Intro) == "table" and StageAPI.IsIn(music.Intro, id)))) then
                if id == Music.MUSIC_JINGLE_BOSS or id == music.Intro or (type(music.Intro) == "table" and StageAPI.IsIn(music.Intro, id)) then
                    musicID, queue = music.Intro, music.Fight
                else
                    musicID, queue = music.Outro, music.Cleared
                end

                disregardNonOverride = true
            else
                local isCleared = room:GetAliveBossesCount() < 1 or room:IsClear()
                if isCleared then
                    musicID = music.Cleared
                else
                    musicID = music.Fight
                end
            end

            if type(musicID) == "table" then
                StageAPI.MusicRNG:SetSeed(room:GetDecorationSeed(), 0)
                musicID = musicID[StageAPI.Random(1, #musicID, StageAPI.MusicRNG)]
            end

            local newMusicID = StageAPI.CallCallbacks("POST_SELECT_BOSS_MUSIC", true, self, musicID, isCleared, StageAPI.MusicRNG)
            if newMusicID then
                musicID = newMusicID
            end

            if musicID then
                return musicID, not room:IsClear(), queue, disregardNonOverride
            end
        end
    elseif roomType ~= RoomType.ROOM_CHALLENGE or not room:IsAmbushActive() then
        local music = self.Music
        if music then
            local musicID = music[roomType]
            local newMusicID = StageAPI.CallCallbacks("POST_SELECT_STAGE_MUSIC", true, self, musicID, roomType, StageAPI.MusicRNG)
            if newMusicID then
                musicID = newMusicID
            end

            if musicID then
                return musicID, not room:IsClear()
            end
        end
    end
end

function StageAPI.CustomStage:OverrideRockAltEffects(rooms)
    self.OverridingRockAltEffects = rooms or true
end

function StageAPI.CustomStage:OverrideTrapdoors()
    self.OverridingTrapdoors = true
end

function StageAPI.CustomStage:SetTransitionIcon(icon, ground, bg)
    self.TransitionIcon = icon
    self.TransitionGround = ground
    self.TransitionBackground = bg
end

function StageAPI.IsSameStage(base, comp, noAlias)
    if not base then return false end

    return base.Name == comp.Name or (not noAlias and base.Alias == comp.Alias)
end

function StageAPI.CustomStage:IsStage(noAlias)
    return StageAPI.IsSameStage(StageAPI.CurrentStage, self, noAlias)
end

function StageAPI.CustomStage:IsNextStage(noAlias)
    return StageAPI.IsSameStage(StageAPI.NextStage, self, noAlias)
end

function StageAPI.CustomStage:SetRequireRoomTypeMatching()
    self.RequireRoomTypeMatching = true
end

function StageAPI.CustomStage:SetRequireRoomTypeBoss()
    self.RequireRoomTypeBoss = true
end

function StageAPI.CustomStage:SetRequireRoomTypeSin()
    self.RequireRoomTypeSin = true
end

function StageAPI.ShouldPlayStageMusic()
    return room:GetType() == RoomType.ROOM_DEFAULT or room:GetType() == RoomType.ROOM_TREASURE, not room:IsClear()
end