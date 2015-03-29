% Макросы (ВНИМАНИЕ перевод в черновом варианте!)

К этому моменту вы узнали о многих инструментах Rust, которые нацелены на абстрагирование и повторное использование кода. Эти единицы повторно использованного кода имеют богатую смысловую структуру. Например, функции имеют сигнатуры типа, типы параметров могут имеют ограничения по трейтам, перегруженные функции также могут принадлежать к определенному трейту.

Эта структура означает, что ключевые абстракции Rust имеют мощный механизм проверки времени компиляции. Но это достигается за счет снижения гибкости. Если вы визуально определите структуру повторно используемого кода, то вы можете найти трудным или громоздким выражение этой схемы в виде дженерик функции, трейта, или чего-то еще в семантике Rust.

Макросы позволяют абстрагироваться на *синтаксическом* уровне. Вызов макроса является сокращением для "расширенной" синтаксической формы. Это расширение происходит в начале компиляции, до начала статической проверки. В результате, макросы могут охватить много шаблонов повторного использования кода, которые невозможны при использовании лишь ключевых абстракций Rust.

Недостатком является то, что код, основанный на макросах, может быть трудным для понимания, потому что к нему применяется меньше встроенных правил. Подобно обычной функции, качественный макрос может быть использован без понимания его реализации. Тем не менее, может быть трудно разработать качественный макрос! Кроме того, ошибки компилятора в макро коде сложнее интерпретировать, потому что они описывают проблемы в расширенной форме кода, а не в исходной сокращенной форме кода, которую используют разработчики.

Эти недостатки делают макросы чем-то вроде "фичи последней инстанции". Это не означает, что макросы это плохо; они являются частью Rust, потому что иногда они все же нужны для по-настоящему краткой записи хорошо абстрагированной части кода. Просто имейте этот компромисс в виду.

# Определение макросов

Вы, возможно, видели макрос `vec!`, который используется для инициализации [вектора][vector] с произвольным количеством элементов.

[vector]: arrays-vectors-and-slices.html

```rust
let x: Vec<u32> = vec![1, 2, 3];
# assert_eq!(&[1,2,3], &x);
```

Его нельзя реализовать в виде обычной функциии, так как он принимает любое количество аргументов. Но мы можем представить его в виде синтаксического сокращения для следующего кода

```rust
let x: Vec<u32> = {
    let mut temp_vec = Vec::new();
    temp_vec.push(1);
    temp_vec.push(2);
    temp_vec.push(3);
    temp_vec
};
# assert_eq!(&[1,2,3], &x);
```

Мы можем реализовать это сокращение, используя макрос: [^actual]

[^actual]: Фактическое определение `vec!` в libcollections отличается от представленной здесь по соображениям эффективности и повторного использования. Некоторые из них упомянуты в главе [продвинутые макросы][advanced macros chapter].

```rust
macro_rules! vec {
    ( $( $x:expr ),* ) => {
        {
            let mut temp_vec = Vec::new();
            $(
                temp_vec.push($x);
            )*
            temp_vec
        }
    };
}
# fn main() {
#     assert_eq!([1,2,3], vec![1,2,3]);
# }
```

Вау, тут много нового синтаксиса! Давайте разберем его.

```ignore
macro_rules! vec { ... }
```

Тут мы определяем макрос с именем `vec`, аналогично тому, как `fn vec` определяло бы функцию с именем `vec`. При вызове мы неформально пишем имя макроса с восклицательным знаком, например, `vec!`. Восклицательный знак является частью синтаксиса вызова и служит для того, чтобы отличать макрос от обычной функции.

## Matching

Макрос определяется с помощью ряда *правил*, которые представляют собой варианты сопоставления с образцом. Выше у нас было

```ignore
( $( $x:expr ),* ) => { ... };
```

Это как вариант выражения `match`, но сопоставление происходит на уровне синтаксических деревьев Rust, на этапе компиляции. Точка с запятой не является обязательной для последнего (только здесь) варианта. "Шаблон" слева от `=>` известен как *шаблон совпадений* (*matcher*). Он имеет [свою собственную грамматику][their own little grammar] в рамках языка.

[their own little grammar]: ../reference.html#macros

Шаблон `$x:expr` будет соответствовать любому выражению Rust, связывая его дерево синтаксиса с *метапеременной* `$x`. Идентификатор `expr` является *спецификатором фрагмента*; полные возможности перечислены в главе [продвинутые макросы][advanced macros chapter]. Шаблон, окруженный `$(...),*`, будет соответствовать нулю или более выражениям, разделенным запятыми.

Помимо специального синтаксиса шаблона совпадений, любые токены Rust, которые появляются в шаблоне должны в точности совпадать. Например,

```rust
macro_rules! foo {
    (x => $e:expr) => (println!("mode X: {}", $e));
    (y => $e:expr) => (println!("mode Y: {}", $e));
}

fn main() {
    foo!(y => 3);
}
```

выведет

```text
mode Y: 3
```

А с

```rust,ignore
foo!(z => 3);
```

мы получим ошибку компиляции

```text
error: no rules expected the token `z`
```

## Раскрытие

The right-hand side of a macro rule is ordinary Rust syntax, for the most part.
But we can splice in bits of syntax captured by the matcher. From the original
example:
С правой стороны макро правил используется, по большей части, обычный синтаксис Rust. Но мы можем соединить кусочки синтаксиса, захваченные шаблоном. Из предыдущего примера:

```ignore
$(
    temp_vec.push($x);
)*
```

Each matched expression `$x` will produce a single `push` statement in the
macro expansion. The repetition in the expansion proceeds in "lockstep" with
repetition in the matcher (more on this in a moment).
Каждое соответствие выражению `$x` будет производить одиночный оператор `push` в раскрытой форме макроса. Повторение в расширение происходит в "ногу" с повторением в шаблоне совпадений (более подробно об этом чуть позже).

Because `$x` was already declared as matching an expression, we don't repeat
`:expr` on the right-hand side. Also, we don't include a separating comma as
part of the repetition operator. Instead, we have a terminating semicolon
within the repeated block.
Поскольку `$x` уже объявлен как шаблонное выражение, мы не повторяем `:expr` с правой стороны. Кроме того, мы не включаем разделительную запятую в качестве части оператора повторения. Вместо этого, у нас есть точка с запятой в пределах повторяемого блока.

Еще одна деталь: макрос `vec!` имеет *две* пары фигурных скобках правой части. Они часто сочетаются таким образом:

```ignore
macro_rules! foo {
    () => {{
        ...
    }}
}
```

Внешние скобки являются частью синтаксиса `macro_rules!`. На самом деле, вы можете использовать `()` или `[]` вместо них. Они просто разграничивают правую часть в целом.

Внутренние скобки являются частью расширенного синтаксиса. Помните, что макрос `vec!` используется в контексте выражения. Мы используем блок, чтобы записать выражение с множественными состояниями, в том числе включающее `let` привязки. Если ваш макрос раскрывается в одно единственное выражение, то дополнительной слой скобок не нужен.

Note that we never *declared* that the macro produces an expression. In fact,
this is not determined until we use the macro as an expression. With care, you
can write a macro whose expansion works in several contexts. For example,
shorthand for a data type could be valid as either an expression or a pattern.
Обратите внимание, что мы никогда не *говорили*, что макрос создает выражения. На самом деле, это не определяется, пока мы не использовать макрос как выражение. С осторожностью, вы можете написать макрос, разложение которого работает в нескольких контекстах. Например, сокращение для типа данных может быть действительным или как выражение или рисунком.

## Repetition

Оператору повтора всегда сопутствуют два основных правила:

1. `$(...)*` walks through one "layer" of repetitions, for all of the `$name`s
   it contains, in lockstep, and
2. each `$name` must be under at least as many `$(...)*`s as it was matched
   against. If it is under more, it'll be duplicated, as appropriate.
1. `$(...)*` проходит через один "слой" повторений, для всех `$name`, которые он содержит, в ногу, и
2. каждое `$name` должно быть под крайней мере, столько `$(...)*`, как это было сопоставляется. Если это в более, это будет дублироваться, при необходимости.

This baroque macro illustrates the duplication of variables from outer
repetition levels.
Этот причудливый макрос иллюстрирует дублирования переменных из внешних уровней повторения.

```rust
macro_rules! o_O {
    (
        $(
            $x:expr; [ $( $y:expr ),* ]
        );*
    ) => {
        &[ $($( $x + $y ),*),* ]
    }
}

fn main() {
    let a: &[i32]
        = o_O!(10; [1, 2, 3];
               20; [4, 5, 6]);

    assert_eq!(a, [11, 12, 13, 24, 25, 26]);
}
```

That's most of the matcher syntax. These examples use `$(...)*`, which is a
"zero or more" match. Alternatively you can write `$(...)+` for a "one or
more" match. Both forms optionally include a separator, which can be any token
except `+` or `*`.

This system is based on
"[Macro-by-Example](http://www.cs.indiana.edu/ftp/techreports/TR206.pdf)"
(PDF ссылка).

# Гигиена (Hygiene)

Некоторые языки реализуют макросы с помощью простой текстовой замены, что приводит к различным проблемам. Например, нижеприведенная C программа напечатает `13` вместо ожидаемого `25`.

```text
#define FIVE_TIMES(x) 5 * x

int main() {
    printf("%d\n", FIVE_TIMES(2 + 3));
    return 0;
}
```

После раскрытия мы получаем `5 * 2 + 3`, но умножение имеет больший приоритет чем сложение. Если вы часто использовали C макросы, вы, наверное, знаете стандартные идиомы для устранения этой проблемы, а также пять или шесть других проблем. В Rust мы не должны беспокоиться об этом.

```rust
macro_rules! five_times {
    ($x:expr) => (5 * $x);
}

fn main() {
    assert_eq!(25, five_times!(2 + 3));
}
```

Метапеременная `$x` обрабатывается как единый узел выражения, и сохраняет свое место в дереве синтаксиса даже после замены.

Другой распространенной проблемой в системе макросов является *захват переменной*. Вот C макрос, использующий [GNU C расширение], который эмулирует блоки выражениий в Rust.

[a GNU C extension]: https://gcc.gnu.org/onlinedocs/gcc/Statement-Exprs.html

```text
#define LOG(msg) ({ \
    int state = get_log_state(); \
    if (state > 0) { \
        printf("log(%d): %s\n", state, msg); \
    } \
})
```

Вот простой случай использования, что идет ужасно неправильно:
Here's a simple use case that goes terribly wrong:

```text
const char *state = "reticulating splines";
LOG(state)
```

Он раскрывается в

```text
const char *state = "reticulating splines";
int state = get_log_state();
if (state > 0) {
    printf("log(%d): %s\n", state, state);
}
```

Вторая переменная с именем `state` затеняет первую. Это проблема, потому что команде печати требуется обращаться к ним обоим.

Эквивалентный макрос в Rust обладает требуемым поведением.

```rust
# fn get_log_state() -> i32 { 3 }
macro_rules! log {
    ($msg:expr) => {{
        let state: i32 = get_log_state();
        if state > 0 {
            println!("log({}): {}", state, $msg);
        }
    }};
}

fn main() {
    let state: &str = "reticulating splines";
    log!(state);
}
```

Это работает, потому что Rust имеет [систему макросов с соблюдением гигиены]. Раскрытие каждого макроса происходит в отдельном *контексте синтаксиса*, и каждая переменная обладает меткой контекста синтаксиса, где она была введена. Это как если бы переменная `state` внутри `main` была бы окрашена в другой "цвет" в отличае от переменной `state` внутри макроса, из-за чего они бы не конфликтовали.

[систему макросов с соблюдением гигиены]: http://en.wikipedia.org/wiki/Hygienic_macro

Это также ограничивает возможности макросов для внедрения новых привязок на вызова сайте. Код, приведенный ниже, не будет работать:

This also restricts the ability of macros to introduce new bindings at the
invocation site. Code such as the following will not work:

```rust,ignore
macro_rules! foo {
    () => (let x = 3);
}

fn main() {
    foo!();
    println!("{}", x);
}
```

Вместо этого вы должны передавать имя переменной при вызове, тогда она будет обладать меткой правильного контекста синтаксиса.

```rust
macro_rules! foo {
    ($v:ident) => (let $v = 3);
}

fn main() {
    foo!(x);
    println!("{}", x);
}
```

Это справедливо для `let` привязок и меток loop, но не для [элементов][]. Код, приведенный ниже, компилируется:

```rust
macro_rules! foo {
    () => (fn x() { });
}

fn main() {
    foo!();
    x();
}
```

[элементов]: ../reference.html#items

# Рекурсия макросов

A macro's expansion can include more macro invocations, including invocations
of the very same macro being expanded.  These recursive macros are useful for
processing tree-structured input, as illustrated by this (simplistic) HTML
shorthand:
Раскрытие макроса также может включать в себя вызовы макросов, в том числе вызовы того макроса, который раскрывается. Эти рекурсивные макросы могут быть использованы для обработки древовидного ввода, как показано на этом (упрощенном) HTML сокращение:

```rust
# #![allow(unused_must_use)]
macro_rules! write_html {
    ($w:expr, ) => (());

    ($w:expr, $e:tt) => (write!($w, "{}", $e));

    ($w:expr, $tag:ident [ $($inner:tt)* ] $($rest:tt)*) => {{
        write!($w, "<{}>", stringify!($tag));
        write_html!($w, $($inner)*);
        write!($w, "</{}>", stringify!($tag));
        write_html!($w, $($rest)*);
    }};
}

fn main() {
#   // FIXME(#21826)
    use std::fmt::Write;
    let mut out = String::new();

    write_html!(&mut out,
        html[
            head[title["Macros guide"]]
            body[h1["Macros are the best!"]]
        ]);

    assert_eq!(out,
        "<html><head><title>Macros guide</title></head>\
         <body><h1>Macros are the best!</h1></body></html>");
}
```

# Debugging macro code

To see the results of expanding macros, run `rustc --pretty expanded`. The
output represents a whole crate, so you can also feed it back in to `rustc`,
which will sometimes produce better error messages than the original
compilation. Note that the `--pretty expanded` output may have a different
meaning if multiple variables of the same name (but different syntax contexts)
are in play in the same scope. In this case `--pretty expanded,hygiene` will
tell you about the syntax contexts.

`rustc` provides two syntax extensions that help with macro debugging. For now,
they are unstable and require feature gates.

* `log_syntax!(...)` will print its arguments to standard output, at compile
  time, and "expand" to nothing.

* `trace_macros!(true)` will enable a compiler message every time a macro is
  expanded. Use `trace_macros!(false)` later in expansion to turn it off.

# Further reading

The [advanced macros chapter][] goes into more detail about macro syntax. It
also describes how to share macros between different modules or crates.

[advanced macros chapter]: advanced-macros.html