-- CONFIG
APP_NAME = "Ravenor Online"  -- important, change it, it's name for config dir and files in appdata
APP_VERSION = 1       -- client version for updater and login to identify outdated client
DEFAULT_LAYOUT = "retro" -- on android it's forced to "mobile", check code bellow
DEVLOPMENT_MODE = not g_resources.isEncrypted()--true

DLL_CHECKSUM = { {"d3dcompiler_47.dll", "58b0c8ba"}, {"libEGL.dll", "3592d8f0"}, {"libGLESv2.dll", "27c4f73a"} }
BAD_FILES = {"lam", "engine.spr", "LanEngine.key", "LanEngine.dll", "opengl32.dll"}
BAD_PROCESSES = {"NinjaRipper.exe", "injhelper.exe", "ripdump.exe"}
BAD_DLLS = {"intruder.dll", "d3dx8d.dll", "d3dwrap.dll"}

-- If you don't use updater or other service, set it to updater = ""
Services = {
  website = "https://ravenor.online", -- currently not used
  -- updater = "https://patch.ravenor.online/api/updater.php", -- Comentado: EMAC / Descomentado: Versão antiga
--   stats = "",
--   crash = "http://otclient.ovh/api/crash.php",
--   feedback = "http://otclient.ovh/api/feedback.php",
--   status = "http://otclient.ovh/api/status.php"
  accessAccountWebsite = "https://ravenor.online/account/login"
}

discordInviteLink = "https://discord.gg/unTqBsa"

--g_proxy.addProxy("proxy-us01.ravenor.online", 7162, 0)
--g_proxy.addProxy("proxy-us02.ravenor.online", 7162, 0)
--g_proxy.addProxeu y("proxy-us03.ravenor.online", 7162, 0)
--g_proxy.addProxy("proxy-uk01.ravenor.online", 7162, 0)
math.randomseed(os.time())

local proxyId = math.random(1,9)
vpsPort = tonumber(6580 + proxyId)
g_proxy.addProxy("p01.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p02.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p03.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p04.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p05.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p06.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p07.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p08.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p09.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p10.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p11.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p12.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p13.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p14.ravenor.online", vpsPort, 0)
g_proxy.addProxy("p15.ravenor.online", vpsPort, 0)

-- g_proxy.addProxy("5.188.238.75", 7171, 0)

-- Servers accept http login url, websocket login url or ip:port:version
Servers = {
  -- TS = "23.95.79.111:7162:772" --TesteServer
  --Ravenor = "5.188.238.75:443:772", --Oficial
  Proxy = "127.0.0.1:17171:772"
}

--Server = "ws://otclient.ovh:3000/"
--Server = "ws://127.0.0.1:88/"
--USE_NEW_ENERGAME = true -- uses entergamev2 based on websockets instead of entergame
ALLOW_CUSTOM_SERVERS = false -- if true it shows option ANOTHER on server list

g_app.setName("Ravenor Online")
g_app.setVersion("4.1")
-- CONFIG END

-- print first terminal message
g_logger.info(os.date("== application started at %b %d %Y %X"))
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ') made by ' .. g_app.getAuthor() .. ' built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch())

if not g_resources.directoryExists("/data") then
  g_logger.fatal("Data dir doesn't exist.")
end

if not g_resources.directoryExists("/modules") then
  g_logger.fatal("Modules dir doesn't exist.")
end

-- settings
g_configs.loadSettings("/config.otml")

-- set layout
local settings = g_configs.getSettings()
local layout = DEFAULT_LAYOUT
if g_app.isMobile() then
  layout = "mobile"
elseif settings:exists('layout') then
  layout = settings:getValue('layout')
end
g_resources.setLayout(layout)

-- load mods
g_modules.discoverModules()
g_modules.ensureModuleLoaded("corelib")
  
local function loadModules()
  -- libraries modules 0-99
  g_modules.autoLoadModules(99)
  g_modules.ensureModuleLoaded("gamelib")

  -- client modules 100-499
  g_modules.autoLoadModules(499)
  g_modules.ensureModuleLoaded("client")

  -- game modules 500-999
  g_modules.autoLoadModules(999)
  g_modules.ensureModuleLoaded("game_interface")

  -- mods 1000-9999
  g_modules.autoLoadModules(9999)
end

-- report crash
if type(Services.crash) == 'string' and Services.crash:len() > 4 and g_modules.getModule("crash_reporter") then
  g_modules.ensureModuleLoaded("crash_reporter")
end


-- run updater, must use data.zip
if type(Services.updater) == "string" and Services.updater:len() > 4 and (g_resources.isLoadedFromArchive() or g_resources.isEncrypted()) and g_modules.getModule("updater") then
  -- local launcher_arguments = ""
  -- if string.find(g_app.getStartupOptions(), "--launcher=") then -- if opened by
    
  --   local paths = string.split(g_app.getStartupOptions(), "--launcher=")
  
  --   local launcher_path = string.split(paths[2]:trim(), ".exe")[1] .. ".exe"
  --   local client_path = string.split(paths[1], "--client=")[2]:trim()
  
  --   g_app.setLauncherPath(launcher_path)
  --   launcher_arguments = "--game=ravenor --client=" .. client_path .. ""
  --   g_app.restartArgs({ launcher_arguments })
  -- end
  -- modules.updater.setRestartArgs(launcher_arguments)
  g_modules.ensureModuleLoaded("updater")
  return Updater.init(loadModules)
end
loadModules()