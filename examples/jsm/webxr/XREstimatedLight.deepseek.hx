import three.DirectionalLight;
import three.Group;
import three.LightProbe;
import three.WebGLCubeRenderTarget;

class SessionLightProbe {

	var xrLight:Dynamic;
	var renderer:Dynamic;
	var lightProbe:Dynamic;
	var xrWebGLBinding:Dynamic;
	var estimationStartCallback:Dynamic;
	var frameCallback:Dynamic;

	public function new( xrLight:Dynamic, renderer:Dynamic, lightProbe:Dynamic, environmentEstimation:Dynamic, estimationStartCallback:Dynamic ) {

		this.xrLight = xrLight;
		this.renderer = renderer;
		this.lightProbe = lightProbe;
		this.xrWebGLBinding = null;
		this.estimationStartCallback = estimationStartCallback;
		this.frameCallback = this.onXRFrame.bind( this );

		var session = renderer.xr.getSession();

		if ( environmentEstimation && 'XRWebGLBinding' in window ) {

			var cubeRenderTarget = new WebGLCubeRenderTarget( 16 );
			xrLight.environment = cubeRenderTarget.texture;

			var gl = renderer.getContext();

			switch ( session.preferredReflectionFormat ) {

				case 'srgba8':
					gl.getExtension( 'EXT_sRGB' );
					break;

				case 'rgba16f':
					gl.getExtension( 'OES_texture_half_float' );
					break;

			}

			this.xrWebGLBinding = new XRWebGLBinding( session, gl );

			this.lightProbe.addEventListener( 'reflectionchange', () -> {

				this.updateReflection();

			} );

		}

		session.requestAnimationFrame( this.frameCallback );

	}

	function updateReflection() {

		var textureProperties = this.renderer.properties.get( this.xrLight.environment );

		if ( textureProperties ) {

			var cubeMap = this.xrWebGLBinding.getReflectionCubeMap( this.lightProbe );

			if ( cubeMap ) {

				textureProperties.__webglTexture = cubeMap;

				this.xrLight.environment.needsPMREMUpdate = true;

			}

		}

	}

	function onXRFrame( time:Dynamic, xrFrame:Dynamic ) {

		if ( ! this.xrLight ) {

			return;

		}

		var session = xrFrame.session;
		session.requestAnimationFrame( this.frameCallback );

		var lightEstimate = xrFrame.getLightEstimate( this.lightProbe );
		if ( lightEstimate ) {

			this.xrLight.lightProbe.sh.fromArray( lightEstimate.sphericalHarmonicsCoefficients );
			this.xrLight.lightProbe.intensity = 1.0;

			var intensityScalar = Math.max( 1.0,
				Math.max( lightEstimate.primaryLightIntensity.x,
					Math.max( lightEstimate.primaryLightIntensity.y,
						lightEstimate.primaryLightIntensity.z ) ) );

			this.xrLight.directionalLight.color.setRGB(
				lightEstimate.primaryLightIntensity.x / intensityScalar,
				lightEstimate.primaryLightIntensity.y / intensityScalar,
				lightEstimate.primaryLightIntensity.z / intensityScalar );
			this.xrLight.directionalLight.intensity = intensityScalar;
			this.xrLight.directionalLight.position.copy( lightEstimate.primaryLightDirection );

			if ( this.estimationStartCallback ) {

				this.estimationStartCallback();
				this.estimationStartCallback = null;

			}

		}

	}

	function dispose() {

		this.xrLight = null;
		this.renderer = null;
		this.lightProbe = null;
		this.xrWebGLBinding = null;

	}

}

class XREstimatedLight extends Group {

	var lightProbe:LightProbe;
	var directionalLight:DirectionalLight;
	var environment:Dynamic;

	public function new( renderer:Dynamic, environmentEstimation:Bool = true ) {

		super();

		this.lightProbe = new LightProbe();
		this.lightProbe.intensity = 0;
		this.add( this.lightProbe );

		this.directionalLight = new DirectionalLight();
		this.directionalLight.intensity = 0;
		this.add( this.directionalLight );

		this.environment = null;

		var sessionLightProbe:Dynamic = null;
		var estimationStarted:Bool = false;
		renderer.xr.addEventListener( 'sessionstart', () -> {

			var session = renderer.xr.getSession();

			if ( 'requestLightProbe' in session ) {

				session.requestLightProbe( {

					reflectionFormat: session.preferredReflectionFormat

				} ).then( ( probe ) -> {

					sessionLightProbe = new SessionLightProbe( this, renderer, probe, environmentEstimation, () -> {

						estimationStarted = true;

						this.dispatchEvent( { type: 'estimationstart' } );

					} );

				} );

			}

		} );

		renderer.xr.addEventListener( 'sessionend', () -> {

			if ( sessionLightProbe ) {

				sessionLightProbe.dispose();
				sessionLightProbe = null;

			}

			if ( estimationStarted ) {

				this.dispatchEvent( { type: 'estimationend' } );

			}

		} );

		this.dispose = () -> {

			if ( sessionLightProbe ) {

				sessionLightProbe.dispose();
				sessionLightProbe = null;

			}

			this.remove( this.lightProbe );
			this.lightProbe = null;

			this.remove( this.directionalLight );
			this.directionalLight = null;

			this.environment = null;

		};

	}

}