//
//  main.m
//  Viewtiful
//
//  Created by Marius Kintel on Wed Jul 09 2003.
//  Copyright (c) 2003 Systems in Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Inventor/SoDB.h>
#import <SC21/SCController.h>

int main(int argc, const char *argv[])
{
    [SCController initCoin];
    return NSApplicationMain(argc, argv);
}
