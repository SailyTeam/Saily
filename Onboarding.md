# Onboarding Documentation for New Saily Developers

> Prerequisites
- Any Mac running macOS 10.15 Catalina or higher
- Xcode installed with Catalyst support
- Install dpkg, xcpretty, cocoapods, ldid
- Execute ./Attachments/boarding.sh to bootsrtap pods and patches
To get started with developing Saily you must follow a few extra steps rather than just pulling and opening the workspace.

First, download Saily's source code by running the following command in Terminal:

```
git clone --recursive https://github.com/SailyTeam/Saily.git
```

Once you do this, continue by installing cocoapods, dpkg, ldid, and xcpretty by running the following commands separately in Terminal:

```
sudo gem install cocoapods
```

```
brew install dpkg
```

```
brew install ldid
```

```
brew install xcpretty
```

Then, enter Saily's master folder by running the following command in Terminal (given that you haven't moved it out of your Downloads folder):

```
cd /Downloads/Saily-master
```

Now that you're in Saily's master folder, let's install the pods used by Saily by running the following command:

```
pod install
```

From within the master folder, run the following command to enter the Attachments folder:

```
cd Attachments
```

Now that your in the Attachments folder, enter the following command to complete the boarding process:

```
./boarding.sh
```

You've now completed the basic setup process, but you still need to run a few more commands depending on what build you want to install.

> Development & Debug Build

- Change BundleIdentifier for each target, including the WatchKit app
- Check User-Defined settings
- Select Generic iOS Device to build the .deb on for the Debug Build
- Install docker to build a local repo with port 900 for nginx server

> In-House Release

- Open ./Attachments/bake.command
- Check out temps folder for packages


Open the Protein.xcworkspace, ***not*** the .xcproj. Once you open the Workspace, change the Bundle ID for the Protein project to a new identifier. This way you will be able to compile with your own provisioning profile. 

Good luck! If you have any questions, dont hesistate to contact @SailySupport on Twitter.
