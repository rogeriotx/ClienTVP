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

#include "resourcemanager.h"
#include "filestream.h"
#include "resource.h"

#include <framework/core/application.h>
#include <framework/luaengine/luainterface.h>
#include <framework/platform/platform.h>
#include <framework/util/crypt.h>
#include <framework/http/http.h>
#include <queue>
#include <regex>

#if not(defined(ANDROID) || defined(FREE_VERSION))
#include <boost/process.hpp>
#endif
#include <locale>
#include <zlib.h>

#define PHYSFS_DEPRECATED
#include <physfs.h>
#ifndef __EMSCRIPTEN__
#include <zip.h>
#include <zlib.h>
#endif

#ifdef WIN32
#include <filesystem>

namespace fs = std::filesystem;
#else
#include <boost/filesystem.hpp>

namespace fs = boost::filesystem;
#endif

ResourceManager g_resources;
static const std::string INIT_FILENAME = "init.lua";
static const int BLOCK_SIZE = 1024;

void ResourceManager::init(const char *argv0)
{
#if defined(WIN32)
    char fileName[255];
    GetModuleFileNameA(NULL, fileName, sizeof(fileName));
    m_binaryPath = std::filesystem::absolute(fileName);
#elif defined(ANDROID)
    // nothing
#else
    m_binaryPath = std::filesystem::absolute(argv0);    
#endif
    PHYSFS_init(argv0);
    PHYSFS_permitSymbolicLinks(1);
}

void ResourceManager::terminate()
{
    PHYSFS_deinit();
}

bool ResourceManager::launchCorrect(const std::string& product, const std::string& app) { // curently works only on windows
#if not(defined(ANDROID) || defined(FREE_VERSION))
    auto init_path = m_binaryPath.parent_path();
    init_path /= INIT_FILENAME;
    if (std::filesystem::exists(init_path)) // debug version
        return false;

    const char* localDir = PHYSFS_getPrefDir(product.c_str(), app.c_str());
    if (!localDir)
        return false;

    auto fileName2 = m_binaryPath.stem().string();
    fileName2 = stdext::split(fileName2, "-")[0];
    stdext::tolower(fileName2);

    std::filesystem::path path(std::filesystem::u8path(localDir));
    std::error_code ec;
    auto lastWrite = std::filesystem::last_write_time(m_binaryPath, ec);
    std::filesystem::path binary = m_binaryPath;
    for (auto& entry : std::filesystem::directory_iterator(path)) {
        if (std::filesystem::is_directory(entry.path()))
            continue;

        auto fileName1 = entry.path().stem().string();
        fileName1 = stdext::split(fileName1, "-")[0];
        stdext::tolower(fileName1);
        if (fileName1 != fileName2)
            continue;

        if (entry.path().extension() == m_binaryPath.extension()) {
            std::error_code ec;
            auto writeTime = std::filesystem::last_write_time(entry.path(), ec);
            if (!ec && writeTime > lastWrite) {
                lastWrite = writeTime;
                binary = entry.path();
            }
        }
    }

    for (auto& entry : std::filesystem::directory_iterator(path)) { // remove old
        if (std::filesystem::is_directory(entry.path()))
            continue;

        auto fileName1 = entry.path().stem().string();
        fileName1 = stdext::split(fileName1, "-")[0];
        stdext::tolower(fileName1);
        if (fileName1 != fileName2)
            continue;

        if (entry.path().extension() == m_binaryPath.extension()) {
            if (binary == entry.path())
                continue;
            std::error_code ec;
            std::filesystem::remove(entry.path(), ec);
        }
    }

    if (binary == m_binaryPath)
        return false;

    boost::process::child c(binary.string());
    std::error_code ec2;
    if (c.wait_for(std::chrono::seconds(5), ec2)) {
        return c.exit_code() == 0;
    }

    c.detach();
    return true;
#else
    return false;
#endif
}

bool ResourceManager::setupWriteDir(const std::string& product, const std::string& app) {
#ifdef ANDROID
    const char* localDir = g_androidState->activity->internalDataPath;
#else
    const char* localDir = PHYSFS_getPrefDir(product.c_str(), app.c_str());
#endif

    if (!localDir) {
        g_logger.fatal(stdext::format("Unable to get local dir, error: %s", PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    if (!PHYSFS_mount(localDir, NULL, 0)) {
        g_logger.fatal(stdext::format("Unable to mount local directory '%s': %s", localDir, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    if (!PHYSFS_setWriteDir(localDir)) {
        g_logger.fatal(stdext::format("Unable to set write dir '%s': %s", localDir, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

#ifndef ANDROID
    m_writeDir = std::filesystem::path(std::filesystem::u8path(localDir));
#endif
    return true;
}

bool ResourceManager::setup()
{
    std::shared_ptr<std::vector<uint8_t>> data = nullptr;
#ifdef ANDROID
    PHYSFS_File* file = PHYSFS_openRead("data.zip");
    if (file) {
        auto data = std::make_shared<std::vector<uint8_t>>(PHYSFS_fileLength(file));
        PHYSFS_readBytes(file, data->data(), data->size());
        PHYSFS_close(file);
        if (mountMemoryData(data))
            return true;
    }
#else
    std::string localDir(PHYSFS_getWriteDir());
    std::vector<std::string> possiblePaths = { localDir, g_platform.getCurrentDir() };
    const char* baseDir = PHYSFS_getBaseDir();
    if (baseDir)
        possiblePaths.push_back(baseDir);

    for (const std::string& dir : possiblePaths) {
        if (dir == localDir || !PHYSFS_mount(dir.c_str(), NULL, 0))
            continue;

        if(PHYSFS_exists(INIT_FILENAME.c_str())) {
            g_logger.info(stdext::format("Found work dir at '%s'", dir));
            return true;
        }

        PHYSFS_unmount(dir.c_str());
    }

    for(const std::string& dir : possiblePaths) {
        if (dir != localDir && !PHYSFS_mount(dir.c_str(), NULL, 0)) {
            continue;
        }

        if (!PHYSFS_exists("data.zip")) {
            if(dir != localDir)
                PHYSFS_unmount(dir.c_str());
            continue;
        }

        PHYSFS_File* file = PHYSFS_openRead("data.zip");
        if (!file) {
            if (dir != localDir)
                PHYSFS_unmount(dir.c_str());
            continue;
        }

        auto data = std::make_shared<std::vector<uint8_t>>(PHYSFS_fileLength(file));
        PHYSFS_readBytes(file, data->data(), data->size());
        PHYSFS_close(file);
        if (dir != localDir)
            PHYSFS_unmount(dir.c_str());

        g_logger.info(stdext::format("Found work dir at '%s'", dir));
        if (mountMemoryData(data))
            return true;
    }
#endif
    if (loadDataFromSelf()) {
        g_logger.info(stdext::format("Found work dir inside binary"));
        return true;
    }

    g_logger.fatal("Unable to find working directory (or data.zip)");
    return false;
}

std::string ResourceManager::getCompactName() {
    std::string fileData;
    if (loadDataFromSelf()) {
        try {
            fileData = readFileContents(INIT_FILENAME);
        } catch (...) {
            fileData = "";
        }
        unmountMemoryData();
    }

#ifndef ANDROID
    std::vector<std::string> possiblePaths = { g_platform.getCurrentDir() };
    const char* baseDir = PHYSFS_getBaseDir();
    if (baseDir)
        possiblePaths.push_back(baseDir);

    if (fileData.empty()) {
        try {
            for (const std::string& dir : possiblePaths) {
                if (!PHYSFS_mount(dir.c_str(), NULL, 0))
                    continue;

                if (PHYSFS_exists(INIT_FILENAME.c_str())) {
                    fileData = readFileContents(INIT_FILENAME);
                    PHYSFS_unmount(dir.c_str());
                    break;
                }
                PHYSFS_unmount(dir.c_str());
            }
        } catch (...) {
            fileData = "";
        }
    }

    if (fileData.empty()) {
        try {
            for (const std::string& dir : possiblePaths) {
                std::string path = dir + "/data.zip";
                if (!PHYSFS_mount(path.c_str(), NULL, 0))
                    continue;

                if (PHYSFS_exists(INIT_FILENAME.c_str())) {
                    fileData = readFileContents(INIT_FILENAME);
                    PHYSFS_unmount(path.c_str());
                    break;
                }
                PHYSFS_unmount(path.c_str());
            }
        } catch (...) {}
    }
#endif

    std::smatch regex_match;
    if (std::regex_search(fileData, regex_match, std::regex("APP_NAME[^\"]+\"([^\"]+)"))) {
        if (regex_match.size() == 2 && regex_match[1].str().length() > 0 && regex_match[1].str().length() < 30) {
            return regex_match[1].str();
        }
    }
    return "retronia";
}

bool ResourceManager::loadDataFromSelf(bool unmountIfMounted) {
    std::shared_ptr<std::vector<uint8_t>> data = nullptr;
#ifdef ANDROID
    AAsset* file = AAssetManager_open(g_androidState->activity->assetManager, "data.zip", AASSET_MODE_BUFFER);
    if (!file)
        g_logger.fatal("Can't open data.zip from assets");
    data = std::make_shared<std::vector<uint8_t>>(AAsset_getLength(file));
    AAsset_read(file, data->data(), data->size());
    AAsset_close(file);
#else
    std::ifstream file(m_binaryPath.string(), std::ios::binary);
    if (!file.is_open())
        return false;
    file.seekg(0, std::ios_base::end);
    std::size_t size = file.tellg();
    file.seekg(0, std::ios_base::beg);
    if (size < 1024 || size > 1024 * 1024 * 256) {
        file.close();
        return false;
    }

    std::vector<uint8_t> v(1 + size);
    file.read((char*)&v[0], size);
    file.close();
    for (size_t i = 0, end = size - 128; i < end; ++i) {
        if (v[i] == 0x50 && v[i + 1] == 0x4b && v[i + 2] == 0x03 && v[i + 3] == 0x04 && v[i + 4] == 0x14) {
            uint32_t compSize = *(uint32_t*)&v[i + 18];
            uint32_t decompSize = *(uint32_t*)&v[i + 22];
            if (compSize < 1024 * 1024 * 512 && decompSize < 1024 * 1024 * 512) {
                data = std::make_shared<std::vector<uint8_t>>(&v[i], &v[v.size() - 1]);
                break;
            }
        }
    }
    v.clear();

#endif

    if (unmountIfMounted)
        unmountMemoryData();

    if (mountMemoryData(data)) {
        m_loadedFromMemory = true;
        return true;
    }

    return false;
}

bool ResourceManager::fileExists(const std::string& fileName)
{
    if (fileName.find("/downloads") != std::string::npos)
        return g_http.getFile(fileName.substr(10)) != nullptr;
    auto path = resolvePath(fileName);
    if (path.find(".part") != std::string::npos) {
        path.append("1");
    }
    return (PHYSFS_exists(path.c_str()) && !PHYSFS_isDirectory(path.c_str()));
}

bool ResourceManager::directoryExists(const std::string& directoryName)
{
    if (directoryName == "/downloads")
        return true;
    return (PHYSFS_isDirectory(resolvePath(directoryName).c_str()));
}

void ResourceManager::readFileStream(const std::string& fileName, std::iostream& out)
{
    std::string buffer(readFileContents(fileName));
    if(buffer.length() == 0) {
        out.clear(std::ios::eofbit);
        return;
    }
    out.clear(std::ios::goodbit);
    out.write(&buffer[0], buffer.length());
    out.seekg(0, std::ios::beg);
}

void ResourceManager::readFileSafe(const std::string& fullPath, std::string& buffer)
{
    PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
    if (!file)
        stdext::throw_exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

    buffer.clear();
    int fileSize = PHYSFS_fileLength(file);
    buffer.resize(fileSize, 0);
    PHYSFS_readBytes(file, (void*)&buffer[0], fileSize);
    PHYSFS_close(file);
}

std::string ResourceManager::readFileContents(const std::string& fileName, bool safe)
{
    std::string fullPath = resolvePath(fileName);
    
    if (fullPath.find("/downloads") != std::string::npos) {
        auto dfile = g_http.getFile(fullPath.substr(10));
        if (dfile)
            return std::string(dfile->response.begin(), dfile->response.end());
    }

    std::string buffer;
    if (!m_encrypted) {
        readFileSafe(fullPath, buffer);
    }

    if (safe) {
        if (m_encrypted) {
            if (!decryptOen(fullPath, buffer)) {
                readFileSafe(fullPath, buffer);
            }
        }
    }

    // skip decryption for bot configs
    if (fullPath.find("/bot/") != std::string::npos) {
        if (m_encrypted) {
            if (!decryptOen(fullPath, buffer)) {
                readFileSafe(fullPath, buffer);
            }
        }
        return buffer;
    }

    static std::string unencryptedExtensions[] = { ".otml", ".otmm", ".dmp", ".log", ".txt", ".dll", ".exe", ".zip", ".json", ".cwmmap" };

    if (m_encrypted || !m_encryptionChecked) {
        buffer.clear();
        if (!decryptOen(fullPath, buffer)) {
            bool ignore = false;
            for (auto& it : unencryptedExtensions) {
                if (fileName.find(it) == fileName.size() - it.size()) {
                    ignore = true;
                }
            }
            if (!ignore && m_encryptionChecked)
                g_logger.fatal(stdext::format("unable to decrypt file: %s", fullPath));
            else
                readFileSafe(fullPath, buffer);
            m_encryptionChecked = true;
        }
        else if (!m_encrypted) {
            m_encrypted = true;
            m_encryptionChecked = true;
        }
    } else if (!decryptBuffer(buffer)) {
        bool ignore = (m_customEncryption == 0);
        for (auto& it : unencryptedExtensions) {
            if (fileName.find(it) == fileName.size() - it.size()) {
                ignore = true;
            }
        }
        if(!ignore)
            g_logger.fatal(stdext::format("unable to decrypt file: %s", fullPath));
    }

    return buffer;
}

bool ResourceManager::isFileEncryptedOrCompressed(const std::string& fileName)
{
    std::string fullPath = resolvePath(fileName);
    std::string fileContent;

    if (fullPath.find("/downloads") != std::string::npos) {
        auto dfile = g_http.getFile(fullPath.substr(10));
        if (dfile) {
            if (dfile->response.size() < 10)
                return false;
            fileContent = std::string(dfile->response.begin(), dfile->response.begin() + 10);
        }
    }

    if (!fileContent.empty()) {
        PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
        if (!file)
            stdext::throw_exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

        int fileSize = std::min<int>(10, PHYSFS_fileLength(file));
        fileContent.resize(fileSize);
        PHYSFS_readBytes(file, (void*)&fileContent[0], fileSize);
        PHYSFS_close(file);
    }

    if (fileContent.size() < 10)
        return false;
    
    if (fileContent.substr(0, 4).compare("ENC3") == 0)
        return true;

    if ((uint8_t)fileContent[0] != 0x1f || (uint8_t)fileContent[1] != 0x8b || (uint8_t)fileContent[2] != 0x08) {
        return false;
    }

    return true;
}

bool ResourceManager::writeFileBuffer(const std::string& fileName, const uchar* data, uint size)
{
    PHYSFS_file* file = PHYSFS_openWrite(fileName.c_str());
    if(!file) {
        g_logger.error(stdext::format("unable to open file for writing '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    PHYSFS_writeBytes(file, (void*)data, size);
    PHYSFS_close(file);
    return true;
}

bool ResourceManager::writeFileStream(const std::string& fileName, std::iostream& in)
{
    std::streampos oldPos = in.tellg();
    in.seekg(0, std::ios::end);
    std::streampos size = in.tellg();
    in.seekg(0, std::ios::beg);
    std::vector<char> buffer(size);
    in.read(&buffer[0], size);
    bool ret = writeFileBuffer(fileName, (const uchar*)&buffer[0], size);
    in.seekg(oldPos, std::ios::beg);
    return ret;
}

bool ResourceManager::writeFileContents(const std::string& fileName, const std::string& data)
{
    return writeFileBuffer(fileName, (const uchar*)data.c_str(), data.size());
}

FileStreamPtr ResourceManager::openFile(const std::string& fileName, bool dontCache)
{
    std::string fullPath = resolvePath(fileName);
    if (m_encrypted || isFileEncryptedOrCompressed(fullPath) || !dontCache) {
        return FileStreamPtr(new FileStream(fullPath, readFileContents(fullPath)));
    }
    PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
    if (!file)
        stdext::throw_exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fullPath, file, false));
}

FileStreamPtr ResourceManager::appendFile(const std::string& fileName)
{
    PHYSFS_File* file = PHYSFS_openAppend(fileName.c_str());
    if(!file)
        stdext::throw_exception(stdext::format("failed to append file '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fileName, file, true));
}

FileStreamPtr ResourceManager::createFile(const std::string& fileName)
{
    PHYSFS_File* file = PHYSFS_openWrite(fileName.c_str());
    if(!file)
        stdext::throw_exception(stdext::format("failed to create file '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fileName, file, true));
}

bool ResourceManager::deleteFile(const std::string& fileName)
{
    return PHYSFS_delete(resolvePath(fileName).c_str()) != 0;
}

bool ResourceManager::makeDir(const std::string directory)
{
    return PHYSFS_mkdir(directory.c_str());
}

std::list<std::string> ResourceManager::listDirectoryFiles(const std::string& directoryPath, bool fullPath /* = false */, bool raw /*= false*/)
{
    std::list<std::string> files;
    auto path = raw ? directoryPath : resolvePath(directoryPath);
    auto rc = PHYSFS_enumerateFiles(path.c_str());

    if (!rc)
        return files;

    for (int i = 0; rc[i] != NULL; i++) {
        if(fullPath)
            files.push_back(path + "/" + rc[i]);
        else
            files.push_back(rc[i]);
    }

    PHYSFS_freeList(rc);
    files.sort();
    return files;
}

std::string ResourceManager::resolvePath(std::string path)
{
    if (!stdext::starts_with(path, "/")) {
        std::string scriptPath = "/" + g_lua.getCurrentSourcePath();
        if (!scriptPath.empty())
            path = scriptPath + "/" + path;
        else
            g_logger.traceWarning(stdext::format("the following file path is not fully resolved: %s", path));
    }
    stdext::replace_all(path, "//", "/");
    if (!PHYSFS_exists(path.c_str())) {
        if (PHYSFS_exists((path + ".part1").c_str())) {
            return path + ".part";
        }
        static const std::string layouts_prefix = "/layouts/";
        if (!m_layout.empty()) {
            if (PHYSFS_exists((layouts_prefix + m_layout + path).c_str())) {
                return layouts_prefix + m_layout + path;
            }
            else if (PHYSFS_exists((layouts_prefix + m_layout + path + ".part1").c_str())) {
                return layouts_prefix + m_layout + path + ".part";
            }
        }
        static const std::string extra_check[] = { "/mods", "/data", "/modules" };
        for (auto extra : extra_check) {
            if (PHYSFS_exists((extra + path).c_str())) {
                return extra + path;
            }
            else if (PHYSFS_exists((extra + path + ".part1").c_str())) {
                return extra + path + ".part";
            }
        }
    }
    return path;
}

std::string ResourceManager::guessFilePath(const std::string& filename, const std::string& type)
{
    if(isFileType(filename, type))
        return filename;
    return filename + "." + type;
}

bool ResourceManager::isFileType(const std::string& filename, const std::string& type)
{
    if(stdext::ends_with(filename, std::string(".") + type))
        return true;
    return false;
}

std::string ResourceManager::fileChecksum(const std::string& path) {
    static std::map<std::string, std::string> cache;
    static const int BUFSIZE = 4096;

    auto it = cache.find(path);
    if (it != cache.end())
        return it->second;

    std::ifstream file(path, std::ios::binary);

    if (!file.is_open()) {
        return "";
    }

    // Initialize the CRC value
    uLong crc = crc32(0L, Z_NULL, 0);

    // Read the file in chunks
    char buf[BUFSIZE];
    while (!file.eof()) {
        file.read(buf, BUFSIZE);
        crc = crc32(crc, (Bytef*)buf, file.gcount());
    }
    std::stringstream hexstr;
    hexstr << std::setw(8) << std::setfill('0') << std::hex << crc;
    cache[path] = hexstr.str();

    return cache[path];
}

std::map<std::string, std::string> ResourceManager::filesChecksums()
{
    std::map<std::string, std::string> ret;
#ifndef __EMSCRIPTEN__
    if (m_encrypted && !m_loadedFromArchive) {
        auto it = fs::recursive_directory_iterator(".");
        for (const auto& entry : it) {
#ifdef WIN32
            if (entry.is_regular_file()) {
#else
            if (fs::is_regular_file(entry)) {
#endif
                const auto& pathStr = entry.path().string();
                auto crc = fileChecksum(pathStr);
                std::string name(fs::relative(entry.path(), ".\\").string());
                if (name[0] != '/')
                    name = std::string("/") + name;
                stdext::replace_all(name, "\\", "/");
                ret[name] = crc;
            }
        }

        return ret;
    }
    if (!m_memoryData)
        return ret;

    zip_source_t* src;
    zip_t* za;
    zip_stat_t file_stat;
    zip_error_t error;
    zip_error_init(&error);
    zip_stat_init(&file_stat);

    if ((src = zip_source_buffer_create(m_memoryData->data(), m_memoryData->size(), 0, &error)) == NULL)
        g_logger.fatal(stdext::format("can't create source: %s", zip_error_strerror(&error)));

    if ((za = zip_open_from_source(src, ZIP_RDONLY, &error)) == NULL)
        g_logger.fatal(stdext::format("can't open zip from source: %s", zip_error_strerror(&error)));

    zip_int64_t entries = zip_get_num_entries(za, 0);
    for (zip_int64_t entry_idx = 0; entry_idx < entries; entry_idx++) {
        if (zip_stat_index(za, entry_idx, 0, &file_stat)) {
            g_logger.fatal(stdext::format("error stat-ing file at index %i: %s",
                    (int)(entry_idx), zip_strerror(za)));
        }
        if (!(file_stat.valid & ZIP_STAT_NAME)) {
            g_logger.warning(stdext::format("warning: skipping entry at index %i with invalid name.",
                    (int)entry_idx));
            continue;
        }
        std::string name(file_stat.name);
        if (name.empty()) continue;
        if (name[0] != '/')
            name = std::string("/") + name;
        if (name.back() == '/' || file_stat.size == 0) // dir
            continue;
        stdext::replace_all(name, "\\", "/");
        ret[name] = stdext::dec_to_hex(file_stat.crc);
    }

    if (zip_close(za) < 0)
        g_logger.fatal(stdext::format("can't close zip archive: %s", zip_strerror(za)));
    zip_error_fini(&error);
#endif
    return ret;
}

std::string ResourceManager::selfChecksum() {
#ifdef ANDROID
    return "";
#else
    static std::string checksum;
    if (!checksum.empty())
        return checksum;

    std::ifstream file(m_binaryPath.string(), std::ios::binary);
    if (!file.is_open())
        return "";

    std::string buffer(std::istreambuf_iterator<char>(file), {});
    file.close();

    checksum = g_crypt.crc32(buffer, false);
    return checksum;
#endif
}

void ResourceManager::updateData(const std::set<std::string>& files, bool reMount) {
#if not(defined(__EMSCRIPTEN__) || defined(FREE_VERSION))
    if (m_encrypted && !m_loadedFromArchive) {
        std::vector<std::string> tempFiles;
        bool failed = false;
        std::string failMsg;
        for (auto fileName : files) {
            if (fileName.empty())
                continue;
            if (fileName.size() > 1 && fileName[0] == '/')
                fileName = fileName.substr(1);
            auto dFile = g_http.getFile(fileName);
            if (dFile) {
                auto tempFileName = fileName + ".tmp";
                if (fs::exists(tempFileName)) {
                    remove(tempFileName.c_str());
                }

                fs::path path(fs::u8path(tempFileName));
                fs::create_directory(path.parent_path());

                BIO* tempFile = BIO_new_file(tempFileName.c_str(), "wb");
                if (!tempFile)
                {
                    failMsg = stdext::format("Failed to open file for update - %s", tempFileName);
                    failed = true;
                    break;
                }

                BIO_write(tempFile, dFile->response.data(), dFile->response.size());
                BIO_free(tempFile);
#ifdef WIN32
                SetFileAttributes(tempFileName.c_str(), FILE_ATTRIBUTE_HIDDEN);
#endif
                tempFiles.emplace_back(tempFileName);
            }
            else {
                failed = true;
                failMsg = stdext::format("Download file not found - %s", fileName);
                break;
            }
        }

        for (auto& tempFileName : tempFiles) {
            auto fileName = tempFileName.substr(0, tempFileName.size() - 4);
            if (fs::exists(fileName)) {
                remove(fileName.c_str());
            }
            if (fs::exists(tempFileName)) {
                if (rename(tempFileName.c_str(), fileName.c_str())) {
                    g_logger.info(stdext::format("Failed to rename file %s to %s", tempFileName, fileName));
                }
#ifdef WIN32
                else {
                    SetFileAttributes(fileName.c_str(), GetFileAttributes(fileName.c_str()) & ~FILE_ATTRIBUTE_HIDDEN);
                }
#endif
            }
        }

        if (failed)
            g_logger.fatal(failMsg);

        return;
    }

    if (!m_loadedFromArchive)
        g_logger.fatal("Client can be updated only when running from zip archive");

    g_logger.info(stdext::format("Updating client, %i files", files.size()));

    zip_source_t *src;
    zip_t *za;
    zip_error_t error;
    zip_error_init(&error);

    if ((src = zip_source_buffer_create(0, 0, 0, &error)) == NULL)
        return g_logger.fatal(stdext::format("can't create source: %s", zip_error_strerror(&error)));
    zip_source_keep(src);

    if ((za = zip_open_from_source(src, ZIP_TRUNCATE, &error)) == NULL)
        return g_logger.fatal(stdext::format("can't open zip from source: %s", zip_error_strerror(&error)));

    zip_error_fini(&error);

    for (auto fileName : files) {
        if (fileName.empty())
            continue;
        if (fileName.size() > 1 && fileName[0] == '/')
            fileName = fileName.substr(1);
        zip_source_t* s;
        auto dFile = g_http.getFile(fileName);
        if (dFile) {
            if ((s = zip_source_buffer(za, dFile->response.data(), dFile->response.size(), 0)) == NULL)
                return g_logger.fatal(stdext::format("can't create source buffer: %s", zip_strerror(za)));
        } else {
            PHYSFS_File* file = PHYSFS_openRead((std::string("/") + fileName).c_str());
            if (!file)
                g_logger.fatal(stdext::format("unable to open file '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

            int fileSize = PHYSFS_fileLength(file);
            void* buffer = malloc(fileSize);
            PHYSFS_readBytes(file, buffer, fileSize);
            PHYSFS_close(file);
            if ((s = zip_source_buffer(za, buffer, fileSize, 1)) == NULL)
                return g_logger.fatal(stdext::format("can't create source buffer: %s", zip_strerror(za)));
        }

        int fileIndex = zip_file_add(za, fileName.c_str(), s, ZIP_FL_OVERWRITE);
        if(fileIndex < 0)
            return g_logger.fatal(stdext::format("can't add file %s to zip archive: %s", fileName, zip_strerror(za)));
        if (zip_set_file_compression(za, fileIndex, ZIP_CM_DEFLATE, 1) != 0)
            return g_logger.fatal("Can't set file compression level");
    }

    if (zip_close(za) < 0)
        return g_logger.fatal(stdext::format("can't close zip archive: %s", zip_strerror(za)));

    zip_stat_t zst;
    if (zip_source_stat(src, &zst) < 0)
        return g_logger.fatal(stdext::format("can't stat source: %s", zip_error_strerror(zip_source_error(src))));
    
    size_t zipSize = zst.size;    

    if (zip_source_open(src) < 0)
        return g_logger.fatal(stdext::format("can't open source: %s", zip_error_strerror(zip_source_error(src))));

    PHYSFS_file* file = PHYSFS_openWrite("data.zip");
    if (!file)
        return g_logger.fatal(stdext::format("can't open data.zip for writing: %s", PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

    static const size_t CHUNK_SIZE = 1024 * 1024;
    std::vector<char> chunk(CHUNK_SIZE);
    while (zipSize > 0) {
        size_t currentChunk = std::min<size_t>(zipSize, CHUNK_SIZE);
        if ((zip_uint64_t)zip_source_read(src, chunk.data(), currentChunk) < currentChunk)
            return g_logger.fatal(stdext::format("can't read data from source: %s", zip_error_strerror(zip_source_error(src))));
        PHYSFS_writeBytes(file, chunk.data(), currentChunk);
        zipSize -= currentChunk;
    }

    PHYSFS_close(file);
    zip_source_close(src);
    zip_source_free(src);

    if (reMount) {
        unmountMemoryData();
        file = PHYSFS_openRead("data.zip");
        if (!file)
            g_logger.fatal(stdext::format("Can't open new data.zip"));

        int size = PHYSFS_fileLength(file);
        if (size < 1024)
            g_logger.fatal(stdext::format("New data.zip is invalid"));

        auto data = std::make_shared<std::vector<uint8_t>>(size);
        PHYSFS_readBytes(file, data->data(), data->size());
        PHYSFS_close(file);
        if (!mountMemoryData(data)) {
            g_logger.fatal("Error while mounting new data.zip");
        }
    }
#else
    g_logger.fatal("updateData is unsupported");
#endif
}

void ResourceManager::updateExecutable(std::string fileName)
{
#if defined(ANDROID) || defined(FREE_VERSION)
    g_logger.fatal("Executable cannot be updated on android or in free version");
#else
    if (fileName.size() <= 2) {
        g_logger.fatal("Invalid executable name");
    }

    if (fileName[0] == '/')
        fileName = fileName.substr(1);

    auto dFile = g_http.getFile(fileName);
    if (!dFile)
        g_logger.fatal(stdext::format("Cannot find executable: %s in downloads", fileName));

    fs::path path(m_binaryPath);
    if (m_encrypted && !m_loadedFromArchive) {
        auto exeName = m_binaryPath.filename().string();
        auto tempFile = exeName + ".tmp";
        std::ofstream out(tempFile, std::ios::binary | std::ios::out);
        out.write(reinterpret_cast<char*>(dFile->response.data()), dFile->response.size());
        out.close();

        if (fs::exists(path)) {
            rename(exeName.c_str(), ".tmp");
#ifdef WIN32
            SetFileAttributes(".tmp", FILE_ATTRIBUTE_HIDDEN);
#endif
            rename(tempFile.c_str(), exeName.c_str());
        }
    }
    else {
        auto newBinary = path.stem().string() + "-" + std::to_string(time(nullptr)) + path.extension().string();
        g_logger.info(stdext::format("Updating binary file: %s", newBinary));
        PHYSFS_file* file = PHYSFS_openWrite(newBinary.c_str());
        if (!file)
            return g_logger.fatal(stdext::format("can't open %s for writing: %s", newBinary, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        PHYSFS_writeBytes(file, dFile->response.data(), dFile->response.size());
        PHYSFS_close(file);

        std::filesystem::path newBinaryPath(std::filesystem::u8path(PHYSFS_getWriteDir()));
#if defined(WIN32) && not(defined(FREE_VERSION))
        installDlls(newBinaryPath);
#endif
    }
#endif
}

std::string ResourceManager::createArchive(const std::map<std::string, std::string>& files)
{
#ifdef __EMSCRIPTEN__
    return "";
#else
    if (files.empty()) return "";

    zip_source_t* src;
    zip_t* za;
    zip_error_t error;
    zip_error_init(&error);

    if ((src = zip_source_buffer_create(0, 0, 0, &error)) == NULL)
        stdext::throw_exception(stdext::format("can't create source: %s", zip_error_strerror(&error)));
    zip_source_keep(src);

    if ((za = zip_open_from_source(src, ZIP_TRUNCATE, &error)) == NULL)
        stdext::throw_exception(stdext::format("can't open zip from source: %s", zip_error_strerror(&error)));

    zip_error_fini(&error);

    for (auto& file : files) {
        if (file.first.empty() || file.second.empty())
            continue;

        zip_source_t* s;
        if ((s = zip_source_buffer(za, file.second.data(), file.second.size(), 0)) == NULL)
            stdext::throw_exception(stdext::format("can't create source buffer: %s", zip_strerror(za)));

        std::string fileName = file.first;
        if (fileName.size() > 1 && fileName[0] == '/')
            fileName = fileName.substr(1);

        int fileIndex = zip_file_add(za, fileName.c_str(), s, ZIP_FL_OVERWRITE);
        if (fileIndex < 0)
            stdext::throw_exception(stdext::format("can't add file %s to zip archive: %s", fileName, zip_strerror(za)));
//        if (zip_set_file_compression(za, fileIndex, ZIP_CM_DEFLATE, 1) != 0)
//            stdext::throw_exception("Can't set file compression level");
    }

    if (zip_close(za) < 0)
        stdext::throw_exception(stdext::format("can't close zip archive: %s", zip_strerror(za)));

    zip_stat_t zst;
    if (zip_source_stat(src, &zst) < 0)
        stdext::throw_exception(stdext::format("can't stat source: %s", zip_error_strerror(zip_source_error(src))));

    size_t zipSize = zst.size;

    if (zip_source_open(src) < 0)
        stdext::throw_exception(stdext::format("can't open source: %s", zip_error_strerror(zip_source_error(src))));

    std::string data(zipSize, '\0');
    if ((zip_uint64_t)zip_source_read(src, data.data(), data.size()) != data.size())
        stdext::throw_exception(stdext::format("can't read data from source: %s", zip_error_strerror(zip_source_error(src))));

    zip_source_close(src);
    zip_source_free(src);

    return data;
#endif
}

std::map<std::string, std::string> ResourceManager::decompressArchive(std::string dataOrPath)
{
    std::map<std::string, std::string> ret;
#ifdef __EMSCRIPTEN__
    return ret;
#else
    if (dataOrPath.size() < 64) {
        dataOrPath = readFileContents(dataOrPath);
    }

    zip_source_t* src;
    zip_t* za;
    zip_stat_t file_stat;
    zip_error_t error;
    zip_error_init(&error);
    zip_stat_init(&file_stat);

    if ((src = zip_source_buffer_create(dataOrPath.c_str(), dataOrPath.size(), 0, &error)) == NULL)
        stdext::throw_exception(stdext::format("unpackArchive: can't create source: %s", zip_error_strerror(&error)));

    if ((za = zip_open_from_source(src, ZIP_RDONLY, &error)) == NULL)
        stdext::throw_exception(stdext::format("unpackArchive: can't open zip from source: %s", zip_error_strerror(&error)));

    zip_int64_t entries = zip_get_num_entries(za, 0);
    for (zip_int64_t entry_idx = 0; entry_idx < entries; entry_idx++) {
        if (zip_stat_index(za, entry_idx, 0, &file_stat)) {
            stdext::throw_exception(stdext::format("unpackArchive: error stat-ing file at index %i: %s",
                                          (int)(entry_idx), zip_strerror(za)));
        }
        if (!(file_stat.valid & ZIP_STAT_NAME)) {
            g_logger.warning(stdext::format("warning: skipping entry at index %i with invalid name.",
                                            (int)entry_idx));
            continue;
        }
        std::string name(file_stat.name);
        if (name.empty()) continue;
        if (name[0] != '/')
            name = std::string("/") + name;
        if (name.back() == '/' || file_stat.size == 0) // dir
            continue;
        stdext::replace_all(name, "\\", "/");

        zip_file_t* file = zip_fopen_index(za, entry_idx, 0);
        if(!file)
            stdext::throw_exception(stdext::format("can't open file from zip archive: %s - %s", name, zip_strerror(za)));
        std::string buffer(file_stat.size, '\0');
        zip_fread(file, buffer.data(), buffer.size());
        zip_fclose(file);
        ret[name] = std::move(buffer);
    }

    if (zip_close(za) < 0)
        stdext::throw_exception(stdext::format("can't close zip archive: %s", zip_strerror(za)));
    zip_error_fini(&error);
    return ret; // success
#endif
}

#if defined(WIN32) && not(defined(FREE_VERSION))
void ResourceManager::installDlls(std::filesystem::path dest)
{
    static std::list<std::string> dlls = {
        {"libEGL.dll"},
        {"libGLESv2.dll"},
        {"d3dcompiler_46.dll"},
        {"d3dcompiler_47.dll"}
    };

    int added_dlls = 0;
    for (auto& dll : dlls) {
        auto dll_path = m_binaryPath.parent_path();
        dll_path /= dll;
        if (!std::filesystem::exists(dll_path)) {
            continue;
        }
        auto out_path = dest;
        out_path /= dll;
        if (std::filesystem::exists(out_path)) {
            continue;
        }
        std::filesystem::copy_file(dll_path, out_path);
    }
}
#endif

#if defined(WITH_ENCRYPTION) && !defined(ANDROID)
void ResourceManager::encrypt(const std::string& seed) {
    const std::string dirsToCheck[] = { "data", "modules", "mods", "layouts" };
    const std::string luaExtension = ".lua";

    g_logger.setLogFile("encryption.log");
    g_logger.info("----------------------");

    std::queue<std::filesystem::path> toEncrypt;
    // you can add custom files here
    toEncrypt.push(std::filesystem::path(INIT_FILENAME));

    for (auto& dir : dirsToCheck) {
        if (!std::filesystem::exists(dir))
            continue;
        for(auto&& entry : std::filesystem::recursive_directory_iterator(std::filesystem::path(dir))) {
            if (!std::filesystem::is_regular_file(entry.path()))
                continue;
            std::string str(entry.path().string());
            // skip encryption for bot configs
            if (str.find("game_bot") != std::string::npos && str.find("default_config") != std::string::npos) {
                continue;
            }
            toEncrypt.push(entry.path());
        }
    }

    bool encryptForAndroid = seed.find("android") != std::string::npos;
    uint32_t uintseed = seed.empty() ? 0 : stdext::adler32((const uint8_t*)seed.c_str(), seed.size());

    while (!toEncrypt.empty()) {
        auto it = toEncrypt.front();
        toEncrypt.pop();
        std::ifstream in_file(it, std::ios::binary);
        if (!in_file.is_open())
            continue;
        std::string buffer(std::istreambuf_iterator<char>(in_file), {});
        in_file.close();
        if (buffer.size() >= 4 && buffer.substr(0, 4).compare("ENC3") == 0)
            continue; // already encrypted

        if (!encryptForAndroid && it.extension().string() == luaExtension && it.filename().string() != INIT_FILENAME) {
            std::string bytecode = g_lua.generateByteCode(buffer, it.string());
            if (bytecode.length() > 10) {
                buffer = bytecode;
                g_logger.info(stdext::format("%s - lua bytecode encrypted", it.string()));
            } else {
                g_logger.info(stdext::format("%s - lua but not bytecode encrypted", it.string()));
            }
        }

        if (!encryptBuffer(buffer, uintseed)) { // already encrypted
            g_logger.info(stdext::format("%s - already encrypted", it.string()));
            continue;
        }

        std::ofstream out_file(it, std::ios::binary);
        if (!out_file.is_open())
            continue;
        out_file.write(buffer.data(), buffer.size());
        out_file.close();
        g_logger.info(stdext::format("%s - encrypted", it.string()));
    }
}
#endif 

bool ResourceManager::decryptBuffer(std::string& buffer) {
#ifdef FREE_VERSION
    return false;
#else
    if (buffer.size() < 5)
        return true;

    if (buffer.substr(0, 4).compare("ENC3") != 0) {
        return false;
    }

    uint64_t key = *(uint64_t*)&buffer[4];
    uint32_t compressed_size = *(uint32_t*)&buffer[12];
    uint32_t size = *(uint32_t*)&buffer[16];
    uint32_t adler = *(uint32_t*)&buffer[20];

    if (compressed_size < buffer.size() - 24)
        return false;

    g_crypt.bdecrypt((uint8_t*)&buffer[24], compressed_size, key);
    std::string new_buffer;
    new_buffer.resize(size);
    unsigned long new_buffer_size = new_buffer.size();
    if (uncompress((uint8_t*)new_buffer.data(), &new_buffer_size, (uint8_t*)&buffer[24], compressed_size) != Z_OK)
        return false;

    uint32_t addlerCheck = stdext::adler32((const uint8_t*)&new_buffer[0], size);
    if (adler != addlerCheck) {
        uint32_t cseed = adler ^ addlerCheck;
        if (m_customEncryption == 0) {
            m_customEncryption = cseed;
        }
        if ((addlerCheck ^ m_customEncryption) != adler) {
            return false;
        }
    }

    buffer = new_buffer;
    return true;
#endif
}

#ifdef WITH_ENCRYPTION
bool ResourceManager::encryptBuffer(std::string& buffer, uint32_t seed) {
    if (buffer.size() >= 4 && buffer.substr(0, 4).compare("ENC3") == 0)
        return false; // already encrypted

    // not random beacause it would require to update to new files each time
    int64_t key = stdext::adler32((const uint8_t*)&buffer[0], buffer.size());
    key <<= 32;
    key += stdext::adler32((const uint8_t*)&buffer[0], buffer.size() / 2);

    std::string new_buffer(24 + buffer.size() * 2, '0');
    new_buffer[0] = 'E';
    new_buffer[1] = 'N';
    new_buffer[2] = 'C';
    new_buffer[3] = '3';

    unsigned long dstLen = new_buffer.size() - 24;
    if (compress((uint8_t*)&new_buffer[24], &dstLen, (const uint8_t*)buffer.data(), buffer.size()) != Z_OK) {
        g_logger.error("Error while compressing");
        return false;
    }
    new_buffer.resize(24 + dstLen);

    *(int64_t*)&new_buffer[4] = key;
    *(uint32_t*)&new_buffer[12] = (uint32_t)dstLen;
    *(uint32_t*)&new_buffer[16] = (uint32_t)buffer.size();
    *(uint32_t*)&new_buffer[20] = ((uint32_t)stdext::adler32((const uint8_t*)&buffer[0], buffer.size())) ^ seed;

    g_crypt.bencrypt((uint8_t*)&new_buffer[0] + 24, new_buffer.size() - 24, key);
    buffer = new_buffer;
    return true;
}
#endif

void ResourceManager::setLayout(std::string layout)
{
    stdext::tolower(layout);
    stdext::replace_all(layout, "/", "");
    if (layout == "default") {
        layout = "";
    }
    if (!layout.empty() && !PHYSFS_exists((std::string("/layouts/") + layout).c_str())) {
        g_logger.error(stdext::format("Layour %s doesn't exist, using default", layout));
        return;
    }
    m_layout = layout;
}

bool ResourceManager::mountMemoryData(const std::shared_ptr<std::vector<uint8_t>>& data)
{
    if (!data || data->size() < 1024)
        return false;

    if (PHYSFS_mountMemory(data->data(), data->size(), nullptr,
                           "memory_data.zip", "/", 0)) {
        if (PHYSFS_exists(INIT_FILENAME.c_str())) {
            m_loadedFromArchive = true;
            m_memoryData = data;
            return true;
        }
        PHYSFS_unmount("memory_data.zip");
    }
    return false;
}

void ResourceManager::unmountMemoryData()
{
    if (!m_memoryData)
        return;

    if (!PHYSFS_unmount("memory_data.zip")) {
        g_logger.fatal(stdext::format("Unable to unmount memory data", PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    }
    m_memoryData = nullptr;
    m_loadedFromMemory = false;
    m_loadedFromArchive = false;
}

void ResourceManager::checkEncryption()
{
    std::string decrypted;
    m_encrypted = decryptOen(INIT_FILENAME, decrypted);
}

bool ResourceManager::decryptOen(const std::string& fullPath, std::string& buffer, bool clean)
{
    if (!clean && fullPath.find(".part") != std::string::npos) {
        return decryptOenParts(fullPath, buffer);
    }

    PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
    if (!file)
        stdext::throw_exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

    int fileSize = PHYSFS_fileLength(file);
    bool isInit = fullPath.find(INIT_FILENAME) != std::string::npos;

    if ((isInit && fileSize < 32) || fileSize < 16) {
        PHYSFS_close(file);
        return false;
    }

    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        PHYSFS_close(file);
        return false;
    }

    unsigned char key[32];
    unsigned char iv[16];

    if (isInit)
        PHYSFS_readBytes(file, key, 16);

    PHYSFS_readBytes(file, iv, 16);

    if (isInit)
        PHYSFS_readBytes(file, key + 16, 16);

    if (!isInit) {
        getOenKey(key);
    }

    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv) != 1) {
        PHYSFS_close(file);
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }

    std::string decrypted;
    char inbuf[BLOCK_SIZE];
    int inlen;
    char outbuf[BLOCK_SIZE + EVP_MAX_BLOCK_LENGTH];
    int outlen;
    while ((inlen = PHYSFS_readBytes(file, inbuf, sizeof(inbuf))) > 0) {
        if (EVP_DecryptUpdate(ctx, (unsigned char*)outbuf, &outlen, (const unsigned char*)inbuf, inlen) != 1) {
            PHYSFS_close(file);
            EVP_CIPHER_CTX_free(ctx);
            return false;
        }
        decrypted.append(outbuf, outlen);
    }

    if (EVP_DecryptFinal_ex(ctx, (unsigned char*)outbuf, &outlen) != 1) {
        PHYSFS_close(file);
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    decrypted.append(outbuf, outlen);

    PHYSFS_close(file);
    EVP_CIPHER_CTX_free(ctx);

    uncompressOenFile(decrypted, buffer);

    return true;
}

void ResourceManager::uncompressOenFile(const std::string& decrypted, std::string& buffer)
{
    uLongf decompressed_length = decrypted.size() * 2;
    std::vector<Bytef> decompressed_buffer(decompressed_length);
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = decrypted.size();
    strm.next_in = (Bytef*)decrypted.data();
    strm.avail_out = decompressed_length;
    strm.next_out = decompressed_buffer.data();

    inflateInit(&strm);

    int ret;
    do {
        ret = inflate(&strm, Z_NO_FLUSH);
        if (ret == Z_STREAM_END) break;
        if (strm.avail_out == 0) {
            uLongf newSize = strm.total_out * 2;
            decompressed_buffer.resize(newSize);
            strm.avail_out = newSize - strm.total_out;
            strm.next_out = decompressed_buffer.data() + strm.total_out;
        }
    } while (ret == Z_OK);
    inflateEnd(&strm);

    buffer.append((const char*)decompressed_buffer.data(), strm.total_out);
}

bool ResourceManager::decryptOenParts(const std::string& fullPath, std::string& decrypted)
{
    int part = 0;
    while (true) {
        std::string partPath = stdext::format("%s%d", fullPath, ++part);
        if (!PHYSFS_exists(partPath.c_str())) break;
        decryptOen(partPath, decrypted, true);
    }

    return true;
}

void ResourceManager::getOenKey(unsigned char* dest)
{
    PHYSFS_File* in = PHYSFS_openRead(INIT_FILENAME.c_str());
    if (!in)
    {
        g_logger.fatal(stdext::format("getOenKey Failed to open file - %s", INIT_FILENAME));
        return;
    }

    unsigned char vi[16];
    PHYSFS_readBytes(in, dest, 16);
    PHYSFS_readBytes(in, vi, 16);
    PHYSFS_readBytes(in, dest + 16, 16);
    PHYSFS_close(in);
}