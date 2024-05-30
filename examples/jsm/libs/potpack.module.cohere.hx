/**
 * potpack - by [@mourner](https://github.com/mourner)
 * 
 * A tiny JavaScript function for packing 2D rectangles into a near-square container, 
 * which is useful for generating CSS sprites and WebGL textures. Similar to 
 * [shelf-pack](https://github.com/mapbox/shelf-pack), but static (you can't add items 
 * once a layout is generated), and aims for maximal space utilization.
 *
 * A variation of algorithms used in [rectpack2D](https://github.com/TeamHypersomnia/rectpack2D)
 * and [bin-pack](https://github.com/bryanburgers/bin-pack), which are in turn based 
 * on [this article by Blackpawn](http://blackpawn.com/texts/lightmaps/default.html).
 * 
 * @license
 * ISC License
 * 
 * Copyright (c) 2018, Mapbox
 * 
 * Permission to use, copy, modify, and/or distribute this software for any purpose
 * with or without fee is hereby granted, provided that the above copyright notice
 * and this permission notice appear in all copies.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
 * THIS SOFTWARE.
 */

function potpack(boxes:Array<Box>) : Pot {

	// calculate total box area and maximum box width
	var area = 0;
	var maxWidth = 0;
	
	for (box in boxes) {
		area += box.w * box.h;
		maxWidth = max(maxWidth, box.w);
	}
	
	// sort the boxes for insertion by height, descending
	boxes.sort($boxA -> $boxB -> $boxB.h - $boxA.h);
	
	// aim for a squarish resulting container,
	// slightly adjusted for sub-100% space utilization
	var startWidth = max(ceil(sqrt(area / 0.95)), maxWidth);
	
	// start with a single empty space, unbounded at the bottom
	var spaces = [Space(0, 0, startWidth, Infinity)];
	
	var width = 0;
	var height = 0;
	
	for (box in boxes) {
		// look through spaces backwards so that we check smaller spaces first
		for (i in rrange(spaces.length)) {
			var space = spaces[spaces.length - i - 1];
			
			// look for empty spaces that can accommodate the current box
			if (box.w > space.w || box.h > space.h) continue;
			
			// found the space; add the box to its top-left corner
			// |-------|-------|
			// |  box  |       |
			// |_______|       |
			// |         space |
			// |_______________|
			box.x = space.x;
			box.y = space.y;
			
			height = max(height, box.y + box.h);
			width = max(width, box.x + box.w);
			
			if (box.w == space.w && box.h == space.h) {
				// space matches the box exactly; remove it
				var last = spaces.pop();
				if (spaces.length > 0) spaces[spaces.length - i - 1] = last;
			
			} else if (box.h == space.h) {
				// space matches the box height; update it accordingly
				// |-------|---------------|
				// |  box  | updated space |
				// |_______|_______________|
				space.x += box.w;
				space.w -= box.w;
			
			} else if (box.w == space.w) {
				// space matches the box width; update it accordingly
				// |---------------|
				// |      box      |
				// |_______________|
				// | updated space |
				// |_______________|
				space.y += box.h;
				space.h -= box.h;
			
			} else {
				// otherwise the box splits the space into two spaces
				// |-------|-----------|
				// |  box  | new space |
				// |_______|___________|
				// | updated space     |
				// |___________________|
				spaces.push(Space(space.x + box.w, space.y, space.w - box.w, box.h));
				space.y += box.h;
				space.h -= box.h;
			}
			break;
		}
	}
	
	return Pot(width, height, (area / (width * height)) as Float);
}

class Box {
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;
	public function new(x:Int, y:Int, w:Int, h:Int) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
}

class Space {
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;
	public function new(x:Int, y:Int, w:Int, h:Int) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
}

class Pot {
	public var w : Int;
	public var h : Int;
	public var fill : Float;
	public function new(w:Int, h:Int, fill:Float) {
		this.w = w;
		this.h = h;
		this.fill = fill;
	}
}

function max(a:Int, b:Int) : Int {
	return (a > b) ? a : b;
}

function ceil(f:Float) : Int {
	return Std.int(f);
}

function rrange(length:Int) : Array<Int> {
	return [0...length].reverse();
}