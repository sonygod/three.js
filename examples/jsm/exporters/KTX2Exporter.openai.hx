package three.js.examples.jsm.exporters;

import three.js.DataTexture;
import three.js.Data3DTexture;
import three.js.WebGLRenderer;
import three.js.WebGLRenderTarget;
import three(js_FloatType;
import three.HalfFloatType;
import three.UnsignedByteType;
import three.RGBAFormat;
import three.RGFormat;
import three.RGIntegerFormat;
import three.RedFormat;
import three.RedIntegerFormat;
import three.NoColorSpace;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;
import three.REVISION;

// Importing ktx-parse module
import ktx_parse.KTX2Container;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_ALPHA;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_BLUE;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_GREEN;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_RED;
import ktx_parse.KHR_DF_MODEL_RGBSDA;
import ktx_parse.KHR_DF_PRIMARIES_BT709;
import ktx_parse.KHR_DF_PRIMARIES_UNSPECIFIED;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_FLOAT;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_LINEAR;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_SIGNED;
import ktx_parse.KHR_DF_TRANSFER_LINEAR;
import ktx_parse.KHR_DF_TRANSFER_SRGB;
import ktx_parse.VK_FORMAT_R16_SFLOAT;
import ktx_parse.VK_FORMAT_R16G16_SFLOAT;
import ktx_parse.VK_FORMAT_R16G16B16A16_SFLOAT;
import ktx_parse.VK_FORMAT_R32_SFLOAT;
import ktx_parse.VK_FORMAT_R32G32_SFLOAT;
import ktx_parse.VK_FORMAT_R32G32B32A32_SFLOAT;
import ktx_parse.VK_FORMAT_R8_SRGB;
import ktx_parse.VK_FORMAT_R8_UNORM;
import ktx_parse.VK_FORMAT_R8G8_SRGB;
import ktx_parse.VK_FORMAT_R8G8_UNORM;
import ktx_parse.VK_FORMAT_R8G8B8A8_SRGB;
import ktx_parse.VK_FORMAT_R8G8B8A8_UNORM;

class KTX2Exporter {
    static var VK_FORMAT_MAP = [
        RGBAFormat => [
            FloatType => [
                NoColorSpace => VK_FORMAT_R32G32B32A32_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R32G32B32A32_SFLOAT,
            ],
            HalfFloatType => [
                NoColorSpace => VK_FORMAT_R16G16B16A16_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R16G16B16A16_SFLOAT,
            ],
            UnsignedByteType => [
                NoColorSpace => VK_FORMAT_R8G8B8A8_UNORM,
                LinearSRGBColorSpace => VK_FORMAT_R8G8B8A8_UNORM,
                SRGBColorSpace => VK_FORMAT_R8G8B8A8_SRGB,
            ],
        ],
        RGFormat => [
            FloatType => [
                NoColorSpace => VK_FORMAT_R32G32_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R32G32_SFLOAT,
            ],
            HalfFloatType => [
                NoColorSpace => VK_FORMAT_R16G16_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R16G16_SFLOAT,
            ],
            UnsignedByteType => [
                NoColorSpace => VK_FORMAT_R8G8_UNORM,
                LinearSRGBColorSpace => VK_FORMAT_R8G8_UNORM,
                SRGBColorSpace => VK_FORMAT_R8G8_SRGB,
            ],
        ],
        RedFormat => [
            FloatType => [
                NoColorSpace => VK_FORMAT_R32_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R32_SFLOAT,
            ],
            HalfFloatType => [
                NoColorSpace => VK_FORMAT_R16_SFLOAT,
                LinearSRGBColorSpace => VK_FORMAT_R16_SFLOAT,
            ],
            UnsignedByteType => [
                NoColorSpace => VK_FORMAT_R8_UNORM,
                LinearSRGBColorSpace => VK_FORMAT_R8_UNORM,
                SRGBColorSpace => VK_FORMAT_R8_SRGB,
            ],
        ],
    ];

    static var KHR_DF_CHANNEL_MAP = [
        0 => KHR_DF_CHANNEL_RGBSDA_RED,
        1 => KHR_DF_CHANNEL_RGBSDA_GREEN,
        2 => KHR_DF_CHANNEL_RGBSDA_BLUE,
        3 => KHR_DF_CHANNEL_RGBSDA_ALPHA,
    ];

    static var ERROR_INPUT = 'THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.';
    static var ERROR_FORMAT = 'THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.';
    static var ERROR_TYPE = 'THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.';
    static var ERROR_COLOR_SPACE = 'THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.';

    public static function parse(arg1:Dynamic, arg2:Dynamic) {
        var texture:DataTexture;

        if (arg1.isDataTexture || arg1.isData3DTexture) {
            texture = arg1;
        } else if (arg1.isWebGLRenderer && arg2.isWebGLRenderTarget) {
            texture = toDataTexture(arg1, arg2);
        } else {
            throw new Error(ERROR_INPUT);
        }

        if (VK_FORMAT_MAP[texture.format] == null) {
            throw new Error(ERROR_FORMAT);
        }

        if (VK_FORMAT_MAP[texture.format][texture.type] == null) {
            throw new Error(ERROR_TYPE);
        }

        if (VK_FORMAT_MAP[texture.format][texture.type][texture.colorSpace] == null) {
            throw new Error(ERROR_COLOR_SPACE);
        }

        var array:haxe.io.BytesData = texture.image.data;
        var channelCount:Int = getChannelCount(texture);
        var container:KTX2Container = new KTX2Container();

        container.vkFormat = VK_FORMAT_MAP[texture.format][texture.type][texture.colorSpace];
        container.typeSize = array.BYTES_PER_ELEMENT;
        container.pixelWidth = texture.image.width;
        container.pixelHeight = texture.image.height;

        if (texture.isData3DTexture) {
            container.pixelDepth = texture.image.depth;
        }

        var basicDesc:Dynamic = container.dataFormatDescriptor[0];

        basicDesc.colorModel = KHR_DF_MODEL_RGBSDA;
        basicDesc.colorPrimaries = texture.colorSpace == NoColorSpace ? KHR_DF_PRIMARIES_UNSPECIFIED : KHR_DF_PRIMARIES_BT709;
        basicDesc.transferFunction = texture.colorSpace == SRGBColorSpace ? KHR_DF_TRANSFER_SRGB : KHR_DF_TRANSFER_LINEAR;

        basicDesc.texelBlockDimension = [0, 0, 0, 0];

        basicDesc.bytesPlane = [container.typeSize * channelCount, 0, 0, 0, 0, 0, 0, 0];

        for (i in 0...channelCount) {
            var channelType:Int = KHR_DF_CHANNEL_MAP[i];

            if (texture.colorSpace == LinearSRGBColorSpace || texture.colorSpace == NoColorSpace) {
                channelType |= KHR_DF_SAMPLE_DATATYPE_LINEAR;
            }

            if (texture.type == FloatType || texture.type == HalfFloatType) {
                channelType |= KHR_DF_SAMPLE_DATATYPE_FLOAT;
                channelType |= KHR_DF_SAMPLE_DATATYPE_SIGNED;
            }

            basicDesc.samples.push({
                channelType: channelType,
                bitOffset: i * array.BYTES_PER_ELEMENT,
                bitLength: array.BYTES_PER_ELEMENT * 8 - 1,
                samplePosition: [0, 0, 0, 0],
                sampleLower: texture.type == UnsignedByteType ? 0 : -1,
                sampleUpper: texture.type == UnsignedByteType ? 255 : 1,
            });
        }

        container.levels = [
            {
                levelData: new haxe.io.Bytes(new BytesOutput(), array.length),
                uncompressedByteLength: array.length,
            }
        ];

        container.keyValue['KTXwriter'] = `three.js ${REVISION}`;

        return write(container, { keepWriter: true });
    }

    static function toDataTexture(renderer:WebGLRenderer, rtt:WebGLRenderTarget):DataTexture {
        var channelCount:Int = getChannelCount(rtt.texture);

        var view:haxe.io.BytesData;

        switch (rtt.texture.type) {
            case FloatType:
                view = new haxe.io.Bytes(new haxe.io.BytesOutput(), rtt.width * rtt.height * channelCount);
            case HalfFloatType:
                view = new haxe.io.Bytes(new haxe.io.BytesOutput(), rtt.width * rtt.height * channelCount);
            case UnsignedByteType:
                view = new haxe.io.Bytes(new haxe.io.BytesOutput(), rtt.width * rtt.height * channelCount);
            default:
                throw new Error(ERROR_TYPE);
        }

        renderer.readRenderTargetPixels(rtt, 0, 0, rtt.width, rtt.height, view);

        return new DataTexture(view, rtt.width, rtt.height, rtt.texture.format, rtt.texture.type);
    }

    static function getChannelCount(texture:DataTexture):Int {
        switch (texture.format) {
            case RGBAFormat:
                return 4;
            case RGFormat, RGIntegerFormat:
                return 2;
            case RedFormat, RedIntegerFormat:
                return 1;
            default:
                throw new Error(ERROR_FORMAT);
        }
    }
}