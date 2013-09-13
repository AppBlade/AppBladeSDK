#import "NSObject+MethodSwizzling.h"
#import <objc/runtime.h>
#import <objc/message.h>

void Swizz(Class c, SEL orig, SEL replace)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, replace);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, replace, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}


@implementation NSObject (swizz)

// Load gets called on every object that has it. Off Thread, before application start.
+ (void) load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizz([NSObject class], @selector(init), @selector(initIntercept));
    });
}

- (id) initIntercept{
    self = [self initIntercept]; // Calls the Original init method
    if(self){
        [self swizzInit];
    }
    return self;
}

- (void) swizzInit{
    //Do Nothing.. Gives an extension point for other classes.
}

@end
