using Test

include("../pipeline/flux_trainer.jl")
include("../pipeline/utils.jl")
include("../pipeline/plot.jl")
include("../architecture/kan_model.jl")
include("../pipeline/optimisation.jl")
using .KolmogorovArnoldNets
using .FluxTrainer
using .PipelineUtils
using .Plotting
using .Optimisation

function test_trainer()
    train_loader, test_loader = create_loaders(x -> x[1] * x[2], N_var=2, x_range=(-1,1), N_train=200, N_test=200, batch_size=200, normalise_input=false, init_seed=1234)
    model = KAN([2,5,1]; k=3, grid_interval=5)
    lr_scheduler = step_decay_scheduler(5, 0.8, 1e-9)
    opt = create_flux_opt(model, "adam"; LR=1e-7, decay_scheduler=lr_scheduler)
    trainer = init_flux_trainer(model, train_loader, test_loader, opt; max_epochs=100, verbose=true)
    train!(trainer; λ=0.0, λ_l1=1.0, λ_entropy=0.0, λ_coef=0.1, λ_coefdiff=0.1)

    @test sum(trainer.model.act_scale) > 0.0
    return trainer.model, first(test_loader)[1] |> permutedims
end

function test_prune(model, x)
    mask_before = model.mask[1]
    model = prune(model)
    mask_after = model.mask
    fwd!(model, x) # Remember to call fwd! to update the acts

    sum_mask_after = 0.0
    for i in eachindex(mask_after)
        sum_mask_after += sum(mask_after[i])
    end

    println("Number of neurons after pruning: ", sum_mask_after)
    @test sum_mask_after != sum(mask_before)
    return model
end

function test_plot(model)
    plot_kan!(model; mask=true, in_vars=["x1", "x2"], out_vars=["x1 * x2"], title="KAN")
end


model, x = test_trainer()
model = test_prune(model, x)
test_plot(model)
