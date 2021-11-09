@super begin
    abstract type Shape
        width  :: Int64 > 0
        height :: Int64 > 0
    end

    struct Square <: Shape
        @check width == height
    end
end

struct ShoppingCart
    id       :: @auto randstring(10)
    products :: Dict{Product{id}, (Product{price}, quantity :: Range(0:10))} #  <=> (Product.id, Product.price)
    total    :: @auto sum(map(product -> product[1] * product[2], values(products)))
end

struct Product
    id     :: Regex(\d{1,3}\.(\d{1,3}\.)?\d{9}) # category.(subcategory)?.productId
    name   :: String
    price  :: Range(0:0.01:1)
    type   :: ["Food", "Beverages", "Tobacco"] = "Food"

    @meta
    # Java-like stactic properties
end


macro super(expr)
    expr = macroexpand(__module__, expr) 
    expr isa Expr && expr.head === :struct || error("Invalid usage of @super")
    expr = expr::Expr
    
    T = expr.args[2]
    if T isa Expr && T.head === :<:
        T = T.args[1]
    end
    
    params_ex = Expr(:parameters)
    call_args = Any[]

    _super!(expr.args[3], params_ex.args, call_args)

    # Only define a constructor if the type has fields
    if !isempty(params_ex.args)

    else
        kwdefs = nothing
    end

    quote
        Base.@__doc__($(esc(expr)))
        $kwdefs
    end
end