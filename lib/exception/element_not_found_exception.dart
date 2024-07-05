class ElementNotFoundException implements Exception{
  String cause;
  ElementNotFoundException(this.cause);
  @override
  String toString(){
    return "ElementNotFoundException: $cause";
  }
}