//
//  PropertyDescriptionOption.h
//  QUANTWM
//
//  Created by Xavier on 16/05/16.
//  Copyright © 2016 XL Software Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, PropertyDescriptionOption)
{
    PropertyDescriptionOptionNone               =  0,
    PropertyDescriptionOptionContainsNode       = 1 << 1,
    PropertyDescriptionOptionContainsCollection = 1 << 2,
    PropertyDescriptionOptionIsRoot             = 1 << 3,
    PropertyDescriptionOptionIsObjectiveC       = 1 << 4,
};


