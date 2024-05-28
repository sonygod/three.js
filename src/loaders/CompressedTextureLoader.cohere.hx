package;

import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;

import js.Browser;

class CompressedTextureLoader extends Loader {

	public function new (manager:Dynamic) {
		super();
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var images = [];
		var texture = new CompressedTexture();
		var loader = new FileLoader(manager);
		loader.path = path;
		loader.responseType = 'arraybuffer';
		loader.requestHeader = requestHeader;
		loader.withCredentials = withCredentials;
		var loaded = 0;

		function loadTexture(i:Int):Void {
			loader.load(url[i], function(buffer:Dynamic) {
				var texDatas = scope.parse(buffer, true);
				images[i] = { width: texDatas.width, height: texDatas.height, format: texDatas.format, mipmaps: texDatas.mipmaps };
				loaded += 1;
				if (loaded == 6) {
					if (texDatas.mipmapCount == 1) texture.minFilter = LinearFilter;
					texture.image = images;
					texture.format = texDatas.format;
					texture.needsUpdate = true;
					if (onLoad != null) onLoad(texture);
				}
			}, onProgress, onError);
		}

		if (Type.enumIndex(Array, url) != -1) {
			var i:Int, il:Int = url.length;
			for (i = 0; i < il; ++i) {
				loadTexture(i);
			}
		} else {
			loader.load(url, function(buffer:Dynamic) {
				var texDatas = scope.parse(buffer, true);
				if (texDatas.isCubemap) {
					var faces = Std.int(texDatas.mipmaps.length / texDatas.mipmapCount);
					var f:Int;
					for (f = 0; f < faces; f++) {
						images[f] = { mipmaps: [] };
						var i:Int;
						for (i = 0; i < texDatas.mipmapCount; i++) {
							images[f].mipmaps.push(texDatas.mipmaps[f * texDatas.mipmapCount + i]);
							images[f].format = texDatas.format;
							images[f].width = texDatas.width;
							images[f].height = texDatas.height;
						}
					}
					texture.image = images;
				} else {
					texture.image.width = texDatas.width;
					texture.image.height = texDatas.height;
					texture.mipmaps = texDatas.mipmaps;
				}
				if (texDatas.mipmapCount == 1) {
					texture.minFilter = LinearFilter;
				}
				texture.format = texDatas.format;
				texture.needsUpdate = true;
				if (onLoad != null) onLoad(texture);
			}, onProgress, onError);
		}
		return texture;
	}

}

class FileLoader extends Loader {

	public function new (manager:Dynamic) {
		super();
	}

}

class CompressedTexture {

	public var image:Dynamic;
	public var format:Dynamic;
	public var needsUpdate:Bool;
	public var minFilter:Dynamic;

}

enum LinearFilter { }

class LoaderInfo {

	public var contentType:String;

}

class Loader {

	public var path:String;
	public var responseType:String;
	public var requestHeader:Dynamic;
	public var withCredentials:Bool;

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		Browser.window.alert('Abstract method');
	}

}

class BitmapData {

	public var width:Int;
	public var height:Int;

}

class ByteArray implements IDataInput {

	public function new () {
		Browser.window.alert('Abstract class');
	}

	public function readInt():Int {
		Browser.window.alert('Abstract method');
	}

	public function readFloat():Float {
		Browser.window.alert('Abstract method');
	}

	public function readDouble():Float {
		Browser.window.alert('Abstract method');
	}

	public function readMultiByte(length:Int, charSet:String):String {
		Browser.window.alert('Abstract method');
	}

	public function readObject():Dynamic {
		Browser.window.alert('Abstract method');
	}

	public function readBoolean():Bool {
		Browser.window.alert('Abstract method');
	}

	public function readByte():Int {
		Browser.window.alert('Abstract method');
	}

	public function readBytes(bytes:ByteArray, offset:Int = 0, length:Int = -1):Void {
		Browser.window.alert('Abstract method');
	}

	public function readShort():Int {
		Browser.window.alert('Abstract method');
	}

	public function readUnsignedInt():Int {
		Browser.window.alert('Abstract method');
	}

	public function readUnsignedByte():Int {
		Browser.window.alert('Abstract method');
	}

	public function readUnsignedShort():Int {
		Browser.window.alert('Abstract method');
	}

	public function readUTF():String {
		Browser.window.alert('Abstract method');
	}

	public function readUTFBytes(length:Int):String {
		Browser.window.alert('Abstract method');
	}

	public function readLong():Int {
		Browser.window.alert('Abstract method');
	}

	public function getBytesAvailable():Int {
		Browser.window.alert('Abstract method');
	}

	public function getPosition():Int {
		Browser.window.alert('Abstract method');
	}

	public function setPosition(pos:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function getLength():Int {
		Browser.window.alert('Abstract method');
	}

	public function clear():Void {
		Browser.window.alert('Abstract method');
	}

	public function writeBoolean(value:Bool):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeByte(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeBytes(value:ByteArray, offset:Int = 0, length:Int = -1):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeShort(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeUnsignedInt(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeInt(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeUnsignedByte(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeUnsignedShort(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeFloat(value:Float):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeDouble(value:Float):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeMultiByte(value:String, charSet:String):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeObject(value:Dynamic):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeUTF(value:String):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeUTFBytes(value:String):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeLong(value:Int):Void {
		Browser.window.alert('Abstract method');
	}

	public function writeBytes(value:String):Void {
		Browser.window.alert('Abstract method');
	}

	public function readBytes(length:Int):ByteArray {
		Browser.window.alert('Abstract method');
	}

	public function readObject():Dynamic {
		Browser.window.alert('Abstract method');
	}

}

class Event {

	public var type:String;

}