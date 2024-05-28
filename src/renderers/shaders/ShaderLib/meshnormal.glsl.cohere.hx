package;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.BlendMode;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.VertexBuffer3DData;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Main extends Sprite {

	private var shader:Shader;
	private var graphics:Graphics;

	public function new() {
		super();
		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(e:Event) {
		var stage:DisplayObjectContainer = stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		graphics = new Graphics();
		graphics.beginFill(0xFFFFFF);
		graphics.drawRect(0, 0, 100, 100);
		graphics.endFill();
		addChild(graphics);

		var vertex:String =
			"#define NORMAL

			#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )

				varying vec3 vViewPosition;

			#endif

			#include <common>
			#include <batching_pars_vertex>
			#include <uv_pars_vertex>
			#include <displacementmap_pars_vertex>
			#include <normal_pars_vertex>
			#include <morphtarget_pars_vertex>
			#include <skinning_pars_vertex>
			#include <logdepthbuf_pars_vertex>
			#include <clipping_planes_pars_vertex>

			void main() {

				#include <uv_vertex>
				#include <batching_vertex>

				#include <beginnormal_vertex>
				#include <morphinstance_vertex>
				#include <morphnormal_vertex>
				#include <skinbase_vertex>
				#include <skinnormal_vertex>
				#include <defaultnormal_vertex>
				#include <normal_vertex>

				#include <begin_vertex>
				#include <morphtarget_vertex>
				#include <skinning_vertex>
				#include <displacementmap_vertex>
				#include <project_vertex>
				#include <logdepthbuf_vertex>
				#include <clipping_planes_vertex>

			#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )

				vViewPosition = - mvPosition.xyz;

			#endif

			}";

		var fragment:String =
			"#define NORMAL

			uniform float opacity;

			#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )

				varying vec3 vViewPosition;

			#endif

			#include <packing>
			#include <uv_pars_fragment>
			#include <normal_pars_fragment>
			#include <bumpmap_pars_fragment>
			#include <normalmap_pars_fragment>
			#include <logdepthbuf_pars_fragment>
			#include <clipping_planes_pars_fragment>

			void main() {

				vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );

				#include <clipping_planes_fragment>
				#include <logdepthbuf_fragment>
				#include <normal_fragment_begin>
				#include <normal_fragment_maps>

				gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );

				#ifdef OPAQUE

					gl_FragColor.a = 1.0;

				#endif

			}";

		shader = new Shader(vertex, fragment, [], []);
		graphics.shader = shader;
	}
}

var main = new Main();