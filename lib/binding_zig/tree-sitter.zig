const std = @import("std");
const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

// ==============================
// =  Section - ABI Versioning  =
// ==============================

/// The latest ABI version that is supported by the current version of the
/// library. When Languages are generated by the Tree-sitter CLI, they are
/// assigned an ABI version number that corresponds to the current CLI version.
/// The Tree-sitter library is generally backwards-compatible with languages
/// generated using older CLI versions, but is not forwards-compatible.
pub const LANGUAGE_VERSION = 14;

/// The earliest ABI version that is supported by the current version of the
/// library.
pub const MIN_COMPATIBLE_LANGUAGE_VERSION = 13;

// =====================
// =  Section - Types  =
// =====================

pub const StateId = u16;
pub const Symbol = u16;
pub const FieldId = u16;

test {
    try std.testing.expectEqual(@TypeOf(c.TSStateId), @TypeOf(StateId));
    try std.testing.expectEqual(@TypeOf(c.TSSymbol), @TypeOf(Symbol));
    try std.testing.expectEqual(@TypeOf(c.TSFieldId), @TypeOf(FieldId));
}

pub const Language = opaque {};
pub const Parser = opaque {};
pub const LookaheadIterator = opaque {};

pub const SymbolType = enum(c_uint) {
    regular,
    anonymous,
    auxiliary,
};

test {
    try std.testing.expectEqual(
        c.TSSymbolTypeRegular,
        @intFromEnum(SymbolType.regular),
    );
    try std.testing.expectEqual(
        c.TSSymbolTypeAnonymous,
        @intFromEnum(SymbolType.anonymous),
    );
    try std.testing.expectEqual(
        c.TSSymbolTypeAuxiliary,
        @intFromEnum(SymbolType.auxiliary),
    );
}

pub const Point = extern struct {
    row: u32,
    column: u32,
};

pub const Range = extern struct {
    start_point: Point,
    end_point: Point,
    start_byte: u32,
    end_byte: u32,
};

test {
    try std.testing.expectEqual(@sizeOf(c.TSPoint), @sizeOf(Point));
    try std.testing.expectEqual(@sizeOf(c.TSRange), @sizeOf(Range));
}

pub const Input = extern struct {
    payload: ?*anyopaque,
    read: ?*const fn (
        payload: ?*anyopaque,
        byte_index: u32,
        position: Point,
        bytes_read: *u32,
    ) callconv(.C) [*]const u8,
    encoding: Encoding,

    pub const Encoding = enum(c_uint) {
        utf8,
        utf16,
    };

    pub const Edit = extern struct {
        start_byte: u32,
        old_end_byte: u32,
        new_end_byte: u32,
        start_point: Point,
        old_end_point: Point,
        new_end_point: Point,
    };
};

test {
    try std.testing.expectEqual(@sizeOf(c.TSInput), @sizeOf(Input));
    try std.testing.expectEqual(
        @sizeOf(c.TSInputEncoding),
        @sizeOf(Input.Encoding),
    );
    try std.testing.expectEqual(
        c.TSInputEncodingUTF8,
        @intFromEnum(Input.Encoding.utf8),
    );
    try std.testing.expectEqual(
        c.TSInputEncodingUTF16,
        @intFromEnum(Input.Encoding.utf16),
    );
    try std.testing.expectEqual(@sizeOf(c.TSInputEdit), @sizeOf(Input.Edit));
}

pub const LogType = enum(c_uint) {
    parse,
    lex,
};

test {
    try std.testing.expectEqual(c.TSLogTypeParse, @intFromEnum(LogType.parse));
    try std.testing.expectEqual(c.TSLogTypeLex, @intFromEnum(LogType.lex));
}

pub const Logger = extern struct {
    payload: ?*anyopaque,
    log: ?*const fn (
        payload: ?*anyopaque,
        log_type: LogType,
        buffer: [*c]const u8,
    ) callconv(.C) void,
};

test {
    try std.testing.expectEqual(@sizeOf(c.TSLogger), @sizeOf(Logger));
}

pub const Node = extern struct {
    context: [4]u32,
    id: ?*anyopaque,
    tree: ?*Tree,
};

test {
    try std.testing.expectEqual(@sizeOf(c.TSNode), @sizeOf(Node));
}

pub const Tree = opaque {
    pub const Cursor = extern struct {
        tree: ?*anyopaque,
        id: ?*anyopaque,
        context: [3]u32,
    };
};

test {
    try std.testing.expectEqual(@sizeOf(c.TSTreeCursor), @sizeOf(Tree.Cursor));
}

pub const Quantifier = enum(c_uint) {
    zero = 0,
    zero_or_one,
    zero_or_more,
    one,
    one_or_more,
};

test {
    try std.testing.expectEqual(
        c.TSQuantifierZero,
        @intFromEnum(Quantifier.zero),
    );
    try std.testing.expectEqual(
        c.TSQuantifierZeroOrOne,
        @intFromEnum(Quantifier.zero_or_one),
    );
    try std.testing.expectEqual(
        c.TSQuantifierZeroOrMore,
        @intFromEnum(Quantifier.zero_or_more),
    );
    try std.testing.expectEqual(
        c.TSQuantifierOne,
        @intFromEnum(Quantifier.one),
    );
    try std.testing.expectEqual(
        c.TSQuantifierOneOrMore,
        @intFromEnum(Quantifier.one_or_more),
    );
}

pub const Query = opaque {
    pub const Cursor = opaque {};

    pub const Capture = extern struct {
        node: Node,
        index: u32,
    };

    pub const Match = extern struct {
        id: u32,
        pattern_index: u16,
        capture_count: u16,
        captures: [*]Capture,
    };

    pub const PredicateStep = extern struct {
        type: Type,
        value_id: u32,

        pub const Type = enum(c_uint) {
            done,
            capture,
            string,
        };
    };

    pub const Error = enum(c_uint) {
        none = 0,
        syntax,
        node_type,
        field,
        capture,
        structure,
        language,
    };
};

// ======================
// =  Section - Parser  =
// ======================

/// Create a new parser.
extern "tree-sitter" fn ts_parser_new() callconv(.C) Parser;

/// Delete the parser, freeing all of the memory that it used.
extern "tree-sitter" fn ts_parser_delete(self: *Parser) callconv(.C) void;

/// Get the parser's current language.
extern "tree-sitter" fn ts_parser_language(
    self: *const Parser,
) callconv(.C) ?*const Language;

/// Set the language that the parser should use for parsing.
///
/// Returns a boolean indicating whether or not the language was successfully
/// assigned. True means assignment succeeded. False means there was a version
/// mismatch: the language was generated with an incompatible version of the
/// Tree-sitter CLI. Check the language's version using [`ts_language_version`]
/// and compare it to this library's [`LANGUAGE_VERSION`] and
/// [`MIN_COMPATIBLE_LANGUAGE_VEVRSION`] constants.
extern "tree-sitter" fn ts_parser_set_language(
    self: *Parser,
    language: *const Language,
) callconv(.C) bool;

/// Set the ranges of text that the parser should include when parsing.
///
/// By default, the parser will always include entire documents. This function
/// allows you to parse only a *portion* of a document but still return a
/// syntax tree whose ranges match up with the document as a whole. You can
/// also pass multiple disjoint ranges.
///
/// The second and third parameters specify the location and length of an array
/// of ranges. The parser does *not* take ownership of these ranges; it copies
/// the data, so it doesn't matter how these ranges are allocated.
///
/// If `count` is zero, then the entire document will be parsed. Otherwise, the
/// given ranges must be ordered from earliest to latest in the document, and
/// they must not overlap. That is, the following must hold for all:
///
/// `i < count - 1`: `ranges[i].end_byte <= ranges[i + 1].start_byte`
///
/// If this requirement is not satisfied, the operation will fail, the ranges
/// will not be assigned, and this function will return `false`. On success,
/// this function returns `true`.
extern "tree-sitter" fn ts_parser_set_included_ranges(
    self: *Parser,
    ranges: [*]const Range,
    count: u32,
) callconv(.C) bool;

/// Get the ranges of text that the parser will include when parsing.
///
/// The returned pointer is owned by the parser. The caller should not free it
/// or write to it. The length of the array will be written to the given
/// `count` pointer.
extern "tree-sitter" fn ts_parser_included_ranges(
    self: *const Parser,
    count: *u32,
) callconv(.C) [*]const Range;

/// Use the parser to parse some source code and create a syntax tree.
///
/// If you are parsing this document for the first time, pass `null` for the
/// `old_tree` parameter. Otherwise, if you have already parsed an earlier
/// version of this document and the document has since been edited, pass the
/// previous syntax tree so that the unchanged parts of it can be reused. This
/// will save time and memory. For this to work correctly, you must have
/// already edited the old syntax tree using the [`ts_tree_edit`] function in a
/// way that exactly matches the source code changes.
///
/// The [`Input`] parameter lets you specify how to read the text. It has the
/// following three fields:
/// 1. [`read`]: A function to retrieve a chunk of text at a given byte offset
///    and (row, column) position. The function should return a pointer to the
///    text and write its length to the [`bytes_read`] pointer. The parser does
///    not take ownership of this buffer; it just borrows it until it has
///    finished reading it. The function should write a zero value to the
///    [`bytes_read`] pointer to indicate the end of the document.
/// 2. [`payload`]: An arbitrary pointer that will be passed to each invocation
///    of the [`read`] function.
/// 3. [`encoding`]: An indication of how the text is encoded.
///
/// This function returns a syntax tree on success, and `null` on failure.
/// There are three possible reasons for failure:
/// 1. The parser does not have a language assigned. Check for this using the
///    [`ts_parser_language`] function.
/// 2. Parsing was cancelled due to a timeout that was set by an earlier call
///    to the [`ts_parser_set_timeout_micros`] function. You can resume parsing
///    from where the parser left out by calling [`ts_parser_parse`] again with
///    the same arguments. Or you can start parsing from scratch by first
///    calling [`ts_parser_reset`].
/// 3. Parsing was cancelled using a cancellation flag that was set by an
///    earlier call to [`ts_parser_set_cancellation_flag`]. You can resume
///    parsing from where the parser left out by calling [`ts_parser_parse`]
///    again with the same arguments.
extern "tree-sitter" fn ts_parser_parse(
    self: *Parser,
    old_tree: ?*const Tree,
    input: Input,
) callconv(.C) ?*Tree;

/// Use the parser to parse some source code stored in one contiguous buffer.
/// The first two parameters are the same as in the [`ts_parser_parse`]
/// function.above. The second two parameters indicate the location of the
/// buffer and its length in bytes.
extern "tree-sitter" fn ts_parser_parse_string(
    self: *Parser,
    old_tree: ?*const Tree,
    string: [*]const u8,
    length: u32,
) callconv(.C) ?*Tree;

/// Use the parser to parse some source code stored in one contiguous buffer
/// with a given encoding. The first four parameters work the same as in the
/// [`ts_parser_parse_string`] method above. The final parameter indicates
/// whether the text is encoded as UTF8 or UTF16.
extern "tree-sitter" fn ts_parser_parse_string_encoding(
    self: *Parser,
    old_tree: ?*const Tree,
    string: [*]const u8,
    length: u32,
    encoding: Input.Encoding,
) callconv(.C) ?*Tree;

/// Instruct the parser to start the next parse from the beginning.
///
/// If the parser previously failed because of a timeout or a cancellation,
/// then by default, it will resume where it left off on the next call to
/// [`ts_parser_parse`] or other parsing functions. If you don't want to
/// resume, and instead intend to use this parser to parse some other document,
/// you must call [`ts_parser_reset`] first.
extern "tree-sitter" fn ts_parser_reset(self: *Parser) callconv(.C) void;

/// Set the maximum duration in microseconds that parsing should be allowed to
/// take before halting.
///
/// If parsing takes longer than this, it will halt early, returning `null`.
/// See [`ts_parser_parse`] for more information.
extern "tree-sitter" fn ts_parser_set_timeout_micros(
    self: *Parser,
    timeout_micros: u64,
) callconv(.C) void;

/// Get the duration in microseconds that parsing is allowed to take.
extern "tree-sitter" fn ts_parser_timeout_micros(
    self: *const Parser,
) callconv(.C) u64;

/// Set the parser's current cancellation flag pointer.
///
/// If a non-null pointer is assigned, then the parser will periodically read
/// from this pointer during parsing. If it reads a non-zero value, it will
/// halt early, returning `null`. See [`ts_parser_parse`] for more information.
extern "tree-sitter" fn ts_parser_set_cancellation_flag(
    self: *Parser,
    flag: ?*const isize,
) callconv(.C) void;

/// Get the parser's current cancellation flag pointer.
extern "tree-sitter" fn ts_parser_cancellation_flag(
    self: *const Parser,
) callconv(.C) ?*const isize;
