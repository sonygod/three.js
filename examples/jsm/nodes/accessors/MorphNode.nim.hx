import Node, { addNodeClass } from '../core/Node.js';
import { NodeUpdateType } from '../core/constants.js';
import { float, nodeProxy, tslFn } from '../shadernode/ShaderNode.js';
import { uniform } from '../core/UniformNode.js';
import { reference } from './ReferenceNode.js';
import { positionLocal } from './PositionNode.js';
import { normalLocal } from './NormalNode.js';
import { textureLoad } from './TextureNode.js';
import { instanceIndex, vertexIndex } from '../core/IndexNode.js';
import { ivec2, int } from '../shadernode/ShaderNode.js';
import { DataArrayTexture, Vector2, Vector4, FloatType } from 'three';
import { loop } from '../utils/LoopNode.js';

class MorphTextures {
    public var map: Map<Dynamic, Dynamic>;
    public function new() {
        this.map = new Map<Dynamic, Dynamic>();
    }
}

var morphTextures = new MorphTextures();
var morphVec4 = new Vector4();

var getMorph = tslFn( ( { bufferMap, influence, stride, width, depth, offset } ) -> {

    var texelIndex = int( vertexIndex ).mul( stride ).add( offset );

    var y = texelIndex.div( width );
    var x = texelIndex.sub( y.mul( width ) );

    var bufferAttrib = textureLoad( bufferMap, ivec2( x, y ) ).depth( depth );

    return bufferAttrib.mul( influence );

} );

function getEntry( geometry ) {

    var hasMorphPosition = geometry.morphAttributes.position != null;
    var hasMorphNormals = geometry.morphAttributes.normal != null;
    var hasMorphColors = geometry.morphAttributes.color != null;

    var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
    var morphTargetsCount = ( morphAttribute != null ) ? morphAttribute.length : 0;

    var entry = morphTextures.map.get( geometry );

    if ( entry == null || entry.count != morphTargetsCount ) {

        if ( entry != null ) entry.texture.dispose();

        var morphTargets = geometry.morphAttributes.position || [];
        var morphNormals = geometry.morphAttributes.normal || [];
        var morphColors = geometry.morphAttributes.color || [];

        var vertexDataCount = 0;

        if ( hasMorphPosition == true ) vertexDataCount = 1;
        if ( hasMorphNormals == true ) vertexDataCount = 2;
        if ( hasMorphColors == true ) vertexDataCount = 3;

        var width = geometry.attributes.position.count * vertexDataCount;
        var height = 1;

        var maxTextureSize = 4096; // @TODO: Use 'capabilities.maxTextureSize'

        if ( width > maxTextureSize ) {

            height = Math.ceil( width / maxTextureSize );
            width = maxTextureSize;

        }

        var buffer = new Float32Array( width * height * 4 * morphTargetsCount );

        var bufferTexture = new DataArrayTexture( buffer, width, height, morphTargetsCount );
        bufferTexture.type = FloatType;
        bufferTexture.needsUpdate = true;

        // fill buffer

        var vertexDataStride = vertexDataCount * 4;

        for ( i in 0...morphTargetsCount ) {

            var morphTarget = morphTargets[ i ];
            var morphNormal = morphNormals[ i ];
            var morphColor = morphColors[ i ];

            var offset = width * height * 4 * i;

            for ( j in 0...morphTarget.count ) {

                var stride = j * vertexDataStride;

                if ( hasMorphPosition == true ) {

                    morphVec4.fromBufferAttribute( morphTarget, j );

                    buffer[ offset + stride + 0 ] = morphVec4.x;
                    buffer[ offset + stride + 1 ] = morphVec4.y;
                    buffer[ offset + stride + 2 ] = morphVec4.z;
                    buffer[ offset + stride + 3 ] = 0;

                }

                if ( hasMorphNormals == true ) {

                    morphVec4.fromBufferAttribute( morphNormal, j );

                    buffer[ offset + stride + 4 ] = morphVec4.x;
                    buffer[ offset + stride + 5 ] = morphVec4.y;
                    buffer[ offset + stride + 6 ] = morphVec4.z;
                    buffer[ offset + stride + 7 ] = 0;

                }

                if ( hasMorphColors == true ) {

                    morphVec4.fromBufferAttribute( morphColor, j );

                    buffer[ offset + stride + 8 ] = morphVec4.x;
                    buffer[ offset + stride + 9 ] = morphVec4.y;
                    buffer[ offset + stride + 10 ] = morphVec4.z;
                    buffer[ offset + stride + 11 ] = ( morphColor.itemSize == 4 ) ? morphVec4.w : 1;

                }

            }

        }

        entry = {
            count: morphTargetsCount,
            texture: bufferTexture,
            stride: vertexDataCount,
            size: new Vector2( width, height )
        };

        morphTextures.map.set( geometry, entry );

        function disposeTexture() {

            bufferTexture.dispose();

            morphTextures.map.delete( geometry );

            geometry.removeEventListener( 'dispose', disposeTexture );

        }

        geometry.addEventListener( 'dispose', disposeTexture );

    }

    return entry;

}


class MorphNode extends Node {

    public var mesh: Dynamic;
    public var morphBaseInfluence: Dynamic;

    public function new( mesh ) {

        super( 'void' );

        this.mesh = mesh;
        this.morphBaseInfluence = uniform( 1 );

        this.updateType = NodeUpdateType.OBJECT;

    }

    public function setup( builder ) {

        var geometry = builder.geometry;

        var hasMorphPosition = geometry.morphAttributes.position != null;
        var hasMorphNormals = geometry.morphAttributes.normal != null;

        var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
        var morphTargetsCount = ( morphAttribute != null ) ? morphAttribute.length : 0;

        // nodes

        var { texture: bufferMap, stride, size } = getEntry( geometry );

        if ( hasMorphPosition == true ) positionLocal.mulAssign( this.morphBaseInfluence );
        if ( hasMorphNormals == true ) normalLocal.mulAssign( this.morphBaseInfluence );

        var width = int( size.width );

        loop( morphTargetsCount, ( { i } ) -> {

            var influence = float( 0 ).toVar();

            if ( this.mesh.isInstancedMesh == true && ( this.mesh.morphTexture != null && this.mesh.morphTexture != undefined ) ) {

                influence.assign( textureLoad( this.mesh.morphTexture, ivec2( int( i ).add( 1 ), int( instanceIndex ) ) ).r );

            } else {

                influence.assign( reference( 'morphTargetInfluences', 'float' ).element( i ).toVar() );

            }

            if ( hasMorphPosition == true ) {

                positionLocal.addAssign( getMorph( {
                    bufferMap,
                    influence,
                    stride,
                    width,
                    depth: i,
                    offset: int( 0 )
                } ) );

            }

            if ( hasMorphNormals == true ) {

                normalLocal.addAssign( getMorph( {
                    bufferMap,
                    influence,
                    stride,
                    width,
                    depth: i,
                    offset: int( 1 )
                } ) );

            }

        } );

    }

    public function update() {

        var morphBaseInfluence = this.morphBaseInfluence;

        if ( this.mesh.geometry.morphTargetsRelative ) {

            morphBaseInfluence.value = 1;

        } else {

            morphBaseInfluence.value = 1 - this.mesh.morphTargetInfluences.reduce( ( a, b ) -> a + b, 0 );

        }

    }

}

export default MorphNode;

export var morphReference = nodeProxy( MorphNode );

addNodeClass( 'MorphNode', MorphNode );