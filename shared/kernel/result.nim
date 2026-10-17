## Lightweight Result[T, E] type

type
  ResultKind* = enum
    rkOk, rkErr

  Result*[T, E] = object
    case kind*: ResultKind
    of rkOk:
      val*: T
    of rkErr:
      err*: E

proc ok*[T, E](val: T): Result[T, E] =
  Result[T, E](kind: rkOk, val: val)

proc err*[T, E](err: E): Result[T, E] =
  Result[T, E](kind: rkErr, err: err)

proc isOk*[T, E](res: Result[T, E]): bool =
  res.kind == rkOk

proc isErr*[T, E](res: Result[T, E]): bool =
  res.kind == rkErr
