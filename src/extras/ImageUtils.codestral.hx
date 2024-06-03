import js.html.CanvasElement;
import js.html.ImageData;
import js.html.HTMLImageElement;
import js.html.HTMLCanvasElement;
import js.html.ImageBitmap;
import js.html.CanvasRenderingContext2D;

class ImageUtils {

    private static var _canvas:CanvasElement;

    public static function getDataURL(image:Dynamic):String {
        if (Std.is(image.src, String) && image.src.match(new EReg("^data:","i")) != null) {
            return image.src;
        }

        // Haxe does not have a direct equivalent to HTMLCanvasElement
        // This part of the code needs to be implemented or replaced with a suitable alternative

        // var canvas:CanvasElement;

        // if (Std.is(image, HTMLCanvasElement)) {
        //     canvas = image;
        // } else {
        //     if (_canvas == null) _canvas = js.Browser.document.createElement("canvas");

        //     _canvas.width = image.width;
        //     _canvas.height = image.height;

        //     var context:CanvasRenderingContext2D = _canvas.getContext("2d");

        //     if (Std.is(image, ImageData)) {
        //         context.putImageData(image, 0, 0);
        //     } else {
        //         context.drawImage(image, 0, 0, image.width, image.height);
        //     }

        //     canvas = _canvas;
        // }

        // if (canvas.width > 2048 || canvas.height > 2048) {
        //     js.Browser.console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", image);
        //     return canvas.toDataURL("image/jpeg", 0.6);
        // } else {
        //     return canvas.toDataURL("image/png");
        // }

        return image.src;
    }

    public static function sRGBToLinear(image:Dynamic):Dynamic {
        if ((js.html.Lib.isDefined(HTMLImageElement) && Std.is(image, HTMLImageElement)) ||
            (js.html.Lib.isDefined(HTMLCanvasElement) && Std.is(image, HTMLCanvasElement)) ||
            (js.html.Lib.isDefined(ImageBitmap) && Std.is(image, ImageBitmap))) {

            // Haxe does not have a direct equivalent to HTMLCanvasElement and ImageData
            // This part of the code needs to be implemented or replaced with a suitable alternative

            // var canvas:CanvasElement = js.Browser.document.createElement("canvas");

            // canvas.width = image.width;
            // canvas.height = image.height;

            // var context:CanvasRenderingContext2D = canvas.getContext("2d");
            // context.drawImage(image, 0, 0, image.width, image.height);

            // var imageData:ImageData = context.getImageData(0, 0, image.width, image.height);
            // var data:Uint8ClampedArray = imageData.data;

            // for (var i:Int = 0; i < data.length; i++) {
            //     data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
            // }

            // context.putImageData(imageData, 0, 0);

            // return canvas;

        } else if (Std.hasField(image, "data")) {

            var data:Array<Dynamic> = image.data.slice(0);

            for (var i:Int = 0; i < data.length; i++) {
                if (Std.is(data[i], Int)) {
                    data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
                } else {
                    // assuming float
                    data[i] = ColorManagement.SRGBToLinear(data[i]);
                }
            }

            return {
                data: data,
                width: image.width,
                height: image.height
            };

        } else {

            js.Browser.console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
            return image;

        }
    }
}