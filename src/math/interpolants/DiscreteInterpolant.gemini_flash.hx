package ;

import haxe.extern.EitherType;

class DiscreteInterpolant extends Interpolant {
	
	public function new(parameterPositions:Array<EitherType<Float, Array<Float>>>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>){
		super(parameterPositions, sampleValues, sampleSize, resultBuffer);
	}

	override public function interpolate_( i1 : Int, ?t0 : Float, ?t : Float, ?t1 : Float) : Void {
		this.copySampleValue_(i1 - 1);
	}
}