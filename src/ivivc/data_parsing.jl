# Vivo Data
"""
    read_vivo(df::Union{DataFrame,AbstractString}; id=:id, time=:time,
             conc=:conc, form=:form, dose=:dose, kwargs...)

Parse a `DataFrame` object or a CSV file to `VIVOSubject` or `VIVOPopulation`
which holds an array of `VIVOSubject`s.
"""
read_vivo(file::AbstractString; kwargs...) = read_vivo(CSV.read(file); kwargs...)

function read_vivo(df; group=nothing, kwargs...)
  pop = if group === nothing
    ___read_vivo(df; kwargs...)
  else
    error("not implemented")
  end
  return pop
end

function ___read_vivo(df; id=:id, time=:time, conc=:conc, form=:form, dose=:dose, kwargs...)
  local ids, times, concs, forms, doses
  key_check = haskey(df, id) && haskey(df, time) && haskey(df, conc) && haskey(df, form) && haskey(df, dose)
  if !key_check
    @info "The CSV file has keys: $(names(df))"
    throw(ArgumentError("The CSV file must have: id, time, conc, form, dose"))
  end
  sortvars = (id, time)
  iss = issorted(df, sortvars)
  # we need to use a stable sort because we want to preserve the order of `time`
  sortedf = iss ? df : sort(df, sortvars, alg=Base.Sort.DEFAULT_STABLE)
  ids   = df[id]
  times = df[time]
  concs = df[conc]
  forms = df[form]
  doses = df[dose]
  uids = unique(ids)
  uforms = unique(forms)
  idx  = -1
  ncas = Vector{Any}(undef, length(uids))
  for (i, id) in enumerate(uids)
    # id's range, and we know that it is sorted
    idx = findfirst(isequal(id), ids):findlast(isequal(id), ids)
    ind = Dict{eltype(forms), VivoSubject}()
    for form in uforms
      if form in forms[idx]
        idx_n = findfirst(isequal(form), forms[idx]):findlast(isequal(form), forms[idx])
        try
          ind[form] = VivoSubject(concs[idx_n], times[idx_n], form, doses[idx_n[1]], id, kwargs...)
        catch
          @info "ID $id errored for formulation $(form)"
          rethrow()
        end
      end
    end
    ncas[i] = ind
  end
  # Use broadcast to tighten ncas element type
  pop = VivoPopulation(identity.(ncas))
  return pop
end


# Vitro Data
"""
    read_vitro(df::Union{DataFrame,AbstractString}; id=:id, time=:time,
             conc=:conc, form=:form, kwargs...)

Parse a `DataFrame` object or a CSV file to `VitroSubject` or `VitroPopulation`
which holds an array of `VitroSubject`s.
"""
read_vitro(file::AbstractString; kwargs...) = read_vitro(CSV.read(file); kwargs...)

function read_vitro(df; group=nothing, kwargs...)
  pop = if group === nothing
    ___read_vitro(df; kwargs...)
  else
    error("not implemented")
  end
  return pop
end

function ___read_vitro(df; id=:id, time=:time, conc=:conc, form=:form, kwargs...)
  local ids, times, concs, forms
  key_check = haskey(df, id) && haskey(df, time) && haskey(df, conc) && haskey(df, form)
  if !key_check
    @info "The CSV file has keys: $(names(df))"
    throw(ArgumentError("The CSV file must have: id, time, conc, form"))
  end
  sortvars = (id, time)
  iss = issorted(df, sortvars)
  # we need to use a stable sort because we want to preserve the order of `time`
  sortedf = iss ? df : sort(df, sortvars, alg=Base.Sort.DEFAULT_STABLE)
  ids   = df[id]
  times = df[time]
  concs = df[conc]
  forms = df[form]
  uids = unique(ids)
  uforms = unique(forms)
  idx  = -1
  ncas = Vector{Any}(undef, length(uids))
  for (i, id) in enumerate(uids)
    # id's range, and we know that it is sorted
    idx = findfirst(isequal(id), ids):findlast(isequal(id), ids)
    ind = Dict{eltype(forms), VitroSubject}()
    for form in uforms
      if form in forms[idx]
        idx_n = findfirst(isequal(form), forms[idx]):findlast(isequal(form), forms[idx])
        try
          ind[form] = VitroSubject(concs[idx_n], times[idx_n], form, id, kwargs...)
        catch
          @info "ID $id errored for formulation $(form)"
          rethrow()
        end
      end
    end
    ncas[i] = ind
  end
  # Use broadcast to tighten ncas element type
  pop = VitroPopulation(identity.(ncas))
  return pop
end