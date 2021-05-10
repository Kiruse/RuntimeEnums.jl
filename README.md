# RuntimeEnums.jl
Enums whose values can be registered at runtime.

Naturally, these enums are less performant in value registration. Their usage, however, should not suffer from any penalties.

Runtime-defined enums are useful for extendable systems. Clients may inject custom values into an existing system, thus customizing its behavior.

# Usage

