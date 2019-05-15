//
//  GLPanelTexture.h
//  GLRenderer
//
//  Created by JT Ma on 11/06/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "GLTexture.h"

@interface GLPanelTexture : GLTexture

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithColor:(UIColor *)color;

@end
