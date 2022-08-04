//
//  MachoViewStateManager.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/22.
//

import Foundation

class ObserableValueWrapper<T>: ObservableObject {
    @Published var value: T; init(value: T) { self.value = value }
}

class MachoViewState {
    
    let macho: Macho
    
    let componentListViewModel: ComponentListViewModel
    
    var selectedMachoComponentIndex: Int {
        willSet {
            self.componentListViewModel.cellModels[selectedMachoComponentIndex].isSelected = false
        }
        didSet {
            self.componentListViewModel.cellModels[selectedMachoComponentIndex].isSelected = true

            let machoComponent = macho.allComponents[selectedMachoComponentIndex]
            self.selectedMachoComponentWrapper.value = machoComponent
            
            self.currentMachoComponentRangeWrapper.value = UInt64(machoComponent.offsetInMacho)..<UInt64(machoComponent.offsetInMacho + machoComponent.dataSize)
        }
    }
    
    let selectedMachoComponentWrapper: ObserableValueWrapper<MachoComponent>
    let selectedDataRangeWrapper: ObserableValueWrapper<Range<UInt64>?>
    let currentMachoComponentRangeWrapper: ObserableValueWrapper<Range<UInt64>>
    
    init(macho: Macho) {
        self.macho = macho
        
        let defaultSelectedMachoComponentIndex = 0
        self.selectedMachoComponentIndex = defaultSelectedMachoComponentIndex
        self.componentListViewModel = ComponentListViewModel(with: macho, selectedIndex: defaultSelectedMachoComponentIndex)
        
        let machoComponent = macho.allComponents[defaultSelectedMachoComponentIndex]
        self.selectedMachoComponentWrapper = ObserableValueWrapper(value: machoComponent)
        
        self.selectedDataRangeWrapper = ObserableValueWrapper(value: nil)
        let dataRangeAllTranslation = UInt64(machoComponent.offsetInMacho)..<UInt64(machoComponent.offsetInMacho + machoComponent.dataSize)
        self.currentMachoComponentRangeWrapper = ObserableValueWrapper(value: dataRangeAllTranslation)
    }

}
