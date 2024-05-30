class Si {
    public var vkFormat:Int;
    public var typeSize:Int;
    public var pixelWidth:Int;
    public var pixelHeight:Int;
    public var pixelDepth:Int;
    public var layerCount:Int;
    public var faceCount:Int;
    public var supercompressionScheme:Int;
    public var levels:Array<Map<String, Dynamic>>;
    public var dataFormatDescriptor:Array<Map<String, Dynamic>>;
    public var keyValue:Map<String, String>;
    public var globalData:Dynamic;

    public function new() {
        vkFormat = 0;
        typeSize = 1;
        pixelWidth = 0;
        pixelHeight = 0;
        pixelDepth = 0;
        layerCount = 0;
        faceCount = 1;
        supercompressionScheme = 0;
        levels = [];
        dataFormatDescriptor = [{
            "vendorId": 0,
            "descriptorType": 0,
            "descriptorBlockSize": 0,
            "versionNumber": 2,
            "colorModel": 0,
            "colorPrimaries": 1,
            "transferFunction": 2,
            "flags": 0,
            "texelBlockDimension": [0, 0, 0, 0],
            "bytesPlane": [0, 0, 0, 0, 0, 0, 0, 0],
            "samples": []
        }];
        keyValue = new Map();
        globalData = null;
    }
}

class Ii {
    public var _dataView:DataView;
    public var _littleEndian:Bool;
    public var _offset:Int;

    public function new(t:ArrayBuffer, e:Int, n:Int, i:Bool) {
        _dataView = new DataView(t, e, n);
        _littleEndian = i;
        _offset = 0;
    }

    public function _nextUint8():Int {
        var t = _dataView.getUint8(_offset);
        _offset += 1;
        return t;
    }

    public function _nextUint16():Int {
        var t = _dataView.getUint16(_offset, _littleEndian);
        _offset += 2;
        return t;
    }

    public function _nextUint32():Int {
        var t = _dataView.getUint32(_offset, _littleEndian);
        _offset += 4;
        return t;
    }

    public function _nextUint64():Int {
        var t = _dataView.getUint32(_offset, _littleEndian) + 2 ** 32 * _dataView.getUint32(_offset + 4, _littleEndian);
        _offset += 8;
        return t;
    }

    public function _nextInt32():Int {
        var t = _dataView.getInt32(_offset, _littleEndian);
        _offset += 4;
        return t;
    }

    public function _skip(t:Int):Void {
        _offset += t;
    }

    public function _scan(t:Int, e:Int = 0):Uint8Array {
        var n = _offset;
        var i = 0;
        while (_dataView.getUint8(_offset) != e && i < t) {
            i++;
            _offset++;
        }
        if (i < t) {
            _offset++;
        }
        return new Uint8Array(_dataView.buffer, _dataView.byteOffset + n, i);
    }
}

static var Oi = new Uint8Array([0]);
static var Ti = [171, 75, 84, 88, 32, 50, 48, 187, 13, 10, 26, 10];

function Vi(t) {
    if (typeof TextEncoder != "undefined") {
        return (new TextEncoder()).encode(t);
    } else {
        return Buffer.from(t);
    }
}

function Ei(t) {
    if (typeof TextDecoder != "undefined") {
        return (new TextDecoder()).decode(t);
    } else {
        return Buffer.from(t).toString("utf8");
    }
}

function Fi(t) {
    var e = 0;
    for (var n in t) {
        e += n.byteLength;
    }
    var i = new Uint8Array(e);
    var s = 0;
    for (var n in t) {
        i.set(new Uint8Array(n), s);
        s += n.byteLength;
    }
    return i;
}

function Pi(t) {
    var e = new Uint8Array(t.buffer, t.byteOffset, Ti.length);
    if (e[0] != Ti[0] || e[1] != Ti[1] || e[2] != Ti[2] || e[3] != Ti[3] || e[4] != Ti[4] || e[5] != Ti[5] || e[6] != Ti[6] || e[7] != Ti[7] || e[8] != Ti[8] || e[9] != Ti[9] || e[10] != Ti[10] || e[11] != Ti[11]) {
        throw new Error("Missing KTX 2.0 identifier.");
    }
    var n = new Si();
    var i = 17 * Uint32Array.BYTES_PER_ELEMENT;
    var s = new Ii(t, Ti.length, i, true);
    n.vkFormat = s._nextUint32();
    n.typeSize = s._nextUint32();
    n.pixelWidth = s._nextUint32();
    n.pixelHeight = s._nextUint32();
    n.pixelDepth = s._nextUint32();
    n.layerCount = s._nextUint32();
    n.faceCount = s._nextUint32();
    var a = s._nextUint32();
    n.supercompressionScheme = s._nextUint32();
    var r = s._nextUint32();
    var o = s._nextUint32();
    var l = s._nextUint32();
    var f = s._nextUint32();
    var U = s._nextUint64();
    var c = s._nextUint64();
    var h = new Ii(t, Ti.length + i, 3 * a * 8, true);
    for (var e = 0; e < a; e++) {
        n.levels.push({
            "levelData": new Uint8Array(t.buffer, t.byteOffset + h._nextUint64(), h._nextUint64()),
            "uncompressedByteLength": h._nextUint64()
        });
    }
    var _ = new Ii(t, r, o, true);
    var p = {
        "vendorId": _._skip(4)._nextUint16(),
        "descriptorType": _._nextUint16(),
        "versionNumber": _._nextUint16(),
        "descriptorBlockSize": _._nextUint16(),
        "colorModel": _._nextUint8(),
        "colorPrimaries": _._nextUint8(),
        "transferFunction": _._nextUint8(),
        "flags": _._nextUint8(),
        "texelBlockDimension": [_._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8()],
        "bytesPlane": [_._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8()],
        "samples": []
    };
    var g = (p.descriptorBlockSize / 4 - 6) / 4;
    for (var t = 0; t < g; t++) {
        var e = {
            "bitOffset": _._nextUint16(),
            "bitLength": _._nextUint8(),
            "channelType": _._nextUint8(),
            "samplePosition": [_._nextUint8(), _._nextUint8(), _._nextUint8(), _._nextUint8()],
            "sampleLower": -Infinity,
            "sampleUpper": Infinity
        };
        if (64 & e.channelType) {
            e.sampleLower = _._nextInt32();
            e.sampleUpper = _._nextInt32();
        } else {
            e.sampleLower = _._nextUint32();
            e.sampleUpper = _._nextUint32();
        }
        p.samples[t] = e;
    }
    n.dataFormatDescriptor.length = 0;
    n.dataFormatDescriptor.push(p);
    var y = new Ii(t, l, f, true);
    while (y._offset < f) {
        var t = y._nextUint32();
        var e = y._scan(t);
        var i = Ei(e);
        var s = y._scan(t - e.byteLength);
        n.keyValue[i] = i.match(/^ktx/i) ? Ei(s) : s;
        if (y._offset % 4 != 0) {
            y._skip(4 - y._offset % 4);
        }
    }
    if (c <= 0) {
        return n;
    }
    var x = new Ii(t, U, c, true);
    var u = x._nextUint16();
    var b = x._nextUint16();
    var d = x._nextUint32();
    var m = x._nextUint32();
    var w = x._nextUint32();
    var D = x._nextUint32();
    var B = [];
    for (var t = 0; t < a; t++) {
        B.push({
            "imageFlags": x._nextUint32(),
            "rgbSliceByteOffset": x._nextUint32(),
            "rgbSliceByteLength": x._nextUint32(),
            "alphaSliceByteOffset": x._nextUint32(),
            "alphaSliceByteLength": x._nextUint32()
        });
    }
    var L = U + x._offset;
    var A = L + d;
    var k = A + m;
    var v = k + w;
    var S = new Uint8Array(t.buffer, t.byteOffset + L, d);
    var I = new Uint8Array(t.buffer, t.byteOffset + A, m);
    var O = new Uint8Array(t.buffer, t.byteOffset + k, w);
    var T = new Uint8Array(t.buffer, t.byteOffset + v, D);
    n.globalData = {
        "endpointCount": u,
        "selectorCount": b,
        "imageDescs": B,
        "endpointsData": S,
        "selectorsData": I,
        "tablesData": O,
        "extendedData": T
    };
    return n;
}

function Ci(t, e) {
    if (e == null) {
        e = {};
    }
    for (var n in e) {
        t[n] = e[n];
    }
    return t;
}

static var zi = {
    "keepWriter": false
};

function Mi(t, e = {}) {
    e = Ci({}, zi, e);
    var n = new ArrayBuffer(0);
    if (t.globalData) {
        var i = new ArrayBuffer(20 + 5 * t.globalData.imageDescs.length * 4);
        var s = new DataView(i);
        s.setUint16(0, t.globalData.endpointCount, true);
        s.setUint16(2, t.globalData.selectorCount, true);
        s.setUint32(4, t.globalData.endpointsData.byteLength, true);
        s.setUint32(8, t.globalData.selectorsData.byteLength, true);
        s.setUint32(12, t.globalData.tablesData.byteLength, true);
        s.setUint32(16, t.globalData.extendedData.byteLength, true);
        for (var a = 0; a < t.globalData.imageDescs.length; a++) {
            var r = t.globalData.imageDescs[a];
            s.setUint32(20 + 5 * a * 4 + 0, r.imageFlags, true);
            s.setUint32(20 + 5 * a * 4 + 4, r.rgbSliceByteOffset, true);
            s.setUint32(20 + 5 * a * 4 + 8, r.rgbSliceByteLength, true);
            s.setUint32(20 + 5 * a * 4 + 12, r.alphaSliceByteOffset, true);
            s.setUint32(20 + 5 * a * 4 + 16, r.alphaSliceByteLength, true);
        }
        n = Fi([i, t.globalData.endpointsData, t.globalData.selectorsData, t.globalData.tablesData, t.globalData.extendedData]);
    }
    var o = [];
    var l = t.keyValue;
    if (!e.keepWriter) {
        l = Ci({}, t.keyValue, {
            "KTXwriter": "KTX-Parse v0.3.1"
        });
    }
    for (var f in l) {
        var U = Vi(f);
        var c = "string" == typeof l[f] ? Vi(l[f]) : l[f];
        var h = U.byteLength + 1 + c.byteLength + 1;
        var _ = h % 4 ? 4 - h % 4 : 0;
        o.push(Fi([new Uint32Array([h]), U, Oi, c, Oi, new Uint8Array(_).fill(0)]));
    }
    var p = Fi(o);
    if (1 != t.dataFormatDescriptor.length || 0 != t.dataFormatDescriptor[0].descriptorType) {
        throw new Error("Only BASICFORMAT Data Format Descriptor output supported.");
    }
    var g = t.dataFormatDescriptor[0];
    var y = new ArrayBuffer(28 + 16 * g.samples.length);
    var x = new DataView(y);
    x.setUint32(0, y.byteLength, true);
    x.setUint16(4, g.vendorId, true);
    x.setUint16(6, g.descriptorType, true);
    x.setUint16(8, g.versionNumber, true);
    x.setUint16(10, 24 + 16 * g.samples.length, true);
    x.setUint8(12, g.colorModel);
    x.setUint8(13, g.colorPrimaries);
    x.setUint8(14, g.transferFunction);
    x.setUint8(15, g.flags);
    if (Array.isArray(g.texelBlockDimension)) {
        throw new Error("texelBlockDimension is now an array. For dimensionality `d`, set `d - 1`.");
    }
    x.setUint8(16, g.texelBlockDimension[0]);
    x.setUint8(17, g.texelBlockDimension[1]);
    x.setUint8(18, g.texelBlockDimension[2]);
    x.setUint8(19, g.texelBlockDimension[3]);
    for (var u = 0; u < 8; u++) {
        x.setUint8(20 + u, g.bytesPlane[u]);
    }
    for (var b = 0; b < g.samples.length; b++) {
        var d = g.samples[b];
        var m = 28 + 16 * b;
        if (d.channelID) {
            throw new Error("channelID has been renamed to channelType.");
        }
        x.setUint16(m + 0, d.bitOffset, true);
        x.setUint8(m + 2, d.bitLength);
        x.setUint8(m + 3, d.channelType);
        x.setUint8(m + 4, d.samplePosition[0]);
        x.setUint8(m + 5, d.samplePosition[1]);
        x.setUint8(m + 6, d.samplePosition[2]);
        x.setUint8(m + 7, d.samplePosition[3]);
        if (64 & d.channelType) {
            x.setInt32(m + 8, d.sampleLower, true);
            x.setInt32(m + 12, d.sampleUpper, true);
        } else {
            x.setUint32(m + 8, d.sampleLower, true);
            x.setUint32(m + 12, d.sampleUpper, true);
        }
    }
    var D = Ti.length + 68 + 3 * t.levels.length * 8;
    var B = D + y.byteLength;
    var L = n.byteLength > 0 ? B + p.byteLength : 0;
    if (L % 8 != 0) {
        L += 8 - L % 8;
    }
    var A = [];
    var k = new DataView(new ArrayBuffer(3 * t.levels.length * 8));
    var v = (L || B + p.byteLength) + n.byteLength;
    for (var f = 0; f < t.levels.length;
    for (var f = 0; f < t.levels.length; f++) {
        var e = t.levels[f];
        A.push(e.levelData);
        k.setBigUint64(24 * f + 0, BigInt(v), true);
        k.setBigUint64(24 * f + 8, BigInt(e.levelData.byteLength), true);
        k.setBigUint64(24 * f + 16, BigInt(e.uncompressedByteLength), true);
        v += e.levelData.byteLength;
    }
    var S = new ArrayBuffer(68);
    var I = new DataView(S);
    I.setUint32(0, t.vkFormat, true);
    I.setUint32(4, t.typeSize, true);
    I.setUint32(8, t.pixelWidth, true);
    I.setUint32(12, t.pixelHeight, true);
    I.setUint32(16, t.pixelDepth, true);
    I.setUint32(20, t.layerCount, true);
    I.setUint32(24, t.faceCount, true);
    I.setUint32(28, t.levels.length, true);
    I.setUint32(32, t.supercompressionScheme, true);
    I.setUint32(36, U, true);
    I.setUint32(40, o.byteLength, true);
    I.setUint32(44, c, true);
    I.setUint32(48, a.byteLength, true);
    I.setBigUint64(52, BigInt(n.byteLength > 0 ? L : 0), true);
    I.setBigUint64(60, BigInt(n.byteLength), true);
    return new Uint8Array(Fi([new Uint8Array(Ti).buffer, S, k.buffer, y, a, L > 0 ? new ArrayBuffer(L - (c + a.byteLength)) : new ArrayBuffer(0), n, ...A]));
}

class KTX2Container {
    public var vkFormat:Int;
    public var typeSize:Int;
    public var pixelWidth:Int;
    public var pixelHeight:Int;
    public var pixelDepth:Int;
    public var layerCount:Int;
    public var faceCount:Int;
    public var levels:Array<Map<String, Dynamic>>;
    public var supercompressionScheme:Int;
    public var keyValue:Map<String, String>;
    public var dataFormatDescriptor:Array<Map<String, Dynamic>>;
    public var globalData:Dynamic;

    public function new() {
        vkFormat = 0;
        typeSize = 1;
        pixelWidth = 0;
        pixelHeight = 0;
        pixelDepth = 0;
        layerCount = 0;
        faceCount = 1;
        supercompressionScheme = 0;
        levels = [];
        keyValue = new Map();
        dataFormatDescriptor = [];
        globalData = null;
    }
}

static var KHR_DF_CHANNEL_RGBSDA_ALPHA = "alpha";
static var KHR_DF_CHANNEL_RGBSDA_BLUE = "blue";
static var KHR_DF_CHANNEL_RGBSDA_DEPTH = "depth";
static var KHR_DF_CHANNEL_RGBSDA_GREEN = "green";
static var KHR_DF_CHANNEL_RGBSDA_RED = "red";
static var KHR_DF_CHANNEL_RGBSDA_STENCIL = "stencil";
static var KHR_DF_FLAG_ALPHA_PREMULTIPLIED = "alphaPremultiplied";
static var KHR_DF_FLAG_ALPHA_STRAIGHT = "alphaStraight";
static var KHR_DF_KHR_DESCRIPTORTYPE_BASICFORMAT = "basicFormat";
static var KHR_DF_MODEL_ASTC = "astc";
static var KHR_DF_MODEL_ETC1 = "etc1";
static var KHR_DF_MODEL_ETC1S = "etc1s";
static var KHR_DF_MODEL_ETC2 = "etc2";
static var KHR_DF_MODEL_RGBSDA = "rgbsda";
static var KHR_DF_MODEL_UNSPECIFIED = "unspecified";
static var KHR_DF_PRIMARIES_ACES = "aces";
static var KHR_DF_PRIMARIES_ACESCC = "acescc";
static var KHR_DF_PRIMARIES_ADOBERGB = "adobergb";
static var KHR_DF_PRIMARIES_BT2020 = "bt2020";
static var KHR_DF_PRIMARIES_BT601_EBU = "bt601Ebu";
static var KHR_DF_PRIMARIES_BT601_SMPTE = "bt601Smpte";
static var KHR_DF_PRIMARIES_BT709 = "bt709";
static var KHR_DF_PRIMARIES_CIEXYZ = "ciexyz";
static var KHR_DF_PRIMARIES_DISPLAYP3 = "displayP3";
static var KHR_DF_PRIMARIES_NTSC1953 = "ntsc1953";
static var KHR_DF_PRIMARIES_PAL525 = "pal525";
static var KHR_DF_PRIMARIES_UNSPECIFIED = "unspecified";
static var KHR_DF_SAMPLE_DATATYPE_EXPONENT = "exponent";
static var KHR_DF_SAMPLE_DATATYPE_FLOAT = "float";
static var KHR_DF_SAMPLE_DATATYPE_LINEAR = "linear";
static var KHR_DF_SAMPLE_DATATYPE_SIGNED = "signed";
static var KHR_DF_TRANSFER_ACESCC = "acescc";
static var KHR_DF_TRANSFER_ACESCCT = "acescct";
static var KHR_DF_TRANSFER_ADOBERGB = "adobergb";
static var KHR_DF_TRANSFER_BT1886 = "bt1886";
static var KHR_DF_TRANSFER_DCIP3 = "dciP3";
static var KHR_DF_TRANSFER_HLG_EOTF = "hlgEotf";
static var KHR_DF_TRANSFER_HLG_OETF = "hlgOetf";
static var KHR_DF_TRANSFER_ITU = "itu";
static var KHR_DF_TRANSFER_LINEAR = "linear";
static var KHR_DF_TRANSFER_NTSC = "ntsc";
static var KHR_DF_TRANSFER_PAL625_EOTF = "pal625Eotf";
static var KHR_DF_TRANSFER_PAL_OETF = "palOetf";
static var KHR_DF_TRANSFER_PQ_EOTF = "pqEotf";
static var KHR_DF_TRANSFER_PQ_OETF = "pqOetf";
static var KHR_DF_TRANSFER_SLOG = "slog";
static var KHR_DF_TRANSFER_SLOG2 = "slog2";
static var KHR_DF_TRANSFER_SRGB = "srgb";
static var KHR_DF_TRANSFER_ST240 = "st240";
static var KHR_DF_TRANSFER_UNSPECIFIED = "unspecified";
static var KHR_DF_VENDORID_KHRONOS = "KHRONOS";
static var KHR_DF_VERSION = 2;
static var KHR_SUPERCOMPRESSION_BASISLZ = "basisLZ";
static var KHR_SUPERCOMPRESSION_NONE = "none";
static var KHR_SUPERCOMPRESSION_ZLIB = "zlib";
static var KHR_SUPERCOMPRESSION_ZSTD = "zstd";

static function read(t:ArrayBuffer):KTX2Container {
    return Pi(t);
}

static function write(t:KTX2Container):ArrayBuffer {
    return Mi(t);
}