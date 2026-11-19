# Port do cliente TVP para o servidor pbOT (TFS 8.00)

Objetivo: usar o layout do cliente TVP (OTCv8 com fonte, layout `retro`) com o servidor pbOT (`X:\src` + `X:\data`), substituindo o `old_pbOT_Client` (binario fechado). Referencias usadas: modulos/mods do old e o servidor TVP (`TVP-Ravenor-Server/TVP/src`) para comparar o protocolo.

Build: `MSBuild vc16\otclient.vcxproj /p:Configuration=OpenGL /p:Platform=Win32` (vcpkg `x86-windows-static`).
Servidor em `init.lua`: `192.168.100.254:7171:800`.

## Fase 1 - Protocolo (C++ `src/client`)
| Ponto | Ajuste |
|---|---|
| Item (`addItem`) | le duracao (flag + u32 ms + u8 stopTime), raridade u8, tier u8 -> feature `GameItemDurationRarityTier` (128) |
| Criatura (`0x61`) | bytes star/icon do TVP opcionais -> `GameCreatureStarIcon` (129, desligada) |
| `0x6E/0x70/0x71/0x78` | u16 `lootCategory` apos o item |
| `0x70` | slot u8; lista do NPC u16; compra amount u8 -> `GamePbotProtocol` (130) |
| `0x60` autoloot / `0x5E` `0x5F` loot category | parse + envio, API Lua (`addAutoLoot`, `g_game.addLootCategory`...) |
| `0x54` UpdateContainer | `g_game.onUpdateContainer` |
| `0x6A` | sem stackpos (feature `GameTileAddThingWithStackpos` desligada) |
| Sprites | `PATH_SPRITES` -> `things/800`; HD so com `.cwm` (evita divisao por zero) |
| Login | lista de personagens com level/vocation/outfit (`protocollogin.lua`) |

`features.lua` reescrito para o protocolo 8.00 (sem wings/aura/shaders/custom attributes/new walking/custom font).

## Fase 2 - Itens
- Contador de duracao no `UIItem` (C++).
- Moldura de raridade do old (`rarity_frames.png`, 5 cores incl. brutal), icone de tier t1-t10, icone de loot category (`gamelib/ui/uiitem.lua`).
- Janela de autoloot (`game_interface`) e de loot category (`game_containers`) + menus de contexto.

## Fase 3 - Modulos do servidor (portados do old)
- `game_crafting` (91), `game_tasks` (92), `game_forge` (93), `game_tooltip` (0x9F/0x9E; hover em `uiitem.lua`).
- Botoes no `game_sidemenu` (Tasks, Tracker, Forge, Crafting); Battlepass/Bestiary ocultos; `game_tooltips` do TVP desligado.
- Market: parse de `0xF6` sem lista de itens.

## Fase 4 - Mods do old (`mods/`)
`game_bossbar` (61), `game_buffs` (100), `game_characterstats` (106), `game_citywar` (120), `game_guildmanagement` (ext 1 + opcode 51), `game_marketplace` (179), `game_titles`, `game_healthbars`.
- `game_sidemenu.addModuleButton()` (topmenu fica oculto no TVP); altura do sidemenu dinamica.
- Corelib: `UIRadioGroup:setEnabled`, `UIPopupMenu:addText`.

## Interface (layout 8.0)
- Hotkeys com Select object / Use on yourself / target / crosshair.
- Inventario: Soul/Cap e faixa de condicoes do Classic UI (icones 9x9, estados 8.x).
- Options: Show Levels in Console, Enable Lights, Ambient Light.
- Crafting redesenhado; Battle sem duplicar no reload; `tooltipItem` oculto por padrao.

## Pendente
- Janela de outfit sem mounts (outfit do TVP e 7.72).
- Sem modulo de cliente: inspect (107), pontos (89), dungeons (109).
- Servidor: `addItem(ITEM_BAG, 1)` sem byte de tier (`protocolgame.cpp`); `missile id 41` invalido em algum script.
- `data/things/800/Tibia.spr` (136 MB) fora do git - copiar do old_pbOT_Client.
