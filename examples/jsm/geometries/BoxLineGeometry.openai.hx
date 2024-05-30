package three.js.examples.jsm.geometries;

import three.js.BufferGeometry;
import three.js_Float32BufferAttribute;

class BoxLineGeometry extends BufferGeometry {
    
    public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
        super();

        widthSegments = Math.floor(widthSegments);
        heightSegments = Math.floor(heightSegments);
        depthSegments = Math.floor(depthSegments);

        var widthHalf:Float = width / 2;
        var heightHalf:Float = height / 2;
        var depthHalf:Float = depth / 2;

        var segmentWidth:Float = width / widthSegments;
        var segmentHeight:Float = height / heightSegments;
        var segmentDepth:Float = depth / depthSegments;

        var vertices:Array<Float> = [];

        var x:Float = -widthHalf;
        var y:Float = -heightHalf;
        var z:Float = -depthHalf;

        for (i in 0...widthSegments + 1) {
            vertices.push(x, -heightHalf, -depthHalf);
            vertices.push(x, heightHalf, -depthHalf);
            vertices.push(x, heightHalf, depthHalf);
            vertices.push(x, -heightHalf, depthHalf);
            vertices.push(x, -heightHalf, -depthHalf);

            x += segmentWidth;
        }

        x = -widthHalf;

        for (i in 0...heightSegments + 1) {
            vertices.push(-widthHalf, y, -depthHalf);
            vertices.push(widthHalf, y, -depthHalf);
            vertices.push(widthHalf, y, depthHalf);
            vertices.push(-widthHalf, y, depthHalf);
            vertices.push(-widthHalf, y, -depthHalf);

            y += segmentHeight;
        }

        y = -heightHalf;

        for (i in 0...depthSegments + 1) {
            vertices.push(-widthHalf, -heightHalf, z);
            vertices.push(-widthHalf, heightHalf, z);
            vertices.push(widthHalf, heightHalf, z);
            vertices.push(widthHalf, -heightHalf, z);
            vertices.push(-widthHalf, -heightHalf, z);

            z += segmentDepth;
        }

        setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }
}