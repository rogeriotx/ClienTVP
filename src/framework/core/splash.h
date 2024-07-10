#ifndef SPLASH_H
#define SPLASH_H

#include <winsock2.h>
#include <windows.h>
#include <mutex>

class SplashScreen
{
public:
	SplashScreen();

	void defineClass();
	bool registerClass();
	void createWindow();
	bool loadBitmap();
	void show();
	void destroy();

	void setProgress(int value);
	void setText(const char* msg);

private:
	static LRESULT CALLBACK WndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
	WNDCLASSEX wndClass;
	HINSTANCE hInstance;
	HWND hWnd;
};

extern SplashScreen g_splash;

#endif