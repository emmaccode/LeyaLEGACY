<div align="center"><img src="https://github.com/emmettgb/Leya/blob/master/Leya_Round.png" width="400" /><h2>0.0.2</h2></div>



### Installation
**This package depends heavily on nasm, which is not compatible with kernels that aren't Linux-based.**
```bash
[emmett@emmett-kabylake Downloads] git clone https://github.com/emmettgb/Leya
[emmett@emmett-kabylake Downloads] cd Leya
[emmett@emmett-kabylake Leya]$ . install.sh
[emmett@emmett-kabylake Leya]$ leya
__________________
|Welcome to Leya!|
|~~~~~~~~~~~~~~~~|
|    V 0.0.2     |
| Copyright 2020 |
| Emmett         |
|    Boudreau    |
------------------
emmett in Leya 🦩 } (* 5 5)
25
emmett in Leya 🦩 } 
```
### Some quick examples!
```clisp
(function add (x y) (+ x y))
(var sum (add 5 10))
```
**var is used to define a global variable, like setq in common lisp. Function is the equivalent of defun.**
