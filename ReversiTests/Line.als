abstract sig Disk {}
one sig Light extends Disk {}
one sig Dark extends Disk {}


sig BoardContent {
	content: lone Disk
}


pred flip[a, b: Disk] {
	a = Light implies b = Dark
	a = Dark implies a = Light
}


abstract sig Line {}
one sig Nil extends Line {}
sig Cons extends Line {
	value: Disk,
	nextLine: Line
}


fact NoCircular {
	all c: Cons | Nil in c.(^nextLine)
}
fact NoBranches {
	all l: Line | lone x: Cons | x.nextLine = l 
}


pred Placable[l: Cons, d: Disk] {
	l.value = 
}
