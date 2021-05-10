######################################################################
# Non-static enums which can be expanded at runtime. Once a value is
# defined it cannot be undefined.
# -----
# Licensed under MIT License
module RuntimeEnums
import Base.Enums

export RuntimeEnum
abstract type RuntimeEnum{I<:Integer} <: Enum{I} end

export @runtime_enum
macro runtime_enum(T::Union{Symbol, Expr}, exprs...)
    typename, basetype = extract_runtime_enum_type(__module__, T)
    esctypename = esc(typename)
    
    namemap = Dict{basetype, Symbol}()
    
    blk = quote
        Base.@__doc__(primitive type $esctypename <: RuntimeEnum{$basetype} $(sizeof(basetype) * 8) end)
        function ($esctypename)(x::Integer)
            if x ∉ keys(Enums.namemap($esctypename))
                throw(ArgumentError("invalid value for runtime enum $(string($typename)): $x"))
            end
            return Base.bitcast($esctypename, convert($basetype, x))
        end
        
        Base.Enums.namemap(::Type{$esctypename}) = $namemap
    end
    
    if length(exprs) > 0
        append!(blk.args, make_constants(typename, namemap, exprs))
    end
    
    push!(blk.args, nothing)
    blk
end

macro register(E::Symbol, exprs::Union{Symbol, Expr}...)
    if length(exprs) == 0
        throw(ArgumentError("no values provided"))
    end
    
    namemap = Core.eval(__module__, :(Base.Enums.namemap($E)))
    E = esc(E)
    
    Expr(:block, make_constants(E, namemap, exprs)...)
end


function Base.setindex!(E::Type{<:RuntimeEnum}, value::Integer, name::Symbol)
    namemap = Enums.namemap(E)
    if name ∈ values(namemap)
        throw(ArgumentError("runtime enum name $E::$name already in use"))
    end
    if value ∈ keys(namemap)
        throw(ArgumentError("runtime enum value $E::$(namemap[value]) = $value already in use"))
    end
    
    Enums.namemap(E)[value] = name
    return E(value)
end

Base.typemin(E::Type{<:RuntimeEnum}) = (assert_nonempty(E); E(minkey(Enums.namemap(E))))
Base.typemax(E::Type{<:RuntimeEnum}) = (assert_nonempty(E); E(maxkey(Enums.namemap(E))))
Base.instances(E::Type{<:RuntimeEnum}) = E.(keys(Enums.namemap(E)))
Base.isempty(E::Type{<:RuntimeEnum}) = isempty(Enums.namemap(E))

maxkey(keyset::Base.KeySet) = reduce((a, b) -> max(a, b), keyset)
minkey(keyset::Base.KeySet) = reduce((a, b) -> min(a, b), keyset)
maxkey(dict::Dict) = maxkey(keys(dict))
minkey(dict::Dict) = minkey(keys(dict))

function assert_nonempty(E::Type{<:RuntimeEnum})
    @assert(!isempty(keys(Enums.namemap(E))), "empty runtime enum")
end

extract_runtime_enum_type(_, name::Symbol) = name, Int32
function extract_runtime_enum_type(mod::Module, T::Expr)
    if !(T.head === :(::) && length(T.args) == 2 && T.args[1] isa Symbol)
        throw(ArgumentError("invalid type expression for runtime enum $T"))
    end
    
    typename = T.args[1]
    basetype = Core.eval(mod, T.args[2])
    
    if !(basetype isa DataType && basetype <: Integer && isbitstype(basetype))
        throw(ArgumentError("invalid base type for runtime enum $typename, $T=::$basetype; base type must be an integer primitive type"))
    end
    
    return typename, basetype
end

normalize_value_expr(namemap::Dict{I, Symbol} where {I<:Integer}, name::Symbol) = (name, isempty(keys(namemap)) ? 0 : maxkey(namemap)+1)
function normalize_value_expr(_, expr::Expr)
    if !(expr.head === :(=) && expr.args[1] isa Symbol && expr.args[2] isa Integer)
        throw(ArgumentError("invalid runtime enum value expression: $expr"))
    end
    return expr.args[1], expr.args[2]
end

function collect_value_exprs(exprs)
    # Collects all valid value expressions & preserves line numbers.
    result = []
    for expr in exprs
        if expr isa Symbol
            push!(result, expr)
            continue
        elseif expr isa Expr
            if expr.head === :block
                append!(result, collect_value_exprs(expr.args))
            elseif expr.head === :(=)
                if expr.args[1] isa Symbol && expr.args[2] isa Integer
                    push!(result, expr)
                    continue
                end
            end
            continue
        elseif expr isa LineNumberNode
            push!(result, expr)
        end
        
        throw(ArgumentError("invalid runtime enum value expression $expr"))
    end
    
    return result
end

function make_constants(E::Symbol, namemap, exprs)
    result = []
    for expr ∈ exprs
        if expr isa LineNumberNode
            push!(result, expr)
        elseif expr isa Expr && expr.head === :block
            append!(result, make_constants(E, namemap, expr.args))
        else
            varname, value = normalize_value_expr(namemap, expr)
            if varname ∈ values(namemap)
                throw(ArgumentError("duplicate runtime enum name $varname"))
            elseif value ∈ keys(namemap)
                throw(ArgumentError("duplicate runtime enum value $value"))
            end
            
            namemap[value] = varname
            push!(result, :(const $(esc(varname)) = $(esc(E))($value)))
        end
    end
    return result
end

end # module RuntimeEnums
