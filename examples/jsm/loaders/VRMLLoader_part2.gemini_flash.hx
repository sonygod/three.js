import haxe.macro.Expr;

class VRMLToASTVisitor extends BaseVRMLVisitor {

  public function new() {
    super();
    this.validateVisitor();
  }

  public function vrml(ctx:VRMLParser.VrmlContext):Dynamic {
    var data = {
      version: this.visit(ctx.version),
      nodes: [],
      routes: []
    };

    for (i in 0...ctx.node.length) {
      var node = ctx.node[i];
      data.nodes.push(this.visit(node));
    }

    if (ctx.route != null) {
      for (i in 0...ctx.route.length) {
        var route = ctx.route[i];
        data.routes.push(this.visit(route));
      }
    }

    return data;
  }

  public function version(ctx:VRMLParser.VersionContext):String {
    return ctx.Version[0].image;
  }

  public function node(ctx:VRMLParser.NodeContext):Dynamic {
    var data = {
      name: ctx.NodeName[0].image,
      fields: []
    };

    if (ctx.field != null) {
      for (i in 0...ctx.field.length) {
        var field = ctx.field[i];
        data.fields.push(this.visit(field));
      }
    }

    if (ctx.def != null) {
      data.DEF = this.visit(ctx.def[0]);
    }

    return data;
  }

  public function field(ctx:VRMLParser.FieldContext):Dynamic {
    var data = {
      name: ctx.Identifier[0].image,
      type: null,
      values: null
    };

    var result:Dynamic;

    if (ctx.singleFieldValue != null) {
      result = this.visit(ctx.singleFieldValue[0]);
    } else if (ctx.multiFieldValue != null) {
      result = this.visit(ctx.multiFieldValue[0]);
    }

    data.type = result.type;
    data.values = result.values;

    return data;
  }

  public function def(ctx:VRMLParser.DefContext):String {
    return (ctx.Identifier != null ? ctx.Identifier[0].image : ctx.NodeName[0].image);
  }

  public function use(ctx:VRMLParser.UseContext):Dynamic {
    return {USE: (ctx.Identifier != null ? ctx.Identifier[0].image : ctx.NodeName[0].image)};
  }

  public function singleFieldValue(ctx:VRMLParser.SingleFieldValueContext):Dynamic {
    return processField(this, ctx);
  }

  public function multiFieldValue(ctx:VRMLParser.MultiFieldValueContext):Dynamic {
    return processField(this, ctx);
  }

  public function route(ctx:VRMLParser.RouteContext):Dynamic {
    var data = {
      FROM: ctx.RouteIdentifier[0].image,
      TO: ctx.RouteIdentifier[1].image
    };
    return data;
  }

}

macro processField(this:Expr, ctx:Expr) {
  var result = macro {
    var type = null;
    var values = null;
    if ($ctx.SFBool != null) {
      type = "SFBool";
      values = $ctx.SFBool[0].image;
    } else if ($ctx.SFColor != null) {
      type = "SFColor";
      values = $ctx.SFColor[0].image;
    } else if ($ctx.SFFloat != null) {
      type = "SFFloat";
      values = $ctx.SFFloat[0].image;
    } else if ($ctx.SFInt32 != null) {
      type = "SFInt32";
      values = $ctx.SFInt32[0].image;
    } else if ($ctx.SFString != null) {
      type = "SFString";
      values = $ctx.SFString[0].image;
    } else if ($ctx.SFVec2f != null) {
      type = "SFVec2f";
      values = $ctx.SFVec2f[0].image;
    } else if ($ctx.SFVec3f != null) {
      type = "SFVec3f";
      values = $ctx.SFVec3f[0].image;
    } else if ($ctx.SFVec4f != null) {
      type = "SFVec4f";
      values = $ctx.SFVec4f[0].image;
    } else if ($ctx.MFBool != null) {
      type = "MFBool";
      values = $ctx.MFBool[0].image;
    } else if ($ctx.MFColor != null) {
      type = "MFColor";
      values = $ctx.MFColor[0].image;
    } else if ($ctx.MFFloat != null) {
      type = "MFFloat";
      values = $ctx.MFFloat[0].image;
    } else if ($ctx.MFInt32 != null) {
      type = "MFInt32";
      values = $ctx.MFInt32[0].image;
    } else if ($ctx.MFString != null) {
      type = "MFString";
      values = $ctx.MFString[0].image;
    } else if ($ctx.MFVec2f != null) {
      type = "MFVec2f";
      values = $ctx.MFVec2f[0].image;
    } else if ($ctx.MFVec3f != null) {
      type = "MFVec3f";
      values = $ctx.MFVec3f[0].image;
    } else if ($ctx.MFVec4f != null) {
      type = "MFVec4f";
      values = $ctx.MFVec4f[0].image;
    }
    return { type: type, values: values };
  };
  return result;
}