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
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.radioOrderRandom = new System.Windows.Forms.RadioButton();
            this.radioOrderNormal = new System.Windows.Forms.RadioButton();
            this.label1 = new System.Windows.Forms.Label();
            this.linkWeb = new System.Windows.Forms.LinkLabel();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // buttonOk
            // 
            this.buttonOk.Location = new System.Drawing.Point(61, 145);
            this.buttonOk.Name = "buttonOk";
            this.buttonOk.Size = new System.Drawing.Size(75, 23);
            this.buttonOk.TabIndex = 1;
            this.buttonOk.Text = "OK";
            this.buttonOk.UseVisualStyleBackColor = true;
            this.buttonOk.Click += new System.EventHandler(this.buttonOk_Click);
            // 
            // buttonCancel
            // 
            this.buttonCancel.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.buttonCancel.Location = new System.Drawing.Point(142, 145);
            this.buttonCancel.Name = "buttonCancel";
            this.buttonCancel.Size = new System.Drawing.Size(75, 23);
            this.buttonCancel.TabIndex = 2;
            this.buttonCancel.Text = "キャンセル";
            this.buttonCancel.UseVisualStyleBackColor = true;
            this.buttonCancel.Click += new System.EventHandler(this.buttonCancel_Click);
            // 
            // pictureBox1
            // 
            this.pictureBox1.Image = global::hokkaido.Properties.Resources.hokkaido;
            this.pictureBox1.Location = new System.Drawing.Point(12, 11);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(32, 32);
            this.pictureBox1.TabIndex = 0;
            this.pictureBox1.TabStop = false;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.radioOrderRandom);
            this.groupBox1.Controls.Add(this.radioOrderNormal);
            this.groupBox1.Location = new System.Drawing.Point(61, 64);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(266, 66);
            this.groupBox1.TabIndex = 0;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "表示順";
            // 
            // radioOrderRandom
            // 
            this.radioOrderRandom.AutoSize = true;
            this.radioOrderRandom.Location = new System.Drawing.Point(15, 40);
            this.radioOrderRandom.Name = "radioOrderRandom";
            this.radioOrderRandom.Size = new System.Drawing.Size(75, 16);
            this.radioOrderRandom.TabIndex = 1;
            this.radioOrderRandom.TabStop = true;
            this.radioOrderRandom.Text = "ランダム(&R)";
            this.radioOrderRandom.UseVisualStyleBackColor = true;
            // 
            // radioOrderNormal
            // 
            this.radioOrderNormal.AutoSize = true;
            this.radioOrderNormal.Location = new System.Drawing.Point(15, 18);
            this.radioOrderNormal.Name = "radioOrderNormal";
            this.radioOrderNormal.Size = new System.Drawing.Size(91, 16);
            this.radioOrderNormal.TabIndex = 0;
            this.radioOrderNormal.TabStop = true;
            this.radioOrderNormal.Text = "北から南へ(&N)";
            this.radioOrderNormal.UseVisualStyleBackColor = true;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("MS UI Gothic", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.label1.Location = new System.Drawing.Point(61, 11);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(184, 12);
            this.label1.TabIndex = 6;
            this.label1.Text = "北海道を落とすとどう跳ねるのか？";
            // 
            // linkWeb
            // 
            this.linkWeb.AutoSize = true;
            this.linkWeb.Location = new System.Drawing.Point(63, 31);
            this.linkWeb.Name = "linkWeb";
            this.linkWeb.Size = new System.Drawing.Size(254, 12);
            this.linkWeb.TabIndex = 7;
            this.linkWeb.TabStop = true;
            this.linkWeb.Text = "http://d.hatena.ne.jp/nitoyon/20090415/hokkaido";
            this.linkWeb.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel1_LinkClicked);
            // 
            // OptionsForm
            // 
            this.AcceptButton = this.buttonOk;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.buttonCancel;
            this.ClientSize = new System.Drawing.Size(339, 178);
            this.Controls.Add(this.linkWeb);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.pictureBox1);
            this.Controls.Add(this.buttonCancel);
            this.Controls.Add(this.buttonOk);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "OptionsForm";
            this.Padding = new System.Windows.Forms.Padding(9, 8, 9, 8);
            this.ShowIcon = false;
            this.Text = "スクリーン セーバーの設定";
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button buttonOk;
        private System.Windows.Forms.Button buttonCancel;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.RadioButton radioOrderRandom;
        private System.Windows.Forms.RadioButton radioOrderNormal;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.LinkLabel linkWeb;

    }
}