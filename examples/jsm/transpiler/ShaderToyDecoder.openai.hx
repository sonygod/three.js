package three.js.examples.jsg.transpiler;

import AST.Return;
import AST.VariableDeclaration;
import AST.Accessor;

class ShaderToyDecoder extends GLSLDecoder {
    public function new() {
        super();
        addPolyfill('iTime', 'float iTime = timerGlobal();');
        addPolyfill('iResolution', 'vec2 iResolution = viewportResolution;');
        addPolyfill('fragCoord', 'vec3 fragCoord = vec3( viewportCoordinate.x, viewportResolution.y - viewportCoordinate.y, viewportCoordinate.z );');
    }

    override function parseFunction():AST.Function {
        var node = super.parseFunction();

        if (node.name == 'mainImage') {
            node.params = []; // remove default parameters
            node.type = 'vec4';
            node.layout = false; // for now

            var fragColor = new Accessor('fragColor');

            for (subNode in node.body) {
                if (Std.isOfType(subNode, Return)) {
                    subNode.value = fragColor;
                }
            }

            node.body.unshift(new VariableDeclaration('vec4', 'fragColor'));
            node.body.push(new Return(fragColor));
        }

        return node;
    }
}