namespace hokkaido
{
    partial class OptionsForm : System.Windows.Forms.Form
    {
        /// <summary>
        /// デザイナ変数が必要です。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 使用中のリソースをすべてクリーンアップします。
        /// </summary>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows フォーム デザイナで生成されたコード

        /// <summary>
        /// デザイナ サポートに必要なメソッドです。このメソッドの内容を
        /// コード エディタで変更しないでください。
        /// </summary>
        private void InitializeComponent()
        {
            this.buttonOk = new System.Windows.Forms.Button();
            this.buttonCancel = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.radioOrderNormal = new System.Windows.Forms.RadioButton();
            this.radioOrderRandom = new System.Windows.Forms.RadioButton();
            this.SuspendLayout();
            // 
            // buttonOk
            // 
            this.buttonOk.Location = new System.Drawing.Point(12, 83);
            this.buttonOk.Name = "buttonOk";
            this.buttonOk.Size = new System.Drawing.Size(75, 23);
            this.buttonOk.TabIndex = 3;
            this.buttonOk.Text = "OK";
            this.buttonOk.UseVisualStyleBackColor = true;
            this.buttonOk.Click += new System.EventHandler(this.buttonOk_Click);
            // 
            // buttonCancel
            // 
            this.buttonCancel.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.buttonCancel.Location = new System.Drawing.Point(102, 83);
            this.buttonCancel.Name = "buttonCancel";
            this.buttonCancel.Size = new System.Drawing.Size(75, 23);
            this.buttonCancel.TabIndex = 4;
            this.buttonCancel.Text = "キャンセル";
            this.buttonCancel.UseVisualStyleBackColor = true;
            this.buttonCancel.Click += new System.EventHandler(this.buttonCancel_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(13, 12);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(59, 12);
            this.label1.TabIndex = 0;
            this.label1.Text = "表示順(&O):";
            // 
            // radioOrderNormal
            // 
            this.radioOrderNormal.AutoSize = true;
            this.radioOrderNormal.Location = new System.Drawing.Point(15, 28);
            this.radioOrderNormal.Name = "radioOrderNormal";
            this.radioOrderNormal.Size = new System.Drawing.Size(91, 16);
            this.radioOrderNormal.TabIndex = 1;
            this.radioOrderNormal.TabStop = true;
            this.radioOrderNormal.Text = "北から南へ(&N)";
            this.radioOrderNormal.UseVisualStyleBackColor = true;
            // 
            // radioOrderRandom
            // 
            this.radioOrderRandom.AutoSize = true;
            this.radioOrderRandom.Location = new System.Drawing.Point(15, 50);
            this.radioOrderRandom.Name = "radioOrderRandom";
            this.radioOrderRandom.Size = new System.Drawing.Size(75, 16);
            this.radioOrderRandom.TabIndex = 2;
            this.radioOrderRandom.TabStop = true;
            this.radioOrderRandom.Text = "ランダム(&R)";
            this.radioOrderRandom.UseVisualStyleBackColor = true;
            // 
            // OptionsForm
            // 
            this.AcceptButton = this.buttonOk;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.buttonCancel;
            this.ClientSize = new System.Drawing.Size(339, 117);
            this.Controls.Add(this.radioOrderRandom);
            this.Controls.Add(this.radioOrderNormal);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.buttonCancel);
            this.Controls.Add(this.buttonOk);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "OptionsForm";
            this.Padding = new System.Windows.Forms.Padding(9, 8, 9, 8);
            this.ShowIcon = false;
            this.Text = "スクリーン セーバーの設定";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button buttonOk;
        private System.Windows.Forms.Button buttonCancel;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.RadioButton radioOrderNormal;
        private System.Windows.Forms.RadioButton radioOrderRandom;

    }
}