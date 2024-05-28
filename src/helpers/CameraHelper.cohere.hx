import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DRenderMode;

class CameraHelper extends LineSegments {

    public var camera:Camera;
    public var pointMap:Array<String, Array<Int>> = [];
    public var colorFrustum:openfl.display.ColorTransform;
    public var colorCone:openfl.display.ColorTransform;
    public var colorUp:openfl.display.ColorTransform;
    public var colorTarget:openfl.display.ColorTransform;
    public var colorCross:openfl.display.ColorTransform;

    public function new(camera:Camera) {
        var geometry = new BufferGeometry();
        var material = new LineBasicMaterial( { color: 0xffffff, vertexColors: true, toneMapped: false } );

        var vertices = [];
        var colors = [];

        // near

        addLine( 'n1', 'n2' );
        addLine( 'n2', 'n4' );
        addLine( 'n4', 'n3' );
        addLine( 'n3', 'n1' );

        // far

        addLine( 'f1', 'f2' );
        addLine( 'f2', 'f4' );
        addLine( 'f4', 'f3' );
        addLine( 'f3', 'f1' );

        // sides

        addLine( 'n1', 'f1' );
        addLine( 'n2', 'f2' );
        addLine( 'n3', 'f3' );
        addLine( 'n4', 'f4' );

        // cone

        addLine( 'p', 'n1' );
        addLine( 'p', 'n2' );
        addLine( 'p', 'n3' );
        addLine( 'p', 'n4' );

        // up

        addLine( 'u1', 'u2' );
        addLine( 'u2', 'u3' );
        addLine( 'u3', 'u1' );

        // target

        addLine( 'c', 't' );
        addLine( 'p', 'c' );

        // cross

        addLine( 'cn1', 'cn2' );
        addLine( 'cn3', 'cn4' );

        addLine( 'cf1', 'cf2' );
        addLine( 'cf3', 'cf4' );

        geometry.setAttribute( 'position', new Float32BufferAttribute( vertices, 3 ) );
        geometry.setAttribute( 'color', new Float32BufferAttribute( colors, 3 ) );

        super( geometry, material );

        this.type = 'CameraHelper';

        this.camera = camera;
        if ( this.camera.updateProjectionMatrix ) this.camera.updateProjectionMatrix();

        this.matrix = camera.matrixWorld;
        this.matrixAutoUpdate = false;

        this.pointMap = pointMap;

        this.update();

        // colors

        colorFrustum = new openfl.display.ColorTransform(0xffaa00, 0xffaa00, 0xffaa00, 1);
        colorCone = new openfl.display.ColorTransform(0xff0000, 0xff0000, 0xff0000, 1);
        colorUp = new openfl.display.ColorTransform(0x00aaff, 0x00aaff, 0x00aaff, 1);
        colorTarget = new openfl.display.ColorTransform(0xffffff, 0xffffff, 0xffffff, 1);
        colorCross = new openfl.display.ColorTransform(0x333333, 0x333333, 0x333333, 1);

        this.setColors( colorFrustum, colorCone, colorUp, colorTarget, colorCross );
    }

    public function setColors( frustum:openfl.display.ColorTransform, cone:openfl.display.ColorTransform, up:openfl.display.ColorTransform, target:openfl.display.ColorTransform, cross:openfl.display.ColorTransform ) {
        var geometry = this.geometry;
        var colorAttribute = geometry.getAttribute( 'color' );

        // near

        colorAttribute.setXYZ( 0, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 1, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n1, n2
        colorAttribute.setXYZ( 2, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 3, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n2, n4
        colorAttribute.setXYZ( 4, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 5, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n4, n3
        colorAttribute.setXYZ( 6, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 7, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n3, n1

        // far

        colorAttribute.setXYZ( 8, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 9, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // f1, f2
        colorAttribute.setXYZ( 10, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 11, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // f2, f4
        colorAttribute.setXYZ( 12, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 13, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // f4, f3
        colorAttribute.setXYZ( 14, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 15, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // f3, f1

        // sides

        colorAttribute.setXYZ( 16, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 17, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n1, f1
        colorAttribute.setXYZ( 18, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 19, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n2, f2
        colorAttribute.setXYZ( 20, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 21, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n3, f3
        colorAttribute.setXYZ( 22, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier );
        colorAttribute.setXYZ( 23, frustum.redMultiplier, frustum.greenMultiplier, frustum.blueMultiplier ); // n4, f4

        // cone

        colorAttribute.setXYZ( 24, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier );
        colorAttribute.setXYZ( 25, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier ); // p, n1
        colorAttribute.setXYZ( 26, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier );
        colorAttribute.setXYZ( 27, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier ); // p, n2
        colorAttribute.setXYZ( 28, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier );
        colorAttribute.setXYZ( 29, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier ); // p, n3
        colorAttribute.setXYZ( 30, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier );
        colorAttribute.setXYZ( 31, cone.redMultiplier, cone.greenMultiplier, cone.blueMultiplier ); // p, n4

        // up

        colorAttribute.setXYZ( 32, up.redMultiplier, up.greenMultiplier, up.blueMultiplier );
        colorAttribute.setXYZ( 33, up.redMultiplier, up.greenMultiplier, up.blueMultiplier ); // u1, u2
        colorAttribute.setXYZ( 34, up.redMultiplier, up.greenMultiplier, up.blueMultiplier );
        colorAttribute.setXYZ( 35, up.redMultiplier, up.greenMultiplier, up.blueMultiplier ); // u2, u3
        colorAttribute.setXYZ( 36, up.redMultiplier, up.greenMultiplier, up.blueMultiplier );
        colorAttribute.setXYZ( 37, up.redMultiplier, up.greenMultiplier, up.blueMultiplier ); // u3, u1

        // target

        colorAttribute.setXYZ( 38, target.redMultiplier, target.greenMultiplier, target.blueMultiplier );
        colorAttribute.setXYZ( 39, target.redMultiplier, target.greenMultiplier, target.blueMultiplier ); // c, t
        colorAttribute.setXYZ( 40, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier );
        colorAttribute.setXYZ( 41, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier ); // p, c

        // cross

        colorAttribute.setXYZ( 42, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier );
        colorAttribute.setXYZ( 43, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier ); // cn1, cn2
        colorAttribute.setXYZ( 44, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier );
        colorAttribute.setXYZ( 45, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier ); // cn3, cn4

        colorAttribute.setXYZ( 46, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier );
        colorAttribute.setXYZ( 47, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier ); // cf1, cf2
        colorAttribute.setXYZ( 48, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier );
        colorAttribute.setXYZ( 49, cross.redMultiplier, cross.greenMultiplier, cross.blueMultiplier ); // cf3, cf4

        colorAttribute.needsUpdate = true;
    }

    public function update() {
        var geometry = this.geometry;
        var pointMap = this.pointMap;
        var w = 1;
        var h = 1;

        // we need just camera projection matrix inverse
        // world matrix must be identity

        var cameraProjectionMatrixInverse:Matrix3D = new Matrix3D();
        cameraProjectionMatrixInverse.copyFrom( this.camera.projectionMatrixInverse );

        // center / target

        setPoint( 'c', pointMap, geometry, cameraProjectionMatrixInverse, 0, 0, - 1 );
        setPoint( 't', pointMap, geometry, cameraProjectionMatrixInverse, 0, 0, 1 );

        // near

        setPoint( 'n1', pointMap, geometry, cameraProjectionMatrixInverse, - w, - h, - 1 );
        setPoint( 'n2', pointMap, geometry, cameraProjectionMatrixInverse, w, - h, - 1 );
        setPoint( 'n3', pointMap, geometry, cameraProjectionMatrixInverse, - w, h, - 1 );
        setPoint( 'n4', pointMap, geometry, cameraProjectionMatrixInverse, w, h, - 1 );

        // far

        setPoint( 'f1', pointMap, geometry, cameraProjectionMatrixInverse, - w, - h, 1 );
        setPoint( 'f2', pointMap, geometry, cameraProjectionMatrixInverse, w, - h, 1 );
        setPoint( 'f3', pointMap, geometry, cameraProjectionMatrixInverse, - w, h, 1 );
        setPoint( 'f4', pointMap, geometry, cameraProjectionMatrixInverse, w, h, 1 );

        // up

        setPoint( 'u1', pointMap, geometry, cameraProjectionMatrixInverse, w * 0.7, h * 1.1, - 1 );
        setPoint( 'u2', pointMap, geometry, cameraProjectionMatrixInverse, - w * 0.7, h * 1.1, - 1 );
        setPoint( 'u3', pointMap, geometry, cameraProjectionMatrixInverse, 0, h * 2, - 1 );

        // cross

        setPoint( 'cf1', pointMap, geometry, cameraProjectionMatrixInverse, - w, 0, 1 );
        setPoint( 'cf2', pointMap, geometry, cameraProjectionMatrixInverse, w, 0, 1 );
        setPoint( 'cf3', pointMap, geometry, cameraProjectionMatrixInverse, 0, - h, 1 );
        setPoint( 'cf4', pointMap, geometry, cameraProjectionMatrixInverse, 0, h, 1 );

        setPoint( 'cn1', pointMap, geometry, cameraProjectionMatrixInverse, - w, 0, - 1 );
        setPoint( 'cn2', pointMap, geometry, cameraProjectionMatrixInverse, w, 0, - 1 );
        setPoint( 'cn3', pointMap, geometry, cameraProjectionMatrixInverse, 0, - h, - 1 );
        setPoint( 'cn4', pointMap, geometry, cameraProjectionMatrixInverse, 0, h, - 1 );

        geometry.getAttribute( 'position' ).needsUpdate = true;
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }

}

function addLine( a:String, b:String ) {
    addPoint( a );
    addPoint( b );
}

function addPoint( id:String ) {
    var vertices = (cast this.geometry.getAttribute('position') to Float32BufferAttribute).data;
    var colors = (cast this.geometry.getAttribute('color') to Float32BufferAttribute).data;

    vertices.push( 0 );
    vertices.push( 0 );
    vertices.push( 0 );

    colors.push( 0 );
    colors.push( 0 );
    colors.push( 0 );

    if ( !pointMap.exists(id) ) {
        pointMap[ id ] = [];
    }

    pointMap[ id ].push( Std.int((vertices.length / 3) - 1) );
}

function setPoint( point:String, pointMap:Array<String, Array<Int>>, geometry:BufferGeometry, camera:Matrix3D, x:Float, y:Float, z:Float ) {
    var vector = new Vector3D(x, y, z);
    vector = camera.invert().transformVector(vector);

    var points = pointMap[ point ];
    var position = cast geometry.getAttribute('position') to Float32BufferAttribute;

    for ( point in points ) {
        position.setXYZ( points[ point ], vector.x, vector.y, vector.z );
    }
}