
structure Token =
  struct
    datatype t =
        NUM of int
      | SYMBOL of Symbol.symbol
      | STEP
      | REVEAL
      | STOP
      | PREV

      | EQUAL
      | SET

      | EOF

    fun to_string t =
      case t of
        NUM i => "NUM " ^ Int.toString i
      | SYMBOL sym => Symbol.toValue sym
      | STEP => "STEP"
      | REVEAL => "REVEAL"
      | STOP => "STOP"
      | EQUAL => "EQUAL"
      | SET => "SET"
      | PREV => "PREV"
      | EOF => "EOF"

  end
