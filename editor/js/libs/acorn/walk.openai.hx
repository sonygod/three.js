package acorn.walk;

import haxe.extern.Either;

class Walker {
    static public function simple(node:Dynamic, visitors:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        if (base == null) base = exports.base;
        var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
            var type:String = override != null ? override : node.type;
            var found:Dynamic = visitors[type];
            base[type](node, st, c);
            if (found != null) found(node, st);
        }
        c(node, state);
    }

    static public function ancestor(node:Dynamic, visitors:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        if (base == null) base = exports.base;
        if (state == null) state = [];
        var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
            var type:String = override != null ? override : node.type;
            var found:Dynamic = visitors[type];
            if (node != st[st.length - 1]) {
                st = st.slice();
                st.push(node);
            }
            base[type](node, st, c);
            if (found != null) found(node, st);
        }
        c(node, state);
    }

    static public function recursive(node:Dynamic, state:Dynamic, funcs:Dynamic, base:Dynamic = null) {
        var visitor:Dynamic = funcs != null ? exports.make(funcs, base) : base;
        var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
            visitor[override != null ? override : node.type](node, st, c);
        }
        c(node, state);
    }

    static public function makeTest(test:Dynamic) {
        if (Std.is(test, String)) {
            return function(type:String) {
                return type == test;
            };
        } else if (test == null) {
            return function() {
                return true;
            };
        } else {
            return test;
        }
    }

    static public function findNodeAt(node:Dynamic, start:Dynamic, end:Dynamic, test:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        test = makeTest(test);
        if (base == null) base = exports.base;
        try {
            var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
                var type:String = override != null ? override : node.type;
                if ((start == null || node.start <= start) && (end == null || node.end >= end)) {
                    base[type](node, st, c);
                }
                if (test(type, node) && (start == null || node.start == start) && (end == null || node.end == end)) {
                    throw new Found(node, st);
                }
            }
            c(node, state);
        } catch (e:Found) {
            return e;
        }
    }

    static public function findNodeAround(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        test = makeTest(test);
        if (base == null) base = exports.base;
        try {
            var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
                var type:String = override != null ? override : node.type;
                if (node.start > pos || node.end < pos) {
                    return;
                }
                base[type](node, st, c);
                if (test(type, node)) {
                    throw new Found(node, st);
                }
            }
            c(node, state);
        } catch (e:Found) {
            return e;
        }
    }

    static public function findNodeAfter(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        test = makeTest(test);
        if (base == null) base = exports.base;
        try {
            var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
                if (node.end < pos) {
                    return;
                }
                var type:String = override != null ? override : node.type;
                if (node.start >= pos && test(type, node)) {
                    throw new Found(node, st);
                }
                base[type](node, st, c);
            }
            c(node, state);
        } catch (e:Found) {
            return e;
        }
    }

    static public function findNodeBefore(node:Dynamic, pos:Dynamic, test:Dynamic, base:Dynamic = null, state:Dynamic = null) {
        test = makeTest(test);
        if (base == null) base = exports.base;
        var max:Found = null;
        var c = function(node:Dynamic, st:Dynamic, override:Dynamic = null) {
            if (node.start > pos) {
                return;
            }
            var type:String = override != null ? override : node.type;
            if (node.end <= pos && (!max || max.node.end < node.end) && test(type, node)) {
                max = new Found(node, st);
            }
            base[type](node, st, c);
        }
        c(node, state);
        return max;
    }

    static public function make(funcs:Dynamic, base:Dynamic = null) {
        if (base == null) base = exports.base;
        var visitor:Dynamic = {};
        for (type in base) {
            visitor[type] = base[type];
        }
        for (type in funcs) {
            visitor[type] = funcs[type];
        }
        return visitor;
    }

    static public function skipThrough(node:Dynamic, st:Dynamic, c:Dynamic) {
        c(node, st);
    }

    static public function ignore(_node:Dynamic, _st:Dynamic, _c:Dynamic) {}

    static public var base:Dynamic = {};

    static public function init() {
        base = {};

        base.Program = base.BlockStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.body) {
                c(node.body[i], st, "Statement");
            }
        };
        base.Statement = skipThrough;
        base.EmptyStatement = ignore;
        base.ExpressionStatement = base.ParenthesizedExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.expression, st, "Expression");
        };
        base.IfStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Statement");
            if (node.alternate != null) c(node.alternate, st, "Statement");
        };
        base.LabeledStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.body, st, "Statement");
        };
        base.BreakStatement = base.ContinueStatement = ignore;
        base.WithStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            c(node.body, st, "Statement");
        };
        base.SwitchStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.discriminant, st, "Expression");
            for (i in node.cases) {
                var cs = node.cases[i];
                if (cs.test != null) c(cs.test, st, "Expression");
                for (j in cs.consequent) {
                    c(cs.consequent[j], st, "Statement");
                }
            }
        };
        base.ReturnStatement = base.YieldExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.argument != null) c(node.argument, st, "Expression");
        };
        base.ThrowStatement = base.SpreadElement = base.RestElement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.argument, st, "Expression");
        };
        base.TryStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.block, st, "Statement");
            if (node.handler != null) c(node.handler.body, st, "ScopeBody");
            if (node.finalizer != null) c(node.finalizer, st, "Statement");
        };
        base.WhileStatement = base.DoWhileStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.body, st, "Statement");
        };
        base.ForStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.init != null) c(node.init, st, "ForInit");
            if (node.test != null) c(node.test, st, "Expression");
            if (node.update != null) c(node.update, st, "Expression");
            c(node.body, st, "Statement");
        };
        base.ForInStatement = base.ForOfStatement = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.left, st, "ForInit");
            c(node.right, st, "Expression");
            c(node.body, st, "Statement");
        };
        base.ForInit = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.type == "VariableDeclaration") c(node, st);
            else c(node, st, "Expression");
        };
        base.DebuggerStatement = ignore;

        base.FunctionDeclaration = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node, st, "Function");
        };
        base.VariableDeclaration = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.declarations) {
                var decl = node.declarations[i];
                if (decl.init != null) c(decl.init, st, "Expression");
            }
        };

        base.Function = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.body, st, "ScopeBody");
        };
        base.ScopeBody = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node, st, "Statement");
        };

        base.Expression = skipThrough;
        base.ThisExpression = base.Super = base.MetaProperty = ignore;
        base.ArrayExpression = base.ArrayPattern = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.elements) {
                var elt = node.elements[i];
                if (elt != null) c(elt, st, "Expression");
            }
        };
        base.ObjectExpression = base.ObjectPattern = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.properties) {
                c(node.properties[i], st);
            }
        };
        base.FunctionExpression = base.ArrowFunctionExpression = base.FunctionDeclaration;
        base.SequenceExpression = base.TemplateLiteral = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.expressions) {
                c(node.expressions[i], st, "Expression");
            }
        };
        base.UnaryExpression = base.UpdateExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.argument, st, "Expression");
        };
        base.BinaryExpression = base.AssignmentExpression = base.AssignmentPattern = base.LogicalExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.left, st, "Expression");
            c(node.right, st, "Expression");
        };
        base.ConditionalExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.test, st, "Expression");
            c(node.consequent, st, "Expression");
            c(node.alternate, st, "Expression");
        };
        base.NewExpression = base.CallExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.callee, st, "Expression");
            if (node.arguments != null) for (i in node.arguments) {
                c(node.arguments[i], st, "Expression");
            }
        };
        base.MemberExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.object, st, "Expression");
            if (node.computed) c(node.property, st, "Expression");
        };
        base.ExportDeclaration = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            return c(node.declaration, st);
        };
        base.ImportDeclaration = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.specifiers) {
                c(node.specifiers[i], st);
            }
        };
        base.ImportSpecifier = base.ImportBatchSpecifier = base.Identifier = base.Literal = ignore;

        base.TaggedTemplateExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            c(node.tag, st, "Expression");
            c(node.quasi, st);
        };
        base.ClassDeclaration = base.ClassExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.superClass != null) c(node.superClass, st, "Expression");
            for (i in node.body.body) {
                c(node.body.body[i], st);
            }
        };
        base.MethodDefinition = base.Property = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            if (node.computed) c(node.key, st, "Expression");
            c(node.value, st, "Expression");
        };
        base.ComprehensionExpression = function(node:Dynamic, st:Dynamic, c:Dynamic) {
            for (i in node.blocks) {
                c(node.blocks[i].right, st, "Expression");
            }
            c(node.body, st, "Expression");
        };
    }
}

class Found {
    public var node:Dynamic;
    public var state:Dynamic;

    public function new(node:Dynamic, state:Dynamic) {
        this.node = node;
        this.state = state;
    }
}