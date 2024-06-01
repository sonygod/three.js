class Shader {

    public static function main(): String {
        return
        '#ifdef USE_SKINNING\n' +
        '\n' +
        '	uniform mat4 bindMatrix;\n' +
        '	uniform mat4 bindMatrixInverse;\n' +
        '\n' +
        '	uniform sampler2D boneTexture;\n' +
        '\n' +
        '	mat4 getBoneMatrix( const in float i ) {\n' +
        '\n' +
        '		ivec2 size = textureSize( boneTexture, 0 );\n' +
        '		int j = int( i ) * 4;\n' +
        '		int x = j % size.x;\n' +
        '		int y = j / size.x;\n' +
        '		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );\n' +
        '		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );\n' +
        '		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );\n' +
        '		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );\n' +
        '\n' +
        '		return mat4( v1, v2, v3, v4 );\n' +
        '\n' +
        '	}\n' +
        '\n' +
        '#endif\n';
    }
}


**Explanation:**

1. **Class Definition:** We encapsulate the code within a Haxe class named `Shader` for better organization.
2. **`main` Function:**  The GLSL code is placed inside a static function called `main`. This function returns the entire GLSL code as a single string.
3. **String Concatenation:** The GLSL code is broken down into multiple string literals concatenated using the `+` operator for better readability.
4. **Newlines:** We use `\n` to represent newlines, ensuring proper formatting in the final GLSL output.

**Using the Code:**

To access the GLSL code, you can simply call the `Shader.main()` function, which will return the GLSL string. For example:


var glslCode:String = Shader.main();