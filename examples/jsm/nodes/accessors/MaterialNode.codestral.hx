import js.Browser;
import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.accessors.ReferenceNode;
import three.examples.jsm.nodes.accessors.MaterialReferenceNode;
import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.core.UniformNode;
import three.math.Vector2;

class MaterialNode extends Node {
    private var _scope:String;
    private static var _propertyCache:Map<String, Node> = new Map<String, Node>();

    public function new(scope:String) {
        super();
        this._scope = scope;
    }

    public function getCache(property:String, type:String):Node {
        var node = _propertyCache.get(property);
        if(node == null) {
            node = MaterialReferenceNode.materialReference(property, type);
            _propertyCache.set(property, node);
        }
        return node;
    }

    public function getFloat(property:String):Node {
        return this.getCache(property, 'float');
    }

    public function getColor(property:String):Node {
        return this.getCache(property, 'color');
    }

    public function getTexture(property:String):Node {
        return this.getCache(property == 'map' ? 'map' : property + 'Map', 'texture');
    }

    public function setup(builder:Builder):Node {
        var material = builder.context.material;
        var scope = this._scope;
        var node:Node = null;

        switch(scope) {
            case MaterialNode.COLOR:
                var colorNode = this.getColor(scope);
                if(material.map != null && Browser.hasField(material.map, 'isTexture')) {
                    node = colorNode.mul(this.getTexture('map'));
                } else {
                    node = colorNode;
                }
                break;

            // Add the rest of the cases here, following the same pattern.
            // Note that Haxe does not support the same switch case fallthrough feature as JavaScript, so you'll need to copy the common code for each case.
        }

        return node;
    }

    // Add the rest of the class methods and properties here, following the same pattern.
}

// Add the static properties here, following the same pattern.

ShaderNode.addNodeClass('MaterialNode', MaterialNode);