//
//  Faking.swift
//  DonQuixote
//
//  Created by white on 2023/6/26.
//

import Foundation
import ProjectSpec
import XcodeGenKit
import PathKit

class Faking {
    
    let ipa: IPA
    let fakingProjDirectory: URL
    
    init(ipa: IPA) throws {
        self.ipa = ipa
        let fakingProjDirectory = ipa.unzipRootURL.appendingPathComponent("faking", conformingTo: .folder)
        try FileManager.default.createDirectory(at: fakingProjDirectory, withIntermediateDirectories: true)
        self.fakingProjDirectory = fakingProjDirectory
    }
    
    func copySourceFiles() throws {
        
    }
    
    func generateXcodeProj() throws {
        let project = try Project.create(basedOn: self.ipa, baseDirectory: self.fakingProjDirectory)
        let generator = ProjectGenerator(project: project)
        let xcodeProject = try generator.generateXcodeProject(userName: "abc")
        try xcodeProject.write(path: Path(self.fakingProjDirectory.path()))
    }
    
    static func run(for ipa: IPA) throws {
        let faking = try Faking(ipa: ipa)
        try faking.copySourceFiles()
        try faking.generateXcodeProj()
        
        print(1)
    }
    
}
