# Snoopy
Snoopy screensaver from tvOS for macOS.

## Features
* SwiftUI built
* Support all animations from tvOS with masks during transitions

## Download
Download from the releases, and double click to install.

## Getting Started

### Prerequisites:
* Swift 6 and above
* Xcode

### Get Resource Files
This project relies on the resource files from the tvOS simulator.
Please copy the files into the `Resources` folder at the project root level.

You can follow the [instruction](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7) to fetch resource files from the Xcode simulator.

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
![screenshot](https://github.com/user-attachments/assets/88ebe8b2-e70b-44a4-89fa-339a833303a7)
![screenshot](https://github.com/user-attachments/assets/d3faed3f-44f3-476b-9822-26835c8d32f7)
