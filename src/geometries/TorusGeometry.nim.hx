import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class TorusGeometry extends BufferGeometry {

    public var radius:Float = 1;
    public var tube:Float = 0.4;
    public var radialSegments:Int = 12;
    public var tubularSegments:Int = 48;
    public var arc:Float = Math.PI * 2;

    public function new(radius:Float = 1, tube:Float = 0.4, radialSegments:Int = 12, tubularSegments:Int = 48, arc:Float = Math.PI * 2) {

        super();

        this.type = 'TorusGeometry';

        this.parameters = {
            radius: radius,
            tube: tube,
            radialSegments: radialSegments,
            tubularSegments: tubularSegments,
            arc: arc
        };

        radialSegments = Math.floor( radialSegments );
        tubularSegments = Math.floor( tubularSegments );

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var center:Vector3 = new Vector3();
        var vertex:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();

        // generate vertices, normals and uvs

        for ( i in 0...radialSegments+1 ) {

            for ( j in 0...tubularSegments+1 ) {

                var u:Float = j / tubularSegments * arc;
                var v:Float = i / radialSegments * Math.PI * 2;

                // vertex

                vertex.x = ( radius + tube * Math.cos( v ) ) * Math.cos( u );
                vertex.y = ( radius + tube * Math.cos( v ) ) * Math.sin( u );
                vertex.z = tube * Math.sin( v );

                vertices.push( vertex.x, vertex.y, vertex.z );

                // normal

                center.x = radius * Math.cos( u );
                center.y = radius * Math.sin( u );
                normal.subVectors( vertex, center ).normalize();

                normals.push( normal.x, normal.y, normal.z );

                // uv

                uvs.push( j / tubularSegments );
                uvs.push( i / radialSegments );

            }

        }

        // generate indices

        for ( i in 1...radialSegments+1 ) {

            for ( j in 1...tubularSegments+1 ) {

                // indices

                var a:Int = ( tubularSegments + 1 ) * i + j - 1;
                var b:Int = ( tubularSegments + 1 ) * ( i - 1 ) + j - 1;
                var c:Int = ( tubularSegments + 1 ) * ( i - 1 ) + j;
                var d:Int = ( tubularSegments + 1 ) * i + j;

                // faces

                indices.push( a, b, d );
                indices.push( b, c, d );

            }

        }

        // build geometry

        this.setIndex( indices );
        this.setAttribute( 'position', new BufferAttribute( vertices, 3 ) );
        this.setAttribute( 'normal', new BufferAttribute( normals, 3 ) );
        this.setAttribute( 'uv', new BufferAttribute( uvs, 2 ) );

    }

    public function copy( source:TorusGeometry ):TorusGeometry {

        super.copy( source );

        this.parameters = source.parameters.copy();

        return this;

    }

    public static function fromJSON( data:Dynamic ):TorusGeometry {

        return new TorusGeometry( data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc );

    }

}

export(TorusGeometry);