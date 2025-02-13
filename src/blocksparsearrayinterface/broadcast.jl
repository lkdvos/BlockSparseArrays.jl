using Base.Broadcast: BroadcastStyle, AbstractArrayStyle, DefaultArrayStyle, Broadcasted
using BroadcastMapConversion: map_function, map_args
using Derive: Derive, @interface

abstract type AbstractBlockSparseArrayStyle{N} <: AbstractArrayStyle{N} end

Derive.interface(::Type{<:AbstractBlockSparseArrayStyle}) = BlockSparseArrayInterface()

struct BlockSparseArrayStyle{N} <: AbstractBlockSparseArrayStyle{N} end

# Define for new sparse array types.
# function Broadcast.BroadcastStyle(arraytype::Type{<:MyBlockSparseArray})
#   return BlockSparseArrayStyle{ndims(arraytype)}()
# end

BlockSparseArrayStyle(::Val{N}) where {N} = BlockSparseArrayStyle{N}()
BlockSparseArrayStyle{M}(::Val{N}) where {M,N} = BlockSparseArrayStyle{N}()

Broadcast.BroadcastStyle(a::BlockSparseArrayStyle, ::DefaultArrayStyle{0}) = a
function Broadcast.BroadcastStyle(
  ::BlockSparseArrayStyle{N}, a::DefaultArrayStyle
) where {N}
  return BroadcastStyle(DefaultArrayStyle{N}(), a)
end
function Broadcast.BroadcastStyle(
  ::BlockSparseArrayStyle{N}, ::Broadcast.Style{Tuple}
) where {N}
  return DefaultArrayStyle{N}()
end

function Base.similar(bc::Broadcasted{<:BlockSparseArrayStyle}, elt::Type)
  # TODO: Make sure this handles GPU arrays properly.
  return similar(first(map_args(bc)), elt, combine_axes(axes.(map_args(bc))...))
end

# Broadcasting implementation
# TODO: Delete this in favor of `Derive` version.
function Base.copyto!(
  dest::AbstractArray{<:Any,N}, bc::Broadcasted{BlockSparseArrayStyle{N}}
) where {N}
  # convert to map
  # flatten and only keep the AbstractArray arguments
  @interface interface(bc) map!(map_function(bc), dest, map_args(bc)...)
  return dest
end
