/**
 * @file hokkaido.cpp
 * @brief �X�N���[���Z�[�o���C�������B
 */

#define _WIN32_WINNT 0x501

#include <windows.h>
#include <shlobj.h>
#include <atlbase.h>
CComModule _Module;
#include <atlwin.h>
#include <atlpath.h>
#include <scrnsave.h>
#include "resource.h"

//#import "c:\WINDOWS\system32\macromed\flash\Flash.ocx" rename_namespace("Flash") named_guids
#import "c:\WINDOWS\system32\macromed\flash\Flash10b.ocx" rename_namespace("Flash") named_guids

/**
 * @brief �ݒ��ێ�����N���X�ł��B
 */
class Config
{
public:
	BOOL normal;

	void MkdirRecursive(const CString& dir) const
	{
		CPath path(dir);
		if (!path.IsDirectory())
		{
			path.RemoveFileSpec();
			MkdirRecursive(path);
			CreateDirectory(dir, NULL);
		}
	}

	CString GetIniPath() const
	{
		CString dir;
		SHGetSpecialFolderPath(NULL, dir.GetBuffer(MAX_PATH), CSIDL_APPDATA, FALSE);
		dir.ReleaseBuffer();

		CPath path(dir);
		path.Append(TEXT("nitoyon\\hokkaido"));
		MkdirRecursive(path);
		path.Append(TEXT("hokkaido.ini"));
		return (CString)path;
	}

	void Load()
	{
		CString path = GetIniPath();
		CString order;
		GetPrivateProfileString(TEXT("config"), TEXT("order"), TEXT("normal"), order.GetBuffer(256), 256, path);
		order.ReleaseBuffer();
		normal = (order.CompareNoCase(TEXT("normal")) == 0);
	}

	void Save()
	{
		CString path = GetIniPath();
		WritePrivateProfileString(TEXT("config"), TEXT("order"), normal ? TEXT("normal") : TEXT("random"), path);
	}
};

/**
 * @brief Flash �̕\�����s���E�C���h�E�ł��B
 *
 * http://www.denpa.org/~go/denpa/200304/atlflash.txt ���Q�l�ɂ��Ă��܂��B
 */
class CAxFlashWindow : 
    public CWindowImpl<CAxFlashWindow,CAxWindow>, // ATL ActiveX ��
    public CComPtr<Flash::IShockwaveFlash>      // COM �C���^�[�t�F�[�X
{
public:
    DECLARE_WND_SUPERCLASS("CAxFlashWindow", CAxWindow::GetWndClassName());
    CAxFlashWindow(){};
    virtual ~CAxFlashWindow(){
        // �����Ƃ��Ȃ��Ƒ��d������Ă��܂�
        p = NULL; 
    }

    // ������
    HWND Create(HWND hWndParent,
            RECT& rcPos, LPCTSTR szWindowName = NULL,
            DWORD dwStyle = 0, DWORD dwExStyle = 0,
            UINT nID = 0, LPVOID lpCreateParam = NULL)
    {

        //**********************************************************
        // ATL Active X ������
        AtlAxWinInit();
        //**********************************************************

        // ������
        CWindowImpl<CAxFlashWindow, CAxWindow>::
            Create(hWndParent, rcPos, szWindowName,
                   dwStyle, dwExStyle, nID, lpCreateParam);
        
        if (m_hWnd) {
            //**********************************************************
            // Flash OCX �ǂݏo��
            LPOLESTR clsid = NULL;
            StringFromCLSID(Flash::CLSID_ShockwaveFlash, &clsid);
            CreateControl(clsid);
            CoTaskMemFree(clsid);
            // Flash �C���^�[�t�F�[�X�擾
            Flash::IShockwaveFlash *flash;
            QueryControl(Flash::IID_IShockwaveFlash, (void**)&flash);
            //**********************************************************

            // Flash::IShockwaveFlash CComPtr::p �ɋL�^
            p = flash;
        }

        return m_hWnd;
    }

    // �I�����b�Z�[�W�n���h��
    LRESULT OnDestroy(UINT, WPARAM, LPARAM, BOOL&){
        PostQuitMessage(0);
        return 0;
    }

    // ���b�Z�[�W�n���h���̗�
    BEGIN_MSG_MAP(CAxFlashWindow)
        MESSAGE_HANDLER(WM_DESTROY, OnDestroy)
    END_MSG_MAP()
};


HWND ghWnd;
WNDPROC gOriginalFlashProc;

/**
 * @brief �T�u�N���X���p�̃E�B���h�E�v���V�[�W���ł��B
 *
 * Flash ��\������E�C���h�E���}�E�X�C�x���g��D���Ă��܂����߁A
 * �}�E�X�ړ��ŃX�N���[���Z�[�o���I�����܂���B
 * ������������邽�߂ɁA�T�u�N���X�����s���A�ꕔ�̃��b�Z�[�W��
 * �X�N���[���Z�[�o�̃��C���E�C���h�E�ɓ]�����Ă��܂��B
 */
LRESULT WINAPI FlashSubclassProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	switch (msg)
	{
		case WM_KEYDOWN:
		case WM_LBUTTONDOWN:
		case WM_MBUTTONDOWN:
		case WM_POWERBROADCAST:
		case WM_RBUTTONDOWN:
		case WM_SYSKEYDOWN:
		case WM_MOUSEMOVE:
		case WM_POWER:
		case WM_ACTIVATEAPP:
		case WM_SETCURSOR:
			SendMessage(ghWnd, msg, wParam, lParam);
			return 0;
	}
	return gOriginalFlashProc(hWnd, msg, wParam, lParam);
}

/**
 * @brief �X�N���[���Z�[�o�̃v���V�[�W���ł��B
 *
 * scrnsave.lib �ɂ���ČĂ΂�܂��B
 */
LRESULT WINAPI ScreenSaverProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	static CAxFlashWindow flash;

    switch(msg)
	{
        case WM_CREATE:
		{
			ghWnd = hWnd;

			LPCREATESTRUCT pcs = (LPCREATESTRUCT)lParam;
			RECT rc = {0, 0, pcs->cx, pcs->cy};
			HWND h = flash.Create(hWnd, rc, NULL, WS_VISIBLE | WS_CHILD);

			// �T�u�N���X�����s��
			HWND hwndFlash = GetWindow(h, GW_CHILD);
			if (hwndFlash != NULL)
			{
				gOriginalFlashProc = (WNDPROC)GetWindowLong(hwndFlash, GWL_WNDPROC);
				SetWindowLong(hwndFlash, GWL_WNDPROC, (LONG)FlashSubclassProc);
			}

			// �ݒ�̃��[�h
			Config config;
			config.Load();

			// swf �̃p�X���擾
			CString exePath;
			GetModuleFileName(NULL, exePath.GetBuffer(MAX_PATH), MAX_PATH);
			exePath.ReleaseBuffer();
            CPath swfPath(exePath);
			swfPath.RemoveFileSpec();
			swfPath.Append(TEXT("hokkaido.swf"));

			// Flash �̐ݒ�
			CComBSTR str(CString(TEXT("auto_repeat=1&random=")) + (config.normal ? TEXT("0") : TEXT("1")));
			flash->put_FlashVars(str);
			flash->Movie = CComBSTR(swfPath).m_str;
            break;
		}

		case WM_DESTROY:
			flash.DestroyWindow();
			break;
    }
    return DefScreenSaverProc(hWnd, msg, wParam, lParam);
}

class CLink : public CWindowImpl<CLink>
{
BEGIN_MSG_MAP(CLink)
	MESSAGE_HANDLER(WM_SETCURSOR, OnSetCursor)
END_MSG_MAP()

	LRESULT OnSetCursor(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled)
	{
		SetCursor(LoadCursor(NULL, IDC_HAND));
		bHandled = TRUE;
		return 0;
	}
};

/**
 * @brief �X�N���[���Z�[�o�ݒ�_�C�A���O�̃v���V�[�W���ł��B
 *
 * scrnsave.lib �ɂ���ČĂ΂�܂��B
 */
BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
	static HFONT hFontLink;
	static HFONT hFontTitle;
	static CLink link;

	switch(msg)
	{
		case WM_INITDIALOG:
		{
			Config config;
			config.Load();
			CheckDlgButton(hDlg, config.normal ? IDC_RADIO_NORMAL : IDC_RADIO_RANDOM, BST_CHECKED);

			HFONT hFontLink = (HFONT)SendMessage(hDlg, WM_GETFONT, 0, 0);
			LOGFONT logfont;
			GetObject(hFontLink, sizeof(logfont), &logfont);
			logfont.lfWeight = 700;
			hFontTitle = CreateFontIndirect(&logfont);
			SendMessage(GetDlgItem(hDlg, IDC_TITLE), WM_SETFONT, (WPARAM)hFontTitle, 0);

			logfont.lfWeight = 400;
			logfont.lfUnderline = 1;
			hFontLink = CreateFontIndirect(&logfont);
			SendMessage(GetDlgItem(hDlg, IDC_URL), WM_SETFONT, (WPARAM)hFontLink, 0) ;

			link.SubclassWindow(GetDlgItem(hDlg, IDC_URL));
			return FALSE;
		}

		case WM_CTLCOLORSTATIC:
			if (GetDlgItem(hDlg, IDC_URL) == (HWND)lParam)
			{
				HDC hdc = (HDC)wParam;
				SetTextColor(hdc, RGB(0, 0, 255));
				SetBkColor(hdc, GetSysColor(COLOR_3DFACE)) ;
				return (BOOL)(HBRUSH)GetStockObject(NULL_BRUSH) ;
			}
			return FALSE;

		case WM_COMMAND:
			switch (LOWORD(wParam))
			{
				case IDC_URL:
				{
					if (HIWORD(wParam) == STN_CLICKED)
					{
						CString url;
						GetDlgItemText(hDlg, IDC_URL, url.GetBuffer(256), 256);
						url.ReleaseBuffer();
						ShellExecute(hDlg, TEXT("open"), url, NULL, NULL, SW_SHOWNORMAL);
					}
					break;
				}
				case IDOK:
					Config config;
					config.normal = IsDlgButtonChecked(hDlg, IDC_RADIO_NORMAL);
					config.Save();
					EndDialog(hDlg, TRUE);
					return TRUE;
				case IDCANCEL:
					EndDialog(hDlg, 0);
					return TRUE;
			}
	}
    return FALSE;
}

BOOL WINAPI RegisterDialogClasses(HANDLE hInst)
{
    return TRUE;
}
