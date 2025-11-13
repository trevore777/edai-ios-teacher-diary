//
//  DateFormatter+Ext.swift
//  songcaptureV3
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation


extension DateFormatter {
static let songStamp: DateFormatter = {
let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
return df
}()
}