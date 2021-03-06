//
//  GLVideoTexture.m
//  GLRenderer
//
//  Created by JT Ma on 11/06/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "GLVideoTexture.h"

@implementation GLVideoTexture {
    CVOpenGLESTextureCacheRef _textureCacheRef;
    CVOpenGLESTextureRef _textureRef;
}

@synthesize
verticesID  = _verticesID,
fragmentsID = _fragmentsID,
textureUVID = _textureUVID,
textureID   = _textureID;

static const SceneVertex kVertices[] = {
    {{-0.5, -0.5, 0}},
    {{ 0.5, -0.5, 0}},
    {{-0.5,  0.5, 0}},
    {{-0.5,  0.5, 0}},
    {{ 0.5, -0.5, 0}},
    {{ 0.5,  0.5, 0}}
};

static UVVertex kUVs[6];

- (void)_rotateUV0 {
    kUVs[0].positionCoords.x = 0; kUVs[0].positionCoords.y = 1;
    kUVs[1].positionCoords.x = 1; kUVs[1].positionCoords.y = 1;
    kUVs[2].positionCoords.x = 0; kUVs[2].positionCoords.y = 0;
    kUVs[3].positionCoords.x = 0; kUVs[3].positionCoords.y = 0;
    kUVs[4].positionCoords.x = 1; kUVs[4].positionCoords.y = 1;
    kUVs[5].positionCoords.x = 1; kUVs[5].positionCoords.y = 0;
}

- (void)_rotateUV90 {
    kUVs[0].positionCoords.x = 1; kUVs[0].positionCoords.y = 1;
    kUVs[1].positionCoords.x = 1; kUVs[1].positionCoords.y = 0;
    kUVs[2].positionCoords.x = 0; kUVs[2].positionCoords.y = 1;
    kUVs[3].positionCoords.x = 0; kUVs[3].positionCoords.y = 1;
    kUVs[4].positionCoords.x = 1; kUVs[4].positionCoords.y = 0;
    kUVs[5].positionCoords.x = 0; kUVs[5].positionCoords.y = 0;
}

- (void)_rotateUV180 {
    kUVs[0].positionCoords.x = 1; kUVs[0].positionCoords.y = 0;
    kUVs[1].positionCoords.x = 0; kUVs[1].positionCoords.y = 0;
    kUVs[2].positionCoords.x = 1; kUVs[2].positionCoords.y = 1;
    kUVs[3].positionCoords.x = 1; kUVs[3].positionCoords.y = 1;
    kUVs[4].positionCoords.x = 0; kUVs[4].positionCoords.y = 0;
    kUVs[5].positionCoords.x = 0; kUVs[5].positionCoords.y = 1;
}

- (void)_rotateUV270 {
    kUVs[0].positionCoords.x = 0; kUVs[0].positionCoords.y = 0;
    kUVs[1].positionCoords.x = 0; kUVs[1].positionCoords.y = 1;
    kUVs[2].positionCoords.x = 1; kUVs[2].positionCoords.y = 0;
    kUVs[3].positionCoords.x = 1; kUVs[3].positionCoords.y = 0;
    kUVs[4].positionCoords.x = 0; kUVs[4].positionCoords.y = 1;
    kUVs[5].positionCoords.x = 1; kUVs[5].positionCoords.y = 1;
}

- (void)_updateUVWithRotation:(NSUInteger)rotation {
    switch (rotation) {
        case 0:
            [self _rotateUV0];
            break;
        case 90:
            [self _rotateUV90];
            break;
        case 180:
            [self _rotateUV180];
            break;
        case 270:
            [self _rotateUV270];
            break;
        default:
            break;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _rotateUV0];
        [self genBuffer];
        [self bindTexture];
        [self createCache];
    }
    return self;
}

- (instancetype)initWithRotation:(NSUInteger)rotation {
    self = [super init];
    if (self) {
        [self _updateUVWithRotation:rotation];
        [self genBuffer];
        [self bindTexture];
        [self createCache];
    }
    return self;
}

- (void)dealloc {
    [self deallocCache];
}

- (void)genBuffer {
    glGenBuffers(1, &_verticesID);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kVertices), kVertices, GL_STATIC_DRAW);

    glGenBuffers(1, &_textureUVID);
    glBindBuffer(GL_ARRAY_BUFFER, _textureUVID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kUVs), kUVs, GL_STATIC_DRAW);
    
    glGenTextures(1, &_textureID);
}

- (void)bindTexture {
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)createCache {
    EAGLContext *context = [EAGLContext currentContext];
    if (context && !_textureCacheRef) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                    NULL,
                                                    context,
                                                    NULL,
                                                    &_textureCacheRef);
        if (err != noErr) {
            if (self.debugLogEnable) NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

- (void)flushCache {
    if (_textureRef) {
        CFRelease(_textureRef);
        _textureRef = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_textureCacheRef, 0);
}

- (void)deallocCache {
    if (_textureRef) {
        CFRelease(_textureRef);
        _textureRef = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_textureCacheRef, 0);
    if(_textureCacheRef) {
        CFRelease(_textureCacheRef);
        _textureCacheRef = NULL;
    }
}

- (void)draw {
    [super draw];
    
    [self.effect prepareToDraw];
    
    glDepthFunc(GL_LESS);
    glActiveTexture(GL_TEXTURE0);
    self.effect.texture2d0.name = _textureID;
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
    glVertexAttribPointer(GLKVertexAttribPosition,
                          3,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(SceneVertex),
                          NULL);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glBindBuffer(GL_ARRAY_BUFFER, _textureUVID);
    glVertexAttribPointer(GLKVertexAttribTexCoord0,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          0,
                          (void*)0);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

- (void)updateTexture:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer != NULL) {
        int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!_textureCacheRef) {
            if (self.debugLogEnable) NSLog(@"No texture cache");
            return;
        }
        
        [self flushCache];
        
        glActiveTexture(GL_TEXTURE0);
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    _textureCacheRef,
                                                                    pixelBuffer,
                                                                    NULL,
                                                                    GL_TEXTURE_2D,
                                                                    GL_RGBA,
                                                                    frameWidth,
                                                                    frameHeight,
                                                                    GL_BGRA,
                                                                    GL_UNSIGNED_BYTE,
                                                                    0,
                                                                    &_textureRef);
        if (err) {
            if (self.debugLogEnable) NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        _textureID = CVOpenGLESTextureGetName(_textureRef);
        [self bindTexture];
    }
}

- (void)updateTexture:(void *)buffer width:(int)width height:(int)height {
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glTexImage2D(GL_TEXTURE_2D,     // Specifies the target texture of the active texture unit. Must be GL_TEXTURE_2D, GL_TEXTURE_CUBE_MAP_POSITIVE_X, GL_TEXTURE_CUBE_MAP_NEGATIVE_X, GL_TEXTURE_CUBE_MAP_POSITIVE_Y, GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, GL_TEXTURE_CUBE_MAP_POSITIVE_Z, or GL_TEXTURE_CUBE_MAP_NEGATIVE_Z.
                 0,                 // Specifies the level-of-detail number. Level 0 is the base image level. Level n is the nth mipmap reduction image.
                 GL_RGBA,           // Specifies the internal format of the texture. Must be one of the following symbolic constants: GL_ALPHA, GL_LUMINANCE, GL_LUMINANCE_ALPHA, GL_RGB, GL_RGBA.
                 width,             // Specifies the width of the texture image. All implementations support 2D texture images that are at least 64 texels wide and cube-mapped texture images that are at least 16 texels wide.
                 height,            // Specifies the height of the texture image All implementations support 2D texture images that are at least 64 texels high and cube-mapped texture images that are at least 16 texels high.
                 0,                 // Specifies the width of the border. Must be 0.
                 GL_BGRA,           // Specifies the format of the texel data. Must match internalformat. The following symbolic values are accepted: GL_ALPHA, GL_RGB, GL_RGBA, GL_LUMINANCE, and GL_LUMINANCE_ALPHA. But in this sample, using GL_BGRA, it's same as kCVPixelFormatType_32BGRA.
                 GL_UNSIGNED_BYTE,  // Specifies the data type of the texel data. The following symbolic values are accepted: GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT_5_6_5, GL_UNSIGNED_SHORT_4_4_4_4, and GL_UNSIGNED_SHORT_5_5_5_1.
                 buffer);           // Specifies a pointer to the image data in memory.
}

@end
