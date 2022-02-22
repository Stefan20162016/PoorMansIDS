using System;
using System.Diagnostics;
using System.IO;

using System.Threading;

using System.Windows;

using System.Windows.Documents;

using System.Windows.Threading;

namespace PoorMansIDS
{
    public partial class MainWindow : Window
    {
        private string[] files = { 
            "PoorIDS_Registry.txt",
            "PoorIDS_Services.txt",
            "PoorIDS_Tasks.txt"
        };

        public MainWindow()
        {
            InitializeComponent();
            int seconds = (int)(App.aTimer.Interval / 1000);
            //var seconds = (App.aTimer.Interval / 1000).ToString();
            int minutes = (int)seconds / 60;
            seconds -= minutes * 60;
            textBox.Text = minutes.ToString();
            textBox2.Text = seconds.ToString();
        }

        private void Button_Click_SET_TIMER(object sender, RoutedEventArgs e)
        {
            int minutes, seconds;
            int newtimervalue=0;
            bool ok=false, ok2=false;
            
            // check textbox for minutes
            if (textBox.Text == "") 
            {
                newtimervalue = 0;
                ok = true;
            }
            else
            {
                ok = int.TryParse(textBox.Text, out minutes);
                if (ok)
                {
                    newtimervalue = 60 * minutes;
                }
                else
                {
                    newtimervalue = 0;
                    textBox.Text = "ERROR";
                }
            }

            // check textbox2 for seconds
            if (textBox2.Text == "")
            {
                ok2 = true;
            }
            else
            {
                ok2 = int.TryParse(textBox2.Text, out seconds);
                if (ok2)
                {
                    newtimervalue += seconds;
                }
                else { 
                    textBox2.Text = "ERROR"; 
                }
            }

            if (ok && ok2)
            {
                if (newtimervalue == 0) { // at least 1 sec
                    newtimervalue = 1;
                }
                App.SetTimer(newtimervalue);
                Debug.WriteLine("XXXX: settimer: " + newtimervalue);
            }
            //Debug.WriteLine("XXXX: settimer: " + App.aTimer.Interval);
        }

        private void Button_Click_RESET(object sender, RoutedEventArgs e)
        {
            var result = MessageBox.Show("Would you like to RESET/DELETE the reference files", "POORMANSIDS", MessageBoxButton.YesNo);
            switch (result)
            {
                case MessageBoxResult.Yes:
                    foreach( string file in files)
                    {
                        try
                        {
                            File.Delete(file);
                        } catch (IOException ex)
                        {
                            Debug.WriteLine("delete res: " + ex + ex.Message);
                        }
                    }
                    break;
                case MessageBoxResult.No:
                    Debug.WriteLine("NO");
                    break;
            }
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            LaunchProcess();
        }

        private void LaunchProcess()
        {
            var scriptWorkingDirectory = System.AppDomain.CurrentDomain.BaseDirectory;
            var scriptPath = scriptWorkingDirectory + "PoorMansIDS.ps1";

            Process build = new Process();
            build.StartInfo.FileName = "powershell.exe";
            //build.StartInfo.WorkingDirectory = @"C:\PowerShellScripts";
            //build.StartInfo.Arguments = @"-executionpolicy unrestricted c:\PowerShellScripts\PoorIDS.ps1";
            build.StartInfo.WorkingDirectory = scriptWorkingDirectory;
            build.StartInfo.Arguments = "-File \"" + scriptPath + "\"" ;
            //label1.Content = build.StartInfo.Arguments;
            build.StartInfo.UseShellExecute = false;
            build.StartInfo.RedirectStandardOutput = true;
            build.StartInfo.RedirectStandardError = true;
            build.StartInfo.CreateNoWindow = true;
            //build.ErrorDataReceived += build_ErrorDataReceived;
            //build.OutputDataReceived += build_ErrorDataReceived;
            build.EnableRaisingEvents = true;
            build.Start();
            //build.BeginOutputReadLine();
            //build.BeginErrorReadLine();

            StreamReader reader = build.StandardOutput;
            string output = reader.ReadToEnd();
            
            App.Current.Dispatcher.BeginInvoke(DispatcherPriority.Send, (ThreadStart)delegate ()
            {
                string strMessage = output;
                if (MyRichBox != null && !String.IsNullOrEmpty(strMessage))
                {
                    App.Current.Dispatcher.BeginInvoke(DispatcherPriority.Send, (ThreadStart)delegate ()
                    {
                        Paragraph para = new Paragraph(new Run(strMessage));
                        para.Margin = new Thickness(0);
                        MyRichBox.Document.Blocks.Add(para);
                    });
                }
            });

            build.WaitForExit();
        }

        

        /*void build_ErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            string strMessage = e.Data;
            if (MyRichBox != null && !String.IsNullOrEmpty(strMessage))
            {
                App.Current.Dispatcher.BeginInvoke(DispatcherPriority.Send, (ThreadStart)delegate ()
                {
                    Paragraph para = new Paragraph(new Run(strMessage));
                    para.Margin = new Thickness(0);
                    MyRichBox.Document.Blocks.Add(para);
                });
            }
        }*/
    }
}
