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

@end

@interface CapStoneHelper : NSObject

+ (NSArray <CapStoneInstruction*>*)instructionsFrom:(NSData *)data
                                startVirtualAddress:(uint64_t)startVirtualAddress
                                               arch:(CapStoneArchType)arch;

@end

NS_ASSUME_NONNULL_END
