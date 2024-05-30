class VRMLToASTVisitor extends BaseVRMLVisitor {
	public function new() {
		super();
		validateVisitor();
	}

	public function vrml(ctx: Context) {
		var data = { version: visit(ctx.version) as String, nodes: [], routes: [] };

		for (node in ctx.node) {
			data.nodes.push(visit(node));
		}

		if (ctx.route != null) {
			for (route in ctx.route) {
				data.routes.push(visit(route));
			}
		}

		return data;
	}

	private function version(ctx: Context) {
		return ctx.Version[0].image;
	}

	private function node(ctx: Context) {
		var data = { name: ctx.NodeName[0].image, fields: [] };

		for (field in ctx.field) {
			data.fields.push(visit(field));
		}

		if (ctx.def != null) {
			data.DEF = visit(ctx.def[0]);
		}

		return data;
	}

	private function field(ctx: Context) {
		var data = { name: ctx.Identifier[0].image, type: null, values: null };
		var result: { type: String, values: Array<Dynamic> };

		if (ctx.singleFieldValue != null) {
			result = visit(ctx.singleFieldValue[0]);
		} else if (ctx.multiFieldValue != null) {
			result = visit(ctx.multiFieldValue[0]);
		}

		data.type = result.type;
		data.values = result.values;

		return data;
	}

	private function def(ctx: Context) {
		return (ctx.Identifier != null ? ctx.Identifier[0] : ctx.NodeName[0]).image;
	}

	private function use(ctx: Context) {
		return { USE: (ctx.Identifier != null ? ctx.Identifier[0] : ctx.NodeName[0]).image };
	}

	private function singleFieldValue(ctx: Context) {
		return processField(this, ctx);
	}

	private function multiFieldValue(ctx: Context) {
		return processField(this, ctx);
	}

	private function route(ctx: Context) {
		var data = { FROM: ctx.RouteIdentifier[0].image, TO: ctx.RouteIdentifier[1].image };
		return data;
	}
}