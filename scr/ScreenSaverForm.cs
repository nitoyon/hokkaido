using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace hokkaido
{
    partial class ScreenSaverForm : Form
    {
        // スクリーン セーバーがアクティブになっているかどうかを把握します。
        private bool isActive = false;

        // マウスの場所を把握します。
        private Point mouseLocation;

        public ScreenSaverForm()
        {
            InitializeComponent();

            SetupScreenSaver();

            String swfPath = Directory.GetCurrentDirectory() + Path.DirectorySeparatorChar + "hokkaido.swf";

            flash.FlashVars = "auto_repeat=1&random=" + (Properties.Settings.Default.Order == "random" ? "1" : "0");
            flash.LoadMovie(0, swfPath);
        }

        /// <summary>
        /// メイン フォームを全画面スクリーン セーバーとして設定します。
        /// </summary>
        private void SetupScreenSaver()
        {
            // マウスをキャプチャします。
            this.Capture = true;

            // アプリケーションを全画面表示モードに設定して、マウスを表示しません。
            Cursor.Hide();
            Bounds = Screen.PrimaryScreen.Bounds;
            WindowState = FormWindowState.Maximized;
            ShowInTaskbar = false;
        }

        private void ScreenSaverForm_MouseMove(object sender, MouseEventArgs e)
        {
            // IsActive および MouseLocation を、このイベントが最初に呼び出されるときにのみ設定します。
            if (!isActive)
            {
                mouseLocation = MousePosition;
                isActive = true;
            }
            else
            {
                // 最初の呼び出し以来マウスが著しく移動した場合、閉じます。
                if ((Math.Abs(MousePosition.X - mouseLocation.X) > 10) ||
                    (Math.Abs(MousePosition.Y - mouseLocation.Y) > 10))
                {
                    Close();
                }
            }
        }

        private void ScreenSaverForm_KeyDown(object sender, KeyEventArgs e)
        {
            Close();
        }

        private void ScreenSaverForm_MouseDown(object sender, MouseEventArgs e)
        {
            Close();
        }

        private void flash_PreviewKeyDown(object sender, PreviewKeyDownEventArgs e)
        {
            Close();
        }
    }
}
