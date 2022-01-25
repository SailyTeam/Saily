// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

/**
 Represents an error which happened during the creation of a new TAR container.

 - Note: This error type is never used and will be removed in the next major update.
 */
public enum TarCreateError: Error {
    /**
     One of the `TarEntryInfo`'s string properties (such as `name`) cannot be encoded with UTF-8 encoding.

     - Note: This error is never thrown and will be removed in the next major update.
     */
    case utf8NonEncodable
}
