//
//  HexFiendUtil.h
//  mocha (macOS)
//
//  Created by white on 2022/7/15.
//

#import <Foundation/Foundation.h>
#import <HexFiend/HexFiend.h>
#import <HexFiend/HFRepresenterTextView.h>

NS_ASSUME_NONNULL_BEGIN

@interface HexFiendUtil : NSObject

+ (void)doSwizzleOnce;

@end

@interface HFUntouchableLineCountingRepresenter : HFLineCountingRepresenter

@end

NS_ASSUME_NONNULL_END
