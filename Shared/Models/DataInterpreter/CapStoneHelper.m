//
//  CapstoneHelper.m
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

#import "CapStoneHelper.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // ignoring all warnings from capstore
#import "capstone/capstone.h"
#pragma clang diagnostic pop

@implementation CapStoneInstruction

@end

@implementation CapStoneHelper

+ (NSArray<CapStoneInstruction *> *)instructionsFrom:(NSData *)data
                                 startVirtualAddress:(uint64_t)startVirtualAddress
                                                arch:(CapStoneArchType)arch {
    
    csh cs_handle;
    cs_insn *cs_insn = NULL;
    size_t disasm_count = 0;
    cs_err cserr;
    /* open capstone */
    cs_arch target_arch;
    cs_mode target_mode;
    
    switch (arch) {
        case CapStoneArchTypeI386:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_32;
            break;
        case CapStoneArchTypeX8664:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_64;
            break;
        case CapStoneArchTypeThumb:
            target_arch = CS_ARCH_ARM;
            target_mode = CS_MODE_ARM;
            break;
        case CapStoneArchTypeARM:
            target_arch = CS_ARCH_ARM;
            target_mode = CS_MODE_ARM;
            break;
        case CapStoneArchTypeARM64:
            target_arch = CS_ARCH_ARM64;
            target_mode = CS_MODE_ARM;
            break;
    }
    
    if ( (cserr = cs_open(target_arch, target_mode, &cs_handle)) != CS_ERR_OK ) {
        @throw @"Fatal error."; // unexpected. failed to init capstore
    }
    
    switch (arch) {
        case CapStoneArchTypeThumb:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_THUMB);
            break;
        case CapStoneArchTypeARM:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_ARM);
            break;
        default:
            break;
    }
    
    /* enable detail - we need fields available in detail field */
    cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    cs_option(cs_handle, CS_OPT_SKIPDATA, CS_OPT_ON);
    
    disasm_count = cs_disasm(cs_handle, (uint8_t *)[data bytes], (uint32_t)[data length], startVirtualAddress, 0, &cs_insn);
    NSMutableArray <CapStoneInstruction *>* instructions = [NSMutableArray arrayWithCapacity:disasm_count];
    
    for (size_t i = 0; i < disasm_count; i++) {
        NSString *mnemonic = [NSString stringWithCString:cs_insn[i].mnemonic encoding:NSUTF8StringEncoding];
        NSString *operand = [NSString stringWithCString:cs_insn[i].op_str encoding:NSUTF8StringEncoding];
        CapStoneInstruction *ins = [[CapStoneInstruction alloc] init];
        ins.mnemonic = mnemonic;
        ins.operand = operand;
        [instructions addObject:ins];
    }
    
    return instructions;
    
}

@end
