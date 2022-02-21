### Mocha
Mocha是一款全新的Mach-O文件查看工具。Mocha可以解释Mach-O文件中每一个字节的含义。
Mocha在左边显示出该Mach-O所有的Section，在中间显示选中的Section的16进制数据，在右边显示这些数据的解释说明。一个Section的数据有很多条解释说明，每一条都对应Macho-O文件中某一段数据。选中一条解释，Mach-O就会高亮对应的二进制数据。
Mocha在上方有一个Mini Map，显式当前选中的Section在Mach-O文件中的位置。

#### 高性能
Mocha可以瞬间打开一个超大Macho-O文件，无需等待任何解析过程，因为Macho对所有的数据解释都尽可能地懒加载。对于Symbol Table和String Table这种必须完全提前解析的数据，Macho用多线程将解析过程放在后台。

#### 现代的
Mocha不仅是一个纯Swift项目，同时也是一个纯SwiftUI项目。Mocha的代码尽可能地保证可读性，方便任何对Mach-O感兴趣的人，通过阅读Mocha的代码就能理解其文件格式。

#### 开源的
Mocha是我个人的开源项目，遵循GPL协议。


### Mocha
Mocha is yet another Macho-O file viewer. Mocha explains every bit of your Mach-O files.
Mocha lists all sections of your Mach-O file, shows a hex view for the selected section's raw data, and shows all explanations of the selected section.

#### High-Performance
Mocha can open big Mach-O files instantly, without waiting for any synchronous parsing process. All information is loaded lazily.
For structures likes String Table and Symbol Table that can't be loaded lazily, Mocha uses background threads.

#### Modern
Mocha is not only a pure Swift project, but also a pure SwiftUI project. Code readability is of highest priority, to make sure anyone interested in Mach-O can learn about it's format
with Mocha's source code.

#### Open Sourced
Mocha is my own side project, and is open sourced under GPL.

### Compare to Other Proejcts
#### [MachOView](https://sourceforge.net/projects/machoview/)
MachOView is a great Mach-O file viewer and used to be all iOS devs' 'must have' tool. But it's now deprecated.
There is a nice compilable fork of MachOView: https://github.com/gdbinit/MachOView
Mocha is actually greatly inpired by MachOView and the fork above. 
Specially, Mocha also uses Capstone to parse instructions.

Compare to MachOView, Mocha is faster, newer and less buggy. I'd like Mocha to be the best replacement of MachOView.

#### [LIEF](https://lief-project.github.io/)
LIEF is a matured cross-platform library to parse all those binary formats. (ELF, PE, Mach-O)
But it's written in grandpa language and to complicated to be a starter's tool.

#### Hopper
Hopper is a great tool for reverse engineering for hardly a good tool to view macho files.
They serve for different purposes. Mocha is just a toy comparing with Hopper.

### Great Mach-O Related Resources
Aside from above projects, Mocha project owes a lot to these good resources:
[osx-abi-macho-file-format-reference](https://github.com/aidansteele/osx-abi-macho-file-format-reference)
[Inside a Hello World executable on OS X](https://adrummond.net/posts/macho)
[MachO-Kit](https://github.com/DeVaukz/MachO-Kit)
[Mach-O文件基础](https://www.cnblogs.com/kekec/p/15533060.html)

### Requirement:
Xcode: 13.\*, macOS 13.\*

### Setup:
Clone the project, init its git submodules and build&run with Xcode.

![example](./README_ASSETS/example.jpg)

### Progress:

✅: Done
⌛️: Not explained yet
🔨: Done but need better explanations

|  Macho Component   | Supported  |
|  ----  | ----  |
| Macho Header  | ✅ |

|  Load Command   | Supported  |
|  ----  | ----  |
| LC_SEGMENT | ✅ |        
| LC_SYMTAB | ⌛️ |        
| LC_SYMSEG | ⌛️ |        
| LC_THREAD | ⌛️ |        
| LC_UNIXTHREAD | ⌛️ |        
| LC_LOADFVMLIB | ⌛️ |        
| LC_IDFVMLIB | ⌛️ |        
| LC_IDENT | ⌛️ |        
| LC_FVMFILE | ⌛️ |        
| LC_PREPAGE | ⌛️ |        
| LC_DYSYMTAB | ⌛️ |        
| LC_LOAD_DYLIB | ⌛️ |        
| LC_ID_DYLIB | ⌛️ |        
| LC_LOAD_DYLINKER | ⌛️ |        
| LC_ID_DYLINKER | ⌛️ |        
| LC_PREBOUND_DYLIB | ⌛️ |        
| LC_ROUTINES | ⌛️ |        
| LC_SUB_FRAMEWORK | ⌛️ |        
| LC_SUB_UMBRELLA | ⌛️ |        
| LC_SUB_CLIENT | ⌛️ |        
| LC_SUB_LIBRARY | ⌛️ |        
| LC_TWOLEVEL_HINTS | ⌛️ |        
| LC_PREBIND_CKSUM | ⌛️ |        
| LC_LOAD_WEAK_DYLIB | ✅ |        
| LC_SEGMENT_64 | ✅ |        
| LC_ROUTINES_64 | ⌛️ |        
| LC_UUID | ✅ |        
| LC_RPATH | ✅ |        
| LC_CODE_SIGNATURE | ⌛️ |        
| LC_SEGMENT_SPLIT_INFO | ⌛️ |        
| LC_REEXPORT_DYLIB | ⌛️ |        
| LC_LAZY_LOAD_DYLIB | ⌛️ |        
| LC_ENCRYPTION_INFO | ✅ |        
| LC_DYLD_INFO | ⌛️ |        
| LC_DYLD_INFO_ONLY | ⌛️ |        
| LC_LOAD_UPWARD_DYLIB | ⌛️ |        
| LC_VERSION_MIN_MACOSX | ✅ |        
| LC_VERSION_MIN_IPHONEOS | ✅ |        
| LC_FUNCTION_STARTS | ✅ |        
| LC_DYLD_ENVIRONMENT | ⌛️ |        
| LC_MAIN | ⌛️ |        
| LC_DATA_IN_CODE | ⌛️ |        
| LC_SOURCE_VERSION | ✅ |        
| LC_DYLIB_CODE_SIGN_DRS | ⌛️ |        
| LC_ENCRYPTION_INFO_64 | ✅ |        
| LC_LINKER_OPTION | ✅ |        
| LC_LINKER_OPTIMIZATION_HINT | ⌛️ |        
| LC_VERSION_MIN_TVOS | ✅ |        
| LC_VERSION_MIN_WATCHOS | ✅ |        
| LC_NOTE | ⌛️ |        
| LC_BUILD_VERSION | ✅ |        
| LC_DYLD_EXPORTS_TRIE | ⌛️ |        
| LC_DYLD_CHAINED_FIXUPS | ⌛️ |        
| LC_FILESET_ENTRY | ⌛️ |

| Section Type | Supported |
|  ----  | ----  |
| S_REGULAR | ✅ |
| S_ZEROFILL | ✅ |
| S_CSTRING_LITERALS | ✅ |
| S_4BYTE_LITERALS | ⏳ |
| S_8BYTE_LITERALS | ⏳ |
| S_LITERAL_POINTERS | ✅ |
| S_NON_LAZY_SYMBOL_POINTERS | ✅ |
| S_LAZY_SYMBOL_POINTERS | ✅ |
| S_SYMBOL_STUBS | ✅ |
| S_MOD_INIT_FUNC_POINTERS | ⏳ |
| S_MOD_TERM_FUNC_POINTERS | ⏳ |
| S_COALESCED | ⏳ |
| S_GB_ZEROFILL | ✅ |
| S_INTERPOSING | ⏳ |
| S_16BYTE_LITERALS | ⏳ |
| S_DTRACE_DOF | ⏳ |
| S_LAZY_DYLIB_SYMBOL_POINTERS | ⏳ |
| S_THREAD_LOCAL_REGULAR | ⏳ |
| S_THREAD_LOCAL_ZEROFILL | ✅ |
| S_THREAD_LOCAL_VARIABLES | ⏳ |
| S_THREAD_LOCAL_VARIABLE_POINTERS | ⏳ |
| S_THREAD_LOCAL_INIT_FUNCTION_POINTERS | ⏳ |
| S_INIT_FUNC_OFFSETS  | ⏳ |

| Swift Section | Supported |
|  ----  | ----  |
| \_\_TEXT,\_\_swift5_reflstr  | ✅ |

<!--| Objective-C Section | Supported |-->
<!--|  ----  | ----  |-->
<!--| \_\_TEXT,\_\_ustring  | ✅ |-->

| Other Section | Supported |
|  ----  | ----  |
| \_\_TEXT,\_\_ustring  | ✅ |
| \_\_TEXT,\_\_text  | ✅ |
| \_\_TEXT,\_\_stubs  | ✅ |
| \_\_TEXT,\_\_stub_helper  | ✅ |


| LinkedIT Type   | Supported  |
|  ----  | ----  |
| Rebase Info  | ✅ |
| Binding Info  | ✅ |
| Weak Binding Info  | ✅ |
| Lazy Binding Info  | ✅ |
| Export Info  | ✅ |
| String Table  | ✅ |
| Symbol Table  | ✅ 🔨 |
| Indirect Symbol Table  | ✅ |
| Code Signature  | ✅ |
