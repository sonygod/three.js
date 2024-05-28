import js.html.ImageData;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.ImageBitmap;

class ImageUtils {
    static function getDataURL(image:ImageElement):String {
        if (image.src.indexOf("data:") == 0) {
            return image.src;
        }

        if (image is CanvasElement) {
            return image.toDataURL();
        }

        var canvas = CanvasElement.create();
        canvas.width = Std.int(image.width);
        canvas.height = Std.int(image.height);

        var context = canvas.getContext2d();
        if (image is ImageData) {
            context.putImageData(image, 0, 0);
        } else {
            context.drawImage(image, 0, 0, image.width, image.height);
        }

        if (canvas.width > 2048 || canvas.height > 2048) {
            trace("ImageUtils.getDataURL: Image converted to jpg for performance reasons");
            return canvas.toDataURL("image/jpeg", 0.6);
        } else {
            return canvas.toDataURL("image/png");
        }
    }

    static function sRGBToLinear(image:ImageElement):CanvasElement {
        if (image is ImageElement || image is CanvasElement || image is ImageBitmap) {
            var canvas = CanvasElement.create();
            canvas.width = Std.int(image.width);
            canvas.height = Std.int(image.height);

            var context = canvas.getContext2d();
            context.drawImage(image, 0, 0, image.width, image.height);

            var imageData = context.getImageData(0, 0, image.width, image.height);
            var data = imageData.data;

            for (i in 0...data.length) {
                data[i] = Std.int(SRGBToLinear(data[i] / 255) * 255);
            }

            context.putImageData(imageData, 0, 0);

            return canvas;
        } else if (image.data != null) {
            var data = image.data.slice(0);

            for (i in 0...data.length) {
                if (data is Array<Int> || data is Array<UInt>) {
                    data[i] = Std.int(SRGBToLinear(data[i] / 255) * 255);
                } else {
                    // assuming float
                    data[i] = SRGBToLinear(data[i]);
                }
            }

            return { data: data, width: image.width, height: image.height };
        } else {
            trace("ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
            return image;
        }
    }
}