using System;
using System.Configuration;
using System.Drawing;
using System.Windows.Forms;

namespace hokkaido
{
    partial class OptionsForm : Form
    {
        public OptionsForm()
        {
            InitializeComponent();

            // 現在の設定からテキスト ボックスを読み込みます。
            try
            {
                bool random = (Properties.Settings.Default.Order == "random");
                radioOrderNormal.Checked = !random;
                radioOrderRandom.Checked = random;
            }
            catch
            {
                MessageBox.Show("スクリーン セーバーの設定での読み取り中に問題が発生しました。");
            }
        }

        // 設定を適用する
        private void ApplyChanges()
        {
            Properties.Settings.Default.Order = (radioOrderNormal.Checked ? "normal" : "random");
            Properties.Settings.Default.Save();
        }

        private void buttonOk_Click(object sender, EventArgs e)
        {
            try
            {
                ApplyChanges();
            }
            catch (ConfigurationException)
            {
                MessageBox.Show("設定を保存できませんでした。スクリーン セーバーと同じディレクトリ内に .config ファイルがあることを確認してください。", "設定を保存できませんでした。", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                Close();
            }
        }

        private void buttonCancel_Click(object sender, EventArgs e)
        {
            Close();
        }
    }
}