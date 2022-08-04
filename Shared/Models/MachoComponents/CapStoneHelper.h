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

@interface CapStoneInstruction: NSObject

@property (nonatomic, strong) NSString *mnemonic;
@property (nonatomic, strong) NSString *operand;
@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger length;

@end

@interface CapStoneDisasmResult : NSObject

@property (nonatomic, strong) NSArray<CapStoneInstruction *> * _Nullable instructions;
@property (nonatomic, strong) NSError * _Nullable error;

@end

@interface CapStoneHelper : NSObject

+ (CapStoneDisasmResult *)instructionsFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock;

@end

NS_ASSUME_NONNULL_END
