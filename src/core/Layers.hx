package three.core;

class Layers {
    public var mask:Int;

    public function new() {
        mask = 1 | 0;
    }

    public function set(channel:Int):Void {
        mask = (1 << channel) >>> 0;
    }

    public function enable(channel:Int):Void {
        mask |= 1 << channel | 0;
    }

    public function enableAll():Void {
        mask = 0xffffffff | 0;
    }

    public function toggle(channel:Int):Void {
        mask ^= 1 << channel | 0;
    }

    public function disable(channel:Int):Void {
        mask &= ~(1 << channel | 0);
    }

    public function disableAll():Void {
        mask = 0;
    }

    public function test(layers:Layers):Bool {
        return (mask & layers.mask) != 0;
    }

    public function isEnabled(channel:Int):Bool {
        return (mask & (1 << channel | 0)) != 0;
    }
}