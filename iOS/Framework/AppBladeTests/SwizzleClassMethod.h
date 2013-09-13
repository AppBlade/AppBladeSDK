//
//  SwizzleClassMethod.h
//  AppBlade
//
//  Created by AndrewTremblay on 9/13/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#ifndef AppBlade_SwizzleClassMethod_h
#define AppBlade_SwizzleClassMethod_h

void SwizzleClassMethod(Class c, SEL orig, SEL new) {
    
    Method origMethod = class_getClassMethod(c, orig);
    Method newMethod = class_getClassMethod(c, new);
    
    c = object_getClass((id)c);
    
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}


#endif
