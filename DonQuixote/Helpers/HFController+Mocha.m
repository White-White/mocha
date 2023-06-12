//
//  HFController+Mocha.m
//  mocha (macOS)
//
//  Created by white on 2022/9/21.
//

#import "HFController+Mocha.h"
#import <objc/runtime.h>

@implementation HFController (Mocha)

- (void)scrollHexViewBasedOn:(NSRange)selectedRange bytesPerLine:(NSUInteger)bytesPerLine {
    long double targetLineIndex = selectedRange.location / bytesPerLine;
    HFFPRange visableLineRange = [self displayedLineRange];
    if (targetLineIndex < (visableLineRange.location + 5) || targetLineIndex > (visableLineRange.location + visableLineRange.length - 5)) {
        long double visableRangeMid = visableLineRange.location + visableLineRange.length / 2;
        long double scrollingDistance = targetLineIndex - visableRangeMid;
        [self scrollByLines:scrollingDistance];
    }
}

- (HexFiendViewController *)viewController {
    return objc_getAssociatedObject(self, @selector(viewController));
}

- (void)setController:(HexFiendViewController *)viewController {
    objc_setAssociatedObject(self, @selector(viewController), viewController, OBJC_ASSOCIATION_ASSIGN);
}

@end
