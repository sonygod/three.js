class Layers {

	public var mask:Int;

	public function new() {
		this.mask = 1;
	}

	public function set(channel:Int) {
		this.mask = (1 << channel) >>> 0;
	}

	public function enable(channel:Int) {
		this.mask |= (1 << channel);
	}

	public function enableAll() {
		this.mask = 0xffffffff;
	}

	public function toggle(channel:Int) {
		this.mask ^= (1 << channel);
	}

	public function disable(channel:Int) {
		this.mask &= ~(1 << channel);
	}

	public function disableAll() {
		this.mask = 0;
	}

	public function test(layers:Layers):Bool {
		return (this.mask & layers.mask) != 0;
	}

	public function isEnabled(channel:Int):Bool {
		return (this.mask & (1 << channel)) != 0;
	}

}