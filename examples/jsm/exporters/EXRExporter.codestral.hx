import js.Browser;
import js.Float;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Uint16Array;
import js.html.Uint8Array;
import js.html.WebGLRenderer;
import js.html.WebGLRenderTarget;
import js.html.DataTexture;
import js.html.FloatType;
import js.html.HalfFloatType;
import js.html.RGBAFormat;
import js.html.DataUtils;
import fflate.Zlib;

class EXRExporter {
    public static function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Uint8Array {
        if (arg1 == null || (!Std.is(arg1, WebGLRenderer) && !Std.is(arg1, DataTexture))) {
            throw "EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.";
        } else if (Std.is(arg1, WebGLRenderer)) {
            var renderer:WebGLRenderer = arg1;
            var renderTarget:WebGLRenderTarget = arg2;
            var options:Dynamic = arg3;

            supportedRTT(renderTarget);

            var info = buildInfoRTT(renderTarget, options);
            var dataBuffer = getPixelData(renderer, renderTarget, info);
            var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
            var chunks = compressData(rawContentBuffer, info);

            return fillData(chunks, info);
        } else if (Std.is(arg1, DataTexture)) {
            var texture:DataTexture = arg1;
            var options:Dynamic = arg2;

            supportedDT(texture);

            var info = buildInfoDT(texture, options);
            var dataBuffer = texture.image.data;
            var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
            var chunks = compressData(rawContentBuffer, info);

            return fillData(chunks, info);
        } else {
            throw "EXRExporter.parse: Unsupported parameter.";
        }
    }
}

function supportedRTT(renderTarget:WebGLRenderTarget) {
    if (renderTarget == null || !Std.is(renderTarget, WebGLRenderTarget)) {
        throw "EXRExporter.parse: Unsupported second parameter, expected instance of WebGLRenderTarget.";
    }

    if (Std.is(renderTarget, WebGLCubeRenderTarget) || Std.is(renderTarget, WebGL3DRenderTarget) || Std.is(renderTarget, WebGLArrayRenderTarget)) {
        throw "EXRExporter.parse: Unsupported render target type, expected instance of WebGLRenderTarget.";
    }

    if (renderTarget.texture.type != FloatType && renderTarget.texture.type != HalfFloatType) {
        throw "EXRExporter.parse: Unsupported WebGLRenderTarget texture type.";
    }

    if (renderTarget.texture.format != RGBAFormat) {
        throw "EXRExporter.parse: Unsupported WebGLRenderTarget texture format, expected RGBAFormat.";
    }
}

function supportedDT(texture:DataTexture) {
    if (texture.type != FloatType && texture.type != HalfFloatType) {
        throw "EXRExporter.parse: Unsupported DataTexture texture type.";
    }

    if (texture.format != RGBAFormat) {
        throw "EXRExporter.parse: Unsupported DataTexture texture format, expected RGBAFormat.";
    }

    if (texture.image.data == null) {
        throw "EXRExporter.parse: Invalid DataTexture image data.";
    }

    if (texture.type == FloatType && texture.image.data.constructor != Float32Array) {
        throw "EXRExporter.parse: DataTexture image data doesn't match type, expected 'Float32Array'.";
    }

    if (texture.type == HalfFloatType && texture.image.data.constructor != Uint16Array) {
        throw "EXRExporter.parse: DataTexture image data doesn't match type, expected 'Uint16Array'.";
    }
}

// Other functions would need to be converted similarly.
// This is a rough conversion and may not work without modifications.