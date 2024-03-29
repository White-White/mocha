//
//  CapstoneHelper.h
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CapStoneArchType) {
    CapStoneArchTypeI386,
    CapStoneArchTypeX8664,
    CapStoneArchTypeThumb,
    CapStoneArchTypeARM,
    CapStoneArchTypeARM64
};

@interface CapStoneInstruction : NSObject

@property (nonatomic, strong) NSString *mnemonic;
@property (nonatomic, strong) NSString *operand;
@property (nonatomic, assign) uint64_t startAddr;
@property (nonatomic, assign) uint16_t size;

@end

@interface CapStoneInstructionBank : NSObject

@property (nonatomic, strong) NSError * _Nullable error;

- (NSInteger)numberOfInstructions;
- (CapStoneInstruction *)instructionAtIndex:(NSInteger)index;

@end

@interface CapStoneHelper : NSObject

+ (CapStoneInstructionBank *)instructionsFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock;

@end

NS_ASSUME_NONNULL_END
