import haxe.ds.StringMap;
import chevrotain.TokenType;
import chevrotain.Grammar;
import chevrotain.Lexer;
import chevrotain.Parser;
import chevrotain.CommonToken;
import chevrotain.Visitable;
import chevrotain.visitor.Visitor;
import chevrotain.estree.AstNode;
import chevrotain.estree.BaseVisitor;
import chevrotain.estree.Node;
import chevrotain.estree.Identifier;
import chevrotain.estree.RouteIdentifier;
import chevrotain.estree.NodeName;
import chevrotain.estree.DEF;
import chevrotain.estree.USE;
import chevrotain.estree.ROUTE;
import chevrotain.estree.TO;
import chevrotain.estree.StringLiteral;
import chevrotain.estree.HexLiteral;
import chevrotain.estree.NumberLiteral;
import chevrotain.estree.TrueLiteral;
import chevrotain.estree.FalseLiteral;
import chevrotain.estree.NullLiteral;
import chevrotain.estree.LSquare;
import chevrotain.estree.RSquare;
import chevrotain.estree.LCurly;
import chevrotain.estree.RCurly;
import chevrotain.estree.Comment;
import chevrotain.estree.WhiteSpace;
import chevrotain.estree.Version;
import chevrotain.estree.Node;
import chevrotain.estree.Field;
import chevrotain.estree.FieldValue;
import chevrotain.estree.SingleFieldValue;
import chevrotain.estree.MultiFieldValue;
import chevrotain.estree.Route;
import chevrotain.LexerError;
import chevrotain.Token;
import chevrotain.Context;
import chevrotain.estree.ParseError;
import chevrotain.estree.Function;
import chevrotain.estree.FunctionValue;
import chevrotain.estree.BlockStatement;
import chevrotain.estree.FunctionBody;
import chevrotain.estree.ReturnStatement;
import chevrotain.estree.IdentifierRef;
import chevrotain.estree.Expression;
import chevrotain.estree.BinaryExpression;
import chevrotain.estree.UnaryExpression;
import chevrotain.estree.LogicalExpression;
import chevrotain.estree.MemberExpression;
import chevrotain.estree.ArrayExpression;
import chevrotain.estree.ObjectExpression;
import chevrotain.estree.Property;
import chevrotain.estree.PropertyValue;
import chevrotain.estree.ThisExpression;
import chevrotain.estree.CallExpression;
import chevrotain.estree.NewExpression;
import chevrotain.estree.SequenceExpression;
import chevrotain.estree.ConditionalExpression;
import chevrotain.estree.Literal;
import chevrotain.estree.NumericLiteral;
import chevrotain.estree.StringLiteral as ESTreeStringLiteral;
import chevrotain.estree.RegularExpressionLiteral;
import chevrotain.estree.BooleanLiteral;
import chevrotain.estree.NullLiteral as ESTreeNullLiteral;
import chevrotain.estree.ArrayPattern;
import chevrotain.estree.AssignmentExpression;
import chevrotain.estree.UpdateExpression;
import chevrotain.estree.YieldExpression;
import chevrotain.estree.AwaitExpression;
import chevrotain.estree.ThrowStatement;
import chevrotain.estree.TryStatement;
import chevrotain.estree.CatchClause;
import chevrotain.estree.VariableDeclaration;
import chevrotain.estree.VariableDeclarator;
import chevrotain.estree.VariableDeclaratorId;
import chevrotain.estree.ExpressionStatement;
import chevrotain.estree.EmptyStatement;
import chevrotain.estree.BreakStatement;
import chevrotain.estree.ContinueStatement;
import chevrotain.estree.SwitchStatement;
import chevrotain.estree.SwitchCase;
import chevrotain.estree.LabeledStatement;
import chevrotain.estree.IfStatement;
import chevrotain.estree.WhileStatement;
import chevrotain.estree.ForStatement;
import chevrotain.estree.ForInStatement;
import chevrotain.estree.DoWhileStatement;
import chevrotain.estree.ImportDeclaration;
import chevrotain.estree.ImportSpecifier;
import chevrotain.estree.ImportDefaultSpecifier;
import chevrotain.estree.ImportNamespaceSpecifier;
import chevrotain.estree.ExportNamedDeclaration;
import chevrotain.estree.ExportDefaultDeclaration;
import chevrotain.estree.ExportSpecifier;
import chevrotain.estree.ExportAllDeclaration;
import chevrotain.estree.ModuleDeclaration;
import chevrotain.estree.ModuleSpecifier;
import chevrotain.estree.DebuggerStatement;
import chevrotain.estree.ClassBody;
import chevrotain.estree.ClassDeclaration;
import chevrotain.estree.ClassExpression;
import chevrotain.estree.ClassHeritage;
import chevrotain.estree.MethodDefinition;
import chevrotain.estree.PropertyName;
import chevrotain.estree.PrivateName;
import chevrotain.estree.Super;
import chevrotain.estree.SpreadElement;
import chevrotain.estree.InterpreterDirective;
import chevrotain.estree.TSAsExpression;
import chevrotain.estree.TSNonNullExpression;
import chevrotain.estree.TSParameterProperty;
import chevrotain.estree.TSEnumDeclaration;
import chevrotain.estree.TSModuleDeclaration;
import chevrotain.estree.TSType;
import chevrotain.estree.TSTypeAnnotation;
import chevrotain.estree.TSTypeLiteral;
import chevrotain.estree.TSTypeOperator;
import chevrotain.estree.TSEnumMember;
import chevrotain.estree.TSMappedType;
import chevrotain.estree.TSIntersectionType;
import chevrotain.estree.TSConditionalType;
import chevrotain.estree.TSIndexedAccessType;
import chevrotain.estree.TSNonNullExpression;
import chevrotain.estree.TSPropertySignature;
import chevrotain.estree.TSRestProperty;
import chevrotain.estree.TSTupleType;
import chevrotain.estree.TSUnderstoodMode;
import chevrotain.estree.TSUndefined;
import chevrotain.estree.TSVoidKeyword;
import chevrotain.estree.TSThisType;
import chevrotain.estree.TSExpressionWithTypeArguments;
import chevrotain.estree.TSParenthesizedType;
import chevrotain.estree.TSArrayType;
import chevrotain.estree.TSInferType;
import chevrotain.estree.TSTypeParameterDeclaration;
import chevrotain.estree.TSTypeParameterInstantiation;
import chevrotain.estree.TSPrivateName;
import chevrotain.estree.TSEnumDecl;
import chevrotain.estree.TSModuleBlock;
import chevrotain.estree.TSTypeElement;
import chevrotain.estree.TSTypeLiteralWithEmptyBody;
import chevrotain.estree.TSParenType;
import chevrotain.estree.TSIntersectionType;
import chevrotain.estree.TSUnionType;
import chevrotain.estree.TSLiteralType;
import chevrotain.estree.TSAnyKeyword;
import chevrotain.estree.TSArrayLiteralType;
import chevrotain.estree.TSConstructorType;
import chevrotain.estree.TSFunctionType;
import chevrotain.estree.TSObjectKeyword;
import chevrotain.estree.TSVoidKeyword;
import chevrotain.estree.TSStringKeyword;
import chevrotain.estree.TSNumberKeyword;
import chevrotain.estree.TSBooleanKeyword;
import chevrotain.estree.TSDictionaryType;
import chevrotain.estree.TSBigIntKeyword;
import chevrotain.estree.TSLiteral;
import chevrotain.estree.TSFlow

class VRMLLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (scope.path === '') ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:String, path:String):Dynamic {
		// Implement the parsing logic here
	}

}