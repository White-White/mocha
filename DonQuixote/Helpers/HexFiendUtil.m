//
//  HexFiendUtil.m
//  mocha (macOS)
//
//  Created by white on 2022/7/15.
//

#import "HexFiendUtil.h"
#import <objc/runtime.h>

@implementation HFRepresenterTextView (Mocha)

- (NSColor *)swizzled_inactiveTextSelectionColor {
    return [NSColor selectedTextBackgroundColor];
}

@end

@implementation HexFiendUtil

+ (void)doSwizzleOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            Class c = [HFRepresenterTextView class];
            SEL orig = NSSelectorFromString(@"inactiveTextSelectionColor");
            SEL newSelector = @selector(swizzled_inactiveTextSelectionColor);
            Method origMethod = class_getInstanceMethod(c, orig);
            Method newdMethod = class_getInstanceMethod(c, newSelector);
            if (!origMethod || !newdMethod) {
                return;
            }
            IMP origIMP = method_getImplementation(origMethod);
            IMP newIMP = method_getImplementation(newdMethod);
            if (!origIMP || !newIMP){
                return;
            }
            const char *originalType = method_getTypeEncoding(origMethod);
            const char *swizzledType = method_getTypeEncoding(newdMethod);
            class_replaceMethod(c,newSelector,origIMP,originalType);
            class_replaceMethod(c,orig,newIMP,swizzledType);
        }
    });
}

@end

@implementation HFUntouchableLineCountingRepresenter

- (void)cycleLineNumberFormat { return; }

@end
