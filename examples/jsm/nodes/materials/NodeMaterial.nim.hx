import Material from 'three';
import { getNodeChildren, getCacheKey } from '../core/NodeUtils.hx';
import { attribute } from '../core/AttributeNode.hx';
import { output, diffuseColor, varyingProperty } from '../core/PropertyNode.hx';
import { materialAlphaTest, materialColor, materialOpacity, materialEmissive, materialNormal } from '../accessors/MaterialNode.hx';
import { modelViewProjection } from '../accessors/ModelViewProjectionNode.hx';
import { transformedNormalView, normalLocal } from '../accessors/NormalNode.hx';
import { instance } from '../accessors/InstanceNode.hx';
import { batch } from '../accessors/BatchNode.hx';
import { materialReference } from '../accessors/MaterialReferenceNode.hx';
import { positionLocal, positionView } from '../accessors/PositionNode.hx';
import { skinningReference } from '../accessors/SkinningNode.hx';
import { morphReference } from '../accessors/MorphNode.hx';
import { texture } from '../accessors/TextureNode.hx';
import { cubeTexture } from '../accessors/CubeTextureNode.hx';
import { lightsNode } from '../lighting/LightsNode.hx';
import { mix } from '../math/MathNode.hx';
import { float, vec3, vec4 } from '../shadernode/ShaderNode.hx';
import AONode from '../lighting/AONode.hx';
import { lightingContext } from '../lighting/LightingContextNode.hx';
import EnvironmentNode from '../lighting/EnvironmentNode.hx';
import IrradianceNode from '../lighting/IrradianceNode.hx';
import { depthPixel } from '../display/ViewportDepthNode.hx';
import { cameraLogDepth } from '../accessors/CameraNode.hx';
import { clipping, clippingAlpha } from '../accessors/ClippingNode.hx';
import { faceDirection } from '../display/FrontFacingNode.hx';

class NodeMaterials {
    public static var map:Map<String, Dynamic>;
}

class NodeMaterial extends Material {

    public function new() {

        super();

        this.isNodeMaterial = true;

        this.type = this.constructor.type;

        this.forceSinglePass = false;

        this.fog = true;
        this.lights = true;
        this.normals = true;

        this.lightsNode = null;
        this.envNode = null;
        this.aoNode = null;

        this.colorNode = null;
        this.normalNode = null;
        this.opacityNode = null;
        this.backdropNode = null;
        this.backdropAlphaNode = null;
        this.alphaTestNode = null;

        this.positionNode = null;

        this.depthNode = null;
        this.shadowNode = null;
        this.shadowPositionNode = null;

        this.outputNode = null;

        this.fragmentNode = null;
        this.vertexNode = null;

    }

    public function customProgramCacheKey():String {

        return this.type + getCacheKey( this );

    }

    public function build( builder:Dynamic ) {

        this.setup( builder );

    }

    public function setup( builder:Dynamic ) {

        // < VERTEX STAGE >

        builder.addStack();

        builder.stack.outputNode = this.vertexNode || this.setupPosition( builder );

        builder.addFlow( 'vertex', builder.removeStack() );

        // < FRAGMENT STAGE >

        builder.addStack();

        var resultNode;

        const clippingNode = this.setupClipping( builder );

        if ( this.depthWrite === true ) this.setupDepth( builder );

        if ( this.fragmentNode === null ) {

            if ( this.normals === true ) this.setupNormal( builder );

            this.setupDiffuseColor( builder );
            this.setupVariants( builder );

            const outgoingLightNode = this.setupLighting( builder );

            if ( clippingNode !== null ) builder.stack.add( clippingNode );

            // force unsigned floats - useful for RenderTargets

            const basicOutput = vec4( outgoingLightNode, diffuseColor.a ).max( 0 );

            resultNode = this.setupOutput( builder, basicOutput );

            // OUTPUT NODE

            output.assign( resultNode );

            //

            if ( this.outputNode !== null ) resultNode = this.outputNode;

        } else {

            var fragmentNode = this.fragmentNode;

            if ( fragmentNode.isOutputStructNode !== true ) {

                fragmentNode = vec4( fragmentNode );

            }

            resultNode = this.setupOutput( builder, fragmentNode );

        }

        builder.stack.outputNode = resultNode;

        builder.addFlow( 'fragment', builder.removeStack() );

    }

    public function setupClipping( builder:Dynamic ):Dynamic {

        if ( builder.clippingContext === null ) return null;

        const { globalClippingCount, localClippingCount } = builder.clippingContext;

        var result = null;

        if ( globalClippingCount || localClippingCount ) {

            if ( this.alphaToCoverage ) {

                // to be added to flow when the color/alpha value has been determined
                result = clippingAlpha();

            } else {

                builder.stack.add( clipping() );

            }

        }

        return result;

    }

    public function setupDepth( builder:Dynamic ) {

        const { renderer } = builder;

        // Depth

        var depthNode = this.depthNode;

        if ( depthNode === null && renderer.logarithmicDepthBuffer === true ) {

            const fragDepth = modelViewProjection().w.add( 1 );

            depthNode = fragDepth.log2().mul( cameraLogDepth ).mul( 0.5 );

        }

        if ( depthNode !== null ) {

            depthPixel.assign( depthNode ).append();

        }

    }

    public function setupPosition( builder:Dynamic ) {

        const { object } = builder;
        const geometry = object.geometry;

        builder.addStack();

        // Vertex

        if ( geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color ) {

            morphReference( object ).append();

        }

        if ( object.isSkinnedMesh === true ) {

            skinningReference( object ).append();

        }

        if ( this.displacementMap ) {

            const displacementMap = materialReference( 'displacementMap', 'texture' );
            const displacementScale = materialReference( 'displacementScale', 'float' );
            const displacementBias = materialReference( 'displacementBias', 'float' );

            positionLocal.addAssign( normalLocal.normalize().mul( ( displacementMap.x.mul( displacementScale ).add( displacementBias ) ) ) );

        }

        if ( object.isBatchedMesh ) {

            batch( object ).append();

        }

        if ( ( object.instanceMatrix && object.instanceMatrix.isInstancedBufferAttribute === true ) && builder.isAvailable( 'instance' ) === true ) {

            instance( object ).append();

        }

        if ( this.positionNode !== null ) {

            positionLocal.assign( this.positionNode );

        }

        const mvp = modelViewProjection();

        builder.context.vertex = builder.removeStack();
        builder.context.mvp = mvp;

        return mvp;

    }

    public function setupDiffuseColor( builder:Dynamic ) {

        var colorNode = this.colorNode ? vec4( this.colorNode ) : materialColor;

        // VERTEX COLORS

        if ( this.vertexColors === true && geometry.hasAttribute( 'color' ) ) {

            colorNode = vec4( colorNode.xyz.mul( attribute( 'color', 'vec3' ) ), colorNode.a );

        }

        // Instanced colors

        if ( object.instanceColor ) {

            const instanceColor = varyingProperty( 'vec3', 'vInstanceColor' );

            colorNode = instanceColor.mul( colorNode );

        }

        // COLOR

        diffuseColor.assign( colorNode );

        // OPACITY

        const opacityNode = this.opacityNode ? float( this.opacityNode ) : materialOpacity;
        diffuseColor.a.assign( diffuseColor.a.mul( opacityNode ) );

        // ALPHA TEST

        if ( this.alphaTestNode !== null || this.alphaTest > 0 ) {

            const alphaTestNode = this.alphaTestNode !== null ? float( this.alphaTestNode ) : materialAlphaTest;

            diffuseColor.a.lessThanEqual( alphaTestNode ).discard();

        }

    }

    public function setupVariants( /*builder*/ ) {

        // Interface function.

    }

    public function setupNormal() {

        // NORMAL VIEW

        if ( this.flatShading === true ) {

            const normalNode = positionView.dFdx().cross( positionView.dFdy() ).normalize();

            transformedNormalView.assign( normalNode.mul( faceDirection ) );

        } else {

            const normalNode = this.normalNode ? vec3( this.normalNode ) : materialNormal;

            transformedNormalView.assign( normalNode.mul( faceDirection ) );

        }

    }

    public function getEnvNode( builder:Dynamic ):Dynamic {

        var node = null;

        if ( this.envNode ) {

            node = this.envNode;

        } else if ( this.envMap ) {

            node = this.envMap.isCubeTexture ? cubeTexture( this.envMap ) : texture( this.envMap );

        } else if ( builder.environmentNode ) {

            node = builder.environmentNode;

        }

        return node;

    }

    public function setupLights( builder:Dynamic ):Dynamic {

        const envNode = this.getEnvNode( builder );

        //

        const materialLightsNode:Array<Dynamic> = [];

        if ( envNode ) {

            materialLightsNode.push( new EnvironmentNode( envNode ) );

        }

        if ( builder.material.lightMap ) {

            materialLightsNode.push( new IrradianceNode( materialReference( 'lightMap', 'texture' ) ) );

        }

        if ( this.aoNode !== null || builder.material.aoMap ) {

            const aoNode = this.aoNode !== null ? this.aoNode : texture( builder.material.aoMap );

            materialLightsNode.push( new AONode( aoNode ) );

        }

        var lightsN = this.lightsNode || builder.lightsNode;

        if ( materialLightsNode.length > 0 ) {

            lightsN = lightsNode( [ ...lightsN.lightNodes, ...materialLightsNode ] );

        }

        return lightsN;

    }

    public function setupLightingModel( /*builder*/ ) {

        // Interface function.

    }

    public function setupLighting( builder:Dynamic ) {

        const { material } = builder;
        const { backdropNode, backdropAlphaNode, emissiveNode } = this;

        // OUTGOING LIGHT

        const lights = this.lights === true || this.lightsNode !== null;

        const lightsNode = lights ? this.setupLights( builder ) : null;

        var outgoingLightNode = diffuseColor.rgb;

        if ( lightsNode && lightsNode.hasLight !== false ) {

            const lightingModel = this.setupLightingModel( builder );

            outgoingLightNode = lightingContext( lightsNode, lightingModel, backdropNode, backdropAlphaNode );

        } else if ( backdropNode !== null ) {

            outgoingLightNode = vec3( backdropAlphaNode !== null ? mix( outgoingLightNode, backdropNode, backdropAlphaNode ) : backdropNode );

        }

        // EMISSIVE

        if ( ( emissiveNode && emissiveNode.isNode === true ) || ( material.emissive && material.emissive.isColor === true ) ) {

            outgoingLightNode = outgoingLightNode.add( vec3( emissiveNode ? emissiveNode : materialEmissive ) );

        }

        return outgoingLightNode;

    }

    public function setupOutput( builder:Dynamic, outputNode:Dynamic ) {

        // FOG

        const fogNode = builder.fogNode;

        if ( fogNode ) outputNode = vec4( fogNode.mix( outputNode.rgb, fogNode.colorNode ), outputNode.a );

        return outputNode;

    }

    public function setDefaultValues( material:Dynamic ) {

        // This approach is to reuse the native refreshUniforms*
        // and turn available the use of features like transmission and environment in core

        for ( var property in material ) {

            var value = material[ property ];

            if ( this[ property ] === undefined ) {

                this[ property ] = value;

                if ( value && value.clone ) this[ property ] = value.clone();

            }

        }

        const descriptors = Reflect.field( material.constructor.prototype );

        for ( var key in descriptors ) {

            if ( Reflect.field( this.constructor.prototype, key ) === undefined &&
                 descriptors[ key ].get !== undefined ) {

                Reflect.setField( this.constructor.prototype, key, descriptors[ key ] );

            }

        }

    }

    public function toJSON( meta:Dynamic ) {

        const isRoot = ( meta === undefined || typeof meta === 'string' );

        if ( isRoot ) {

            meta = {
                textures: {},
                images: {},
                nodes: {}
            };

        }

        const data = Material.prototype.toJSON.call( this, meta );
        const nodeChildren = getNodeChildren( this );

        data.inputNodes = {};

        for ( var { property, childNode } of nodeChildren ) {

            data.inputNodes[ property ] = childNode.toJSON( meta ).uuid;

        }

        // TODO: Copied from Object3D.toJSON

        function extractFromCache( cache:Dynamic ) {

            const values:Array<Dynamic> = [];

            for ( var key in cache ) {

                const data = cache[ key ];
                delete data.metadata;
                values.push( data );

            }

            return values;

        }

        if ( isRoot ) {

            const textures = extractFromCache( meta.textures );
            const images = extractFromCache( meta.images );
            const nodes = extractFromCache( meta.nodes );

            if ( textures.length > 0 ) data.textures = textures;
            if ( images.length > 0 ) data.images = images;
            if ( nodes.length > 0 ) data.nodes = nodes;

        }

        return data;

    }

    public function copy( source:Dynamic ) {

        this.lightsNode = source.lightsNode;
        this.envNode = source.envNode;

        this.colorNode = source.colorNode;
        this.normalNode = source.normalNode;
        this.opacityNode = source.opacityNode;
        this.backdropNode = source.backdropNode;
        this.backdropAlphaNode = source.backdropAlphaNode;
        this.alphaTestNode = source.alphaTestNode;

        this.positionNode = source.positionNode;

        this.depthNode = source.depthNode;
        this.shadowNode = source.shadowNode;
        this.shadowPositionNode = source.shadowPositionNode;

        this.outputNode = source.outputNode;

        this.fragmentNode = source.fragmentNode;
        this.vertexNode = source.vertexNode;

        return super.copy( source );

    }

    public static function fromMaterial( material:Dynamic ) {

        if ( material.isNodeMaterial === true ) { // is already a node material

            return material;

        }

        const type = material.type.replace( 'Material', 'NodeMaterial' );

        const nodeMaterial = createNodeMaterialFromType( type );

        if ( nodeMaterial === undefined ) {

            throw new Error( `NodeMaterial: Material "${ material.type }" is not compatible.` );

        }

        for ( var key in material ) {

            nodeMaterial[ key ] = material[ key ];

        }

        return nodeMaterial;

    }

}

NodeMaterials.map = new Map<String, Dynamic>();

export default NodeMaterial;

export function addNodeMaterial( type:String, nodeMaterial:Dynamic ) {

    if ( typeof nodeMaterial !== 'function' || ! type ) throw new Error( `Node material ${ type } is not a class` );
    if ( NodeMaterials.map.has( type ) ) {

        console.warn( `Redefinition of node material ${ type }` );
        return;

    }

    NodeMaterials.map.set( type, nodeMaterial );
    nodeMaterial.type = type;

}

export function createNodeMaterialFromType( type:String ):Dynamic {

    const Material = NodeMaterials.map.get( type );

    if ( Material !== undefined ) {

        return new Material();

    }

}

addNodeMaterial( 'NodeMaterial', NodeMaterial );