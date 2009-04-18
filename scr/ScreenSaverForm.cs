using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Flash.External;

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

            String swfPath = "C:\\Documents and Settings\\saita\\My Documents\\program\\as\\hokkaido\\HokkaidoBox2d.swf";//Directory.GetCurrentDirectory() + Path.DirectorySeparatorChar + "hokkaido.swf";

            ExternalInterfaceProxy proxy = new ExternalInterfaceProxy(flash);
            proxy.ExternalInterfaceCall += new ExternalInterfaceCallEventHandler(ExternalInterfaceCall);

            flash.LoadMovie(0, swfPath);
        }

        /// <summary>
        /// メイン フォームを全画面スクリーン セーバーとして設定します。
        /// </summary>
        private void SetupScreenSaver()
        {
            // ダブル バッファを使用して、表示パフォーマンスを改善します。
            this.SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint, true);
            // マウスをキャプチャします。
            this.Capture = true;

            // アプリケーションを全画面表示モードに設定して、マウスを表示しません。
            Cursor.Hide();
            Bounds = Screen.PrimaryScreen.Bounds;
            WindowState = FormWindowState.Maximized;
            ShowInTaskbar = false;
            DoubleBuffered = true;
            BackgroundImageLayout = ImageLayout.Stretch;
        }

        private object ExternalInterfaceCall(object sender, ExternalInterfaceCallEventArgs e)
        {
            switch (e.FunctionCall.FunctionName)
            {
                case "window._hokkaido_auto_repeat":
                    return true;

                case "window._hokkaido_random":
                    return Properties.Settings.Default.Order == "random";
            }
            return null;
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
