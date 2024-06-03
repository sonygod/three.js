class VRMLToASTVisitor extends BaseVRMLVisitor {

    public function new() {
        super();
        this.validateVisitor();
    }

    public function vrml(ctx:Dynamic):Dynamic {
        var data = {
            version: this.visit(ctx.version),
            nodes: [],
            routes: []
        };

        for (var i:Int = 0; i < ctx.node.length; i++) {
            var node = ctx.node[i];
            data.nodes.push(this.visit(node));
        }

        if (ctx.route != null) {
            for (var i:Int = 0; i < ctx.route.length; i++) {
                var route = ctx.route[i];
                data.routes.push(this.visit(route));
            }
        }

        return data;
    }

    public function version(ctx:Dynamic):String {
        return ctx.Version[0].image;
    }

    public function node(ctx:Dynamic):Dynamic {
        var data = {
            name: ctx.NodeName[0].image,
            fields: []
        };

        if (ctx.field != null) {
            for (var i:Int = 0; i < ctx.field.length; i++) {
                var field = ctx.field[i];
                data.fields.push(this.visit(field));
            }
        }

        if (ctx.def != null) {
            data.DEF = this.visit(ctx.def[0]);
        }

        return data;
    }

    public function field(ctx:Dynamic):Dynamic {
        var data = {
            name: ctx.Identifier[0].image,
            type: null,
            values: null
        };

        var result:Dynamic;

        if (ctx.singleFieldValue != null) {
            result = this.visit(ctx.singleFieldValue[0]);
        }

        if (ctx.multiFieldValue != null) {
            result = this.visit(ctx.multiFieldValue[0]);
        }

        data.type = result.type;
        data.values = result.values;

        return data;
    }

    public function def(ctx:Dynamic):String {
        return (ctx.Identifier != null ? ctx.Identifier : ctx.NodeName)[0].image;
    }

    public function use(ctx:Dynamic):Dynamic {
        return { USE: (ctx.Identifier != null ? ctx.Identifier : ctx.NodeName)[0].image };
    }

    public function singleFieldValue(ctx:Dynamic):Dynamic {
        return processField(this, ctx);
    }

    public function multiFieldValue(ctx:Dynamic):Dynamic {
        return processField(this, ctx);
    }

    public function route(ctx:Dynamic):Dynamic {
        var data = {
            FROM: ctx.RouteIdentifier[0].image,
            TO: ctx.RouteIdentifier[1].image
        };

        return data;
    }
}