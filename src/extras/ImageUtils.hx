package three.extras;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.html.ImageBitmap;
import js.Browser;

class ImageUtils {
  static var _canvas:CanvasElement;

  static function getDataURL(image:Dynamic):String {
    if (~~/^data:/i.match(image.src)) {
      return image.src;
    }

    if (typeof HTMLCanvasElement == 'undefined') {
      return image.src;
    }

    var canvas:CanvasElement;

    if (Std.isOfType(image, CanvasElement)) {
      canvas = image;
    } else {
      if (_canvas == null) _canvas = Browser.document.createElementNS('http://www.w3.org/1999/xhtml', 'canvas');
      _canvas.width = image.width;
      _canvas.height = image.height;

      var context:CanvasRenderingContext2D = _canvas.getContext('2d');

      if (Std.isOfType(image, ImageData)) {
        context.putImageData(image, 0, 0);
      } else {
        context.drawImage(image, 0, 0, image.width, image.height);
      }

      canvas = _canvas;
    }

    if (canvas.width > 2048 || canvas.height > 2048) {
      Browser.console.warn('THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons', image);
      return canvas.toDataURL('image/jpeg', 0.6);
    } else {
      return canvas.toDataURL('image/png');
    }
  }

  static function sRGBToLinear(image:Dynamic):Dynamic {
    if ((typeof HTMLImageElement != 'undefined' && Std.isOfType(image, HTMLImageElement)) ||
        (typeof HTMLCanvasElement != 'undefined' && Std.isOfType(image, HTMLCanvasElement)) ||
        (typeof ImageBitmap != 'undefined' && Std.isOfType(image, ImageBitmap))) {
      var canvas:CanvasElement = Browser.document.createElementNS('http://www.w3.org/1999/xhtml', 'canvas');
      canvas.width = image.width;
      canvas.height = image.height;

      var context:CanvasRenderingContext2D = canvas.getContext('2d');
      context.drawImage(image, 0, 0, image.width, image.height);

      var imageData:ImageData = context.getImageData(0, 0, image.width, image.height);
      var data:Array<Int> = imageData.data;

      for (i in 0...data.length) {
        data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
      }

      context.putImageData(imageData, 0, 0);

      return canvas;
    } else if (image.data != null) {
      var data:Array<Int> = image.data.copy();
      for (i in 0...data.length) {
        if (Std.isOfType(image.data, Uint8Array) || Std.isOfType(image.data, Uint8ClampedArray)) {
          data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
        } else {
          // assuming float
          data[i] = SRGBToLinear(data[i]);
        }
      }

      return {
        data: data,
        width: image.width,
        height: image.height
      };
    } else {
      Browser.console.warn('THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.');
      return image;
    }
  }
}