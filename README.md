### Mocha
Mocha是一个可视化的Mach-O文件查看工具，并通过解释Mach-O文件中每一个字节的含义，帮助使用者理解Mach-O。

#### 简介的UI
Mocha的UI是简单直接的。它在左边显示出该Mach-O所有的Section，在中间显示选中的Section的16进制数据，在右边显示这些数据的解释说明。一个Section的数据有很多条解释说明。
每一条解释都对应Macho-O文件中某一段数据。选中一条解释，Mach-O就会高亮对应的二进制数据。
Mocha在上方有一个Mini Map，显式当前选中的Section在Mach-O文件中的位置。

#### 高性能
Mocha可以瞬间打开一个超大Macho-O文件，无需等待任何解析过程，因为Macho对所有的数据解释都尽可能地懒加载。
对于Symbol Table和String Table这种必须完全提前解析的数据，Macho用多线程将解析过程放在后台。

#### 现代的
Mocha不仅是一个纯Swift项目，同时也是一个纯SwiftUI项目。Mocha的代码尽可能地保证可读性，方便任何对Mach-O感兴趣的人，通过阅读Mocha的代码就能理解其文件格式。

#### 开源的
Mocha是我个人的开源项目，遵循GPL协议。


### Mocha
Mocha is yet another visual Macho-O file viewer, which helps user to learn about Mach-O by explaining every bit of the Mach-O file.

#### Clean Interface
Mocha's UI is simple and intuitive. It lists all sections of your Mach-O file at the left, shows a hex view for the selected section's raw data in the middle, and shows all explanations of the selected section at the right.
Every explanation item has it's coresponding data range in the Mach-O file. Upon selected, Mocha highlights the data of the range.
There is also a Mini Map at the top of Mocha, showing the in Mach-O file position of the selected section.

#### High-Performance
Mocha can open big Mach-O files instantly, without waiting for any synchronous parsing process. All information is loaded lazily.
For structures likes String Table and Symbol Table that can't be loaded lazily, Mocha uses background threads.

#### Modern
Mocha is not only a pure Swift project, but also a pure SwiftUI project. Code readability is of highest priority, to make sure anyone interested in Mach-O can learn about it's format with Mocha's source code.

#### Open Sourced
Mocha is my own side project, and is open sourced under GPL.

### Compare to Other Proejcts
#### [MachOView](https://sourceforge.net/projects/machoview/)
MachOView is a great Mach-O file viewer and used to be all iOS devs' 'must have' tool. But it's now deprecated.
There is a nice compilable fork for MachOView at https://github.com/gdbinit/MachOView , but it's still outdated. 
Mocha is greatly inpired by MachOView and the fork above. Specifically, Mocha also uses Capstone to parse instructions.
Compare to MachOView, Mocha is faster, newer and less buggy. I'd like Mocha to be the best replacement of MachOView.

#### [LIEF](https://lief-project.github.io/)
LIEF is a matured cross-platform library to parse all those binary formats. (ELF, PE, Mach-O)
But it's written in grandpa language and to complicated to be a starter's tool.

#### [Hopper](https://www.hopperapp.com/)
Hopper is a great tool for reverse engineering but hardly a good tool to view Mach-O files.
Hopper provides detailed analysis on \_\_text (source code) section that Mocha lacks.  
They serve for different purposes. Mocha is merely a toy comparing to Hopper.

#### [jtool](http://www.newosxbook.com/tools/jtool.html)
jtool is a work from [Jonathan Levin](http://www.newosxbook.com/index.php?page=me), who is also the author of \*OS Internals books.
jtool is command line tool focusing on usage, without UI. I learned a lot from Johnthan's posts.
By the way, \*OS Internals Volume 3 (on Security) was translated to Chinese by [蒸米](https://github.com/zhengmin1989), and can be found on 淘宝 & 京东.

### Great Mach-O Related Resources
Aside from projects above, Mocha owes a lot to these good articles:
[osx-abi-macho-file-format-reference](https://github.com/aidansteele/osx-abi-macho-file-format-reference)
[Inside a Hello World executable on OS X](https://adrummond.net/posts/macho)
[MachO-Kit](https://github.com/DeVaukz/MachO-Kit)
[Mach-O文件基础](https://www.cnblogs.com/kekec/p/15533060.html)

### Requirement:
Xcode: 13.\*, macOS 13.\*

### Compile:
Clone the project, init its git submodules, and build & run with Xcode.

![example](./README_ASSETS/example.jpg)

### Progress:

✅: Supported
⌛️: To be supported
🔨: Supported but need polish
🙅: Not supported and will not be supported. Mostly because it's legacy or not important

|  Macho Component   | Supported  |
|  ----  | ----  |
| Macho Header  | ✅ |
| (Load Command) LC_SEGMENT | ✅ |        
| (Load Command) LC_SYMTAB | ✅ |        
| (Load Command) LC_SYMSEG | 🙅 |        
| (Load Command) LC_THREAD | 🙅 |        
| (Load Command) LC_UNIXTHREAD | 🙅 |        
| (Load Command) LC_LOADFVMLIB | 🙅 |        
| (Load Command) LC_IDFVMLIB | ✅ |        
| (Load Command) LC_IDENT | 🙅 |        
| (Load Command) LC_FVMFILE | 🙅 |        
| (Load Command) LC_PREPAGE | 🙅 |        
| (Load Command) LC_DYSYMTAB | ✅ |        
| (Load Command) LC_LOAD_DYLIB | ✅ |        
| (Load Command) LC_ID_DYLIB | ✅ |        
| (Load Command) LC_LOAD_DYLINKER | ✅ |        
| (Load Command) LC_ID_DYLINKER | ✅ |        
| (Load Command) LC_PREBOUND_DYLIB | ✅ |        
| (Load Command) LC_ROUTINES | 🙅 |        
| (Load Command) LC_SUB_FRAMEWORK | 🙅 |        
| (Load Command) LC_SUB_UMBRELLA | 🙅 |        
| (Load Command) LC_SUB_CLIENT | 🙅 |        
| (Load Command) LC_SUB_LIBRARY | 🙅 |        
| (Load Command) LC_TWOLEVEL_HINTS | 🙅 |        
| (Load Command) LC_PREBIND_CKSUM | 🙅 |        
| (Load Command) LC_LOAD_WEAK_DYLIB | ✅ |        
| (Load Command) LC_SEGMENT_64 | ✅ |        
| (Load Command) LC_ROUTINES_64 | 🙅 |        
| (Load Command) LC_UUID | ✅ |        
| (Load Command) LC_RPATH | ✅ |        
| (Load Command) LC_CODE_SIGNATURE | ✅ |        
| (Load Command) LC_SEGMENT_SPLIT_INFO | 🙅 |        
| (Load Command) LC_REEXPORT_DYLIB | ✅ |        
| (Load Command) LC_LAZY_LOAD_DYLIB | ✅ |        
| (Load Command) LC_ENCRYPTION_INFO | ✅ |        
| (Load Command) LC_DYLD_INFO | ✅ |        
| (Load Command) LC_DYLD_INFO_ONLY | ✅ |        
| (Load Command) LC_LOAD_UPWARD_DYLIB | ✅ |        
| (Load Command) LC_VERSION_MIN_MACOSX | ✅ |        
| (Load Command) LC_VERSION_MIN_IPHONEOS | ✅ |        
| (Load Command) LC_FUNCTION_STARTS | ✅ |        
| (Load Command) LC_DYLD_ENVIRONMENT | ✅ |        
| (Load Command) LC_MAIN | ✅ |        
| (Load Command) LC_DATA_IN_CODE | ✅ |        
| (Load Command) LC_SOURCE_VERSION | ✅ |        
| (Load Command) LC_DYLIB_CODE_SIGN_DRS | 🙅 |        
| (Load Command) LC_ENCRYPTION_INFO_64 | ✅ |        
| (Load Command) LC_LINKER_OPTION | ✅ |        
| (Load Command) LC_LINKER_OPTIMIZATION_HINT | 🙅 |        
| (Load Command) LC_VERSION_MIN_TVOS | ✅ |        
| (Load Command) LC_VERSION_MIN_WATCHOS | ✅ |        
| (Load Command) LC_NOTE | 🙅 |        
| (Load Command) LC_BUILD_VERSION | ✅ |        
| (Load Command) LC_DYLD_EXPORTS_TRIE | ✅ |        
| (Load Command) LC_DYLD_CHAINED_FIXUPS | 🙅 |        
| (Load Command) LC_FILESET_ENTRY | 🙅 |
| (Section Type) S_REGULAR | ✅ |
| (Section Type) S_ZEROFILL | ✅ |
| (Section Type) S_CSTRING_LITERALS | ✅ |
| (Section Type) S_4BYTE_LITERALS | ⏳ |
| (Section Type) S_8BYTE_LITERALS | ⏳ |
| (Section Type) S_LITERAL_POINTERS | ✅ |
| (Section Type) S_NON_LAZY_SYMBOL_POINTERS | ✅ |
| (Section Type) S_LAZY_SYMBOL_POINTERS | ✅ |
| (Section Type) S_SYMBOL_STUBS | ✅ |
| (Section Type) S_MOD_INIT_FUNC_POINTERS | ⏳ |
| (Section Type) S_MOD_TERM_FUNC_POINTERS | ⏳ |
| (Section Type) S_COALESCED | ⏳ |
| (Section Type) S_GB_ZEROFILL | ✅ |
| (Section Type) S_INTERPOSING | ⏳ |
| (Section Type) S_16BYTE_LITERALS | ⏳ |
| (Section Type) S_DTRACE_DOF | ⏳ |
| (Section Type) S_LAZY_DYLIB_SYMBOL_POINTERS | ✅ |
| (Section Type) S_THREAD_LOCAL_REGULAR | ⏳ |
| (Section Type) S_THREAD_LOCAL_ZEROFILL | ✅ |
| (Section Type) S_THREAD_LOCAL_VARIABLES | ⏳ |
| (Section Type) S_THREAD_LOCAL_VARIABLE_POINTERS | ⏳ |
| (Section Type) S_THREAD_LOCAL_INIT_FUNCTION_POINTERS | ⏳ |
| (Section Type) S_INIT_FUNC_OFFSETS  | ⏳ |
| (Section Name) \_\_TEXT,\_\_swift5_reflstr  | ✅ |
| (Section Name) \_\_TEXT,\_\_ustring  | ✅ |
| (Section Name) \_\_TEXT,\_\_text  | ✅ |
| (Section Name) \_\_TEXT,\_\_stubs  | ✅ |
| (Section Name) \_\_TEXT,\_\_stub_helper  | ✅ |
| (LinkedIt Section) Rebase Info  | ✅ |
| (LinkedIt Section) Binding Info  | ✅ |
| (LinkedIt Section) Weak Binding Info  | ✅ |
| (LinkedIt Section) Lazy Binding Info  | ✅ |
| (LinkedIt Section) Export Info  | ✅ |
| (LinkedIt Section) String Table  | ✅ |
| (LinkedIt Section) Symbol Table  | ✅ 🔨 |
| (LinkedIt Section) Indirect Symbol Table  | ✅ |
| Code Signature  | ⏳ |
