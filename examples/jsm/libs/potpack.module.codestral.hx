import Math;

class Box {
    public var w:Float;
    public var h:Float;
    public var x:Float;
    public var y:Float;
}

class Space {
    public var x:Float;
    public var y:Float;
    public var w:Float;
    public var h:Float;
}

class PotpackResult {
    public var w:Float;
    public var h:Float;
    public var fill:Float;
}

class Potpack {
    public static function pack(boxes:Array<Box>):PotpackResult {
        var area:Float = 0;
        var maxWidth:Float = 0;

        for (box in boxes) {
            area += box.w * box.h;
            maxWidth = Math.max(maxWidth, box.w);
        }

        boxes.sort(function(a, b):Int {
            return -Math.sign(a.h - b.h);
        });

        var startWidth:Float = Math.max(Math.ceil(Math.sqrt(area / 0.95)), maxWidth);

        var spaces:Array<Space> = [new Space(0, 0, startWidth, Float.POSITIVE_INFINITY)];

        var width:Float = 0;
        var height:Float = 0;

        for (box in boxes) {
            for (i in (spaces.length - 1).to(0)) {
                var space:Space = spaces[i];

                if (box.w > space.w || box.h > space.h) continue;

                box.x = space.x;
                box.y = space.y;

                height = Math.max(height, box.y + box.h);
                width = Math.max(width, box.x + box.w);

                if (box.w == space.w && box.h == space.h) {
                    if (i < spaces.length) spaces[i] = spaces.pop();
                    else spaces.pop();
                } else if (box.h == space.h) {
                    space.x += box.w;
                    space.w -= box.w;
                } else if (box.w == space.w) {
                    space.y += box.h;
                    space.h -= box.h;
                } else {
                    spaces.push(new Space(space.x + box.w, space.y, space.w - box.w, box.h));
                    space.y += box.h;
                    space.h -= box.h;
                }
                break;
            }
        }

        return new PotpackResult(width, height, (area / (width * height)) || 0);
    }
}