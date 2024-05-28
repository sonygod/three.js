package three.js.src.extras;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image;
import js.html.ImageData;
import js.html.ImageBitmap;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
import three.js.src.utils.createElementNS;
import three.js.src.math.ColorManagement.SRGBToLinear;

class ImageUtils {
  static var _canvas:CanvasElement;

  static function getDataURL(image:Dynamic):String {
    if (~image.src.indexOf("data:")) {
      return image.src;
    }

    if (Type.getClass(CanvasElement) == null) {
      return image.src;
    }

    var canvas:CanvasElement;

    if (Std.is(image, CanvasElement)) {
      canvas = image;
    } else {
      if (_canvas == null) {
        _canvas = createElementNS("canvas");
      }

      _canvas.width = image.width;
      _canvas.height = image.height;

      var context = _canvas.getContext2d();
      if (Std.is(image, ImageData)) {
        context.putImageData(image, 0, 0);
      } else {
        context.drawImage(image, 0, 0, image.width, image.height);
      }

      canvas = _canvas;
    }

    if (canvas.width > 2048 || canvas.height > 2048) {
      js.Lib.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", image);
      return canvas.toDataURL("image/jpeg", 0.6);
    } else {
      return canvas.toDataURL("image/png");
    }
  }

  static function sRGBToLinear(image:Dynamic):Dynamic {
    if ((Type.getClass(HTMLImageElement) != null && Std.is(image, HTMLImageElement)) ||
        (Type.getClass(HTMLCanvasElement) != null && Std.is(image, HTMLCanvasElement)) ||
        (Type.getClass(ImageBitmap) != null && Std.is(image, ImageBitmap))) {
      var canvas = createElementNS("canvas");
      canvas.width = image.width;
      canvas.height = image.height;

      var context = canvas.getContext2d();
      context.drawImage(image, 0, 0, image.width, image.height);

      var imageData = context.getImageData(0, 0, image.width, image.height);
      var data = imageData.data;

      for (i in 0...data.length) {
        data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
      }

      context.putImageData(imageData, 0, 0);

      return canvas;
    } else if (image.data != null) {
      var data = image.data.copy();

      for (i in 0...data.length) {
        if (Std.is(data, Uint8Array) || Std.is(data, Uint8ClampedArray)) {
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
      js.Lib.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
      return image;
    }
  }
}