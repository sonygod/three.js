import threejs.nodes.Nodes.MathNode;
import threejs.nodes.Nodes.GLSLNodeParser;
import threejs.nodes.Nodes.NodeBuilder;
import threejs.nodes.Nodes.UniformNode;
import threejs.nodes.Nodes.vectorComponents;

import threejs.renderers.webgl.common.nodes.NodeUniformBuffer;
import threejs.renderers.webgl.common.nodes.NodeUniformsGroup;

import threejs.renderers.webgl.common.nodes.NodeSampledTexture;

import threejs.textures.TextureConstants.RedFormat;
import threejs.textures.TextureConstants.RGFormat;
import threejs.textures.TextureConstants.IntType;
import threejs.textures.DataTexture;
import threejs.textures.TextureConstants.RGBFormat;
import threejs.textures.TextureConstants.RGBAFormat;
import threejs.textures.TextureConstants.FloatType;

class GLSLNodeBuilder extends NodeBuilder {
    public static var glslMethods:Map<String, String> = new Map<String, String>();
    static {
        glslMethods.set(MathNode.ATAN2, "atan");
        glslMethods.set("textureDimensions", "textureSize");
        glslMethods.set("equals", "equal");
    }

    public static var precisionLib:Map<String, String> = new Map<String, String>();
    static {
        precisionLib.set("low", "lowp");
        precisionLib.set("medium", "mediump");
        precisionLib.set("high", "highp");
    }

    public static var supports:Map<String, Bool> = new Map<String, Bool>();
    static {
        supports.set("instance", true);
        supports.set("swizzleAssign", true);
    }

    public static var defaultPrecisions:String = "precision highp float;\n" +
                                                 "precision highp int;\n" +
                                                 "precision mediump sampler2DArray;\n" +
                                                 "precision lowp sampler2DShadow;\n";

    public var uniformGroups:Map<String, Dynamic> = new haxe.ds.StringMap<Dynamic>();
    public var transforms:Array<Dynamic> = [];

    public function new(object:Dynamic, renderer:Dynamic, scene:Dynamic = null) {
        super(object, renderer, new GLSLNodeParser(), scene);
    }

    public function getMethod(method:String):String {
        return glslMethods.get(method) ?? method;
    }

    public override function getPropertyName(node:Dynamic, shaderStage:String):String {
        if (node.isOutputStructVar) return "";
        return super.getPropertyName(node, shaderStage);
    }

    public function buildFunctionCode(shaderNode:Dynamic):String {
        // Implement the method according to the JavaScript code
    }

    public function setupPBO(storageBufferNode:Dynamic):Void {
        // Implement the method according to the JavaScript code
    }

    public function generatePBO(storageArrayElementNode:Dynamic):String {
        // Implement the method according to the JavaScript code
        return "";
    }

    // Add other methods here...
}