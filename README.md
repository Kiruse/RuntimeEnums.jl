# RuntimeEnums.jl
Enums whose values can be registered at runtime.

Naturally, these enums are less performant in value registration. Their usage, however, should not suffer from any penalties.

Runtime-defined enums are useful for extendable systems. Clients may inject custom values into an existing system, thus customizing its behavior.

# Usage
Creation of new `RuntimeEnum`s is designed to be like creation of regular `Enum`s with the [`@enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.@enum) macro:

```julia
using RuntimeEnums

@runtime_enum SomeEnum
# "empty" enum `SomeEnum`
isempty(SomeEnum) === true

@runtime_enum AnotherEnum Foo Bar Baz
# Foo === AnotherEnum(0), Bar === AnotherEnum(1), Baz === AnotherEnum(2)

@runtime_enum YetAnotherEnum::UInt8 begin
    Byte1 = 0x1
    Byte2
    Byte3
end
```

The main distinction, obviously, is that new enum values can be added dynamically at runtime:

```julia
using RuntimeEnums

@runtime_enum ExtensibleEnum

RuntimeEnums.@register ExtensibleEnum First Second
RuntimeEnums.@register ExtensibleEnum begin
    Third
    Fourth
    Fifth
end
# First === ExtensibleEnum(0), Second === ExtensibleEnum(1), ...
```

Additionally to the `RuntimeEnums.@register` macro, one may call the underlying `Base.setindex!` method. As this is a method, it does not have the capacity to define a constant for you, it merely creates a mapping for the given key/value pair.

```julia
using RuntimeEnums

@runtime_enum ExtensibleEnum

ExtensibleEnum[:Foo] = 24
ExtensibleEnum[:Bar] = 42
ExtensibleEnum[:Baz] = 69
Base.Enums.instances(ExtensibleEnum) == (ExtensibleEnum(24), ExtensibleEnum(42), ExtensibleEnum(69))
```

Both, the name and the value must be unique. Attempting to override either will raise an `ArgumentError`.

```julia
using RuntimeEnums

@runtime_enum SomeEnum Foo Bar Baz = 42

ExtensibleEnum[:Foo] = 24 # throws ArgumentError
ExtensibleEnum[:New] = 42 # also throws ArgumentError
```

# License
The MIT License (MIT)
Copyright © 2021 Kiruse

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
