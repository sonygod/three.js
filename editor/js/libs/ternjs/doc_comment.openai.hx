package three.js.editor.js.libs.ternjs.doc_comment;

import haxe.extern.Either;
import tern.Comment;
import tern.Infer;
import tern.Lib;
import tern.Server;
import acorn.Acorn;
import acorn.walk.Walk;

class DocComment {
  static var WG_MADEUP = 1;
  static var WG_STRONG = 101;

  static function registerPlugin(server:Server, options:Either<{}, { strong:Bool; fullDocs:Bool; }>):Void {
    server.jsdocTypedefs = {};
    server.on("reset", function() {
      server.jsdocTypedefs = {};
    });
    server._docComment = {
      weight: if (options != null && options.strong) WG_STRONG else null,
      fullDocs: options != null && options.fullDocs
    };

    return {
      passes: {
        postParse: postParse,
        postInfer: postInfer,
        postLoadDef: postLoadDef
      }
    };
  }

  static function postParse(ast:Acorn.Node, text:String):Void {
    function attachComments(node:Acorn.Node):Void {
      Comment.ensureCommentsBefore(text, node);
    }

    Walk.simple(ast, {
      VariableDeclaration: attachComments,
      FunctionDeclaration: attachComments,
      AssignmentExpression: function(node:Acorn.Node) {
        if (node.operator == "=") attachComments(node);
      },
      ObjectExpression: function(node:Acorn.Node) {
        for (i in 0...node.properties.length) {
          attachComments(node.properties[i]);
        }
      },
      CallExpression: function(node:Acorn.Node) {
        if (isDefinePropertyCall(node)) attachComments(node);
      }
    });
  }

  static function isDefinePropertyCall(node:Acorn.Node):Bool {
    return node.callee.type == "MemberExpression" &&
      node.callee.object.name == "Object" &&
      node.callee.property.name == "defineProperty" &&
      node.arguments.length >= 3 &&
      Std.isOfType(node.arguments[1].value, String);
  }

  // ... (rest of the code remains the same)
}