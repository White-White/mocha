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

@interface CapStoneInstructionBank ()

@property (nonatomic, strong) NSMutableData *instructionStringBank;
@property (nonatomic, strong) NSMutableData *instructionOffsetInStringBank;
@property (nonatomic, strong) NSMutableData *instructionOpStrSizes;
@property (nonatomic, strong) NSMutableData *instructionMnemonicSizes;
@property (nonatomic, strong) NSMutableData *instructionBinarySizes;
@property (nonatomic, assign) NSUInteger numberOfInstructions;

@end

@implementation CapStoneInstructionBank

- (instancetype)init {
    self = [super init];
    _instructionStringBank = [NSMutableData data];
    _instructionOffsetInStringBank = [NSMutableData data];
    _instructionOpStrSizes = [NSMutableData data];
    _instructionMnemonicSizes = [NSMutableData data];
    _instructionBinarySizes = [NSMutableData data];
    _numberOfInstructions = 0;
    return self;
}

- (void)appendInstruction:(const cs_insn *)insn codeSize:(size_t)codeSize {
    
    NSUInteger offsetInStringBank = _instructionStringBank.length;
    [_instructionOffsetInStringBank appendBytes:&offsetInStringBank length:sizeof(NSUInteger)];
    
    NSUInteger mnemonicSize = strlen(insn->mnemonic);
    [_instructionMnemonicSizes appendBytes:&mnemonicSize length:sizeof(NSUInteger)];
    [_instructionStringBank appendBytes:insn->mnemonic length:mnemonicSize];
    
    NSUInteger opStrSize = strlen(insn->op_str);
    [_instructionOpStrSizes appendBytes:&opStrSize length:sizeof(NSUInteger)];
    [_instructionStringBank appendBytes:insn->op_str length:opStrSize];
    
    NSUInteger codeSizeUInt = codeSize;
    [_instructionBinarySizes appendBytes:&codeSizeUInt length:sizeof(NSUInteger)];
    
    _numberOfInstructions ++;
}

- (NSUInteger)numberOfInstructions {
    return _numberOfInstructions;
}

- (CapStoneInstruction *)instructionAtIndex:(NSUInteger)index {
    CapStoneInstruction *instruction = [[CapStoneInstruction alloc] init];
    
    NSUInteger offsetInStringBank = [self getOffsetInStringBankForInstructionIndex:index];
    NSUInteger mnemonicSize = [self getMnemonicSizeForInstructionIndex:index];
    NSUInteger operandSize = [self getOperandSizeForInstructionIndex:index];
    
    instruction.mnemonic = [[NSString alloc] initWithBytes:_instructionStringBank.bytes + offsetInStringBank
                                                    length:mnemonicSize
                                                  encoding:NSUTF8StringEncoding];
    
    instruction.operand = [[NSString alloc] initWithBytes:_instructionStringBank.bytes + offsetInStringBank + mnemonicSize
                                                    length:operandSize
                                                  encoding:NSUTF8StringEncoding];
    
    instruction.codeSize = [self getCodeSizeForInstructionIndex:index];
    
    return instruction;
}

- (NSUInteger)getOffsetInStringBankForInstructionIndex:(NSUInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionOffsetInStringBank forIndex:instructionIndex];
}

- (NSUInteger)getMnemonicSizeForInstructionIndex:(NSUInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionMnemonicSizes forIndex:instructionIndex];
}

- (NSUInteger)getOperandSizeForInstructionIndex:(NSUInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionOpStrSizes forIndex:instructionIndex];
}

- (NSUInteger)getCodeSizeForInstructionIndex:(NSUInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionBinarySizes forIndex:instructionIndex];
}

- (NSUInteger)getNSUIntegerValueFromData:(NSData *)data forIndex:(NSUInteger)index {
    const void *bytes = data.bytes;
    const void *startPointer = bytes + sizeof(NSUInteger) * index;
    NSUInteger value = *((NSUInteger *)startPointer);
    return value;
}

@end

@implementation CapStoneHelper

+ (CapStoneInstructionBank *)instructionsFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock {
    
    CapStoneInstructionBank *instructionBank = [[CapStoneInstructionBank alloc] init];
    
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
        instructionBank.error = [NSError errorWithDomain:@"Capstore" code:cserr userInfo:nil];
        return instructionBank;
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
    
    
    struct cs_insn *insn = cs_malloc(cs_handle);
    
    uint64_t startOffset = 0;
    size_t initial_code_size = (size_t)[data length];
    float progress = 0;
    
    uint64_t codeAddress = codeStartAddress; // value will be updated in iteration
    uint8_t *code = (uint8_t *)[data bytes]; // value will be updated in iteration
    size_t code_size = (size_t)[data length]; // value will be updated in iteration
    
    while(cs_disasm_iter(cs_handle, (const uint8_t **)&code, &code_size, &codeAddress, insn)) {
        [instructionBank appendInstruction:insn codeSize:code_size];
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
        instructionBank.error = [NSError errorWithDomain:@"Capstone" code:cserr userInfo:nil];
    }
    cs_close(&cs_handle);
    
    return instructionBank;
    
}

@end
