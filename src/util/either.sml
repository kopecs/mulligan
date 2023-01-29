(** Brandon Wu 
  *
  * Copyright (c) 2022-2023
  * See the file LICENSE for details.
  *)

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(* Just a library for an either type.
 *)

(*****************************************************************************)
(* Implementation *)
(*****************************************************************************)

structure Either =
  struct
    datatype ('a, 'b) t = INL of 'a | INR of 'b
  end

datatype either = datatype Either.t