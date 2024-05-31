```haxe
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
```

**Explanation:**

1. **Class Declaration:** The `class` keyword is used to declare the `Layers` class, similar to JavaScript.
2. **Member Variables:** We define a `mask` member variable of type `Int` to store the layer mask.
3. **Constructor:** The `new()` function acts as the constructor, initializing the `mask` to `1`.
4. **Methods:** All the methods from the JavaScript code are directly translated to Haxe, with minor adjustments:
   - **Bitwise Operators:** Haxe uses the same bitwise operators (`|`, `^`, `&`, `~`) as JavaScript.
   - **Casting:** The `>>> 0` cast used in JavaScript for unsigned right shift is not necessary in Haxe.
   - **Type Annotations:** Haxe requires explicit type annotations, so we specify `Int` for parameters and return values where applicable.
   - **Method Visibility:** Haxe uses `public` as the default visibility modifier for methods.
5. **Boolean Expressions:** We use `!= 0` instead of `!== 0` in Haxe for comparing with zero, as Haxe doesn't have strict comparison operators.

This Haxe code is a direct translation of the original JavaScript code, preserving its functionality. You can now use this `Layers` class in your Haxe projects to manage object layers effectively.
