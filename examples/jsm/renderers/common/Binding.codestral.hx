class Binding {

    public var name: String = "";
    public var visibility: Int = 0;

    public function new(name: String = "") {
        this.name = name;
    }

    public function setVisibility(visibility: Int): Void {
        this.visibility |= visibility;
    }

    public function clone(): Binding {
        var cloned = new Binding(this.name);
        cloned.visibility = this.visibility;
        return cloned;
    }
}