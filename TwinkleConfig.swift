//
//  TwinkleConfig.swift
//  ProjectTemplete
//
//  Created by allen on 16/6/30.
//  Copyright © 2016年 com.allen. All rights reserved.
//

import Foundation

func TwinkleLog<T>(message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line)
{
    #if TWINKLEDEBUG
        print("[DEBUG]\((file as NSString).lastPathComponent) \(method) line:\(line) \(message)")
    #endif
}

#if TWINKLEDEBUG
    public let __kXMLPath__ = "ApplicationContext.xml"
    public let __kAESKey__ = ""
#else
    public let __kXMLPath__ = "ApplicationContext.juwang"
    public let __kAESKey__ = "com.juwang"
#endif
