//
//  Signals.swift
//  AuxiliaryExecute
//
//  Created by Lakr Aream on 2021/12/6.
//

import Foundation

/*

 Copied from XNU bsd/sys/wait.h

 */

internal enum Signal {
    //    #define _W_INT(w)       (*(int *)&(w))  /* convert union wait to int */
    //    #define _WSTATUS(x)     (_W_INT(x) & 0177) <- this is Octal!!!
    //    #define WIFEXITED(x)    (_WSTATUS(x) == 0)
    //    #define WIFSIGNALED(x)  (_WSTATUS(x) != _WSTOPPED && _WSTATUS(x) != 0)

    static func waitExited<T: BinaryInteger>(_ val: T) -> Bool {
        val == 0
    }

    static func waitSignaled<T: BinaryInteger>(_ val: T) -> Bool {
        (val & 127) != _WSTOPPED && (val & 127) != 0
    }

    static func continueWaitLoop<T: BinaryInteger>(_ val: T) -> Bool {
        guard !waitExited(val) else {
            return false
        }
        guard !waitSignaled(val) else {
            return false
        }
        return true
    }
}
