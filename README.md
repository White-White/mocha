#### Mocha is yet another mach-o file viewer.

Requirement:
Xcode: 13.\*, macOS 13.\*

It's written in SwiftUI, so it requires the latest version of Xcode and macOS.

It'll be an alternative of MachOViewer, but newer, better, simpler, and most importantly, compilable.

![example](./README_ASSETS/example.jpg)

Feature:
- Flat layout of all macho sections
- A hex view showing the raw bytes of the selected section
- A readable explanation of the selection
- A mini map showing the position of the selected section in the mach-o file
- Upon selecting an explanation, the coresponding bytes will be highlighted