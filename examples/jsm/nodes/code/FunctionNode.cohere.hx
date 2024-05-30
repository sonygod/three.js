import CodeNode from './CodeNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeObject } from '../shadernode/ShaderNode.hx';

class FunctionNode extends CodeNode {
    public var keywords:Map<String,Dynamic>;

    public function new( code:String = "", includes:Array<Dynamic> = [], language:String = "" ) {
        super( code, includes, language );
        this.keywords = Map();
    }

    public function getNodeType( builder:Dynamic ) : Dynamic {
        return this.getNodeFunction( builder ).getType();
    }

    public function getInputs( builder:Dynamic ) : Dynamic {
        return this.getNodeFunction( builder ).getInputs();
    }

    public function getNodeFunction( builder:Dynamic ) : Dynamic {
        var nodeData = builder.getDataFromNode( this );
        var nodeFunction = nodeData.nodeFunction;

        if ( nodeFunction == null ) {
            nodeFunction = builder.parser.parseFunction( this.code );
            nodeData.nodeFunction = nodeFunction;
        }

        return nodeFunction;
    }

    public function generate( builder:Dynamic, output:String ) : String {
        super.generate( builder );
        var nodeFunction = this.getNodeFunction( builder );
        var name = nodeFunction.getName();
        var type = nodeFunction.getType();
        var nodeCode = builder.getCodeFromNode( this, type );

        if ( name != "" ) {
            nodeCode.name = name;
        }

        var propertyName = builder.getPropertyName( nodeCode );
        var code = this.getNodeFunction( builder ).getCode( propertyName );

        var keywords = this.keywords;
        var keywordsProperties = keywords.keys();

        if ( keywordsProperties.length > 0 ) {
            for ( property in keywordsProperties ) {
                var propertyRegExp = EReg.new( "\\b" + property + "\\b", "g" );
                var nodeProperty = keywords.get( property ).build( builder, "property" );
                code = code.replace( propertyRegExp, nodeProperty );
            }
        }

        nodeCode.code = code + "\n";

        if ( output == "property" ) {
            return propertyName;
        } else {
            return builder.format( "${ propertyName }()", type, output );
        }
    }
}

function nativeFn( code:String, includes:Array<Dynamic> = [], language:String = "" ) : Dynamic {
    for ( i in 0 ... includes.length ) {
        var include = includes[i];
        if ( Std.is( include, Dynamic -> Function ) ) {
            includes[i] = include( null );
        }
    }

    var functionNode = nodeObject( new FunctionNode( code, includes, language ) );
    var fn = function( ...params ) {
        return functionNode( ...params );
    };
    fn.functionNode = functionNode;
    return fn;
}

function glslFn( code:String, includes:Array<Dynamic> ) : Dynamic {
    return nativeFn( code, includes, "glsl" );
}

function wgslFn( code:String, includes:Array<Dynamic> ) : Dynamic {
    return nativeFn( code, includes, "wgsl" );
}

addNodeClass( "FunctionNode", FunctionNode );

export { FunctionNode, nativeFn, glslFn, wgslFn };