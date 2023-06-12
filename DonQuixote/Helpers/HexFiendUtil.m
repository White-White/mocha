//
//  HexFiendUtil.m
//  mocha (macOS)
//
//  Created by white on 2022/7/15.
//

#import <objc/runtime.h>

#import "HexFiendUtil.h"
#import "HFController+Mocha.h"
#import "DonQuixote-Swift.h"

@interface HFRepresenter (DonQuixote)

- (unsigned long long)byteIndexForCharacterIndex:(NSUInteger)characterIndex;

@end

@interface HFRepresenterTextView (DonQuixote)

- (NSUInteger)characterAtPointForSelection:(CGPoint)point;

@end

@implementation HFTextRepresenter (DonQuixote)

- (void)swizzled_beginSelectionWithEvent:(NSEvent *)event forCharacterIndex:(NSUInteger)characterIndex {
    [self __don_qui_setIsSelectionInProgress:NO];
    [self swizzled_beginSelectionWithEvent:event forCharacterIndex:characterIndex];
}

- (void)swizzled_continueSelectionWithEvent:(NSEvent *)event forCharacterIndex:(NSUInteger)characterIndex {
    [self __don_qui_setIsSelectionInProgress:YES];
    [self swizzled_continueSelectionWithEvent:event forCharacterIndex:characterIndex];
}

- (BOOL)__don_qui_isSelectionInProgress {
    return [objc_getAssociatedObject(self, @selector(__don_qui_isSelectionInProgress)) boolValue];
}

- (void)__don_qui_setIsSelectionInProgress:(BOOL)selecting {
    objc_setAssociatedObject(self, @selector(__don_qui_isSelectionInProgress), @(selecting), OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation HFRepresenterTextView (Mocha)

- (NSColor *)swizzled_inactiveTextSelectionColor {
    return [NSColor selectedTextBackgroundColor];
}

- (void)swizzled_mouseUp:(NSEvent *)event {
    
    BOOL wasSelectionInProgress = [self.representer __don_qui_isSelectionInProgress];
    
    [self swizzled_mouseUp:event];
    
    BOOL shouldReportCharacterClick = YES;
    if (wasSelectionInProgress) {
        NSArray *selectedContentsRanges = [self.representer.controller selectedContentsRanges];
        for (HFRangeWrapper *rangeWrapper in selectedContentsRanges) {
            if (rangeWrapper.HFRange.length > 0) {
                shouldReportCharacterClick = NO;
                break;
            }
        }
    }
    
    if (shouldReportCharacterClick) {
        NSPoint mouseDownLocation = [self convertPoint:[event locationInWindow] fromView:nil];
        NSUInteger characterIndex = [self characterAtPointForSelection:mouseDownLocation];
        [[self.representer.controller viewController] didClickCharacterAt:[[self representer] byteIndexForCharacterIndex:characterIndex]];
    }
    
}

@end

@implementation HexFiendUtil

+ (void)doSwizzleOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodFor:[HFRepresenterTextView class] method:@"inactiveTextSelectionColor"];
        [self swizzleInstanceMethodFor:[HFRepresenterTextView class] method:@"mouseUp:"];
        [self swizzleInstanceMethodFor:[HFTextRepresenter class] method:@"beginSelectionWithEvent:forCharacterIndex:"];
        [self swizzleInstanceMethodFor:[HFTextRepresenter class] method:@"continueSelectionWithEvent:forCharacterIndex:"];
    });
}

+ (void)swizzleInstanceMethodFor:(Class)c method:(NSString *)method {
    SEL orig = NSSelectorFromString(method);
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"swizzled_%@", method]);
    
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

@end

@implementation HFUntouchableLineCountingRepresenter

- (void)cycleLineNumberFormat { return; }

@end
