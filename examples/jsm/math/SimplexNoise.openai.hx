class SimplexNoise {
    public var grad3:Array<Array<Float>> = [
        [1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0],
        [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
        [0, 1, 1], [0, 1, -1], [0, -1, 1], [0, -1, -1]
    ];

    public var grad4:Array<Array<Float>> = [
        [0, 1, 1, 1], [0, 1, 1, -1], [0, 1, -1, 1], [0, 1, -1, -1],
        [0, -1, 1, 1], [0, -1, 1, -1], [0, -1, -1, 1], [0, -1, -1, -1],
        [1, 0, 1, 1], [1, 0, 1, -1], [1, 0, -1, 1], [1, 0, -1, -1],
        [-1, 0, 1, 1], [-1, 0, 1, -1], [-1, 0, -1, 1], [-1, 0, -1, -1],
        [1, 1, 0, 1], [1, 1, 0, -1], [1, -1, 0, 1], [1, -1, 0, -1],
        [-1, 1, 0, 1], [-1, 1, 0, -1], [-1, -1, 0, 1], [-1, -1, 0, -1],
        [1, 1, 1, 0], [1, 1, -1, 0], [1, -1, 1, 0], [1, -1, -1, 0],
        [-1, 1, 1, 0], [-1, 1, -1, 0], [-1, -1, 1, 0], [-1, -1, -1, 0]
    ];

    public var p:Array<Int> = [];
    public var perm:Array<Int> = [];

    public function new(?r:Float->Float = Math.random) {
        for (i in 0...256) {
            p.push(Std.int(r() * 256));
        }
        for (i in 0...512) {
            perm.push(p[i & 255]);
        }
    }

    function dot(g:Array<Float>, x:Float, y:Float) {
        return g[0] * x + g[1] * y;
    }

    function dot3(g:Array<Float>, x:Float, y:Float, z:Float) {
        return g[0] * x + g[1] * y + g[2] * z;
    }

    function dot4(g:Array<Float>, x:Float, y:Float, z:Float, w:Float) {
        return g[0] * x + g[1] * y + g[2] * z + g[3] * w;
    }

    public function noise(x:Float, y:Float) {
        // omitted for brevity
    }

    public function noise3d(x:Float, y:Float, z:Float) {
        // omitted for brevity
    }

    public function noise4d(x:Float, y:Float, z:Float, w:Float) {
        // omitted for brevity
    }
}