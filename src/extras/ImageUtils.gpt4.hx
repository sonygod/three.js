import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.html.HTMLImageElement;
import js.html.ImageBitmap;

class ImageUtils {

    static var _canvas:CanvasElement;

    public static function getDataURL(image:Dynamic):String {
        if (/^data:/i.match(image.src) != null) {
            return image.src;
        }

        if (Type.resolveClass("js.html.CanvasElement") == null) {
            return image.src;
        }

        var canvas:CanvasElement;

        if (Std.is(image, CanvasElement)) {
            canvas = cast image;
        } else {
            if (_canvas == null) _canvas = createElementNS('canvas');

            _canvas.width = image.width;
            _canvas.height = image.height;

            var context:CanvasRenderingContext2D = _canvas.getContext('2d');

            if (Std.is(image, ImageData)) {
                context.putImageData(cast image, 0, 0);
            } else {
                context.drawImage(image, 0, 0, image.width, image.height);
            }

            canvas = _canvas;
        }

        if (canvas.width > 2048 || canvas.height > 2048) {
            trace('THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons', image);
            return canvas.toDataURL('image/jpeg', 0.6);
        } else {
            return canvas.toDataURL('image/png');
        }
    }

    public static function sRGBToLinear(image:Dynamic):Dynamic {
        if (Type.resolveClass("js.html.HTMLImageElement") != null && Std.is(image, HTMLImageElement) ||
            Type.resolveClass("js.html.CanvasElement") != null && Std.is(image, CanvasElement) ||
            Type.resolveClass("js.html.ImageBitmap") != null && Std.is(image, ImageBitmap)) {

            var canvas:CanvasElement = createElementNS('canvas');
            canvas.width = image.width;
            canvas.height = image.height;

            var context:CanvasRenderingContext2D = canvas.getContext('2d');
            context.drawImage(image, 0, 0, image.width, image.height);

            var imageData:ImageData = context.getImageData(0, 0, image.width, image.height);
            var data:Array<UInt8> = imageData.data;

            for (i in 0...data.length) {
                data[i] = Math.round(SRGBToLinear(data[i] / 255) * 255);
            }

            context.putImageData(imageData, 0, 0);
            return canvas;

        } else if (Reflect.hasField(image, "data")) {
            var data:Array<Dynamic> = Reflect.field(image, "data").copy();

            for (i in 0...data.length) {
                if (Std.is(data, UInt8Array) || Std.is(data, UInt8ClampedArray)) {
                    data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
                } else {
                    data[i] = SRGBToLinear(data[i]);
                }
            }

            return {
                data: data,
                width: image.width,
                height: image.height
            };

        } else {
            trace('THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.');
            return image;
        }
    }

    private static function createElementNS(name:String):CanvasElement {
        return js.Browser.document.createElement(name);
    }

    private static function SRGBToLinear(value:Float):Float {
        return value < 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    }

}