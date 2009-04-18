using System;
using System.Windows.Forms;
using System.Globalization;

namespace hokkaido
{
    static class Program
    {
        /// <summary>
        /// アプリケーションの主なエントリ ポイントです。
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            if (args.Length > 0)
            {
                // 2 文字のコマンド ライン引数を取得します。
                string arg = args[0].ToLower(CultureInfo.InvariantCulture).Trim().Substring(0, 2);
                switch (arg)
                {
                    case "/c":
                        // オプション ダイアログを表示します。
                        ShowOptions();
                        break;
                    case "/p":
                        // プレビューに対して何もしません。
                        break;
                    case "/s":
                        // スクリーン セーバーのフォームを表示します。
                        ShowScreenSaver();
                        break;
                    default:
                        MessageBox.Show("コマンド ライン引数が無効です :" + arg, "コマンド ライン引数が無効です。", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        break;
                }
            }
            else
            {
                // 渡される引数がない場合、スクリーン セーバーを表示します。
                //ShowScreenSaver();
                ShowOptions();
            }
        }

        static void ShowOptions()
        {
            OptionsForm optionsForm = new OptionsForm();
            Application.Run(optionsForm);
        }

        static void ShowScreenSaver()
        {
            ScreenSaverForm screenSaver = new ScreenSaverForm();
            Application.Run(screenSaver);
        }
    }
}