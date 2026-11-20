function init()
  connect(g_game, { onClientVersionChange = updateFeatures })
end

function terminate()
  disconnect(g_game, { onClientVersionChange = updateFeatures })
end

function updateFeatures(version)
    g_game.resetFeatures()
    if version <= 0 then
      return
    end
    
    -- ===== pbOT server (TFS 8.00 custom, X:\src) =====
    -- Somente features que NAO alteram o protocolo ou que o servidor realmente envia.
    -- Espelha modules/game_features do old_pbOT_Client.
    g_game.enableFeature(GameExtendedOpcode)
    g_game.enableFeature(GamePurseSlot)
    g_game.enableFeature(GameUnjustifiedPoints)
    g_game.enableFeature(GamePlayerMarket)
    g_game.enableFeature(GameCreatureWalkthrough)   -- AddCreature: byte unpass
    g_game.enableFeature(GameCreatureEmblems)       -- AddCreature: emblem quando !known
    g_game.enableFeature(GamePlayerMounts)          -- AddOutfit: lookMount u16
    g_game.enableFeature(GameNameOnNpcTrade)
    -- GameTileAddThingWithStackpos: NAO - servidor nao envia stackpos no 0x6A (sendAddTileItem/sendAddCreature)
    g_game.enableFeature(GamePremiumExpiration)     -- sendBasicData (0x9F) manda u32
    g_game.enableFeature(GameItemDurationRarityTier) -- addItem: duracao/raridade/tier
    g_game.enableFeature(GamePbotProtocol)          -- sendShop u16, compra amount u8, 0x70 com slot u8
    g_game.enableFeature(GameDoublePlayerGoodsMoney) -- sendSaleItemList: dinheiro u64
    g_game.enableFeature(GameForceAllowItemHotkeys) -- local
    g_game.enableFeature(GameSpritesU32)            -- things/800/Tibia.otfi: extended = true
    g_game.enableFeature(GameNewWalking)
    
    -- render/local only (TVP engine)
    g_game.enableFeature(GameDontMergeAnimatedText)

    -- NAO habilitar com este servidor (quebram o protocolo):
    -- GameAnimatedTextCustomFont, GameWingsAndAura, GameWingOffset, GameDrawAuraOnTop,
    -- GameOutfitShaders, GameItemCustomAttributes, GameCreatureStarIcon,
    -- GameSpritesAlphaChannel (things/800/Tibia.otfi: transparency = false), GameClientPing

    -- GameNewWalking: NAO ligar aqui. O servidor liga via pacote 0x43 (sendFeatures) quando
    -- detecta o OTCv8 no login; ligar estatico quebra servidores sem suporte.
    if DEVLOPMENT_MODE then
        g_game.enableFeature(GameBot)
    else
        g_game.enableFeature(GameNoDebug)
    end

    if(version >= 770) then
        g_game.enableFeature(GameLooktypeU16)
        g_game.enableFeature(GameMessageStatements)
        g_game.enableFeature(GameLoginPacketEncryption)
        g_game.enableFeature(GamePlayerAddons)
        g_game.enableFeature(GameNewOutfitProtocol)
        -- GameFasterAnimations: NAO ligar. Dobra o ciclo das pernas por tile e em speed alta
        -- troca o frame a cada 20ms (pisca/"ghost"). O old_pbOT_Client nao usa.
    end

    if(version >= 780) then
        g_game.enableFeature(GamePlayerStamina)
        g_game.enableFeature(GameNewFluids)
        g_game.enableFeature(GameMessageLevel)
        g_game.enableFeature(GamePlayerStateU16)
    end

    if(version >= 790) then
        g_game.enableFeature(GameWritableDate)
    end

    if(version >= 840) then
        g_game.enableFeature(GameProtocolChecksum)
        g_game.enableFeature(GameAccountNames)
        g_game.enableFeature(GameDoubleFreeCapacity)
    end

    if(version >= 841) then
        g_game.enableFeature(GameChallengeOnLogin)
        g_game.enableFeature(GameMessageSizeCheck)
    end

    if(version >= 854) then
        g_game.enableFeature(GameCreatureEmblems)
    end

    if(version >= 860) then
        g_game.enableFeature(GameAttackSeq)
    end

    if(version >= 862) then
        g_game.enableFeature(GamePenalityOnDeath)
    end

    if(version >= 870) then
        g_game.enableFeature(GameDoubleExperience)
        g_game.enableFeature(GamePlayerMounts)
        g_game.enableFeature(GameSpellList)
    end

    if(version >= 910) then
        g_game.enableFeature(GameNameOnNpcTrade)
        g_game.enableFeature(GameTotalCapacity)
        g_game.enableFeature(GameSkillsBase)
        g_game.enableFeature(GamePlayerRegenerationTime)
        g_game.enableFeature(GameChannelPlayerList)
        g_game.enableFeature(GameEnvironmentEffect)
        g_game.enableFeature(GameItemAnimationPhase)
    end

    if(version >= 940) then
        g_game.enableFeature(GamePlayerMarket)
    end

    if(version >= 960) then
        g_game.enableFeature(GameSpritesU32)
        g_game.enableFeature(GameOfflineTrainingTime)
    end

    if(version >= 963) then
        g_game.enableFeature(GameAdditionalVipInfo)
    end

    if(version >= 972) then
        g_game.enableFeature(GameDoublePlayerGoodsMoney)
    end

    if(version >= 980) then
        g_game.enableFeature(GamePreviewState)
        g_game.enableFeature(GameClientVersion)
    end

    if(version >= 981) then
        g_game.enableFeature(GameLoginPending)
        g_game.enableFeature(GameNewSpeedLaw)
    end

    if(version >= 984) then
        g_game.enableFeature(GameContainerPagination)
        g_game.enableFeature(GameBrowseField)
    end

    if(version >= 1000) then
        g_game.enableFeature(GameThingMarks)
        g_game.enableFeature(GamePVPMode)
    end

    if(version >= 1035) then
        g_game.enableFeature(GameDoubleSkills)
        g_game.enableFeature(GameBaseSkillU16)
    end

    if(version >= 1036) then
        g_game.enableFeature(GameCreatureIcons)
        g_game.enableFeature(GameHideNpcNames)
    end

    if(version >= 1038) then
        g_game.enableFeature(GamePremiumExpiration)
    end

    if(version >= 1050) then
        g_game.enableFeature(GameEnhancedAnimations)
    end

    if(version >= 1053) then
        g_game.enableFeature(GameUnjustifiedPoints)
    end

    if(version >= 1054) then
        g_game.enableFeature(GameExperienceBonus)
    end

    if(version >= 1055) then
        g_game.enableFeature(GameDeathType)
    end

    if(version >= 1057) then
        g_game.enableFeature(GameIdleAnimations)
    end

    if(version >= 1061) then
        g_game.enableFeature(GameOGLInformation)
    end

    if(version >= 1071) then
        g_game.enableFeature(GameContentRevision)
    end

    if(version >= 1072) then
        g_game.enableFeature(GameAuthenticator)
    end

    if(version >= 1074) then
        g_game.enableFeature(GameSessionKey)
    end

    if(version >= 1080) then
        g_game.enableFeature(GameIngameStore)
    end

    if(version >= 1092) then
        g_game.enableFeature(GameIngameStoreServiceType)
    end

    if(version >= 1093) then
        g_game.enableFeature(GameIngameStoreHighlights)
    end

    if(version >= 1094) then
        g_game.enableFeature(GameAdditionalSkills)
    end
    
    if(version >= 1100) then
        g_game.enableFeature(GamePrey)    
    end
    
    if(version >= 1200) then
      g_game.enableFeature(GameSequencedPackets)
      --g_game.enableFeature(GameSendWorldName)
      g_game.enableFeature(GamePlayerStateU32)
      g_game.enableFeature(GameTibia12Protocol)
    end
    
    modules.game_things.load()
end
