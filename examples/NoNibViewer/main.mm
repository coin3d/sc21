//
//  main.m
//  NoNibViewer
//
//  Created by Marius Kintel on Mon Jul 14 2003.
//  Copyright (c) 2003 Systems in Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SC21/SCController.h>

int main(int argc, const char *argv[])
{
  [SCController initCoin];
  return NSApplicationMain(argc, argv);
}
