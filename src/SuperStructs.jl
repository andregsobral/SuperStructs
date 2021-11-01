module SuperStructs

export @constrain

macro constrain(expr)
    constraints    = []
    argconstraints = []
    @assert expr.head == :struct "expr should be a struct!"

    # -- update body of the struct: expr.args[3]
    structname = expr.args[2]
    structbody = quote end
    pop!(structbody.args)
    sbody = expr.args[3].args
    
    # -- Analyse body of struct
    for e in sbody 
        # -- gather information on constraints (:in operator)
        if !isa(e,LineNumberNode) && !isempty(e.args) && 
            (:in in e.args || :< in e.args || :> in e.args || :<= in e.args || :>= in e.args)
            push!(structbody.args, e.args[2])
            push!(constraints, Expr(:call,e.args[1], e.args[2].args[1], e.args[3]))
        # -- store unconstrained fields
        else
            push!(structbody.args, e)
        end
    end
    fields_wtypes = filter(x -> !isa(x,LineNumberNode), structbody.args) # -- get "label::String", "value::Int"
    fields        = map(x -> x.args[1], fields_wtypes)                   # -- get "label", "value"

    # -- Build new constraint expressions to add to default constructor
    for e in constraints
        fname  = string(e.args[2])
        fconst = string(e)
        msg = """ArgumentError: field '$fname' must follow constraint:\n=> $fconst"""
        req = quote if !$(e) error($(msg)) end end
        push!(argconstraints, req.args[2]) # -- store only :if expr not a whole :block
    end

    # -- Define new default constructor
    constructor = quote
        function $(structname)($(fields_wtypes...))
            $(argconstraints...)
            return new($(fields...))
        end
    end
    push!(structbody.args, constructor.args[2]) # -- store only :call expr not a whole :block
    
    # -- update final expression
    expr.args[3] = structbody 
    return expr
end


@constrain struct Slider
    label ::String in ["hello"]
    value ::Int    in 1:100
end

@constrain struct OtherType
    label ::String in ["hello"]
    v1 ::Int > 100
    v2 ::Int < 100
    v3 ::Int >= 100
    v4 ::Int <= 100
    v5 ::Int in 123:200
    free::Int
    altlabel::String
end

end


