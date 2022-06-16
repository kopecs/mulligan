
structure Basis :
  sig
    val initial : SMLSyntax.context
  end =
  struct
    open SMLSyntax
    open Value
    open Error

    val sym = Symbol.fromValue

    infix |>
    fun x |> f = f x

    val sym_true = sym "true"
    val sym_false = sym "false"

    fun dict_from_list l =
      List.foldl
        (fn ((key, elem), dict) =>
          SymDict.insert dict key elem
        )
        SymDict.empty
        l

    fun convert b =
      if b then
        Vconstr {id = [sym_true], arg = NONE}
      else
        Vconstr {id = [sym_false], arg = NONE}

    fun poly_eq v1 v2 =
      case (v1, v2) of
        (Vnumber (Int i1), Vnumber (Int i2)) => i1 = i2
      | (Vnumber (Word w1), Vnumber (Word w2)) => w1 = w2
      | (Vstring s1, Vstring s2) => Symbol.eq (s1, s2)
      | (Vchar c1, Vchar c2) => c1 = c2
      | (Vrecord fields1, Vrecord fields2) =>
          let
            fun subset fields1 fields2 =
              List.foldl
                (fn ({lab, value}, acc) =>
                  acc andalso
                  (case List.find (fn {lab = lab', ...} => Symbol.eq (lab, lab')) fields2 of
                    NONE => false
                  | SOME {value = value', ...} => poly_eq value value'
                  )
                )
                true
                fields1
          in
            subset fields1 fields2 andalso subset fields2 fields1
          end
      | (Vunit, Vunit) => true
      | (Vconstr {id, arg}, Vconstr {id = id', arg = arg'}) =>
          longid_eq (id, id') andalso
          (case (arg, arg') of
            (NONE, NONE) => true
          | (SOME v, SOME v') => poly_eq v v'
          | _ => false
          )
      | (Vselect sym, Vselect sym') => Symbol.eq (sym, sym')
      | (Vtuple vs1, Vtuple vs2) =>
          ListPair.allEq (fn (v, v') => poly_eq v v') (vs1, vs2)
      | (Vlist vs1, Vlist vs2) =>
          ListPair.allEq (fn (v, v') => poly_eq v v') (vs1, vs2)
      | (Vinfix {left, id, right}, Vinfix {left=left', id=id', right=right'}) =>
          poly_eq left left' andalso poly_eq right right' andalso Symbol.eq (id, id')
      | (Vfn _, _) => prog_err "= called on function value"
      | (_, Vfn _) => prog_err "= called on function value"
      | (Vbasis {name, ...}, _) => prog_err "= called on basis function value"
      | (_, Vbasis {name, ...}) => prog_err "= called on basis function value"
      | _ => false

    val poly_eq = fn v1 => fn v2 => convert (poly_eq v1 v2)


    (* TODO: word stuff *)
    val initial_values =
      [ ( "+"
        , (fn Vtuple [Vnumber (Int i1), Vnumber (Int i2)] => Vnumber (Int (i1 + i2))
          | Vtuple [Vnumber (Real r1), Vnumber (Real r2)] => Vnumber (Real (r1 + r2))
          | _ => eval_err "invalid args to +"
          )
        )
      , ( "-"
        , (fn Vtuple [Vnumber (Int i1), Vnumber (Int i2)] => Vnumber (Int (i1 - i2))
          | Vtuple [Vnumber (Real r1), Vnumber (Real r2)] => Vnumber (Real (r1 - r2))
          | _ => eval_err "invalid args to -"
          )
        )
      , ( "*"
        , (fn Vtuple [Vnumber (Int i1), Vnumber (Int i2)] => Vnumber (Int (i1 * i2))
          | Vtuple [Vnumber (Real r1), Vnumber (Real r2)] => Vnumber (Real (r1 * r2))
          | _ => eval_err "invalid args to *"
          )
        )
      , ( "div"
        , (fn Vtuple [Vnumber (Int i1), Vnumber (Int i2)] => Vnumber (Int (i1 div i2))
          | _ => eval_err "invalid args to div"
          )
        )
      , ( "mod"
        , (fn Vtuple [Vnumber (Int i1), Vnumber (Int i2)] => Vnumber (Int (i1 mod i2))
          | _ => eval_err "invalid args to div"
          )
        )
      , ( "/"
        , (fn Vtuple [Vnumber (Real r1), Vnumber (Real r2)] => Vnumber (Real (r1 / r2))
          | _ => eval_err "invalid args to /"
          )
        )
      , ( "not"
        , (fn Vconstr {id = [x], arg = NONE} =>
            if Symbol.eq (x, sym_true) then
              Vconstr {id = [sym_false], arg = NONE}
            else if Symbol.eq (x, sym_false) then
              Vconstr {id = [sym_true], arg = NONE}
            else
              eval_err "invalid arg to `not`"
          | _ => eval_err "invalid arg to `not`"
          )
        )
      , ( "^"
        , (fn Vtuple [Vstring s1, Vstring s2] =>
              Vstring (Symbol.fromValue (Symbol.toValue s1 ^ Symbol.toValue s2))
          | _ => eval_err "invalid args to ^"
          )
        )
      , ( "chr"
        , (fn Vnumber (Int i) => Vchar (Char.chr i)
          | _ => eval_err "invalid args to `chr`"
          )
        )
      , ( "explode"
        , (fn Vstring s => Vlist (List.map Vchar (String.explode (Symbol.toValue s)))
          | _ => eval_err "invalid args to `explode`"
          )
        )
      , ( "floor"
        , (fn Vnumber (Real r) => Vnumber (Int (Real.floor r))
          | _ => eval_err "invalid args to `floor`"
          )
        )
      , ( "ord"
        , (fn Vchar c => Vnumber (Int (Char.ord c))
          | _ => eval_err "invalid arg to `ord`"
          )
        )
      , ( "real"
        , (fn Vnumber (Int i) => Vnumber (Real (real i))
          | _ => eval_err "invalid arg to `real`"
          )
        )
      , ( "size"
        , (fn Vstring s => Vnumber (Int (String.size (Symbol.toValue s)))
          | _ => eval_err "invalid arg to `size`"
          )
        )
      , ( "str"
        , (fn Vchar c => Vstring (Symbol.fromValue (str c))
          | _ => eval_err "invalid arg to `str`"
          )
        )
      , ( "round"
        , (fn Vnumber (Real r) => Vnumber (Int (round r))
          | _ => eval_err "invalid arg to `round`"
          )
        )
      , ( "substring"
        , (fn Vtuple [Vstring s, Vnumber (Int i1), Vnumber (Int i2)] =>
            ( Vstring
              (Symbol.fromValue (String.substring (Symbol.toValue s, i1, i2))) handle Subscript =>
                raise Context.Raise (Vconstr {id = [Symbol.fromValue "Subscript"], arg = NONE})
            )
          | _ => eval_err "invalid args to `substring`"
          )
        )
      , ( "~"
        , (fn Vnumber (Int i) => Vnumber (Int (~i))
          | Vnumber (Real i) => Vnumber (Real (~i))
          | _ => eval_err "invalid arg to `~`"
          )
        )
      , ( "="
        , (fn Vtuple [left, right] => poly_eq left right
          | _ => eval_err "invalid arg to `=`"
          )
        )
      ]
      |> List.map (fn (x, y) => (sym x, Vbasis { name = sym x, function = y }))

    val initial_cons =
      [ "SOME", "NONE", "true", "false", "::", "LESS", "EQUAL", "GREATER",
         "nil", "Match", "Bind", "Div", "Fail"]
      |> List.map sym

    val initial_exns =
      [ "Fail", "Bind", "Match", "Div", "Subscript" ]
      |> List.map sym

    val initial_mods = []

    val initial_infix =
      [ ( "div", (LEFT, 7) )
      , ( "mod", (LEFT, 7) )
      , ( "*", (LEFT, 7) )
      , ( "/", (LEFT, 7) )

      , ( "+", (LEFT, 6) )
      , ( "-", (LEFT, 6) )
      , ( "^", (LEFT, 6) )

      , ( "::", (RIGHT, 5) )
      , ( "@", (RIGHT, 5) )

      , ( "<>", (LEFT, 4) )
      , ( "=", (LEFT, 4) )
      , ( "<", (LEFT, 4) )
      , ( ">", (LEFT, 4) )
      , ( "<=", (LEFT, 4) )
      , ( ">=", (LEFT, 4) )

      , ( ":=", (LEFT, 3) )
      , ( "o", (LEFT, 3) )

      , ( "before", (LEFT, 0) )
      ]
      |> List.map (fn (x, y) => (sym x, y))

    val initial_tys =
      [ ( "order"
        , ( 0
          , [ ("LESS", NONE)
            , ("GREATER", NONE)
            , ("EQUAL", NONE)
            ]
          )
        )
      , ( "option"
        , ( 1
          , [ ("SOME", SOME (Ttyvar (sym "'a")))
            , ("NONE", NONE)
            ]
          )
        )
      , ( "list"
        , ( 1
          , [ ("::", SOME ( Tprod [ Ttyvar (sym "'a")
                                  , Tapp ([Ttyvar (sym "'a")], [sym "list"])
                                  ]
                          )
              )
            , ("nil", NONE)
            ]
          )
        )
      , ( "unit"
        , ( 0
          , [ ("()", NONE) ]
          )
        )
        (* TODO: int, real, types with weird constructors? *)
      ]
      |> List.map
           (fn (tycon, (arity, cons)) =>
             (sym tycon
             , { arity = arity
               , cons = List.map (fn (x, y) => { id = sym x, ty = y }) cons
               }
             )
           )

    fun sym_from_list l =
      List.foldl
        (fn (x, acc) =>
          SymSet.insert acc x
        )
        SymSet.empty
        l

    val initial_scope =
      Scope
        { valdict = dict_from_list initial_values
        , condict = sym_from_list initial_cons
        , exndict = sym_from_list initial_exns
        , moddict = dict_from_list initial_mods
        , infixdict = dict_from_list initial_infix
        , tydict = dict_from_list initial_tys
        }


    val initial =
      { scope = initial_scope
      , outer_scopes = []
      , sigdict = SymDict.empty
      , functordict = SymDict.empty
      , hole_print_fn = fn () => PrettySimpleDoc.text TerminalColors.white "<hole>"
      , settings =
          { break_assigns = ref SymSet.empty
          , substitute = ref true
          , step_app = ref true
          , step_arithmetic = ref false
          , print_dec = ref true
          , print_depth = ref 1
          }
      }
  end
