import js.Browser;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;

class ImageUtils {
    
    private static var _canvas: js.html.HTMLCanvasElement;
    
    public static function getDataURL(image: js.html.HTMLImageElement): String {
        if (js.RegExp.create("^data:", "i").match(image.src)) {
            return image.src;
        }
        
        if (!Browser.window.hasOwnProperty("HTMLCanvasElement")) {
            return image.src;
        }
        
        var canvas: js.html.HTMLCanvasElement;
        
        if (Std.is(image, js.html.HTMLCanvasElement)) {
            canvas = cast image;
        } else {
            if (_canvas == null) {
                _canvas = Browser.document.createElementNS("canvas");
            }
            
            _canvas.width = image.width;
            _canvas.height = image.height;
            
            var context: CanvasRenderingContext2D = _canvas.getContext("2d");
            
            if (Std.is(image, js.html.ImageData)) {
                context.putImageData(cast image, 0, 0);
            } else {
                context.drawImage(image, 0, 0, image.width, image.height);
            }
            
            canvas = _canvas;
        }
        
        if (canvas.width > 2048 || canvas.height > 2048) {
            Browser.console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", image);
            return canvas.toDataURL("image/jpeg", 0.6);
        } else {
            return canvas.toDataURL("image/png");
        }
    }
    
    public static function sRGBToLinear(image: Dynamic): Dynamic {
        if ((Std.is(image, js.html.HTMLImageElement) && Browser.window.hasOwnProperty("HTMLImageElement")) || 
            (Std.is(image, js.html.HTMLCanvasElement) && Browser.window.hasOwnProperty("HTMLCanvasElement")) || 
            (Std.is(image, js.html.ImageBitmap) && Browser.window.hasOwnProperty("ImageBitmap"))) {
            var canvas: js.html.HTMLCanvasElement = Browser.document.createElementNS("canvas");
            canvas.width = image.width;
            canvas.height = image.height;
            
            var context: CanvasRenderingContext2D = canvas.getContext("2d");
            context.drawImage(image, 0, 0, image.width, image.height);
            
            var imageData: ImageData = context.getImageData(0, 0, image.width, image.height);
            var data: js.html.Uint8Array = imageData.data;
            
            for (i in 0...data.length) {
                data[i] = Math.floor(sRGBToLinear(data[i] / 255) * 255);
            }
            
            context.putImageData(imageData, 0, 0);
            return canvas;
        } else if (Reflect.hasField(image, "data")) {
            var data: js.html.Uint8Array = Reflect.field(image, "data");
            
            for (i in 0...data.length) {
                if (Std.is(data, js.html.Uint8Array) || Std.is(data, js.html.Uint8ClampedArray)) {
                    data[i] = Math.floor(sRGBToLinear(data[i] / 255) * 255);
                } else {
                    // assuming float
                    data[i] = sRGBToLinear(data[i]);
                }
            }
            
            return {
                data: data,
                width: Reflect.field(image, "width"),
                height: Reflect.field(image, "height")
            };
        } else {
            Browser.console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
            return image;
        }
    }
}