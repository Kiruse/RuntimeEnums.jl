######################################################################
# RuntimeEnums UTs
# -----
# Licensed under MIT License.
using Test
using RuntimeEnums

@runtime_enum OneLiner::UInt8 Byte1 = 1 Byte2 Byte3
@runtime_enum Blocked::Int begin
    SixtyNine = 69
    FourTwenty = 420
    FourtyTwo = 42
end

@runtime_enum Extendable Error Predef1 Predef2

@testset "RuntimeEnums" begin
    @testset "1-liner" begin
        @test OneLiner <: Enum{UInt8}
        @test Byte1 isa OneLiner && Byte2 isa OneLiner && Byte3 isa OneLiner
        @test issetequal(Base.Enums.instances(OneLiner), (Byte1, Byte2, Byte3))
        @test Byte1 === OneLiner(1) && Byte2 === OneLiner(2) && Byte3 === OneLiner(3)
        @test typemin(OneLiner) === Byte1 && typemax(OneLiner) === Byte3
    end
    
    @testset "Blocked" begin
        @test Blocked <: Enum{Int}
        @test FourtyTwo isa Blocked && SixtyNine isa Blocked && FourTwenty isa Blocked
        @test issetequal(Base.Enums.instances(Blocked), (FourtyTwo, SixtyNine, FourTwenty))
        @test FourtyTwo === Blocked(42) && SixtyNine === Blocked(69) && FourTwenty === Blocked(420)
        @test typemin(Blocked) === FourtyTwo && typemax(Blocked) === FourTwenty
    end
    
    @testset "Extendable" begin
        @assert issetequal(Base.Enums.instances(Extendable), (Error, Predef1, Predef2))
        @assert typemin(Extendable) === Error && typemax(Extendable) === Predef2
        
        @test_throws ArgumentError Extendable[:Extended1] = 0
        @test_throws ArgumentError Extendable[:Predef1] = 0
        
        Extendable[:NewMax] =  42
        Extendable[:NewMin] = -12
        @test issetequal(Base.Enums.instances(Extendable), (Error, Predef1, Predef2, Extendable(42), Extendable(-12)))
        @test typemin(Extendable) === Extendable(-12) && typemax(Extendable) === Extendable(42)
    end
end
