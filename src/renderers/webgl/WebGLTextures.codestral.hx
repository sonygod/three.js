import js.html.WebGLRenderingContext;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.html.VideoFrame;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.HTMLVideoElement;
import js.html.OffscreenCanvas;
import js.html.ImageBitmap;

import ThreeConstants;
import ThreeUtils;
import ThreeColorManagement;
import ThreeVector2;

class WebGLTextures {
    var _gl:WebGLRenderingContext;
    var extensions:Map<String, dynamic>;
    var state:WebGLState;
    var properties:Map<Object, dynamic>;
    var capabilities:WebGLCapabilities;
    var utils:ThreeUtils;
    var info:WebGLInfo;

    var multisampledRTTExt:dynamic;
    var supportsInvalidateFramebuffer:Bool;

    var _imageDimensions:ThreeVector2;
    var _videoTextures:Map<Texture, Int>;
    var _canvas:HTMLCanvasElement;

    var _sources:Map<Source, Map<String, dynamic>>;

    var useOffscreenCanvas:Bool;

    public function new(gl:WebGLRenderingContext, extensions:Map<String, dynamic>, state:WebGLState, properties:Map<Object, dynamic>, capabilities:WebGLCapabilities, utils:ThreeUtils, info:WebGLInfo) {
        this._gl = gl;
        this.extensions = extensions;
        this.state = state;
        this.properties = properties;
        this.capabilities = capabilities;
        this.utils = utils;
        this.info = info;

        multisampledRTTExt = extensions.has('WEBGL_multisampled_render_to_texture') ? extensions.get('WEBGL_multisampled_render_to_texture') : null;
        supportsInvalidateFramebuffer = js.Browser.navigator != null && js.Browser.navigator.userAgent.match(/OculusBrowser/g) != null;

        _imageDimensions = new ThreeVector2();
        _videoTextures = new haxe.ds.WeakMap();
        _sources = new haxe.ds.WeakMap();

        useOffscreenCanvas = false;
        try {
            useOffscreenCanvas = js.html.OffscreenCanvas != null && (new OffscreenCanvas(1, 1)).getContext('2d') != null;
        } catch (_:Dynamic) {}
    }

    public function createCanvas(width:Int, height:Int):HTMLCanvasElement {
        if (useOffscreenCanvas) {
            return new OffscreenCanvas(width, height);
        } else {
            return ThreeUtils.createElementNS('canvas');
        }
    }

    public function resizeImage(image:dynamic, needsNewCanvas:Bool, maxSize:Int):dynamic {
        var scale:Float = 1;
        var dimensions:ThreeVector2 = getDimensions(image);

        if (dimensions.width > maxSize || dimensions.height > maxSize) {
            scale = maxSize / Math.max(dimensions.width, dimensions.height);
        }

        if (scale < 1) {
            if (((js.html.HTMLImageElement != null && image is HTMLImageElement)) ||
                ((js.html.HTMLCanvasElement != null && image is HTMLCanvasElement)) ||
                ((js.html.ImageBitmap != null && image is ImageBitmap)) ||
                ((js.html.VideoFrame != null && image is VideoFrame))) {

                var width:Int = Math.floor(scale * dimensions.width);
                var height:Int = Math.floor(scale * dimensions.height);

                if (_canvas == null) _canvas = createCanvas(width, height);

                var canvas:HTMLCanvasElement = needsNewCanvas ? createCanvas(width, height) : _canvas;
                canvas.width = width;
                canvas.height = height;

                var context:CanvasRenderingContext2D = canvas.getContext('2d');
                context.drawImage(image, 0, 0, width, height);

                trace('THREE.WebGLRenderer: Texture has been resized from (' + dimensions.width + 'x' + dimensions.height + ') to (' + width + 'x' + height + ').');

                return canvas;
            } else {
                if ('data' in image) {
                    trace('THREE.WebGLRenderer: Image in DataTexture is too big (' + dimensions.width + 'x' + dimensions.height + ').');
                }
                return image;
            }
        }
        return image;
    }

    // Continue with the rest of the methods, converting JavaScript syntax to Haxe syntax as needed
}