//
//  ProjectExtension.swift
//  DonQuixote
//
//  Created by white on 2023/6/26.
//

import Foundation
import ProjectSpec
import PathKit

extension ProjectSpec.Project {
    
    static func create(basedOn ipa: IPA, baseDirectory: URL) throws -> ProjectSpec.Project {
        
        var json: [String: Any] = [:]
        json["name"] = ipa.infoPlist.bundleName
        json["options"] = ["settingPresets": "none"]
        json["settings"] = ["ALWAYS_SEARCH_USER_PATHS": "NO",
                            "CLANG_ANALYZER_NONNULL": "YES",
                            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
                            "CLANG_CXX_LANGUAGE_STANDARD": "gnu++14",
                            "CLANG_CXX_LIBRARY": "libc++",
                            "CLANG_ENABLE_MODULES": "YES",
                            "CLANG_ENABLE_OBJC_ARC": "YES",
                            "CLANG_ENABLE_OBJC_WEAK": "YES",
                            "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
                            "CLANG_WARN_BOOL_CONVERSION": "YES",
                            "CLANG_WARN_COMMA": "YES",
                            "CLANG_WARN_CONSTANT_CONVERSION": "YES",
                            "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
                            "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
                            "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
                            "CLANG_WARN_EMPTY_BODY": "YES",
                            "CLANG_WARN_ENUM_CONVERSION": "YES",
                            "CLANG_WARN_INFINITE_RECURSION": "YES",
                            "CLANG_WARN_INT_CONVERSION": "YES",
                            "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
                            "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
                            "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
                            "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
                            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
                            "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
                            "CLANG_WARN_STRICT_PROTOTYPES": "YES",
                            "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
                            "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
                            "CLANG_WARN_UNREACHABLE_CODE": "YES",
                            "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
                            "COPY_PHASE_STRIP": "NO",
                            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
                            "GCC_C_LANGUAGE_STANDARD": "gnu11",
                            "GCC_NO_COMMON_BLOCKS": "YES",
                            "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
                            "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
                            "GCC_WARN_UNDECLARED_SELECTOR": "YES",
                            "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
                            "GCC_WARN_UNUSED_FUNCTION": "YES",
                            "GCC_WARN_UNUSED_VARIABLE": "YES",
                            "MTL_FAST_MATH": "YES",
                            "PRODUCT_NAME": "$(TARGET_NAME)",
                            "SWIFT_VERSION": "5.0"]
        json["fileGroups"] = ["Sources"]
        
        let appTarget: [String: Any] = ["platform": ipa.infoPlist.platform.name,
                                        "type": "application",
                                        "deploymentTarget": ipa.infoPlist.platform.deploymentTarget,
                                        "configFiles": ["Debug": "app.xcconfig", "Release": "app.xcconfig"],
                                        "dependencies": [["target": "Faking"]],
                                        "sources": [["path": "Sources/Main.m"], ["path": "Payload", "type": "folder", "buildPhase": "none"], ["path": "Assets.xcassets"]],
                                        "settings": ["PRODUCT_NAME": "$(TARGET_NAME)", "CODE_SIGN_IDENTITY": "iPhone Developer", "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"],
                                        "info": ["path": "Sources/Info.plist", "properties": ["CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                                                                                              "CFBundleName": "$(PRODUCT_NAME)",
                                                                                              "CFDisplayName": "$(INFOPLIST_KEY_CFBundleDisplayName)",
                                                                                              "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                                                                                              "CFBundleExecutable": "$(EXECUTABLE_NAME)",
                                                                                              "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
                                                                                              "CFBundleInfoDictionaryVersion": "6.0",
                                                                                              "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                                                                                              "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)"]] as [String: Any],
                                        "postBuildScripts": [["script": "bash \"$SRCROOT/scripts/faking.sh\"", "name": "Execute Faking Script"]]]
        
        let fakingTarget: [String: Any] = ["platform": ipa.infoPlist.platform.name,
                                           "type": "framework",
                                           "deploymentTarget": ipa.infoPlist.platform.deploymentTarget,
                                           "configFiles": ["Debug": "app.xcconfig", "Release": "app.xcconfig"],
                                           "sources": [["path": "Sources/Faking.m"], ["path": "Sources/Utils/choose/choose.mm", "compilerFlags": ["-fno-objc-arc"]] as [String : Any], ["path": "Sources/Utils"]],
                                           "settings": ["PRODUCT_NAME": "$(TARGET_NAME)",
                                                        "PRODUCT_BUNDLE_IDENTIFIER": "$(PRODUCT_BUNDLE_IDENTIFIER).faking",
                                                        "CURRENT_PROJECT_VERSION": "1",
                                                        "DEFINES_MODULE": "'YES'",
                                                        "CODE_SIGN_IDENTITY": "",
                                                        "DYLIB_COMPATIBILITY_VERSION": "1",
                                                        "DYLIB_CURRENT_VERSION": "1",
                                                        "VERSIONING_SYSTEM": "apple-generic",
                                                        "INSTALL_PATH": "$(LOCAL_LIBRARY_DIR)/Frameworks",
                                                        "DYLIB_INSTALL_NAME_BASE": "@rpath",
                                                        "SKIP_INSTALL": "YES"],
                                           "info": ["path": "Faking/Info.plist", "properties": ["CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                                                                                                "CFBundleName": "$(PRODUCT_NAME)",
                                                                                                "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                                                                                                "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
                                                                                                "CFBundleInfoDictionaryVersion": "6.0",
                                                                                                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                                                                                                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)"]] as [String: Any]]
        
        json["targets"] = [[ipa.infoPlist.bundleName: appTarget], ["Faking": fakingTarget]]
        
        return try ProjectSpec.Project(basePath: PathKit.Path(baseDirectory.path()), jsonDictionary: json)
    }
    
}
