package base64

// @ref(zh): https://rosettacode.org/wiki/Base64_encode_data#Java

ENC_TABLE := [64]byte {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 
    'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 
    'w', 'x', 'y', 'z', '0', '1', '2', '3', 
    '4', '5', '6', '7', '8', '9', '+', '/'
};

PADDING :: '=';

DEC_TABLE := [128]int {
    -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, 62, -1, -1, -1, 63, 
    52, 53, 54, 55, 56, 57, 58, 59, 
    60, 61, -1, -1, -1, -1, -1, -1, 
    -1,  0,  1,  2,  3,  4,  5,  6, 
     7,  8,  9, 10, 11, 12, 13, 14, 
    15, 16, 17, 18, 19, 20, 21, 22, 
    23, 24, 25, -1, -1, -1, -1, -1, 
    -1, 26, 27, 28, 29, 30, 31, 32, 
    33, 34, 35, 36, 37, 38, 39, 40, 
    41, 42, 43, 44, 45, 46, 47, 48, 
    49, 50, 51, -1, -1, -1, -1, -1
};

encode :: proc(data: []byte) -> string #no_bounds_check {
    length := len(data);
    if length == 0 do return "";

    out_length := ((4 * length / 3) + 3) &~ 3;
    out := make([]byte, out_length);

    c0, c1, c2, block: int;

    for i, d := 0, 0; i < length; i, d = i + 3, d + 4 {
        c0, c1, c2 = int(data[i]), 0, 0;

        if i + 1 < length do c1 = int(data[i + 1]);
        if i + 2 < length do c2 = int(data[i + 2]);

        block = (c0 << 16) | (max(c1, 0) << 8) | max(c2, 0);

        out[d]     = ENC_TABLE[block >> 18 & 63];
        out[d + 1] = ENC_TABLE[block >> 12 & 63];
        out[d + 2] = c1 == 0 ? PADDING : ENC_TABLE[block >> 6 & 63];
        out[d + 3] = c2 == 0 ? PADDING : ENC_TABLE[block & 63];
    }
    return string(out);
}

decode :: proc(data: string) -> []byte #no_bounds_check{
    length := len(data);
    if length == 0 do return []byte{};
    assert(length % 4 == 0, "Malformed Base64 input");

    pad_count := data[length - 1] == PADDING ? (data[length - 2] == PADDING ? 2 : 1) : 0;
    out_length := ((length * 6) >> 3) - pad_count;
    out := make([]byte, out_length);

    c0, c1, c2, c3: int;
    b0, b1, b2: int;

    for i, j := 0, 0; i < length; i, j = i + 4, j + 3 {
        c0 = DEC_TABLE[data[i]];
        c1 = DEC_TABLE[data[i + 1]];
        c2 = DEC_TABLE[data[i + 2]];
        c3 = DEC_TABLE[data[i + 3]];

        b0 = (c0 << 2) | (c1 >> 4);
        b1 = (c1 << 4) | (c2 >> 2);
        b2 = (c2 << 6) | c3;

        out[j]     = byte(b0);
        out[j + 1] = byte(b1);
        out[j + 2] = byte(b2);
    }
    return out;
}

// @note(zh): Test inputs. Larger one is taken from the WikiPedia entry for Base64
/* 
main :: proc() {
    str := "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
    expected := "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=";

    out := encode(([]byte)(str));
    assert(out == expected, "Wrong base64 string produced for str");

    out_dec := decode(expected);
    assert(string(out_dec) == str, "base64 decoded wrongly for str");

    str2 := "aaaaaaaaa";
    expected2 := "YWFhYWFhYWFh";

    out2 := encode(([]byte)(str2));
    assert(out2 == expected2, "Wrong base64 string produced for str2");

    out_dec2 := decode(expected2);
    assert(string(out_dec2) == str2, "base64 decoded wrongly for str2");
}
*/