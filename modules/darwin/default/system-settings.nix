{
  pkgs,
  config,
  ...
}: {
  # System settings
  system = {
    activationScripts.postActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    defaults = {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = -1.0;
      };
      loginwindow.GuestEnabled = false;
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        NSUseAnimatedFocusRing = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSDocumentSaveNewDocumentsToCloud = true;
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 25;
        KeyRepeat = 4;
        "com.apple.mouse.tapBehavior" = 1;
      };
      LaunchServices = {
        LSQuarantine = false;
      };
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.ActivityMonitor" = {
          OpenMainWindow = true;
          IconType = 5;
          SortColumn = "CPUUsage";
          SortDirection = 0;
        };
        #        "com.apple.Safari" = {
        #          # Privacy: don’t send search queries to Apple
        #          UniversalSearchEnabled = false;
        #          SuppressSearchSuggestions = true;
        #        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };
        "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
        # Turn on app auto-update
        "com.apple.commerce".AutoUpdate = true;
        "com.googlecode.iterm2".PromptOnQuit = false;
        "com.google.Chrome" = {
          AppleEnableSwipeNavigateWithScrolls = true;
          DisablePrintPreview = true;
          PMPrintingExpandedStateForPrint2 = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
          DisableAllAnimations = true;
          NewWindowTarget = "PfDe";
          NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXEnableExtensionChangeWarning = false;
          ShowStatusBar = true;
          ShowPathbar = true;
          WarnOnEmptyTrash = false;
        };
      };
      trackpad = {
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
        Clicking = false;
      };
      dock = {
        autohide = true;
        launchanim = false;
        static-only = false;
        show-recents = true;
        show-process-indicators = true;
        orientation = "bottom";
        tilesize = 36;
        minimize-to-application = true;
        mineffect = "scale";
        persistent-apps = [
          "/System/Applications/Messages.app"
          "/Applications/Google Chrome.app"
          "/Users/jmeskill/Applications/Chrome Apps.localized/Google Chat.app"
          "${pkgs.wezterm}/Applications/WezTerm.app"
          "/Applications/Obsidian.app"
          "/Applications/Mimestream.app"
          "/Applications/Todoist.app"
          "/Applications/Spotify.app"
          "/Applications/Fantastical.app"
          "/Applications/Slack.app"
          "/Users/jmeskill/Applications/Chrome Apps.localized/Glance.app"
          "/Users/jmeskill/Applications/Chrome Apps.localized/Gemini.app"
          "/Applications/Claude.app"
          "/Applications/1Password.app"
        ];
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
      screencapture = {
        location = "/Users/${config.system.primaryUser}/Screenshots/temp";
        type = "png";
        disable-shadow = true;
      };
    };
    keyboard = {
      enableKeyMapping = true;
    };
  };
}
