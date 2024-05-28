package three.math;

import haxe.ds.StringMap;

using Lambda;

class Color {

    public var r:Float = 1;
    public var g:Float = 1;
    public var b:Float = 1;

    public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
        set(r, g, b);
    }

    public function set(r:Float, g:Float, b:Float):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        return this;
    }

    // ...

    public function setHex(hex:Int, colorSpace:String = SRGBColorSpace):Color {
        hex = Math.floor(hex);
        this.r = (hex >> 16 & 255) / 255;
        this.g = (hex >> 8 & 255) / 255;
        this.b = (hex & 255) / 255;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setRGB(r:Float, g:Float, b:Float, colorSpace:String = ColorManagement.workingColorSpace):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setHSL(h:Float, s:Float, l:Float, colorSpace:String = ColorManagement.workingColorSpace):Color {
        // ...
    }

    // ...

    public static var NAMES:StringMap<Int> = [
        'aliceblue' => 0xF0F8FF,
        'antiquewhite' => 0xFAEBD7,
        'aqua' => 0x00FFFF,
        // ...
    ];
}