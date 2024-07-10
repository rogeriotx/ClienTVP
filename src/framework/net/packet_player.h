#pragma once

#include <deque>
#include <framework/core/eventdispatcher.h>
#include <framework/net/outputmessage.h>
#include <framework/core/timer.h>

// @bindclass
class PacketPlayer : public LuaObject {
public:
    PacketPlayer();
    virtual ~PacketPlayer();

    void stop();

    bool load(const std::string& file);

    void start(std::function<void(std::shared_ptr<std::vector<uint8_t>>)> recvCallback,
        std::function<void(boost::system::error_code)> disconnectCallback);
    void forceProcess();

    bool isPlaying() const;

    void onOutputPacket(const OutputMessagePtr& packet);

    double getSpeed();
    void setSpeed(double speed);
    void increaseSpeed();
    void decreaseSpeed();
    std::string getCamFile();
    void fastForward(const std::string& text);
    void logout();

    uint64_t StrToMiliseconds(std::string str);
    std::shared_ptr<std::vector<uint8_t>> getPacket();

    uint64_t getNextPacket();
    uint64_t getTotalPlayTime();
    uint64_t getCurrentPlayTime();

protected:
    void wait(double timescale = 1.0);
    void setNextPacket(uint64_t next);
    void setTotalPlayTime(uint64_t total);

private:
    void process();

    ticks_t m_currentPlayTime;

    double m_speed;

    uint64_t m_timeAlignment;
    uint64_t m_timeTotal;
    uint64_t m_timeCurrent;
    uint64_t m_timeSleep;
    uint64_t m_timeForward;
    uint64_t m_nextPacket;

    bool m_fastForward;

    std::string m_camFile;

    ScheduledEventPtr m_event;
    ScheduledEventPtr m_logoutEvent;
    std::deque<std::pair<ticks_t, std::shared_ptr<std::vector<uint8_t>>>> m_input;
    std::deque<std::pair<ticks_t, std::shared_ptr<std::vector<uint8_t>>>> m_output;
    std::function<void(std::shared_ptr<std::vector<uint8_t>>)> m_recvCallback;
    std::function<void(boost::system::error_code)> m_disconnectCallback;
};
