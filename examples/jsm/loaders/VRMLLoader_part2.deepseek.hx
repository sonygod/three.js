class VRMLToASTVisitor extends BaseVRMLVisitor {

    public function new() {
        super();
        validateVisitor();
    }

    public function vrml(ctx:Context):Data {
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

    public function version(ctx:Context):String {
        return ctx.Version[0].image;
    }

    public function node(ctx:Context):Data {
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

    public function field(ctx:Context):Data {
        var data = {
            name: ctx.Identifier[0].image,
            type: null,
            values: null
        };

        var result:Result;

        if (ctx.singleFieldValue != null) {
            result = visit(ctx.singleFieldValue[0]);
        }

        if (ctx.multiFieldValue != null) {
            result = visit(ctx.multiFieldValue[0]);
        }

        data.type = result.type;
        data.values = result.values;

        return data;
    }

    public function def(ctx:Context):String {
        return (ctx.Identifier || ctx.NodeName)[0].image;
    }

    public function use(ctx:Context):Data {
        return {USE: (ctx.Identifier || ctx.NodeName)[0].image};
    }

    public function singleFieldValue(ctx:Context):Result {
        return processField(this, ctx);
    }

    public function multiFieldValue(ctx:Context):Result {
        return processField(this, ctx);
    }

    public function route(ctx:Context):Data {
        var data = {
            FROM: ctx.RouteIdentifier[0].image,
            TO: ctx.RouteIdentifier[1].image
        };

        return data;
    }
}