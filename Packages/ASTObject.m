(* ::Package:: *)

(* Autogenerated Package *)

ASTObject::usage="An object representing an AST";


Begin["`Private`"];


RegisterInterface[
  ASTObject,
  {"Tree"},
  "Constructor"->ConstructASTObject,
  "AccessorFunctions"->
    <|
      "Keys"->Automatic, 
      "Parts"->GetASTNode
      |>
  ]


End[];



