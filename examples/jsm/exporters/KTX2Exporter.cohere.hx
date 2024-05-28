import js.three.DataTexture;
import js.three.FloatType;
import js.three.HalfFloatType;
import js.three.LinearSRGBColorSpace;
import js.three.NoColorSpace;
import js.three.RedFormat;
import js.three.RGFormat;
import js.three.RGBAFormat;
import js.three.SRGBColorSpace;
import js.three.UnsignedByteType;

import js.three.ktx2.KHR_DF_CHANNEL_RGBSDA_ALPHA;
import js.three.ktx2.KHR_DF_CHANNEL_RGBSDA_BLUE;
import js.three.ktx2.KHR_DF_CHANNEL_RGBSDA_GREEN;
import js.three.ktx2.KHR_DF_CHANNEL_RGBSDA_RED;
import js.three.ktx2.KHR_DF_MODEL_RGBSDA;
import js.three.ktx2.KHR_DF_PRIMARIES_BT709;
import js.three.ktx2.KHR_DF_PRIMARIES_UNSPECIFIED;
import js.three.ktx2.KHR_DF_SAMPLE_DATATYPE_FLOAT;
import js.three.ktx2.KHR_DF_SAMPLE_DATATYPE_LINEAR;
import js.three.ktx2.KHR_DF_SAMPLE_DATATYPE_SIGNED;
import js.three.ktx2.KHR_DF_TRANSFER_LINEAR;
import js.three.ktx2.KHR_DF_TRANSFER_SRGB;
import js.three.ktx2.KTX2Container;
import js.three.ktx2.VK_FORMAT_R16_SFLOAT;
import js.three.ktx2.VK_FORMAT_R16G16_SFLOAT;
import js.three.ktx2.VK_FORMAT_R16G16B16A16_SFLOAT;
import js.three.ktx2.VK_FORMAT_R32_SFLOAT;
import js.three.ktx2.VK_FORMAT_R32G32_SFLOAT;
import js.three.ktx2.VK_FORMAT_R32G32B32A32_SFLOAT;
import js.three.ktx2.VK_FORMAT_R8_SRGB;
import js.three.ktx2.VK_FORMAT_R8_UNORM;
import js.three.ktx2.VK_FORMAT_R8G8_SRGB;
import js.three.ktx2.VK_FORMAT_R8G8_UNORM;
import js.three.ktx2.VK_FORMAT_R8G8B8A8_SRGB;
import js.three.ktx2.VK_FORMAT_R8G8B8A8_UNORM;
import js.three.ktx2.write;

class KTX2Exporter {
    public function parse(arg1:Dynamic, arg2:Dynamic):String {
        var texture:DataTexture;

        if (Reflect.hasField(arg1, 'isDataTexture') && Reflect.field(arg1, 'isDataTexture') || Reflect.hasField(arg1, 'isData3DTexture') && Reflect.field(arg1, 'isData3DTexture')) {
            texture = arg1;
        } else if (Reflect.hasField(arg1, 'isWebGLRenderer') && Reflect.field(arg1, 'isWebGLRenderer') && Reflect.hasField(arg2, 'isWebGLRenderTarget') && Reflect.field(arg2, 'isWebGLRenderTarget')) {
            texture = toDataTexture(arg1, arg2);
        } else {
            throw new haxe.Exception(ERROR_INPUT);
        }

        var format = VK_FORMAT_MAP[texture.format];
        if (format == null) {
            throw new haxe.Exception(ERROR_FORMAT);
        }

        var type = format[texture.type];
        if (type == null) {
            throw new haxe.Exception(ERROR_TYPE);
        }

        var colorSpace = type[texture.colorSpace];
        if (colorSpace == null) {
            throw new haxe.Exception(ERROR_COLOR_SPACE);
        }

        var array = texture.image.data;
        var channelCount = getChannelCount(texture);
        var container = new KTX2Container();

        container.vkFormat = colorSpace;
        container.typeSize = array.BYTES_PER_ELEMENT;
        container.pixelWidth = texture.image.width;
        container.pixelHeight = texture.image.height;

        if (Reflect.hasField(texture, 'isData3DTexture') && Reflect.field(texture, 'isData3DTexture')) {
            container.pixelDepth = texture.image.depth;
        }

        var basicDesc = container.dataFormatDescriptor[0];

        basicDesc.colorModel = KHR_DF_MODEL_RGBSDA;
        basicDesc.colorPrimaries = texture.colorSpace == NoColorSpace ? KHR_DF_PRIMARIES_UNSPECIFIED : KHR_DF_PRIMARIES_BT709;
        basicDesc.transferFunction = texture.colorSpace == SRGBColorSpace ? KHR_DF_TRANSFER_SRGB : KHR_DF_TRANSFER_LINEAR;

        basicDesc.texelBlockDimension = [0, 0, 0, 0];

        basicDesc.bytesPlane = [
            container.typeSize * channelCount,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
        ];

        var i = 0;
        while (i < channelCount) {
            var channelType = KHR_DF_CHANNEL_MAP[i];

            if (texture.colorSpace == LinearSRGBColorSpace || texture.colorSpace == NoColorSpace) {
                channelType = channelType | KHR_DF_SAMPLE_DATATYPE_LINEAR;
            }

            if (texture.type == FloatType || texture.type == HalfFloatType) {
                channelType = channelType | KHR_DF_SAMPLE_DATATYPE_FLOAT;
                channelType = channelType | KHR_DF_SAMPLE_DATATYPE_SIGNED;
            }

            basicDesc.samples.push({
                channelType: channelType,
                bitOffset: i * array.BYTES_PER_ELEMENT,
                bitLength: array.BYTES_PER_ELEMENT * 8 - 1,
                samplePosition: [0, 0, 0, 0],
                sampleLower: if (texture.type == UnsignedByteType) 0 else -1,
                sampleUpper: if (texture.type == UnsignedByteType) 255 else 1,
            });

            i += 1;
        }

        container.levels = [{
            levelData: new Uint8Array(array.buffer, array.byteOffset, array.byteLength),
            uncompressedByteLength: array.byteLength,
        }];

        container.keyValue['KTXwriter'] = 'three.js ${REVISION}';

        return write(container, { keepWriter: true });
    }

    static inline function toDataTexture(renderer:Dynamic, rtt:Dynamic):DataTexture {
        var channelCount = getChannelCount(rtt.texture);

        var view:Dynamic;

        if (rtt.texture.type == FloatType) {
            view = new Float32Array(rtt.width * rtt.height * channelCount);
        } else if (rtt.texture.type == HalfFloatType) {
            view = new Uint16Array(rtt.width * rtt.height * channelCount);
        } else if (rtt.texture.type == UnsignedByteType) {
            view = new Uint8Array(rtt.width * rtt.height * channelCount);
        } else {
            throw new haxe.Exception(ERROR_TYPE);
        }

        renderer.readRenderTargetPixels(rtt, 0, 0, rtt.width, rtt.height, view);

        return new DataTexture(view, rtt.width, rtt.height, rtt.texture.format, rtt.texture.type);
    }

    static inline function getChannelCount(texture:Dynamic):Int {
        switch (texture.format) {
            case RGBAFormat:
                return 4;

            case RGFormat:
            case js.three.RGIntegerFormat:
                return 2;

            case RedFormat:
            case js.three.RedIntegerFormat:
                return 1;

            default:
                throw new haxe.Exception(ERROR_FORMAT);
        }
    }
}

var VK_FORMAT_MAP = {
    $RGBAFormat: {
        $FloatType: {
            $NoColorSpace: VK_FORMAT_R32G32B32A32_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R32G32B32A32_SFLOAT,
        },
        $HalfFloatType: {
            $NoColorSpace: VK_FORMAT_R16G16B16A16_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R16G16B16A16_SFLOAT,
        },
        $UnsignedByteType: {
            $NoColorSpace: VK_FORMAT_R8G8B8A8_UNORM,
            $LinearSRGBColorSpace: VK_FORMAT_R8G8B8A8_UNORM,
            $SRGBColorSpace: VK_FORMAT_R8G8B8A8_SRGB,
        },
    },

    $RGFormat: {
        $FloatType: {
            $NoColorSpace: VK_FORMAT_R32G32_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R32G32_SFLOAT,
        },
        $HalfFloatType: {
            $NoColorSpace: VK_FORMAT_R16G16_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R16G16_SFLOAT,
        },
        $UnsignedByteType: {
            $NoColorSpace: VK_FORMAT_R8G8_UNORM,
            $LinearSRGBColorSpace: VK_FORMAT_R8G8_UNORM,
            $SRGBColorSpace: VK_FORMAT_R8G8_SRGB,
        },
    },

    $RedFormat: {
        $FloatType: {
            $NoColorSpace: VK_FORMAT_R32_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R32_SFLOAT,
        },
        $HalfFloatType: {
            $NoColorSpace: VK_FORMAT_R16_SFLOAT,
            $LinearSRGBColorSpace: VK_FORMAT_R16_SFLOAT,
        },
        $UnsignedByteType: {
            $NoColorSpace: VK_FORMAT_R8_UNORM,
            $LinearSRGBColorSpace: VK_FORMAT_R8_UNORM,
            $SRGBColorSpace: VK_FORMAT_R8_SRGB,
        },
    },
};

var KHR_DF_CHANNEL_MAP = {
    0: KHR_DF_CHANNEL_RGBSDA_RED,
    1: KHR_DF_CHANNEL_RGBSDA_GREEN,
    2: KHR_DF_CHANNEL_RGBSDA_BLUE,
    3: KHR_DF_CHANNEL_RGBSDA_ALPHA,
};

var ERROR_INPUT = 'THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.';
var ERROR_FORMAT = 'THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.';
var ERROR_TYPE = 'THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.';
var ERROR_COLOR_SPACE = 'THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.';