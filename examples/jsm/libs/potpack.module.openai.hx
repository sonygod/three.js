package three.js.examples.jsm.libs;

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
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
 * THIS SOFTWARE.
 */

class PotPack {
    public static function potpack(boxes:Array<{w:Float, h:Float}>):{w:Float, h:Float, fill:Float} {
        var area:Float = 0;
        var maxWidth:Float = 0;
        
        for (box in boxes) {
            area += box.w * box.h;
            maxWidth = Math.max(maxWidth, box.w);
        }
        
        boxes.sort((a, b) -> b.h - a.h);
        
        var startWidth:Float = Math.max(Math.ceil(Math.sqrt(area / 0.95)), maxWidth);
        
        var spaces:Array<{x:Float, y:Float, w:Float, h:Float}> = [{x: 0, y: 0, w: startWidth, h: Math.POSITIVE_INFINITY}];
        
        var width:Float = 0;
        var height:Float = 0;
        
        for (box in boxes) {
            for (i in (spaces.length - 1)...0) {
                var space = spaces[i];
                
                if (box.w > space.w || box.h > space.h) continue;
                
                box.x = space.x;
                box.y = space.y;
                
                height = Math.max(height, box.y + box.h);
                width = Math.max(width, box.x + box.w);
                
                if (box.w == space.w && box.h == space.h) {
                    spaces.pop();
                    if (i < spaces.length) spaces[i] = spaces[spaces.length - 1];
                
                } else if (box.h == space.h) {
                    space.x += box.w;
                    space.w -= box.w;
                
                } else if (box.w == space.w) {
                    space.y += box.h;
                    space.h -= box.h;
                
                } else {
                    spaces.push({
                        x: space.x + box.w,
                        y: space.y,
                        w: space.w - box.w,
                        h: box.h
                    });
                    space.y += box.h;
                    space.h -= box.h;
                }
                break;
            }
        }
        
        return {
            w: width, // container width
            h: height, // container height
            fill: (area / (width * height)) || 0 // space utilization
        };
    }
}