//
//  Error+Extension.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 06.01.2020.
//

import Foundation

extension Error {
  var code: Int { return (self as NSError).code }
  var noInternetConnection: Bool {code == -1009}
  var domain: String { return (self as NSError).domain }
}
