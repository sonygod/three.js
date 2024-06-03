import GLSLDecoder;

class ShaderToyDecoder extends GLSLDecoder {
    public function new() {
        super();

        this.addPolyfill("iTime", "var iTime:Float = timerGlobal();");
        this.addPolyfill("iResolution", "var iResolution:Vec2 = viewportResolution;");
        this.addPolyfill("fragCoord", "var fragCoord:Vec3 = new Vec3(viewportCoordinate.x, viewportResolution.y - viewportCoordinate.y, viewportCoordinate.z);");
    }

    override public function parseFunction():ASTNode {
        var node:ASTNode = super.parseFunction();

        if (node.name == "mainImage") {
            node.params = []; // remove default parameters
            node.type = "Vec4";
            node.layout = false; // for now

            var fragColor:Accessor = new Accessor("fragColor");

            for (subNode in node.body) {
                if (subNode is Return) {
                    subNode.value = fragColor;
                }
            }

            node.body.unshift(new VariableDeclaration("Vec4", "fragColor"));
            node.body.push(new Return(fragColor));
        }

        return node;
    }
}