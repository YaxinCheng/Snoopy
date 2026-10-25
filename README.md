# Snoopy
Snoopy screensaver from tvOS for macOS.

## Features
* SwiftUI built
* Support all animations from tvOS with masks during transitions

## Download Prebuilt Versions
Download from the releases, and double click to install.

### Requirements
* macOS Sonoma (14.0) and above

### Screensaver can't be opened?
Setting the screensaver and showing only black screen may be related to this issue.
After unlocking from the black screen, it may show an alert like 

> Screensaver can’t be opened because Apple cannot check it for malicious software

Here is what you can do to solve it:

* Open System Settings
* Go to `Privacy & Security`
* Scroll down to the bottom and click allow Snoopy.saver to open anyway
* Go back to `Screen Saver` in System Settings, and select Snoopy as the screensaver
* Click on "Open Anyway" when the alert pops up again
* [Optional] You may need to kill legacyScreensaver process using `pkill legacyScreensaver` in terminal if it still shows a black screen

## DIY (Develop It Yourself)

### Prerequisites:
* Xcode
* Swift 6 or above
* [Optioanl] tvOS Simulator (if you don't already have the video & image resource files)

### Get Resource Files

This project relies on the resource files from the tvOS.
Please copy the resource files into the existing `Resources` folder at the project root level (`Snoopy/Resources`).
All the files (.mov and .heic) should be directly in the `Resources` folder without any subfolder existing.

#### Full Resources
The complete resource files are around 7GB in total.
They are dumped from ipsw files for Apple TV 4K.
I have not went through the process of doing so, but AI helped me find some existing resources dumped by other developers.
You can download the full list from this [Google Drive](https://drive.google.com/file/d/1nMUCcU_zkRBOaJ5IQS8BWdLUJLnOv4Ai/view).

#### Simulator Resources
**Warning: Resources obtained from tvOS simulator is only a subset of the full resources! It works, but you will not see some animations.** 

You can follow the [instruction](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7) to fetch resource files from a tvOS simulator.

A simplified version on how to do it is:
* find simulator path through `xcrun simctl runtime list -v`.
    * it will show a few paths, then you should go to the one ending with `.simruntime`.
* cd into the simulator path. E.g. `cd '/private/var/run/com.apple.security.cryptexd/mnt/com.apple.AppleTVOS.SimulatorRuntime-v24.10.360.0.qFF4AQ/Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS 27.0.simruntime'`. 
    * The path may be different given the version exists in the path
* copy the resource files. `sudo find -E . -regex ".*/[0-9]{3}.*\.(mov|heic)" -exec cp {} ~/Developer/Snoopy/Resources \;`
* remove unused files (not sure why the same masks are represented in both mov and heic, so this project just uses the heic version)
    * `rm Resources/*Mask*.mov`
    * `rm Resources/*Outline*.mov`

### Compile
1. Download the code
2. Open the project with Xcode
3. Build the Snoopy target
    * The output file can be found at `~/Library/Developer/Xcode/DerivedData/Snoopy-<SOME_HASH>/Build/Products/Release/Snoopy.saver`

## Demo
![video](https://github.com/user-attachments/assets/6a434e4f-bb32-4ec3-b975-3d02eced8ba7)
![video](https://github.com/user-attachments/assets/03d5eddf-99f5-4b04-90e4-2cd13e380b5a)
![video](https://github.com/user-attachments/assets/b9c1eb90-1c23-4b39-abe9-eca95338070e)
![screenshot](https://github.com/user-attachments/assets/21cfe793-c578-4307-a887-9bd1f6342b86)
![screenshot](https://github.com/user-attachments/assets/d378722e-697e-487a-bf0e-32da8f0f4da5)
![screenshot](https://github.com/user-attachments/assets/b8ff0830-1102-4ef8-a296-7fcaf5df4828)
![screenshot](https://github.com/user-attachments/assets/88ebe8b2-e70b-44a4-89fa-339a833303a7)
![screenshot](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7)

