const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const mem = std.mem;
const Allocator = mem.Allocator;
const zigstr = @import("zig-string/zig-string.zig");
const String = zigstr.String;

pub const Token = struct {
    raw: []u8,
};

pub fn lexLojbanString(allocator: Allocator, chars: []const u8) ![]const Token {
    // Create your String
    var string: String = String.init(&allocator);
    defer string.deinit();

    try string.concat(chars);

    var tokens: ArrayList(Token) = ArrayList(Token).init(allocator);
    defer tokens.deinit();

    const str_size: usize = string.len();
    var str_i: usize = 0;

    var append_to_token: bool = true;

    var current_token: ArrayList(u8) = ArrayList(u8).init(allocator);
    defer current_token.deinit();

    while(str_i < str_size) {
        var char: []const u8 = string.charAt(str_i) orelse {
            std.debug.print("charAt failed! possible invalid string or zig-string is broken!\n", .{});
            unreachable;
        };

        //Check if the current character is a space, if so then we have reached the end of a token
        if(mem.eql(u8, " ", char)) {
            try tokens.append(Token {
                .raw = current_token.toOwnedSlice()
            });

            current_token.clearRetainingCapacity();
            append_to_token = false;
        }

        if(append_to_token)
            try current_token.appendSlice(char);

        str_i += 1;
        append_to_token = true;
        if(str_i == str_size)
            try tokens.append(Token {
                .raw = current_token.toOwnedSlice()
            });

        // allocator.free(char);
    }

    // current_token.deinit();

    return tokens.toOwnedSlice();
}

pub fn main() anyerror!void {
    
}

test "lexer test" {
    //Our real allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator: std.mem.Allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) std.testing.expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }

    //We use this to just blanket clear all memory used in the lexer
    var arena_allocator = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena_allocator.deinit();

    const tokens: []const Token = try lexLojbanString(arena_allocator.allocator(), ".i lo sonci cu se pluka lo ckape je lo nunkei gi'e se mu'i bo nelci lo ninmu ku noi jai caprai co selkei");

    //Make sure we got the amount of tokens expected
    try std.testing.expectEqual(@as(usize, 24), tokens.len);

    for(tokens) |token| {
        std.debug.print("{s} ", .{ token.raw });
    }
    std.debug.print("\n", .{});
}
