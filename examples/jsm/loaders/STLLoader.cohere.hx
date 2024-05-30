import haxe.io.Bytes;
import js.Browser;

class STLLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Bytes->Void, onProgress:Float->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.path = this.path;
        loader.responseType = 'arraybuffer';
        loader.requestHeader = this.requestHeader;
        loader.withCredentials = this.withCredentials;

        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch( e ) {
                if ( onError ) {
                    onError( e );
                } else {
                    trace(e);
                }
                scope.manager.itemError( url );
            }
        }, onProgress, onError);
    }

    public function parse(data:Bytes):BufferGeometry {
        function isBinary(data:Bytes):Bool {
            var reader = new DataView(data);
            var face_size = ( 32 / 8 * 3 ) + ( ( 32 / 8 * 3 ) * 3 ) + ( 16 / 8 );
            var n_faces = reader.getUint32( 80, true );
            var expect = 80 + ( 32 / 8 ) + ( n_faces * face_size );

            if ( expect == reader.byteLength ) {
                return true;
            }

            // An ASCII STL data must begin with 'solid ' as the first six bytes.
            // However, ASCII STLs lacking the SPACE after the 'd' are known to be
            // plentiful.  So, check the first 5 bytes for 'solid'.

            // Several encodings, such as UTF-8, precede the text with up to 5 bytes:
            // https://en.wikipedia.org/wiki/Byte_order_mark#Byte_order_marks_by_encoding
            // Search for "solid" to start anywhere after those prefixes.

            // US-ASCII ordinal values for 's', 'o', 'l', 'i', 'd'

            var solid = [ 115, 111, 108, 105, 100 ];

            for ( i in 0...5 ) {
                // If "solid" text is matched to the current offset, declare it to be an ASCII STL.
                if ( matchDataViewAt( solid, reader, i ) ) return false;
            }

            // Couldn't find "solid" text at the beginning; it is binary STL.
            return true;
        }

        function matchDataViewAt(query:Array<Int>, reader:DataView, offset:Int):Bool {
            // Check if each byte in query matches the corresponding byte from the current offset
            for ( i in 0...query.length ) {
                if ( query[i] != reader.getUint8(offset + i) ) return false;
            }
            return true;
        }

        function parseBinary(data:Bytes):BufferGeometry {
            var reader = new DataView(data);
            var faces = reader.getUint32( 80, true );

            var r:Float, g:Float, b:Float, hasColors:Bool, colors:Float32Array;
            var defaultR:Float, defaultG:Float, defaultB:Float, alpha:Float;

            // process STL header
            // check for default color in header ("COLOR=rgba" sequence).
            for (var index = 0; index < 80 - 10; index++) {
                if ( ( reader.getUint32( index, false ) == 0x434F4C4F /*COLO*/ ) &&
                    ( reader.getUint8( index + 4 ) == 0x52 /*'R'*/ ) &&
                    ( reader.getUint8( index + 5 ) == 0x3D /*'='*/ ) ) {

                    hasColors = true;
                    colors = new Float32Array( faces * 3 * 3 );

                    defaultR = reader.getUint8( index + 6 ) / 255;
                    defaultG = reader.getUint8( index + 7 ) / 255;
                    defaultB = reader.getUint8( index + 8 ) / 255;
                    alpha = reader.getUint8( index + 9 ) / 255;
                }
            }

            var dataOffset = 84;
            var faceLength = 12 * 4 + 2;

            var geometry = new BufferGeometry();

            var vertices = new Float32Array( faces * 3 * 3 );
            var normals = new Float32Array( faces * 3 * 3 );

            var color = new Color();

            for (var face = 0; face < faces; face++) {
                var start = dataOffset + face * faceLength;
                var normalX = reader.getFloat32( start, true );
                var normalY = reader.getFloat32( start + 4, true );
                var normalZ = reader.getFloat32( start + 8, true );

                if ( hasColors ) {
                    var packedColor = reader.getUint16( start + 48, true );

                    if ( ( packedColor & 0x8000 ) == 0 ) {
                        // facet has its own unique color
                        r = ( packedColor & 0x1F ) / 31;
                        g = ( ( packedColor >> 5 ) & 0x1F ) / 31;
                        b = ( ( packedColor >> 10 ) & 0x1F ) / 31;
                    } else {
                        r = defaultR;
                        g = defaultG;
                        b = defaultB;
                    }
                }

                for (var i = 1; i <= 3; i++) {
                    var vertexstart = start + i * 12;
                    var componentIdx = ( face * 3 * 3 ) + ( ( i - 1 ) * 3 );

                    vertices[ componentIdx ] = reader.getFloat32( vertexstart, true );
                    vertices[ componentIdx + 1 ] = reader.getFloat32( vertexstart + 4, true );
                    vertices[ componentIdx + 2 ] = reader.getFloat32( vertexstart + 8, true );

                    normals[ componentIdx ] = normalX;
                    normals[ componentIdx + 1 ] = normalY;
                    normals[ componentIdx + 2 ] = normalZ;

                    if ( hasColors ) {
                        color.set( r, g, b ).convertSRGBToLinear();

                        colors[ componentIdx ] = color.r;
                        colors[ componentIdx + 1 ] = color.g;
                        colors[ componentIdx + 2 ] = color.b;
                    }
                }
            }

            geometry.setAttribute( 'position', new BufferAttribute( vertices, 3 ) );
            geometry.setAttribute( 'normal', new BufferAttribute( normals, 3 ) );

            if ( hasColors ) {
                geometry.setAttribute( 'color', new BufferAttribute( colors, 3 ) );
                geometry.hasColors = true;
                geometry.alpha = alpha;
            }

            return geometry;
        }

        function parseASCII(data:String):BufferGeometry {
            var geometry = new BufferGeometry();
            var patternSolid = ~/solid([\s\S]*?)endsolid/g;
            var patternFace = ~/facet([\s\S]*?)endfacet/g;
            var patternName = ~/solid\s(.+)/;
            var faceCounter = 0;

            var patternFloat = ~/[\s]+([+-]?(?:\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?)/;
            var patternVertex = new RegExp( 'vertex' + patternFloat.source + patternFloat.source + patternFloat.source, 'g' );
            var patternNormal = new RegExp( 'normal' + patternFloat.source + patternFloat.source + patternFloat.source, 'g' );

            var vertices = [];
            var normals = [];
            var groupNames = [];

            var normal = new Vector3();

            var result;

            var groupCount = 0;
            var startVertex = 0;
            var endVertex = 0;

            while ( ( result = patternSolid.exec( data ) ) != null ) {
                startVertex = endVertex;

                var solid = result[ 0 ];

                var name = ( result = patternName.exec( solid ) ) != null ? result[ 1 ] : '';
                groupNames.push( name );

                while ( ( result = patternFace.exec( solid ) ) != null ) {
                    var vertexCountPerFace = 0;
                    var normalCountPerFace = 0;

                    var text = result[ 0 ];

                    while ( ( result = patternNormal.exec( text ) ) != null ) {
                        normal.x = Std.parseFloat( result[ 1 ] );
                        normal.y = Std.parseFloat( result[ 2 ] );
                        normal.z = Std.parseFloat( result[ 3 ] );
                        normalCountPerFace++;
                    }

                    while ( ( result = patternVertex.exec( text ) ) != null ) {
                        vertices.push( Std.parseFloat( result[ 1 ] ), Std.parseFloat( result[ 2 ] ), Std.parseFloat( result[ 3 ] ) );
                        normals.push( normal.x, normal.y, normal.z );
                        vertexCountPerFace++;
                        endVertex++;
                    }

                    // every face have to own ONE valid normal
                    if ( normalCountPerFace != 1 ) {
                        trace('THREE.STLLoader: Something isn\'t right with the normal of face number ' + faceCounter);
                    }

                    // each face have to own THREE valid vertices
                    if ( vertexCountPerFace != 3 ) {
                        trace('THREE.STLLoader: Something isn\'t right with the vertices of face number ' + faceCounter);
                    }

                    faceCounter++;
                }

                var start = startVertex;
                var count = endVertex - startVertex;

                geometry.userData.groupNames = groupNames;

                geometry.addGroup( start, count, groupCount );
                groupCount++;
            }

            geometry.setAttribute( 'position', new Float32BufferAttribute( vertices, 3 ) );
            geometry.setAttribute( 'normal', new Float32BufferAttribute( normals, 3 ) );

            return geometry;
        }

        function ensureString(buffer:Bytes):String {
            if ( !Std.isString(buffer) ) {
                return new TextDecoder().decode(buffer);
            }
            return buffer;
        }

        function ensureBinary(buffer:Dynamic):Bytes {
            if ( Std.isString(buffer) ) {
                var array_buffer = new Uint8Array(buffer.length);
                for ( i in 0...buffer.length ) {
                    array_buffer[i] = buffer.charCodeAt(i) & 0xff; // implicitly assumes little-endian
                }
                return array_buffer.toBytes();
            } else {
                return buffer;
            }
        }

        // start

        var binData = ensureBinary(data);

        return isBinary(binData) ? parseBinary(binData) : parseASCII(ensureString(data));
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

class Color {
    public var r:Float;
    public var g:Float;
    public var b:Float;

    public function set(r:Float, g:Float, b:Float):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        return this;
    }

    public function convertSRGBToLinear():Color {
        this.r = Math.pow(this.r, 2.2);
        this.g = Math.pow(this.g, 2.2);
        this.b = Math.pow(this.b, 2.2);
        return this;
    }
}

class BufferGeometry {
    public function new() {

    }

    public function addGroup(start:Int, count:Int, materialIndex:Int):Void {

    }

    public function setAttribute(name:String, attribute:BufferAttribute):Void {

    }

    public var hasColors:Bool;
    public var alpha:Float;
}

class BufferAttribute {
    public function new(array:Float32Array, itemSize:Int) {

    }
}

class Loader {
    public var manager:Loader;
    public var path:String;
    public var requestHeader:String;
    public var withCredentials:Bool;

    public function new(manager:Loader) {
        this.manager = manager;
    }
}

class FileLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function setResponseType(value:String):Void {

    }
}

class TextDecoder {
    public function decode(buffer:Bytes):String {
        return Bytes.toString(buffer, 'utf8');
    }
}