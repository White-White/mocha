//
//  HFController+Mocha.h
//  mocha (macOS)
//
//  Created by white on 2022/9/21.
//

#import <HexFiend/HexFiend.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFController (Mocha)

- (void)scrollHexViewBasedOn:(NSRange)selectedRange bytesPerLine:(NSUInteger)bytesPerLine;

@end

NS_ASSUME_NONNULL_END
