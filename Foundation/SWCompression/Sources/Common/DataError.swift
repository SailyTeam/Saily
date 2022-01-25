// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Represents an error which happened during processing input data.
public enum DataError: Error, Equatable {
    /// Indicates that input data is likely truncated or incomplete.
    case truncated
    /**
     Indicates that input data is corrupted, e.g. does not conform to the format specifications or contains other
     invalid values.
     */
    case corrupted
    /**
     Indicates that the computed checksum of the output data does not match the stored checksum. While usually the
     associated value contains the output from all processed inputs up to and including the point when this error was
     thrown, it is still recommended to check the documenation of a function to confirm this.
     */
    case checksumMismatch([Data])
    /// Indicates that input data was created using a feature that is not supported by the processing function.
    case unsupportedFeature
}
