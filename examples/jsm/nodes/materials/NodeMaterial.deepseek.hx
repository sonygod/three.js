import three.Material;
import three.jsm.nodes.core.NodeUtils.*;
import three.jsm.nodes.core.AttributeNode.*;
import three.jsm.nodes.core.PropertyNode.*;
import three.jsm.nodes.accessors.MaterialNode.*;
import three.jsm.nodes.accessors.ModelViewProjectionNode.*;
import three.jsm.nodes.accessors.NormalNode.*;
import three.jsm.nodes.accessors.InstanceNode.*;
import three.jsm.nodes.accessors.BatchNode.*;
import three.jsm.nodes.accessors.MaterialReferenceNode.*;
import three.jsm.nodes.accessors.PositionNode.*;
import three.jsm.nodes.accessors.CameraNode.*;
import three.jsm.nodes.lighting.AONode.*;
import three.jsm.nodes.lighting.LightingContextNode.*;
import three.jsm.nodes.lighting.EnvironmentNode.*;
import three.jsm.nodes.lighting.IrradianceNode.*;
import three.jsm.nodes.display.ViewportDepthNode.*;
import three.jsm.nodes.accessors.ClippingNode.*;
import three.jsm.nodes.display.FrontFacingNode.*;
import three.jsm.shadernode.ShaderNode.*;

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
        return this.type + getCacheKey(this);
    }

    public function build(builder:Builder):Void {
        this.setup(builder);
    }

    public function setup(builder:Builder):Void {
        // < VERTEX STAGE >
        builder.addStack();
        builder.stack.outputNode = this.vertexNode || this.setupPosition(builder);
        builder.addFlow('vertex', builder.removeStack());
        // < FRAGMENT STAGE >
        builder.addStack();
        var resultNode:ShaderNode;
        var clippingNode = this.setupClipping(builder);
        if (this.depthWrite === true) this.setupDepth(builder);
        if (this.fragmentNode === null) {
            if (this.normals === true) this.setupNormal(builder);
            this.setupDiffuseColor(builder);
            this.setupVariants(builder);
            var outgoingLightNode = this.setupLighting(builder);
            if (clippingNode !== null) builder.stack.add(clippingNode);
            // force unsigned floats - useful for RenderTargets
            var basicOutput = vec4(outgoingLightNode, diffuseColor.a).max(0);
            resultNode = this.setupOutput(builder, basicOutput);
            // OUTPUT NODE
            output.assign(resultNode);
            //
            if (this.outputNode !== null) resultNode = this.outputNode;
        } else {
            var fragmentNode = this.fragmentNode;
            if (fragmentNode.isOutputStructNode !== true) {
                fragmentNode = vec4(fragmentNode);
            }
            resultNode = this.setupOutput(builder, fragmentNode);
        }
        builder.stack.outputNode = resultNode;
        builder.addFlow('fragment', builder.removeStack());
    }

    public function setupClipping(builder:Builder):ShaderNode {
        if (builder.clippingContext === null) return null;
        var globalClippingCount = builder.clippingContext.globalClippingCount;
        var localClippingCount = builder.clippingContext.localClippingCount;
        var result = null;
        if (globalClippingCount || localClippingCount) {
            if (this.alphaToCoverage) {
                // to be added to flow when the color/alpha value has been determined
                result = clippingAlpha();
            } else {
                builder.stack.add(clipping());
            }
        }
        return result;
    }

    public function setupDepth(builder:Builder):Void {
        var renderer = builder.renderer;
        // Depth
        var depthNode = this.depthNode;
        if (depthNode === null && renderer.logarithmicDepthBuffer === true) {
            var fragDepth = modelViewProjection().w.add(1);
            depthNode = fragDepth.log2().mul(cameraLogDepth).mul(0.5);
        }
        if (depthNode !== null) {
            depthPixel.assign(depthNode).append();
        }
    }

    public function setupPosition(builder:Builder):ShaderNode {
        var object = builder.object;
        var geometry = object.geometry;
        builder.addStack();
        // Vertex
        if (geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color) {
            morphReference(object).append();
        }
        if (object.isSkinnedMesh === true) {
            skinningReference(object).append();
        }
        if (this.displacementMap) {
            var displacementMap = materialReference('displacementMap', 'texture');
            var displacementScale = materialReference('displacementScale', 'float');
            var displacementBias = materialReference('displacementBias', 'float');
            positionLocal.addAssign(normalLocal.normalize().mul((displacementMap.x.mul(displacementScale).add(displacementBias))));
        }
        if (object.isBatchedMesh) {
            batch(object).append();
        }
        if ((object.instanceMatrix && object.instanceMatrix.isInstancedBufferAttribute === true) && builder.isAvailable('instance') === true) {
            instance(object).append();
        }
        if (this.positionNode !== null) {
            positionLocal.assign(this.positionNode);
        }
        var mvp = modelViewProjection();
        builder.context.vertex = builder.removeStack();
        builder.context.mvp = mvp;
        return mvp;
    }

    public function setupDiffuseColor(builder:Builder):Void {
        var object = builder.object;
        var geometry = object.geometry;
        var colorNode = this.colorNode ? vec4(this.colorNode) : materialColor;
        // VERTEX COLORS
        if (this.vertexColors === true && geometry.hasAttribute('color')) {
            colorNode = vec4(colorNode.xyz.mul(attribute('color', 'vec3')), colorNode.a);
        }
        // Instanced colors
        if (object.instanceColor) {
            var instanceColor = varyingProperty('vec3', 'vInstanceColor');
            colorNode = instanceColor.mul(colorNode);
        }
        // COLOR
        diffuseColor.assign(colorNode);
        // OPACITY
        var opacityNode = this.opacityNode ? float(this.opacityNode) : materialOpacity;
        diffuseColor.a.assign(diffuseColor.a.mul(opacityNode));
        // ALPHA TEST
        if (this.alphaTestNode !== null || this.alphaTest > 0) {
            var alphaTestNode = this.alphaTestNode !== null ? float(this.alphaTestNode) : materialAlphaTest;
            diffuseColor.a.lessThanEqual(alphaTestNode).discard();
        }
    }

    public function setupVariants(/*builder*/):Void {
        // Interface function.
    }

    public function setupNormal():Void {
        // NORMAL VIEW
        if (this.flatShading === true) {
            var normalNode = positionView.dFdx().cross(positionView.dFdy()).normalize();
            transformedNormalView.assign(normalNode.mul(faceDirection));
        } else {
            var normalNode = this.normalNode ? vec3(this.normalNode) : materialNormal;
            transformedNormalView.assign(normalNode.mul(faceDirection));
        }
    }

    public function getEnvNode(builder:Builder):ShaderNode {
        var node = null;
        if (this.envNode) {
            node = this.envNode;
        } else if (this.envMap) {
            node = this.envMap.isCubeTexture ? cubeTexture(this.envMap) : texture(this.envMap);
        } else if (builder.environmentNode) {
            node = builder.environmentNode;
        }
        return node;
    }

    public function setupLights(builder:Builder):ShaderNode {
        var envNode = this.getEnvNode(builder);
        //
        var materialLightsNode = [];
        if (envNode) {
            materialLightsNode.push(new EnvironmentNode(envNode));
        }
        if (builder.material.lightMap) {
            materialLightsNode.push(new IrradianceNode(materialReference('lightMap', 'texture')));
        }
        if (this.aoNode !== null || builder.material.aoMap) {
            var aoNode = this.aoNode !== null ? this.aoNode : texture(builder.material.aoMap);
            materialLightsNode.push(new AONode(aoNode));
        }
        var lightsN = this.lightsNode || builder.lightsNode;
        if (materialLightsNode.length > 0) {
            lightsN = lightsNode([...lightsN.lightNodes, ...materialLightsNode]);
        }
        return lightsN;
    }

    public function setupLightingModel(/*builder*/):ShaderNode {
        // Interface function.
    }

    public function setupLighting(builder:Builder):ShaderNode {
        var material = builder.material;
        var backdropNode = this.backdropNode;
        var backdropAlphaNode = this.backdropAlphaNode;
        var emissiveNode = this.emissiveNode;
        // OUTGOING LIGHT
        var lights = this.lights === true || this.lightsNode !== null;
        var lightsNode = lights ? this.setupLights(builder) : null;
        var outgoingLightNode = diffuseColor.rgb;
        if (lightsNode && lightsNode.hasLight !== false) {
            var lightingModel = this.setupLightingModel(builder);
            outgoingLightNode = lightingContext(lightsNode, lightingModel, backdropNode, backdropAlphaNode);
        } else if (backdropNode !== null) {
            outgoingLightNode = vec3(backdropAlphaNode !== null ? mix(outgoingLightNode, backdropNode, backdropAlphaNode) : backdropNode);
        }
        // EMISSIVE
        if ((emissiveNode && emissiveNode.isNode === true) || (material.emissive && material.emissive.isColor === true)) {
            outgoingLightNode = outgoingLightNode.add(vec3(emissiveNode ? emissiveNode : materialEmissive));
        }
        return outgoingLightNode;
    }

    public function setupOutput(builder:Builder, outputNode:ShaderNode):ShaderNode {
        // FOG
        var fogNode = builder.fogNode;
        if (fogNode) outputNode = vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);
        return outputNode;
    }

    public function setDefaultValues(material:Material):Void {
        // This approach is to reuse the native refreshUniforms*
        // and turn available the use of features like transmission and environment in core
        for (property in material) {
            var value = material[property];
            if (this[property] === undefined) {
                this[property] = value;
                if (value && value.clone) this[property] = value.clone();
            }
        }
        var descriptors = Object.getOwnPropertyDescriptors(material.constructor.prototype);
        for (key in descriptors) {
            if (Object.getOwnPropertyDescriptor(this.constructor.prototype, key) === undefined && descriptors[key].get !== undefined) {
                Object.defineProperty(this.constructor.prototype, key, descriptors[key]);
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRoot = (meta === undefined || typeof meta === 'string');
        if (isRoot) {
            meta = {
                textures: {},
                images: {},
                nodes: {}
            };
        }
        var data = Material.prototype.toJSON.call(this, meta);
        var nodeChildren = getNodeChildren(this);
        data.inputNodes = {};
        for (childNode in nodeChildren) {
            data.inputNodes[property] = childNode.toJSON(meta).uuid;
        }
        // TODO: Copied from Object3D.toJSON
        function extractFromCache(cache:Dynamic):Array<Dynamic> {
            var values = [];
            for (key in cache) {
                var data = cache[key];
                delete data.metadata;
                values.push(data);
            }
            return values;
        }
        if (isRoot) {
            var textures = extractFromCache(meta.textures);
            var images = extractFromCache(meta.images);
            var nodes = extractFromCache(meta.nodes);
            if (textures.length > 0) data.textures = textures;
            if (images.length > 0) data.images = images;
            if (nodes.length > 0) data.nodes = nodes;
        }
        return data;
    }

    public function copy(source:NodeMaterial):NodeMaterial {
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
        return super.copy(source);
    }

    public static function fromMaterial(material:Material):NodeMaterial {
        if (material.isNodeMaterial === true) { // is already a node material
            return material;
        }
        var type = material.type.replace('Material', 'NodeMaterial');
        var nodeMaterial = createNodeMaterialFromType(type);
        if (nodeMaterial === undefined) {
            throw new Error(`NodeMaterial: Material "${material.type}" is not compatible.`);
        }
        for (key in material) {
            nodeMaterial[key] = material[key];
        }
        return nodeMaterial;
    }

    public static function addNodeMaterial(type:String, nodeMaterial:Class<NodeMaterial>):Void {
        if (typeof nodeMaterial !== 'function' || !type) throw new Error(`Node material ${type} is not a class`);
        if (NodeMaterials.has(type)) {
            console.warn(`Redefinition of node material ${type}`);
            return;
        }
        NodeMaterials.set(type, nodeMaterial);
        nodeMaterial.type = type;
    }

    public static function createNodeMaterialFromType(type:String):NodeMaterial {
        var Material = NodeMaterials.get(type);
        if (Material !== undefined) {
            return new Material();
        }
    }

    static function main():Void {
        addNodeMaterial('NodeMaterial', NodeMaterial);
    }
}