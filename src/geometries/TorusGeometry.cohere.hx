import js.Browser.Float32Array;
import js.Browser.Math.Vector3;

class TorusGeometry extends BufferGeometry {
    public var radius:Float = 1.0;
    public var tube:Float = 0.4;
    public var radialSegments:Int = 12;
    public var tubularSegments:Int = 48;
    public var arc:Float = Std.Math.PI * 2.0;

    public function new(radius:Float = 1.0, tube:Float = 0.4, radialSegments:Int = 12, tubularSegments:Int = 48, arc:Float = Std.Math.PI * 2.0) {
        super();

        this.radius = radius;
        this.tube = tube;
        this.radialSegments = radialSegments;
        this.tubularSegments = tubularSegments;
        this.arc = arc;

        radialSegments = Math.floor( radialSegments );
        tubularSegments = Math.floor( tubularSegments );

        // buffers

        var indices = [];
        var vertices = [];
        var normals = [];
        var uvs = [];

        // helper variables

        var center = new Vector3();
        var vertex = new Vector3();
        var normal = new Vector3();

        // generate vertices, normals and uvs

        var j:Int;
        for (j = 0; j <= radialSegments; j++) {
            var i:Int;
            for (i = 0; i <= tubularSegments; i++) {
                var u:Float = i / tubularSegments * arc;
                var v:Float = j / radialSegments * Std.Math.PI * 2.0;

                // vertex

                vertex.x = ( radius + tube * Math.cos( v ) ) * Math.cos( u );
                vertex.y = ( radius + tube * Math.cos( v ) ) * Math.sin( u );
                vertex.z = tube * Math.sin( v );

                vertices.push( vertex.x );
                vertices.push( vertex.y );
                vertices.push( vertex.z );

                // normal

                center.x = radius * Math.cos( u );
                center.y = radius * Math.sin( u );
                normal.sub( vertex, center ).normalize();

                normals.push( normal.x );
                normals.push( normal.y );
                normals.push( normal.z );

                // uv

                uvs.push( i / tubularSegments );
                uvs.push( j / radialSegments );

            }

        }

        // generate indices

        for (j = 1; j <= radialSegments; j++) {
            for (i = 1; i <= tubularSegments; i++) {

                // indices

                var a:Int = ( tubularSegments + 1 ) * j + i - 1;
                var b:Int = ( tubularSegments + 1 ) * ( j - 1 ) + i - 1;
                var c:Int = ( tubularSegments + 1 ) * ( j - 1 ) + i;
                var d:Int = ( tubularSegments + 1 ) * j + i;

                // faces

                indices.push( a );
                indices.push( b );
                indices.push( d );

                indices.push( b );
                indices.push( c );
                indices.push( d );

            }

        }

        // build geometry

        this.setIndex( indices );
        this.setAttribute( 'position', new Float32BufferAttribute( new Float32Array(vertices), 3 ) );
        this.setAttribute( 'normal', new Float32BufferAttribute( new Float32Array(normals), 3 ) );
        this.setAttribute( 'uv', new Float32BufferAttribute( new Float32Array(uvs), 2 ) );

    }

    public function copy(source:TorusGeometry) {
        super.copy( source );

        this.radius = source.radius;
        this.tube = source.tube;
        this.radialSegments = source.radialSegments;
        this.tubularSegments = source.tubularSegments;
        this.arc = source.arc;

        return this;

    }

    public static function fromJSON(data:Dynamic) {
        return new TorusGeometry( data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc );

    }

}