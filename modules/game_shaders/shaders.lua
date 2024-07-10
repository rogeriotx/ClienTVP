function init()

  -- MAP SHADERS
 
	g_shaders.createShader("map_default", "/shaders/map/map_default_vertex", "/shaders/map/map_default_fragment")  
 
    g_shaders.createShader("map_heat", "/shaders/map/map_vertex", "/shaders/map/map_heat_fragment")

	g_shaders.createShader("map_toxic_fog", "/shaders/map/map_vertex", "/shaders/map/map_toxic_fog", false)
	g_shaders.addTexture("map_toxic_fog", "/shaders/map/textures/clouds.png")	

    g_shaders.createShader("map_fog", "/shaders/map/map_vertex", "/shaders/map/map_fog_fragment")  
    g_shaders.addTexture("map_fog", "/shaders/map/textures/clouds.png")

	g_shaders.createShader("map_LightFog", "/shaders/map/map_light_fog_vertex", "/shaders/map/map_light_fog_fragment")
	g_shaders.addTexture("map_LightFog", "/shaders/map/textures/light_fog.png")
	
	g_shaders.createShader("map_HeavyFog", "/shaders/map/map_heavy_fog_vertex", "/shaders/map/map_heavy_fog_fragment")
	g_shaders.addTexture("map_HeavyFog", "/shaders/map/textures/heavy_fog.png")
	
	g_shaders.createShader("map_LightRain", "/shaders/map/map_light_rain_vertex", "/shaders/map/map_light_rain_fragment")
	g_shaders.addTexture("map_LightRain", "/shaders/map/textures/light_rain.png")
	g_shaders.addTexture("map_LightRain", "/shaders/map/textures/light_fog.png")
	
	g_shaders.createShader("map_HeavyRain", "/shaders/map/map_heavy_rain_vertex", "/shaders/map/map_heavy_rain_fragment")
	g_shaders.addTexture("map_HeavyRain", "/shaders/map/textures/heavy_rain.png")
	g_shaders.addTexture("map_HeavyRain", "/shaders/map/textures/heavy_fog.png")
	
	g_shaders.createShader("map_HeavyRainLightning", "/shaders/map/map_heavy_rain_lightning_vertex", "/shaders/map/map_heavy_rain_lightning_fragment")
	g_shaders.addTexture("map_HeavyRainLightning", "/shaders/map/textures/heavy_rain.png")
	g_shaders.addTexture("map_HeavyRainLightning", "/shaders/map/textures/heavy_fog.png")
	g_shaders.addTexture("map_HeavyRainLightning", "/shaders/map/textures/lightning.png")
	
	g_shaders.createShader("map_LightSandstorm", "/shaders/map/map_light_sandstorm_vertex", "/shaders/map/map_light_sandstorm_fragment")
	g_shaders.addTexture("map_LightSandstorm", "/shaders/map/textures/light_sandstorm.png")
	g_shaders.addTexture("map_LightSandstorm", "/shaders/map/textures/sand_fog.png")
	
	g_shaders.createShader("map_HeavySandstorm", "/shaders/map/map_heavy_sandstorm_vertex", "/shaders/map/map_heavy_sandstorm_fragment")
	g_shaders.addTexture("map_HeavySandstorm", "/shaders/map/textures/heavy_sandstorm.png")
	g_shaders.addTexture("map_HeavySandstorm", "/shaders/map/textures/sand_fog.png")
	
	g_shaders.createShader("map_MapLightSandstormDistortion", "/shaders/map/map_light_sandstorm_vertex", "/shaders/map/map_light_sandstorm_distortion_fragment")
	g_shaders.addTexture("map_LightSandstormDistortion", "/shaders/map/textures/light_sandstorm.png")
	
	g_shaders.createShader("map_HeavySandstormDistortion", "/shaders/map/map_heavy_sandstorm_vertex", "/shaders/map/map_heavy_sandstorm_distortion_fragment")
	g_shaders.addTexture("map_HeavySandstormDistortion", "/shaders/map/textures/heavy_sandstorm.png")
	
	g_shaders.createShader("map_Distortion", "/shaders/map/map_default_vertex", "/shaders/map/map_distortion_fragment")
	
	g_shaders.createShader("map_snow", "/shaders/map/map_vertex", "/shaders/map/map_snow", false)
	
	g_shaders.createShader("map_LightSnow", "/shaders/map/map_light_snow_vertex", "/shaders/map/map_light_snow_fragment")
	g_shaders.addTexture("map_LightSnow", "/shaders/map/textures/light_snow.png")
	g_shaders.addTexture("map_LightSnow", "/shaders/map/textures/light_fog.png")
	
	g_shaders.createShader("map_HeavySnow", "/shaders/map/map_heavy_snow_vertex", "/shaders/map/map_heavy_snow_fragment")
	g_shaders.addTexture("map_HeavySnow", "/shaders/map/textures/heavy_snow.png")
	g_shaders.addTexture("map_HeavySnow", "/shaders/map/textures/light_fog.png")
	
	g_shaders.createShader("map_Sepia", "/shaders/map/map_default_vertex", "/shaders/map/map_filter_sepia")
	
	g_shaders.createShader("map_Grey", "/shaders/map/map_default_vertex", "/shaders/map/map_grayscale_fragment")
	
	g_shaders.createShader("map_Noise", "/shaders/map/map_default_vertex", "/shaders/map/map_noise_fragment")
	
	g_shaders.createShader("map_OldTV", "/shaders/map/map_default_vertex", "/shaders/map/map_oldtv_fragment")
	
	g_shaders.createShader("map_Pulse", "/shaders/map/map_default_vertex", "/shaders/map/map_pulse_fragment")
	
	g_shaders.createShader("map_death", "/shaders/map/map_vertex_with_static", "/shaders/map/map_death", false)
	g_shaders.addTexture("map_death", "/images/shaders/purpleneon.png")
	
	g_shaders.createShader("map_dark", "/shaders/map/map_vertex_with_static", "/shaders/map/map_dark", false)
	g_shaders.addTexture("map_dark", "/images/shaders/purpleneon.png")
	
	g_shaders.createShader("map_magma", "/shaders/map/map_vertex_with_static", "/shaders/map/map_magma", false)
	g_shaders.addTexture("map_magma", "/images/shaders/magma.png")
	
	g_shaders.createShader("red_alarm", "/shaders/map/map_vertex", "/shaders/map/red_alarm", false)
	
	g_shaders.createShader("black_screen", "/shaders/map/map_vertex", "/shaders/map/black_screen", false)
	
  -- EFFECT SHADER

	g_shaders.createShader("WidgetGlow", "/shaders/widget/widget_default_vertex", "/shaders/widget/pepega")
	g_shaders.createShader("AetherEnhancement", "/shaders/effects/aether_enhancement_vertex", "/shaders/effects/aether_enhancement_fragment", true)
	
	
  
   -- ITEMS SHADER
  
  g_shaders.createShader("magic_rarity", "/shaders/items/magic_vertex", "/shaders/items/magic_fragment", true)
  g_shaders.addTexture("magic_rarity", "/images/shaders/noise.png")
  
  g_shaders.createShader("rare_rarity", "/shaders/items/rare_vertex", "/shaders/items/rare_fragment", true)
  g_shaders.addTexture("rare_rarity", "/images/shaders/noise.png")
  
  g_shaders.createShader("epic_rarity", "/shaders/items/epic_vertex", "/shaders/items/epic_fragment", true)
  g_shaders.addTexture("epic_rarity", "/images/shaders/noise.png")
  
  g_shaders.createShader("legendary_rarity", "/shaders/items/legendary_vertex", "/shaders/items/legendary_fragment", true)
  g_shaders.addTexture("legendary_rarity", "/images/shaders/noise.png")

  
  -- OUTFIT SHADER
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit/outfit_default_vertex", "/shaders/outfit/outfit_default_fragment")
  
  -- OUTFIT NEWS
  
  g_shaders.createOutfitShader("Circle", "/shaders/outfit/outfit_circle_vertex", "/shaders/outfit/outfit_circle_fragment")
  
  g_shaders.createOutfitShader("Shimmering", "/shaders/outfit/outfit_shimmering_vertex", "/shaders/outfit/outfit_shimmering_fragment")
  
  g_shaders.createOutfitShader("Shine", "/shaders/outfit/outfit_shine_vertex", "/shaders/outfit/outfit_shine_fragment")
  
  g_shaders.createOutfitShader("Blood", "/shaders/outfit/outfit_blood_vertex", "/shaders/outfit/outfit_blood_fragment")
  g_shaders.addTexture("Blood", "/images/shaders/blood.png")
  
  g_shaders.createOutfitShader("Camouflage", "/shaders/outfit/outfit_camouflage_vertex", "/shaders/outfit/outfit_camouflage_fragment")
  g_shaders.addTexture("Camouflage", "/images/shaders/camouflage.png")
  
  g_shaders.createOutfitShader("Cosmos", "/shaders/outfit/outfit_cosmos_vertex", "/shaders/outfit/outfit_cosmos_fragment")
  g_shaders.addTexture("Cosmos", "/images/shaders/galaxy1.png")
  
  g_shaders.createOutfitShader("Flash", "/shaders/outfit/outfit_flash_vertex", "/shaders/outfit/outfit_flash_fragment")
  g_shaders.addTexture("Flash", "/images/shaders/gold.png")
  
  g_shaders.createOutfitShader("Glitch", "/shaders/outfit/outfit_glitch_vertex", "/shaders/outfit/outfit_glitch_fragment")
  g_shaders.addTexture("Glitch", "/images/shaders/noise.png")
  
  g_shaders.createOutfitShader("Gold", "/shaders/outfit/outfit_gold_vertex", "/shaders/outfit/outfit_gold_fragment")
  g_shaders.addTexture("Gold", "/images/shaders/gold.png")
  
  g_shaders.createOutfitShader("Ice", "/shaders/outfit/outfit_ice_vertex", "/shaders/outfit/outfit_ice_fragment")
  g_shaders.addTexture("Ice", "/images/shaders/ice2.png")
  
  g_shaders.createOutfitShader("Purple Neon", "/shaders/outfit/outfit_purpleneon_vertex", "/shaders/outfit/outfit_purpleneon_fragment")
  g_shaders.addTexture("Purple Neon", "/images/shaders/purpleneon.png")
  
  g_shaders.createOutfitShader("Purple Sky", "/shaders/outfit/outfit_purplesky_vertex", "/shaders/outfit/outfit_purplesky_fragment")
  g_shaders.addTexture("Purple Sky", "/images/shaders/purplesky.png")
  
  g_shaders.createOutfitShader("Stars", "/shaders/outfit/outfit_stars_vertex", "/shaders/outfit/outfit_stars_fragment")
  g_shaders.addTexture("Stars", "/images/shaders/stars.png")
  
  g_shaders.createOutfitShader("Static", "/shaders/outfit/outfit_static_vertex", "/shaders/outfit/outfit_static_fragment")
  g_shaders.addTexture("Static", "/images/shaders/static.png")
  
  g_shaders.createOutfitShader("Sun", "/shaders/outfit/outfit_sun_vertex", "/shaders/outfit/outfit_sun_fragment")
  g_shaders.addTexture("Sun", "/images/shaders/sun.png")
  
  g_shaders.createOutfitShader("Brazil", "/shaders/outfit/outfit_brazil_vertex", "/shaders/outfit/outfit_brazil_fragment")
  g_shaders.addTexture("Brazil", "/images/shaders/brazil.png")

  g_shaders.createOutfitShader("outfit_black", "/shaders/outfit_blacklayer_vertex", "/shaders/outfit_blacklayer_fragment")
  
   -- DIP TEST
	g_shaders.createOutfitShader("Enterprise", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine15")
	g_shaders.addTexture("Enterprise", "/images/shaders/flare.png")
	
	g_shaders.createOutfitShader("Flaming", "/shaders/outfit/expand_vertex", "/shaders/outfit/flame2")
	g_shaders.addTexture("Flaming", "/images/shaders/flare.png")
	
	g_shaders.createOutfitShader("Blue Bloohs", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine8")
	
	g_shaders.createOutfitShader("Green Bloohs", "/shaders/outfit/expand_vertex", "/shaders/outfit/bloohs_green")
	
	g_shaders.createOutfitShader("Red Bloohs", "/shaders/outfit/expand_vertex", "/shaders/outfit/bloohs_red")
	
	g_shaders.createOutfitShader("Yellow Bloohs", "/shaders/outfit/expand_vertex", "/shaders/outfit/bloohs_white")
	
	g_shaders.createOutfitShader("Blue Dortmond", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine11")
	
	g_shaders.createOutfitShader("Red Dortmond", "/shaders/outfit/expand_vertex", "/shaders/outfit/dortmond_red")
	
	g_shaders.createOutfitShader("White Dortmond", "/shaders/outfit/expand_vertex", "/shaders/outfit/dortmond_white")
	
	g_shaders.createOutfitShader("Green Dortmond", "/shaders/outfit/expand_vertex", "/shaders/outfit/dortmond_green")
	
	g_shaders.createOutfitShader("Yellow Dortmond", "/shaders/outfit/expand_vertex", "/shaders/outfit/dortmond_yellow")
	
	g_shaders.createOutfitShader("Pink Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine111")
	
	g_shaders.createOutfitShader("Blue Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/energizer_blue")
	
	g_shaders.createOutfitShader("Red Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/energizer_red")
	
	g_shaders.createOutfitShader("Yellow Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/energizer_yellow")
	
	g_shaders.createOutfitShader("White Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/energizer_white")
	
	g_shaders.createOutfitShader("Orange Energizer", "/shaders/outfit/expand_vertex", "/shaders/outfit/energizer_orange")
	
	g_shaders.createOutfitShader("Yellow Pixent", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine122")
	
	g_shaders.createOutfitShader("Green Pixent", "/shaders/outfit/expand_vertex", "/shaders/outfit/pixent_green")
	
	g_shaders.createOutfitShader("Blue Pixent", "/shaders/outfit/expand_vertex", "/shaders/outfit/pixent_blue")
	
	g_shaders.createOutfitShader("Green Confused", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine12")
	
	g_shaders.createOutfitShader("White Confused", "/shaders/outfit/expand_vertex", "/shaders/outfit/confused_white")
	
	g_shaders.createOutfitShader("Orange Confused", "/shaders/outfit/expand_vertex", "/shaders/outfit/confused_orange")
	
	g_shaders.createOutfitShader("Yellow Confused", "/shaders/outfit/expand_vertex", "/shaders/outfit/confused_yellow")
	
	g_shaders.createOutfitShader("Red Confused", "/shaders/outfit/expand_vertex", "/shaders/outfit/confused_red")
	
	g_shaders.createOutfitShader("Blue Kaos", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine13")
	
	g_shaders.createOutfitShader("Grape Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine133")
	
	g_shaders.createOutfitShader("Red Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/red_ozeus")
	
	g_shaders.createOutfitShader("Blue Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/blue_ozeus")
	
	g_shaders.createOutfitShader("Yellow Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/yellow_ozeus")
	
	g_shaders.createOutfitShader("Green Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/green_ozeus")
	
	g_shaders.createOutfitShader("White Ozeus", "/shaders/outfit/expand_vertex", "/shaders/outfit/white_ozeus")
	
	g_shaders.createOutfitShader("Cinetic", "/shaders/outfit/expand_vertex", "/shaders/outfit/shine14")
		g_shaders.addTexture("Cinetic", "/images/shaders/flare.png")
	
	g_shaders.createOutfitShader("Blue Lumni", "/shaders/outfit/expand_vertex", "/shaders/outfit/blue_lumni")
	
	g_shaders.createOutfitShader("Red Lumni", "/shaders/outfit/expand_vertex", "/shaders/outfit/red_lumni")
	
	g_shaders.createOutfitShader("Green Lumni", "/shaders/outfit/expand_vertex", "/shaders/outfit/green_lumni")
	
	g_shaders.createOutfitShader("Yellow Lumni", "/shaders/outfit/expand_vertex", "/shaders/outfit/yellow_lumni")
	
	g_shaders.createOutfitShader("Shine", "/shaders/outfit/outfit_line_vertex", "/shaders/outfit/outfit_line_fragment")
	
	g_shaders.createOutfitShader("line_green", "/shaders/outfit/outfit_outlinegreen_vertex", "/shaders/outfit/outfit_outlinegreen_fragment")
	
	g_shaders.createOutfitShader("Out Red", "/shaders/outfit/outfit_outlinered_vertex", "/shaders/outfit/outfit_outlinered_fragment")
	
	g_shaders.createOutfitShader("Out Rainbow", "/shaders/outfit/outline_rainbow_vertex", "/shaders/outfit/outline_rainbow_fragment")
	
	g_shaders.createOutfitShader("outred", "/shaders/outfit/outline_red_vertex", "/shaders/outfit/outline_red_fragment")
	
	g_shaders.createOutfitShader("Rainbow", "/shaders/outfit/rainbow_vertex", "/shaders/outfit/rainbow_fragment")
	
	g_shaders.createOutfitShader("Glitch", "/shaders/outfit/retro_vertex", "/shaders/outfit/retro_fragment")
	
	g_shaders.createOutfitShader("brazil", "/shaders/outfit/outfit_brazil_vertex", "/shaders/outfit/outfit_brazil_fragment")
	
	g_shaders.createOutfitShader("outblack", "/shaders/outfit/outfit_outlineblack_vertex", "/shaders/outfit/outfit_outlineblack_fragment")
	
	g_shaders.createOutfitShader("Out Grey", "/shaders/outfit/outfit_outlinegrey_vertex", "/shaders/outfit/outfit_outlinegrey_fragment")
      
   -- OUTLINE
   
  g_shaders.createOutfitShader("Highlight", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/creature_highlight")
  
  g_shaders.createOutfitShader("Rage", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/rage_shader")
  
  g_shaders.createOutfitShader("Freeze", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_freeze")
  
  g_shaders.createOutfitShader("Fire", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_fire")
  
  g_shaders.createOutfitShader("Friend", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_friend_fragment")
  
  g_shaders.createOutfitShader("Enemy", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_enemy_fragment")
  
  
  
  
   -- CORES ANIMADAS
  
  g_shaders.createOutfitShader("LightBlueOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_light_blue_fragment")
   
  g_shaders.createOutfitShader("BlueOTL", "/shaders/outline/expand_vertex", "/shaders/outline/shine8")
  
  g_shaders.createOutfitShader("RedOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_red_fragment")
  
  g_shaders.createOutfitShader("DarkRedOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_dark_red_fragment")
  
  g_shaders.createOutfitShader("GreenOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_green_fragment")
  
  g_shaders.createOutfitShader("PurpleOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_purple_fragment")
  
  g_shaders.createOutfitShader("WhiteOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_white_fragment")
  
  g_shaders.createOutfitShader("YellowOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_yellow_fragment")
  
  
  

   -- CORES ESTATICAS
   
   	g_shaders.createOutfitShader("LightBlueStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_light_blue_static_fragment")
	
	g_shaders.createOutfitShader("BlueStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_blue_static_fragment")
	
	g_shaders.createOutfitShader("RedStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_red_static_fragment")
	
	g_shaders.createOutfitShader("DarkRedStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_dark_red_static_fragment")
	
	g_shaders.createOutfitShader("PurpleStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_purple_static_fragment")
	
	g_shaders.createOutfitShader("WhiteStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_white_static_fragment")
	
	g_shaders.createOutfitShader("GreenStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_green_static_fragment")
	
	g_shaders.createOutfitShader("YellowStaticOTL", "/shaders/outfit/outfit_outline_vertex", "/shaders/outline/outline_yellow_static_fragment")
  
end

function terminate()
end
