import three.BufferGeometry;
import three.Float32BufferAttribute;

class BoxLineGeometry extends BufferGeometry {

    public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
        super();

        widthSegments = Std.int(widthSegments);
        heightSegments = Std.int(heightSegments);
        depthSegments = Std.int(depthSegments);

        var widthHalf:Float = width / 2;
        var heightHalf:Float = height / 2;
        var depthHalf:Float = depth / 2;

        var segmentWidth:Float = width / widthSegments;
        var segmentHeight:Float = height / heightSegments;
        var segmentDepth:Float = depth / depthSegments;

        var vertices:Array<Float> = [];

        var x:Float = - widthHalf;
        var y:Float = - heightHalf;
        var z:Float = - depthHalf;

        for (var i:Int = 0; i <= widthSegments; i ++) {
            vertices.push(x, - heightHalf, - depthHalf, x, heightHalf, - depthHalf);
            vertices.push(x, heightHalf, - depthHalf, x, heightHalf, depthHalf);
            vertices.push(x, heightHalf, depthHalf, x, - heightHalf, depthHalf);
            vertices.push(x, - heightHalf, depthHalf, x, - heightHalf, - depthHalf);
            x += segmentWidth;
        }

        for (var i:Int = 0; i <= heightSegments; i ++) {
            vertices.push(- widthHalf, y, - depthHalf, widthHalf, y, - depthHalf);
            vertices.push(widthHalf, y, - depthHalf, widthHalf, y, depthHalf);
            vertices.push(widthHalf, y, depthHalf, - widthHalf, y, depthHalf);
            vertices.push(- widthHalf, y, depthHalf, - widthHalf, y, - depthHalf);
            y += segmentHeight;
        }

        for (var i:Int = 0; i <= depthSegments; i ++) {
            vertices.push(- widthHalf, - heightHalf, z, - widthHalf, heightHalf, z);
            vertices.push(- widthHalf, heightHalf, z, widthHalf, heightHalf, z);
            vertices.push(widthHalf, heightHalf, z, widthHalf, - heightHalf, z);
            vertices.push(widthHalf, - heightHalf, z, - widthHalf, - heightHalf, z);
            z += segmentDepth;
        }

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }
}