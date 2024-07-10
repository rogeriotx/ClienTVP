/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <framework/core/application.h>
#include <framework/core/resourcemanager.h>
#include <framework/core/eventdispatcher.h>
#include <framework/luaengine/luainterface.h>
#include <framework/http/http.h>
#include <framework/platform/crashhandler.h>
#include <framework/platform/platformwindow.h>
#include <framework/platform/platform.h>
#include <client/client.h>
#include <framework/core/configmanager.h>
#include <client/spritemanager.h>

#ifdef WIN32
#include <framework/core/splash.h>
#endif
#include <regex>

#ifdef ANDROID
#include <boost/filesystem.hpp>
#endif

#ifdef WIN32
std::unordered_map<std::string, std::string> parseToMap(const std::string& input, const std::string& variable)
{
    std::unordered_map<std::string, std::string> dlls;
    std::regex regex(variable + "\\s*=\\s*\\{\\s*(.*)\\s*\\}");
    std::smatch match;

    if (std::regex_search(input, match, regex))
    {
        std::string pair_list = match[1];

        std::regex pair_regex("\\{\\s*\"(.*?)\"\\s*,\\s*\"(.*?)\"\\s*\\}");
        std::smatch pair_match;

        std::string::const_iterator iter = pair_list.cbegin();
        std::string::const_iterator end = pair_list.cend();
        while (std::regex_search(iter, end, pair_match, pair_regex))
        {
            std::string key = pair_match[1];
            std::string value = pair_match[2];
            dlls[key] = value;
            iter = pair_match[0].second;
        }
    }

    return dlls;
}

std::vector<std::string> parseToVector(const std::string& input, const std::string& variable)
{
    std::vector<std::string> files;
    std::regex regex(variable + "\\s*=\\s*\\{\\s*(.*?)\\s*\\}");
    std::smatch match;

    if (std::regex_search(input, match, regex))
    {
        std::string file_list = match[1];

        std::regex filename_regex("\"(.*?)\"");
        std::smatch filename_match;

        std::string::const_iterator iter = file_list.cbegin();
        std::string::const_iterator end = file_list.cend();
        while (std::regex_search(iter, end, filename_match, filename_regex))
        {
            std::string file = filename_match[1];
            files.push_back(file);
            iter = filename_match[0].second;
        }
    }

    return files;
}

bool scanThirdParty()
{
    auto init = g_resources.readFileContents("init.lua");
    auto dllChecksum = parseToMap(init, "DLL_CHECKSUM");
    auto badFiles = parseToVector(init, "BAD_FILES");
    auto badProcesses = parseToVector(init, "BAD_PROCESSES");
    auto badDlls = parseToVector(init, "BAD_DLLS");

    for (auto& it : dllChecksum) {
        auto crc = g_resources.fileChecksum(it.first);
        if (crc != it.second) {
            return true;
        }
    }

    for (auto& badFile : badFiles) {
        if (std::filesystem::exists(badFile)) {
            return true;
        }
    }

    auto processes = g_platform.getProcesses();
    for (auto& badProcesse : badProcesses) {
        if (std::find(processes.begin(), processes.end(), badProcesse) != processes.end()) {
            return true;
        }
    }

    auto dlls = g_platform.getDlls();
    for (auto& badDll : badDlls) {
        if (std::find(dlls.begin(), dlls.end(), badDll) != dlls.end()) {
            return true;
        }
    }

    return false;
}
#endif

int main(int argc, const char* argv[]) {
    std::vector<std::string> args(argv, argv + argc);

#ifdef CRASH_HANDLER
    installCrashHandler();
#endif

#ifdef WIN32
    // std::thread splashThread([]() {
    //     g_splash.defineClass();
    //     if (!g_splash.registerClass()) {
    //         return;
    //     }
    //     if (!g_splash.loadBitmap()) {
    //         return;
    //     }
    //     g_splash.createWindow();
    //     g_splash.show();
    //     });
#endif

    // initialize resources
    g_resources.init(argv[0]);
    std::string compactName = g_resources.getCompactName();
    g_logger.setLogFile(compactName + ".log");

    // setup application name and version
    g_app.setName("Ravenor Online");
    g_app.setCompactName(compactName);
    g_app.setVersion("3.2");

#ifdef WITH_ENCRYPTION
    if (std::find(args.begin(), args.end(), "--encrypt") != args.end()) {
        g_lua.init();
        g_resources.encrypt(args.size() >= 3 ? args[2] : "");
        std::cout << "Encryption complete" << std::endl;
#ifdef WIN32
        MessageBoxA(NULL, "Encryption complete", "Success", 0);
#endif
        return 0;
    }
#endif

    if (g_resources.launchCorrect(g_app.getName(), g_app.getCompactName())) {
        return 0; // started other executable
    }

    // initialize application framework and otclient
    g_app.init(args);
    g_client.init(args);
    g_http.init();

    bool testMode = std::find(args.begin(), args.end(), "--test") != args.end();
    if (testMode) {
        g_logger.setTestingMode();    
    }

    // find script init.lua and run it
    g_resources.setupWriteDir(g_app.getName(), g_app.getCompactName());
    g_resources.setup();
	g_configs.loadSettings("/config.otml");

#ifndef ANDROID
    if (g_resources.isEncrypted()) {
        if (std::filesystem::exists(".tmp")) {
            remove(".tmp");
        }
    }
#endif

    if (!g_lua.safeRunScript("init.lua")) {
        if (g_resources.isLoadedFromArchive() && !g_resources.isLoadedFromMemory() &&
            g_resources.loadDataFromSelf(true)) {
            g_logger.error("Unable to run script init.lua! Trying to run version from memory.");
            if (!g_lua.safeRunScript("init.lua")) {
                g_resources.deleteFile("data.zip"); // remove incorrect data.zip
                g_logger.fatal("Unable to run script init.lua from binary file!\nTry to run client again.");
            }
        } else {
            g_logger.fatal("Unable to run script init.lua!");
        }
    }

    if (testMode) {
        if (!g_lua.safeRunScript("test.lua")) {
            g_logger.fatal("Can't run test.lua");
        }
    }

#ifdef WIN32
    if (scanThirdParty()) {
        return 0;
    }

    // support for progdn proxy system, if you don't have this dll nothing will happen
    // however, it is highly recommended to use otcv8 proxy system
    LoadLibraryA("progdn32.dll");
#endif

    // g_splash.destroy();
    // splashThread.join();

	g_sprites.init();
    // the run application main loop
    g_app.run();

#ifdef CRASH_HANDLER
    uninstallCrashHandler();
#endif

    // unload modules
    g_app.deinit();

    // terminate everything and free memory
    g_http.terminate();
    g_client.terminate();
	
    g_app.terminate();
    return 0;
}

#ifdef ANDROID
#include <framework/platform/androidwindow.h>

android_app* g_androidState = nullptr;
void android_main(struct android_app* state)
{
    g_mainThreadId = g_dispatcherThreadId = g_graphicsThreadId = std::this_thread::get_id();
    g_androidState = state;

    state->userData = nullptr;
    state->onAppCmd = +[](android_app* app, int32_t cmd) -> void {
       return g_androidWindow.handleCmd(cmd);
    };
    state->onInputEvent = +[](android_app* app, AInputEvent* event) -> int32_t {
        return g_androidWindow.handleInput(event);
    };
    state->activity->callbacks->onNativeWindowResized = +[](ANativeActivity* activity, ANativeWindow* window) -> void {
        g_graphicsDispatcher.scheduleEventEx("updateWindowSize", [] {
            g_androidWindow.updateSize();
        }, 500);
    };
    state->activity->callbacks->onContentRectChanged = +[](ANativeActivity* activity, const ARect* rect) -> void {
        g_graphicsDispatcher.scheduleEventEx("updateWindowSize", [] {
            g_androidWindow.updateSize();
        }, 500);
    };

    bool terminated = false;
    g_window.setOnClose([&] {
        terminated = true;
    });
    while(!g_window.isVisible() && !terminated)
        g_window.poll(); // init window
    // run app
    const char* args[] = { "ravenor Online.apk" };
    main(1, args);
    std::exit(0); // required!
}
#endif
