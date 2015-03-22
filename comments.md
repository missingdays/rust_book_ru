% Коментарии

Теперь, когда у нас есть несколько функций, неплохо бы узнать о комментариях. Комментарии это заметки, которые вы оставляете для других программистов, что бы помочь объяснить некоторые вещи в вашем коде. Компилятор в основном игнорирует их.

В Rust есть два вида комментариев: `строчные комментарии` и `doc-комментарии`.

```rust
// Строчные комментарии это все что угодно после '//' и до конца строки.

let x = 5; // это тоже строчный комментарий.

// Если у вас длинное объяснение для чего-либо, вы можете расположить строчные комментарии
// один за другим. Поместите пробел между // и вашим комментарием, так как это более читаемо.
```
Другое применение комментария - это doc-комментарий. Doc-комментарий использует `///` вместо `//`, и поддерживает Markdown-разметку внутри:

```rust
/// `hello` это функция которая выводит на экран персональное приветствие
/// основанное на полученном имени
///
/// # Параметры
///
/// * `name` - Имя особы, которую вы хотите поприветствовать.
///
/// # Пример
///
/// ```rust
/// let name = "Steve";
/// hello(name); // выведет "Hello, Steve!"
/// ```
fn hello(name: &str) {
    println!("Hello, {}!", name);
}
```
При написании doc-комментария, добавление разделов для любых аргументов, возвращаемых значений, и приведение некоторых примеров использования очень и очень полезно.

Вы можете использовать инструмент `rustdoc` для генерации HTML-документации из этих doc-комментариев. Мы расскажем больше о `rustdoc` позже в отдельной теме.