package three.core;

class Uniform<T> {
	
	public var value:T;
	
	public function new(value:T) {
		this.value = value;
	}
	
	public function clone():Uniform<T> {
		return new Uniform<T>(this.value.clone == null ? this.value : this.value.clone());
	}
}