using Hardcodet.Wpf.TaskbarNotification;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Timers;
using System.Windows;
using System.Windows.Controls.Primitives;
using System.Windows.Threading;

namespace PoorMansIDS
{
    public partial class App : Application
    {
        private static TaskbarIcon notifyIcon;
        public static System.Timers.Timer aTimer;

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            //create the notifyicon (it's a resource declared in NotifyIconResources.xaml
            notifyIcon = (TaskbarIcon)FindResource("MyNotifyIcon");
            // Set Timer Interval to 15 minutes and 1 second
            SetTimer((15 * 60 + 0) ); // 
        }

        public static void SetTimer(int iVal)
        {
            if (aTimer != null) // for resetting: delete old one
            {
                if (aTimer.Enabled) { aTimer.Dispose(); }
            }
            aTimer = new System.Timers.Timer(iVal * 1000); // 5 minutes
            
            aTimer.Elapsed += OnTimedEvent;
            aTimer.AutoReset = true;
            aTimer.Enabled = true;
        }

        private static void OnTimedEvent(Object source, ElapsedEventArgs e)
        {
            Debug.WriteLine("The Elapsed event was raised at {0:HH:mm:ss.fff}", e.SignalTime);

            //var scriptWorkingDirectory = @"C:\PowerShellScripts\";
            var scriptWorkingDirectory = System.AppDomain.CurrentDomain.BaseDirectory;
            // fixed script name
            var scriptPath = scriptWorkingDirectory + "PoorMansIDS.ps1";

            Process build = new Process();
            build.StartInfo.FileName = "powershell.exe";
            build.StartInfo.WorkingDirectory = scriptWorkingDirectory;
            //build.StartInfo.Arguments = @"-executionpolicy unrestricted c:\PowerShellScripts\PoorIDS.ps1";
            //build.StartInfo.Arguments = @"c:\PowerShellScripts\PoorIDS.ps1";
            //build.StartInfo.Arguments = scriptPath;
            build.StartInfo.Arguments = "-File \"" + scriptPath + "\"";
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

            build.WaitForExit();


            if (build.ExitCode == 1)  // means we got CHANGES in registry keys, services, etc -> popup balloon
            {
                App.Current.Dispatcher.BeginInvoke(DispatcherPriority.Send, (ThreadStart)delegate ()
                {
                    
                    FancyBalloon balloon = new FancyBalloon();
                    balloon.BalloonText = "Time: " + e.SignalTime + "\n"
                        + System.AppDomain.CurrentDomain.BaseDirectory + "\n"
                        + output + "ExitCode: " + build.ExitCode;

                    //show balloon and close it after 4 seconds
                    notifyIcon.ShowCustomBalloon(balloon, PopupAnimation.None, null);
                });
            }
        }

        protected override void OnExit(ExitEventArgs e)
        {
            notifyIcon.Dispose(); //the icon would clean up automatically, but this is cleaner
            base.OnExit(e);
        }
    }
}
