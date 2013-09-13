#import <Foundation/Foundation.h>

void SwizzleClassMethod(Class c, SEL orig, SEL replace);

@interface NSObject (swizz)

// This Method allows the class to Swizzle more methods within itself.
// And allows for an overridable init method in Class Extensions
// ######################
// //// To Swizzle a method, call Swizzle once on the class in question.
// //// dispatch_once is a good way to handle that.
//            static dispatch_once_t onceToken;
//            dispatch_once(&onceToken, ^{
//                Swizz([UITableViewCell class], @selector(reuseIdentifier), @selector(classReuseIdentifier));
//            });
@end
