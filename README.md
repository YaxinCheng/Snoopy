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
Setting the screensaver may show alerts like 

> Screensaver can’t be opened because Apple cannot check it for malicious software

You can do this to solve it:

* Open System Settings
* Privacy & Security
* Scroll down to the bottom and click allow Snoopy.saver to open anyway

## DIY (Develop It Yourself)

### Prerequisites:
* Xcode
* Swift 6 or above
* [Optioanl] tvOS Simulator (if you don't already have the video & image resource files)

### Get Resource Files
This project relies on the resource files from the tvOS simulator.
Please copy the files into the existing `Resources` folder at the project root level (`Snoopy/Resources`).

You can follow the [instruction](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7) to fetch resource files from a tvOS simulator.

A simplified version on how to do it is:
* cd into the simulator path. E.g. `cd '/Library/Developer/CoreSimulator/Volumes/tvOS_22K154/Library/Developer/CoreSimulator/Profiles/Runtimes/tvOS 18.2.simruntime'`. 
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
![video](https://github.com/user-attachments/assets/b9c1eb90-1c23-4b39-abe9-eca95338070e)
![screenshot](https://github.com/user-attachments/assets/88ebe8b2-e70b-44a4-89fa-339a833303a7)
![screenshot](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7)

