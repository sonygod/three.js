package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.shadernode.ShaderNode;

class D_GGX {
    public static function tslFn(alpha:Float, dotNH:Float):Float {
        var a2 = alpha * alpha;
        var denom = dotNH * dotNH * (1 - a2) + a2;
        return a2 / (denom * denom) * (1 / Math.PI);
    }

    public static function getD_GGX():ShaderNode {
        var node = new ShaderNode('D_GGX', 'float');
        node.inputs.push({ name: 'alpha', type: 'float' });
        node.inputs.push({ name: 'dotNH', type: 'float' });
        node.fn = tslFn;
        return node;
    }
}

// Export the D_GGX function
.@:keep
extern class D_GGX {
    public static var D_GGX(get, never):ShaderNode;
    public static inline function get_D_GGX():ShaderNode {
        return getD_GGX();
    }
}