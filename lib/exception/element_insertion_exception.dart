class ElementInsertionException implements Exception{
  String cause;
  ElementInsertionException(this.cause);
  @override
  String toString(){
    return "ElementInsertionException: $cause";
  }
}