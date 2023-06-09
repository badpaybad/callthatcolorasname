
extension UniqueItemInList<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNull() {
    if (length > 0) {
      return first;
    }
    return null;
  }
}

