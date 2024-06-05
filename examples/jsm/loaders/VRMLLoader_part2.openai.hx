package three.js.examples.jsm.loaders;

import three.js.examples.jsm.loaders.BaseVRMLVisitor;

class VRMLToASTVisitor extends BaseVRMLVisitor {
    
    public function new() {
        super();
        validateVisitor();
    }

    public function vrml(ctx:Any):Dynamic {
        var data = {
            version: visit(ctx.version),
            nodes: [],
            routes: []
        };

        for (i in 0...ctx.node.length) {
            var node = ctx.node[i];
            data.nodes.push(visit(node));
        }

        if (ctx.route != null) {
            for (i in 0...ctx.route.length) {
                var route = ctx.route[i];
                data.routes.push(visit(route));
            }
        }

        return data;
    }

    public function version(ctx:Any):String {
        return ctx.Version[0].image;
    }

    public function node(ctx:Any):Dynamic {
        var data = {
            name: ctx.NodeName[0].image,
            fields: []
        };

        if (ctx.field != null) {
            for (i in 0...ctx.field.length) {
                var field = ctx.field[i];
                data.fields.push(visit(field));
            }
        }

        if (ctx.def != null) {
            data.DEF = visit(ctx.def[0]);
        }

        return data;
    }

    public function field(ctx:Any):Dynamic {
        var data = {
            name: ctx.Identifier[0].image,
            type: null,
            values: null
        };

        var result:Any;

        if (ctx.singleFieldValue != null) {
            result = visit(ctx.singleFieldValue[0]);
        } else if (ctx.multiFieldValue != null) {
            result = visit(ctx.multiFieldValue[0]);
        }

        data.type = result.type;
        data.values = result.values;

        return data;
    }

    public function def(ctx:Any):String {
        return (ctx.Identifier != null) ? ctx.Identifier[0].image : ctx.NodeName[0].image;
    }

    public function use(ctx:Any):Dynamic {
        return { USE: (ctx.Identifier != null) ? ctx.Identifier[0].image : ctx.NodeName[0].image };
    }

    public function singleFieldValue(ctx:Any):Dynamic {
        return processField(this, ctx);
    }

    public function multiFieldValue(ctx:Any):Dynamic {
        return processField(this, ctx);
    }

    public function route(ctx:Any):Dynamic {
        var data = {
            FROM: ctx.RouteIdentifier[0].image,
            TO: ctx.RouteIdentifier[1].image
        };

        return data;
    }
}