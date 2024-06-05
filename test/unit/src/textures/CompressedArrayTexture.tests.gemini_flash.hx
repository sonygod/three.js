import haxe.extern.js.Lib;
import haxe.ui.Texture;

class CompressedArrayTexture extends Texture {
  public var isCompressedArrayTexture:Bool;

  public function new() {
    this.isCompressedArrayTexture = true;
    return this;
  }

  override public function dispose():Void {
    // TODO: Implement dispose logic
  }

  override public function update():Void {
    // TODO: Implement update logic
  }

  override public function getTexture():haxe.ui.Texture {
    // TODO: Implement getTexture logic
  }
}

class CompressedTexture extends Texture {
  public var isCompressedTexture:Bool;

  public function new() {
    this.isCompressedTexture = true;
    return this;
  }

  override public function dispose():Void {
    // TODO: Implement dispose logic
  }

  override public function update():Void {
    // TODO: Implement update logic
  }

  override public function getTexture():haxe.ui.Texture {
    // TODO: Implement getTexture logic
  }
}

class Main {
  static public function main() {
    // TODO: Add your QUnit tests here
  }
}