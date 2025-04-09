abstract type AbstractQtMCMC <: AbstractMCMC end

Base.@kwdef mutable struct MpsQtMCMC <: AbstractQtMCMC
	id::UUID = uuid4()
	rng::Xoshiro = Xoshiro([rand(UInt64) for _ in 1:5]...)
	state::MPS
	checkpoint_file::HDF5.File = default_checkpoint_file(id)
	save_file::IO = default_save_file(id)
	function MpsQtMCMC(id::UUID, rng::Xoshiro, state::MPS, checkpoint_file::HDF5.File, save_file_::IO)
		x = new(id, rng, state, checkpoint_file, save_file_)
		f(t) = (@async println("Finalizing $(typeof(t))."); close(save_file(t)))
		finalizer(f, x)
	end
end