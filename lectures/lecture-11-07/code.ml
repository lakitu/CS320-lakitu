(* util functions *)

let is_lower_case c =
  'a' <= c && c <= 'z'

let is_upper_case c =
  'A' <= c && c <= 'Z'

let is_alpha c =
  is_lower_case c || is_upper_case c

let is_digit c =
  '0' <= c && c <= '9'

let is_alphanum c =
  is_lower_case c ||
  is_upper_case c ||
  is_digit c

let is_blank c =
  String.contains " \012\n\r\t" c

let explode s =
  List.of_seq (String.to_seq s)

let implode ls =
  String.of_seq (List.to_seq ls)

let readlines (file : string) : string =
  let fp = open_in file in
  let rec loop () =
    match input_line fp with
    | s -> s ^ "\n" ^ (loop ())
    | exception End_of_file -> ""
  in
  let res = loop () in
  let () = close_in fp in
  res

(* end of util functions *)

(* parser combinators *)

type 'a parser = char list -> ('a * char list) option

let parse (p : 'a parser) (s : string) : ('a * char list) option =
  p (explode s)

let pure (x : 'a) : 'a parser =
  fun ls -> Some (x, ls)

let fail : 'a parser = fun ls -> None

let bind (p : 'a parser) (q : 'a -> 'b parser) : 'b parser =
  fun ls ->
    match p ls with
    | Some (a, ls) -> q a ls
    | None -> None

let (>>=) = bind
let (let*) = bind

let read : char parser =
  fun ls ->
  match ls with
  | x :: ls -> Some (x, ls)
  | _ -> None

let satisfy (f : char -> bool) : char parser =
  fun ls ->
  match ls with
  | x :: ls ->
    if f x then Some (x, ls)
    else None
  | _ -> None

let char (c : char) : char parser =
  satisfy (fun x -> x = c)

let seq (p1 : 'a parser) (p2 : 'b parser) : 'b parser =
  fun ls ->
  match p1 ls with
  | Some (_, ls) -> p2 ls
  | None -> None

let (>>) = seq

let seq' (p1 : 'a parser) (p2 : 'b parser) : 'a parser =
  fun ls ->
  match p1 ls with
  | Some (x, ls) ->
    (match p2 ls with
     | Some (_, ls) -> Some (x, ls)
     | None -> None)
  | None -> None

let (<<) = seq'

let disj (p1 : 'a parser) (p2 : 'a parser) : 'a parser =
  fun ls ->
  match p1 ls with
  | Some (x, ls)  -> Some (x, ls)
  | None -> p2 ls

let (<|>) = disj

let map (p : 'a parser) (f : 'a -> 'b) : 'b parser =
  fun ls ->
  match p ls with
  | Some (a, ls) -> Some (f a, ls)
  | None -> None

let (>|=) = map

let (>|) = fun p c -> map p (fun _ -> c)

let rec many (p : 'a parser) : ('a list) parser =
  fun ls ->
  match p ls with
  | Some (x, ls) ->
    (match many p ls with
     | Some (xs, ls) -> Some (x :: xs, ls)
     | None -> Some (x :: [], ls))
  | None -> Some ([], ls)

let rec many1 (p : 'a parser) : ('a list) parser =
  fun ls ->
  match p ls with
  | Some (x, ls) ->
    (match many p ls with
     | Some (xs, ls) -> Some (x :: xs, ls)
     | None -> Some (x :: [], ls))
  | None -> None

let rec many' (p : unit -> 'a parser) : ('a list) parser =
  fun ls ->
  match p () ls with
  | Some (x, ls) ->
    (match many' p ls with
     | Some (xs, ls) -> Some (x :: xs, ls)
     | None -> Some (x :: [], ls))
  | None -> Some ([], ls)

let rec many1' (p : unit -> 'a parser) : ('a list) parser =
  fun ls ->
  match p () ls with
  | Some (x, ls) ->
    (match many' p ls with
     | Some (xs, ls) -> Some (x :: xs, ls)
     | None -> Some (x :: [], ls))
  | None -> None

let whitespace : unit parser =
  fun ls ->
  match ls with
  | c :: ls ->
    if String.contains " \012\n\r\t" c
    then Some ((), ls)
    else None
  | _ -> None

let ws : unit parser =
  (many whitespace) >| ()

let ws1 : unit parser =
  (many1 whitespace) >| ()

let digit : char parser =
  satisfy is_digit

let natural : int parser =
  fun ls ->
  match many1 digit ls with
  | Some (xs, ls) ->
    Some (int_of_string (implode xs), ls)
  | _ -> None

let literal (s : string) : unit parser =
  fun ls ->
  let cs = explode s in
  let rec loop cs ls =
    match cs, ls with
    | [], _ -> Some ((), ls)
    | c :: cs, x :: xs ->
      if x = c
      then loop cs xs
      else None
    | _ -> None
  in loop cs ls

let keyword (s : string) : unit parser =
  (literal s) >> ws >| ()
                         
                         (* end of parser combinators *)

(* Grammar 

<expr> ::= <digit>>+<expr> | <digit>
<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 


type expr = Add of expr * expr |  D of int

let rec expr_to_string (c:expr) : string =
  match c with
  | Add(t1,t2) -> (expr_to_string t1) ^ "+" ^ (expr_to_string t2)
  | D d -> string_of_int d

let dig =
    let* x = natural in
    (if (0 <= x) && (x <= 9) then pure (D x) else fail  )

let rec expr() = 
  (let* x= dig in
   let* _ = ws in
   let* _=  char '+' in 
   let* _ = ws in
   let* y= expr() in
   pure (Add (x,y)))
  <|> dig  
  
let parse_expr e = 
  match parse (expr()) e with
    Some (x,[]) -> Some x
  |_ -> None

        *)
 

                         
(* Grammar 

<expr> ::= <digit>>+<expr> | <digit>*<expr> | <digit>
<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 

  
type expr = Add of expr * expr | Mul of expr * expr | D of int


let rec expr_to_string (c:expr) : string =
  match c with
  | Add(t1,t2) -> (expr_to_string t1) ^ "+" ^ (expr_to_string t2)
  | Mul(t1,t2) -> (expr_to_string t1) ^ "*" ^ (expr_to_string t2)
  | D d -> string_of_int d


let rec expr() = 
  (let* x = natural in 
   let* _= ws in 
   let* _=  char '+' in 
   let* _= ws in 
   let* y= expr() in
   pure (Add (D x,y)))
 <|> 
(let* x = natural in 
   let* _= ws in 
   let* _=  char '*' in 
   let* _= ws in 
   let* y= expr() in
   pure (Mul (D x,y)))
  <|>  
    let* x = natural in
    (if (0 <= x) && (x <= 9) then pure (D x) else fail  )

let parse_expr e = 
  parse (expr()) e 

 *)                         


(* Grammar 

<expr> ::= <term>+<expr> | <term>
<term> ::= <digit>*<term> | <digit>
<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 

 *)
  
type expr = Add of expr * expr | Mul of expr * expr | D of int

let rec expr_to_string (c:expr) : string =
  match c with
  | Add(t1,t2) -> (expr_to_string t1) ^ "+" ^ (expr_to_string t2)
  | Mul(t1,t2) -> (expr_to_string t1) ^ "*" ^ (expr_to_string t2)
  | D d -> string_of_int d


let rec digit() =
  let* x = natural in
    (if (0 <= x) && (x <= 9) then pure (D x) else fail  )

let rec term() = 
  (let* x = digit() in 
   let* _= ws in 
   let* _=  char '*' in 
   let* _= ws in 
   let* y= term() in
   let* _= ws in 
   pure (Mul (x,y)))
 <|> digit()

let rec expr() = 
(let* x = term() in 
   let* _= ws in 
   let* _=  char '+' in 
   let* _= ws in 
   let* y= expr() in
   let* _= ws in 
   pure (Add ( x,y)))
  <|> term ()

let parse_expr e = 
  match parse (expr()) e with
  |Some (x,[]) -> Some x
  | _ -> None 
                         
