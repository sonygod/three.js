import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.ImageData;
import js.html.ImageBitmap;
import js.html.Window;
import js.html.document;
import js.html.CanvasRenderingContext2D;

import three.math.ColorManagement;

class ImageUtils {

	static var _canvas:CanvasElement;

	public static function getDataURL( image:ImageElement ):String {

		if ( image.src.match( /^data:/i ) != null ) {

			return image.src;

		}

		if ( Window.typeof( HTMLCanvasElement ) == "undefined" ) {

			return image.src;

		}

		var canvas:CanvasElement;

		if ( js.Boot.instanceOf( image, CanvasElement ) ) {

			canvas = image;

		} else {

			if ( _canvas == null ) _canvas = document.createElement( "canvas" );

			_canvas.width = image.width;
			_canvas.height = image.height;

			var context:CanvasRenderingContext2D = _canvas.getContext( "2d" );

			if ( js.Boot.instanceOf( image, ImageData ) ) {

				context.putImageData( image, 0, 0 );

			} else {

				context.drawImage( image, 0, 0, image.width, image.height );

			}

			canvas = _canvas;

		}

		if ( canvas.width > 2048 || canvas.height > 2048 ) {

			js.Lib.warn( "THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", image );

			return canvas.toDataURL( "image/jpeg", 0.6 );

		} else {

			return canvas.toDataURL( "image/png" );

		}

	}

	public static function sRGBToLinear( image:Dynamic ):Dynamic {

		if ( ( Window.typeof( HTMLImageElement ) != "undefined" && js.Boot.instanceOf( image, HTMLImageElement ) ) ||
			( Window.typeof( HTMLCanvasElement ) != "undefined" && js.Boot.instanceOf( image, HTMLCanvasElement ) ) ||
			( Window.typeof( ImageBitmap ) != "undefined" && js.Boot.instanceOf( image, ImageBitmap ) ) ) {

			var canvas:CanvasElement = document.createElement( "canvas" );

			canvas.width = image.width;
			canvas.height = image.height;

			var context:CanvasRenderingContext2D = canvas.getContext( "2d" );
			context.drawImage( image, 0, 0, image.width, image.height );

			var imageData:ImageData = context.getImageData( 0, 0, image.width, image.height );
			var data:js.html.ImageDataData = imageData.data;

			for ( var i = 0; i < data.length; i ++ ) {

				data[ i ] = Math.round( ColorManagement.SRGBToLinear( data[ i ] / 255 ) * 255 );

			}

			context.putImageData( imageData, 0, 0 );

			return canvas;

		} else if ( js.Boot.hasField( image, "data" ) ) {

			var data:js.html.ImageDataData = image.data.slice( 0 );

			for ( var i = 0; i < data.length; i ++ ) {

				if ( js.Boot.instanceOf( data, js.html.Uint8Array ) || js.Boot.instanceOf( data, js.html.Uint8ClampedArray ) ) {

					data[ i ] = Math.round( ColorManagement.SRGBToLinear( data[ i ] / 255 ) * 255 );

				} else {

					// assuming float

					data[ i ] = ColorManagement.SRGBToLinear( data[ i ] );

				}

			}

			return {
				data: data,
				width: image.width,
				height: image.height
			};

		} else {

			js.Lib.warn( "THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied." );
			return image;

		}

	}

}