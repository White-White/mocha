### Mocha is yet another mach-o file viewer.

Requirement:
Xcode: 13.\*, macOS 13.\*

It's written in SwiftUI, so it requires the latest version of Xcode and macOS.

It'll be an alternative of MachOViewer, but newer, better, simpler, and most importantly, compilable.

![example](./README_ASSETS/example.jpg)

#### Features:
- A list showing all load commands, sections and all other parts of the mach-o file
- A hex view showing the raw bytes of the selected section
- A readable explanation of the selected section, if possible
- A mini map showing the position of the selected section
- Upon selection of an explanation, the hex view will auto scroll to the right position and highlight the coresponding bytes

#### Notes:
This project is still in development.