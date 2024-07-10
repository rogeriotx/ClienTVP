#include <framework/global.h>
#include <framework/core/clock.h>

#include "packet_player.h"
#define PHYSFS_DEPRECATED
#include <physfs.h>

PacketPlayer::~PacketPlayer()
{
    if (m_event)
        m_event->cancel();
    if (m_logoutEvent)
        m_logoutEvent->cancel();
}

PacketPlayer::PacketPlayer()
{
    m_timeAlignment = 0;
    m_timeTotal = 0;
    m_timeCurrent = 0;
    m_timeSleep = 0;
    m_nextPacket = 0;

    m_speed = 1.0;
    m_fastForward = false;
}

bool PacketPlayer::load(const std::string& file)
{
    m_camFile = file;
#ifdef ANDROID
    std::ifstream f(std::string("records/") + m_camFile);
#else
    std::filesystem::current_path(std::filesystem::u8path(PHYSFS_getWriteDir()));
    std::ifstream f(std::filesystem::path("records") / m_camFile);
#endif
    callLuaField("onCamLoad", m_camFile);
    if (!f.is_open()) {
        callLuaField("onCamLoadFail", true);
        return false;
    }

    std::string type, packetHex;
    ticks_t time;

    while (f >> type >> time >> packetHex) {
        std::string packetStr = boost::algorithm::unhex(packetHex);
        auto packet = std::make_shared<std::vector<uint8_t>>(packetStr.begin(), packetStr.end());

        if (m_input.size() == 0) {
            m_timeAlignment = time;
        }

        if (type == "<") {
            m_input.push_back(std::make_pair(time, packet));
        }
        else if (type == ">") {
            m_output.push_back(std::make_pair(time, packet));
        }
    }
    setTotalPlayTime((m_input.begin() + (m_input.size() - 1))->first - m_timeAlignment);
    if (m_input.empty()) {
        callLuaField("onCamLoadFail", true);
        return false;
    }

    callLuaField("onCamLoadFail", false);
    return true;
}

void PacketPlayer::stop()
{
    if (m_event)
        m_event->cancel();

    m_event = nullptr;
    m_camFile.clear();
    m_input.clear();
    m_output.clear();
    callLuaField("onCamEnd");
}

void PacketPlayer::start(std::function<void(std::shared_ptr<std::vector<uint8_t>>)> recvCallback,
    std::function<void(boost::system::error_code)> disconnectCallback)
{
    m_timeCurrent = Timer::tickCount();
    setNextPacket(0);
    setSpeed(1.0);
    m_timeForward = 0;

    m_recvCallback = recvCallback;
    m_disconnectCallback = disconnectCallback;
    m_event = g_dispatcher.scheduleEvent(std::bind(&PacketPlayer::process, this), 50);
    callLuaField("onCamStart");
}

bool PacketPlayer::isPlaying() const
{
    return m_event != nullptr;
}

void PacketPlayer::onOutputPacket(const OutputMessagePtr& packet)
{
    if (packet->getDataBuffer()[0] == 0x14) { // logout
        m_disconnectCallback(boost::asio::error::eof);
        stop();
    }
}

void PacketPlayer::increaseSpeed()
{
    setSpeed(std::min<double>(256.0, getSpeed() * 2));
}

void PacketPlayer::decreaseSpeed()
{
    setSpeed(std::max<double>(0.0625, getSpeed() / 2.0));
}

double PacketPlayer::getSpeed()
{
    return m_speed;
}

std::string PacketPlayer::getCamFile()
{
    return m_camFile;
}

void PacketPlayer::setSpeed(double speed)
{
    double oldSpeed = m_speed;
    m_speed = (speed < 0.01) ? 0.0 : speed;
    callLuaField("onSpeedChange", m_speed, oldSpeed);
}

uint64_t PacketPlayer::getCurrentPlayTime()
{
    return getNextPacket();
}

uint64_t PacketPlayer::getTotalPlayTime()
{
    return m_timeTotal;
}

void PacketPlayer::setTotalPlayTime(uint64_t total)
{
    m_timeTotal = total;
}

uint64_t PacketPlayer::StrToMiliseconds(std::string str)
{
    int seconds, minutes, hours;
    sscanf(str.c_str(), "%d:%d:%d", &hours, &minutes, &seconds);

    uint64_t ret = 0;
    ret += seconds * 1000;
    ret += minutes * 60 * 1000;
    ret += hours * 60 * 60 * 1000;

    return ret;
}

std::shared_ptr<std::vector<uint8_t>> PacketPlayer::getPacket()
{
    if (m_input.empty()) {
        static std::shared_ptr<std::vector<uint8_t>> emptyPacket;
        return emptyPacket;
    }

    auto packet = m_input.front();

    m_input.erase(m_input.begin());

    m_timeAlignment = packet.first;
    return packet.second;
}

uint64_t PacketPlayer::getNextPacket()
{
    return m_nextPacket;
}

void PacketPlayer::setNextPacket(uint64_t next)
{
    m_nextPacket = next;
}

void PacketPlayer::wait(double timescale /* = 1.0 */)
{
    if (m_input.empty()) {
        return;
    }

    auto packet = m_input.begin();

    setNextPacket(getNextPacket() + (packet->first - m_timeAlignment));

    if (m_fastForward) {
        m_timeSleep = 0;
    }
    else {
        m_timeSleep = static_cast<uint64_t>(Timer::tickCount() + ((packet->first - m_timeAlignment) / timescale));
    }
}

void PacketPlayer::forceProcess()
{
    if (m_event) {
        m_event->execute();
    }
}

void PacketPlayer::process()
{
    if (m_input.empty()) {
        m_disconnectCallback(boost::asio::error::eof);
        stop();
        return;
    }
    if (getSpeed() < 0.01 && !m_fastForward) {
        m_event = g_dispatcher.scheduleEvent(std::bind(&PacketPlayer::process, this), 100);
        callLuaField("onCamPause");
        return;
    }
    auto packet = getPacket();
    if (packet == nullptr) {
        setSpeed(1.0);
        m_disconnectCallback(boost::asio::error::eof);
        stop();
        return;
    }

    if (m_timeForward > getNextPacket()) {
        if (getSpeed() != 2000.0) {
            setSpeed(2000.0);
        }
    }
    else if (m_fastForward) {
        setSpeed(1.0);
        m_fastForward = false;
    }

    m_recvCallback(packet);
    wait(getSpeed());

    if (!m_input.empty()) {
        m_event = g_dispatcher.scheduleEvent(std::bind(&PacketPlayer::process, this), m_timeSleep - Timer::tickCount());
    }
    else {
        m_logoutEvent = g_dispatcher.scheduleEvent([=] {
            logout();
            }, 2000);
    }
    callLuaField("onCamProcessing");
}

void PacketPlayer::logout()
{
    if (getSpeed() == 0) {
        m_logoutEvent = g_dispatcher.scheduleEvent([=] {
            logout();
            }, 500);
        return;
    }

    if (m_logoutEvent)
        m_logoutEvent->cancel();

    m_disconnectCallback(boost::asio::error::eof);
    stop();
}

void PacketPlayer::fastForward(const std::string& text)
{
    if (m_input.empty())
        return;

    m_timeForward = StrToMiliseconds(text);
    m_fastForward = true;
}
