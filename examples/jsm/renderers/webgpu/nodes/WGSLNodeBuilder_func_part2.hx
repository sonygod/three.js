package three.js.examples.jsm.renderers.webgpu.nodes;

class WGSLNodeBuilder {
    // ...

    public function getInstanceIndex():String {
        if (shaderStage == 'vertex') {
            return getBuiltin('instance_index', 'instanceIndex', 'u32', 'attribute');
        }
        return 'instanceIndex';
    }

    public function getFrontFacing():String {
        return getBuiltin('front_facing', 'isFront', 'bool');
    }

    public function getFragCoord():String {
        return getBuiltin('position', 'fragCoord', 'vec4<f32>') + '.xyz';
    }

    public function getFragDepth():String {
        return 'output.' + getBuiltin('frag_depth', 'depth', 'f32', 'output');
    }

    public function isFlipY():Bool {
        return false;
    }

    public function getBuiltins(shaderStage:String):String {
        var snippets:Array<String> = [];
        var builtins:Array<{name:String, property:String, type:String}> = this.builtins[shaderStage];
        if (builtins != null) {
            for (builtin in builtins) {
                snippets.push('@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}');
            }
        }
        return snippets.join(',\n\t');
    }

    public function getAttributes(shaderStage:String):String {
        var snippets:Array<String> = [];
        if (shaderStage == 'compute') {
            getBuiltin('global_invocation_id', 'id', 'vec3<u32>', 'attribute');
        }
        if (shaderStage == 'vertex' || shaderStage == 'compute') {
            var builtins:String = getBuiltins('attribute');
            if (builtins != null) snippets.push(builtins);
            var attributes:Array<{name:String, type:String}> = getAttributesArray();
            for (i in 0...attributes.length) {
                var attribute = attributes[i];
                var name = attribute.name;
                var type = getType(attribute.type);
                snippets.push('@location(${i}) ${name} : ${type}');
            }
        }
        return snippets.join(',\n\t');
    }

    public function getStructMembers(struct:{getMemberTypes:Void->Array<{name:String, type:String}>}):String {
        var snippets:Array<String> = [];
        var members:Array<{name:String, type:String}> = struct.getMemberTypes();
        for (i in 0...members.length) {
            var member = members[i];
            snippets.push('\t@location(${i}) m${i} : ${member.type}<f32>');
        }
        return snippets.join(',\n');
    }

    public function getStructs(shaderStage:String):String {
        var snippets:Array<String> = [];
        var structs:Array<{name:String, getMemberTypes:Void->Array<{name:String, type:String}>}> = this.structs[shaderStage];
        for (i in 0...structs.length) {
            var struct = structs[i];
            var name = struct.name;
            var snippet = '\tstruct ${name} {\n';
            snippet += getStructMembers(struct);
            snippet += '\n}';
            snippets.push(snippet);
        }
        return snippets.join('\n\n');
    }

    public function getVar(type:String, name:String):String {
        return 'var ${name} : ${getType(type)}';
    }

    public function getVars(shaderStage:String):String {
        var snippets:Array<String> = [];
        var vars:Array<{type:String, name:String}> = this.vars[shaderStage];
        if (vars != null) {
            for (variable in vars) {
                snippets.push('\t${getVar(variable.type, variable.name)};');
            }
        }
        return '\n${snippets.join('\n')}\n';
    }

    public function getVaryings(shaderStage:String):String {
        var snippets:Array<String> = [];
        if (shaderStage == 'vertex') {
            getBuiltin('position', 'Vertex', 'vec4<f32>', 'vertex');
        }
        if (shaderStage == 'vertex' || shaderStage == 'fragment') {
            var varyings:Array<{name:String, type:String}> = this.varyings;
            for (i in 0...varyings.length) {
                var varying = varyings[i];
                if (varying.needsInterpolation) {
                    var attributesSnippet = '@location(${i})';
                    if (/^(int|uint|ivec|uvec)/.test(varying.type)) {
                        attributesSnippet += ' @interpolate( flat )';
                    }
                    snippets.push('${attributesSnippet} ${varying.name} : ${getType(varying.type)}');
                } else if (shaderStage == 'vertex' && vars.includes(varying) == false) {
                    vars.push(varying);
                }
            }
        }
        var builtins:String = getBuiltins(shaderStage);
        if (builtins != null) snippets.push(builtins);
        var code = snippets.join(',\n\t');
        return shaderStage == 'vertex' ? _getWGSLStruct('VaryingsStruct', '\t' + code) : code;
    }

    public function getUniforms(shaderStage:String):String {
        var uniforms:Array<{name:String, type:String}> = this.uniforms[shaderStage];
        var bindingSnippets:Array<String> = [];
        var bufferSnippets:Array<String> = [];
        var structSnippets:Array<String> = [];
        var uniformGroups:Map<String, {index:Int, snippets:Array<String>}> = new Map();
        var index:Int = this.bindingsOffset[shaderStage];
        for (uniform in uniforms) {
            if (uniform.type == 'texture' || uniform.type == 'cubeTexture' || uniform.type == 'storageTexture') {
                // ...
            } else if (uniform.type == 'buffer' || uniform.type == 'storageBuffer') {
                // ...
            } else {
                // ...
            }
        }
        // ...
    }

    public function buildCode():Void {
        var shadersData:Map<String, {uniforms:String, attributes:String, varyings:String, structs:String, vars:String, codes:String}> = new Map();
        for (shaderStage in ['vertex', 'fragment', 'compute']) {
            var stageData = shadersData[shaderStage] = {};
            stageData.uniforms = getUniforms(shaderStage);
            stageData.attributes = getAttributes(shaderStage);
            stageData.varyings = getVaryings(shaderStage);
            stageData.structs = getStructs(shaderStage);
            stageData.vars = getVars(shaderStage);
            stageData.codes = getCodes(shaderStage);
            // ...
        }
    }

    public function getMethod(method:String, output:String = null):String {
        var wgslMethod:String;
        if (output != null) {
            wgslMethod = _getWGSLMethod(method + '_' + output);
        }
        if (wgslMethod == null) {
            wgslMethod = _getWGSLMethod(method);
        }
        return wgslMethod != null ? wgslMethod : method;
    }

    public function getType(type:String):String {
        return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
    }

    public function isAvailable(name:String):Bool {
        return supports[name] == true;
    }

    private function _getWGSLMethod(method:String):String {
        if (wgslPolyfill[method] != null) {
            _include(method);
        }
        return wgslMethods[method];
    }

    private function _include(name:String):Void {
        var codeNode = wgslPolyfill[name];
        codeNode.build(this);
        if (currentFunctionNode != null) {
            currentFunctionNode.includes.push(codeNode);
        }
    }

    private function _getWGSLVertexCode(shaderData:{uniforms:String, attributes:String, varyings:String, structs:String, vars:String, codes:String}):String {
        return '${getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

    // vars
    ${shaderData.vars}

    // flow
    ${shaderData.flow}

    return varyings;
}';
    }

    private function _getWGSLFragmentCode(shaderData:{uniforms:String, structs:String, codes:String, returnType:String, vars:String, flow:String}):String {
        return '${getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

    // vars
    ${shaderData.vars}

    // flow
    ${shaderData.flow}
}';
    }

    private function _getWGSLComputeCode(shaderData:{uniforms:String, attributes:String, vars:String, flow:String}, workgroupSize:String):String {
        return '${getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

    // system
    instanceIndex = id.x;

    // vars
    ${shaderData.vars}

    // flow
    ${shaderData.flow}
}';
    }

    private function _getWGSLStruct(name:String, vars:String):String {
        return 'struct ${name} {\n${vars}\n}';
    }

    private function _getWGSLStructBinding(name:String, vars:String, access:String, binding:Int = 0, group:Int = 0):String {
        var structName = name + 'Struct';
        var structSnippet = _getWGSLStruct(structName, vars);
        return '${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};';
    }
}