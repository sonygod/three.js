class Layers {
    var mask:Int;

    public function new() {
        mask = 1;
    }

    public function set(channel:Int) {
        mask = 1 << channel;
    }

    public function enable(channel:Int) {
        mask |= 1 << channel;
    }

    public function enableAll() {
        mask = -1;
    }

    public function toggle(channel:Int) {
        mask ^= 1 << channel;
    }

    public function disable(channel:Int) {
        mask &= ~(1 << channel);
    }

    public function disableAll() {
        mask = 0;
    }

    public function test(layers:Layers):Bool {
        return (mask & layers.mask) != 0;
    }

    public function isEnabled(channel:Int):Bool {
        return (mask & (1 << channel)) != 0;
    }
}