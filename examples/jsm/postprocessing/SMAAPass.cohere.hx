import h3d.Texture;
import h3d.TextureFilter;
import h3d.TextureWrap;
import h3d.WebGLRenderTarget;
import h3d.Pass;
import h3d.FullScreenQuad;
import h3d.ShaderMaterial;
import h3d.UniformsUtils;

class SMAAPass extends Pass {

	public var edgesRT:WebGLRenderTarget;
	public var weightsRT:WebGLRenderTarget;
	public var areaTexture:Texture;
	public var searchTexture:Texture;
	public var materialEdges:ShaderMaterial;
	public var materialWeights:ShaderMaterial;
	public var materialBlend:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public function new(width:Int, height:Int) {
		super();

		// render targets

		edgesRT = new WebGLRenderTarget(width, height, { depthBuffer: false, type: HalfFloatType });
		edgesRT.texture.name = 'SMAAPass.edges';

		weightsRT = new WebGLRenderTarget(width, height, { depthBuffer: false, type: HalfFloatType });
		weightsRT.texture.name = 'SMAAPass.weights';

		// textures
		var scope = this;

		var areaTextureImage = new Image();
		areaTextureImage.src = this.getAreaTexture();
		areaTextureImage.onload = function() {

			// assigning data to HTMLImageElement.src is asynchronous (see #15162)
			scope.areaTexture.needsUpdate = true;

		};

		areaTexture = new Texture();
		areaTexture.name = 'SMAAPass.area';
		areaTexture.image = areaTextureImage;
		areaTexture.minFilter = LinearFilter;
		areaTexture.generateMipmaps = false;
		areaTexture.flipY = false;

		var searchTextureImage = new Image();
		searchTextureImage.src = this.getSearchTexture();
		searchTextureImage.onload = function() {

			// assigning data to HTMLImageElement.src is asynchronous (see #15162)
			scope.searchTexture.needsUpdate = true;

		};

		searchTexture = new Texture();
		searchTexture.name = 'SMAAPass.search';
		searchTexture.image = searchTextureImage;
		searchTexture.magFilter = NearestFilter;
		searchTexture.minFilter = NearestFilter;
		searchTexture.generateMipmaps = false;
		searchTexture.flipY = false;

		// materials - pass 1

		var uniformsEdges = UniformsUtils.clone(SMAAEdgesShader.uniforms);

		uniformsEdges['resolution'].value.set(1 / width, 1 / height);

		materialEdges = new ShaderMaterial({
			defines: Object.assign({}, SMAAEdgesShader.defines),
			uniforms: uniformsEdges,
			vertexShader: SMAAEdgesShader.vertexShader,
			fragmentShader: SMAAEdgesShader.fragmentShader
		});

		// materials - pass 2

		var uniformsWeights = UniformsUtils.clone(SMAAWeightsShader.uniforms);

		uniformsWeights['resolution'].value.set(1 / width, 1 / height);
		uniformsWeights['tDiffuse'].value = edgesRT.texture;
		uniformsWeights['tArea'].value = areaTexture;
		uniformsWeights['tSearch'].value = searchTexture;

		materialWeights = new ShaderMaterial({
			defines: Object.assign({}, SMAAWeightsShader.defines),
			uniforms: uniformsWeights,
			vertexShader: SMAAWeightsShader.vertexShader,
			fragmentShader: SMAAWeightsShader.fragmentShader
		});

		// materials - pass 3

		var uniformsBlend = UniformsUtils.clone(SMAABlendShader.uniforms);

		uniformsBlend['resolution'].value.set(1 / width, 1 / height);
		uniformsBlend['tDiffuse'].value = weightsRT.texture;

		materialBlend = new ShaderMaterial({
			uniforms: uniformsBlend,
			vertexShader: SMAABlendShader.vertexShader,
			fragmentShader: SMAABlendShader.fragmentShader
		});

		fsQuad = new FullScreenQuad(null);

	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {

		// pass 1

		uniformsEdges['tDiffuse'].value = readBuffer.texture;

		fsQuad.material = materialEdges;

		renderer.setRenderTarget(edgesRT);
		if (this.clear) renderer.clear();
		fsQuad.render(renderer);

		// pass 2

		fsQuad.material = materialWeights;

		renderer.setRenderTarget(weightsRT);
		if (this.clear) renderer.clear();
		fsQuad.render(renderer);

		// pass 3

		uniformsBlend['tColor'].value = readBuffer.texture;

		fsQuad.material = materialBlend;

		if (this.renderToScreen) {

			renderer.setRenderTarget(null);
			fsQuad.render(renderer);

		} else {

			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear();
			fsQuad.render(renderer);

		}

	}

	public function setSize(width:Int, height:Int) {

		edgesRT.setSize(width, height);
		weightsRT.setSize(width, height);

		materialEdges.uniforms['resolution'].value.set(1 / width, 1 / height);
		materialWeights.uniforms['resolution'].value.set(1 / width, 1 / height);
		materialBlend.uniforms['resolution'].value.set(1 / width, 1 / height);

	}

	public function getAreaTexture():String {

		return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKAAAAIwCAIAAACOVPcQAACBeklEQVR42u39W4xlWXrnh/3WWvuciIzMrKxrV8/0rWbY0+SQFKcb4owIkSIFCjY9AC1BT/LYBozRi+EX+cV+8IMsYAaCwRcBwjzMiw2jAWtgwC8WR5Q8mDFHZLNHTarZGrLJJllt1W2qKrsumZWZcTvn7L3W54e1vrXX3vuciLPPORFR1XE2EomorB0nVuz//r71re/y/1eMvb4Cb3N11xV/PP/2v4UBAwJG/7H8urx6/25/Gf8O5hypMQ0EEEQwAqLfoN/Z+97f/SW+/NvcgQk4sGBJK6H7N4PFVL+K+e0N11yNfkKvwUdwdlUAXPHHL38oa15f/i/46Ih6SuMSPmLAYAwyRKn7dfMGH97jaMFBYCJUgotIC2YAdu+LyW9vvubxAP8kAL8H/koAuOKP3+q6+xGnd5kdYCeECnGIJViwGJMAkQKfDvB3WZxjLKGh8VSCCzhwEWBpMc5/kBbjawT4HnwJfhr+pPBIu7uu+OOTo9vsmtQcniMBGkKFd4jDWMSCRUpLjJYNJkM+IRzQ+PQvIeAMTrBS2LEiaiR9b/5PuT6Ap/AcfAFO4Y3dA3DFH7/VS+M8k4baEAQfMI4QfbVDDGIRg7GKaIY52qAjTAgTvGBAPGIIghOCYAUrGFNgzA7Q3QhgCwfwAnwe5vDejgG44o/fbm1C5ZlYQvQDARPAIQGxCWBM+wWl37ZQESb4gImexGMDouhGLx1Cst0Saa4b4AqO4Hk4gxo+3DHAV/nx27p3JziPM2pVgoiia5MdEzCGULprIN7gEEeQ5IQxEBBBQnxhsDb5auGmAAYcHMA9eAAz8PBol8/xij9+C4Djlim4gJjWcwZBhCBgMIIYxGAVIkH3ZtcBuLdtRFMWsPGoY9rN+HoBji9VBYdwD2ZQg4cnO7OSq/z4rU5KKdwVbFAjNojCQzTlCLPFSxtamwh2jMUcEgg2Wm/6XgErIBhBckQtGN3CzbVacERgCnfgLswhnvqf7QyAq/z4rRZm1YglYE3affGITaZsdIe2FmMIpnOCap25I6jt2kCwCW0D1uAD9sZctNGXcQIHCkINDQgc78aCr+zjtw3BU/ijdpw3zhCwcaONwBvdeS2YZKkJNJsMPf2JKEvC28RXxxI0ASJyzQCjCEQrO4Q7sFArEzjZhaFc4cdv+/JFdKULM4px0DfUBI2hIsy06BqLhGTQEVdbfAIZXYMPesq6VoCHICzUyjwInO4Y411//LYLs6TDa9wvg2CC2rElgAnpTBziThxaL22MYhzfkghz6GAs2VHbbdM91VZu1MEEpupMMwKyVTb5ij9+u4VJG/5EgEMMmFF01cFai3isRbKbzb+YaU/MQbAm2XSMoUPAmvZzbuKYRIFApbtlrfFuUGd6vq2hXNnH78ZLh/iFhsQG3T4D1ib7k5CC6vY0DCbtrohgLEIClXiGtl10zc0CnEGIhhatLBva7NP58Tvw0qE8yWhARLQ8h4+AhQSP+I4F5xoU+VilGRJs6wnS7ruti/4KvAY/CfdgqjsMy4pf8fodQO8/gnuX3f/3xi3om1/h7THr+co3x93PP9+FBUfbNUjcjEmhcrkT+8K7ml7V10Jo05mpIEFy1NmCJWx9SIKKt+EjAL4Ez8EBVOB6havuT/rByPvHXK+9zUcfcbb254+9fydJknYnRr1oGfdaiAgpxu1Rx/Rek8KISftx3L+DfsLWAANn8Hvw0/AFeAGO9DFV3c6D+CcWbL8Dj9e7f+T1k8AZv/d7+PXWM/Z+VvdCrIvuAKO09RpEEQJM0Ci6+B4xhTWr4cZNOvhktabw0ta0rSJmqz3Yw5/AKXwenod7cAhTmBSPKf6JBdvH8IP17h95pXqw50/+BFnj88fev4NchyaK47OPhhtI8RFSvAfDSNh0Ck0p2gLxGkib5NJj/JWCr90EWQJvwBzO4AHcgztwAFN1evHPUVGwfXON+0debT1YeGON9Yy9/63X+OguiwmhIhQhD7l4sMqlG3D86Suc3qWZ4rWjI1X7u0Ytw6x3rIMeIOPDprfe2XzNgyj6PahhBjO4C3e6puDgXrdg+/5l948vF3bqwZetZ+z9Rx9zdIY5pInPK4Nk0t+l52xdK2B45Qd87nM8fsD5EfUhIcJcERw4RdqqH7Yde5V7m1vhNmtedkz6EDzUMF/2jJYWbC+4fzzA/Y+/8PPH3j9dcBAPIRP8JLXd5BpAu03aziOL3VVHZzz3CXWDPWd+SH2AnxIqQoTZpo9Ckc6HIrFbAbzNmlcg8Ag8NFDDAhbJvTBZXbC94P7t68EXfv6o+21gUtPETU7bbkLxvNKRFG2+KXzvtObonPP4rBvsgmaKj404DlshFole1Glfh02fE7bYR7dZ82oTewIBGn1Md6CG6YUF26X376oevOLzx95vhUmgblI6LBZwTCDY7vMq0op5WVXgsObOXJ+1x3qaBl9j1FeLxbhU9w1F+Wiba6s1X/TBz1LnUfuYDi4r2C69f1f14BWfP+p+W2GFKuC9phcELMYRRLur9DEZTUdEH+iEqWdaM7X4WOoPGI+ZYD2+wcQ+y+ioHUZ9dTDbArzxmi/bJI9BND0Ynd6lBdve/butBw8+f/T9D3ABa3AG8W3VPX4hBin+bj8dMMmSpp5pg7fJ6xrBFE2WQQEWnV8Qg3FbAWzYfM1rREEnmvkN2o1+acG2d/9u68GDzx91v3mAjb1zkpqT21OipPKO0b9TO5W0nTdOmAQm0TObts3aBKgwARtoPDiCT0gHgwnbArzxmtcLc08HgF1asN0C4Ms/fvD5I+7PhfqyXE/b7RbbrGyRQRT9ARZcwAUmgdoz0ehJ9Fn7QAhUjhDAQSw0bV3T3WbNa59jzmiP6GsWbGXDX2ytjy8+f9T97fiBPq9YeLdBmyuizZHaqXITnXiMUEEVcJ7K4j3BFPurtB4bixW8wTpweL8DC95szWMOqucFYGsWbGU7p3TxxxefP+r+oTVktxY0v5hbq3KiOKYnY8ddJVSBxuMMVffNbxwIOERShst73HZ78DZrHpmJmH3K6sGz0fe3UUj0eyRrSCGTTc+rjVNoGzNSv05srAxUBh8IhqChiQgVNIIBH3AVPnrsnXQZbLTm8ammv8eVXn/vWpaTem5IXRlt+U/LA21zhSb9cye6jcOfCnOwhIAYXAMVTUNV0QhVha9xjgA27ODJbLbmitt3tRN80lqG6N/khgot4ZVlOyO4WNg3OIMzhIZQpUEHieg2im6F91hB3I2tubql6BYNN9Hj5S7G0G2tahslBWKDnOiIvuAEDzakDQKDNFQT6gbn8E2y4BBubM230YIpBnDbMa+y3dx0n1S0BtuG62lCCXwcY0F72T1VRR3t2ONcsmDjbmzNt9RFs2LO2hQNyb022JisaI8rAWuw4HI3FuAIhZdOGIcdjLJvvObqlpqvWTJnnQbyi/1M9O8UxWhBs//H42I0q1Yb/XPGONzcmm+ri172mHKvZBpHkJaNJz6v9jxqiklDj3U4CA2ugpAaYMWqNXsdXbmJNd9egCnJEsphXNM+MnK3m0FCJ5S1kmJpa3DgPVbnQnPGWIDspW9ozbcO4K/9LkfaQO2KHuqlfFXSbdNzcEcwoqNEFE9zcIXu9/6n/ym/BC/C3aJLzEKPuYVlbFnfhZ8kcWxV3dbv4bKl28566wD+8C53aw49lTABp9PWbsB+knfc/Li3eVizf5vv/xmvnPKg5ihwKEwlrcHqucuVcVOxEv8aH37E3ZqpZypUulrHEtIWKUr+txHg+ojZDGlwnqmkGlzcVi1dLiNSJiHjfbRNOPwKpx9TVdTn3K05DBx4psIk4Ei8aCkJahRgffk4YnEXe07T4H2RR1u27E