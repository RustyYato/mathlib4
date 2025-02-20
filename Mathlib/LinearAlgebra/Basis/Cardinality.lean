/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro, Alexander Bentkamp, Kim Morrison
-/
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.LinearAlgebra.LinearIndependent
import Mathlib.SetTheory.Cardinal.Cofinality

/-!
# Results relating bases and cardinality.
-/

section Finite

open Basis Cardinal Set Submodule Finsupp

universe u v w w'

variable {R : Type u} {M : Type v}

section Semiring

variable [Semiring R] [AddCommMonoid M] [Nontrivial R] [Module R M]

-- One might hope that a finite spanning set implies that any linearly independent set is finite.
-- While this is true over a division ring
-- (simply because any linearly independent set can be extended to a basis),
-- or more generally over a ring satisfying the strong rank condition
-- (which covers all commutative rings; see `LinearIndependent.finite_of_le_span_finite`),
-- this is not true in general.
-- For example, the left ideal generated by the variables in a noncommutative polynomial ring
-- (`FreeAlgebra R ι`) in infinitely many variables (indexed by `ι`) is free
-- with an infinite basis (consisting of the variables).
-- As another example, for any commutative ring R, the ring of column-finite matrices
-- `Module.End R (ℕ →₀ R)` is isomorphic to `ℕ → Module.End R (ℕ →₀ R)` as a module over itself,
-- which also clearly contains an infinite linearly independent set.
/--
Over any nontrivial ring, the existence of a finite spanning set implies that any basis is finite.
-/
lemma basis_finite_of_finite_spans (w : Set M) (hw : w.Finite) (s : span R w = ⊤) {ι : Type w}
    (b : Basis ι R M) : Finite ι := by
  classical
  haveI := hw.to_subtype
  cases nonempty_fintype w
  -- We'll work by contradiction, assuming `ι` is infinite.
  rw [← not_infinite_iff_finite]
  intro i
  -- Let `S` be the union of the supports of `x ∈ w` expressed as linear combinations of `b`.
  -- This is a finite set since `w` is finite.
  let S : Finset ι := Finset.univ.sup fun x : w => (b.repr x).support
  let bS : Set M := b '' S
  have h : ∀ x ∈ w, x ∈ span R bS := by
    intro x m
    rw [← b.linearCombination_repr x, span_image_eq_map_linearCombination, Submodule.mem_map]
    use b.repr x
    simp only [and_true, eq_self_iff_true, Finsupp.mem_supported]
    rw [Finset.coe_subset, ← Finset.le_iff_subset]
    exact Finset.le_sup (f := fun x : w ↦ (b.repr ↑x).support) (Finset.mem_univ (⟨x, m⟩ : w))
  -- Thus this finite subset of the basis elements spans the entire module.
  have k : span R bS = ⊤ := eq_top_iff.2 (le_trans s.ge (span_le.2 h))
  -- Now there is some `x : ι` not in `S`, since `ι` is infinite.
  obtain ⟨x, nm⟩ := Infinite.exists_not_mem_finset S
  -- However it must be in the span of the finite subset,
  have k' : b x ∈ span R bS := by
    rw [k]
    exact mem_top
  -- giving the desire contradiction.
  simp only [self_mem_span_image, Finset.mem_coe, bS] at k'
  exact nm k'

end Semiring

section Ring

variable [Semiring R] [AddCommMonoid M] [Nontrivial R] [Module R M]

-- From [Les familles libres maximales d'un module ont-elles le meme cardinal?][lazarus1973]
/-- Over any ring `R`, if `b` is a basis for a module `M`,
and `s` is a maximal linearly independent set,
then the union of the supports of `x ∈ s` (when written out in the basis `b`) is all of `b`.
-/
theorem union_support_maximal_linearIndependent_eq_range_basis {ι : Type w} (b : Basis ι R M)
    {κ : Type w'} (v : κ → M) (ind : LinearIndependent R v) (m : ind.Maximal) :
    ⋃ k, ((b.repr (v k)).support : Set ι) = Set.univ := by
  -- If that's not the case,
  by_contra h
  simp only [← Ne.eq_def, ne_univ_iff_exists_not_mem, mem_iUnion, not_exists_not,
    Finsupp.mem_support_iff, Finset.mem_coe] at h
  -- We have some basis element `b i` which is not in the support of any of the `v k`.
  obtain ⟨i, w⟩ := h
  have repr_eq_zero (l) : b.repr (linearCombination R v l) i = 0 := by
    simp [linearCombination_apply, Finsupp.sum, w]
  -- Using this, we'll construct a linearly independent family strictly larger than `v`,
  -- by also using this `b i`.
  let v' (o : Option κ) : M := o.elim (b i) v
  have r : range v ⊆ range v' := by rintro - ⟨k, rfl⟩; exact ⟨some k, rfl⟩
  have r' : b i ∉ range v := fun ⟨k, p⟩ ↦ by simpa [w] using congr(b.repr $p i)
  have r'' : range v ≠ range v' := (r' <| · ▸ ⟨none, rfl⟩)
  -- The key step in the proof is checking that this strictly larger family is linearly independent.
  have i' : LinearIndepOn R id (range v') := by
    apply LinearIndependent.linearIndepOn_id
    rw [linearIndependent_iffₛ]
    intro l l' z
    simp_rw [linearCombination_option, v', Option.elim'] at z
    change _ + linearCombination R v l.some = _ + linearCombination R v l'.some at z
    -- We have some equality between linear combinations of `b i` and the `v k`,
    -- and want to show the coefficients are equal.
    ext (_ | a)
    -- We'll first show the coefficient of `b i` is zero,
    -- by expressing the `v k` in the basis `b`, and using that the `v k` have no `b i` term.
    · simpa [repr_eq_zero] using congr(b.repr $z i)
    -- All the other coefficients are also equal, because `v` is linear independent,
    -- by comparing the coefficients in the basis `b`.
    have l₁ : l.some = l'.some := ind <| b.repr.injective <| ext fun j ↦ by
      obtain rfl | ne := eq_or_ne i j
      · simp_rw [repr_eq_zero]
      classical simpa [single_apply, ne] using congr(b.repr $z j)
    exact DFunLike.congr_fun l₁ a
  exact r'' (m (range v') i' r)

/-- Over any ring `R`, if `b` is an infinite basis for a module `M`,
and `s` is a maximal linearly independent set,
then the cardinality of `b` is bounded by the cardinality of `s`.
-/
theorem infinite_basis_le_maximal_linearIndependent' {ι : Type w} (b : Basis ι R M) [Infinite ι]
    {κ : Type w'} (v : κ → M) (i : LinearIndependent R v) (m : i.Maximal) :
    Cardinal.lift.{w'} #ι ≤ Cardinal.lift.{w} #κ := by
  let Φ := fun k : κ => (b.repr (v k)).support
  have w₁ : #ι ≤ #(Set.range Φ) := by
    apply Cardinal.le_range_of_union_finset_eq_top
    exact union_support_maximal_linearIndependent_eq_range_basis b v i m
  have w₂ : Cardinal.lift.{w'} #(Set.range Φ) ≤ Cardinal.lift.{w} #κ := Cardinal.mk_range_le_lift
  exact (Cardinal.lift_le.mpr w₁).trans w₂

-- (See `infinite_basis_le_maximal_linearIndependent'` for the more general version
-- where the index types can live in different universes.)
/-- Over any ring `R`, if `b` is an infinite basis for a module `M`,
and `s` is a maximal linearly independent set,
then the cardinality of `b` is bounded by the cardinality of `s`.
-/
theorem infinite_basis_le_maximal_linearIndependent {ι : Type w} (b : Basis ι R M) [Infinite ι]
    {κ : Type w} (v : κ → M) (i : LinearIndependent R v) (m : i.Maximal) : #ι ≤ #κ :=
  Cardinal.lift_le.mp (infinite_basis_le_maximal_linearIndependent' b v i m)

end Ring

end Finite
