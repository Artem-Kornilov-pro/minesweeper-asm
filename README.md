# 🕹️ Minesweeper in Pure x64 Assembly

Полноценный "Сапёр", написанный **с нуля на ассемблере MASM x64** для Windows.  
Никаких внешних библиотек — только WinAPI и GDI.

## Особенности
- Поле 9×9, 10 мин
- Левая кнопка — открыть ячейку
- Правая кнопка — флаг
- Рекурсивное открытие пустых областей
- Отрисовка чисел с автоматическим цветом
- Сообщения о победе/поражении

## Сборка и запуск
1. Установите Visual Studio 2022 (Community) с "Desktop development with C++"
2. Откройте **x64 Native Tools Command Prompt**
3. Выполните:
```bash
ml64.exe minesweeper.asm /link /subsystem:windows /entry:main
minesweeper.exe# 🕹️ Minesweeper in Pure x64 Assembly

Полноценный "Сапёр", написанный **с нуля на ассемблере MASM x64** для Windows.  
Никаких внешних библиотек — только WinAPI и GDI.

## Особенности
- Поле 9×9, 10 мин
- Левая кнопка — открыть ячейку
- Правая кнопка — флаг
- Рекурсивное открытие пустых областей
- Отрисовка чисел с автоматическим цветом
- Сообщения о победе/поражении

## Сборка и запуск
1. Установите Visual Studio 2022 (Community) с "Desktop development with C++"
2. Откройте **x64 Native Tools Command Prompt**
3. Выполните:
```bash
ml64.exe minesweeper.asm /link /subsystem:windows /entry:main
minesweeper.exe