import js.html.Element;
import js.html.Image;
import js.html.ImageData;
import js.html.CanvasRenderingContext2D;
import js.html.HTMLCanvasElement;
import js.html.ImageBitmap;
import three.math.ColorManagement;

class ImageUtils {
    static var _canvas:HTMLCanvasElement;

    static function getDataURL(image:Dynamic):String {
        if (Type.typeof(image) == Type.typeof(HTMLCanvasElement)) {
            return image.toDataURL();
        }
        if (Type.typeof(HTMLCanvasElement) == "undefined") {
            return image.src;
        }
        var canvas:HTMLCanvasElement;
        if (image is HTMLCanvasElement) {
            canvas = image;
        } else {
            if (_canvas == null) _canvas = Element.canvas();
            _canvas.width = image.width;
            _canvas.height = image.height;
            var context:CanvasRenderingContext2D = _canvas.getContext("2d");
            if (image is ImageData) {
                context.putImageData(image, 0, 0);
            } else {
                context.drawImage(image, 0, 0, image.width, image.height);
            }
            canvas = _canvas;
        }
        if (canvas.width > 2048 || canvas.height > 2048) {
            trace("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", image);
            return canvas.toDataURL("image/jpeg", 0.6);
        } else {
            return canvas.toDataURL("image/png");
        }
    }

    static function sRGBToLinear(image:Dynamic):Dynamic {
        if ((Type.typeof(HTMLImageElement) != "undefined" && image is HTMLImageElement) ||
            (Type.typeof(HTMLCanvasElement) != "undefined" && image is HTMLCanvasElement) ||
            (Type.typeof(ImageBitmap) != "undefined" && image is ImageBitmap)) {
            var canvas:HTMLCanvasElement = Element.canvas();
            canvas.width = image.width;
            canvas.height = image.height;
            var context:CanvasRenderingContext2D = canvas.getContext("2d");
            context.drawImage(image, 0, 0, image.width, image.height);
            var imageData:ImageData = context.getImageData(0, 0, image.width, image.height);
            var data:Uint8ClampedArray = imageData.data;
            for (i in 0...data.length) {
                data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
            }
            context.putImageData(imageData, 0, 0);
            return canvas;
        } else if (image.data != null) {
            var data:Dynamic = Std.int(image.data.slice(0));
            for (i in 0...data.length) {
                if (data is Uint8Array || data is Uint8ClampedArray) {
                    data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
                } else {
                    data[i] = ColorManagement.SRGBToLinear(data[i]);
                }
            }
            return {
                data: data,
                width: image.width,
                height: image.height
            };
        } else {
            trace("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
            return image;
        }
    }
}