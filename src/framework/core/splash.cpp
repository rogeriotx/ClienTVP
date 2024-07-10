#include "splash.h"
#include "resource.h"
#include <framework/core/eventdispatcher.h>

SplashScreen g_splash;

HBITMAP hBitmap;
const char* text = "Initializing...";
int progress = 0;

void DrawBitmap(HDC hdc)
{
	// Create a memory device context
	HDC hdcMem = CreateCompatibleDC(hdc);

	// Select the bitmap into the device context
	SelectObject(hdcMem, hBitmap);

	// Get the size of the bitmap
	BITMAP bm;
	GetObject(hBitmap, sizeof(bm), &bm);

	// Calculate the position for the bitmap so it is centered in the window
	int x = (GetSystemMetrics(SM_CXSCREEN) - bm.bmWidth) / 2;
	int y = (GetSystemMetrics(SM_CYSCREEN) - bm.bmHeight) / 2;

	// Copy the bitmap from the memory device context to the screen
	BitBlt(hdc, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);

	// Clean up
	DeleteDC(hdcMem);
}

void RenderText(HDC hdc, const char* text)
{
	BITMAP bm;
	GetObject(hBitmap, sizeof(bm), &bm);

	SetTextColor(hdc, RGB(255, 255, 255));
	SetBkMode(hdc, TRANSPARENT);

	TextOut(hdc, 4, bm.bmHeight - 24, text, strlen(text));
}

void RenderProgress(HDC hdc)
{
	BITMAP bm;
	GetObject(hBitmap, sizeof(bm), &bm);

	HPEN hPen = CreatePen(PS_SOLID, 1, RGB(255, 255, 255));
	HBRUSH hBrush = CreateSolidBrush(RGB(255, 255, 255));
	SelectObject(hdc, hPen);
	SelectObject(hdc, hBrush);

	Rectangle(hdc, 2, bm.bmHeight - 7, std::max<int>(2, (bm.bmWidth - 2) * (progress / 100.0)), bm.bmHeight - 2);

	DeleteObject(hPen);
	DeleteObject(hBrush);
}

SplashScreen::SplashScreen()
{
	hInstance = NULL;
	hWnd = NULL;
	wndClass = { 0 };
}

LRESULT CALLBACK SplashScreen::WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	SplashScreen* splash = (SplashScreen*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
	switch (message)
	{
	case WM_CREATE:
	{
		// Save the pointer to the window object
		splash = (SplashScreen*)((LPCREATESTRUCT)lParam)->lpCreateParams;
		SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR)splash);
		break;
	}
	case WM_PAINT:
	{
		// Get the device context for painting
		PAINTSTRUCT ps;
		HDC hdc = BeginPaint(hWnd, &ps);

		DrawBitmap(hdc);
		//RenderProgress(hdc);
		//RenderText(hdc, text);

		ReleaseDC(hWnd, hdc);
		ValidateRect(hWnd, NULL);

		EndPaint(hWnd, &ps);
		break;
	}
	case WM_CLOSE:
	{
		DestroyWindow(hWnd);
		break;
	}
	case WM_DESTROY:
	{
		DeleteObject(hBitmap);
		PostQuitMessage(0);
		break;
	}
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	// Handle any other messages by returning the default window procedure's result
	return DefWindowProc(hWnd, message, wParam, lParam);
}

void SplashScreen::destroy()
{
	PostMessage(hWnd, WM_CLOSE, 0, 0);
}

void SplashScreen::defineClass()
{
	hInstance = GetModuleHandle(NULL);

	wndClass = { 0 };
	wndClass.cbSize = sizeof(WNDCLASSEX);
	wndClass.style = CS_HREDRAW | CS_VREDRAW;
	wndClass.lpfnWndProc = WndProc;
	wndClass.cbClsExtra = 0;
	wndClass.cbWndExtra = 0;
	wndClass.hInstance = hInstance;
	wndClass.hCursor = LoadCursor(NULL, IDC_WAIT);
	wndClass.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wndClass.lpszClassName = "SplashScreen";
}

bool SplashScreen::registerClass()
{
	return RegisterClassEx(&wndClass);
}

void SplashScreen::createWindow()
{
	BITMAP bm;
	GetObject(hBitmap, sizeof(BITMAP), &bm);
	int width = bm.bmWidth;
	int height = bm.bmHeight;

	int xPos = (GetSystemMetrics(SM_CXSCREEN) / 2) - (width / 2);
	int yPos = (GetSystemMetrics(SM_CYSCREEN) / 2) - (height / 2);

	hWnd = CreateWindowEx(
		0,
		"SplashScreen",
		"Splash Screen",
		WS_VISIBLE | WS_POPUP,
		xPos, yPos,
		width, height,
		NULL,
		NULL,
		hInstance,
		this
	);
}

bool SplashScreen::loadBitmap()
{
	hBitmap = LoadBitmap(GetModuleHandle(NULL), MAKEINTRESOURCE(IDB_BITMAP1));
	return hBitmap != NULL;
}

void SplashScreen::show()
{
	progress = 0;
	text = "";
	ShowWindow(hWnd, SW_SHOW);
	UpdateWindow(hWnd);

	MSG msg = {};
	while (GetMessage(&msg, NULL, 0, 0) > 0)
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
}

void SplashScreen::setText(const char* msg)
{
	text = msg;
	InvalidateRect(hWnd, NULL, TRUE);
	UpdateWindow(hWnd);
}

void SplashScreen::setProgress(int value)
{
	if (progress >= 100) return;

	progress = value;
	InvalidateRect(hWnd, NULL, TRUE);
	UpdateWindow(hWnd);
}