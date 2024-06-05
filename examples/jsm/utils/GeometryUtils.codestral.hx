class GeometryUtils {
    public static function hilbert2D(center:Vector3 = new Vector3(0, 0, 0), size:Float = 10, iterations:Int = 1, v0:Int = 0, v1:Int = 1, v2:Int = 2, v3:Int = 3):Array<Vector3> {
        var half:Float = size / 2;
        var vec_s:Array<Vector3> = [
            new Vector3(center.x - half, center.y, center.z - half),
            new Vector3(center.x - half, center.y, center.z + half),
            new Vector3(center.x + half, center.y, center.z + half),
            new Vector3(center.x + half, center.y, center.z - half)
        ];
        var vec:Array<Vector3> = [
            vec_s[v0],
            vec_s[v1],
            vec_s[v2],
            vec_s[v3]
        ];
        if (0 <= --iterations) {
            return [
                ...hilbert2D(vec[0], half, iterations, v0, v3, v2, v1),
                ...hilbert2D(vec[1], half, iterations, v0, v1, v2, v3),
                ...hilbert2D(vec[2], half, iterations, v0, v1, v2, v3),
                ...hilbert2D(vec[3], half, iterations, v2, v1, v0, v3)
            ];
        }
        return vec;
    }

    public static function hilbert3D(center:Vector3 = new Vector3(0, 0, 0), size:Float = 10, iterations:Int = 1, v0:Int = 0, v1:Int = 1, v2:Int = 2, v3:Int = 3, v4:Int = 4, v5:Int = 5, v6:Int = 6, v7:Int = 7):Array<Vector3> {
        var half:Float = size / 2;
        var vec_s:Array<Vector3> = [
            new Vector3(center.x - half, center.y + half, center.z - half),
            new Vector3(center.x - half, center.y + half, center.z + half),
            new Vector3(center.x - half, center.y - half, center.z + half),
            new Vector3(center.x - half, center.y - half, center.z - half),
            new Vector3(center.x + half, center.y - half, center.z - half),
            new Vector3(center.x + half, center.y - half, center.z + half),
            new Vector3(center.x + half, center.y + half, center.z + half),
            new Vector3(center.x + half, center.y + half, center.z - half)
        ];
        var vec:Array<Vector3> = [
            vec_s[v0],
            vec_s[v1],
            vec_s[v2],
            vec_s[v3],
            vec_s[v4],
            vec_s[v5],
            vec_s[v6],
            vec_s[v7]
        ];
        if (--iterations >= 0) {
            return [
                ...hilbert3D(vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1),
                ...hilbert3D(vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3),
                ...hilbert3D(vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3),
                ...hilbert3D(vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5),
                ...hilbert3D(vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5),
                ...hilbert3D(vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7),
                ...hilbert3D(vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7),
                ...hilbert3D(vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7)
            ];
        }
        return vec;
    }

    public static function gosper(size:Float = 1):Array<Float> {
        function fractalize(config:Dynamic):String {
            var output:String;
            var input:String = config.axiom;
            for (i in 0...config.steps) {
                output = '';
                for (j in 0...input.length) {
                    var char:String = input.charAt(j);
                    if (config.rules.hasOwnProperty(char)) {
                        output += config.rules[char];
                    } else {
                        output += char;
                    }
                }
                input = output;
            }
            return output;
        }

        function toPoints(config:Dynamic):Array<Float> {
            var currX:Float = 0, currY:Float = 0;
            var angle:Float = 0;
            var path:Array<Float> = [0, 0, 0];
            var fractal:String = config.fractal;
            for (i in 0...fractal.length) {
                var char:String = fractal.charAt(i);
                if (char == '+') {
                    angle += config.angle;
                } else if (char == '-') {
                    angle -= config.angle;
                } else if (char == 'F') {
                    currX += config.size * Math.cos(angle);
                    currY += - config.size * Math.sin(angle);
                    path.push(currX, currY, 0);
                }
            }
            return path;
        }

        var gosper:String = fractalize({
            axiom: 'A',
            steps: 4,
            rules: {
                'A': 'A+BF++BF-FA--FAFA-BF+',
                'B': '-FA+BFBF++BF+FA--FA-B'
            }
        });

        var points:Array<Float> = toPoints({
            fractal: gosper,
            size: size,
            angle: Math.PI / 3 // 60 degrees
        });

        return points;
    }
}