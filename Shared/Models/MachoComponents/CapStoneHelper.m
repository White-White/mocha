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

@implementation CapStoneDisasmResult

@end

@implementation CapStoneHelper

+ (CapStoneDisasmResult *)instructionsFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock {
    
    CapStoneDisasmResult *disasmResult = [[CapStoneDisasmResult alloc] init];
    
    csh cs_handle;
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
        disasmResult.error = [NSError errorWithDomain:@"Capstore" code:cserr userInfo:nil];
        return disasmResult;
    }
    
    switch (arch) {
        case CapStoneArchTypeThumb:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_THUMB);
            break;
        case CapStoneArchTypeARM:
            // fallthrough
        case CapStoneArchTypeARM64:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_ARM);
            break;
        default:
            break;
    }
    
    /* enable detail - we need fields available in detail field */
    cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    cs_option(cs_handle, CS_OPT_SKIPDATA, CS_OPT_ON);
    
    
    
    
    NSMutableArray <CapStoneInstruction *>* instructions = [NSMutableArray array];
    struct cs_insn *insn = cs_malloc(cs_handle);
    
    uint64_t startOffset = 0;
    size_t initial_code_size = (size_t)[data length];
    float progress = 0;
    
    uint64_t codeAddress = codeStartAddress; // value will be updated in iteration
    uint8_t *code = (uint8_t *)[data bytes]; // value will be updated in iteration
    size_t code_size = (size_t)[data length]; // value will be updated in iteration
    
    while(cs_disasm_iter(cs_handle, (const uint8_t **)&code, &code_size, &codeAddress, insn)) {
        NSString *mnemonic = [NSString stringWithCString:insn->mnemonic encoding:NSUTF8StringEncoding];
        NSString *operand = [NSString stringWithCString:insn->op_str encoding:NSUTF8StringEncoding];
        CapStoneInstruction *ins = [[CapStoneInstruction alloc] init];
        ins.mnemonic = mnemonic;
        ins.operand = operand;
        ins.startOffset = startOffset;
        ins.length = insn->size;
        [instructions addObject:ins];
        startOffset += insn->size;
        
        float newProgress = (float)startOffset / (float)initial_code_size;
        if (newProgress - progress > 0.02) {
            progressBlock(newProgress);
            progress = newProgress;
        }
    }
    cs_free(insn, 1);
    
    cs_err err_handle = cs_errno(cs_handle);
    if (err_handle != CS_ERR_OK) {
        disasmResult.error = [NSError errorWithDomain:@"Capstone" code:cserr userInfo:nil];
    }
    cs_close(&cs_handle);
    
    disasmResult.instructions = instructions;
    
    return disasmResult;
    
}

@end
