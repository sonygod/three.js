import haxe.macro.Context;
import haxe.macro.Expr;

class MaterialResources {
	public static inline function getMaterialResources():Array<Expr> {
		return [
			#ShadowMaterial,
			#SpriteMaterial,
			#RawShaderMaterial,
			#ShaderMaterial,
			#PointsMaterial,
			#MeshPhysicalMaterial,
			#MeshStandardMaterial,
			#MeshPhongMaterial,
			#MeshToonMaterial,
			#MeshNormalMaterial,
			#MeshLambertMaterial,
			#MeshDepthMaterial,
			#MeshDistanceMaterial,
			#MeshBasicMaterial,
			#MeshMatcapMaterial,
			#LineDashedMaterial,
			#LineBasicMaterial,
			#Material
		];
	}
}

class MaterialExports {
	public static inline function getMaterialExports():Array<Expr> {
		return [
			Expr.Ident("ShadowMaterial"),
			Expr.Ident("SpriteMaterial"),
			Expr.Ident("RawShaderMaterial"),
			Expr.Ident("ShaderMaterial"),
			Expr.Ident("PointsMaterial"),
			Expr.Ident("MeshPhysicalMaterial"),
			Expr.Ident("MeshStandardMaterial"),
			Expr.Ident("MeshPhongMaterial"),
			Expr.Ident("MeshToonMaterial"),
			Expr.Ident("MeshNormalMaterial"),
			Expr.Ident("MeshLambertMaterial"),
			Expr.Ident("MeshDepthMaterial"),
			Expr.Ident("MeshDistanceMaterial"),
			Expr.Ident("MeshBasicMaterial"),
			Expr.Ident("MeshMatcapMaterial"),
			Expr.Ident("LineDashedMaterial"),
			Expr.Ident("LineBasicMaterial"),
			Expr.Ident("Material")
		];
	}
}

@:isResource("MaterialResources", MaterialResources.getMaterialResources())
@:export(MaterialExports.getMaterialExports())
class Material {
}