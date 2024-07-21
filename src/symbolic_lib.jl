module SymbolicLib

export f_inv, f_inv2, f_inv3, f_inv4, f_inv5, f_sqrt, f_power1d5, f_invsqrt, f_log, f_tan, f_arctanh, f_arcsin, f_arccos, f_exp, SYMBOLIC_LIB

using Flux, LinearAlgebra, SymPy

# Helper functions
nan_to_num(x) = replace(x, NaN => 0.0, Inf => 0.0, -Inf => 0.0)
sign(x) = x < 0 ? -1 : (x > 0 ? 1 : 0)
safe_log(x) = x > 0 ? log(x) : (x < 0 ? complex(log(-x), π) : -Inf)

# Singularity protection functions
function f_inv(x, y_th)
    x_th = (1 ./ y_th)
    return x_th, (y_th ./ x_th) .* x .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ x) .* (abs.(x) .>= x_th)
end

function f_inv2(x, y_th)
    x_th = (1 ./ y_th).^0.5
    return x_th, y_th .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ x.^2) .* (abs.(x) .>= x_th)
end

function f_inv3(x, y_th)
    x_th = 1 ./ y_th.^(1/3)
    return x_th, y_th ./ x_th .* x .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ x.^3) .* (abs.(x) .>= x_th)
end

function f_inv4(x, y_th)
    x_th = 1 ./ y_th.^(1/4)
    return x_th, y_th .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ x.^4) .* (abs.(x) .>= x_th)
end

function f_inv5(x, y_th)
    x_th = 1 ./ y_th.^(1/5)
    return x_th, y_th ./ x_th .* x .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ x.^5) .* (abs.(x) .>= x_th)
end

function f_sqrt(x, y_th)
    x_th = 1 ./ y_th.^2
    return x_th, x_th ./ y_th .* x .* (abs.(x) .< x_th) .+ nan_to_num(sqrt.(abs.(x)) .* sign.(x)) .* (abs.(x) .>= x_th)
end

f_power1d5(x, y_th) = abs.(x).^1.5

function f_invsqrt(x, y_th)
    x_th = 1 ./ y_th.^2
    return x_th, y_th .* (abs.(x) .< x_th) .+ nan_to_num(1 ./ sqrt.(abs.(x))) .* (abs.(x) .>= x_th)
end

function f_log(x, y_th)
    x_th = exp.(-y_th)
    return x_th, -y_th .* (abs.(x) .< x_th) .+ nan_to_num(log.(abs.(x))) .* (abs.(x) .>= x_th)
end

function f_tan(x, y_th)
    clip = x .% π
    delta = π/2 .- atan.(y_th)
    return clip, delta, -y_th ./ delta .* (clip .- π/2) .* (abs.(clip .- π/2) .< delta) .+ nan_to_num(tan.(clip)) .* (abs.(clip .- π/2) .>= delta)
end

"""
f_arctanh = lambda x, y_th: ((delta := 1-torch.tanh(y_th) + 1e-4), y_th * torch.sign(x) * (torch.abs(x) > 1 - delta) + torch.nan_to_num(torch.arctanh(x)) * (torch.abs(x) <= 1 - delta))
f_arcsin = lambda x, y_th: ((), torch.pi/2 * torch.sign(x) * (torch.abs(x) > 1) + torch.nan_to_num(torch.arcsin(x)) * (torch.abs(x) <= 1))
f_arccos = lambda x, y_th: ((), torch.pi/2 * (1-torch.sign(x)) * (torch.abs(x) > 1) + torch.nan_to_num(torch.arccos(x)) * (torch.abs(x) <= 1))
f_exp = lambda x, y_th: ((x_th := torch.log(y_th)), y_th * (x > x_th) + torch.exp(x) * (x <= x_th))
"""
function f_arctanh(x, y_th)
    delta = 1 .- tanh.(y_th) .+ 1e-4
    return delta, y_th .* sign.(x) .* (abs.(x) .> 1 .- delta) .+ nan_to_num(atanh.(x)) .* (abs.(x) .<= 1 .- delta)
end

function f_arcsin(x, y_th)
    return nothing, π/2 .* sign.(x) .* (abs.(x) .> 1) .+ nan_to_num(asin.(x)) .* (abs.(x) .<= 1)
end

function f_arccos(x, y_th)
    return nothing, π/2 .* (1 .- sign.(x)) .* (abs.(x) .> 1) .+ nan_to_num(acos.(x)) .* (abs.(x) .<= 1)
end

function f_exp(x, y_th)
    x_th = log.(y_th)
    return x_th, y_th .* (x .> x_th) .+ exp.(x) .* (x .<= x_th)
end

SYMBOLIC_LIB = Dict(
    "x" => (x -> x, x -> x, 1, (x, y_th) -> ((), x)),
    "x^2" => (x -> x.^2, x -> x.^2, 2, (x, y_th) -> ((), x.^2)),
    "x^3" => (x -> x.^3, x -> x.^3, 3, (x, y_th) -> ((), x.^3)),
    "x^4" => (x -> x.^4, x -> x.^4, 3, (x, y_th) -> ((), x.^4)),
    "x^5" => (x -> x.^5, x -> x.^5, 3, (x, y_th) -> ((), x.^5)),
    "1/x" => (x -> 1 ./ x, x -> 1 ./ x, 2, f_inv),
    "1/x^2" => (x -> 1 ./ x.^2, x -> 1 ./ x.^2, 2, f_inv2),
    "1/x^3" => (x -> 1 ./ x.^3, x -> 1 ./ x.^3, 3, f_inv3),
    "1/x^4" => (x -> 1 ./ x.^4, x -> 1 ./ x.^4, 4, f_inv4),
    "1/x^5" => (x -> 1 ./ x.^5, x -> 1 ./ x.^5, 5, f_inv5),
    "sqrt" => (x -> sqrt.(x), x -> sympy.sqrt.(x), 2, f_sqrt),
    "x^0.5" => (x -> sqrt.(x), x -> sympy.sqrt.(x), 2, f_sqrt),
    "x^1.5" => (x -> sqrt.(x).^3, x -> sympy.sqrt.(x).^3, 4, f_power1d5),
    "1/sqrt(x)" => (x -> 1/sqrt.(x), x -> 1/sympy.sqrt.(x), 2, f_invsqrt),
    "1/x^0.5" => (x -> 1/sqrt.(x), x -> 1/sympy.sqrt.(x), 2, f_invsqrt),
    "exp" => (x -> exp.(x), x -> sympy.exp.(x), 2, f_exp),
    "log" => (x -> log.(x), x -> sympy.log.(x), 2, f_log),
    "abs" => (x -> abs.(x), x -> sympy.Abs.(x), 3, (x, y_th) -> ((), abs.(x))),
    "sin" => (x -> sin.(x), x -> sympy.sin.(x), 2, (x, y_th) -> ((), sin.(x))),
    "cos" => (x -> cos.(x), x -> sympy.cos.(x), 2, (x, y_th) -> ((), cos.(x))),
    "tan" => (x -> tan.(x), x -> sympy.tan.(x), 3, f_tan),
    "tanh" => (x -> tanh.(x), x -> sympy.tanh.(x), 3, (x, y_th) -> ((), tanh.(x))),
    "sgn" => (x -> sign.(x), x -> sympy.sign.(x), 3, (x, y_th) -> ((), sign.(x))),
    "arcsin" => (x -> asin.(x), x -> sympy.asin.(x), 4, f_arcsin),
    "arccos" => (x -> acos.(x), x -> sympy.acos.(x), 4, f_arccos),
    "arctan" => (x -> atan.(x), x -> sympy.atan.(x), 4, (x, y_th) -> ((), atan.(x))),
    "arctanh" => (x -> atanh.(x), x -> sympy.atanh.(x), 4, f_arctanh),
    "0" => (x -> x * 0, x -> x * 0, 0, (x, y_th) -> ((), x * 0)),
    "gaussian" => (x -> exp.(-x.^2), x -> sympy.exp.(-x.^2), 3, (x, y_th) -> ((), exp.(-x.^2)))
)

end

using Test
using .SymbolicLib

x_test, y_test = [0.1, 0.2], [0.1, 0.2]
@test all(f_inv3(x_test, y_test) .≈ ([2.1544346900318834, 1.7099759466766968], [0.004641588833612781, 0.023392141905702935]))
@test all(f_inv4(x_test, y_test) .≈ ([1.7782794100389228, 1.4953487812212205], [0.1, 0.2]))
@test all(f_inv5(x_test, y_test) .≈ ([1.5848931924611134, 1.379729661461215], [0.006309573444801934, 0.028991186547107823]))
@test all(f_sqrt(x_test, y_test) .≈ ([100.0, 25.0], [100.0, 25.0]))
@test all(f_power1d5(x_test, y_test) ≈ [0.0316227766016838, 0.0894427190999916])
@test all(f_invsqrt(x_test, y_test) .≈ ([100.0, 25.0], [0.1, 0.2]))
@test all(f_log(x_test, y_test) .≈ ([0.9048374180359595, 0.8187307530779818], [-0.1, -0.2]))
@test all(f_tan(x_test, y_test) .≈ ([0.1, 0.2], [1.4711276743037345, 1.3734007669450157], [0.09997747663138791, 0.19962073122240753]))
@test all(f_arctanh(x_test, y_test) .≈ ([0.9004320053750442, 0.802724679775096], [0.1, 0.2]))
@test all(f_arcsin(x_test, y_test)[2] ≈ [0.1001674211615598, 0.2013579207903308])
@test all(f_arccos(x_test, y_test)[2] ≈ [1.4706289056333368, 1.369438406004566])
@test all(f_exp(x_test, y_test) .≈ ([-2.3025850929940455, -1.6094379124341003], [0.1, 0.2]))

# Test symbolic library
@test SYMBOLIC_LIB["x"][1](x_test) ≈ x_test
@test SYMBOLIC_LIB["x"][2](x_test) ≈ x_test
@test SYMBOLIC_LIB["x^2"][1](x_test) ≈ x_test.^2
@test SYMBOLIC_LIB["x^2"][2](x_test) ≈ x_test.^2
@test SYMBOLIC_LIB["x^3"][1](x_test) ≈ x_test.^3
@test SYMBOLIC_LIB["x^3"][2](x_test) ≈ x_test.^3
@test SYMBOLIC_LIB["x^4"][1](x_test) ≈ x_test.^4
@test SYMBOLIC_LIB["x^4"][2](x_test) ≈ x_test.^4
@test SYMBOLIC_LIB["x^5"][1](x_test) ≈ x_test.^5
@test SYMBOLIC_LIB["x^5"][2](x_test) ≈ x_test.^5
@test SYMBOLIC_LIB["1/x"][1](x_test) ≈ 1 ./ x_test
@test SYMBOLIC_LIB["1/x"][2](x_test) ≈ 1 ./ x_test
@test SYMBOLIC_LIB["1/x^2"][1](x_test) ≈ 1 ./ x_test.^2
@test SYMBOLIC_LIB["1/x^2"][2](x_test) ≈ 1 ./ x_test.^2
@test SYMBOLIC_LIB["1/x^3"][1](x_test) ≈ 1 ./ x_test.^3
@test SYMBOLIC_LIB["1/x^3"][2](x_test) ≈ 1 ./ x_test.^3
@test SYMBOLIC_LIB["1/x^4"][1](x_test) ≈ 1 ./ x_test.^4
@test SYMBOLIC_LIB["1/x^4"][2](x_test) ≈ 1 ./ x_test.^4
@test SYMBOLIC_LIB["1/x^5"][1](x_test) ≈ 1 ./ x_test.^5
@test SYMBOLIC_LIB["1/x^5"][2](x_test) ≈ 1 ./ x_test.^5
@test SYMBOLIC_LIB["sqrt"][1](x_test) ≈ sqrt.(x_test)
@test SYMBOLIC_LIB["sqrt"][2](x_test) ≈ sqrt.(x_test)
@test SYMBOLIC_LIB["x^0.5"][1](x_test) ≈ sqrt.(x_test)
@test SYMBOLIC_LIB["x^0.5"][2](x_test) ≈ sqrt.(x_test)
@test SYMBOLIC_LIB["x^1.5"][1](x_test) ≈ sqrt.(x_test).^3
@test SYMBOLIC_LIB["x^1.5"][2](x_test) ≈ sqrt.(x_test).^3
@test SYMBOLIC_LIB["1/sqrt(x)"][1](x_test) ≈ 1 ./ sqrt.(x_test)
@test SYMBOLIC_LIB["1/sqrt(x)"][2](x_test) ≈ 1 ./ sqrt.(x_test)
@test SYMBOLIC_LIB["1/x^0.5"][1](x_test) ≈ 1 ./ sqrt.(x_test)
@test SYMBOLIC_LIB["1/x^0.5"][2](x_test) ≈ 1 ./ sqrt.(x_test)
@test SYMBOLIC_LIB["exp"][1](x_test) ≈ exp.(x_test)
@test SYMBOLIC_LIB["exp"][2](x_test) ≈ exp.(x_test)
@test SYMBOLIC_LIB["log"][1](x_test) ≈ log.(x_test)
@test SYMBOLIC_LIB["log"][2](x_test) ≈ log.(x_test)
@test SYMBOLIC_LIB["abs"][1](x_test) ≈ abs.(x_test)


