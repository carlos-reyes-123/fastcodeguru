+++
draft       = true
featured    = false
title       = "Article Title for Template"
slug        = "the-title-of-the-post"
description = "This is the example description of the example post."
ogImage     = "./fastcodeguru-logo-96x96.png"
pubDatetime = 2025-05-04T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "some",
    "example",
    "tags",
]
+++

Images with the same filename and alternate formats (such as webp or avif)
will automatically be selected and loaded if appropriate.

![Jane Doe](./linux-logo-tux.svg "Linux Tux logo")

---

```csharp
public void SayHello()
{
    Console.WriteLine("Hello, world!");
}
```

That's some text with a footnote.[^1]&nbsp;some more text

[^1]: And that's the footnote.


That's some text with a custom label footnote.[^label]

[^label]: And that's the footnote with the custom label.

```cpp
#include <array>
#include <iostream>

struct Counter {
    int value = 0;
    void increment() const -> void { const_cast<Counter*>(this)->value++; }
};

int main() {
    constexpr std::array nums{1, 2, 3, 4, 5};
    Counter c;
    for (auto n : nums) if (n % 2 == 1) c.increment();
    std::cout << "Odd count: " << c.value << '\n';
}
```
