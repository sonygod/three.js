package ktx;

class KTX2Container {
    public var vkFormat:UInt;
    public var typeSize:UInt;
    public var pixelWidth:UInt;
    public var pixelHeight:UInt;
    public var pixelDepth:UInt;
    public var layerCount:UInt;
    public var faceCount:UInt;
    public var supercompressionScheme:UInt;
    public var levels:Array<KTXLevel>;
    public var dataFormatDescriptor:KTXDataFormatDescriptor;
    public var keyValue:Map<String, String>;
    public var globalData:KTXGlobalData;

    public function new() {}
}

class KTXLevel {
    public var levelData:Bytes;
    public var uncompressedByteLength:UInt;

    public function new() {}
}

class KTXDataFormatDescriptor {
    public var vendorId:UInt;
    public var descriptorType:UInt;
    public var versionNumber:UInt;
    public var descriptorBlockSize:UInt;
    public var colorModel:UInt;
    public var colorPrimaries:UInt;
    public var transferFunction:UInt;
    public var flags:UInt;
    public var texelBlockDimension:Array<UInt>;
    public var bytesPlane:Array<UInt>;
    public var samples:Array<KTXSample>;

    public function new() {}
}

class KTXSample {
    public var bitOffset:UInt;
    public var bitLength:UInt;
    public var channelType:UInt;
    public var samplePosition:Array<UInt>;
    public var sampleLower:Float;
    public var sampleUpper:Float;

    public function new() {}
}

class KTXGlobalData {
    public var endpointCount:UInt;
    public var selectorCount:UInt;
    public var endpointsData:Bytes;
    public var selectorsData:Bytes;
    public var tablesData:Bytes;
    public var extendedData:Bytes;

    public function new() {}
}