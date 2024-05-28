#if js
import js.Browser.WebGL.*;
#end

#if flash
import openfl.display.OpenGLView;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3DTextureFormat;
#end

#if js || flash

class Shader {
	static var batchingVertex:String =
		#if flash
		"attribute float batchId;
		uniform sampler2D batchingTexture;
		mat4 getBatchingMatrix( const in float i ) {
			int size = textureSize( batchingTexture, 0 ).x;
			int j = int( i ) * 4;
			int x = j % size;
			int y = j / size;
			vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
			vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
			vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
			vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
			return mat4( v1, v2, v3, v4 );
		}
		#else
		'attribute float batchId;
		uniform highp sampler2D batchingTexture;
		mat4 getBatchingMatrix( const in float i ) {

			vec2 size = textureSize( batchingTexture, 0 );
			int j = int( i ) * 4;
			int x = int( mod( float( j ), size.x ) );
			int y = int( floor( float( j ) / size.x ) );
			vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
			vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
			vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
			vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
			return mat4( v1, v2, v3, v4 );

		}
		#end
		";

	static var batchingColorVertex:String =
		#if flash
		"uniform sampler2D batchingColorTexture;
		vec3 getBatchingColor( const in float i ) {
			int size = textureSize( batchingColorTexture, 0 ).x;
			int j = int( i );
			int x = j % size;
			int y = j / size;
			return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
		}
		#else
		'uniform sampler2D batchingColorTexture;
		vec3 getBatchingColor( const in float i ) {

			vec2 size = textureSize( batchingColorTexture, 0 );
			int j = int( i );
			int x = int( mod( float( j ), size.x ) );
			int y = int( floor( float( j ) / size.x ) );
			return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;

		}
		#end
		";
}

#end