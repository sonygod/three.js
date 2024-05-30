class Layers {

    public var mask:Int;

    public function new() {
        this.mask = 1;
    }

    public function set(channel:Int):Void {
        this.mask = (1 << channel);
    }

    public function enable(channel:Int):Void {
        this.mask |= (1 << channel);
    }

    public function enableAll():Void {
        this.mask = 0xFFFFFFFF;
    }

    public function toggle(channel:Int):Void {
        this.mask ^= (1 << channel);
    }

    public function disable(channel:Int):Void {
        this.mask &= ~(1 << channel);
    }

    public function disableAll():Void {
        this.mask = 0;
    }

    public function test(layers:Layers):Bool {
        return (this.mask & layers.mask) != 0;
    }

    public function isEnabled(channel:Int):Bool {
        return (this.mask & (1 << channel)) != 0;
    }

}