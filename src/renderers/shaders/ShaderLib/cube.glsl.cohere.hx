package;

import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Rectangle;

class MyShader extends Shader {

	public function new() {
		super();

		// Define the vertex shader
		vertex = "
			varying vec3 vWorldDirection;

			#include <common>

			void main() {

				vWorldDirection = transformDirection( position, modelMatrix );

				#include <begin_vertex>
				#include <project_vertex>

				gl_Position.z = gl_Position.w; // set z to camera.far

			}
		";

		// Define the fragment shader
		fragment = "
			uniform samplerCube tCube;
			uniform float tFlip;
			uniform float opacity;

			varyement vec3 vWorldDirection;

			void main() {

				vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );

				gl_FragColor = texColor;
				gl_FragColor.a *= opacity;

				#include <tonemapping_fragment>
				#include <colorspace_fragment>

			}
		";
	}

}

class Main extends DisplayObject {

	public function new() {
		super();

		// Create a new instance of the shader
		var shader = new MyShader();

		// Set the shader's parameters
		shader.setShaderInput("tCube", new ShaderInput(myCubeTexture, ShaderInput.SAMPLER_CUBE));
		shader.setShaderInput("tFlip", new ShaderInput(1.0, ShaderInput.FLOAT));
		shader.setShaderInput("opacity", new ShaderInput(0.5, ShaderInput.FLOAT));

		// Apply the shader to this display object
		shader.apply();
	}

}