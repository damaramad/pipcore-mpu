(*******************************************************************************)
(*  © Université de Lille, The Pip Development Team (2015-2024)                *)
(*  Copyright (C) 2020-2024 Orange                                             *)
(*                                                                             *)
(*  This software is a computer program whose purpose is to run a minimal,     *)
(*  hypervisor relying on proven properties such as memory isolation.          *)
(*                                                                             *)
(*  This software is governed by the CeCILL license under French law and       *)
(*  abiding by the rules of distribution of free software.  You can  use,      *)
(*  modify and/ or redistribute the software under the terms of the CeCILL     *)
(*  license as circulated by CEA, CNRS and INRIA at the following URL          *)
(*  "http://www.cecill.info".                                                  *)
(*                                                                             *)
(*  As a counterpart to the access to the source code and  rights to copy,     *)
(*  modify and redistribute granted by the license, users are provided only    *)
(*  with a limited warranty  and the software's author,  the holder of the     *)
(*  economic rights,  and the successive licensors  have only  limited         *)
(*  liability.                                                                 *)
(*                                                                             *)
(*  In this respect, the user's attention is drawn to the risks associated     *)
(*  with loading,  using,  modifying and/or developing or reproducing the      *)
(*  software by the user in light of its specific status of free software,     *)
(*  that may mean  that it is complicated to manipulate,  and  that  also      *)
(*  therefore means  that it is reserved for developers  and  experienced      *)
(*  professionals having in-depth computer knowledge. Users are therefore      *)
(*  encouraged to load and test the software's suitability as regards their    *)
(*  requirements in conditions enabling the security of their systems and/or   *)
(*  data to be ensured and,  more generally, to use and operate it in the      *)
(*  same conditions as regards security.                                       *)
(*                                                                             *)
(*  The fact that you are presently reading this means that you have had       *)
(*  knowledge of the CeCILL license and that you accept its terms.             *)
(*******************************************************************************)

(** * Summary
    This file contains several internal lemmas to help prove invariants *)
Require Import Model.ADT Model.Monad Model.MAL Model.Lib Core.Internal.

Require Import Proof.Isolation Proof.Consistency Proof.StateLib.
Require Import DependentTypeLemmas.

Require Import List Coq.Logic.ProofIrrelevance Lia Classical_Prop Compare_dec EqNat Arith.
Require Import Coq.Program.Equality.

Module DTL := DependentTypeLemmas.

Import List.ListNotations.

(** ** This file has not been cleaned up from Pip (MMU) legacy in case
      some left over lemmas could be adapted **)

Lemma mappedPDTIsChild block sh1entryaddr partition childPart s:
nullAddrExists s
-> true = checkChild block s sh1entryaddr
-> isPDT partition s
-> bentryStartAddr block childPart s
-> sh1entryAddr block sh1entryaddr s
-> In block (getMappedBlocks partition s)
-> In childPart (getChildren partition s).
Proof.
intros HnullExists HblockIsChild HpartIsPDT Hstart Hsh1 HblockMapped. unfold getChildren.
unfold isPDT in HpartIsPDT. destruct (lookup partition (memory s) beqAddr); try(exfalso; congruence).
destruct v; try(exfalso; congruence). unfold getPDs. induction (getMappedBlocks partition s).
- intuition.
- simpl in *. destruct HblockMapped as [HblockIsA | HblockMappedRec].
  + subst a.
    assert(Hfilter: childFilter s block = true).
    {
      unfold checkChild in HblockIsChild. unfold childFilter. unfold sh1entryAddr in Hsh1.
      destruct (lookup block (memory s) beqAddr); try(exfalso; congruence).
      destruct v; try(exfalso; congruence). subst sh1entryaddr.
      unfold CPaddr in HblockIsChild. unfold Paddr.addPaddrIdx.
      destruct (le_dec (block + sh1offset) maxAddr).
      * set(blockSh1 := {|
                          p := block + sh1offset; Hp := ADT.CPaddr_obligation_1 (block + sh1offset) l0
                        |}).
        fold blockSh1 in HblockIsChild.
        assert(HblockSh1Eq: blockSh1
                = {| p := block + sh1offset; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 block sh1offset l0 |}).
        { subst blockSh1. f_equal. }
        rewrite <-HblockSh1Eq. apply eq_sym. assumption.
      * assert(HzeroIsNull: {| p := 0; Hp := ADT.CPaddr_obligation_2 (block + sh1offset) n |} = nullAddr).
        {
          unfold nullAddr. unfold CPaddr. destruct (le_dec 0 maxAddr); try(lia). f_equal.
          apply proof_irrelevance.
        }
        rewrite HzeroIsNull in *. unfold nullAddrExists in HnullExists. unfold isPADDR in HnullExists. exfalso.
        destruct (lookup nullAddr (memory s) beqAddr); try(congruence).
        destruct v; congruence.
    }
    rewrite Hfilter. simpl. left. unfold bentryStartAddr in Hstart.
    destruct (lookup block (memory s) beqAddr); try(exfalso; congruence).
    destruct v; try(exfalso; congruence). apply eq_sym. assumption.
  + specialize(IHl HblockMappedRec). destruct (childFilter s a); try(assumption). simpl. right. assumption.
Qed.


(* DUP *)
Lemma removeDupIdentity  (l :  list (paddr * value)) :
forall addr1 addr2 , addr1 <> addr2  ->
lookup addr1 (removeDup addr2 l  beqAddr) beqAddr =
lookup addr1 l beqAddr.
Proof.
intros.
induction l.
simpl. trivial.
simpl.
destruct a.
destruct p.
+ case_eq (beqAddr {| p := p; Hp := Hp |} addr2).
  - intros. cbn in *.
    case_eq (PeanoNat.Nat.eqb p addr1).
    * intros.
      apply Nat.eqb_eq in H0.
      apply Nat.eqb_eq in H1.
			rewrite H1 in H0.
			apply beqAddrFalse in H.
			unfold beqAddr in H.
			apply Nat.eqb_neq in H.
			congruence.

		* intros. assumption.
	- intros. simpl.
		case_eq (beqAddr {| p := p; Hp := Hp |} addr1).
		intros. trivial.
		intros. assumption.
Qed.

Lemma removeDupDupIdentity  (l :  list (paddr * value)) :
forall addr1 addr2 , addr1 <> addr2  ->
lookup addr1
  (removeDup addr2 (removeDup addr2 l beqAddr) beqAddr)
	beqAddr
= lookup addr1 (removeDup addr2 l beqAddr) beqAddr.
Proof.
intros.
induction l.
simpl. trivial.
simpl.
destruct a.
destruct p.
+ case_eq (beqAddr {| p := p; Hp := Hp |} addr2).
  - intros. cbn in *. rewrite removeDupIdentity. reflexivity.
		assumption.
	- intros. simpl.
		rewrite H0. simpl.
		case_eq (beqAddr {| p := p; Hp := Hp |} addr1).
		intros. trivial.
		intros. assumption.
Qed.

Lemma addrInBlockIsMapped partition addr block s:
In addr (getAllPaddrAux [block] s) ->
In block (getMappedBlocks partition s) ->
In addr (getMappedPaddr partition s).
Proof.
intros HInBlock HBlockInMapped.

unfold getMappedPaddr in *.
induction (getMappedBlocks partition s).
- intuition.
- simpl in *.

	destruct HBlockInMapped as [HblockIsA  | HBlockInl].
	--  subst a.
			destruct (lookup block (memory s) beqAddr) eqn:Hlookupblock ; try(exfalso; simpl in *; congruence).
			destruct v ; try(exfalso; simpl in *; congruence).
			rewrite app_nil_r in *.
			apply in_or_app. left. intuition.
	--	destruct (lookup block (memory s) beqAddr) eqn:Hlookupblock ; try(exfalso; simpl in *; congruence).
			destruct v ; try(exfalso; simpl in *; congruence).
			rewrite app_nil_r in *.
			destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; intuition.
			destruct v ; try(assumption). apply in_or_app. right. assumption.
Qed.

Lemma firstFreeSlotPointerIsFirstFree (pd:paddr) (s:state) (pdentry:PDTable) (slotListPd:list optionPaddr)
                                      (nbfreeslots:index):
slotListPd = getFreeSlotsList pd s
/\ lookup pd (memory s) beqAddr = Some (PDT pdentry)
/\ firstfreeslot pdentry <> nullAddr
/\ length (getFreeSlotsList pd s) = nbfreeslots
/\ pdentryNbFreeSlots pd nbfreeslots s
/\ consistency1 s
-> exists remainsSlotsList b newNbFree,
    getFreeSlotsList pd s = SomePaddr (firstfreeslot pdentry)::remainsSlotsList
    /\ lookup (firstfreeslot pdentry) (memory s) beqAddr = Some (BE b)
    /\ StateLib.Index.pred (ADT.nbfreeslots pdentry) = Some newNbFree
    /\ remainsSlotsList = getFreeSlotsListRec maxIdx (endAddr (blockrange b)) s newNbFree.
Proof.
intro Hprops.
destruct Hprops as [HgetFreeSlotsList (HlookupPd & (HfirstFreeNotNull & (HnbfreeIsLength & 
(HnbfreeIsNbFreeSlots & Hconsistency))))].
assert(Hsucc: maxIdx + 1 = S maxIdx) by lia.
destruct (getFreeSlotsList pd s) as [ | firstSlotPd slotList] eqn:HfreeSlotsListsPd;
  unfold getFreeSlotsList in HfreeSlotsListsPd; rewrite HlookupPd in HfreeSlotsListsPd;
  rewrite beqAddrFalse in HfirstFreeNotNull; rewrite HfirstFreeNotNull in HfreeSlotsListsPd;
  rewrite FreeSlotsListRec_unroll in HfreeSlotsListsPd; unfold getFreeSlotsListAux in HfreeSlotsListsPd;
  rewrite Hsucc in HfreeSlotsListsPd.
{
  destruct (StateLib.Index.ltb (ADT.nbfreeslots pdentry) zero); try(exfalso; congruence).
  destruct (lookup (firstfreeslot pdentry) (memory s) beqAddr); try(exfalso; congruence).
  destruct v; try(exfalso; congruence).
  - destruct (StateLib.Index.pred (ADT.nbfreeslots pdentry)); try(exfalso; congruence).
  - rewrite HfirstFreeNotNull in HfreeSlotsListsPd. congruence.
}
assert(HnbfreeIsPos: StateLib.Index.ltb (ADT.nbfreeslots pdentry) zero = false).
{
  unfold StateLib.Index.ltb. rewrite PeanoNat.Nat.ltb_nlt. unfold zero. intro Hcontra.
  apply indexLtZero with (ADT.nbfreeslots pdentry). assumption.
}
rewrite HnbfreeIsPos in HfreeSlotsListsPd.
assert(HfirstFreeBE: FirstFreeSlotPointerIsBEAndFreeSlot s) by (unfold consistency1 in *; intuition).
rewrite <-beqAddrFalse in HfirstFreeNotNull.
specialize(HfirstFreeBE pd pdentry HlookupPd HfirstFreeNotNull).
destruct HfirstFreeBE as [HfirstPisBE HfirstPisFree]. unfold isBE in HfirstPisBE.
destruct (lookup (firstfreeslot pdentry) (memory s) beqAddr) eqn:HlookupFirstFreeP; try(exfalso; congruence).
destruct v; try(exfalso; congruence). unfold pdentryNbFreeSlots in HnbfreeIsNbFreeSlots.
rewrite HlookupPd in HnbfreeIsNbFreeSlots. rewrite HnbfreeIsNbFreeSlots in *. simpl in HnbfreeIsLength.
assert(Hpred: exists newNbFree, StateLib.Index.pred (ADT.nbfreeslots pdentry) = Some newNbFree).
{
  unfold Index.pred in *. destruct (Compare_dec.gt_dec (ADT.nbfreeslots pdentry) 0); try(lia).
  set(newNbFree := {|
                     i := ADT.nbfreeslots pdentry - 1;
                     Hi := StateLib.Index.pred_obligation_1 (ADT.nbfreeslots pdentry) g
                   |}).
  exists newNbFree. reflexivity.
}
destruct Hpred as [newNbFree Hpred]. rewrite Hpred in *.
apply eq_sym in HfreeSlotsListsPd.
set(getFreeRemain:= getFreeSlotsListRec maxIdx (endAddr (blockrange b)) s newNbFree).
exists getFreeRemain. exists b. exists newNbFree. subst getFreeRemain. intuition.
Qed.

Lemma addrInAccessibleMappedIsAccessible partition block addr s:
noDupUsedPaddrList s ->
In addr (getAllPaddrAux [block] s) ->
In block (getMappedBlocks partition s) -> (* by block found *)
In addr (getAccessibleMappedPaddr partition s) ->
bentryAFlag block true s.
Proof.
intros HnoDup HInBlock HBlockInMapped HinAccMapped.
unfold getAccessibleMappedPaddr in HinAccMapped.
unfold getAccessibleMappedBlocks in HinAccMapped.
assert(HPDT : isPDT partition s).
{
  unfold isPDT. unfold getMappedBlocks in *.
	unfold getKSEntries in *.
	destruct (lookup partition (memory s) beqAddr) ; intuition.
	destruct v ; intuition.
}
specialize(HnoDup partition HPDT). unfold getUsedPaddr in HnoDup. apply Lib.NoDupSplitInclIff in HnoDup.
destruct HnoDup as [(Hconfig & HnoDupMapped) Hdisjoint]. unfold getMappedPaddr in HnoDupMapped.
clear Hconfig. clear Hdisjoint.
apply isPDTLookupEq in HPDT. destruct HPDT as [pdentry Hlookupd].
rewrite Hlookupd in HinAccMapped.
induction (getMappedBlocks partition s).
- exfalso. simpl in *. congruence.
- simpl in *. destruct HBlockInMapped as [HblockIsA | HBlockInl].
  + subst a.
		destruct (lookup block (memory s) beqAddr) eqn:HlookupBlock; try(exfalso; simpl in *; congruence).
		destruct v; try(exfalso; simpl in *; congruence).
    destruct (accessible b) eqn:Haccess.
    * unfold bentryAFlag. rewrite HlookupBlock. apply eq_sym. assumption.
    * apply Lib.NoDupSplitInclIff in HnoDupMapped. destruct HnoDupMapped as [H Hdisjoint].
      rewrite app_nil_r in HInBlock. specialize(Hdisjoint addr HInBlock).
      assert(Hcontra: In addr (getAllPaddrAux l s)).
      {
        apply NotInPaddrListNotInPaddrFilterAccessibleContra. assumption.
      }
      exfalso; congruence.
  + destruct (lookup a (memory s) beqAddr) eqn:HlookupA; try(apply IHl; assumption).
    destruct v; try(apply IHl; assumption).
    apply Lib.NoDupSplitInclIff in HnoDupMapped. destruct HnoDupMapped as [(H & HnoDupL) Hdisjoint].
    destruct (accessible b) eqn:Haccess; try(apply IHl; assumption). simpl in HinAccMapped.
    rewrite HlookupA in HinAccMapped. apply in_app_or in HinAccMapped.
    destruct HinAccMapped as [HinB | HinAccMapped]; try(apply IHl; assumption).
		destruct (lookup block (memory s) beqAddr) eqn:HlookupBlock; try(exfalso; simpl in *; congruence).
    destruct v; try(exfalso; simpl in *; congruence).
    rewrite app_nil_r in HInBlock. specialize(Hdisjoint addr HinB).
    assert(HinBlockAux: In addr (getAllPaddrAux [block] s)).
    {
      simpl. rewrite HlookupBlock. rewrite app_nil_r. assumption.
    }
    contradict Hdisjoint. apply blockIsMappedAddrInPaddrList with block; assumption.
Qed.

Lemma addrInAccessibleBlockIsAccessibleMapped partition block addr s:
In addr (getAllPaddrAux [block] s) ->
In block (getMappedBlocks partition s) -> (* by block found *)
bentryAFlag block true s ->
In addr (getAccessibleMappedPaddr partition s).
Proof.
intros HInBlock HBlockInMapped Haccessible.

unfold getAccessibleMappedPaddr in *.
unfold getAccessibleMappedBlocks.
assert(HPDT : isPDT partition s).
{ unfold isPDT. unfold getMappedBlocks in *.
	unfold getKSEntries in *.
	destruct (lookup partition (memory s) beqAddr) ; intuition.
	destruct v ; intuition.
}
apply isPDTLookupEq in HPDT. destruct HPDT as [pdentry Hlookupd].
rewrite Hlookupd.
induction (getMappedBlocks partition s).
- intuition.
-
 simpl in *.

	destruct HBlockInMapped as [HblockIsA  | HBlockInl].
	--  subst a.
			destruct (lookup block (memory s) beqAddr) eqn:Hlookupblock ; try(exfalso; simpl in *; congruence).
			destruct v ; try(exfalso; simpl in *; congruence).
			rewrite app_nil_r in *.
			unfold bentryAFlag in *. rewrite Hlookupblock in *.
			rewrite <-Haccessible.
			simpl. rewrite Hlookupblock.
			apply in_or_app. left. intuition.
	--	destruct (lookup block (memory s) beqAddr) eqn:Hlookupblock ; try(exfalso; simpl in *; congruence).
			destruct v ; try(exfalso; simpl in *; congruence).
			rewrite app_nil_r in *.
			destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; try(apply IHl; assumption).
			destruct v ; try(apply IHl; assumption).
			destruct (accessible b0) ; intuition.
			simpl.
			rewrite Hlookupa.
			apply in_or_app. right. intuition.
Qed.

Lemma accessibleBlockIsAccessibleMapped partition block s:
In block (getMappedBlocks partition s) ->
bentryAFlag block true s ->
In block (getAccessibleMappedBlocks partition s).
Proof.
intros HBlockInMapped Haccessible.
unfold getAccessibleMappedBlocks.
assert(HPDT : isPDT partition s).
{ unfold isPDT. unfold getMappedBlocks in *.
	unfold getKSEntries in *.
	destruct (lookup partition (memory s) beqAddr) ; intuition.
	destruct v ; intuition.
}
apply isPDTLookupEq in HPDT. destruct HPDT as [pdentry Hlookupd].
rewrite Hlookupd.
induction (getMappedBlocks partition s).
- intuition.
-
 simpl in *. unfold bentryAFlag in Haccessible.

	destruct HBlockInMapped as [HblockIsA  | HBlockInl].
	--  subst a.
			destruct (lookup block (memory s) beqAddr) eqn:Hlookupblock ; intuition.
			destruct v ; intuition. rewrite <-Haccessible.
			simpl. left. reflexivity.
	--	assert(In block (filterAccessible l s)) by (apply IHl; assumption).
			destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; intuition.
			destruct v ; intuition.
			destruct (accessible b); try(simpl; right) ; assumption.
Qed.

Lemma addrInAccessibleMappedIsIsMappedPaddr partition addr s:
In addr (getAccessibleMappedPaddr partition s) ->
In addr (getMappedPaddr partition s).
Proof.
intro HaccessibleMapped.
unfold getAccessibleMappedPaddr in *.
unfold getAccessibleMappedBlocks in *.
unfold getMappedPaddr.
destruct (lookup partition (memory s) beqAddr) eqn:Hlookupparts0; try(exfalso; simpl in *; congruence).
destruct v ; try(exfalso; simpl in *; congruence).
induction (getMappedBlocks partition s).
- intuition.
- simpl in *.
	destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; intuition.
	destruct v ; intuition.
	destruct (accessible b) ; try(apply in_or_app; right; apply IHl; assumption).
	simpl in *. rewrite Hlookupa in *.
	apply in_app_iff in HaccessibleMapped. apply in_or_app.
  destruct HaccessibleMapped as [Hleft | Hright]; try(left; assumption). right.
	intuition.
Qed.

(*
(* Require Import Model.ADT Model.Hardware Core.Services Isolation
Consistency Invariants WeakestPreconditions Model.Lib StateLib
Model.MAL UpdateShadow1Structure InternalLemmas DependentTypeLemmas Lib
WriteAccessible *)
Lemma inclGetIndirectionsAuxLe root s n m :
n <= m ->
incl (getIndirectionsAux root s n) (getIndirectionsAux root s m).
Proof.
revert  m n root.
unfold incl.
induction m;simpl;
intros.
destruct n.
simpl in *.
trivial.
lia.
assert(Hor : root = a \/ root <> a) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].
left;trivial.
right.
rewrite in_flat_map.
destruct n.
simpl in *.
intuition.
simpl in *.
intuition.
rewrite in_flat_map in H1.
destruct H1 as (x & Hx1 & Hx2).
exists x.
split;trivial.
apply IHm with (n);trivial.
lia.
Qed.

Lemma getIndirectionStop1 s indirection x idxind va l:
StateLib.Level.eqb l fstLevel = false ->  indirection <> defaultPage ->
lookup indirection idxind (memory s) beqPage beqIndex = Some (PE x) ->
StateLib.getIndexOfAddr va l  =  idxind ->
StateLib.getIndirection indirection va l 1 s = Some (pa x).
Proof.
intros Hlnotzero Hindnotnull Hlookup Hidx .
unfold StateLib.getIndirection.
  case_eq (StateLib.Level.eqb l fstLevel).
  - intros H2. rewrite H2 in Hlnotzero.
    contradict Hlnotzero.  intuition.
  - intros H2.
    unfold  StateLib.getIndexOfAddr in *.
    case_eq ( ge_dec l (length va)).
    * intros.
      destruct va.
      simpl in *.
      subst.
      destruct l. simpl in *.
      contradict H.
      lia.
   * unfold runvalue in Hidx.
     intros.
     unfold StateLib.readPhyEntry.
     inversion Hidx.
     rewrite H0.
     rewrite Hlookup.
     case_eq(Nat.eqb defaultPage (pa x)).
     intros.
     apply beq_nat_true in H1.
     f_equal.
     unfold defaultPage in *.
     unfold CPage.
     unfold CPage in H1.
     destruct(lt_dec 0 nbPage).
     subst.
     simpl in *.
     destruct x.
     simpl in *.
     subst.
     destruct pa.
     simpl in *.
     subst.
     assert (Hp = ADT.CPage_obligation_1 0 l0).
     apply proof_irrelevance.
     subst.
     reflexivity.
     destruct page_d.
     destruct pa.
     simpl in *.
     subst.
     assert (Hp0 = Hp).
     apply proof_irrelevance.
     subst. reflexivity.
     intros.
     unfold StateLib.Level.pred.
     case_eq (gt_dec l 0).
     intros g H4; reflexivity.
     intros.
     subst.
     apply levelEqBEqNatFalse0 in H2.
     contradict H2.
     assumption.

Qed.

Lemma inNotInList  :
forall (l : list page) (a : page), In a l \/ ~ In a l.
Proof.
intros.
induction l;simpl.
right;auto.
destruct IHl.
left.
right.
trivial.
assert(a0= a \/ a0 <> a) by apply pageDecOrNot.
destruct H0.
left;left;trivial.
right.
intuition.
Qed.

Lemma getIndirectionStopS :
forall  stop (s : state) (nbL : level)  nextind pd va indirection,
stop + 1 <= nbL -> indirection <> defaultPage ->
StateLib.getIndirection pd va nbL stop s = Some indirection->
StateLib.getIndirection indirection va (CLevel (nbL - stop)) 1 s = Some (pa nextind) ->
StateLib.getIndirection pd va nbL (stop + 1) s = Some (pa nextind).
Proof.
induction stop.
- intros. simpl.
  cbn in *.
  inversion H1.
  subst.
  rewrite NPeano.Nat.sub_0_r in H2.
  unfold CLevel in H2.
  destruct (lt_dec nbL nbLevel ).
  simpl in *.
  destruct nbL.
  simpl in *.
  assert (Hl = ADT.CLevel_obligation_1 l0 l ).
  apply proof_irrelevance.
  subst.
  assumption.
  destruct nbL. simpl in *.
  contradict n.
  lia.
- intros.
  simpl .
  simpl in H1.
  case_eq (StateLib.Level.eqb nbL fstLevel).
  + intros. rewrite <- H2.
    inversion H1.
    subst.
    symmetry.
    rewrite H3 in H5. inversion H5. subst.
    simpl. clear H1.
    apply levelEqBEqNatTrue in H3.
    case_eq (StateLib.Level.eqb (CLevel (nbL - S stop)) fstLevel).
    intros.
    reflexivity.
    intros.
    apply levelEqBEqNatFalse0 in H1.

    contradict H1.
    unfold CLevel.
    case_eq ( lt_dec (nbL - S stop) nbLevel ).
    intros. simpl . rewrite H3.
    unfold fstLevel.
    unfold CLevel.
    case_eq(lt_dec 0 nbLevel ).
    intros.
    simpl. lia.
    intros.
    assert(0 < nbLevel).
    apply nbLevelNotZero.
    contradict H6. lia.
    intros.
    Opaque StateLib.getIndirection.
    simpl in *.
    unfold fstLevel in H3.
    unfold CLevel in H3.
    case_eq (lt_dec 0 nbLevel).
    intros.
    rewrite H4 in H3.
    simpl in *.
    destruct nbL.
    simpl in *.
    subst.
    inversion H3.
    subst. lia.
    intros.
    assert (0 < nbLevel).
    apply nbLevelNotZero.
    lia.
  + intros Hftlevel.
    rewrite Hftlevel in H1.
    case_eq (StateLib.readPhyEntry pd (StateLib.getIndexOfAddr va nbL) (memory s)).
    { intros. rewrite H3 in H1.
      case_eq (Nat.eqb defaultPage p).
      - intros. rewrite H4 in H1.
        inversion H1.
       contradict H0. intuition.
      - intros. rewrite H4 in H1.
        case_eq (StateLib.Level.pred nbL ).
        + intros. rewrite H5 in H1.
          unfold StateLib.Level.pred in H5.
          case_eq (gt_dec nbL 0).
          intros.
          rewrite H6 in H5.
          generalize (IHstop s l nextind p va indirection);clear IHstop;intros IHstop.
          apply IHstop.
          inversion H5.
          simpl in *.
          lia.
          assumption.
          assumption.
          clear IHstop.
          inversion H5.
          Opaque StateLib.getIndirection.
          simpl in *.
          subst.
          replace (nbL - 1 - stop) with (nbL - S stop).
          assumption.
          lia.
          intros.
          apply levelEqBEqNatFalse0 in Hftlevel.
          contradict Hftlevel.
          lia.
          Transparent StateLib.getIndirection.
        + intros.  rewrite H5 in H1. inversion H1.

     }
     { intros. rewrite H3 in H1.    inversion H1. }
Qed.

Lemma getIndirectionProp :
forall stop s nextind idxind indirection pd va (nbL : level),
stop +1 <= nbL -> indirection <> defaultPage ->
StateLib.Level.eqb (CLevel (nbL - stop)) fstLevel = false ->
StateLib.getIndexOfAddr va (CLevel (nbL - stop)) = idxind ->
lookup indirection idxind (memory s) beqPage beqIndex = Some (PE nextind)->
StateLib.getIndirection pd va nbL stop s = Some indirection ->
StateLib.getIndirection pd va nbL (stop + 1) s = Some (pa nextind).
Proof.
intros.
apply getIndirectionStopS with indirection;trivial.
apply getIndirectionStop1  with idxind;trivial.
Qed.

Lemma getIndirectionStopS1 :
forall  stop (s : state) (nbL : level)  nextind pd va indirection,
stop + 1 <= nbL -> indirection <> defaultPage ->
StateLib.getIndirection pd va nbL stop s = Some indirection->
StateLib.getIndirection indirection va (CLevel (nbL - stop)) 1 s = Some (nextind) ->
StateLib.getIndirection pd va nbL (stop + 1) s = Some (nextind).
Proof.
induction stop.
- intros. simpl.
  cbn in *.
  inversion H1.
  subst.
  rewrite NPeano.Nat.sub_0_r in H2.
  unfold CLevel in H2.
  destruct (lt_dec nbL nbLevel ).
  simpl in *.
  destruct nbL.
  simpl in *.
  assert (Hl = ADT.CLevel_obligation_1 l0 l ).
  apply proof_irrelevance.
  subst.
  assumption.
  destruct nbL. simpl in *.
  contradict n.
  lia.
- intros.
  simpl .
  simpl in H1.
  case_eq (StateLib.Level.eqb nbL fstLevel).
  + intros. rewrite <- H2.
    inversion H1.
    subst.
    symmetry.
    rewrite H3 in H5. inversion H5. subst.
    simpl. clear H1.
    apply levelEqBEqNatTrue in H3.
    case_eq (StateLib.Level.eqb (CLevel (nbL - S stop)) fstLevel).
    intros.
    reflexivity.
    intros.
    apply levelEqBEqNatFalse0 in H1.

    contradict H1.
    unfold CLevel.
    case_eq ( lt_dec (nbL - S stop) nbLevel ).
    intros. simpl . rewrite H3.
    unfold fstLevel.
    unfold CLevel.
    case_eq(lt_dec 0 nbLevel ).
    intros.
    simpl. lia.
    intros.
    assert(0 < nbLevel).
    apply nbLevelNotZero.
    contradict H6. lia.
    intros.
    Opaque StateLib.getIndirection.
    simpl in *.
    unfold fstLevel in H3.
    unfold CLevel in H3.
    case_eq (lt_dec 0 nbLevel).
    intros.
    rewrite H4 in H3.
    simpl in *.
    destruct nbL.
    simpl in *.
    subst.
    inversion H3.
    subst. lia.
    intros.
    assert (0 < nbLevel).
    apply nbLevelNotZero.
    lia.
  + intros Hftlevel.
    rewrite Hftlevel in H1.
    case_eq (StateLib.readPhyEntry pd (StateLib.getIndexOfAddr va nbL) (memory s)).
    { intros. rewrite H3 in H1.
      case_eq (Nat.eqb defaultPage p).
      - intros. rewrite H4 in H1.
        inversion H1.
       contradict H0. intuition.
      - intros. rewrite H4 in H1.
        case_eq (StateLib.Level.pred nbL ).
        + intros. rewrite H5 in H1.
          unfold StateLib.Level.pred in H5.
          case_eq (gt_dec nbL 0).
          intros.
          rewrite H6 in H5.
          generalize (IHstop s l nextind p va indirection);clear IHstop;intros IHstop.
          apply IHstop.
          inversion H5.
          simpl in *.
          lia.
          assumption.
          assumption.
          clear IHstop.
          inversion H5.
          Opaque StateLib.getIndirection.
          simpl in *.
          subst.
          replace (nbL - 1 - stop) with (nbL - S stop).
          assumption.
          lia.
          intros.
          apply levelEqBEqNatFalse0 in Hftlevel.
          contradict Hftlevel.
          lia.
          Transparent StateLib.getIndirection.
        + intros.  rewrite H5 in H1. inversion H1.

     }
     { intros. rewrite H3 in H1.    inversion H1. }
Qed.
 Lemma getIndirectionRetNotDefaultLtNbLevel:
 forall (stop2 stop1  : nat) (nbL : level)  (pd table1 table2 : page) (va : vaddr) (s : state),
 (Nat.eqb defaultPage pd) = false ->
 stop1 <= stop2 ->
 getIndirection pd va nbL stop1 s = Some table1 ->
 getIndirection pd va nbL stop2 s = Some table2 ->
 (Nat.eqb defaultPage table2) = false  ->
 (Nat.eqb defaultPage table1) = false.
 Proof.
 induction stop2;simpl; intros.
 assert(stop1 = 0) by lia.
 subst.
 simpl in *.
 inversion H1;inversion H2.
 subst.
 assumption.
 (* destruct table2; destruct table1; simpl in *.
 inversion H6.
 subst.
 assumption. *)
 case_eq(StateLib.Level.eqb nbL fstLevel);intros;
 rewrite H4 in *.
 + destruct stop1;simpl in *.
     inversion H1;inversion H2.
     subst.
    (*  destruct table2; destruct table1; simpl in *.
     inversion H7.
     subst. *)
     assumption.
   - rewrite H4 in H1.
      inversion H1;inversion H2.
     subst.
     (*
     destruct table2; destruct table1; simpl in *.
     inversion H7.
     subst.
      *) assumption.
 + case_eq(StateLib.readPhyEntry pd (StateLib.getIndexOfAddr va nbL) (memory s) );
 [intros next Hnext | intros Hnext];
 rewrite Hnext in *; try now contradict H1.
 case_eq(Nat.eqb defaultPage next) ;intros  Hb; rewrite Hb in *.
 - inversion H2.
 subst.
 apply beq_nat_false in H3.
 now contradict H3.
-  case_eq(StateLib.Level.pred nbL); intros; rewrite H5 in *; try now contradict H2.
 destruct stop1.
 simpl in *.
 inversion H1.
 subst.
 trivial.
 simpl in *.
 rewrite H4 in *.
 rewrite Hnext in *.
 rewrite Hb in *.
 rewrite H5 in *.
   apply IHstop2 with stop1 l next  table2 va s;trivial.
   lia.
 Qed.
Lemma fstIndirectionContainsValue_nbLevel_1  indirection idxroot s idx va l currentPart :
(idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx) ->
dataStructurePdSh1Sh2asRoot idxroot s -> In currentPart (getPartitions multiplexer s) ->
StateLib.Level.eqb l fstLevel = true ->
nextEntryIsPP currentPart idxroot indirection s ->
StateLib.getIndexOfAddr va fstLevel = idx -> indirection <> defaultPage ->
Some l = StateLib.getNbLevel ->
isVE indirection idx s /\ idxroot = sh1idx \/
isVA indirection idx s /\ idxroot = sh2idx \/
isPE indirection idx s /\ idxroot = PDidx.
Proof.
intros Hisroot Hroot Hcprpl Hfstlevel Hcurpd  Hidxva  Hpdnotnull Hnblevel.
unfold dataStructurePdSh1Sh2asRoot in *.
unfold currentPartitionInPartitionsList in *.


generalize (Hroot currentPart Hcprpl); clear Hroot; intro Hroot.
assert (True) as Hvarefchild.
trivial. (** va into the list of all Vaddr **)
subst.
intros.
generalize (Hroot indirection  Hcurpd va Hvarefchild l
          (nbLevel-1) Hnblevel indirection (StateLib.getIndexOfAddr va fstLevel));clear Hroot.
intros Hroot.
destruct Hroot.
+ (** prove a condition into consistency **) subst.
 induction ((nbLevel - 1)).
 * simpl in *.
   trivial.
 * simpl.
   rewrite Hfstlevel.
   trivial.
+ contradict H.  assumption.
+ destruct H.
  destruct H as [(H & Hnotfstlevel) | H].
  unfold StateLib.getNbLevel in *.
  assert (nbLevel > 0).
  apply nbLevelNotZero.
  destruct (gt_dec nbLevel 0).
  { simpl in *.
    inversion Hnblevel. simpl in *.
    subst.
    contradict H. simpl.  lia. }
  { contradict H. lia. }
 destruct H. assumption.
Qed.

Lemma  lastIndirectionContainsValueRec   idxroot s l rootind indirection va idx currentPart:
StateLib.Level.eqb l fstLevel = true ->
In currentPart (getPartitions multiplexer s) ->
dataStructurePdSh1Sh2asRoot idxroot s ->
 (idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx )->
 nextEntryIsPP currentPart idxroot rootind s ->
rootind <> defaultPage ->
(exists (nbL : level) (stop : nat),
                 Some nbL = StateLib.getNbLevel /\ stop <= nbL /\
                 getIndirection rootind va nbL stop s = Some indirection /\
                 indirection <> defaultPage /\ l = CLevel (nbL - stop) ) ->
StateLib.getIndexOfAddr va fstLevel = idx ->
isVE indirection idx s /\ idxroot = sh1idx \/
isVA indirection idx s /\ idxroot = sh2idx \/
isPE indirection idx s /\ idxroot = PDidx.
Proof.
intros Hfstlevel Hcurpart Hroot Hisroot Hcurpd
        Hpdnotnull Hindirection Hidx.
destruct Hindirection. destruct H. destruct H.
unfold dataStructurePdSh1Sh2asRoot in *.
generalize (Hroot currentPart Hcurpart); clear Hroot; intro Hroot.
assert (True) as Hvarefchild;trivial. (** va into the list of all Vaddr **)
subst.
destruct H0. destruct H1.
generalize (Hroot rootind  Hcurpd va Hvarefchild x x0 H indirection (StateLib.getIndexOfAddr va fstLevel) );clear Hroot;
intros Hroot.
destruct Hroot. assumption.
destruct H2. now contradict H2.
destruct H3.
apply levelEqBEqNatTrue in Hfstlevel.
subst.
destruct H2.
unfold fstLevel in H5.
apply levelEqNat in H5.
+ destruct H3 as [(Hfalse &H3) | H3].
  contradict Hfalse;lia.
  destruct H3. assumption.
+ apply nbLevelNotZero.
+ unfold StateLib.getNbLevel in H.
  assert (nbLevel > 0).
  apply nbLevelNotZero.
  destruct (gt_dec nbLevel 0).
  simpl in *.
  inversion H.
  subst.
  simpl. lia.
  contradict H5.
  lia.
Qed.

Lemma fstIndirectionContainsPENbLevelGT1 idxroot s l currentpd va idxind currentPart :
(idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx) ->
 StateLib.Level.eqb l fstLevel = false ->
dataStructurePdSh1Sh2asRoot idxroot s ->
In currentPart (getPartitions multiplexer s) ->
nextEntryIsPP currentPart idxroot currentpd s ->
 currentpd <> defaultPage ->
 Some l = StateLib.getNbLevel ->
 StateLib.getIndexOfAddr va l = idxind ->  (* isPE currentpd idxpd s. *)
isPE currentpd idxind s.
Proof.

intros Hroot Hnotfstlevel Hisroot Hcprpl  Hcurpd Hpdnotnull Hlevel Hidx .
 unfold  dataStructurePdSh1Sh2asRoot in Hroot.
          assert (True) as Hvarefchild.
          trivial. (** va into the list of all Vaddr **)
          assert (In currentPart ( getPartitions multiplexer s) ) as Hcurpart.
          { unfold currentPartitionInPartitionsList in Hcprpl.
            subst. intuition. }
          subst.
          assert ( StateLib.getIndirection currentpd va l fstLevel s =
          Some currentpd ) as Hnextind.
          { unfold fstLevel.
            unfold CLevel.
            assert (nbLevel > 0).
            apply nbLevelNotZero.
            case_eq (lt_dec 0 nbLevel).
            intros. simpl.
            cbn. reflexivity.
            intros. contradict H. lia. }
(*           destruct Hindirection as (Hcurind & Hlevel).
          subst.   *)
          unfold dataStructurePdSh1Sh2asRoot in Hisroot.
          generalize (Hisroot currentPart Hcurpart currentpd Hcurpd va
          Hvarefchild  l fstLevel Hlevel currentpd (StateLib.getIndexOfAddr va l) Hnextind);
          clear Hisroot; intro Hisroot.
          destruct Hisroot. subst. contradict Hpdnotnull. reflexivity.
          destruct H as (H & _).
          subst.
          apply levelEqBEqNatFalse0 in Hnotfstlevel.
          destruct H as [(Hl & H) | H].
          assumption.
          destruct H. unfold fstLevel in H.
          unfold CLevel in H. destruct (lt_dec 0 nbLevel).
           simpl in *. contradict H. lia.
           assert (0 < nbLevel).
           apply nbLevelNotZero. now contradict H1.
Qed.

Lemma middleIndirectionsContainsPE  idxroot s l rootind indirection va idxind currentPart:
 (idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx )->
StateLib.Level.eqb l fstLevel = false ->
In currentPart (getPartitions multiplexer s) ->
dataStructurePdSh1Sh2asRoot idxroot s ->

rootind <> defaultPage ->
(exists (nbL : level) (stop : nat),
                 Some nbL = StateLib.getNbLevel /\ stop <= nbL /\
                 getIndirection rootind va nbL stop s = Some indirection /\
                 indirection <> defaultPage /\ l = CLevel (nbL - stop) ) ->
nextEntryIsPP currentPart idxroot rootind s  ->
isPE indirection idxind s.
Proof.
intros Hisroot Hnotfstlevel Hcurpart Hroot  Hpdnotnull Hindirection Hcurpd (* Hidx *).
destruct Hindirection. destruct H.
destruct H.
subst.
unfold dataStructurePdSh1Sh2asRoot in *.
unfold currentPartitionInPartitionsList in *.
generalize (Hroot currentPart Hcurpart); clear Hroot; intro Hroot.
assert (True) as Hvarefchild.
trivial. (** va into the list of all Vaddr **)
subst.
destruct H0.
generalize (Hroot rootind  Hcurpd va Hvarefchild x
x0 H indirection idxind);clear Hroot.
intros Hroot.
destruct H1 as (Hind & Hnotnull & Hlevel).
destruct Hroot.
assumption. now contradict H1.
apply levelEqBEqNatFalse0 in Hnotfstlevel.
subst.
destruct H1.
destruct H1 as [(Hx & Hpe)  | H1].
+ assumption.
+ destruct H1.
  destruct H1.  subst.  apply level_gt in Hnotfstlevel.  destruct x.
  simpl in *. contradict Hnotfstlevel. lia. assert (0 < nbLevel).
  apply nbLevelNotZero. lia.
  lia.
Qed.

Lemma getIndirectionStopLevelGT s va p (l: nat) (level : level)  (l0 : nat) p0:
l0 > level -> l = level ->
getIndirection p va level l s = Some p0 ->
getIndirection p va level l0 s = Some p0.
Proof.
intros.
revert p0 p level l H H0 H1.
induction l0;
intros. now contradict H.
simpl.
destruct l; simpl in *.
assert (  StateLib.Level.eqb level fstLevel = true).
unfold MALInternal.Level.eqb.
apply NPeano.Nat.eqb_eq.
rewrite <- H0. unfold fstLevel. unfold CLevel.
assert ( 0 < nbLevel) by apply nbLevelNotZero.
case_eq (lt_dec 0 nbLevel ); intros.
simpl. trivial.
now contradict H2.
rewrite H2. assumption.
simpl in *.
case_eq (StateLib.Level.eqb level fstLevel); intros.
rewrite H2 in H1. destruct l0. simpl. assumption. assumption.
+ simpl. rewrite H2 in H1.
  case_eq(StateLib.readPhyEntry p (StateLib.getIndexOfAddr va level) (memory s) ). intros.
  rewrite H3 in H1.
  case_eq (Nat.eqb defaultPage p1); intros;
  rewrite H4 in H1. assumption.
  case_eq (StateLib.Level.pred level);
  intros; rewrite H5 in H1.
  apply levelPredMinus1 in H5; trivial. unfold CLevel in H5.
  case_eq(lt_dec (level - 1) nbLevel ); intros; rewrite H6 in H5. destruct level. simpl in *. subst.
  simpl in *.
  apply IHl0 with l; trivial. simpl. lia. simpl. lia.
  destruct level. simpl in *. lia. assumption.
  intros. rewrite H3 in H1. assumption.
Qed.

Lemma getIndirectionStopLevelGT2 s va p (l: nat) (level : level)  (l0 : nat) p0:
l0 > level -> l = level ->
getIndirection p va level l0 s = Some p0 ->
getIndirection p va level l s = Some p0.
Proof.
intros.
revert p0 p level l H H0 H1.
induction l0;
intros. now contradict H.
simpl.
destruct l; simpl in *.
assert (  StateLib.Level.eqb level fstLevel = true).
unfold MALInternal.Level.eqb.
apply NPeano.Nat.eqb_eq.
rewrite <- H0. unfold fstLevel. unfold CLevel.
assert ( 0 < nbLevel) by apply nbLevelNotZero.
case_eq (lt_dec 0 nbLevel ); intros.
simpl. trivial.
now contradict H2.
rewrite H2 in H1. assumption.
simpl in *.
case_eq (StateLib.Level.eqb level fstLevel); intros.
rewrite H2 in H1. destruct l0. simpl. assumption. assumption.
+ simpl. rewrite H2 in H1.
  case_eq(StateLib.readPhyEntry p (StateLib.getIndexOfAddr va level) (memory s) ). intros.
  rewrite H3 in H1.
  case_eq (Nat.eqb defaultPage p1); intros;
  rewrite H4 in H1. assumption.
  case_eq (StateLib.Level.pred level);
  intros; rewrite H5 in H1.
  apply levelPredMinus1 in H5; trivial.
  unfold CLevel in H5.
  case_eq(lt_dec (level - 1) nbLevel ); intros; rewrite H6 in H5.
  destruct level. simpl in *. subst.
  simpl in *.

  apply IHl0 ; trivial. simpl. lia. simpl. lia.
  destruct level. simpl in *. lia. assumption.
  intros. rewrite H3 in H1. assumption.
Qed.

Lemma getIndirectionRetDefaultLtNbLevel l1 l0 (nbL :level) p va s:
l0 > 0 ->
l0 < l1 ->
l0 < nbL ->
getIndirection p va nbL l0 s = Some defaultPage ->
getIndirection p va nbL l1 s = Some defaultPage.
Proof.
revert l0 nbL p va.
induction l1; intros.
+ now contradict H0.
+ simpl in *.
  case_eq (StateLib.Level.eqb nbL fstLevel); intros.
  destruct l0.
  now contradict H.
  simpl in H2.
  rewrite H3 in H2. assumption.
  case_eq (StateLib.readPhyEntry p (StateLib.getIndexOfAddr va nbL) (memory s)); intros.
  case_eq (Nat.eqb defaultPage p0); intros; trivial.
  case_eq (StateLib.Level.pred nbL); intros.
  destruct l0.
  now contradict H2.
  simpl in H2.
  rewrite H3 in H2.
  rewrite H4 in H2.
  rewrite H5 in H2.
  rewrite H6 in H2.
  apply IHl1 with l0.
  destruct l0.
  simpl in H2.
  inversion H2.
  subst.
  contradict H5.
  apply Bool.not_false_iff_true.
  symmetry.
  apply beq_nat_refl.
  lia.
  lia.
  apply levelPredMinus1 with nbL l in H3; trivial.
  destruct nbL.
  simpl in *.
  unfold CLevel in H3.
  case_eq (lt_dec (l2 - 1) nbLevel); intros; rewrite H7 in H3.
  destruct l.
  simpl in *.
  inversion H3.
  subst.
  lia. lia.
  assumption.
  unfold StateLib.Level.pred in H6.
  apply levelEqBEqNatFalse0 in H3.
  case_eq (gt_dec nbL 0); intros; rewrite H7 in *.
  now contradict H6.
  lia.
  destruct l0. now contradict H.
  simpl in H2.
  rewrite H3 in H2.
  rewrite H4 in H2.
  assumption.
Qed.

Lemma getIndirectionNbLevelEq (l1 l0 : nat) (nbL :level) p va s:
l0 > 0 ->
l1 = nbL ->
l0 <= nbL ->
getIndirection p va nbL l0 s = Some defaultPage ->
getIndirection p va nbL l1 s = Some defaultPage.
Proof.
revert l0 nbL p va.
induction l1; intros.
+ lia.
+ simpl in *.
  case_eq (StateLib.Level.eqb nbL fstLevel); intros.
  destruct l0.
  now contradict H.
  simpl in H2.
  rewrite H3 in H2. assumption.
  case_eq (StateLib.readPhyEntry p (StateLib.getIndexOfAddr va nbL) (memory s)); intros.
  case_eq (Nat.eqb defaultPage p0); intros; trivial.
  case_eq (StateLib.Level.pred nbL); intros.
  destruct l0.
  now contradict H.

  simpl in H2.
  rewrite H6 in H2.
  rewrite H3 in H2.
  rewrite H4 in H2.
  rewrite H5 in H2.
  apply IHl1 with l0.
  destruct l0.
  simpl in H2.
  inversion H2.
  subst.
  contradict H5.
  apply Bool.not_false_iff_true.
  symmetry.
  apply beq_nat_refl.
  lia.
  apply levelPredMinus1 with nbL l in H3; trivial.
  destruct nbL.
  simpl in *.
  unfold CLevel in H3.
  case_eq (lt_dec (l2 - 1) nbLevel); intros; rewrite H7 in H3.
  destruct l.
  simpl in *.
  inversion H3.
  subst.
  lia. lia.
  unfold StateLib.Level.pred in H6.
  apply levelEqBEqNatFalse0 in H3.
  case_eq (gt_dec nbL 0); intros; rewrite H7 in *.
  inversion H6.
  destruct l.
  simpl in *.
  inversion H9.
  lia. now contradict H3.
  assumption.
    unfold StateLib.Level.pred in H6.
  apply levelEqBEqNatFalse0 in H3.
  case_eq (gt_dec nbL 0); intros; rewrite H7 in *.
  inversion H6.
  now contradict H3.

  destruct l0.
  now contradict H2.
  simpl in H2.
  rewrite H3 in H2.
  rewrite H4 in H2.
  assumption.
Qed.

Lemma checkVAddrsEqualityWOOffsetTrue' n va1 va2 (nbL predNbL : level) :
StateLib.checkVAddrsEqualityWOOffset n va1 va2 nbL = true ->
predNbL <= nbL ->
nbL < n ->
StateLib.getIndexOfAddr va1 predNbL  = StateLib.getIndexOfAddr va2 predNbL .
Proof.
revert nbL predNbL.
induction n.
+ simpl in *.
intros.

lia.
+
intros.
simpl in H.
case_eq(StateLib.Level.eqb nbL fstLevel); intros; rewrite H2 in *.
 - apply levelEqBEqNatTrue in H2.
subst.
assert(predNbL = fstLevel).
clear H IHn.
unfold fstLevel in * .
unfold CLevel in *.
case_eq(lt_dec 0 nbLevel );intros.
rewrite H in *.

destruct predNbL.
simpl in *.
assert(l0 = 0) by lia.
subst.
f_equal;apply proof_irrelevance;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
subst.
apply beq_nat_true in H.
destruct (StateLib.getIndexOfAddr va1 fstLevel);
destruct (StateLib.getIndexOfAddr va2 fstLevel).
simpl in *.
subst.
f_equal;apply proof_irrelevance;trivial.
-
case_eq(StateLib.Level.pred nbL); intros; rewrite H3 in *.
 * case_eq(Nat.eqb (StateLib.getIndexOfAddr va1 nbL) (StateLib.getIndexOfAddr va2 nbL));
intros; trivial; rewrite H4 in *;try now contradict H4.
apply NPeano.Nat.lt_eq_cases in H0.
destruct H0.
 apply IHn with l;trivial.
 apply levelPredMinus1 in H3;trivial.

  unfold CLevel in H3.
  case_eq (lt_dec (nbL - 1) nbLevel); intros.
  rewrite H5 in *.
  destruct l.
  inversion H3.
  subst.
  simpl.
  apply levelEqBEqNatFalse0  in H2.
  lia.
  apply levelEqBEqNatFalse0 in H2.
  rewrite H5 in *.
  destruct nbL.
  simpl in *.
  lia.
 apply levelPredLt in H3;trivial.
 lia.
 apply beq_nat_true in H4.
 destruct predNbL.
 destruct nbL.
 simpl in *.
 subst.
 assert(Hl = Hl0) by apply proof_irrelevance.
 subst.
  destruct (StateLib.getIndexOfAddr va1 {| l := l1; Hl := Hl0 |}).
  destruct (StateLib.getIndexOfAddr va2 {| l := l1; Hl := Hl0 |}).
  simpl in *.
  subst.
  f_equal.
  apply proof_irrelevance.

*
apply levelPredNone in H2.
 destruct (StateLib.Level.pred nbL).
 now contradict H3.
 now contradict H2.
Qed.

Lemma checkVAddrsEqualityWOOffsetTrue2 :
forall (n : nat) (va1 va2 : vaddr) (nbL predNbL : level),
n <= nbLevel ->
StateLib.checkVAddrsEqualityWOOffset n va1 va2 nbL = true ->
nbL < n ->
predNbL <= nbL ->
StateLib.checkVAddrsEqualityWOOffset n va1 va2 predNbL = true.
Proof.
induction n.
simpl in *.
trivial.
intros va1 va2 nbL predNbL Htrue.
intros.
simpl in *.
case_eq  (StateLib.Level.eqb nbL fstLevel); intros;rewrite H2 in *;trivial.
+ case_eq( StateLib.Level.eqb predNbL fstLevel); intros.
  - apply levelEqBEqNatTrue in H2;trivial.
    apply levelEqBEqNatTrue in H3;trivial.
    subst.
    assumption.
  - apply levelEqBEqNatTrue in H2;trivial.
    apply levelEqBEqNatFalse in H3;trivial.
    subst.
    lia.
+ case_eq (StateLib.Level.pred nbL); intros; rewrite H3 in *.
  * case_eq(Nat.eqb (StateLib.getIndexOfAddr va1 nbL) (StateLib.getIndexOfAddr va2 nbL)); intros;
        rewrite H4 in *; try now contradict H.
    case_eq(StateLib.Level.eqb predNbL fstLevel);intros.
    apply NPeano.Nat.eqb_eq.
    apply NPeano.Nat.lt_eq_cases in H1.
    destruct H1.
    rewrite checkVAddrsEqualityWOOffsetTrue' with n  va1 va2 l predNbL;trivial.
    apply levelPredMinus1 in H3; trivial.
    { unfold CLevel in H3.
  case_eq (lt_dec (nbL - 1) nbLevel); intros.
  rewrite H6 in *.
  destruct l.
  inversion H3.
  subst.
  simpl.
  lia.
  rewrite H6 in *.
  destruct nbL.
  simpl in *.
  lia. }
 apply levelPredLt in H3;trivial.
 lia.
 apply beq_nat_true in H4.
 destruct predNbL.
 destruct nbL.
 simpl in *.
 subst.
 assert(Hl = Hl0) by apply proof_irrelevance.
 subst.
  destruct (StateLib.getIndexOfAddr va1 {| l := l1; Hl := Hl0 |}).
  destruct (StateLib.getIndexOfAddr va2 {| l := l1; Hl := Hl0 |}).
  simpl in *.
  subst.
  trivial.

   case_eq  (StateLib.Level.pred predNbL ); intros;trivial.
   case_eq (Nat.eqb (StateLib.getIndexOfAddr va1 predNbL)
                    (StateLib.getIndexOfAddr va2 predNbL)
           ); intros.
  apply IHn with l.
  lia.
  assumption.
  apply levelPredLt in H3;trivial.
  apply levelPredLt in H6;trivial.
  lia.
  apply levelPredMinus1 in H6;trivial.
  unfold CLevel in H6.
  case_eq (lt_dec (predNbL - 1) nbLevel ); intros.
  rewrite H8 in H6.
  inversion H6.

  simpl in *.
    apply levelPredMinus1 in H3;trivial.
  unfold CLevel in H3.
  case_eq (lt_dec (nbL - 1) nbLevel ); intros.
  rewrite H10 in H3.
  inversion H3.

  simpl in *.
  lia.
  destruct nbL.
  simpl in *.
  lia.

  destruct predNbL.
  simpl in *.


  lia.

   assert(StateLib.getIndexOfAddr va1 predNbL  = StateLib.getIndexOfAddr va2 predNbL ).

      apply NPeano.Nat.lt_eq_cases in H1.
    destruct H1.
    rewrite checkVAddrsEqualityWOOffsetTrue' with n  va1 va2 l predNbL;trivial.
    apply levelPredMinus1 in H3; trivial.
    { unfold CLevel in H3.
  case_eq (lt_dec (nbL - 1) nbLevel); intros.
  rewrite H8 in *.
  destruct l.
  inversion H3.
  subst.
  simpl.
  lia.
  rewrite H8 in *.
  destruct nbL.
  simpl in *.
  lia. }
 apply levelPredLt in H3;trivial.
 lia.
 apply beq_nat_true in H4.
 destruct predNbL.
 destruct nbL.
 simpl in *.
 subst.
 assert(Hl = Hl0) by apply proof_irrelevance.
 subst.
  destruct (StateLib.getIndexOfAddr va1 {| l := l2; Hl := Hl0 |}).
  destruct (StateLib.getIndexOfAddr va2 {| l := l2; Hl := Hl0 |}).
  simpl in *.
  subst.
  apply beq_nat_false in H7.
  lia.
  apply beq_nat_false in H7.
    destruct (StateLib.getIndexOfAddr va1 predNbL);
    destruct (StateLib.getIndexOfAddr va2 predNbL).
    simpl in *.
    inversion H8.
    subst.
    now contradict H7.
  * apply levelPredNone in H3.
    contradict H3.
    destruct(StateLib.Level.pred nbL).
    assumption.
    trivial.
Qed.
Lemma checkVAddrsEqualityWOOffsetTrue va1 va2 (nbL predNbL : level):
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
nbL < nbLevel ->
predNbL <= nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 predNbL = true.
Proof.
assert (Htrue : nbLevel <= nbLevel) by lia.
revert va1 va2 nbL predNbL Htrue.
generalize nbLevel at 1 3 4 5.
apply checkVAddrsEqualityWOOffsetTrue2.
Qed.


Lemma getIndirectionEq (nbL : level) va1 va2 pd stop s:
nbL < nbLevel  ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
getIndirection pd va1 nbL stop s =
getIndirection pd va2 nbL stop s .
Proof.
intros Hlevel Heq.
revert nbL va1 va2  pd Hlevel Heq.
induction stop.
simpl in *.
trivial.
simpl.
intros.
case_eq (StateLib.Level.eqb nbL fstLevel).
intros;trivial.
intros.
assert(StateLib.getIndexOfAddr va1 nbL  = StateLib.getIndexOfAddr va2 nbL ).
apply checkVAddrsEqualityWOOffsetTrue' with nbLevel nbL;trivial.
rewrite H0.
case_eq (StateLib.readPhyEntry pd (StateLib.getIndexOfAddr va2 nbL) (memory s) );
intros; trivial.
case_eq(Nat.eqb defaultPage p);intros;trivial.
case_eq( StateLib.Level.pred nbL); intros;trivial.
apply IHstop.
apply levelPredMinus1 in H3.
subst.
unfold CLevel.
case_eq( lt_dec (nbL - 1) nbLevel); intros.
simpl.
assumption.
apply levelEqBEqNatFalse0 in H;trivial.
lia.
trivial.
apply checkVAddrsEqualityWOOffsetTrue with nbL;trivial.
apply levelPredMinus1 in H3.
subst.
unfold CLevel.
case_eq( lt_dec (nbL - 1) nbLevel); intros.
simpl.
apply levelEqBEqNatFalse0 in H;trivial.
lia.
destruct nbL.
simpl in *.
lia.
assumption.
Qed.

Lemma Index_eq_i (i1 i2 : index) : (ADT.i i1) = (ADT.i i2) -> i1 = i2.
Proof.
  revert i1 i2; intros (i1 & Hi1) (i2 & Hi2).
  simpl.
  intros Heqi; subst i1.
  assert (HeqHi : Hi1 = Hi2) by apply proof_irrelevance.
  now subst.
Qed.

Lemma AllIndicesAll : forall idx : index, In idx getAllIndices.
Proof.
  assert (Gen: forall n i j: nat, i <= j < n + i -> j < tableSize -> In (CIndex j) (getAllIndicesAux i n)).
  { intros n.
    induction n as [ | n IH ]; [ intros i j H; contradict H; lia | ].
     intros i j (Hlei & Hltn) Hltsize.
     simpl.
     destruct (lt_dec i tableSize) as [ Hltsize'' | Hgtsize ];
        [ | contradict Hgtsize; now apply le_lt_trans with j ].
     apply le_lt_or_eq in Hlei; destruct Hlei as [ Hlti | Heqi ].
     - right.
        apply IH; [ | assumption ].
        now lia.
     - left; subst i.
        unfold CIndex.
        destruct (lt_dec j tableSize); [ | now contradict Hltsize ].
        now apply Index_eq_i.
  }
  unfold getAllIndices.
  intros (i & Hi).
  assert (Heq : Build_index i Hi = CIndex i).
  { unfold CIndex.
    destruct (lt_dec i tableSize); [ | now contradict Hi ].
    now apply Index_eq_i. }
  rewrite Heq.
  apply Gen; lia.
Qed.

Lemma VAddrEqVA (v1 v2: vaddr) : ADT.va v1 = ADT.va v2 -> v1 = v2.
Proof.
  revert v1 v2; intros (v1 & Hv1) (v2 & Hv2).
  simpl; intros Heq; subst v1.
  assert (Heq: Hv1 = Hv2) by apply proof_irrelevance.
  now subst.
Qed.

Lemma AllVAddrAll : forall v : vaddr, In v getAllVAddr.
Proof.
  assert (Gen: forall levels (idxs: list index), length idxs = levels -> In idxs (getAllVAddrAux levels)).
  { intros levels.
    induction levels as [ | levels IH ].

    - intros idxs Hlen0; left; symmetry.
      now rewrite <- length_zero_iff_nil.
    - intros idxs Hlen.
      unfold getAllVAddrAux.
      apply in_flat_map.
      destruct idxs as [ | idx idxs ];
        [ now contradict Hlen | ].
      exists idx; split; [apply AllIndicesAll | ].
      apply in_map_iff.
      exists idxs; split; [ easy | ].
      apply IH.
      simpl in Hlen.
      now apply eq_add_S.
  }

  unfold getAllVAddr, CVaddr.
  intros (v & Hv).
  apply in_map_iff.
  exists v.
  split.

  - destruct (PeanoNat.Nat.eq_dec (length v) (nbLevel + 1));
    [ | now contradict Hv ].
    now apply VAddrEqVA.

  - apply Gen.
    rewrite Hv.
    now apply PeanoNat.Nat.add_1_r.
Qed.
 Lemma lengthRemoveLast(A :Type) :
     forall l : list A, forall n, length l = S n ->length (removelast l) = n.
     Proof.
     induction l;simpl;intros.
     lia.
     case_eq l;intros.
     inversion H.
     subst;trivial.
     Opaque removelast.
     simpl.
     assert(n=0 \/ n > 0) by lia.
     destruct H1 ;subst.
     simpl in H.
     lia.

     assert((length (removelast (a0 :: l0))) = (n-1)).
     apply IHl.
     simpl in *.
     inversion H.
     rewrite H2.

     lia.
     rewrite H0.
     lia.
     Transparent removelast.
     Qed.
Lemma AllVAddrWithOffset0 :
forall va, exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel va va1 ( CLevel (nbLevel -1) ) = true.
Proof.
intros.
assert(Hinva : In va getAllVAddr) by apply AllVAddrAll.
unfold getAllVAddrWithOffset0.
eexists.
split.
+ destruct va.

  instantiate(1:= (CVaddr (removelast va ++ [CIndex 0]))).
  apply filter_In.
  split.
  - apply AllVAddrAll.
  - unfold checkOffset0.
  simpl.
    case_eq(Nat.eqb (nth nbLevel (CVaddr (removelast va ++ [CIndex 0])) defaultIndex) (CIndex 0));
    intros;trivial.
    unfold CVaddr in *.
     assert(Hmykey : length (removelast va) = nbLevel).
     { apply lengthRemoveLast;lia. }
    case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1));
      intros; rewrite H0 in *;simpl in *.
    * rewrite <- H.
      clear H0 H.
      rewrite <- Hva in e.
      rewrite app_nth2.
      rewrite Hmykey.
      simpl.
      case_eq(nbLevel - nbLevel);intros;try lia.
      symmetry. apply beq_nat_refl.
      lia.
    * clear H0.
    contradict n.
    rewrite app_length.
    rewrite Hmykey.
    simpl;trivial.
+ assert(Hmykey : length (removelast va) = nbLevel).
     {  assert (length va = nbLevel +1).
       { destruct va. simpl. trivial. }  apply lengthRemoveLast;lia. }
       replace va with  (CVaddr (removelast va ++ [last va defaultIndex]))
       at 1.
     {
     clear Hinva.
     assert(Hmykey1 : length (removelast va) >= nbLevel) by lia.
     clear Hmykey.
     revert va  Hmykey1.
     induction nbLevel;simpl;trivial.
     intros.
     case_eq (StateLib.Level.eqb (CLevel (n - 0)) fstLevel);intros.
     + assert(n=0).
       { replace (n - 0) with n in * by lia.
         { unfold StateLib.Level.eqb in *.
           unfold fstLevel in *.
           apply beq_nat_true in H.
           apply levelEqNat;subst;trivial.
           assert(Hmykey : length (removelast va) = nbLevel).
           { assert (length va = nbLevel +1).
             { destruct va. simpl. trivial. }
             apply lengthRemoveLast;lia. }
             rewrite <-Hmykey.
             lia.
             apply nbLevelNotZero.
            destruct (CLevel n);destruct (CLevel 0);simpl in *.
            subst;f_equal;apply proof_irrelevance.
        } }
       subst.
     simpl in *.
  rewrite NPeano.Nat.eqb_eq.
  clear H.
unfold StateLib.getIndexOfAddr.
assert(Htmp :CLevel 0 + 2 =2).
{ unfold CLevel.
assert(0<nbLevel) by apply nbLevelNotZero.
case_eq( lt_dec 0 nbLevel);intros; try now contradict H1.
simpl;lia. lia. }
rewrite Htmp in *;clear Htmp.
 assert(Hi :length (removelast va ++ [CIndex 0])  =
length (removelast va ++ [last va defaultIndex]) ).
{  rewrite app_length.
rewrite app_length.
simpl.
trivial. }
assert (Hi1:length (CVaddr (removelast va ++ [CIndex 0])) - 2 =
 (length (CVaddr (removelast va ++ [last va defaultIndex])) - 2)).
 { unfold CVaddr .
   case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1));intros;
   simpl.
   + case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));intros;simpl.
     - rewrite Hi.  trivial.
     - clear H H0.
     rewrite Hi in e.
     contradiction.
   +  case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));intros;simpl.
     - rewrite e.
      rewrite repeat_length.  trivial.
     -trivial. }
rewrite Hi1.
set (pos := length (CVaddr (removelast va ++ [last va defaultIndex])) - 2) in *.
unfold CVaddr.
case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));simpl;intros;trivial.
 - assert(Hmykey : pos < length (removelast va)).
 {  unfold pos in *. clear pos.
     unfold CVaddr.
     rewrite H.
     simpl.
     rewrite app_length.
     simpl. lia. }
   case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1) );
    simpl;intros;trivial.
   * rewrite app_nth1;trivial.
  rewrite app_nth1;trivial.

   * clear H H0.  rewrite Hi in *. contradiction.
  -  case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1));
  simpl;intros;trivial.  clear H H0.  rewrite Hi in *. contradiction.
  + case_eq(StateLib.Level.pred (CLevel (n - 0)));simpl; intros;trivial.
    case_eq(Nat.eqb (StateLib.getIndexOfAddr (CVaddr (removelast va ++ [last va defaultIndex]))
    (CLevel (n - 0)))
  (StateLib.getIndexOfAddr (CVaddr (removelast va ++ [CIndex 0]))
    (CLevel (n - 0))));intros.
*   assert( StateLib.checkVAddrsEqualityWOOffset n
        (CVaddr (removelast va ++ [last va defaultIndex]))
        (CVaddr (removelast va ++ [CIndex 0])) (CLevel (n - 1)) = true).
        apply IHn;trivial.
        lia.
         assert(Hmykey : length (removelast va) = nbLevel).
     {  assert (length va = nbLevel +1).
       { destruct va. simpl. trivial. }  apply lengthRemoveLast;lia. }
    apply checkVAddrsEqualityWOOffsetTrue2 with (CLevel (n - 1));trivial.
     rewrite Hmykey in *.
     lia.
     unfold CLevel.
     case_eq(lt_dec (n - 1) nbLevel );simpl;intros;trivial.
     assert(Hn : n=0 \/ n> 0) by lia.
     destruct Hn as [Hn | Hn];subst.
     simpl in *.
    assert( Htrue : StateLib.Level.eqb (CLevel ( 0)) fstLevel = true).
    {  unfold StateLib.Level.eqb. unfold fstLevel.
      symmetry. apply beq_nat_refl. }
      rewrite Htrue in *.
      intuition.
      lia.
      lia.
      replace (n-0) with n in * by lia.
      simpl in *.
     apply levelPredMinus1 in H0;trivial.
     subst.
     unfold CLevel at 2.
     case_eq( lt_dec n nbLevel);intros;simpl.
     lia.
     clear H0.
     rewrite <-  Hmykey in n0.
     lia.
  * rewrite <- H1.
      rewrite NPeano.Nat.eqb_eq.
        replace (n-0) with n in * by lia.

        unfold StateLib.getIndexOfAddr.

 assert(Hi :length (removelast va ++ [CIndex 0])  =
length (removelast va ++ [last va defaultIndex]) ).
        {  rewrite app_length.
        rewrite app_length.
        simpl.
        trivial. }
assert (Hi1:length (CVaddr (removelast va ++ [CIndex 0])) -  (CLevel n + 2) =
 (length (CVaddr (removelast va ++ [last va defaultIndex])) -  (CLevel n + 2))).
 { unfold CVaddr .
   case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1));intros;
   simpl.
   + case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));intros;simpl.
     - rewrite Hi.  trivial.
     - clear H2 H3.
     rewrite Hi in e.
     contradiction.
   +  case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));intros;simpl.
     - rewrite e.
      rewrite repeat_length.  trivial.
     -trivial. }
rewrite Hi1.
set (pos := length (CVaddr (removelast va ++ [last va defaultIndex])) -  (CLevel n + 2)) in *.
unfold CVaddr.
case_eq(PeanoNat.Nat.eq_dec (length (removelast va ++ [last va defaultIndex]))
      (nbLevel + 1));simpl;intros;trivial.
 - assert(Hmykey : pos < length (removelast va)).
 {  unfold pos in *. clear pos.
     unfold CVaddr.
     rewrite H2.
     simpl.
     rewrite app_length.
     simpl. lia. }
   case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1) );
    simpl;intros;trivial.
    --

   rewrite app_nth1;trivial.
  rewrite app_nth1;trivial.

   -- clear H2 H3.  rewrite Hi in *. contradiction.
  -  case_eq( PeanoNat.Nat.eq_dec (length (removelast va ++ [CIndex 0])) (nbLevel + 1));
  simpl;intros;trivial.  clear H2 H3.  rewrite Hi in *. contradiction. }
  rewrite <- app_removelast_last .
  destruct va. unfold CVaddr.
  case_eq( PeanoNat.Nat.eq_dec (length  {| ADT.va := va; Hva := Hva |}) (nbLevel + 1));intros;simpl in *;trivial.
  f_equal.
  apply proof_irrelevance.
  clear H.
  rewrite Hva in *.
  now contradict n.
  destruct va.
  simpl.
  intuition.
  subst.
  simpl in *.
  lia.
Qed.


Lemma noDupAllVaddr : NoDup getAllVAddr.
Proof.
  assert (Gen: forall levels (idxs: list index), In idxs (getAllVAddrAux levels) -> length idxs = levels) .
  { intros levels.
    induction levels as [ | levels IH ].

    - intros idxs Hlen0. simpl in *. intuition. rewrite <- H.
    apply length_zero_iff_nil;trivial.
    - intros idxs Hlen.
      simpl in *.
      rewrite  in_flat_map in Hlen.
      destruct Hlen as (x & Hx & Hxx).
      rewrite in_map_iff in Hxx.
      destruct Hxx as (xs & Hxs & Hgen).
      rewrite <- Hxs.
      simpl.
      f_equal.
      apply IH;trivial.
  }
  assert(Gen1 :  forall  (idxs : list index),
   In idxs (getAllVAddrAux (S nbLevel)) -> length idxs = (S nbLevel)).
    { intros.
      apply Gen;trivial. }
  clear Gen.
  unfold getAllVAddr.
  assert(Hnodup : NoDup (getAllVAddrAux (S nbLevel))).
  { clear Gen1.

    induction (S nbLevel).
    simpl;constructor;intuition.
    constructor.
    simpl. unfold getAllIndices. simpl.

    assert(NoDup (getAllIndicesAux 0 tableSize)).
    { clear IHn n.
       assert (Gen: forall n i j: nat, i <= j < n + i -> j < tableSize -> In (CIndex j) (getAllIndicesAux i n)).
  { intros n.
    induction n as [ | n IH ]; [ intros i j H; contradict H; lia | ].
     intros i j (Hlei & Hltn) Hltsize.
     simpl.
     destruct (lt_dec i tableSize) as [ Hltsize'' | Hgtsize ];
        [ | contradict Hgtsize; now apply le_lt_trans with j ].
     apply le_lt_or_eq in Hlei; destruct Hlei as [ Hlti | Heqi ].
     - right.
        apply IH; [ | assumption ].
        now lia.
     - left; subst i.
        unfold CIndex.
        destruct (lt_dec j tableSize); [ | now contradict Hltsize ].
        now apply Index_eq_i.
  }

  clear Gen.
  assert(tableSize <= tableSize) by lia.
  generalize 0.
  revert H.
  generalize tableSize at 1 3 .
  induction n. simpl. constructor.
  intros.
  simpl.
  case_eq( lt_dec n0 tableSize);intros;constructor.
  simpl.
  assert (Gen: forall n i j: nat, j < i -> ~In (CIndex j) (getAllIndicesAux i n)).
  { clear.  intros n.
    induction n.
    simpl. intuition.
    simpl.
    intros.

  case_eq(lt_dec i tableSize);intros.
  simpl.
  apply Classical_Prop.and_not_or.
  split.
  unfold CIndex.
  case_eq (lt_dec j tableSize );intros.
  unfold not;intros.
  inversion H2.
  subst.
  lia.
  lia.
  apply IHn. lia.
  intuition.
   }
  assert( ~ In (CIndex n0) (getAllIndicesAux (S n0) n)).
  apply Gen.
  lia.
  unfold CIndex in H1.
  rewrite H0 in *.
  assumption.
  simpl.
  apply IHn.
   lia.  }
   induction  (getAllIndicesAux 0 tableSize).
   +
   simpl.
   constructor.
   +
   simpl.
   apply NoDupSplitInclIff.
   split.
   -
   split.
   *
   clear IHl.
   induction (getAllVAddrAux n).
   simpl.
   constructor.
   simpl.
   apply NoDup_cons.
   rewrite in_map_iff.
   unfold not;intros.
   destruct H0 as (x & Hx & Hxx).
   inversion Hx.
   subst.
   apply NoDup_cons_iff in IHn.
   intuition.
   apply IHl0.
   apply NoDup_cons_iff in IHn.
   intuition.
   *
   apply IHl.
   apply NoDup_cons_iff in H.
   intuition.
   -
   unfold disjoint.
   intros.
   assert( NoDup (flat_map (fun idx : index => map (cons idx) (getAllVAddrAux n)) l)).
   apply IHl.
   apply NoDup_cons_iff in H.
   intuition. clear IHl.
   rewrite in_map_iff in H0.
   destruct H0 as (x0 & Hx0 &Hxx0).
   rewrite <- Hx0 in *.
   rewrite in_flat_map.
   unfold not;intros.
   destruct H0 as (b & Hb & Hbb).
   rewrite in_map_iff in Hbb.


   destruct Hbb as  (c & Hc & Hcc).

   inversion Hc.
   subst.
   clear Hc.
      apply NoDup_cons_iff in H.
      intuition.
  }
  induction (getAllVAddrAux (S nbLevel)).
  simpl in *.
  constructor.
  simpl.
  apply NoDup_cons_iff in Hnodup.
  constructor.
  simpl in *.
  destruct Hnodup.
  clear IHl.
  clear H0.
  rewrite in_map_iff.
  contradict H.
  destruct H as (x & Hx & Hxx)  .
  assert(length x = S nbLevel).
  apply Gen1.
  right.
  trivial.
  assert(length a = S nbLevel).
  apply Gen1.
  left;trivial.
  assert (x = a).
  unfold CVaddr in *.
  case_eq ( PeanoNat.Nat.eq_dec (length x) (nbLevel + 1) ); intros;
  rewrite H1 in *.
  case_eq(PeanoNat.Nat.eq_dec (length a) (nbLevel + 1));intros;
  rewrite H2 in *.
  inversion Hx;trivial.
  clear H2 Hx.
  rewrite  H0 in n.
  lia.
  clear H1 Hx.
  rewrite H in n.
  lia.
  subst. trivial.
  apply IHl.
  intros.
  apply Gen1.
  simpl;right;trivial.
  intuition.
Qed. (** noDupAllVaddr*)

Lemma filterOptionInIff l elt :
List.In elt (filterOption l) <-> List.In (SomePage elt) l.
Proof.
split.
+ revert l elt.
  induction l.
  simpl; trivial.
  intros.
  simpl in *.
  case_eq a; intros .
  *
  rewrite H0 in H.
  simpl in H.
  destruct H;
  subst.
  left; trivial.
  right.
  apply IHl; trivial.
  *
  rewrite H0 in H.
  right. apply IHl; trivial.
  *
  rewrite H0 in H.
  right. apply IHl; trivial.
+ revert l elt.
  induction l.
  simpl; trivial.
  intros.
  simpl in *.
  case_eq a; intros .
  *
  rewrite H0 in H.
  simpl in H.
  destruct H;
  subst.
  left; trivial.
  inversion H; trivial.
  simpl.
  right.
  apply IHl; trivial.
  *
  apply IHl; trivial.
  destruct H. subst.
  now contradict H0.
  assumption.
  *
  apply IHl; trivial.
  destruct H. subst.
  now contradict H0.
  assumption.
Qed.

Lemma checkVAddrsEqualityWOOffsetEqFalse  (nbL alevel : level):
forall va1 va2,
Some nbL = StateLib.getNbLevel ->
alevel <= nbL ->
false = StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 alevel ->
va1 <> va2.
Proof.
intros.
revert alevel H1 H0.
induction nbLevel;
simpl in *; intros.
- now contradict H1.
- case_eq(StateLib.Level.eqb alevel fstLevel); intros; rewrite H2 in *.
  + unfold not; intros.
    subst.
    symmetry in H1.
    apply beq_nat_false in H1.
    apply H1. reflexivity.
  + case_eq (StateLib.Level.pred alevel); intros; rewrite H3 in *; try now contradict H1.
    case_eq (Nat.eqb (StateLib.getIndexOfAddr va1 alevel)
                     (StateLib.getIndexOfAddr va2 alevel)
            ); intros; rewrite H4 in *.
    apply IHn with l; trivial.
    apply levelPredMinus1 in H3; trivial.
    apply getNbLevelEq in H.
    assert(0<nbLevel) by apply nbLevelNotZero.
    unfold CLevel in *.
    case_eq(lt_dec (nbLevel - 1) nbLevel); intros; rewrite H6 in *; try lia.
    case_eq(lt_dec (alevel - 1) nbLevel); intros; rewrite H7 in *; simpl in *.
    destruct nbL; simpl in *.
    inversion H.
    subst.
    simpl.
    destruct alevel.
    simpl in *.
    lia.
    destruct alevel.
    simpl in *.
    lia.
    unfold not; intros.
    subst.
    apply beq_nat_false in H4.
    apply H4. reflexivity.
Qed.

(* Lemma twoMappedPagesAreDifferent' phy1 phy2 v1 v2 p s:
getMappedPage p s v1 = Some phy1 ->
 In v1 getAllVAddr ->
 getMappedPage p s v2 = Some phy2->
In v2 getAllVAddr ->
NoDup (filterOption (map (getMappedPage p s) getAllVAddr)) ->
v1 <> v2 ->
phy1 <> phy2.
Proof.
revert phy1 phy2 v1 v2.
induction getAllVAddr.
intuition.
intros.
destruct H0; destruct H2.
subst.
(* rewrite H2 in H4. *)
now contradict H4.
subst.
simpl in *.
rewrite H in H3.
apply NoDup_cons_iff in H3.
destruct H3.
assert(In phy2 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists v2; split; trivial.
unfold not; intros.
subst.
now contradict H0.
subst.
simpl in *.
rewrite H1 in H3.
apply NoDup_cons_iff in H3.
destruct H3.
assert(In phy1 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists v1; split; trivial.
unfold not; intros.
subst.
now contradict H0.
subst.
apply IHl with v1 v2; trivial.
simpl in H3.
destruct(getMappedPage p s a ).
apply NoDup_cons_iff in H3.
intuition.
assumption.
Qed.
 *)
Lemma getMappedPageEq pd va1 va2  nbL s :
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
getMappedPage pd s va1 = getMappedPage pd s va2.
Proof.
intros HnbL Heqva.
unfold getMappedPage.
rewrite HnbL.
assert(Heqind : getIndirection pd va1 nbL (nbLevel - 1) s =
getIndirection pd va2 nbL (nbLevel - 1) s).
apply getIndirectionEq;trivial.
apply getNbLevelLt;trivial.
rewrite Heqind.
destruct (getIndirection pd va2 nbL (nbLevel - 1) s);trivial.
assert(Heqidx : (StateLib.getIndexOfAddr va1 fstLevel) = (StateLib.getIndexOfAddr va2 fstLevel)).
apply checkVAddrsEqualityWOOffsetTrue'  with nbLevel nbL;trivial.
apply fstLevelLe.
apply getNbLevelLt;trivial.
rewrite Heqidx;trivial.
Qed.


Lemma checkChildEq partition va1 va2  nbL s :
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
checkChild partition nbL s va1 = checkChild partition nbL s va2.
Proof.
intros HnbL Heqva.
unfold checkChild.
destruct (StateLib.getFstShadow partition (memory s)) ;trivial.
assert(Heqind : getIndirection p va1 nbL (nbLevel - 1) s =
getIndirection p va2 nbL (nbLevel - 1) s).
apply getIndirectionEq;trivial.
apply getNbLevelLt;trivial.
rewrite Heqind.
destruct (getIndirection p va2 nbL (nbLevel - 1) s);trivial.
assert(Heqidx : (StateLib.getIndexOfAddr va1 fstLevel) = (StateLib.getIndexOfAddr va2 fstLevel)).
apply checkVAddrsEqualityWOOffsetTrue'  with nbLevel nbL;trivial.
apply fstLevelLe.
apply getNbLevelLt;trivial.
rewrite Heqidx;trivial.
Qed.

Lemma getPDFlagEq sh1 va1 va2  nbL s :
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
getPDFlag sh1 va1 s = getPDFlag sh1 va2 s.
Proof.
intros HnbL Heqva.
unfold getPDFlag.
rewrite HnbL.
assert(Heqind : getIndirection sh1 va1 nbL (nbLevel - 1) s =
getIndirection sh1 va2 nbL (nbLevel - 1) s).
apply getIndirectionEq;trivial.
apply getNbLevelLt;trivial.
rewrite Heqind.
destruct (getIndirection sh1 va2 nbL (nbLevel - 1) s);trivial.
assert(Heqidx : (StateLib.getIndexOfAddr va1 fstLevel) = (StateLib.getIndexOfAddr va2 fstLevel)).
apply checkVAddrsEqualityWOOffsetTrue'  with nbLevel nbL;trivial.
apply fstLevelLe.
apply getNbLevelLt;trivial.
rewrite Heqidx;trivial.
Qed.

Lemma getVirtualAddressSh1Eq sh1 va1 va2  nbL s :
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
getVirtualAddressSh1 sh1 s va1 = getVirtualAddressSh1 sh1 s va2.
Proof.
intros HnbL Heqva.
unfold getVirtualAddressSh1.
rewrite HnbL.
assert(Heqind : getIndirection sh1 va1 nbL (nbLevel - 1) s =
getIndirection sh1 va2 nbL (nbLevel - 1) s).
apply getIndirectionEq;trivial.
apply getNbLevelLt;trivial.
rewrite Heqind.
destruct (getIndirection sh1 va2 nbL (nbLevel - 1) s);trivial.
assert(Heqidx : (StateLib.getIndexOfAddr va1 fstLevel) = (StateLib.getIndexOfAddr va2 fstLevel)).
apply checkVAddrsEqualityWOOffsetTrue'  with nbLevel nbL;trivial.
apply fstLevelLe.
apply getNbLevelLt;trivial.
rewrite Heqidx;trivial.
Qed.

Lemma  checkVAddrsEqualityWOOffsetTrans :
forall vaChild va1 a level,
StateLib.checkVAddrsEqualityWOOffset nbLevel vaChild va1
          level = true ->
StateLib.checkVAddrsEqualityWOOffset nbLevel a va1 level =
      false ->
StateLib.checkVAddrsEqualityWOOffset nbLevel vaChild a level = false.
Proof.

induction nbLevel;simpl;trivial.
intros.
case_eq(StateLib.Level.eqb level fstLevel);intros;rewrite H1 in *.
+
apply beq_nat_true in H.
rewrite H.
apply NPeano.Nat.eqb_neq.
apply beq_nat_false in H0.
intuition.
+
case_eq(StateLib.Level.pred level);intros;rewrite H2 in *.
-
case_eq(Nat.eqb (StateLib.getIndexOfAddr vaChild level)
                (StateLib.getIndexOfAddr va1 level)
       );intros;rewrite H3 in *.
      * apply beq_nat_true in H3. trivial.
        rewrite H3;trivial.
        rewrite PeanoNat.Nat.eqb_sym;trivial.
        case_eq(Nat.eqb (StateLib.getIndexOfAddr a level)
                        (StateLib.getIndexOfAddr va1 level)
               );intros H4;
        rewrite H4 in *;trivial.
        apply IHn  with va1;trivial;trivial.
    * now contradict H.
 - now contradict H0.
Qed.
Lemma checkVAddrsEqualityWOOffsetPermut va1 va2 level1 :
  StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 level1 =
  StateLib.checkVAddrsEqualityWOOffset nbLevel va2 va1 level1.
Proof.
  revert va1 va2 level1.
  induction nbLevel.
  simpl. trivial.
  simpl. intros.
  case_eq (StateLib.Level.eqb level1 fstLevel); intros.
  apply NPeano.Nat.eqb_sym.
  case_eq(StateLib.Level.pred level1);
  intros; trivial.
  rewrite  NPeano.Nat.eqb_sym.
  case_eq (Nat.eqb (StateLib.getIndexOfAddr va2 level1)
                   (StateLib.getIndexOfAddr va1 level1)
          ); intros; trivial.
Qed.

Lemma checkVAddrsEqualityWOOffsetEqTrue  descChild nbL :
StateLib.checkVAddrsEqualityWOOffset nbLevel descChild descChild nbL = true.
Proof.
revert nbL.
induction nbLevel;intros.
simpl;trivial.
simpl.
destruct (StateLib.Level.eqb nbL fstLevel).
symmetry.
apply beq_nat_refl.
destruct(StateLib.Level.pred nbL);trivial.
rewrite <- beq_nat_refl.
apply IHn;trivial.
Qed.
Lemma twoMappedPagesAreDifferent phy1 phy2 v1 v2 p nbL s:
getMappedPage p s v1 = SomePage phy1 ->
getMappedPage p s v2 = SomePage phy2->
NoDup (filterOption (map (getMappedPage p s) getAllVAddrWithOffset0)) ->
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel v1 v2 nbL = false ->
phy1 <> phy2.
Proof.
intros.
assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel v1 va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1 & Hva11).
assert(Hmap1: getMappedPage p s va1 = SomePage phy1).
rewrite <- H.
symmetry.
apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.
clear H.

assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel v2 va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va2 & Hva2 & Hva22).
assert(Hmap2: getMappedPage p s va2 = SomePage phy2).
rewrite <- H0.
symmetry.
apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.
clear H0.
assert(Hx :StateLib.checkVAddrsEqualityWOOffset nbLevel  va2 v1 nbL = false).
apply checkVAddrsEqualityWOOffsetTrans with v2;trivial.
rewrite <- Hva22.
assert(StateLib.getNbLevel = Some (CLevel (nbLevel - 1))).
apply getNbLevelEqOption.
rewrite  H in *.
inversion H2;trivial.
apply checkVAddrsEqualityWOOffsetPermut.
assert(Hvax :StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = false).
apply checkVAddrsEqualityWOOffsetTrans with v1;trivial.
rewrite <- Hva11.
assert(StateLib.getNbLevel = Some (CLevel (nbLevel - 1))).
apply getNbLevelEqOption.
rewrite  H in *.
inversion H2;trivial.
apply checkVAddrsEqualityWOOffsetPermut.
clear H3 Hva11 Hva22 Hx.
revert dependent va1.
revert dependent va2.
revert H1 H2.
revert phy1 phy2 p nbL.
clear v1 v2.

induction getAllVAddrWithOffset0.
intuition.
intros.
destruct Hva2; destruct Hva1.
subst.
(* rewrite H2 in H4. *)
contradict Hvax.
rewrite  Bool.not_false_iff_true.
apply checkVAddrsEqualityWOOffsetEqTrue.
subst.
simpl in *.
rewrite Hmap2 in H1.
apply NoDup_cons_iff in H1.
destruct H1.
assert(In phy1 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists va1; split; trivial.
unfold not; intros.
subst.
now contradict H3.
subst.
simpl in *.
rewrite Hmap1 in H1.
apply NoDup_cons_iff in H1.
destruct H1.
assert(In phy2 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists va2; split; trivial.
unfold not; intros.
subst.
now contradict H0.
subst.
apply IHl with  p nbL va2 va1; trivial.
simpl in H1.
destruct(getMappedPage p s a ).
apply NoDup_cons_iff in H1.
intuition.
assumption.
trivial.
Qed.

Lemma eqMappedPagesEqVaddrs phy1 v1 v2 p s:
getMappedPage p s v1 = SomePage phy1 ->
 In v1 getAllVAddrWithOffset0 ->
 getMappedPage p s v2 = SomePage phy1->
In v2 getAllVAddrWithOffset0 ->
NoDup (filterOption (map (getMappedPage p s) getAllVAddrWithOffset0)) ->
v1 = v2.
Proof.
revert phy1  v1 v2.
induction getAllVAddrWithOffset0.
intuition.
intros.
destruct H0; destruct H2.
+
subst.
reflexivity.
+ subst.
(* rewrite H2 in H4.
now contradict H4.
subst.
 *)simpl in *.
rewrite H in H3.
apply NoDup_cons_iff in H3.
destruct H3.
assert(In phy1 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists v2; split; trivial.
now contradict H0.
+
subst.
simpl in *.
rewrite H1 in H3.
apply NoDup_cons_iff in H3.
destruct H3.
assert(In phy1 (filterOption (map (getMappedPage p s) l))).
apply filterOptionInIff.
apply in_map_iff.
exists v1; split; trivial.
now contradict H0.
+ simpl in *.
  case_eq (getMappedPage p s a ); intros; rewrite H4 in *.
  apply NoDup_cons_iff in H3.
  destruct H3.
  apply IHl with phy1; trivial.
  apply IHl with phy1; trivial.
    apply IHl with phy1; trivial.
Qed.


Lemma getAccessibleMappedPageEq pd va1 va2  nbL s :
StateLib.getNbLevel = Some nbL ->
StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 nbL = true ->
getAccessibleMappedPage pd s va1 = getAccessibleMappedPage pd s va2.
Proof.
intros HnbL Heqva.
unfold getAccessibleMappedPage.
rewrite HnbL.
assert(Heqind : getIndirection pd va1 nbL (nbLevel - 1) s =
getIndirection pd va2 nbL (nbLevel - 1) s).
apply getIndirectionEq;trivial.
apply getNbLevelLt;trivial.
rewrite Heqind.
destruct (getIndirection pd va2 nbL (nbLevel - 1) s);trivial.
assert(Heqidx : (StateLib.getIndexOfAddr va1 fstLevel) = (StateLib.getIndexOfAddr va2 fstLevel)).
apply checkVAddrsEqualityWOOffsetTrue'  with nbLevel nbL;trivial.
apply fstLevelLe.
apply getNbLevelLt;trivial.
rewrite Heqidx;trivial.
Qed.



Lemma physicalPageIsAccessible (currentPart : page) (ptPDChild : page)
phyPDChild pdChild idxPDChild accessiblePDChild  nbL presentPDChild
currentPD  s:
 (Nat.eqb defaultPage ptPDChild ) = false ->
accessiblePDChild = true ->
presentPDChild = true ->
StateLib.getIndexOfAddr pdChild fstLevel = idxPDChild ->
nextEntryIsPP currentPart PDidx currentPD s ->
Some nbL = StateLib.getNbLevel ->
(forall idx : index,
        StateLib.getIndexOfAddr pdChild fstLevel = idx ->
        isPE ptPDChild idx s /\ getTableAddrRoot ptPDChild PDidx currentPart pdChild s) ->
entryPresentFlag ptPDChild idxPDChild presentPDChild s ->
entryUserFlag ptPDChild idxPDChild accessiblePDChild s ->
isEntryPage ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) phyPDChild s ->
In currentPart (getPartitions multiplexer s) ->
In phyPDChild (getAccessibleMappedPages currentPart s).
Proof.
intros Hnotnull Haccess Hpresentflag Hidx Hroot Hnbl
Histblroot Hpresent Haccessentry Hentry Hcons.
unfold getAccessibleMappedPages .
assert( Hcurpd : StateLib.getPd currentPart (memory s) = Some currentPD).
{
unfold nextEntryIsPP in Hroot.
unfold StateLib.getPd.
destruct (StateLib.Index.succ PDidx); [| now contradict Hroot].
unfold StateLib.readPhysical.
destruct (lookup currentPart i (memory s) beqPage beqIndex) ; try now contradict Hroot.
destruct v ; try now contradict Hroot. subst; trivial. }
rewrite Hcurpd.
unfold getAccessibleMappedPagesAux.
apply filterOptionInIff.
unfold getAccessibleMappedPagesOption.
apply in_map_iff.
assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel pdChild va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1 & Hva11).
exists va1.
split; [| trivial].
assert(Hnewgoal : getAccessibleMappedPage currentPD s pdChild = SomePage phyPDChild).
{ unfold getAccessibleMappedPage.
rewrite <- Hnbl.
assert (Hind : getIndirection currentPD pdChild nbL   (nbLevel - 1) s = Some ptPDChild).
{ simpl.
  apply getIndirectionStopLevelGT2 with (nbL+1); auto.
  lia.
  unfold StateLib.getNbLevel in Hnbl.
  assert(0<nbLevel) by apply nbLevelNotZero.
  case_eq (gt_dec nbLevel 0); intros.
  rewrite H0 in Hnbl.
  inversion Hnbl.
  simpl. lia.
  now contradict H0.
  apply Histblroot in Hidx.
  destruct Hidx as (Hpe & Hgettbl).
  unfold getTableAddrRoot in Hgettbl.
  destruct Hgettbl as (_ &Hind).
  apply Hind in Hroot.
  clear Hind.
  destruct Hroot as (nbl & HnbL & stop & Hstop & Hind).
  subst. rewrite <- Hnbl in HnbL.
  inversion HnbL. subst. assumption. }
rewrite Hind.
assert(Hpresflag :  StateLib.readPresent ptPDChild
(StateLib.getIndexOfAddr pdChild fstLevel) (memory s) = Some true).
{ subst. unfold StateLib.readPresent.
  unfold  entryPresentFlag in Hpresent.
  destruct (lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) beqPage beqIndex )
  ;[ | now contradict Hpresent].
  destruct v; try now contradict Hpresent.
  f_equal. subst.
  symmetry.
  assumption. }
rewrite Hpresflag.
assert(Haccessflag :  StateLib.readAccessible ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) = Some true).
{ subst. unfold StateLib.readAccessible.
  unfold  entryUserFlag in Haccessentry.
  destruct (lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) beqPage beqIndex )
  ;[ | now contradict Haccessentry].
  destruct v; try now contradict Haccessentry.
  f_equal. subst.
  symmetry.
  assumption. }
rewrite Haccessflag.
subst.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
subst.
destruct(lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) beqPage beqIndex);
[| now contradict Hentry].
destruct v; try now contradict Hentry.
rewrite Hnotnull.
f_equal. assumption. }
rewrite <- Hnewgoal.
apply getAccessibleMappedPageEq with (CLevel (nbLevel - 1));trivial.
apply getNbLevelEqOption.
rewrite <- Hva11.
apply checkVAddrsEqualityWOOffsetPermut.
Qed.

Lemma getIndirectionFstStep s root va (level1 : level) stop table :
level1 > 0 -> stop > 0 -> root <> defaultPage ->  table <> defaultPage ->
getIndirection root va level1 stop s = Some table ->
exists pred page1,page1 <> defaultPage /\ Some pred = StateLib.Level.pred level1 /\
  StateLib.readPhyEntry root (StateLib.getIndexOfAddr va level1) (memory s) = Some page1 /\
 getIndirection page1 va pred (stop -1) s = Some table.
Proof.
intros Hl Hstop Hroot Hnull Hind .
destruct stop.
now contradict Hstop.
simpl in *.
case_eq (StateLib.Level.eqb level1 fstLevel).
intros Hfst.
rewrite Hfst in Hind.
apply beq_nat_true in Hfst. unfold fstLevel in Hfst.
unfold CLevel in Hfst.
case_eq (lt_dec 0 nbLevel).
intros. rewrite H in Hfst.
simpl in Hfst.
lia.
intros.
assert (0 < nbLevel) by apply nbLevelNotZero.
now contradict H0.
intros Hfst.
rewrite Hfst in Hind.
case_eq(StateLib.readPhyEntry root (StateLib.getIndexOfAddr va level1) (memory s)).
intros p Hread.
rewrite Hread in Hind.
case_eq(Nat.eqb defaultPage p);intros Hnullp;
rewrite Hnullp in Hind.
inversion Hind. subst. now contradict Hnull.
destruct (StateLib.Level.pred level1 ).
exists l.
exists p.
repeat split; trivial.
apply beq_nat_false in Hnullp.
unfold not.
intros.
contradict Hnullp.
subst. trivial.
simpl.
rewrite (NPeano.Nat.sub_0_r).
assumption.
inversion Hind.
intros. rewrite H in Hind.
inversion Hind.
Qed.

Lemma readPhyEntryInGetTablePages s root:
forall n : nat,
n <= tableSize ->
forall (idx : nat) (page1 : page),
idx < n ->
page1 <> defaultPage ->
StateLib.readPhyEntry root (CIndex idx) (memory s) = Some page1 ->
In page1 (getTablePages root n s).
Proof.
unfold StateLib.readPhyEntry in *. intros.
case_eq (lookup root (CIndex idx) (memory s) beqPage beqIndex);
[ intros v Hv| intros Hv] ; rewrite Hv in  H2; [ | now contradict H2 ].
destruct v; inversion H2.
subst. clear H2.
induction n.
 + intros.  now contradict H0.
 + destruct (PeanoNat.Nat.eq_dec n idx) as [ Heq | Hneq ].
    - simpl. subst.
      rewrite Hv.
      destruct defaultPage.
      destruct p. cbn in *. destruct pa.
      simpl in *. subst.
      case_eq (Nat.eqb p p0).
      * intros. apply beq_nat_true in H2.
        simpl in *.
        contradict H1.
        subst.
        assert (Hp = Hp0) by apply proof_irrelevance. subst. reflexivity.
      * intros. apply in_app_iff. right.  simpl. left. reflexivity.
    - assert (idx < n). lia.
      assert (n <= tableSize). lia.
      simpl.
      case_eq (lookup root (CIndex n) (memory s) beqPage beqIndex);
      [intros v Hlookup | intros Hlookup]; [ | apply IHn; trivial].
      destruct v; try apply IHn ; trivial.
      case_eq (Nat.eqb (pa p0) defaultPage); intros Hnull;
      [  | apply in_app_iff; left ] ; apply IHn ; trivial.
Qed.

Lemma getIndirectionInGetIndirections1 (stop : nat) s:
(stop+1) <= nbLevel ->
forall (va : vaddr) (level1 : level) (table root : page) ,
getIndirection root va level1 stop s = Some table ->
table <> defaultPage ->
root <> defaultPage -> In table (getIndirectionsAux root s (stop+1)).
Proof.
induction stop.
simpl.
intros.
inversion H0;left;trivial.
intros.
simpl in *.
assert (root = table \/ root <> table) by apply pageDecOrNot.
destruct H3 ;subst.
+ left;trivial.
+ right.
case_eq(StateLib.Level.eqb level1 fstLevel);intros;rewrite H4 in *.
  * inversion H0;subst. now contradict H3.
  * rewrite in_flat_map.
    case_eq(StateLib.readPhyEntry root (StateLib.getIndexOfAddr va level1)
         (memory s));intros;
    rewrite H5 in *;try now contradict H0.
    case_eq(Nat.eqb defaultPage p);intros; rewrite H6 in *; try now contradict H0.
    inversion H0.
    subst. now contradict H1.
    case_eq (StateLib.Level.pred level1);intros;
    rewrite H7 in *;try now contradict H0.
    exists p.
    split.
    apply readPhyEntryInGetTablePages with (StateLib.getIndexOfAddr va level1);trivial.
     destruct (StateLib.getIndexOfAddr va level1 );trivial.
         apply beq_nat_false in H6.
    unfold not;intros;subst.
    now contradict H6.
    rewrite <- H5.
    f_equal.
    destruct (StateLib.getIndexOfAddr va level1).
    simpl.
    unfold CIndex.
    case_eq(lt_dec i tableSize );intros.
    simpl.
    f_equal.
    apply proof_irrelevance.
    lia.
    apply IHstop with va l. lia.
    trivial.
    trivial.
    apply beq_nat_false in H6.
    unfold not;intros;subst.
    now contradict H6.
Qed.






Lemma getIndirectionInGetIndirections (n : nat) s:
n > 0 ->
n <= nbLevel ->
forall (va : vaddr) (level1 : level) (table root : page) (stop : nat),
getIndirection root va level1 stop s = Some table ->
table <> defaultPage ->
level1 <= CLevel (n - 1) -> root <> defaultPage -> In table (getIndirectionsAux root s n).
Proof.
intros Hl Hi  va  level1  table root stop
Hind  Hnotnull Hlevel Hrnotnull .
destruct n. now contradict Hl.
revert Hind Hnotnull Hlevel Hl  Hrnotnull  (* Hlevel *).
revert va level1 table root stop .
induction (S n);  [ simpl; intros; now contradict Hl |].
intros. simpl.
destruct stop; [ simpl in *; left; inversion Hind; trivial| ].
assert (StateLib.Level.eqb level1 fstLevel = true \/ StateLib.Level.eqb level1 fstLevel = false).
{ unfold StateLib.Level.eqb.
  destruct level1.
  simpl. unfold fstLevel.
  unfold CLevel.
  case_eq(lt_dec 0 nbLevel); intros.
  simpl.
  destruct l. left.
  symmetry. apply beq_nat_refl.
  right.
  apply NPeano.Nat.eqb_neq. lia.
  assert (0 < nbLevel) by apply nbLevelNotZero.
  now contradict H0. }

destruct H; [subst;  left; simpl in Hind; rewrite H in Hind; inversion Hind; trivial| ].
right.
apply getIndirectionFstStep  in Hind; trivial;
  [ | apply levelEqBEqNatFalse0 in H; assumption | lia  ].
destruct Hind as (pred &page1 & Hpnotnull & Hpred & Hpage & Hind).
apply in_flat_map.
exists page1.
split.
+ apply readPhyEntryInGetTablePages with  (StateLib.getIndexOfAddr va level1); trivial.
  - destruct (StateLib.getIndexOfAddr va level1). simpl. assumption.
  - assert ((StateLib.getIndexOfAddr va level1) = (CIndex (StateLib.getIndexOfAddr va level1))).
    symmetry.
    apply indexEqId.
    rewrite <- H0. assumption.
+ assert (Hnbl : n0 <= nbLevel). lia.
  apply IHn0   with va pred (S stop - 1); trivial.
  - assert (StateLib.Level.eqb level1 fstLevel = false); trivial.
    apply levelPredMinus1 with level1 pred in H; [ | symmetry; assumption].
    subst.
    unfold CLevel.
    case_eq(lt_dec (level1 - 1) nbLevel); intros ll Hll; [ | destruct level1; simpl in *;
    assert (l< nbLevel) by lia; contradict Hll; lia].
    case_eq (lt_dec (n0 - 1) nbLevel); intros ll' Hll'; [ | lia].
    simpl.
    destruct level1.
    simpl in *.
    unfold CLevel in Hlevel.
    case_eq (lt_dec (n0 -0) nbLevel); intros l' Hl'; [ rewrite Hl' in *;simpl in *|]; lia.
  - apply levelEqBEqNatFalse0 in H.
    destruct n0; [ | lia].
    simpl in Hlevel.
    unfold CLevel in Hlevel.
    assert (0 < nbLevel) as Hll by apply nbLevelNotZero.
    case_eq (lt_dec 0 nbLevel); intros l' Hl';[     rewrite Hl' in *; simpl in *|]; lia.
Qed.
*)


(*
Lemma nbPageLL fstLL s:
NoDup(getLLPages fstLL s (nbPage + 1))  ->
length (getLLPages fstLL s (nbPage + 1)) <(nbPage + 1).
Proof.
intros.
rewrite NPeano.Nat.add_1_r.
apply le_lt_n_Sm.
apply lengthNoDupPartitions.
replace (S nbPage) with (nbPage + 1) by lia.
trivial.
Qed.


Lemma inGetLLPages   s:
forall fstLL LLChildphy lastLLTable,
NoDup(getLLPages fstLL s (nbPage + 1)) ->
In LLChildphy (getLLPages fstLL s (nbPage + 1)) ->
In lastLLTable (getLLPages LLChildphy s (nbPage + 1)) ->
In lastLLTable (getLLPages fstLL s (nbPage + 1)).
Proof.
intros fstLL LLChildphy lastLLTable Hi0 Hi1 Hi2 .
assert(Hi: length (getLLPages fstLL s (nbPage + 1)) <(nbPage + 1)) by (
apply nbPageLL;trivial).
revert dependent LLChildphy.
revert dependent lastLLTable .
revert dependent fstLL.
induction (nbPage+1); simpl.
+ intros. now contradict Hi.
+ intros.
  simpl in *.
  case_eq(StateLib.getMaxIndex);[intros i Hmaxidx|intros Hmaxidx];rewrite Hmaxidx in *; simpl in *;trivial.
  case_eq(StateLib.readPhysical fstLL i (memory s));[intros sndLL HLL|intros HLL];rewrite HLL in *.
  - case_eq (StateLib.readPhysical LLChildphy i (memory s));
  [intros nextLLChildphy HLLChildphy|intros HLLChildphy];rewrite HLLChildphy in *.
  * case_eq(Nat.eqb nextLLChildphy defaultPage);intros Hnotdef;rewrite Hnotdef in *;  trivial;simpl in *; destruct Hi2 as [Hi2 | Hi2];subst;trivial;try
    now contradict Hi2.
   case_eq(Nat.eqb sndLL defaultPage);intros Hnotdef1; rewrite Hnotdef1 in *;trivial;simpl in *.
   -- destruct Hi1 as [Hi1 | Hi1];subst.
   ++
   rewrite  HLLChildphy in HLL.
   inversion HLL;subst.
   contradict Hnotdef.
   rewrite Bool.not_false_iff_true;trivial.
   ++
   now contradict Hi1.
   -- destruct Hi1 as [Hi1 |Hi1];subst.
   **
   rewrite  HLLChildphy in HLL.
   inversion HLL;subst.
   right. trivial.
   **
   right.
   apply IHn with nextLLChildphy;trivial.
   apply NoDup_cons_iff in Hi0.
   intuition.
   lia.
   apply IHn with LLChildphy;trivial.
   apply NoDup_cons_iff in Hi0.
   intuition.

      lia.
   destruct n;simpl in *.
   now contradict Hi2.

    rewrite Hmaxidx in *.
   rewrite HLLChildphy in *.
   rewrite Hnotdef.
   simpl.
   clear IHn.
   case_eq(StateLib.readPhysical nextLLChildphy i (memory s) );[intros x Hi3 |intros Hi3];
   rewrite Hi3 in *.
   ***
   simpl in *.
   case_eq(StateLib.readPhysical sndLL i (memory s));[intros p Htrd | intros Htrd];rewrite Htrd in *.
   +++
   case_eq(Nat.eqb p defaultPage);intros Hi4;rewrite Hi4 in *.
   ---
   simpl in *.
   destruct Hi1;subst;try now contradict H.
   rewrite Htrd in HLLChildphy.
   inversion HLLChildphy.
   subst.
   contradict Hnotdef.
   rewrite Bool.not_false_iff_true;trivial.
   ---
   simpl in *.
   destruct Hi1;subst;try now contradict Hi1.
   ++++
     rewrite Htrd in HLLChildphy.
   inversion HLLChildphy.
   subst.
   right.
   destruct n;simpl in *.
   lia.
   rewrite Hmaxidx in *.
    rewrite Hi3.
    simpl.
    case_eq(Nat.eqb x defaultPage);intros Hx;rewrite Hx in *;
    simpl;left;trivial.
    ++++
    right.
   destruct n;simpl in *.
   lia.
   rewrite Hmaxidx in *.
    rewrite Hi3.
    simpl.
     case_eq(Nat.eqb x defaultPage);intros Hx;rewrite Hx in *;
    simpl;left;trivial.
    +++
    simpl in *.
   destruct Hi1;subst;try now contradict H.
   rewrite Htrd in HLLChildphy.
   now contradict HLLChildphy.
   ***
   simpl in *.
   destruct Hi2 as [Hi2 | Hi2];subst;trivial;try now contradict Hi2.
   case_eq(StateLib.readPhysical sndLL i (memory s));[intros p Htrd | intros Htrd];rewrite Htrd in *.
   +++
   case_eq(Nat.eqb p defaultPage);intros Hi4;rewrite Hi4 in *.
   ---
   simpl in *.
   destruct Hi1;subst;try now contradict H.
   rewrite Htrd in HLLChildphy.
   inversion HLLChildphy.
   subst.
   contradict Hnotdef.
   rewrite Bool.not_false_iff_true;trivial.
   ---
   simpl in *.
   destruct Hi1;subst;try now contradict Hi1.
   ++++
     rewrite Htrd in HLLChildphy.
   inversion HLLChildphy.
   subst.
   right.
   destruct n;simpl in *.
   lia.
   rewrite Hmaxidx in *.
    rewrite Hi3.
    simpl.
    left;trivial.
    ++++
    right.
   destruct n;simpl in *.
   lia.
   rewrite Hmaxidx in *.
    rewrite Hi3.
    simpl.
    left;trivial.
    +++
    simpl in *.
   destruct Hi1;subst;try now contradict H.
   rewrite Htrd in HLLChildphy.
   now contradict HLLChildphy.

   * simpl in *.
    intuition;subst.
    destruct(Nat.eqb sndLL defaultPage);trivial;simpl in *.
  -
  case_eq (StateLib.readPhysical LLChildphy i (memory s));
  [intros nextLLChildphy HLLChildphy|intros HLLChildphy];rewrite HLLChildphy in *.
  *
  destruct(Nat.eqb nextLLChildphy defaultPage);trivial;simpl in *; destruct Hi1;subst;trivial;try
  now contradict Hi0.
   destruct Hi2;[left;trivial|].
   rewrite  HLLChildphy in HLL.
   now contradict HLL.
  *
  simpl in *.
  intuition;subst;trivial.
  left;trivial.
Qed.

Lemma verticalSharingRec n s :
NoDup (getPartitions multiplexer s) ->
noCycleInPartitionTree s ->
isParent s ->
verticalSharing s ->
forall currentPart,
In currentPart (getPartitions multiplexer s) ->
forall   partition, currentPart<> partition ->
In partition (getPartitionAux currentPart s (n + 1)) ->
incl (getMappedPages partition s) (getMappedPages currentPart s).
Proof.
intros Hnodup Hnocycle Hisparent Hvs.
unfold incl.
induction n ; simpl ; intuition.

contradict H2.
clear.
induction (getChildren currentPart s); simpl; intuition.
rewrite in_flat_map in H2.
destruct H2 as (x & Hx1 & Hx2).
assert(Hor : partition = x \/ partition <> x) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].
+ subst x.
unfold verticalSharing in *.
unfold incl in *.
apply Hvs with partition;trivial.
unfold getUsedPages.
simpl. right.
apply in_app_iff. right;trivial.
+
apply IHn with x; trivial.
-
unfold isParent in *.
unfold noCycleInPartitionTree in *.
unfold not in Hnocycle.
apply Hnocycle.
apply childrenPartitionInPartitionList with currentPart; trivial.
intuition.
unfold getAncestors.

assert(Hparent : StateLib.getParent x (memory s)  = Some currentPart).
apply Hisparent;trivial.
destruct nbPage; simpl; rewrite Hparent; simpl;left;trivial.
- destruct n;simpl in *.
  * intuition.
    contradict H2.
    clear.
    induction (getChildren x s); simpl; intuition.
  *  destruct  Hx2; subst.
     now contradict Hor.
      right.
      rewrite in_flat_map.
      exists x;simpl;split;trivial.
      destruct n;simpl; left;trivial.
-
apply IHn with partition; trivial.
apply childrenPartitionInPartitionList with currentPart; trivial.
intuition.
Qed.



   Lemma verticalSharingRec2 :
forall (n : nat) (s : state), NoDup (getPartitions multiplexer s) ->  noCycleInPartitionTree s ->
isParent s ->
verticalSharing s ->
forall currentPart : page,
In currentPart (getPartitions multiplexer s) ->
forall partition : page,
currentPart <> partition ->
In partition (getPartitionAux currentPart s (n + 1)) ->
incl (getUsedPages partition s) (getMappedPages currentPart s).
Proof.
intros n s Hnodup Hnocycle Hisparent Hvs.
unfold incl.
induction n ; simpl.
+ intros.
 clear H2.  intuition.

contradict H2.
clear.
induction (getChildren currentPart s); simpl; intuition.
+ intros.
destruct H1 . intuition.
assert (In a (getUsedPages partition s) ).
unfold getUsedPages. unfold getConfigPages.
simpl. trivial. clear H2.
rewrite in_flat_map in H1.
destruct H1 as (x & Hx1 & Hx2).
assert(Hor : partition = x \/ partition <> x) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].
* subst x.
unfold verticalSharing in *.
unfold incl in *.
apply Hvs with partition;trivial.
*
apply IHn with x; trivial.
-
unfold isParent in *.
unfold noCycleInPartitionTree in *.
apply Hnocycle.
apply childrenPartitionInPartitionList with currentPart; trivial.
unfold getAncestors.

assert(Hparent : StateLib.getParent x (memory s)  = Some currentPart).
apply Hisparent;trivial.
destruct nbPage; simpl; rewrite Hparent; simpl;left;trivial.
- destruct n;simpl in *.
  ** destruct Hx2. subst. now contradict Hor.    contradict H1.
    induction (getChildren x s); simpl; intuition.
  **  destruct  Hx2; subst.
     now contradict Hor.
      right.
      rewrite in_flat_map.
      exists x;simpl;split;trivial.
      destruct n;simpl; left;trivial.
- unfold getUsedPages. rewrite in_app_iff.
right.
apply IHn with partition; trivial.
apply childrenPartitionInPartitionList with currentPart; trivial.
intuition.
Qed.
(*
 assert( incl (getMappedPages currentPart s) (getMappedPages child1 s)). *)
           Lemma toApplyVerticalSharingRec s:
           consistency s ->
           verticalSharing s ->
           forall currentPart child1 closestAnc,
           currentPart <> child1 ->
            In child1 (getChildren closestAnc s) ->
            In closestAnc (getPartitions multiplexer s) ->
             In currentPart (getPartitionAux child1 s nbPage) ->
            incl (getMappedPages currentPart s) (getMappedPages child1 s).
            Proof. intros Hcons Hvs. intros.
            unfold consistency in *.
           apply verticalSharingRec with (nbPage-1); intuition.
           apply childrenPartitionInPartitionList with closestAnc; trivial.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
           Qed.

  Lemma verticalSharing2 child parent s :
  incl (getUsedPages child s) (getMappedPages parent s) ->
  incl (getMappedPages child s) (getMappedPages parent s).
  Proof.
  unfold incl.
  intros.
  apply H.
  unfold getUsedPages.
  apply in_app_iff.
  right;trivial.
  Qed.

Lemma getPartitionAuxMinus1 s :
NoDup (getPartitions multiplexer s) ->
isParent s ->
forall n child parent ancestor,
In ancestor (getPartitions multiplexer s) ->
StateLib.getParent child (memory s) = Some parent ->
In child (flat_map (fun p : page => getPartitionAux p s n) (getChildren ancestor s)) ->
In parent (getPartitionAux ancestor s n).
Proof.
intros Hnodup Hparent .
induction n. simpl in *. intuition.
contradict H1.
clear. induction  (getChildren ancestor s);simpl in *;intuition.
simpl.
intros.
rewrite in_flat_map in H1.
destruct H1 as (x & Hx & Hxx).
simpl in Hxx.
assert(Hor : parent = ancestor \/ parent <> ancestor) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].
left;intuition.
right.
destruct Hxx as [Hx1 | Hx1].
+ subst.
rewrite in_flat_map.
assert(StateLib.getParent child (memory s) = Some ancestor).
unfold isParent in *.
apply Hparent;trivial.
rewrite H1 in H0.
inversion H0; subst. now contradict Hor.
+ rewrite  in_flat_map.
exists x;split;trivial.
simpl.
apply IHn with child;trivial.
apply childrenPartitionInPartitionList with ancestor;trivial.

Qed.



Lemma isAncestorTrans2 ancestor descParent currentPart s:
noDupPartitionTree s ->
multiplexerWithoutParent s ->
isParent s ->
In currentPart (getPartitions multiplexer s)  ->
StateLib.getParent descParent (memory s) = Some ancestor ->
In descParent (getAncestors currentPart s) ->
In ancestor (getAncestors currentPart s).
Proof.
intros Hnoduptree Hmultnone Hisparent.
revert descParent ancestor currentPart.
unfold getPartitions.
unfold getAncestors.
(* assert(Hge : nbPage >= nbPage) by lia.
revert Hge.
generalize nbPage at 1 3 4 . *)
induction nbPage ;intros descParent ancestor currentPart Hmult;intros;simpl in *.
destruct Hmult.
subst.
assert( StateLib.getParent multiplexer (memory s)  = None) by intuition.
rewrite H1 in H0. now contradict H0.
contradict H1.
clear.
induction   (getChildren multiplexer s);simpl in *; intuition.
destruct Hmult as [Hmult | Hmult].
+ subst. assert( StateLib.getParent multiplexer (memory s)  = None) by intuition.
rewrite H1 in *. now contradict H0.
+
case_eq(StateLib.getParent currentPart (memory s) );
[intros parent Hparent | intros Hparent ].
rewrite Hparent in H0.
simpl in *.
assert(Hi :parent = ancestor \/ parent <> ancestor ).
{ destruct parent;simpl in *;subst;destruct ancestor;simpl in *;subst.
  assert (Heq :p=p0 \/ p<> p0) by lia.
    destruct Heq as [Heq|Heq].
    subst.
    left;f_equal;apply proof_irrelevance.
    right. unfold not;intros.
    inversion H1.
    subst.
    now contradict Heq. }
destruct Hi as [Hi | Hi].
left;trivial.
destruct H0;subst.
right.
destruct n.
simpl.
rewrite H.
simpl;left;trivial.
simpl.
rewrite H.
simpl;left;trivial.
right.
apply IHn with descParent;trivial.
apply getPartitionAuxMinus1 with currentPart;trivial.
unfold getPartitions. destruct nbPage;simpl;left;trivial.
rewrite Hparent in H0.
intuition.
Qed.

Lemma getAncestorsProp1 s :
partitionDescriptorEntry s ->
parentInPartitionList s ->
forall ancestor parent child ,
In parent (getPartitions multiplexer s) ->
In ancestor (getAncestors child s) ->
parent <> ancestor ->
StateLib.getParent child (memory s) = Some parent ->
In ancestor (getAncestors parent s).
Proof.
intros Hpde Hparentpart.
unfold getAncestors.
induction (nbPage + 1); intros ancestor parent child  Hin Hinanc Hnoteq Hparent;
simpl in *; trivial.
rewrite Hparent in Hinanc.
simpl in *.
destruct Hinanc.
intuition.
case_eq (StateLib.getParent parent (memory s) ); intros.
simpl in *.
assert( Hor : p=ancestor \/ p<> ancestor) by apply pageDecOrNot.
destruct Hor.
left;trivial.
right.
apply IHn with parent; trivial.
clear IHn.
unfold parentInPartitionList in *.
apply Hparentpart with parent; trivial.
apply nextEntryIsPPgetParent; trivial.
unfold partitionDescriptorEntry in *.
assert((exists entry : page, nextEntryIsPP parent PPRidx entry s /\ entry <> defaultPage)).
apply Hpde;trivial.
do 4 right; left;trivial.
destruct H1 as (parennt & H1 & H2).
rewrite nextEntryIsPPgetParent in *.
rewrite H1 in *.
now contradict H0.
Qed.

Lemma isAncestorTrans3 s :
noDupPartitionTree s ->
multiplexerWithoutParent s ->
noCycleInPartitionTree s ->
isParent s ->
isChild s ->
parentInPartitionList s ->
forall ancestor child x,
In x (getPartitions multiplexer s) ->
In child (getPartitions multiplexer s) ->
In ancestor (getPartitions multiplexer s) ->
In ancestor (getAncestors child s) ->
In x (getChildren child s) ->

In ancestor (getAncestors x s).
Proof.
intros Ha1 Ha2 Hnocycle Hisparent Hischild Hparentintree.
unfold getPartitions at 1, getAncestors.
induction (nbPage+1);simpl; intros;trivial.
destruct H;subst.
assert(Hfalse :  StateLib.getParent multiplexer (memory s) = Some child).
unfold isParent in *.
apply Hisparent;trivial.
assert(Htrue :  StateLib.getParent multiplexer (memory s) = None) by intuition.
rewrite Htrue in Hfalse. now contradict Hfalse.
assert(Hparentx : StateLib.getParent x (memory s)  = Some child).
unfold isParent in *.
apply Hisparent;trivial.
rewrite Hparentx;trivial.
case_eq(StateLib.getParent child (memory s));
[intros parent Hparentchild | intros Hparentchild];rewrite Hparentchild in *;
try now contradict H2.
simpl in *.
destruct H2;subst.
+ right.
  destruct n; simpl in *.
  contradict H.
  induction ((getChildren multiplexer s));simpl in *;intuition.
  rewrite Hparentchild.
  simpl ;trivial;left;trivial.
+

simpl;right.
apply IHn with parent;trivial.
apply getPartitionAuxMinus1 with x;trivial.
unfold getPartitions.
destruct nbPage;simpl;left;trivial.
unfold parentInPartitionList in *.
apply Hparentintree with child;trivial.
apply nextEntryIsPPgetParent;trivial.
unfold isChild in *.
apply Hischild;trivial.
Qed. (* isAncestorTrans3 : multiplexer without parent *)


Lemma noCycleInPartitionTree2 s :
noDupPartitionTree s ->
multiplexerWithoutParent s ->
isChild s ->
parentInPartitionList s ->
noCycleInPartitionTree s ->
isParent s ->
forall n parent child,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
~ In parent (getPartitionAux child s n).
Proof.
(* unfold noCycleInPartitionTree. *)
intros Hnoduptree Hmultnone Ha Ha2 Hnocycle Hisparent.
intros.
assert(In parent (getAncestors child s) ).
{ unfold getAncestors.
  assert(Htrue: StateLib.getParent child (memory s) =Some parent).
  unfold isParent in *.
  apply Hisparent;trivial.
  destruct nbPage;simpl; rewrite Htrue;simpl;left;trivial. }
assert(Hchildintree : In child (getPartitions multiplexer s)).
apply childrenPartitionInPartitionList with parent;trivial.
clear H0.
revert dependent parent.
revert dependent child.
induction n. simpl. intuition.
simpl.
intros child Hchild parent Hparent  Hances.
apply Classical_Prop.and_not_or.
split.
+ unfold not;intros. subst.
assert(Hfaalse : parent <> parent).
unfold noCycleInPartitionTree in *.
apply Hnocycle;trivial.
now contradict Hfaalse.
+ unfold not;intros Hcont.
rewrite in_flat_map in Hcont.
destruct Hcont as (x & Hx & Hx1).
contradict Hx1.
assert(Htrue : In x (getPartitions multiplexer s)).
apply childrenPartitionInPartitionList with child;trivial.
 apply IHn;trivial.
 apply isAncestorTrans3 with child;trivial.
Qed.

Lemma accessiblePageIsNotPartitionDescriptor
phyPDChild pdChild idxPDChild accessiblePDChild currentPart nbL presentPDChild
currentPD (ptPDChild : page) s:
partitionsIsolation s ->
kernelDataIsolation s ->
 (Nat.eqb defaultPage ptPDChild ) = false ->
accessiblePDChild = true ->
presentPDChild = true ->
StateLib.getIndexOfAddr pdChild fstLevel = idxPDChild ->
nextEntryIsPP currentPart PDidx currentPD s ->
Some nbL = StateLib.getNbLevel ->
(forall idx : index,
        StateLib.getIndexOfAddr pdChild fstLevel = idx ->
        isPE ptPDChild idx s /\ getTableAddrRoot ptPDChild PDidx currentPart pdChild s) ->
entryPresentFlag ptPDChild idxPDChild presentPDChild s ->
entryUserFlag ptPDChild idxPDChild accessiblePDChild s ->
isEntryPage ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) phyPDChild s ->
In currentPart (getPartitions multiplexer s) ->
~ In phyPDChild (getPartitionAux multiplexer s (nbPage + 1)).
Proof.
intros Hiso Hanc Hnotnull Haccess Hpresentflag Hidx Hroot Hnbl
Histblroot Hpresent Haccessentry Hentry Hcons.
assert (In phyPDChild (getAccessibleMappedPages currentPart s)) by
  now apply physicalPageIsAccessible with ptPDChild pdChild idxPDChild accessiblePDChild
          nbL presentPDChild currentPD.
  unfold kernelDataIsolation in Hanc.
unfold disjoint in Hanc.
unfold getConfigPages in Hanc.
unfold getConfigPagesAux in Hanc.
simpl in Hanc.
generalize (Hanc currentPart multiplexer) ;  intro Hanc1.
assert( Hp2 : In multiplexer (getPartitions multiplexer s)).
{ unfold getPartitions. destruct nbPage;
  simpl; left; trivial. }
assert( Hpcur : In currentPart (getPartitions multiplexer s) ) by trivial.
apply Hanc1  with phyPDChild in Hcons; trivial.
apply Classical_Prop.not_or_and in Hcons.
destruct Hcons as (Hp1 & _).
clear Hanc1 Hp2.
assert(Hanc' : forall partition2  : page,
In partition2 (getPartitions multiplexer s) ->
partition2 <> phyPDChild).
{ intros.
  apply Hanc with currentPart partition2 phyPDChild in H0;trivial.
  apply Classical_Prop.not_or_and in H0.
  intuition. }
clear Hanc .
unfold not in *.
intros.
apply Hanc' with phyPDChild; trivial.
Qed.

Lemma getPdNextEntryIsPPEq partition pd1 pd2 s :
nextEntryIsPP partition PDidx pd1 s ->
StateLib.getPd partition (memory s) = Some pd2 ->
pd1 = pd2.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getPd in *.
destruct(StateLib.Index.succ PDidx); [| now contradict H0].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H0].
destruct v ; try now contradict H0.
inversion H0; subst; trivial.
Qed.

Lemma getSh1NextEntryIsPPEq partition pd1 pd2 s :
nextEntryIsPP partition sh1idx pd1 s ->
StateLib.getFstShadow partition (memory s) = Some pd2 ->
pd1 = pd2.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getFstShadow in *.
destruct(StateLib.Index.succ sh1idx); [| now contradict H0].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H0].
destruct v ; try now contradict H0.
inversion H0; subst; trivial.
Qed.

Lemma getSh2NextEntryIsPPEq partition pd1 pd2 s :
nextEntryIsPP partition sh2idx pd1 s ->
StateLib.getSndShadow partition (memory s) = Some pd2 ->
pd1 = pd2.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getSndShadow in *.
destruct(StateLib.Index.succ sh2idx); [| now contradict H0].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H0].
destruct v ; try now contradict H0.
inversion H0; subst; trivial.
Qed.

Lemma getListNextEntryIsPPEq partition pd1 pd2 s :
nextEntryIsPP partition sh3idx pd1 s ->
StateLib.getConfigTablesLinkedList partition (memory s) = Some pd2 ->
pd1 = pd2.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getConfigTablesLinkedList in *.
destruct(StateLib.Index.succ sh3idx); [| now contradict H0].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H0].
destruct v ; try now contradict H0.
inversion H0; subst; trivial.
Qed.

Lemma getParentNextEntryIsPPEq partition pd1 pd2 s :
nextEntryIsPP partition PPRidx pd1 s ->
StateLib.getParent partition (memory s) = Some pd2 ->
pd1 = pd2.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getParent in *.
destruct(StateLib.Index.succ PPRidx); [| now contradict H0].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H0].
destruct v ; try now contradict H0.
inversion H0; subst; trivial.
Qed.



Lemma nextEntryIsPPgetPd partition pd s :
nextEntryIsPP partition PDidx pd s <->
StateLib.getPd partition (memory s) = Some pd.
Proof.
split.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getPd in *.
destruct(StateLib.Index.succ PDidx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getPd in *.
destruct(StateLib.Index.succ PDidx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
Qed.

Lemma nextEntryIsPPgetFstShadow partition sh1 s :
nextEntryIsPP partition sh1idx sh1 s <->
StateLib.getFstShadow partition (memory s) = Some sh1.
Proof.
split.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getFstShadow in *.
destruct(StateLib.Index.succ sh1idx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getFstShadow in *.
destruct(StateLib.Index.succ sh1idx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
Qed.

Lemma nextEntryIsPPgetSndShadow partition sh2 s :
nextEntryIsPP partition sh2idx sh2 s <->
StateLib.getSndShadow partition (memory s) = Some sh2.
Proof.
split.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getSndShadow in *.
destruct(StateLib.Index.succ sh2idx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getSndShadow in *.
destruct(StateLib.Index.succ sh2idx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
Qed.

Lemma nextEntryIsPPgetConfigList partition list s :
nextEntryIsPP partition sh3idx list s ->
StateLib.getConfigTablesLinkedList partition (memory s) = Some list.
Proof.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getConfigTablesLinkedList in *.
destruct(StateLib.Index.succ sh3idx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
Qed.


Lemma accessibleMappedPagesInMappedPages partition s :
incl (getAccessibleMappedPages partition s) (getMappedPages partition s).
Proof.
unfold incl.
intros apage Haccesible.
unfold getMappedPages.
unfold getAccessibleMappedPages in *.
destruct (StateLib.getPd partition (memory s)); trivial.
unfold getMappedPagesAux.
unfold getAccessibleMappedPagesAux in *.
apply filterOptionInIff.
apply filterOptionInIff in Haccesible.
 unfold getAccessibleMappedPagesOption in *.
unfold getMappedPagesOption.
apply in_map_iff.
apply in_map_iff in Haccesible.
destruct Haccesible as (va & Haccesible & Hvas).
exists va.
split; trivial.
unfold  getAccessibleMappedPage in *.
unfold getMappedPage.
destruct (StateLib.getNbLevel); trivial.
destruct ( getIndirection p va l (nbLevel - 1) s);trivial.
destruct (StateLib.readPresent p0
          (StateLib.getIndexOfAddr va fstLevel) (memory s));trivial.
destruct b; trivial.
destruct (Nat.eqb defaultPage p0); try now contradict Haccesible.
destruct (StateLib.readAccessible p0
(StateLib.getIndexOfAddr va fstLevel) (memory s));
[|now contradict Haccesible].
destruct b; trivial.
now contradict Haccesible.
destruct (Nat.eqb defaultPage p0);intros;trivial.
now contradict Haccesible.
Qed.


Lemma inGetIndirectionsAuxLt pd s stop table bound:
~ In table (getIndirectionsAux pd s bound) ->
stop <= bound - 1 ->
~ In table (getIndirectionsAux pd s  stop).
Proof.
revert stop pd.
induction bound.
simpl in *; auto.
intros.
destruct stop.
simpl. auto.
now contradict H0.
intros.
destruct stop.
simpl. auto.
simpl in *.
apply Classical_Prop.and_not_or .
apply Classical_Prop.not_or_and in H.
destruct H.
split; trivial.
auto.
simpl in *.

induction  (getTablePages pd tableSize s).
simpl. auto.
simpl in *.
rewrite in_app_iff in *.
apply Classical_Prop.and_not_or .
apply Classical_Prop.not_or_and in H1.
destruct H1.
split; trivial.
apply IHbound; trivial.
lia.
apply IHl; trivial.
Qed.


Lemma notConfigTableNotPdconfigTableLt partition pd table s stop :
stop < nbLevel - 1 ->
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getPd partition (memory s) = Some pd ->
~ In table (getIndirectionsAux pd s (S stop)).
Proof.
intros Hstop Hpde Hgetparts Hconfig Hpd .

unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
(* apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff in Hconfig.
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig.
unfold getIndirections in H.

apply inGetIndirectionsAuxLt with nbLevel; auto.
Qed.
Lemma inGetIndirectionsAuxInConfigPagesPD partition pd table s:
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
In table (getIndirectionsAux pd s nbLevel)->
StateLib.getPd partition (memory s) = Some pd ->
In table (getConfigPagesAux partition s).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
unfold getIndirections.
simpl .
(* apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff .
left;trivial.
Qed.

Lemma notConfigTableNotPdconfigTable partition pd table s :
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getPd partition (memory s) = Some pd ->
~ In table (getIndirectionsAux pd s nbLevel).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
(* apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff in Hconfig.
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig as (H0 & H).
unfold getIndirections in H0.
assumption.
Qed.

Lemma notConfigTableNotSh1configTableLt partition sh1 table s stop :
stop < nbLevel - 1 ->
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getFstShadow partition (memory s) = Some sh1 ->
~ In table (getIndirectionsAux sh1 s (S stop)).
Proof.
intros Hstop Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rewrite in_app_iff in Hconfig.
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig as (H & H0). (*

apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
unfold getIndirections in H0.
simpl in H1. (*
apply Classical_Prop.not_or_and in H1.
destruct H1.
rewrite in_app_iff in H2.
apply Classical_Prop.not_or_and in H2.
destruct H2. *)
unfold getIndirections in H0.
apply inGetIndirectionsAuxLt with nbLevel; auto.
Qed.

Lemma inGetIndirectionsAuxInConfigPagesSh1 partition pd table s:
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
In table (getIndirectionsAux pd s nbLevel)->
StateLib.getFstShadow partition (memory s) = Some pd ->
In table (getConfigPagesAux partition s).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd .
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rewrite in_app_iff .
right.
rewrite in_app_iff .
left;trivial.
Qed.
Lemma notConfigTableNotSh1configTable partition sh1 table s :
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getFstShadow partition (memory s) = Some sh1 ->
~ In table (getIndirectionsAux sh1 s nbLevel).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getSndShadow in *.
destruct (StateLib.Index.succ sh2idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rewrite in_app_iff in Hconfig.
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig.
simpl in H0. (*
apply Classical_Prop.not_or_and in H1.
destruct H1. *)
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
rewrite in_app_iff in H1.
apply Classical_Prop.not_or_and in H1.
destruct H1.
unfold getIndirections in H2.
assumption.
Qed.

Lemma notConfigTableNotSh2configTableLt partition sh2 table s stop :
stop < nbLevel - 1 ->
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getSndShadow partition (memory s) = Some sh2 ->
~ In table (getIndirectionsAux sh2 s (S stop)).
Proof.
intros Hstop Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rename Hconfig into H0. (*
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
unfold getIndirections in H0.
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
rewrite in_app_iff in H1.
simpl in H1.
apply Classical_Prop.not_or_and in H1.
destruct H1. (*
rewrite in_app_iff in H2.
apply Classical_Prop.not_or_and in H2.
destruct H2.
unfold getIndirections in H2.
simpl in H3.
apply Classical_Prop.not_or_and in H3.
destruct H3.
rewrite in_app_iff in H4.
apply Classical_Prop.not_or_and in H4.
destruct H4.
unfold getIndirections in H4.
simpl in H5.
apply Classical_Prop.not_or_and in H5.
destruct H5. *)
apply inGetIndirectionsAuxLt with nbLevel; auto.
Qed.

Lemma inGetIndirectionsAuxInConfigPagesSh2 partition pd table s:
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
In table (getIndirectionsAux pd s nbLevel)->
StateLib.getSndShadow partition (memory s) = Some pd ->
In table (getConfigPagesAux partition s).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rename Hconfig into H0. (*
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
do 2 (rewrite in_app_iff;
right).
rewrite in_app_iff.
left.
trivial.
Qed.

Lemma notConfigTableNotSh2configTable partition sh2 table s :
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getSndShadow partition (memory s) = Some sh2 ->
~ In table (getIndirectionsAux sh2 s nbLevel).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getPd in *.
destruct (StateLib.Index.succ PDidx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear Hrootidx Hisva  Hnotnull.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetpartssh2;auto.
destruct Hgetpartssh2 as (Hrootsh2idx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getFstShadow in *.
destruct (StateLib.Index.succ sh1idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i0 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
clear  Hisva  Hnotnull.
apply Hpde with partition sh3idx in Hgetpartslist; auto.
destruct Hgetpartslist as (Hrootlistidx & Hisva & Hroot  & Hpp & Hnotnull).
unfold nextEntryIsPP in *.
unfold StateLib.getConfigTablesLinkedList in *.
destruct (StateLib.Index.succ sh3idx); auto.
unfold  StateLib.readPhysical in *.
destruct (lookup partition i1 (memory s) beqPage beqIndex);auto.
destruct v; auto.
subst.
simpl in Hconfig.
rename Hconfig into H0. (*
apply Classical_Prop.not_or_and in Hconfig.
destruct Hconfig. *)
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
unfold getIndirections in H0.
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
rewrite in_app_iff in H1.
simpl in H1.
apply Classical_Prop.not_or_and in H1.
destruct H1.
assumption.
Qed.



Lemma notConfigTableNotListconfigTable partition sh3 table s :
partitionDescriptorEntry s ->
In partition (getPartitions multiplexer s) ->
~ In table (getConfigPagesAux partition s) ->
StateLib.getConfigTablesLinkedList partition (memory s) = Some sh3 ->
~ In table (getLLPages sh3 s (nbPage + 1)).
Proof.
intros Hpde Hgetparts Hconfig Hpd .
unfold getConfigPagesAux in *.
rewrite Hpd in Hconfig.
unfold partitionDescriptorEntry in *.
assert(Hgetpartssh2 :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition PDidx in Hgetparts;auto.
destruct Hgetparts as (Hrootidx & Hisva & Hroot  & Hpp & Hnotnull).
rewrite nextEntryIsPPgetPd in *.
rewrite Hpp in *.
clear Hrootidx Hisva  Hnotnull Hpp.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh1idx in Hgetpartslist;auto.
destruct Hgetpartslist as (Hrootidx & Hisva & sh1  & Hpp & Hnotnull).
rewrite nextEntryIsPPgetFstShadow in *.
rewrite Hpp in *.
clear Hrootidx Hisva  Hnotnull Hpp.
assert(Hgetpartslist :In partition (getPartitions multiplexer s)) ; trivial.
apply Hpde with partition sh2idx in Hgetpartslist;auto.
destruct Hgetpartslist as (Hrootidx & Hisva & sh2  & Hpp & Hnotnull).
rewrite nextEntryIsPPgetSndShadow in *.
rewrite Hpp in *.
simpl in Hconfig.
rename Hconfig into H0.
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
unfold getIndirections in H0.
rewrite in_app_iff in H0.
apply Classical_Prop.not_or_and in H0.
destruct H0.
rewrite in_app_iff in H1.
simpl in H1.
apply Classical_Prop.not_or_and in H1.
destruct H1.
assumption.
Qed.


Lemma pdSh1Sh2ListExistsNotNull  (s: state):
partitionDescriptorEntry s ->
forall partition, In partition (getPartitions multiplexer s) ->
(exists pd , StateLib.getPd partition (memory s) = Some pd /\ pd <> defaultPage) /\
(exists sh1, StateLib.getFstShadow partition (memory s) = Some sh1 /\ sh1 <> defaultPage) /\
(exists sh2, StateLib.getSndShadow partition (memory s) = Some sh2 /\ sh2 <> defaultPage) /\
(exists list, StateLib.getConfigTablesLinkedList partition (memory s) = Some list /\ list <> defaultPage).
Proof.
intros; unfold partitionDescriptorEntry in *.
repeat split.
+ apply H with partition PDidx in H0 .
  destruct H0 as (Hi & Hva & entry & Hentry & Hnotdef).
  exists entry.
  split; trivial.
  apply nextEntryIsPPgetPd; trivial.
  left. trivial.
+ apply H with partition sh1idx in H0 .
  destruct H0 as (Hi & Hva & entry & Hentry & Hnotdef).
  exists entry.
  split;trivial.
  apply nextEntryIsPPgetFstShadow; trivial.
  right;  left. trivial.
+ apply H with partition sh2idx in H0 .
  destruct H0 as (Hi & Hva & entry & Hentry & Hnotdef).
  exists entry.
  split; trivial.
  apply nextEntryIsPPgetSndShadow; trivial.
  right; right; left. trivial.
+ apply H with partition sh3idx in H0 .
  destruct H0 as (Hi & Hva & entry & Hentry & Hnotdef).
  exists entry.
  split;trivial.
  apply nextEntryIsPPgetConfigList ; trivial.
  right; right; right; left. trivial.
Qed.

Lemma isConfigTable descChild ptRefChild descParent s :
partitionDescriptorEntry s ->
In descParent (getPartitions multiplexer s) ->
(forall idx : index,
StateLib.getIndexOfAddr descChild fstLevel = idx ->
isPE ptRefChild idx s /\ getTableAddrRoot ptRefChild PDidx descParent descChild s) ->
(Nat.eqb defaultPage ptRefChild) = false ->
In ptRefChild (getConfigPages descParent s).
Proof.
intros Hpde Hpart Hget Hnotnull.
apply pdSh1Sh2ListExistsNotNull  with s descParent in Hpde.
destruct Hpde as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
unfold getConfigPages.
unfold getConfigPagesAux.
rewrite Hpd, Hsh1, Hsh2, Hsh3.
simpl.
do 1 right.
rewrite in_app_iff.
left.
unfold getIndirections.
destruct Hget with (StateLib.getIndexOfAddr descChild fstLevel) ;trivial.
clear Hget.
unfold getTableAddrRoot in *.
destruct H0 as(_ & H0).
rewrite <- nextEntryIsPPgetPd in *.
apply H0 in Hpd.
clear H0.
destruct Hpd as (nbL & HnbL & stop & Hstop & Hind).
apply getIndirectionInGetIndirections with descChild nbL stop;trivial.
assert(0<nbLevel) by apply nbLevelNotZero;trivial.
apply beq_nat_false in Hnotnull.
unfold not;intros.
subst.
now contradict Hnotnull.
apply getNbLevelLe in HnbL;trivial.
assumption.
Qed.

Lemma isConfigTableSh2WithVA descChild ptRefChild descParent s :
partitionDescriptorEntry s ->
In descParent (getPartitions multiplexer s) ->
(forall idx : index,
StateLib.getIndexOfAddr descChild fstLevel = idx ->
isVA ptRefChild idx s /\ getTableAddrRoot ptRefChild sh2idx descParent descChild s) ->
(Nat.eqb defaultPage ptRefChild) = false ->
In ptRefChild (getConfigPages descParent s).
Proof.
intros Hpde Hpart Hget Hnotnull.
apply pdSh1Sh2ListExistsNotNull  with s descParent in Hpde.
destruct Hpde as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
unfold getConfigPages.
unfold getConfigPagesAux.
rewrite Hpd, Hsh1, Hsh2, Hsh3.
simpl.
right.
do 2 (rewrite in_app_iff;
right).
 rewrite in_app_iff.
left.
unfold getIndirections.
destruct Hget with (StateLib.getIndexOfAddr descChild fstLevel) ;trivial.
clear Hget.
unfold getTableAddrRoot in *.
destruct H0 as(_ & H0).
rewrite <- nextEntryIsPPgetSndShadow in *.
apply H0 in Hsh2.
clear H0.
destruct Hsh2 as (nbL & HnbL & stop & Hstop & Hind).
apply getIndirectionInGetIndirections with descChild nbL stop;trivial.
assert(0<nbLevel) by apply nbLevelNotZero;trivial.
apply beq_nat_false in Hnotnull.
unfold not;intros.
subst.
now contradict Hnotnull.
apply getNbLevelLe in HnbL;trivial.
assumption.
Qed.

Lemma isConfigTableSh2 descChild ptRefChild descParent s :
partitionDescriptorEntry s ->
In descParent (getPartitions multiplexer s) ->
getTableAddrRoot ptRefChild sh2idx descParent descChild s ->
(Nat.eqb defaultPage ptRefChild) = false ->
In ptRefChild (getConfigPages descParent s).
Proof.
intros Hpde Hpart Hget Hnotnull.
apply pdSh1Sh2ListExistsNotNull  with s descParent in Hpde;trivial.
destruct Hpde as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
unfold getConfigPages.
unfold getConfigPagesAux.
rewrite Hpd, Hsh1, Hsh2, Hsh3.
simpl.
right.
do 2 (rewrite in_app_iff;
right).
 rewrite in_app_iff.
left.
unfold getIndirections.
unfold getTableAddrRoot in *.
destruct Hget as(_ & H0).
rewrite <- nextEntryIsPPgetSndShadow in *.
apply H0 in Hsh2.
clear H0.
destruct Hsh2 as (nbL & HnbL & stop & Hstop & Hind).
apply getIndirectionInGetIndirections with descChild nbL stop;trivial.
assert(0<nbLevel) by apply nbLevelNotZero;trivial.
apply beq_nat_false in Hnotnull.
unfold not;intros.
subst.
now contradict Hnotnull.
apply getNbLevelLe in HnbL;trivial.
Qed.
Lemma isConfigTableSh1WithVE descChild ptRefChild descParent s :
partitionDescriptorEntry s ->
In descParent (getPartitions multiplexer s) ->
(forall idx : index,
StateLib.getIndexOfAddr descChild fstLevel = idx ->
isVE ptRefChild idx s /\ getTableAddrRoot ptRefChild sh1idx descParent descChild s) ->
(Nat.eqb defaultPage ptRefChild) = false ->
In ptRefChild (getConfigPages descParent s).
Proof.
intros Hpde Hpart Hget Hnotnull.
apply pdSh1Sh2ListExistsNotNull  with s descParent in Hpde.
destruct Hpde as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
unfold getConfigPages.
unfold getConfigPagesAux.
rewrite Hpd, Hsh1, Hsh2, Hsh3.
simpl.
right.
do 1 (rewrite in_app_iff;
right).
 rewrite in_app_iff.
left.
unfold getIndirections.
destruct Hget with (StateLib.getIndexOfAddr descChild fstLevel) ;trivial.
clear Hget.
unfold getTableAddrRoot in *.
destruct H0 as(_ & H0).
rewrite <- nextEntryIsPPgetFstShadow in *.
apply H0 in Hsh1.
clear H0.
destruct Hsh1 as (nbL & HnbL & stop & Hstop & Hind).
apply getIndirectionInGetIndirections with descChild nbL stop;trivial.
assert(0<nbLevel) by apply nbLevelNotZero;trivial.
apply beq_nat_false in Hnotnull.
unfold not;intros.
subst.
now contradict Hnotnull.
apply getNbLevelLe in HnbL;trivial.
assumption.
Qed.



Lemma mappedPageIsNotPTable (table1 table2 currentPart root : page)
F  idxroot  va idx1 (s : state):
 (idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx) ->
(forall partition : page,
          In partition (getPartitions multiplexer s) ->
          partition = table2 \/ In table2 (getConfigPagesAux partition s) -> False) ->
In currentPart (getPartitions multiplexer s) ->
partitionDescriptorEntry s ->
nextEntryIsPP currentPart idxroot root s ->
StateLib.getIndexOfAddr va fstLevel = idx1 ->
(forall idx : index,
        StateLib.getIndexOfAddr va fstLevel = idx ->
       F table1 idx s /\
        getTableAddrRoot table1 idxroot currentPart va s) ->
(Nat.eqb defaultPage table1) = false ->
table2 <> table1.
Proof.
intros Hor Hconfig Hcurpart Hpde Hpp Hidxref Hptref Hptrefnotnull.
assert(Hnotin: ~ In table2 (getConfigPagesAux currentPart s)).
 { generalize (Hconfig currentPart Hcurpart); clear Hconfig; intros Hconfig.
        apply Classical_Prop.not_or_and in Hconfig.
        destruct Hconfig; assumption. }
assert(Hin : In table1 (getConfigPagesAux currentPart s)).
{ unfold getConfigPagesAux.
  unfold consistency in *.
  assert (Hroots :
   (exists pd , StateLib.getPd currentPart (memory s) = Some pd /\
    pd <> defaultPage) /\
   (exists sh1, StateLib.getFstShadow currentPart (memory s) = Some sh1 /\
    sh1 <> defaultPage) /\
   (exists sh2, StateLib.getSndShadow currentPart (memory s) = Some sh2 /\
    sh2 <> defaultPage) /\
   (exists list, StateLib.getConfigTablesLinkedList currentPart (memory s) = Some list /\
    list <> defaultPage)).
  apply pdSh1Sh2ListExistsNotNull; trivial.
  (*
  assert (Hcurpd : StateLib.getPd currentPart (memory s) = Some root).
  apply nextEntryIsPPgetPd; trivial. *)
  destruct Hroots as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
  rewrite Hpd, Hsh1, Hsh2, Hsh3.
  destruct Hor as [Hpdroot | [Hsh1root | Hsh2root]].
  + rewrite Hpdroot in *.
    simpl.
    assert(Hroot : root = pd).
    apply getPdNextEntryIsPPEq with currentPart s;trivial.
    rewrite Hroot in *;clear Hroot. (*
    right. *)
    apply in_app_iff.
    left.
    apply Hptref in Hidxref.
    destruct Hidxref as (Hperef & Htblrootref).
    unfold getTableAddrRoot in Htblrootref.
    assert (Hppref : nextEntryIsPP currentPart PDidx pd s) by trivial.
    destruct  Htblrootref as (_ & Htblrootref).
    generalize (Htblrootref pd  Hppref); clear Htblrootref;
    intros Htblrootref.
    destruct Htblrootref as (nbL & HnbL & stop & Hstop & Hindref).
    apply getIndirectionInGetIndirections with va nbL stop; trivial.
    assert(0 < nbLevel) by apply nbLevelNotZero ; lia.
    apply beq_nat_false in Hptrefnotnull.
    unfold not; intros Hnot.
    subst. now contradict Hptrefnotnull.
    apply getNbLevelLe; trivial.
+  simpl.
    rewrite Hsh1root in *.
    assert(Hroot : root = sh1).
    apply getSh1NextEntryIsPPEq with currentPart s;trivial.
    rewrite Hroot in *;clear Hroot. (*
    right. *)
    apply in_app_iff.
    right.
    simpl. (* right. *)
    apply in_app_iff.
    left.
    apply Hptref in Hidxref.
    destruct Hidxref as (Hperef & Htblrootref).
    unfold getTableAddrRoot in Htblrootref.
    assert (Hppref : nextEntryIsPP currentPart sh1idx sh1 s) by trivial.
    destruct  Htblrootref as (_ & Htblrootref).
    generalize (Htblrootref sh1  Hppref); clear Htblrootref;
    intros Htblrootref.
    destruct Htblrootref as (nbL & HnbL & stop & Hstop & Hindref).
    apply getIndirectionInGetIndirections with va nbL stop; trivial.
    assert(0 < nbLevel) by apply nbLevelNotZero ; lia.
    apply beq_nat_false in Hptrefnotnull.
    unfold not; intros Hnot.
    subst. now contradict Hptrefnotnull.
    apply getNbLevelLe; trivial.
+ simpl.
    rewrite Hsh2root in *.
    assert(Hroot : root = sh2).
    apply getSh2NextEntryIsPPEq with currentPart s;trivial.
    rewrite Hroot in *;clear Hroot. (*
    right. *)
    apply in_app_iff.
    right.
    simpl.
(*      right. *)
    apply in_app_iff.
    right.
    simpl.
(*      right. *)
    apply in_app_iff.
    left.
    apply Hptref in Hidxref.
    destruct Hidxref as (Hperef & Htblrootref).
    unfold getTableAddrRoot in Htblrootref.
    assert (Hppref : nextEntryIsPP currentPart sh2idx sh2 s) by trivial.
    destruct  Htblrootref as (_ & Htblrootref).
    generalize (Htblrootref sh2  Hppref); clear Htblrootref;
    intros Htblrootref.
    destruct Htblrootref as (nbL & HnbL & stop & Hstop & Hindref).
    apply getIndirectionInGetIndirections with va nbL stop; trivial.
    assert(0 < nbLevel) by apply nbLevelNotZero ; lia.
    apply beq_nat_false in Hptrefnotnull.
    unfold not; intros Hnot.
    subst. now contradict Hptrefnotnull.
    apply getNbLevelLe; trivial. }
  unfold not; intros Hnot.
  subst; now contradict Hin.
Qed.


Lemma entryPresentFlagReadPresent s table idx flag:
entryPresentFlag table idx flag s ->
StateLib.readPresent table idx (memory s)  = Some flag.
Proof.
unfold entryPresentFlag , StateLib.readPresent .
intros.
destruct (lookup table idx (memory s) beqPage beqIndex );intros;try now contradict H.
destruct v;intros; try now contradict H.
subst;trivial.
Qed.

Lemma entryPresentFlagReadPresent' s table idx flag:
entryPresentFlag table idx flag s <->
StateLib.readPresent table idx (memory s)  = Some flag.
Proof.
unfold entryPresentFlag , StateLib.readPresent .
intros.
destruct (lookup table idx (memory s) beqPage beqIndex );intros;[|split;intros Hi;try now contradict Hi].
destruct v;split;intros; try now contradict H.
subst;trivial.
inversion H;trivial.
Qed.

Lemma entryUserFlagReadAccessible s table idx flag:
entryUserFlag table idx flag s <->
StateLib.readAccessible table idx (memory s)  = Some flag.
Proof.
unfold entryUserFlag , StateLib.readAccessible .
intros.
destruct (lookup table idx (memory s) beqPage beqIndex );intros;[|split;intros Hi;try now contradict Hi].
destruct v;split;intros; try now contradict H.
subst;trivial.
inversion H;trivial.
Qed.

Lemma isEntryPageLookupEq table idx entry phy s:
lookup table idx (memory s) beqPage beqIndex = Some (PE entry) ->
isEntryPage table idx phy s ->
pa entry = phy.
Proof.
intros Hlookup Hentrypage.
unfold isEntryPage in *.
rewrite Hlookup in *.
trivial.
Qed.

Lemma isEntryPageReadPhyEntry table idx entry s:
isEntryPage table idx (pa entry) s ->
StateLib.readPhyEntry table idx (memory s) = Some (pa entry).
Proof.
intros Hentrypage.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup table idx (memory s) beqPage beqIndex );
try now contradict Hentrypage.
destruct v; try now contradict Hentrypage.
f_equal;trivial.
Qed.

Lemma isEntryPageReadPhyEntry1 table idx p s:
isEntryPage table idx p s ->
StateLib.readPhyEntry table idx (memory s) = Some p.
Proof.
intros Hentrypage.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup table idx (memory s) beqPage beqIndex );
try now contradict Hentrypage.
destruct v; try now contradict Hentrypage.
f_equal;trivial.
Qed.
Lemma isAccessibleMappedPage pdChild currentPD (ptPDChild : page)  entry s :
(Nat.eqb defaultPage ptPDChild ) = false ->
entryPresentFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
entryUserFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) beqPage beqIndex =
    Some (PE entry) ->
 nextEntryIsPP (currentPartition s) PDidx currentPD s ->
(forall idx : index,
StateLib.getIndexOfAddr pdChild fstLevel = idx ->
isPE ptPDChild idx s /\ getTableAddrRoot ptPDChild PDidx (currentPartition s) pdChild s ) ->
getAccessibleMappedPage currentPD s pdChild = SomePage (pa entry).
Proof.
intros Hnotnull Hpe Hue Hlookup Hpp Hget .
assert ( isPE ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) s /\
        getTableAddrRoot ptPDChild PDidx (currentPartition s) pdChild s) as (_ & Hroot).
apply Hget; trivial.
clear Hget.
unfold getAccessibleMappedPage.
unfold getTableAddrRoot in *.
destruct Hroot  as (_ & Hroot).
apply Hroot in Hpp; clear Hroot.
destruct Hpp as (nbL & HnbL & stop & Hstop & Hind).
rewrite <- HnbL.
subst.
assert (Hnewind : getIndirection currentPD pdChild nbL (nbLevel - 1) s= Some ptPDChild).
apply getIndirectionStopLevelGT2 with (nbL + 1);try lia;trivial.
apply getNbLevelEq in HnbL.
unfold CLevel in HnbL.
case_eq (lt_dec (nbLevel - 1) nbLevel); intros; rewrite H in *.
destruct nbL.
simpl in *.
inversion HnbL; trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
apply entryPresentFlagReadPresent in Hpe.
rewrite Hpe.
apply entryUserFlagReadAccessible in Hue.
rewrite Hue.
unfold StateLib.readPhyEntry.
rewrite Hnotnull.
rewrite Hlookup; trivial.
Qed.
Lemma isAccessibleMappedPage2 partition pdChild currentPD (ptPDChild : page)  phypage s :
(Nat.eqb defaultPage ptPDChild ) = false ->
entryPresentFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
entryUserFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
isEntryPage ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) phypage s ->
 nextEntryIsPP partition PDidx currentPD s ->
(forall idx : index,
StateLib.getIndexOfAddr pdChild fstLevel = idx ->
isPE ptPDChild idx s /\ getTableAddrRoot ptPDChild PDidx partition pdChild s ) ->
getAccessibleMappedPage currentPD s pdChild = SomePage phypage.
Proof.
intros Hnotnull Hpe Hue Hlookup Hpp Hget .
assert ( isPE ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) s /\
        getTableAddrRoot ptPDChild PDidx partition pdChild s) as (_ & Hroot).
apply Hget; trivial.
clear Hget.
unfold getAccessibleMappedPage.
unfold getTableAddrRoot in *.
destruct Hroot  as (_ & Hroot).
apply Hroot in Hpp; clear Hroot.
destruct Hpp as (nbL & HnbL & stop & Hstop & Hind).
rewrite <- HnbL.
subst.
assert (Hnewind : getIndirection currentPD pdChild nbL (nbLevel - 1) s= Some ptPDChild).
apply getIndirectionStopLevelGT2 with (nbL + 1);try lia;trivial.
apply getNbLevelEq in HnbL.
unfold CLevel in HnbL.
case_eq (lt_dec (nbLevel - 1) nbLevel); intros; rewrite H in *.
destruct nbL.
simpl in *.
inversion HnbL; trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
apply entryPresentFlagReadPresent in Hpe.
rewrite Hpe.
apply entryUserFlagReadAccessible in Hue.
rewrite Hue.
unfold StateLib.readPhyEntry.
rewrite Hnotnull.
unfold isEntryPage in *.
destruct(lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel)
              (memory s) beqPage beqIndex);
              try now contradict Hlookup.
destruct v;            try now contradict Hlookup.
f_equal;

trivial.
Qed.

Lemma getPDFlagReadPDflag currentShadow1 pdChild (ptPDChildSh1 : page)
idxPDChild currentPart s:
(Nat.eqb ptPDChildSh1 defaultPage) = false ->
nextEntryIsPP currentPart sh1idx currentShadow1 s ->
getPDFlag currentShadow1 pdChild s = false ->
StateLib.getIndexOfAddr pdChild fstLevel =  idxPDChild ->
(forall idx : index,
   StateLib.getIndexOfAddr pdChild fstLevel = idx ->
   isVE ptPDChildSh1 idx s /\
   getTableAddrRoot ptPDChildSh1 sh1idx currentPart pdChild s) ->
StateLib.readPDflag ptPDChildSh1 idxPDChild (memory s) = Some false \/
StateLib.readPDflag ptPDChildSh1 idxPDChild (memory s) = None .
Proof.
intros Hptnotnull Hsh1 Hgetflag Hidx Hind.
assert(isVE ptPDChildSh1 (StateLib.getIndexOfAddr pdChild fstLevel) s /\
      getTableAddrRoot ptPDChildSh1 sh1idx currentPart pdChild s) as (Hve & Hget).
apply Hind;trivial.
clear Hind.
unfold getTableAddrRoot in *.
unfold getPDFlag in *.
destruct Hget as (_ & Hget).
apply Hget in Hsh1.
clear Hget.
destruct Hsh1 as (nbL & HnbL & stop & Hstop & Hget).
subst.
rewrite <- HnbL in *.
assert (Hind1 : getIndirection currentShadow1 pdChild nbL (nbLevel - 1) s  = Some ptPDChildSh1).
apply getIndirectionStopLevelGT2 with (nbL +1);try lia;trivial.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq ( lt_dec (nbLevel - 1) nbLevel);intros.
simpl;trivial.
assert(0 < nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hind1 in *.
rewrite Hptnotnull in *.
case_eq(StateLib.readPDflag ptPDChildSh1
        (StateLib.getIndexOfAddr pdChild fstLevel) (memory s));intros.
rewrite H in *.
destruct b; try now contradict Hgetflag.
trivial.
left;trivial.
right;trivial.
Qed.

Lemma isVaInParent s va descParent (ptsh2 : page) vaInAncestor sh2 :
(Nat.eqb defaultPage ptsh2) = false ->
(forall idx : index,
StateLib.getIndexOfAddr va fstLevel = idx ->
isVA ptsh2 idx s /\ getTableAddrRoot ptsh2 sh2idx descParent va s) ->
isVA' ptsh2 (StateLib.getIndexOfAddr va fstLevel) vaInAncestor s ->
nextEntryIsPP descParent sh2idx sh2 s ->
getVirtualAddressSh2 sh2 s va = Some vaInAncestor.
Proof.
intros Hnotnull Hroot Hva Hpp .
assert( isVA ptsh2 (StateLib.getIndexOfAddr va fstLevel ) s /\ getTableAddrRoot ptsh2 sh2idx descParent va s) as (Hisva & Hget).
apply Hroot;trivial. clear Hroot.
unfold getTableAddrRoot in *.
destruct Hget as (_ & Hget).
apply Hget in Hpp.
clear Hget.
destruct Hpp as (nbL & HnbL & stop & Hstop & Hind).
unfold getVirtualAddressSh2.
rewrite <- HnbL.
subst.
assert (getIndirection sh2 va nbL (nbLevel - 1) s = Some ptsh2).
apply getIndirectionStopLevelGT2 with (nbL+1) ; trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq( lt_dec (nbLevel - 1) nbLevel );intros.
simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
clear Hind.
rewrite H.
rewrite Hnotnull.
unfold isVA' in *.
unfold StateLib.readVirtual.
destruct( lookup ptsh2 (StateLib.getIndexOfAddr va fstLevel) (memory s) beqPage beqIndex );
try now contradict Hva.
destruct v; try now contradict Hva.
subst;trivial.
Qed.

Lemma disjointUsedPagesDisjointMappedPages partition1 partition2 s:
disjoint (getUsedPages partition1 s) (getUsedPages partition2 s) ->
disjoint (getMappedPages partition1 s) (getMappedPages partition2 s).
Proof.
intros.
unfold disjoint in *.
intros.
unfold getUsedPages in *.
simpl in *.
assert(~
(partition2 = x \/
In x (getConfigPagesAux partition2 s ++ getMappedPages partition2 s))).
apply H.
right.
apply in_app_iff.
right;trivial.
apply Classical_Prop.not_or_and in H1.
destruct H1.
rewrite in_app_iff in H2.
apply Classical_Prop.not_or_and in H2.
intuition.
Qed.



Lemma inGetMappedPagesGetIndirection descParent entry vaInDescParent pdDesc (pt : page) nbL1  s:
entryPresentFlag pt (StateLib.getIndexOfAddr vaInDescParent fstLevel) true s ->
(Nat.eqb defaultPage pt) = false ->
Some nbL1 = StateLib.getNbLevel ->
nextEntryIsPP descParent PDidx pdDesc s ->
getIndirection pdDesc vaInDescParent nbL1 (nbL1 + 1) s = Some pt ->
isEntryPage pt (StateLib.getIndexOfAddr vaInDescParent fstLevel) (pa entry) s ->
In (pa entry) (getMappedPages descParent s).
Proof.
intros Hpresent Hptnotnull HnbL Hpd Hind Hep.
unfold getMappedPages.
rewrite nextEntryIsPPgetPd in *.
rewrite Hpd.
unfold getMappedPagesAux.
apply filterOptionInIff.
unfold getMappedPagesOption.
rewrite in_map_iff.
assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel vaInDescParent va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1 & Hva11).
exists va1;split;trivial.
assert(Hnewgoal : getMappedPage pdDesc s vaInDescParent = SomePage (pa entry)).
{
unfold getMappedPage.
rewrite <- HnbL.
assert(Hnewind : getIndirection pdDesc vaInDescParent nbL1 (nbLevel - 1) s  = Some pt).
apply getIndirectionStopLevelGT2 with (nbL1+1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(   lt_dec (nbLevel - 1) nbLevel);intros.
simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hptnotnull.
rewrite entryPresentFlagReadPresent with s pt  (StateLib.getIndexOfAddr
vaInDescParent fstLevel) true;trivial.
apply isEntryPageReadPhyEntry in Hep.
rewrite Hep. trivial. }
rewrite <- Hnewgoal.
symmetry.
apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.
Qed.

Lemma getMappedPageGetIndirection ancestor phypage newVA pdAncestor
 (ptAncestor : page) L  s:
StateLib.readPresent ptAncestor (StateLib.getIndexOfAddr newVA fstLevel)
 (memory s) = Some true ->
(Nat.eqb defaultPage ptAncestor) = false ->
 Some L = StateLib.getNbLevel ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
getIndirection pdAncestor newVA L (nbLevel - 1) s = Some ptAncestor ->
StateLib.readPhyEntry ptAncestor (StateLib.getIndexOfAddr newVA fstLevel)
 (memory s) =  Some phypage ->
getMappedPage pdAncestor s newVA = SomePage phypage.
Proof.
intros Hpresent Hptnotnull HnbL Hpd Hind Hep.
unfold getMappedPage.
rewrite nextEntryIsPPgetPd in *.
rewrite <- HnbL.
rewrite Hind.
rewrite Hptnotnull.
rewrite Hpresent;trivial.
rewrite Hep;trivial.
Qed.

Lemma getMappedPageGetTableRoot ptvaInAncestor ancestor phypage pdAncestor vaInAncestor s :
( forall idx : index,
      StateLib.getIndexOfAddr vaInAncestor fstLevel = idx ->
      isPE ptvaInAncestor idx s /\
      getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s) ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
 isEntryPage ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
 phypage s ->
 entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s
  ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
getMappedPage pdAncestor s vaInAncestor = SomePage phypage.
Proof.
intros Hget Hnotnull Hep Hpresent Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr vaInAncestor fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd ancestor (memory s) = Some pdAncestor).
apply nextEntryIsPPgetPd;trivial.
apply Htableroot in Hpdparent.
 clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).
unfold getMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);
intros;simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
 (memory s) beqPage beqIndex );
try now contradict Hep.
destruct v; try now contradict Hep.
f_equal;trivial.
Qed.
Lemma getVirtualAddressSh2GetTableRoot:
forall (ptsh2 descParent  sh2  : page)
    (vaInAncestor va: vaddr) (s : state) L,
(forall idx : index,
  StateLib.getIndexOfAddr va fstLevel = idx ->
   isVA ptsh2 idx s /\ getTableAddrRoot ptsh2 sh2idx descParent va s) ->
(Nat.eqb defaultPage ptsh2) = false ->
isVA' ptsh2 (StateLib.getIndexOfAddr va fstLevel) vaInAncestor s ->
StateLib.getSndShadow descParent (memory s) = Some sh2 ->
Some L = StateLib.getNbLevel ->
getVirtualAddressSh2 sh2 s va = Some vaInAncestor.
Proof.
intros ptsh2 descParent sh2 vaInAncestor va  s L.
intros Hget Hnotnull Hisva Hsh2 HL.

unfold getVirtualAddressSh2.
rewrite <- HL.
destruct Hget with (StateLib.getIndexOfAddr va fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
rewrite <- nextEntryIsPPgetSndShadow in *.
apply Htableroot in Hsh2.
clear Htableroot.
destruct Hsh2 as (nbL & HnbL & stop & Hstop & Hind ).
subst.
rewrite <- HnbL in *.
inversion HL.
subst.
assert(Hnewind :getIndirection sh2 va nbL (nbLevel - 1) s
= Some ptsh2).
apply getIndirectionStopLevelGT2 with (nbL +1);try lia;trivial.
apply getNbLevelEq in HnbL.
subst. apply nbLevelEq.
rewrite Hnewind.
rewrite Hnotnull.
unfold isVA' in *.
unfold StateLib.readVirtual.
destruct(lookup ptsh2 (StateLib.getIndexOfAddr va fstLevel)
(memory s) beqPage beqIndex );
try now contradict Hisva.
destruct v; try now contradict Hisva.
f_equal;trivial.
Qed.



Lemma getMappedPageNotAccessible
ptvaInAncestor ancestor phypage pdAncestor vaInAncestor s :
( forall idx : index,
      StateLib.getIndexOfAddr vaInAncestor fstLevel = idx ->
      isPE ptvaInAncestor idx s /\
      getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s) ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
 isEntryPage ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
 phypage s ->
 entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s ->
entryUserFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) false s ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
getAccessibleMappedPage pdAncestor s vaInAncestor = NonePage.
Proof.
intros Hget Hnotnull Hep Hpresent Huser Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr vaInAncestor fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd ancestor (memory s) = Some pdAncestor).
apply nextEntryIsPPgetPd;trivial.
apply Htableroot in Hpdparent.
 clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).

unfold getAccessibleMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);
intros;simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
 (memory s) beqPage beqIndex );
try now contradict Hep.
destruct v; try now contradict Hep.
unfold StateLib.readAccessible.
unfold entryUserFlag in *.
case_eq(lookup ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
            (memory s) beqPage beqIndex);[intros v Hv | intros Hv];
            rewrite Hv in *; trivial.
case_eq v; intros entry Hentry;
rewrite Hentry in *; trivial.
rewrite <- Huser;trivial.
Qed.

Lemma getAccessibleMappedPageNotPresent
ptvaInAncestor ancestor  pdAncestor vaInAncestor s :
( forall idx : index,
      StateLib.getIndexOfAddr vaInAncestor fstLevel = idx ->
      isPE ptvaInAncestor idx s /\
      getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s) ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
 entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) false s ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
getAccessibleMappedPage pdAncestor s vaInAncestor = NonePage.
Proof.
intros Hget Hnotnull  Hpresent  Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr vaInAncestor fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd ancestor (memory s) = Some pdAncestor).
apply nextEntryIsPPgetPd;trivial.
apply Htableroot in Hpdparent.
 clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).

unfold getAccessibleMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);
intros;simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
trivial.
Qed.

Lemma getMappedPageNotPresent
ptvaInAncestor ancestor  pdAncestor vaInAncestor s :
( forall idx : index,
      StateLib.getIndexOfAddr vaInAncestor fstLevel = idx ->
      isPE ptvaInAncestor idx s /\
      getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s) ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
 entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) false s ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
getMappedPage pdAncestor s vaInAncestor = SomeDefault.
Proof.
intros Hget Hnotnull  Hpresent  Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr vaInAncestor fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd ancestor (memory s) = Some pdAncestor).
apply nextEntryIsPPgetPd;trivial.
apply Htableroot in Hpdparent.
 clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).
unfold getMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);
intros;simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
trivial.
Qed.

Lemma inGetMappedPagesGetTableRoot va pt descParent phypage pdParent s :
(forall idx : index,
StateLib.getIndexOfAddr va fstLevel = idx ->
isPE pt idx s /\ getTableAddrRoot pt PDidx descParent va s) ->
(Nat.eqb defaultPage pt) = false ->
isEntryPage pt(StateLib.getIndexOfAddr va fstLevel)  phypage s ->
entryPresentFlag pt (StateLib.getIndexOfAddr va fstLevel)  true s ->
nextEntryIsPP descParent PDidx pdParent s ->
In phypage (getMappedPages descParent s).
Proof.
intros Hget Hnotnull Hep Hpresent Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr va fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd descParent (memory s) = Some pdParent).
apply nextEntryIsPPgetPd;trivial.
rewrite Hpd.
apply Htableroot in Hpdparent. clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).
unfold getMappedPagesAux.
apply filterOptionInIff.
unfold getMappedPagesOption.
apply in_map_iff.
assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel va va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1 & Hva11).
exists va1;split;trivial.
assert(Hnewgoal : getMappedPage pdParent s va = SomePage phypage).
{ unfold getMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection  pdParent va nbL  (nbLevel - 1) s = Some pt).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);
intros;simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup pt (StateLib.getIndexOfAddr va fstLevel) (memory s) beqPage beqIndex );
try now contradict Hep.
destruct v; try now contradict Hep.
f_equal;trivial. }
rewrite <- Hnewgoal.
symmetry.
apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.

(* apply AllVAddrAll.
Qed.
 *)
 Qed.


Lemma pageDecOrNot :
forall p1 p2 : page, p1 = p2 \/ p1<>p2.
Proof.
destruct p1;simpl in *;subst;destruct p2;simpl in *;subst.
assert (Heq :p=p0 \/ p<> p0) by lia.
destruct Heq as [Heq|Heq].
subst.
left;f_equal;apply proof_irrelevance.
right. unfold not;intros.
inversion H.
subst.
now contradict Heq.
Qed.

Lemma isAncestorTrans ancestor descParent currentPart s:
parentInPartitionList s ->
noCycleInPartitionTree s->
isParent s ->
noDupPartitionTree s ->
multiplexerWithoutParent s ->
In currentPart (getPartitions multiplexer s) ->
StateLib.getParent descParent (memory s) = Some ancestor ->
isAncestor currentPart descParent s ->
isAncestor currentPart ancestor s.
Proof.
unfold isAncestor.
intros Hparentinlist  Hnocycle.
intros Hisparent Hnoduptree Hmultnone Hcurpart.
intros.
assert(Hor :currentPart = ancestor  \/ currentPart <> ancestor ).
apply pageDecOrNot.
destruct Hor.
left;trivial.
right.
destruct H0.
+ subst.
  unfold getAncestors.
  induction nbPage;
  simpl;
  rewrite H;
  simpl;left;trivial.
+ apply isAncestorTrans2 with descParent;trivial.
Qed.

Lemma parentIsAncestor partition ancestor s:
nextEntryIsPP partition PPRidx ancestor s ->
In ancestor (getAncestors partition s).
Proof.
intros Hpd.
rewrite nextEntryIsPPgetParent in *.
unfold getAncestors.
destruct nbPage;
simpl;
rewrite Hpd;simpl;left;trivial.
Qed.

Lemma phyPageNotDefault table idx phyPage s :
isPresentNotDefaultIff s ->
entryPresentFlag table idx true s ->
isEntryPage table idx phyPage s ->
(Nat.eqb defaultPage phyPage) = false.
Proof.
intros.
unfold isPresentNotDefaultIff in *.
assert (StateLib.readPhyEntry table idx (memory s) = Some phyPage).
{ unfold StateLib.readPhyEntry.
 unfold isEntryPage in *.
 case_eq(lookup table idx (memory s) beqPage beqIndex);intros * Hi;
 rewrite Hi in *;try now contradict H1.
 case_eq v;intros * Hii;
 rewrite Hii in *;try now contradict H1.
 subst;trivial. }
assert (StateLib.readPresent table idx (memory s) = Some true).
{ unfold StateLib.readPresent .
  unfold entryPresentFlag in *.
  case_eq(lookup table idx (memory s) beqPage beqIndex);intros * Hi;
  rewrite Hi in *;try now contradict H1.
  case_eq v;intros * Hii;
  rewrite Hii in *;try now contradict H1.
  subst;f_equal;symmetry; trivial. }
clear H1 H0.
apply PeanoNat.Nat.eqb_neq.
unfold not;intros;subst.
destruct phyPage;destruct defaultPage.
simpl in *.
subst.
assert(Hp0 = Hp).
apply proof_irrelevance;trivial.
subst.
apply H in H2.
rewrite H2 in H3.
inversion H3.
Qed.

Lemma phyPageIsPresent table idx entry s :
isPresentNotDefaultIff s ->
 lookup table idx (memory s) beqPage beqIndex = Some (PE entry) ->
(Nat.eqb defaultPage (pa entry)) = false ->
present entry = true.
Proof.
intros.
unfold isPresentNotDefaultIff in *.
assert (StateLib.readPhyEntry table idx (memory s) = Some (pa entry)).
{ unfold StateLib.readPhyEntry.
  rewrite H0. trivial. }
apply beq_nat_false in H1.
assert (~ (present entry = false) -> present entry = true ).
intros.
unfold not in *.
destruct ( present entry); trivial.
contradict H3;trivial.
apply H3.
unfold not.
intros.
clear H3.
generalize (H table idx);clear H; intros H.
destruct H as (Hii & Hi).
assert(StateLib.readPresent table idx (memory s) = Some false).
unfold StateLib.readPresent.
rewrite H0.
f_equal;trivial.
apply Hii in H.
clear Hi Hii.
apply H1.
rewrite  H in H2.
inversion H2;trivial.
Qed.

Lemma accessiblePAgeIsMapped pd s va accessiblePage :
getAccessibleMappedPage pd s va = SomePage accessiblePage ->
getMappedPage pd s va = SomePage accessiblePage.
Proof.
intros.
unfold getMappedPage.
unfold getAccessibleMappedPage in *.
destruct( StateLib.getNbLevel);try now contradict H.
destruct ( getIndirection pd va l (nbLevel - 1) s );try now contradict H.
destruct(Nat.eqb defaultPage p);try now contradict H.
destruct(StateLib.readPresent p (StateLib.getIndexOfAddr va fstLevel) (memory s) );
try
 now contradict H.
 destruct b;try now contradict H.
destruct( StateLib.readAccessible p (StateLib.getIndexOfAddr va fstLevel) (memory s));
try now contradict H.
destruct b;try now contradict H.

trivial.
Qed.
Import List.ListNotations.
Lemma getIndirectionsOnlyPD pd s:
(forall idx : index,
        StateLib.readPhyEntry pd idx (memory s) = Some defaultPage /\
        StateLib.readPresent pd idx (memory s) = Some false) ->
  getIndirections pd s = [pd].
Proof.
intros.
unfold getIndirections.
assert(0<nbLevel) by apply nbLevelNotZero.
destruct nbLevel.
simpl.
lia.
simpl.
f_equal.
induction tableSize.
simpl;trivial.
simpl.
intros.
destruct H with (CIndex n0) as (Hphy & Hpres);trivial.
unfold StateLib.readPhyEntry in *.
case_eq(lookup pd (CIndex n0) (memory s) beqPage beqIndex);
intros * Hread;rewrite Hread in *;trivial.
case_eq v;intros * Hv; rewrite Hv in *;trivial.
inversion Hphy.
subst.
case_eq(Nat.eqb (pa p) (pa p));intros Hfalse;trivial.
apply beq_nat_false in Hfalse.
now contradict Hfalse.
Qed.

Lemma getIndirectionsOnlySh1 sh1 level s:
Some level =StateLib.getNbLevel ->
 isWellFormedFstShadow level sh1 s ->
  getIndirections sh1 s = [sh1].
Proof.
intros.
apply getNbLevelEq in H.
unfold getIndirections.
unfold isWellFormedFstShadow in *.
assert(0<nbLevel) by apply nbLevelNotZero.
destruct nbLevel.
lia.
simpl.
induction tableSize.
simpl;trivial.
f_equal.
simpl.
inversion IHn0.
destruct H0.
destruct H0 as (Hlevel & Hcontent).
destruct Hcontent with (CIndex n0) as (Hphy & Hpres);trivial.
unfold StateLib.readPhyEntry in *.
case_eq(lookup sh1 (CIndex n0) (memory s) beqPage beqIndex);
intros * Hread;rewrite Hread in *;trivial.
case_eq v;intros * Hv; rewrite Hv in *;trivial.
inversion Hphy.
subst.
case_eq(Nat.eqb (pa p) (pa p));intros Hfalse;trivial.
apply beq_nat_false in Hfalse.
now contradict Hfalse.
inversion IHn0.
 (*
destruct H0. *)
destruct H0 as (Hlevel & H2).
destruct H2 with (CIndex n0) as (Hphy & Hpres);trivial.
unfold StateLib.readVirEntry in *.
case_eq(lookup sh1 (CIndex n0) (memory s) beqPage beqIndex);
intros * Hread;rewrite Hread in *;trivial.
case_eq v;intros * Hv; rewrite Hv in *;trivial.
now contradict Hphy.
Qed.

Lemma getIndirectionsOnlySh2 sh2 level s:
Some level =StateLib.getNbLevel ->
 isWellFormedSndShadow level sh2 s ->
  getIndirections sh2 s = [sh2].
Proof.
intros.
apply getNbLevelEq in H.
unfold getIndirections.
unfold isWellFormedSndShadow in *.
assert(0<nbLevel) by apply nbLevelNotZero.
destruct nbLevel.
lia.
simpl.
induction tableSize.
simpl;trivial.
f_equal.
simpl.
inversion IHn0.
destruct H0.
destruct H0 as (Hlevel & Hcontent).
destruct Hcontent with (CIndex n0) as (Hphy & Hpres);trivial.
unfold StateLib.readPhyEntry in *.
case_eq(lookup sh2 (CIndex n0) (memory s) beqPage beqIndex);
intros * Hread;rewrite Hread in *;trivial.
case_eq v;intros * Hv; rewrite Hv in *;trivial.
inversion Hphy.
subst.
case_eq(Nat.eqb (pa p) (pa p));intros Hfalse;trivial.
apply beq_nat_false in Hfalse.
now contradict Hfalse.
inversion IHn0.
(* destruct H0. *)
destruct H0 as (Hlevel & H2).

unfold StateLib.readVirtual in *.

generalize (H2 (CIndex n0)) ; clear H2 ;intros H2.
case_eq(lookup sh2 (CIndex n0) (memory s) beqPage beqIndex);
intros * Hread;rewrite Hread in *;trivial.
case_eq v;intros * Hv; rewrite Hv in *;trivial.
now contradict H2.
Qed.

Lemma getLLPagesOnlyRoot root s:
initConfigPagesListPostCondition root s -> (*
StateLib.readPhysical root (CIndex (tableSize - 1)) (memory s) = Some defaultPage ->
(forall idx : index,
idx <> CIndex (tableSize - 1) ->
Nat.Odd idx ->
StateLib.readVirtual root idx (memory s) =
Some defaultVAddr) ->
(forall idx : index,
Nat.Even idx ->
exists idxValue : index,
StateLib.readIndex root idx (memory s) = Some idxValue) ->
 *)
 getLLPages root s (nbPage+1) =
[root].
Proof.
unfold initConfigPagesListPostCondition.
intros  (HphyListcontent1 & HphyListcontent2 & HphyListcontent3 & HphyListcontent4) .
assert(Hi : 0<nbPage+1) by lia.
destruct (nbPage+1).
simpl.
lia.
simpl.
case_eq (StateLib.getMaxIndex);intros.
unfold StateLib.getMaxIndex in *.
case_eq (gt_dec tableSize 0 );intros;
rewrite H0 in *.
assert(i =  (CIndex (tableSize - 1))).
destruct i.
inversion H.
subst.
unfold CIndex.
case_eq (lt_dec (tableSize - 1) tableSize);
intros.
f_equal.
apply proof_irrelevance.
assert(tableSizeLowerBound<tableSize) by apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
now contradict H2.
subst.
rewrite HphyListcontent1.
assert((Nat.eqb defaultPage defaultPage) = true).
apply NPeano.Nat.eqb_refl.
rewrite H1;trivial.
now contradict H0.
unfold StateLib.getMaxIndex in *.
case_eq (gt_dec tableSize 0 );intros;
rewrite H0 in *.
now contradict H0.
 assert(tableSizeLowerBound<tableSize) by apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia.
Qed.

Require Import Coq.Sorting.Permutation.

Lemma getIndirectionGetTableRoot (s : state) currentShadow1 currentPart ptRefChildFromSh1 descChild
nbL :
StateLib.getFstShadow currentPart (memory s) = Some currentShadow1 ->
StateLib.getNbLevel = Some nbL ->
(forall idx : index,
  StateLib.getIndexOfAddr descChild fstLevel = idx ->
  isVE ptRefChildFromSh1 idx s /\
  getTableAddrRoot ptRefChildFromSh1 sh1idx currentPart descChild s)
  ->
getIndirection currentShadow1 descChild nbL (nbLevel - 1) s = Some ptRefChildFromSh1.
Proof.
intros.
destruct H1 with (StateLib.getIndexOfAddr descChild fstLevel );
trivial.
clear H1.
unfold getTableAddrRoot in *.
destruct H3 as (_ & H3).
rewrite <- nextEntryIsPPgetFstShadow in *.
apply H3 in H.
clear H3.
destruct H as (nbl & HnbL & stop & Hstop & Hind).
subst.
rewrite H0 in HnbL.
inversion HnbL;subst.
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
symmetry in H0.
apply getNbLevelEq in H0.
subst.
apply nbLevelEq.
Qed.

Lemma getIndirectionGetTableRoot1 (s : state) pd currentPart pt va
nbL :
StateLib.getPd currentPart (memory s) = Some pd ->
StateLib.getNbLevel = Some nbL ->
(forall idx : index,
  StateLib.getIndexOfAddr va fstLevel = idx ->
  isPE pt idx s /\
  getTableAddrRoot pt PDidx currentPart va s)
  ->
getIndirection pd va nbL (nbLevel - 1) s = Some pt.
Proof.
intros.
destruct H1 with (StateLib.getIndexOfAddr va fstLevel );
trivial.
clear H1.
unfold getTableAddrRoot in *.
destruct H3 as (_ & H3).
rewrite <- nextEntryIsPPgetPd in *.
apply H3 in H.
clear H3.
destruct H as (nbl & HnbL & stop & Hstop & Hind).
subst.
rewrite H0 in HnbL.
inversion HnbL;subst.
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
symmetry in H0.
apply getNbLevelEq in H0.
subst.
apply nbLevelEq.
Qed.

Lemma readPhyEntryInGetIndirectionsAux s root n:
forall page1,page1 <> defaultPage ->
In page1 (getTablePages root tableSize s) ->
n> 1 ->
In page1 (getIndirectionsAux root s n)  .
Proof.
intros.
destruct n;
intros; simpl in *.  now contradict H1.
simpl in *. right.
apply in_flat_map.
exists page1.
split; trivial.
destruct n.  lia. simpl.
left. trivial.
Qed.

Lemma nodupLevelMinus1 root s (n0 : nat) idx:
forall p , p<> defaultPage ->
StateLib.readPhyEntry root idx (memory s) = Some p ->
NoDup (getIndirectionsAux root s n0 ) ->
 n0 <= nbLevel  ->
NoDup (getIndirectionsAux p s (n0 - 1)).
Proof.
intros p Hnotnull Hread Hnodup Hnbl.
destruct n0;simpl in *; trivial.
(* constructor;auto.
constructor. *)
rewrite NPeano.Nat.sub_0_r.
apply NoDup_cons_iff in Hnodup.
destruct Hnodup as (_ & Hnodup).
assert (In p (getTablePages root tableSize s)) as HIn.
apply readPhyEntryInGetTablePages with idx; trivial.
destruct idx. simpl in *; trivial.
assert (idx = (CIndex idx)) as Hidx.
symmetry.
apply indexEqId.
rewrite <- Hidx. assumption.
induction (getTablePages root tableSize s).
now contradict HIn.
simpl in *.
apply NoDupSplit in Hnodup.
destruct HIn;
destruct Hnodup;
subst; trivial.
apply IHl;trivial.
Qed.

Lemma inclGetIndirectionsAuxMinus1 n root idx p s:
StateLib.readPhyEntry root idx (memory s) = Some p ->
(Nat.eqb defaultPage p) = false ->
n> 1 ->
incl (getIndirectionsAux p s (n - 1)) (getIndirectionsAux root s n).
Proof.
intros Hread Hnotnull Hn.
unfold incl.
intros.
set(k := n -1) in *.
replace n with (S k); [ | unfold k; lia].
simpl.
assert (In p (getTablePages root tableSize s)) as Htbl.
apply readPhyEntryInGetTablePages with idx; trivial.
destruct idx; simpl in *; trivial.
apply beq_nat_false in Hnotnull. unfold not. intros.
contradict Hnotnull.
rewrite H0. trivial.
assert (idx = (CIndex idx)) as Hidx'.
symmetry. apply indexEqId. rewrite <- Hidx'.
assumption. right.
induction ((getTablePages root tableSize s)).
now contradict Htbl.
simpl in *.
destruct Htbl; subst;
apply in_app_iff. left;trivial.
right.

apply IHl;trivial.
Qed.

Lemma notInFlatMapNotInGetIndirection k l ( p0: page) s x:
In p0 l ->
~ In x (flat_map (fun p : page => getIndirectionsAux p s k) l) ->
~ In x (getIndirectionsAux p0 s k).
Proof.
revert  p0 x k.
induction l; simpl in *; intros; [
now contradict H |].
destruct H; subst.
+ unfold not. intros. apply H0.
  apply in_app_iff. left. assumption.
+ apply IHl; trivial.
  unfold not.
  intros. apply H0.
  apply in_app_iff. right. assumption.
Qed.

Lemma disjointGetIndirectionsAuxMiddle n (p p0 : page) root (idx1 idx2 : index) s:
p0 <> p ->
n > 1 ->
(Nat.eqb defaultPage p) = false ->
(Nat.eqb defaultPage p0) = false ->
NoDup (getIndirectionsAux root s n) ->
StateLib.readPhyEntry root idx1 (memory s) = Some p0 ->
StateLib.readPhyEntry root idx2 (memory s) = Some p ->
disjoint (getIndirectionsAux p s (n - 1)) (getIndirectionsAux p0 s (n - 1)).
Proof.
unfold disjoint.
intros Hp0p Hn Hnotnull1 Hnotnull2 Hnodup Hreadp0 Hreadp x Hxp.
set(k := n -1) in *.
assert(n = S k) as Hk.
unfold k in *.  lia.
rewrite Hk in Hnodup. simpl in *.
apply  NoDup_cons_iff in Hnodup.
destruct Hnodup as (Hnoduproot & Hnodup2).
assert ( In p0  (getTablePages root tableSize s)) as Hp0root.
apply readPhyEntryInGetTablePages with idx1; trivial.
destruct idx1. simpl in *. trivial.
apply beq_nat_false in Hnotnull2.
unfold not;intros; apply Hnotnull2; clear Hk; subst;trivial.
assert(CIndex idx1 =  idx1) as Hcidx.
apply indexEqId.
rewrite Hcidx; trivial.
assert ( In p  (getTablePages root tableSize s)) as Hproot.
apply readPhyEntryInGetTablePages with idx2; trivial.
destruct idx2. simpl in *. trivial.
apply beq_nat_false in Hnotnull1.
unfold not;intros; apply Hnotnull1;
clear Hk; subst;trivial.
assert(CIndex idx2 =  idx2) as Hcidx.
apply indexEqId. rewrite Hcidx. trivial.
move Hnodup2 at bottom.
clear Hnoduproot Hk.
induction (getTablePages root tableSize s);  [
now contradict Hproot | ].
simpl in *.
destruct Hproot as [Hproot | Hproot];
destruct Hp0root as [Hp0root | Hp0root]; subst.
+ subst. now contradict Hp0p.
+ apply NoDupSplitInclIff in Hnodup2.
  destruct Hnodup2 as ((Hnodup1 & Hnodup2) & Hdisjoint).
  unfold disjoint in Hdisjoint. subst. clear IHl.
  generalize (Hdisjoint x Hxp);clear Hdisjoint; intros Hdisjoint.
  apply notInFlatMapNotInGetIndirection with l; trivial.
+ apply NoDupSplitInclIff in Hnodup2.
  destruct Hnodup2 as ((Hnodup1 & Hnodup2) & Hdisjoint).
  unfold disjoint in Hdisjoint. subst.
  unfold not. intros Hxp0. contradict Hxp.
  generalize (Hdisjoint x Hxp0);clear Hdisjoint; intros Hdisjoint.
  apply notInFlatMapNotInGetIndirection with l; trivial.
+ apply IHl; trivial.
  apply NoDupSplit in Hnodup2.
  destruct Hnodup2. assumption.
Qed.

Lemma getIndirectionInGetIndirectionAuxMinus1 table (p: page) s n va1 pred n1 (level1 : level):
level1> 0 ->
(Nat.eqb defaultPage p) = false ->
level1 <= CLevel (n -1) ->
StateLib.Level.pred level1 = Some pred ->
table <> defaultPage ->
n <= nbLevel ->
n > 1 ->
getIndirection p va1 pred n1 s = Some table ->
In table (getIndirectionsAux p s (n - 1)).
Proof.
intros Hfstlevel Hnotnull Hlevel Hpred Hnotnullt Hnbl Hn Hind.
apply getIndirectionInGetIndirections
with va1 pred n1;trivial;  try lia.
  - apply levelPredMinus1 in Hpred; trivial.
    unfold CLevel in Hpred.
    case_eq(lt_dec (level1 - 1) nbLevel ); intros l Hl0;
    rewrite Hl0 in Hpred.
    simpl in *.
    inversion Hpred. subst.
    simpl in *.

    (* clear  Htableroot2 Htableroot1
    Hread2  Hread1 HNoDup2 HNoDup1
    Hnull1 Hnull2 Hnotnull2 Hnotnull1 Hroot2 Hroot1. *)
    unfold CLevel in *.
    destruct level1.
    simpl in *.

    case_eq (lt_dec (n - 1) nbLevel);
    intros ii Hii;  rewrite Hii in *.
    simpl in *.
    case_eq (lt_dec (n - 1 - 1) nbLevel);
    intros.
    simpl in *. lia. lia.
    case_eq (lt_dec (n - 1 - 1) nbLevel);
    intros.
    simpl in *. lia. lia.
    destruct level1.
    simpl in *. lia.
    unfold StateLib.Level.eqb.
    unfold CLevel.
    case_eq(lt_dec (n - 1) nbLevel ); intros;
    simpl in *.
    unfold fstLevel. unfold CLevel.
    case_eq(lt_dec 0 nbLevel).
    intros. simpl.
    apply NPeano.Nat.eqb_neq. lia.
    intros. assert (0 < nbLevel) by apply nbLevelNotZero.
    lia. lia.
  - apply beq_nat_false in Hnotnull. unfold not. intros.
    apply Hnotnull. subst. trivial.
Qed.

Lemma getTablePagesNoDup root (p p0 : page) idx1 idx2    s:
idx1 < tableSize -> idx2 < tableSize ->
NoDup (getTablePages root tableSize s) ->
StateLib.readPhyEntry root (CIndex idx1) (memory s) = Some p0 ->
StateLib.readPhyEntry root (CIndex idx2) (memory s) = Some p ->
(Nat.eqb idx1 idx2) = false ->
(Nat.eqb p defaultPage) = false ->
(Nat.eqb defaultPage p0) = false ->
p0 <> p.
Proof.
assert (H: tableSize <= tableSize) by lia; revert H.
generalize tableSize at 1 3 4 5  .
induction n.
+ intros. now contradict H0.
+ intros. simpl in *.
  apply beq_nat_false in H5.
  assert(Hdec : (idx1 = n /\ idx2 <> n) \/
          (idx2 = n /\ idx1 <> n) \/
          (idx1 <> n /\ idx2 <> n)). lia.
  destruct Hdec as [(Hdec1 & Hdec2) | [(Hdec1 & Hdec2) |(Hdec1 & Hdec2)]];
  subst.
  * unfold StateLib.readPhyEntry in H3. intros.
    case_eq (lookup root (CIndex n) (memory s) beqPage beqIndex);
    [ intros v Hv'| intros Hv'] ; rewrite Hv' in  *; [ | now contradict H3 ];
    destruct v; try now contradict H3. inversion H3. subst.
    subst.  clear IHn H3. rewrite PeanoNat.Nat.eqb_sym in H7.
    rewrite H7 in H2.
    apply NoDupSplitInclIff in H2.
    destruct H2 as ( (_ & _) & H2).
    unfold disjoint in H2.
    assert (In p (getTablePages root n s)).
    apply readPhyEntryInGetTablePages with idx2; trivial.
    lia. lia.
    unfold not. intros. subst. apply beq_nat_false in H6.
    now contradict H6.
    apply H2 in H3. unfold not. intros.
    contradict H3. simpl in *. left. assumption.
  * unfold StateLib.readPhyEntry in H4. intros.
    case_eq (lookup root (CIndex n) (memory s) beqPage beqIndex);
    [ intros v Hv'| intros Hv'] ; rewrite Hv' in  *; [ | now contradict H4 ];
    destruct v; try now contradict H4. inversion H4. subst.
    subst.  clear IHn H4. rewrite H6 in H2.
    apply NoDupSplitInclIff in H2.
    destruct H2 as ( (_ & _) & H2).
    unfold disjoint in H2.
    assert (In p0 (getTablePages root n s)).
    apply readPhyEntryInGetTablePages with idx1; trivial.
    lia. lia.
    unfold not. intros. subst. apply beq_nat_false in H7.
    now contradict H7.
    apply H2 in H4. unfold not. intros.
    contradict H4. simpl in *. left. rewrite H8. trivial.
  *  case_eq (lookup root (CIndex n) (memory s) beqPage beqIndex);
    [ intros v Hv'| intros Hv'] ; rewrite Hv' in  *;

    [ |
    apply IHn; trivial;try lia;
    apply PeanoNat.Nat.eqb_neq; trivial ].
    destruct v; apply IHn;
                try assumption;
                try apply PeanoNat.Nat.eqb_neq; try assumption;
                try lia.
    case_eq(Nat.eqb defaultPage (pa p1)); intros Hnull; rewrite PeanoNat.Nat.eqb_sym in Hnull ; rewrite Hnull in *; trivial.
    apply NoDupSplitInclIff in H2; intuition.
Qed.

Lemma getTablePagesNoDupFlatMap s n k root:
n > 0 ->
NoDup
(flat_map (fun p : page => getIndirectionsAux p s n)
(getTablePages root k s)) ->
NoDup (getTablePages root k s).
Proof.
induction (getTablePages root k s).
simpl in *. trivial.
simpl.
intros Hn H.
apply NoDup_cons_iff.
apply NoDupSplitInclIff in H.
destruct H as((H1 & H2) & H3).
split.
unfold disjoint in *.
generalize (H3 a ); clear H3; intros H3.
assert (~ In a (flat_map (fun p : page => getIndirectionsAux p s n) l)).
apply H3; trivial.
destruct n. simpl in *. lia.
simpl. left. trivial.
unfold not. contradict H.
apply in_flat_map. exists a.
split. assumption. destruct n; simpl. now contradict Hn.
left. trivial.
apply IHl; trivial.
Qed.

   Lemma getIndirectionGetTableRoot2 (s : state) sh2 currentPart pt va
nbL :
StateLib.getSndShadow currentPart (memory s) = Some sh2 ->
StateLib.getNbLevel = Some nbL ->
(forall idx : index,
  StateLib.getIndexOfAddr va fstLevel = idx ->
  isVA pt idx s /\
  getTableAddrRoot pt sh2idx currentPart va s)
  ->
getIndirection sh2 va nbL (nbLevel - 1) s = Some pt.
Proof.
intros.
destruct H1 with (StateLib.getIndexOfAddr va fstLevel );
trivial.
clear H1.
unfold getTableAddrRoot in *.
destruct H3 as (_ & H3).
rewrite <- nextEntryIsPPgetSndShadow in *.
apply H3 in H.
clear H3.
destruct H as (nbl & HnbL & stop & Hstop & Hind).
subst.
rewrite H0 in HnbL.
inversion HnbL;subst.
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
symmetry in H0.
apply getNbLevelEq in H0.
subst.
apply nbLevelEq.
Qed.

Lemma pageTablesOrIndicesAreDifferent (root1 root2 table1 table2 : page )
(va1 va2 : vaddr) (level1 : level)  (stop : nat)  s:
root1 <> defaultPage -> root2 <> defaultPage ->
NoDup (getIndirections root1 s) ->
NoDup (getIndirections root2 s) ->
StateLib.checkVAddrsEqualityWOOffset stop va1 va2 level1 = false ->
( (level1 = CLevel (nbLevel -1) /\ root1 = root2) \/ (level1 < CLevel (nbLevel -1) /\(
(disjoint (getIndirections root1 s) (getIndirections root2 s)/\ root1 <> root2) \/ root1 = root2  )) )->
table1 <> defaultPage ->
table2 <> defaultPage ->
(* stop > 0 ->  *)
getIndirection root1 va1 level1 stop s = Some table1->
getIndirection root2 va2 level1 stop s = Some table2 ->
table1 <> table2 \/ StateLib.getIndexOfAddr va1 fstLevel <> StateLib.getIndexOfAddr va2 fstLevel.
Proof.
intros Hroot1 Hroot2 HNoDup1 HNoDup2 Hvas  Hlevel
Hnotnull1 Hnotnull2  (* Hstop *) Htableroot1    Htableroot2.
assert (StateLib.Level.eqb level1 fstLevel = true \/ StateLib.Level.eqb level1 fstLevel = false).
{ unfold StateLib.Level.eqb.
        rewrite NPeano.Nat.eqb_eq.  rewrite NPeano.Nat.eqb_neq.
        lia. }
assert(StateLib.getIndexOfAddr va1 fstLevel <> StateLib.getIndexOfAddr va2 fstLevel \/
StateLib.getIndexOfAddr va1 fstLevel = StateLib.getIndexOfAddr va2 fstLevel).
{ destruct (StateLib.getIndexOfAddr va1 fstLevel), (StateLib.getIndexOfAddr va2 fstLevel ) .
  assert (i = i0 \/ i<> i0). lia.
  destruct H0. subst.
  assert(Hi = Hi0) by apply proof_irrelevance. subst.
  right. reflexivity. left. trivial.
  unfold not. intros. apply H0.
  clear H0. inversion H1. trivial. }
destruct H0; [right; assumption |].
destruct H.
+ destruct stop. simpl in *.
 now contradict Hvas.
  simpl in Hvas. right.
  rewrite H in Hvas.
  apply beq_nat_false in Hvas.
  apply levelEqBEqNatTrue in H. subst. unfold not.
  intros. contradict Hvas. rewrite H. reflexivity.
+ clear H.
  revert HNoDup1 HNoDup2 Hvas Hlevel Hnotnull1 Hnotnull2
  Htableroot1 (* Hstop *) Htableroot2 H0 Hroot1 Hroot2 .
  revert root1 root2 table1 table2 level1 va1 va2.
  assert (Hs :stop <= stop). lia. revert Hs.
  generalize stop at 1 3 4 5 .
  intros.
  destruct stop0.
  simpl in *.
  now contradict Hvas.
  assert (nbLevel <= nbLevel) as Hnbl by lia.
  revert Hnbl.
  revert HNoDup1 HNoDup2 Hvas Hlevel Hnotnull1 Hnotnull2
  Htableroot1 (* Hstop *) Htableroot2 H0 Hs Hroot1 Hroot2 (* Hroot12 *).
  revert root1 root2 table1 table2 level1 va1 va2 stop.
  unfold getIndirections.
  generalize nbLevel at 1 2 3 4 5 6 7.
  induction (S stop0).
  intros. simpl in *. now contradict Hvas.
  intros.
  simpl in *.
  case_eq (StateLib.Level.eqb level1 fstLevel); intros . rewrite H in *.
  - contradict Hvas.
    apply levelEqBEqNatTrue in H. subst.
    unfold not.
    intros. apply beq_nat_false in H.  contradict H. rewrite H0. reflexivity.
  - rewrite H in *.
    clear H.
    case_eq (StateLib.readPhyEntry root1 (StateLib.getIndexOfAddr va1 level1) (memory s)) ;
    [intros p Hread1 | intros Hread1];
    rewrite Hread1 in *; [ | inversion Htableroot1].
    case_eq (StateLib.readPhyEntry root2 (StateLib.getIndexOfAddr va2 level1) (memory s) );
    [intros p0 Hread2 | intros Hread2];
    rewrite Hread2 in *; [ | inversion Htableroot2].
    case_eq (Nat.eqb defaultPage p); intros Hnull1;
    rewrite Hnull1 in *.
    inversion Htableroot1.
    subst. now contradict Hnotnull1.
    case_eq (Nat.eqb defaultPage p0); intros Hnull2;
    rewrite Hnull2 in *.
    inversion Htableroot2.
    subst. now contradict Hnotnull2.
    case_eq(StateLib.Level.pred level1); [intros pred Hpred | intros Hpred];  rewrite Hpred in *;
    [ | inversion Htableroot1].
    case_eq (Nat.eqb (StateLib.getIndexOfAddr va1 level1)
                     (StateLib.getIndexOfAddr va2 level1)
            );intros Hidx;
            rewrite Hidx in Hvas; trivial.
    * generalize (IHn (n0 -1) p p0 table1 table2 pred va1 va2 stop); clear IHn; intros IHn.
      assert (StateLib.Level.eqb level1 fstLevel = true \/ StateLib.Level.eqb level1 fstLevel = false).
      { unfold StateLib.Level.eqb.
        rewrite NPeano.Nat.eqb_eq.  rewrite NPeano.Nat.eqb_neq.
        lia. }
      destruct H.
      { apply levelEqBEqNatTrue in H. subst.
        unfold StateLib.Level.pred in Hpred.
        unfold fstLevel in Hpred.
        unfold CLevel in Hpred.
        case_eq (lt_dec 0 nbLevel ); intros;
        rewrite H in Hpred; [simpl in *;inversion Hpred |
        assert (0 < nbLevel) by apply nbLevelNotZero;
        now contradict H1]. }
      { apply IHn;trivial; try lia; clear IHn.
        + apply nodupLevelMinus1  with root1 (StateLib.getIndexOfAddr va1 level1); trivial.
          apply beq_nat_false in Hnull1.
          unfold not. intros.
          contradict Hnull1. subst. trivial.
        + apply nodupLevelMinus1  with root2 (StateLib.getIndexOfAddr va2 level1); trivial.
          apply beq_nat_false in Hnull2.
          unfold not. intros.
          contradict Hnull2. subst. trivial.
        + destruct Hlevel as [(Hlevel& Hroot) | Hlevel ].
          - left.
            split.
            apply levelPredMinus1 in Hpred; trivial.
            unfold CLevel in Hpred.
            case_eq(lt_dec (level1 - 1) nbLevel ); intros;
            rewrite H1 in Hpred.
            destruct level1. simpl in *.
            destruct pred.
            inversion Hpred. subst.
            apply levelEqBEqNatFalse0 in H.
            simpl in *.
            clear Htableroot2 Htableroot1 Hvas Hidx
            Hread2  Hread1 HNoDup2 HNoDup1
            Hnull1 Hnull2 Hnotnull2 Hnotnull1 Hroot2 Hroot1.
            unfold CLevel in *.
            case_eq (lt_dec (n0 - 1) nbLevel);
            intros; rewrite H2 in *.
            simpl in *.
            case_eq (lt_dec (n0 - 1 - 1) nbLevel);
            intros.
            inversion Hlevel. subst.
            assert(Hl0 = ADT.CLevel_obligation_1 (n0 - 1 - 1) l2 ) by apply proof_irrelevance.
            subst. reflexivity.
            simpl in *. lia. lia.
            destruct level1.
            simpl in *.
            lia.
            subst.
            apply beq_nat_true in Hidx.
            destruct (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1))).
            destruct (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1))).
            simpl in *.
            subst. assert (Hi = Hi0) by apply proof_irrelevance.
            subst. rewrite Hread1 in Hread2.
            inversion Hread2. trivial.
          - destruct Hlevel as (Hlevellt &  [(Hlevel & Hll) | Hlevel ]).
            * right. split.
              { apply levelPredMinus1 in Hpred; trivial.
                unfold CLevel in Hpred.
                case_eq(lt_dec (level1 - 1) nbLevel ); intros;
                rewrite H1 in Hpred.
                destruct level1. simpl in *.
                inversion Hpred. subst.
                apply levelEqBEqNatFalse0 in H.
                simpl in *.
                clear H2 Htableroot2 Htableroot1 Hvas Hidx
                Hread2  Hread1 Hlevel HNoDup2 HNoDup1 H0
                Hnull1 Hnull2 Hnotnull2 Hnotnull1 Hroot2 Hroot1.
                unfold CLevel in *.
                case_eq (lt_dec (n0 - 1) nbLevel);
                intros; rewrite H0 in *.
                simpl in *.
                case_eq (lt_dec (n0 - 1 - 1) nbLevel);
                intros.
                simpl in *.

                  lia. lia.
                case_eq (lt_dec (n0 - 1 - 1) nbLevel);
                intros.
                simpl in *. lia. lia.
                destruct level1. simpl in *. lia. }
              { assert (n0 <= 1 \/ n0 > 1) as Hn0. lia.
                destruct Hn0.
                apply levelEqBEqNatFalse0 in H.
                assert (CLevel
                (n0 - 1) > 1).
                lia.
                contradict H1.
                unfold CLevel in Hlevellt, H2.
                case_eq ( lt_dec (n0 - 1) nbLevel); intros;  rewrite H1 in *;
                simpl in *. lia.
                apply le_lt_or_eq in Hnbl.
                destruct Hnbl.
                lia.
                assert (n0 > 0).
                assert (0 < nbLevel) by apply nbLevelNotZero.
                lia.
                lia.
                left. split.
                apply inclDisjoint with (getIndirectionsAux root1 s n0) (getIndirectionsAux root2 s n0); trivial.
                apply inclGetIndirectionsAuxMinus1 with (StateLib.getIndexOfAddr va1 level1); trivial.
                apply inclGetIndirectionsAuxMinus1 with (StateLib.getIndexOfAddr va2 level1); trivial.
                assert (In p (getIndirectionsAux root1 s n0) ) as Hp.
                apply readPhyEntryInGetIndirectionsAux; trivial.
                apply beq_nat_false in Hnull1. unfold not. contradict Hnull1.
                subst. trivial.
                apply readPhyEntryInGetTablePages with (StateLib.getIndexOfAddr va1 level1); trivial.
                destruct (StateLib.getIndexOfAddr va1 level1 ); simpl in *; trivial.
                apply beq_nat_false in Hnull1. unfold not. contradict Hnull1.
                subst. trivial.
                assert ((StateLib.getIndexOfAddr va1 level1) = (CIndex (StateLib.getIndexOfAddr va1 level1))).
                symmetry. apply indexEqId. rewrite <- H2. assumption.
                generalize(Hlevel p  Hp); intros Hpage0.
                assert (In p0 (getIndirectionsAux root2 s n0) ) as Hp0.
                apply readPhyEntryInGetIndirectionsAux; trivial.
                apply beq_nat_false in Hnull2. unfold not. contradict Hnull2.
                subst. trivial.
                apply readPhyEntryInGetTablePages with (StateLib.getIndexOfAddr va2 level1); trivial.
                destruct (StateLib.getIndexOfAddr va2 level1 ); simpl in *; trivial.
                apply beq_nat_false in Hnull2. unfold not. contradict Hnull2.
                subst. trivial.
                assert ((StateLib.getIndexOfAddr va2 level1) = (CIndex (StateLib.getIndexOfAddr va2 level1))) as Hcidx.
                symmetry. apply indexEqId. rewrite <- Hcidx. assumption.
                destruct (getIndirectionsAux root2 s n0). simpl in *. now contradict Hp0.
                simpl in *. unfold not in *.
                intros. apply Hpage0.
                destruct Hp0. subst. left. trivial.
                subst.
                right; trivial. }
            * right. split.
              apply levelPredMinus1 in Hpred; trivial.
              unfold CLevel in Hpred.
              case_eq(lt_dec (level1 - 1) nbLevel ); intros;
              rewrite H1 in Hpred.
              destruct level1. simpl in *.
              inversion Hpred. subst.
              apply levelEqBEqNatFalse0 in H.
              simpl in *.
              clear H2 Htableroot2 Htableroot1 Hvas Hidx
              Hread2  Hread1 HNoDup2 HNoDup1 H0
              Hnull1 Hnull2 Hnotnull2 Hnotnull1 Hroot2 Hroot1.
              unfold CLevel in *.
              case_eq (lt_dec (n0 - 1) nbLevel);
              intros; rewrite H0 in *.
              simpl in *.
              case_eq (lt_dec (n0 - 1 - 1) nbLevel);
              intros.
              simpl in *. lia. lia.
              case_eq (lt_dec (n0 - 1 - 1) nbLevel);
              intros;
              simpl in *. contradict H0. lia. lia.
              destruct level1. simpl in *. lia.
              right.
              subst.
              apply beq_nat_true in Hidx.
              destruct (StateLib.getIndexOfAddr va2 level1).
              destruct (StateLib.getIndexOfAddr va1 level1).
              simpl in *.
              subst. assert (Hi = Hi0) by apply proof_irrelevance.
              subst. rewrite Hread1 in Hread2.
              inversion Hread2. trivial.
        + apply beq_nat_false in Hnull1.
          unfold not. intros.
          contradict Hnull1. subst. trivial.
        + apply beq_nat_false in Hnull2.
          unfold not. intros.
          contradict Hnull2. subst. trivial. }
    * clear IHn.
      left. clear stop0 stop (* Hstop *) Hs Hvas .
      destruct Hlevel as [(Hlevel& Hroot) | (Hlevel& [(Hroot & Heq) | Hroot] ) ]; subst.
      { assert (n0 <= 1 \/ n0 > 1) as Hn0. lia.
        destruct Hn0 as [Hn0 | Hn0].
        + assert(n0 = 0 \/ n0 =1) as Hn01. lia.
          destruct Hn01;subst;  simpl in *;
          unfold StateLib.Level.pred in *; [
          case_eq(gt_dec (CLevel 0) 0 ); intros g Hnb0;rewrite Hnb0 in Hpred;
          [ | now contradict Hpred];
          unfold CLevel in g |].
          case_eq (lt_dec 0 nbLevel); intros nbl0 Hnbl0;
          [ |
          assert(0 < nbLevel) by apply nbLevelNotZero; lia].
          clear Hpred Hnb0.
          rewrite Hnbl0 in *; simpl in *.  now contradict g.
          case_eq(gt_dec (CLevel 0) 0 ); intros g Hnb0;rewrite Hnb0 in Hpred;
          [ |
          now contradict Hpred].
          unfold CLevel in g.
          case_eq (lt_dec 0 nbLevel); intros nbl0 Hnbl0; [ |
          assert(0 < nbLevel) by apply nbLevelNotZero; lia].
          clear Hpred Hnb0.
          rewrite Hnbl0 in *; simpl in *.  now contradict g.
       + assert( p0 <> p).
          { apply getTablePagesNoDup with root2 (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1)))
          (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1))) s; trivial.
          destruct (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1))). simpl in *; trivial.
          destruct (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1))). simpl in *; trivial.
          destruct n0; [now contradict Hn0 |].
          simpl in HNoDup2. apply NoDup_cons_iff in HNoDup2.
          destruct HNoDup2 as (_ & HNoDup2).
          apply getTablePagesNoDupFlatMap  with n0; trivial. lia.
          assert (H :(CIndex (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1)))) =
          (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1)))).
          apply indexEqId. rewrite H; trivial.
          assert (H2 :(CIndex (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1)))) =
          (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1)))).
          apply indexEqId. rewrite H2. trivial.
          apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in Hidx.
          apply beq_nat_false in Hidx. now contradict Hidx.
          apply beq_nat_false in Hnull1.
          apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in *.
          now contradict Hnull1. }

(*           apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in *. *)
(*           apply beq_nat_false in Hnull2. now contradict Hnull2. } *)
        assert( disjoint (getIndirectionsAux p s (n0 -1))
       (getIndirectionsAux p0 s (n0 -1))) as Hdisjoint.
         apply disjointGetIndirectionsAuxMiddle with root2
         (StateLib.getIndexOfAddr va2 (CLevel (n0 - 1)))
         (StateLib.getIndexOfAddr va1 (CLevel (n0 - 1))) ; trivial.
         assert (In table1 (getIndirectionsAux  p s (n0 -1))) as Htbl1p.
         apply getIndirectionInGetIndirectionAuxMinus1 with va1 pred n (CLevel (n0 - 1)); trivial.
         unfold CLevel.
         case_eq( lt_dec (n0 - 1) nbLevel). intros. simpl.
         lia.
         intros.
         contradict H1. lia.
         assert (In table2 (getIndirectionsAux  p0 s (n0 -1))) as Htb2p0.
         apply getIndirectionInGetIndirectionAuxMinus1 with va2 pred n (CLevel (n0 - 1)); trivial.
         unfold CLevel.
         case_eq( lt_dec (n0 - 1) nbLevel). intros. simpl.
         lia.
         intros.
         contradict H1. lia.
         unfold disjoint in *.
         apply Hdisjoint in Htbl1p.
         unfold not. intros.
         apply Htbl1p. subst.
         assumption. }
      { assert (n0 <= 1 \/ n0 > 1) as Hn0. lia.
        destruct Hn0 as [Hn0 | Hn0].
        + assert(n0 = 0 \/ n0 =1) as Hn01. lia.
          destruct Hn01;subst;  simpl in *;
          destruct level1; simpl in *;
          unfold CLevel in Hlevel;
          case_eq ( lt_dec 0 nbLevel); intros; rewrite H in *;
          simpl in *; lia.
        +  assert (level1 > 0).
             {unfold StateLib.Level.pred in *.
         case_eq (  gt_dec level1 0) ; intros;
         rewrite H in *.
         inversion Hpred.
         destruct pred.
         destruct level1. simpl in *.
         inversion H2. lia.
         inversion Hpred.
         }
        assert (In table1 (getIndirectionsAux  p s (n0 -1))) as Htbl1p.
         apply getIndirectionInGetIndirectionAuxMinus1 with va1 pred n level1; trivial.
         lia.
          assert (In table2 (getIndirectionsAux  p0 s (n0 -1))) as Htbl2p0.
         apply getIndirectionInGetIndirectionAuxMinus1 with va2 pred n level1; trivial.
          lia.

          apply inclGetIndirectionsAuxMinus1 with n0 root1 (StateLib.getIndexOfAddr va1 level1)
           p s in Hread1; trivial.
           apply inclGetIndirectionsAuxMinus1 with n0 root2 (StateLib.getIndexOfAddr va2 level1)
           p0 s in Hread2; trivial.
           unfold incl, disjoint in *.
           apply Hread1 in Htbl1p.
           apply Hread2 in Htbl2p0.
           apply Hroot in Htbl1p.
           unfold not. intros.
           apply Htbl1p. subst.
           assumption.
            }
        { assert (n0 <= 1 \/ n0 > 1) as Hn0. lia.
        destruct Hn0 as [Hn0 | Hn0].
        + assert(n0 = 0 \/ n0 =1) as Hn01. lia.
        destruct Hn01;subst;  simpl in *;
          destruct level1; simpl in *;
          unfold CLevel in Hlevel;
          case_eq ( lt_dec 0 nbLevel); intros; rewrite H in *;
          simpl in *; lia.

       + assert( p0 <> p).
         { apply getTablePagesNoDup with root2 (StateLib.getIndexOfAddr va2 level1)
          (StateLib.getIndexOfAddr va1 level1) s; trivial.
          destruct (StateLib.getIndexOfAddr va2 level1). simpl in *; trivial.
          destruct (StateLib.getIndexOfAddr va1 level1). simpl in *; trivial.
          destruct n0; [now contradict Hn0 |].
          simpl in HNoDup2. apply NoDup_cons_iff in HNoDup2.
          destruct HNoDup2 as (_ & HNoDup2).
          apply getTablePagesNoDupFlatMap  with n0; trivial. lia.
          assert (H :(CIndex (StateLib.getIndexOfAddr va2 level1)) =
          (StateLib.getIndexOfAddr va2 level1)).
          apply indexEqId. rewrite H; trivial.
          assert (H2 :(CIndex (StateLib.getIndexOfAddr va1 level1)) =
          (StateLib.getIndexOfAddr va1 level1)).
          apply indexEqId. rewrite H2. trivial.
          apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in Hidx.
          apply beq_nat_false in Hidx. now contradict Hidx.
          apply beq_nat_false in Hnull1.
          apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in *.
          now contradict Hnull1. }
(*           apply NPeano.Nat.eqb_neq. unfold not. intros. rewrite H in *. *)
(*           apply beq_nat_false in Hnull2. now contradict Hnull2. } *)
      assert( disjoint (getIndirectionsAux p s (n0 -1))
       (getIndirectionsAux p0 s (n0 -1))) as Hdisjoint.
         apply disjointGetIndirectionsAuxMiddle with root2
         (StateLib.getIndexOfAddr va2 level1)
         (StateLib.getIndexOfAddr va1 level1) ; trivial.
         assert (In table1 (getIndirectionsAux  p s (n0 -1))) as Htbl1p.
         apply getIndirectionInGetIndirectionAuxMinus1 with va1 pred n level1; trivial.
         unfold StateLib.Level.pred in *.
         case_eq (  gt_dec level1 0) ; intros;
         rewrite H1 in *.
         inversion Hpred.
         destruct pred.
         destruct level1. simpl in *.
         inversion H3. lia.
         inversion Hpred.
         lia.
         assert (In table2 (getIndirectionsAux  p0 s (n0 -1))) as Htb2p0.
         apply getIndirectionInGetIndirectionAuxMinus1 with va2 pred n level1; trivial.
         unfold StateLib.Level.pred in *.
         case_eq (  gt_dec level1 0) ; intros;
         rewrite H1 in *.
         inversion Hpred.
         destruct pred.
         destruct level1. simpl in *.
         inversion H3. lia.
         inversion Hpred.
         lia.
         unfold disjoint in *.
         apply Hdisjoint in Htbl1p.
         unfold not. intros.
         apply Htbl1p. subst.
         assumption. }
Qed.
Lemma noDupConfigPagesListNoDupGetIndirections  s:
partitionDescriptorEntry s ->
forall (partition : page),
In partition (getPartitions multiplexer s) ->
NoDup (getConfigPages partition s) ->
forall root idxroot, (idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx) ->
nextEntryIsPP partition idxroot root s->
 NoDup (getIndirections root s).
 Proof.
 intros Hpde partition Hpart Hnodup root idx Hidx Hpp.
 unfold getConfigPages in *.
 apply NoDup_cons_iff in Hnodup as (Hnotin & Hnodup).
 unfold getConfigPagesAux in Hnodup.
   unfold consistency in *.
  assert (Hroots :
   (exists pd , StateLib.getPd partition (memory s) = Some pd /\
    pd <> defaultPage) /\
   (exists sh1, StateLib.getFstShadow partition (memory s) = Some sh1 /\
    sh1 <> defaultPage) /\
   (exists sh2, StateLib.getSndShadow partition (memory s) = Some sh2 /\
    sh2 <> defaultPage) /\
   (exists list, StateLib.getConfigTablesLinkedList partition (memory s) = Some list /\
    list <> defaultPage)).
  apply pdSh1Sh2ListExistsNotNull; trivial.
  destruct Hroots as ((pd & Hpd & Hpdnotnull)
  & (sh1 & Hsh1 & Hsh1notnull) & (sh2 & Hsh2 & Hsh2notnull) &
  (sh3 & Hsh3 & Hsh3notnull)).
  rewrite Hpd, Hsh1, Hsh2, Hsh3 in *.
  apply NoDupSplitInclIff in Hnodup as ((Hi1 & Hnodup) & _).
  apply NoDupSplitInclIff in Hnodup as ((Hi2 & Hnodup) & _).
  apply NoDupSplitInclIff in Hnodup as ((Hi3 & Hnodup) & _).
  destruct Hidx as [Hpdroot | [Hsh1root | Hsh2root]];subst.
  assert(root = pd).
  apply getPdNextEntryIsPPEq with partition s;trivial.
  subst;trivial.
  assert(root = sh1).
  apply getSh1NextEntryIsPPEq with partition s;trivial.
  subst;trivial.
  assert(root = sh2).
  apply getSh2NextEntryIsPPEq with partition s;trivial.
  subst;trivial.
 Qed.

Lemma toApplyPageTablesOrIndicesAreDifferent idx1 idx2 va1 va2 (table1 table2 : page)
currentPart root idxroot level1 F s:
(idxroot = PDidx \/ idxroot = sh1idx \/ idxroot = sh2idx) ->
(Nat.eqb defaultPage table1) = false -> (Nat.eqb defaultPage table2) = false ->
false = StateLib.checkVAddrsEqualityWOOffset nbLevel va1 va2 level1 ->
currentPart = currentPartition s ->
consistency s ->
StateLib.getIndexOfAddr va1 fstLevel = idx1 ->
StateLib.getIndexOfAddr va2 fstLevel = idx2 ->
(forall idx : index,
StateLib.getIndexOfAddr va1 fstLevel = idx ->
F table1 idx s /\ getTableAddrRoot table1 idxroot currentPart va1 s) ->
(forall idx : index,
StateLib.getIndexOfAddr va2 fstLevel = idx ->
F table2 idx s /\ getTableAddrRoot table2 idxroot currentPart va2 s) ->
nextEntryIsPP currentPart idxroot root s ->
Some level1 = StateLib.getNbLevel ->
table1 <> table2 \/ idx1 <> idx2.
Proof.
 intros Hor Hnotnull1 Hnotnull2 Hvas Hcurpart Hcons Hva1 Hva2 Htable1 Htable2 Hroot Hlevel.
 rewrite <- Hva1.
  rewrite <- Hva2.
  apply Htable1 in Hva1.
  apply Htable2 in Hva2.
  unfold getTableAddrRoot in *.
  destruct Hva1 as (Hpe1 & Hor1 & Htableroot1).
  destruct Hva2 as (Hpe2 & Hor2 & Htableroot2).
  generalize (Htableroot1 root Hroot); clear Htableroot1;intros Htableroot1.
  generalize (Htableroot2 root Hroot); clear Htableroot2;intros Htableroot2.
  destruct Htableroot1 as (nbl1 & Hnbl1 & stop1 & Hstop1 & Hind1).
  destruct Htableroot2 as (nbl2 & Hnbl2 & stop2 & Hstop2 & Hind2).
  rewrite <- Hlevel in Hnbl1.
  inversion Hnbl1 as [Hi0].
  rewrite <- Hlevel in Hnbl2.
  inversion Hnbl2 as [Hi1 ].
  rewrite Hi1 in Hind2.
  rewrite Hi0 in Hind1.
  rewrite Hi1 in Hstop2.
  rewrite Hi0 in Hstop1.
  rewrite <- Hstop2 in Hstop1.
  rewrite Hstop1 in Hind1.
  clear Hstop1 Hnbl2 Hnbl1 .
   apply  pageTablesOrIndicesAreDifferent with root root
  level1 stop2 s; trivial.
  - unfold consistency in *.
    destruct Hcons.
    unfold partitionDescriptorEntry in *.
    assert (currentPartitionInPartitionsList s ) as Hpr by intuition.
    unfold currentPartitionInPartitionsList in *.
    subst.
    generalize (H  (currentPartition s)  Hpr); clear H; intros H.
    assert (idxroot = PDidx \/
      idxroot = sh1idx \/ idxroot = sh2idx \/ idxroot = sh3idx \/ idxroot = PPRidx
      \/ idxroot = PRidx) as Hpd .
    intuition.
    apply H in Hpd.
    destruct Hpd as (_ & _ & Hpd).
    destruct Hpd as (pd & Hrootpd & Hnotnul).
    move Hroot at bottom.
    move Hrootpd  at bottom.
    move Hnotnul at bottom.
    unfold nextEntryIsPP in Hroot , Hrootpd.
    destruct (StateLib.Index.succ idxroot); try now contradict Hrootpd.
    destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex); try now contradict Hroot.
    destruct v; try now contradict Hrootpd.
    subst. assumption.
  - unfold consistency in *.
    destruct Hcons.
    unfold partitionDescriptorEntry in *.
    assert (currentPartitionInPartitionsList s ) as Hpr by intuition.
    unfold currentPartitionInPartitionsList in *.
    subst.
    generalize (H  (currentPartition s)  Hpr); clear H; intros H.
    assert (idxroot = PDidx \/
      idxroot = sh1idx \/ idxroot = sh2idx \/ idxroot = sh3idx \/ idxroot = PPRidx
      \/ idxroot = PRidx) as Hpd .
    intuition.
    apply H in Hpd.
    destruct Hpd as (_ & _ & Hpd).
    destruct Hpd as (pd & Hrootpd & Hnotnul).
    move Hroot at bottom.
    move Hrootpd  at bottom.
    move Hnotnul at bottom.
    unfold nextEntryIsPP in Hroot , Hrootpd.
    destruct (StateLib.Index.succ idxroot); try now contradict Hrootpd.
    destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex); try now contradict Hroot.
    destruct v; try now contradict Hrootpd.
    subst. assumption.
  - unfold consistency in Hcons.
    assert(Hpde : partitionDescriptorEntry s) by intuition.
    assert(Hdup :   noDupConfigPagesList s) by intuition.
    assert(Hcurprt : currentPartitionInPartitionsList s ) by intuition.
    apply noDupConfigPagesListNoDupGetIndirections with (currentPartition s) idxroot;trivial.
    apply Hdup;trivial.
    subst. trivial.
  - unfold consistency in Hcons.
    assert(Hpde : partitionDescriptorEntry s) by intuition.
    assert(Hdup :   noDupConfigPagesList s) by intuition.
    assert(Hcurprt : currentPartitionInPartitionsList s ) by intuition.
    apply noDupConfigPagesListNoDupGetIndirections with (currentPartition s) idxroot;trivial.
    apply Hdup;trivial.
    subst. trivial.
  - move Hlevel at bottom.
    unfold StateLib.getNbLevel in Hlevel.
     case_eq (gt_dec nbLevel 0 ); intros;
    rewrite H in Hlevel.
    rewrite Hstop2.
    inversion Hlevel.
    rewrite H1 in *. simpl.
    symmetry. assert( (nbLevel - 1 + 1)  = nbLevel).
    lia. rewrite H0.
    assumption.
    now contradict H.
  - left. split.
    unfold StateLib.getNbLevel in *.
    move Hlevel at bottom.
    unfold CLevel.
    case_eq (gt_dec nbLevel 0); intros.
    rewrite H in Hlevel.
    inversion Hlevel.
    case_eq(lt_dec (nbLevel - 1) nbLevel ); intros.
    subst.
    assert(MAL.getNbLevel_obligation_1 g  =  ADT.CLevel_obligation_1 (nbLevel - 1) l)
    by apply proof_irrelevance.
    rewrite H1. reflexivity. lia.
    assert (0 < nbLevel) by apply nbLevelNotZero. lia.
    trivial.
  - apply beq_nat_false in Hnotnull1.
    unfold not. intros.
    contradict Hnotnull1. subst. trivial.
  - apply beq_nat_false in Hnotnull2.
    unfold not. intros.
    contradict Hnotnull2. subst. trivial.
Qed.

Lemma getMappedPagesAuxConsSome :
forall pd va phyVa listva s,
getMappedPage pd s va = SomePage phyVa ->
 (getMappedPagesAux pd (va :: listva) s) =
 phyVa :: (getMappedPagesAux pd  listva) s.
Proof.
 intros pd va phyVa listva.
 revert   pd va phyVa.
 induction listva;intros;
   unfold getMappedPagesAux;
   unfold getMappedPagesOption.
   simpl.
   rewrite H;trivial.
 + simpl. rewrite H.
   trivial.
Qed.

Lemma getMappedPagesAuxConsNone :
 forall pd va listva s,
getMappedPage pd s va = NonePage ->
 (getMappedPagesAux pd (va :: listva) s) =(getMappedPagesAux pd  listva) s.
Proof.
intros pd va phyVa listva.
revert   pd va phyVa.
induction listva;intros;
unfold getMappedPagesAux;
unfold getMappedPagesOption.
simpl.
rewrite H;trivial.
Qed.

Lemma getMappedPagesAuxConsDefault :
 forall pd va listva s,
getMappedPage pd s va = SomeDefault ->
 (getMappedPagesAux pd (va :: listva) s) =(getMappedPagesAux pd  listva) s.
Proof.
intros pd va phyVa listva.
revert   pd va phyVa.
induction listva;intros;
unfold getMappedPagesAux;
unfold getMappedPagesOption.
simpl.
rewrite H;trivial.
Qed.


Lemma childIsMappedPage partition child s :
In partition (getPartitions multiplexer s) ->
In child (getChildren partition s) ->
In child (getMappedPages partition s).
Proof.
intros Hpart Hchild.
unfold getChildren in *.
unfold getMappedPages.
case_eq (StateLib.getNbLevel );[intros nbL HnbL|intros HnbL];rewrite HnbL in *;
try now contradict Hchild.
case_eq (StateLib.getPd partition (memory s) );[intros pd Hpd | intros Hpd];
rewrite Hpd in *; try now contradict Hpd.
unfold getMappedPagesAux in *.
rewrite filterOptionInIff in *.
unfold getMappedPagesOption in *.
rewrite in_map_iff in *.
destruct Hchild as (va & Hva1 & Hva2).
assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel va va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1i & Hva11).
exists va1;split;trivial.
rewrite <- Hva1.
symmetry.
apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.
Qed.

Lemma ancestorInPartitionTree s:
parentInPartitionList s ->
isChild s ->
forall partition ancestor ,
In partition (getPartitions multiplexer s) ->
In ancestor (getAncestors partition s) ->
In ancestor (getPartitions multiplexer s).
Proof.
intros Hparent HisChild.
unfold getAncestors.
induction (nbPage + 1);simpl;trivial.
intuition.
intros  partition ancestor Hi1 Hi2.
case_eq(StateLib.getParent partition (memory s) );intros;
rewrite H in *;
simpl in *.
+ destruct Hi2 as [Hi2 | Hi2].
  - subst.
    unfold parentInPartitionList in *.
    apply Hparent with partition;trivial.
    apply nextEntryIsPPgetParent;trivial.
  - apply IHn with p;trivial.
    unfold parentInPartitionList in *.
    apply Hparent with partition;trivial.
    apply nextEntryIsPPgetParent;trivial.
+  now contradict Hi2.
Qed.

Lemma getPartitionAuxSn s :
isChild s ->
forall n child parent ancestor,
In child (getPartitions multiplexer s) ->
StateLib.getParent child (memory s) = Some parent ->
In parent (getPartitionAux ancestor s n) ->
In child (flat_map (fun p : page => getPartitionAux p s n) (getChildren ancestor s)).
Proof.
intros Hchild .
induction n. simpl in *. intuition.
simpl.
intros.
destruct H1. subst.
rewrite  in_flat_map.
exists child.
split. unfold isChild in *.
apply Hchild;trivial.
simpl. left;trivial.
rewrite in_flat_map.
rewrite in_flat_map in H1.
destruct H1 as (x & Hx & Hxx).
exists x;split;trivial.
simpl.
right.
apply IHn with parent;trivial.
Qed.



Lemma getPartitionAuxSbound s bound :
forall partition1 partition2, In partition1 (getPartitionAux partition2 s bound) ->
In partition1 (getPartitionAux partition2 s (bound+1)).
Proof.
induction bound;simpl; intros.
now contradict H.
destruct H.
left ;trivial.
right.
rewrite in_flat_map in *.
destruct H as (x & Hx & Hxx).
exists x;split;trivial.
apply IHbound;trivial.
Qed.

Lemma idxSh2idxSh1notEq : sh2idx <> sh1idx. Proof.
unfold sh2idx. unfold sh1idx.
apply indexEqFalse ;
assert (tableSize > tableSizeLowerBound).
apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia.  apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia. apply tableSizeBigEnough. lia. Qed.

Lemma idxPDidxSh1notEq :
PDidx <> sh1idx.
Proof.
unfold PDidx. unfold sh1idx.
apply indexEqFalse ;
assert (tableSize > tableSizeLowerBound).
apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia.  apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia. apply tableSizeBigEnough. lia.
Qed.

Lemma rootStructNotNull root part s idxroot:
idxroot = PDidx \/
idxroot = sh1idx \/
idxroot = sh2idx \/ idxroot = sh3idx \/ idxroot = PPRidx \/ idxroot = PRidx ->
partitionDescriptorEntry s ->
nextEntryIsPP part idxroot root s ->
In part (getPartitions multiplexer s) ->
root <> defaultPage.
Proof.
intros.
unfold partitionDescriptorEntry in *.
assert((exists entry : page,
        nextEntryIsPP part idxroot entry s /\ entry <> defaultPage))
        as (entry & Hentry & Hdefault).
apply H0;trivial.
assert(entry = root).
unfold  nextEntryIsPP in *.
destruct (StateLib.Index.succ idxroot);try now contradict Hentry.
destruct(lookup part i (memory s) beqPage beqIndex);try now contradict Hentry.
destruct v;try now contradict Hentry.
subst;trivial.
subst.
trivial.
Qed.
 Lemma checkVAddrsEqualityWOOffsetTrue1 s phyDescChild vaChild va level:
      In va (getPdsVAddr phyDescChild level getAllVAddr s) ->
StateLib.checkVAddrsEqualityWOOffset nbLevel vaChild va level = true ->
StateLib.getNbLevel = Some level ->
In vaChild (getPdsVAddr phyDescChild level getAllVAddr s).
Proof.
      unfold getPdsVAddr.
      intros.
      rewrite filter_In in *.
      destruct H.
      split.
      apply AllVAddrAll.
      unfold checkChild in *.
      destruct (StateLib.getFstShadow phyDescChild (memory s) );trivial.
      assert(Hind : getIndirection p vaChild level (nbLevel - 1) s =
      getIndirection p va level (nbLevel - 1) s).
      apply getIndirectionEq;trivial.
      apply getNbLevelLt;trivial.
      rewrite Hind.
      destruct (getIndirection p va level (nbLevel - 1) s);trivial.
      destruct (Nat.eqb p0 defaultPage);trivial.
      assert (idxeq :  (StateLib.getIndexOfAddr vaChild fstLevel) =
      (StateLib.getIndexOfAddr va fstLevel)).
     apply checkVAddrsEqualityWOOffsetTrue' with nbLevel level;trivial .
    apply fstLevelLe.
    apply getNbLevelLt;trivial.
    rewrite idxeq;trivial.
Qed.





Lemma pdPartNotNull phyDescChild pdChildphy s:
In phyDescChild (getPartitions multiplexer s) ->
nextEntryIsPP phyDescChild PDidx pdChildphy s ->
partitionDescriptorEntry s ->
pdChildphy <> defaultPage.
Proof.
intros.
 unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild PDidx entry s /\ entry <> defaultPage)).
        apply H1;trivial.
        left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
assert(entryPd = pdChildphy).
apply getPdNextEntryIsPPEq  with phyDescChild s;trivial.
apply nextEntryIsPPgetPd;trivial.
subst;trivial.
Qed.
Lemma sh1PartNotNull phyDescChild pdChildphy s:
In phyDescChild (getPartitions multiplexer s) ->
nextEntryIsPP phyDescChild sh1idx pdChildphy s ->
partitionDescriptorEntry s ->
pdChildphy <> defaultPage.
Proof.
intros.
 unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild sh1idx entry s /\ entry <> defaultPage)).
        apply H1;trivial.
        right;left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
assert(entryPd = pdChildphy).
apply getSh1NextEntryIsPPEq with phyDescChild s;trivial.
apply nextEntryIsPPgetFstShadow;trivial.
subst;trivial.
Qed.

Lemma sh2PartNotNull phyDescChild pdChildphy s:
In phyDescChild (getPartitions multiplexer s) ->
nextEntryIsPP phyDescChild sh2idx pdChildphy s ->
partitionDescriptorEntry s ->
pdChildphy <> defaultPage.
Proof.
intros.
 unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild sh2idx entry s /\ entry <> defaultPage)).
        apply H1;trivial.
        do 2 right;left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
assert(entryPd = pdChildphy).
apply getSh2NextEntryIsPPEq with phyDescChild s;trivial.
apply nextEntryIsPPgetSndShadow;trivial.
subst;trivial.
Qed.

Lemma getConfigTablesRootNotNone phyDescChild s:
In phyDescChild (getPartitions multiplexer s) ->
partitionDescriptorEntry s ->
StateLib.getConfigTablesLinkedList phyDescChild (memory s) = None -> False.
Proof.
intros.
unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild sh3idx entry s /\ entry <> defaultPage)).
        apply H0;trivial.
        do 3 right;left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
apply nextEntryIsPPgetConfigList in Hpp.
rewrite Hpp in *.
now contradict H1.
Qed.

 Lemma sh2PartNotNone phyDescChild s:
In phyDescChild (getPartitions multiplexer s) ->
partitionDescriptorEntry s ->
StateLib.getSndShadow phyDescChild (memory s) = None -> False.
Proof.
intros.
unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild sh2idx entry s /\ entry <> defaultPage)).
        apply H0;trivial.
        do 2 right;left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
apply nextEntryIsPPgetSndShadow in Hpp.
rewrite Hpp in *.
now contradict H1.
Qed.

 Lemma sh1PartNotNone phyDescChild s:
In phyDescChild (getPartitions multiplexer s) ->
partitionDescriptorEntry s ->
StateLib.getFstShadow phyDescChild (memory s) = None -> False.
Proof.
intros.
unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild sh1idx entry s /\ entry <> defaultPage)).
        apply H0;trivial.
        do 1 right;left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
apply nextEntryIsPPgetFstShadow in Hpp.
rewrite Hpp in *.
now contradict H1.
Qed.
 Lemma configNotDefault s stop:
forall  pd ,
pd<> defaultPage ->
(stop+1) <= nbLevel ->
  ~ In defaultPage (getIndirectionsAux pd s stop).
  Proof.
  induction stop;simpl.
  intuition.
  simpl;intros.
  apply and_not_or.
  split;trivial.
  rewrite in_flat_map.
  contradict H.
  destruct H as (x & Hx & Hx1).
  apply NNPP.
  unfold not at 1.
  intros.
  contradict Hx1.
  apply IHstop;try lia.
  induction tableSize;simpl in *.
  now contradict Hx.
  case_eq(lookup pd (CIndex n) (memory s) beqPage beqIndex );intros;
  rewrite H1 in *;[|try apply IHn ;trivial].
  destruct v; try (apply IHn; assumption).
  case_eq(Nat.eqb (pa p) defaultPage ) ;intros ;rewrite H2 in *.
  apply IHn;trivial.
  apply in_app_iff in Hx.
  destruct Hx. apply IHn; trivial.
  simpl in *.
  destruct H3.
  subst.
  unfold not;intros.
  apply beq_nat_false in H2.
  destruct defaultPage;destruct (pa p );simpl in *.
  inversion H3.
  subst.
  now contradict H2.
  now contradict H3.
Qed.

Lemma getIndirectionInGetIndirections2 (stop : nat) s prevtable
(va : vaddr) (level1 : level) (table root : page) :
(stop+1) <= nbLevel ->
getIndirection root va level1 (stop-1) s = Some prevtable ->
StateLib.readPhyEntry prevtable ( StateLib.getIndexOfAddr va (CLevel (level1 - (stop-1))))
         (memory  s) = Some table ->
NoDup (getIndirectionsAux root s (stop+1)) ->
table <> defaultPage ->
root <> defaultPage ->
stop <= level1 ->
prevtable <> defaultPage ->
~ In table (getIndirectionsAux root s stop).
Proof.

      intros.

assert ( Hnotdef :  ~ In defaultPage (getIndirectionsAux root s stop)).
apply configNotDefault;trivial.
revert H H0 H1 H2 H3 H4 H5 H6.

revert Hnotdef.
revert va level1  table root.
revert prevtable.
induction stop;simpl.
intros.
lia.
intros.
apply Classical_Prop.and_not_or.
split.
simpl in *.
apply NoDup_cons_iff in H2.
destruct H2.
clear IHstop.
{ assert(prevtable = table \/ prevtable <> table) by apply pageDecOrNot.
  destruct H8;subst.

 + assert(Hstop : stop = 0 \/ stop <> 0) by lia.
   destruct Hstop.
   * subst.
   simpl in *.
   inversion H0.
   subst.
   assert(In table  (getTablePages table tableSize s)).
   apply readPhyEntryInGetTablePages with
   (StateLib.getIndexOfAddr va (CLevel (level1 - 0)));trivial.
   destruct (StateLib.getIndexOfAddr va (CLevel (level1 - 0)));trivial.
   rewrite <- H1.
   f_equal. apply indexEqId.
   clear H6 H5 H3 H4 H7 H1 H0 H.
   revert H2 H8.
   induction (getTablePages table tableSize s);simpl.
   intuition.
   intros.
   apply Classical_Prop.not_or_and in H2.
   destruct H2.
   rewrite in_app_iff in H0.
   apply Classical_Prop.not_or_and in H0.
   destruct H0.
   destruct H8.
   subst.
   trivial.
   apply IHl;trivial.
   *  assert(In table  (getTablePages table tableSize s)).
   apply readPhyEntryInGetTablePages with
    (StateLib.getIndexOfAddr va (CLevel (level1 - (stop - 0))));trivial.
   destruct  (StateLib.getIndexOfAddr va (CLevel (level1 - (stop - 0))));trivial.
   rewrite <- H1.
   f_equal. apply indexEqId.
   unfold not;intros ;subst.
   revert H2 H9 H8.
   clear.
   induction(getTablePages table tableSize s) ;simpl.
   intuition.
   intros.
   rewrite in_app_iff in H2.
   apply Classical_Prop.not_or_and in H2.
   destruct H2.
   destruct H9.
   subst.
   replace (stop+1) with (S stop) in * by lia.
   simpl in H.
   apply not_or_and in H.
   intuition.
   apply IHl;trivial.
 +
  contradict H2.
  rewrite in_flat_map.
  assert(exists x ,  StateLib.readPhyEntry root
       (StateLib.getIndexOfAddr va level1) (memory s) =
     Some x /\ x <> defaultPage).
  { subst.    destruct stop;simpl in *.
    intros.
    inversion H0;subst.
    now contradict H8.
    (*
   exists prevtable.
   rewrite <- H1.
   f_equal.
   f_equal.
   rewrite <- minus_n_O.
   symmetry.
   apply CLevelIdentity1. *)
   intros.
destruct(StateLib.Level.eqb level1 fstLevel);intros.
inversion H0.
subst.
now contradict H8.
case_eq(StateLib.readPhyEntry table (StateLib.getIndexOfAddr va level1)
         (memory s));intros.
         rewrite H2 in *.
   case_eq(Nat.eqb defaultPage p);intros.
   rewrite H9 in *.
   inversion H0. subst.
   now contradict H6.       exists p;split;trivial.
   apply beq_nat_false in H9.
   unfold not;intros;subst.
   now contradict H9.
         rewrite H2 in H0.
         now contradict H0. }
        destruct H9 as (x & H9 & Hxnotnull).
  exists x.
  split.
  apply readPhyEntryInGetTablePages with  (StateLib.getIndexOfAddr va level1);trivial.
  destruct (StateLib.getIndexOfAddr va level1 );simpl;lia.
  rewrite <- H9.
  f_equal.
  apply indexEqId.

 assert (exists pred,  Some pred =  StateLib.Level.pred level1).
 { unfold StateLib.Level.pred.
  case_eq( gt_dec level1 0); intros.
  simpl. exists (CLevel(level1 - 1));f_equal;trivial.
  unfold CLevel.
  case_eq(lt_dec (level1 - 1) nbLevel);intros.
  f_equal.
  apply proof_irrelevance.
  destruct level1.
  simpl in *;lia.
  lia.
   }
  destruct H10 as (pred & Hpred).
  apply getIndirectionInGetIndirections1 with va pred;trivial.
  lia.
assert(stop = 0 \/ stop <> 0) by lia.
destruct H10.
subst.
simpl in *.
inversion H0.
subst.
now contradict H8.

  assert( getIndirection x va pred (( stop-1)+1) s = Some table).
  apply getIndirectionStopS1 with prevtable.
assert(pred = CLevel (level1 -1)).
apply levelPredMinus1;trivial.
assert(0 < level1) by lia.
apply notFstLevel;trivial.
  symmetry. trivial.
  rewrite H11.
  unfold CLevel.
  case_eq(lt_dec (level1 - 1) nbLevel);intros.
  simpl.
  lia.
  destruct level1.
  simpl in *. lia.
  unfold not;intros;subst.
  now contradict H6.
  assert(Hexist :  exists (pred : level) (page1 : page),
         page1 <> defaultPage /\
         Some pred = StateLib.Level.pred level1 /\
         StateLib.readPhyEntry root (StateLib.getIndexOfAddr va level1)
           (memory s) = Some page1 /\
         getIndirection page1 va pred (stop - 1) s = Some prevtable).
  apply getIndirectionFstStep;trivial.
  lia. lia.
  rewrite <- H0.
  f_equal. lia.
  destruct Hexist as (pred1 & page1 & Hpred1 &
   Hnotnull1 & Hphy & Hind).
   rewrite Hphy in H9.
   inversion H9;subst.
   rewrite <- Hnotnull1 in *.
   inversion Hpred.
   subst.
   trivial.
  simpl.
  assert(Htrue : StateLib.Level.eqb
 (CLevel (pred - (stop - 1))) fstLevel = false).
 { unfold StateLib.Level.eqb.
  apply NPeano.Nat.eqb_neq.
  unfold CLevel.
  case_eq( lt_dec (pred - (stop - 1)) nbLevel );intros.
  simpl.
  unfold fstLevel.
  unfold CLevel.
  case_eq(lt_dec 0 nbLevel );intros.
  simpl.
  assert(pred = CLevel (level1 -1)).
apply levelPredMinus1;trivial.
apply notFstLevel;trivial.
lia.
symmetry; trivial.
subst.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros.
simpl.
  lia.
  assert(level1 < nbLevel).
  destruct level1.
  simpl in *.
  lia.
  lia.
  assert(0<nbLevel) by apply nbLevelNotZero.
  lia.
  destruct pred.
  simpl in *.
  lia.
}
rewrite Htrue
.
assert(Hi : StateLib.readPhyEntry prevtable
    (StateLib.getIndexOfAddr va (CLevel (pred - (stop - 1)))) (memory s) = Some table).
    rewrite <- H1.
 do 3  f_equal.
 {
symmetry in Hpred.
apply levelPredMinus1 in Hpred.
rewrite Hpred.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros.
simpl.
lia.
destruct level1.
simpl in *.
lia.
trivial.
apply notFstLevel;lia.
 }
 rewrite Hi.
 assert((Nat.eqb defaultPage table) = false).
 { subst. apply NPeano.Nat.eqb_neq. unfold not;intros.
 destruct table ;destruct defaultPage;simpl in *;subst.
 contradict H4.
 f_equal. apply proof_irrelevance. }
 rewrite H11.
 case_eq ( StateLib.Level.pred (CLevel (pred - (stop - 1))));intros;trivial.
 assert(Hnotnote : StateLib.Level.pred (CLevel (pred - (stop - 1))) <> None).
 apply levelPredNone;trivial.
 now contradict Hnotnote.
 rewrite H2.
 rewrite <-H11.
 f_equal.
 lia.

}

rewrite in_flat_map.
unfold not;intros Hii.

destruct Hii as (x & Hx & Hfalse).
contradict Hfalse.
assert(Hor1 :stop = 0 \/ stop > 0) by lia.
destruct Hor1 as [Hor1 | Hor1].
{ subst.
  simpl in *. intuition. }
assert(Hor2 : StateLib.Level.eqb level1 fstLevel = true \/
StateLib.Level.eqb level1 fstLevel = false).
{ destruct (StateLib.Level.eqb level1 fstLevel).
  left;trivial. right;trivial. }
destruct Hor2 as [Hor2 | Hor2].
+
destruct stop;try lia.
simpl in *.
rewrite Hor2 in *.
inversion H0;subst.
apply NoDup_cons_iff in H2.
destruct H2.
assert(level1 <= 0).
apply levelEqBEqNatTrue0;trivial.
lia.
+
assert(Htrue : exists (pred : level) (page1 : page),
         page1 <> defaultPage /\
         Some pred = StateLib.Level.pred level1 /\
         StateLib.readPhyEntry root (StateLib.getIndexOfAddr va level1)
           (memory s) = Some page1 /\
         getIndirection page1 va pred (stop - 1) s = Some prevtable).
apply getIndirectionFstStep;trivial. lia.
rewrite <- H0.
f_equal. lia.
rewrite <- minus_n_O in H0;trivial.
destruct Htrue as (pred & page1 & Hpage1notnull & Hpred & Hphyentry & Hind).
assert(Hor :page1 = x \/ page1 <> x) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].

subst.

apply IHstop with prevtable va pred;trivial.
move Hnotdef at bottom.
apply not_or_and in Hnotdef.
destruct Hnotdef.
contradict H8.
rewrite in_flat_map.
exists x;split;trivial.
lia.
rewrite <- H1.
f_equal.
f_equal.
f_equal.
symmetry in Hpred.
apply levelPredMinus1 in Hpred.
rewrite Hpred.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros.
simpl.
lia.
destruct level1.
simpl in *.
lia.
trivial.

apply NoDup_cons_iff in H2.
destruct H2.

revert Hx H7.
clear.

induction (getTablePages root tableSize s);simpl.
intuition.
intros.
destruct Hx;subst.
apply NoDupSplitInclIff in H7.
intuition.
apply IHl;trivial.
apply NoDupSplitInclIff in H7.

intuition.

assert(pred = CLevel (level1 -1)).
apply levelPredMinus1;trivial.
symmetry;trivial.
rewrite H7.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros;simpl.
lia.
destruct level1.
simpl in *.
lia.

assert(~ In table (getIndirectionsAux x s (stop+1))).
{
assert(In table (getIndirectionsAux page1 s (stop+1))).
 {


apply getIndirectionInGetIndirections1  with va pred ;trivial.
lia.
assert(getIndirection page1 va pred ((stop-1) +1) s = Some table).
{

apply getIndirectionStopS1 with prevtable;trivial.
assert(Hhyp : stop <= pred).
{ assert(pred = CLevel (level1 -1)).
apply levelPredMinus1;trivial.
symmetry;trivial.
rewrite H7.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros;simpl.
lia.
destruct level1.
simpl in *.
lia. }
lia.

simpl.

assert(Hhyp : stop <= pred).
{ assert(pred = CLevel (level1 -1)).
apply levelPredMinus1;trivial.
symmetry;trivial.
rewrite H7.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros;simpl.
lia.
destruct level1.
simpl in *.
lia. }

assert(Htrue : StateLib.Level.eqb
 (CLevel (pred - (stop - 1))) fstLevel = false).
 { unfold StateLib.Level.eqb.
  apply NPeano.Nat.eqb_neq.
  unfold CLevel.
  case_eq( lt_dec (pred - (stop - 1)) nbLevel );intros.
  simpl.
  unfold fstLevel.
  unfold CLevel.
  case_eq(lt_dec 0 nbLevel );intros.
  simpl.
  lia.
  assert(0<nbLevel) by apply nbLevelNotZero.
  lia.
  destruct pred.
  simpl in *.
  lia.
}
rewrite Htrue.
assert((CLevel (level1 - (stop - 0))) =
(CLevel (pred - (stop - 1)))).
{
f_equal.
symmetry in Hpred.
apply levelPredMinus1 in Hpred.
rewrite Hpred.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros.
simpl.
lia.
destruct level1.
simpl in *.
lia.
trivial. }
rewrite <- H7.
rewrite H1.
assert((Nat.eqb defaultPage table) = true \/ (Nat.eqb defaultPage table) = false).
{ destruct (Nat.eqb defaultPage table).
  left;trivial.
  right;trivial. }

destruct H8.
rewrite  H8.
apply beq_nat_true in H8;trivial.
f_equal.
destruct table.
simpl in *.
destruct defaultPage;simpl in *.
subst;f_equal;apply proof_irrelevance.
rewrite H8.
case_eq(StateLib.Level.pred (CLevel (level1 - (stop - 0))) );intros;trivial.
assert(StateLib.Level.pred (CLevel (level1 - (stop - 0)))
<> None).
apply levelPredNone.
rewrite <- Htrue.
f_equal.
f_equal.
symmetry in Hpred.
apply levelPredMinus1 in Hpred.
rewrite Hpred.
unfold CLevel.
case_eq(lt_dec (level1 - 1) nbLevel);intros.
simpl.
lia.
destruct level1.
simpl in *.
lia.
trivial.
now contradict H9.   }
rewrite <-  H7.
f_equal.
lia.

}
assert(NoDup (getIndirectionsAux root s (S(stop + 1)))).
simpl;trivial.
assert(disjoint (getIndirectionsAux page1 s (S(stop + 1) -1))
 (getIndirectionsAux x s  (S(stop + 1) -1))  ).
 assert(exists idx, StateLib.readPhyEntry root (CIndex idx) (memory s) = Some x ).
 { revert Hx. clear.
 revert x.
  induction tableSize.
  intros.
  simpl in *.
  intuition.
  simpl;intros.
  case_eq(lookup root (CIndex n) (memory s) beqPage beqIndex);intros;
  rewrite H in *; try (apply IHn ; assumption).
  destruct v; try (apply IHn ; assumption).
  case_eq(Nat.eqb (pa p) defaultPage);intros;rewrite H0 in *.
  apply IHn;trivial.
  apply in_app_iff in Hx.
  destruct Hx; trivial.
  apply IHn;trivial.
  simpl in *.
  destruct H1;subst.
  exists n;trivial.
  unfold StateLib.readPhyEntry.
  rewrite H;trivial.
  intuition.
}

destruct H9 as (idx & Hidx).
{


apply disjointGetIndirectionsAuxMiddle with root
 (CIndex idx) (StateLib.getIndexOfAddr va level1);trivial.
 *
 intuition.
 *
 lia.
 *
 apply NPeano.Nat.eqb_neq.
 unfold not;intros Hfalse.
 contradict Hpage1notnull.
 destruct page1;destruct defaultPage;simpl in *.
 subst;f_equal;apply proof_irrelevance.
 * move Hnotdef at bottom.
 apply not_or_and in Hnotdef.
 destruct Hnotdef.
 rewrite in_flat_map in H10.
 apply NNPP.
 unfold not at 1. intros.
 contradict H10.
 exists x.
 split. trivial.
 apply NNPP.
 unfold not at 1.
 intros.
 contradict H11.
 destruct stop;
 simpl in *.
 now contradict Hor1.
 apply not_or_and in H10.
 destruct H10 .
 apply NPeano.Nat.eqb_neq.
 unfold not;intros;subst.
 destruct x;destruct defaultPage;simpl in *;
 subst.
 contradict H10. f_equal.
 apply proof_irrelevance.
  }
assert(Htrue : S (stop + 1) - 1 = stop +1) by lia.
rewrite Htrue in *.
clear Htrue.
apply H9;trivial. }
apply inGetIndirectionsAuxLt with (stop + 1);trivial.
lia.

Qed.

Lemma indirectionNotInPreviousMMULevel s ptVaChildpd idxvaChild phyVaChild
  pdChildphy currentPart
presentvaChild vaChild phyDescChild level entry:
 partitionDescriptorEntry s ->
 isPresentNotDefaultIff s ->
 noDupConfigPagesList s ->
configTablesAreDifferent s ->
In currentPart (getPartitions multiplexer s) ->
In phyVaChild (getAccessibleMappedPages currentPart s) ->
lookup ptVaChildpd idxvaChild (memory s) beqPage beqIndex = Some (PE entry) ->
StateLib.getNbLevel = Some level ->
negb presentvaChild = true ->
In phyDescChild (getPartitions multiplexer s) ->
 isPE ptVaChildpd (StateLib.getIndexOfAddr vaChild fstLevel) s ->
 getTableAddrRoot ptVaChildpd PDidx phyDescChild vaChild s ->
 (Nat.eqb defaultPage ptVaChildpd) = false ->
 StateLib.getIndexOfAddr vaChild fstLevel = idxvaChild ->
 entryPresentFlag ptVaChildpd idxvaChild presentvaChild s ->
nextEntryIsPP phyDescChild PDidx pdChildphy s ->
pdChildphy <> defaultPage ->
getIndirection pdChildphy vaChild level (nbLevel - 1) s =
            Some ptVaChildpd ->
            nbLevel -1 > 0 ->
~ In ptVaChildpd (getIndirectionsAux pdChildphy s (nbLevel - 1)).
Proof.
intros Hpde Hpresdef Hnodupconf Hconfigdiff Hparts Haccess Hlookup Hlevel
Hnotpresent Hchildpart Hpe Htblroot Hdefaut Hidx Hentrypresent
Hpdchild Hpdchildnotnull Hindchild H0.
 {  assert(0<nbLevel) by apply nbLevelNotZero.
      assert(nbLevel - 1 + 1 = nbLevel) by lia.
 assert(Hprevious : exists prevtab,
      getIndirection pdChildphy vaChild level (nbLevel - 2) s =
            Some prevtab /\prevtab <> defaultPage /\  StateLib.readPhyEntry prevtab
  (StateLib.getIndexOfAddr vaChild (CLevel (level- ((nbLevel - 1) - 1)))) (memory s) =
Some ptVaChildpd).
{   revert Hindchild   Hdefaut  (*  H0 *).


  assert(Hstooo : level > (nbLevel - 1 -1)).
  { symmetry in Hlevel. apply getNbLevelEq in Hlevel.
    subst.
    unfold CLevel.
    case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
    simpl.
    lia. (*
    unfold CLevel in H0.
    rewrite H0 in *.
    simpl in *.
     *)
    lia. }


  assert(Htpp : 0 < nbLevel -1).
  { symmetry in Hlevel. apply getNbLevelEq in Hlevel.
    subst.
    unfold CLevel.
    case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
    simpl.
    lia.
    lia.

     }
  assert(Hnotdef : pdChildphy <> defaultPage) by intuition.
  revert Hstooo Htpp Hnotdef.
  clear.

  replace (nbLevel -2) with (nbLevel -1 -1) by lia.
  revert pdChildphy level ptVaChildpd.
  induction (nbLevel-1);simpl.
  intros.
  lia.
  intros.
  case_eq(StateLib.Level.eqb level fstLevel);intros;
  rewrite H in *.
  apply levelEqBEqNatTrue0 in H.
  lia.
   case_eq(StateLib.readPhyEntry pdChildphy
                (StateLib.getIndexOfAddr vaChild level) (memory s));intros;
    rewrite H0 in *;try now contradict Hindchild.
    case_eq(Nat.eqb defaultPage p);intros;rewrite H1 in *.
    apply beq_nat_false in Hdefaut.
    inversion Hindchild.
    subst.
    now contradict Hdefaut.
    case_eq(StateLib.Level.pred level );intros;rewrite H2 in *.
    + replace (n-0) with n by lia.
    assert(Hooo : n = 0 \/ 0 < n) by lia.
    destruct Hooo.
    *
    subst.
    simpl in *.
    exists  pdChildphy;split;trivial.
    inversion Hindchild.
    subst.
    rewrite <- H0.
    split.  trivial.
    f_equal.
    f_equal.
    rewrite <- minus_n_O.
    apply CLevelIdentity1.
    * assert(Hii : l > n - 1  ) .
    apply levelPredMinus1 in H2.
    subst.
   unfold CLevel.
    case_eq( lt_dec (level - 1) nbLevel );intros.
    simpl.
    lia.
    destruct level.
    simpl in *.
    lia.
    trivial.
    assert(Hi1 : p <> defaultPage).
    apply beq_nat_false in H1.
    intuition.
    subst.
    now contradict H1.
      generalize(IHn p l ptVaChildpd Hii H3 Hi1 Hindchild Hdefaut
       );clear IHn ; intros iHn .
       destruct iHn as (prevtab & Hindprev & Hdef & Hread).
       exists prevtab;split;trivial.
       intros.
       assert(Hs :S(n-1) = n) by lia.
       rewrite <- Hs.
       simpl.
       rewrite H.
       rewrite H0.
       rewrite H1.
       rewrite H2;trivial.
       split;trivial.
       rewrite <- Hread.
       f_equal.
       f_equal.
       f_equal.
apply levelPredMinus1 in H2.
rewrite H2.
unfold CLevel.
case_eq(lt_dec (level - 1) nbLevel);intros.
simpl.
lia.
destruct level.
simpl in *.
lia.
trivial.
+ assert(Hnotnone : StateLib.Level.pred level <> None).
apply levelPredNone;trivial. now contradict Hnotnone.  }
destruct Hprevious as (prevtab & Hprevtable & Hprevnotnull & Hreadprev).
apply getIndirectionInGetIndirections2 with prevtab vaChild level;
simpl; subst;
trivial.
lia.
simpl.
rewrite <- Hprevtable.
f_equal.
lia.
rewrite H1.
assert(Hdup :   noDupConfigPagesList s) by intuition.
apply noDupConfigPagesListNoDupGetIndirections with phyDescChild PDidx;trivial.
apply Hdup;trivial.
left;trivial.
apply beq_nat_false in Hdefaut.
unfold not;intros;subst.
now contradict Hdefaut.
move Hlevel at bottom.
symmetry in Hlevel.

apply getNbLevelEq in Hlevel.
rewrite Hlevel.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);intros.
simpl.
lia.
lia.
}
Qed.
Lemma vaNotDerived currentPart shadow1 (ptSh1ChildFromSh1 : page) s :
consistency s ->
In currentPart (getPartitions multiplexer s) ->
(Nat.eqb defaultPage ptSh1ChildFromSh1) = false  ->
(exists va : vaddr,
isEntryVA ptSh1ChildFromSh1 (StateLib.getIndexOfAddr shadow1 fstLevel) va s /\
beqVAddr defaultVAddr va = true) ->
(forall idx : index,
StateLib.getIndexOfAddr shadow1 fstLevel = idx ->
isVE ptSh1ChildFromSh1 idx s /\ getTableAddrRoot ptSh1ChildFromSh1 sh1idx currentPart shadow1 s) ->
~ isDerived currentPart shadow1 s .
Proof.
intros Hcons Hparts Hptfromsh1notnull Hii Hi.

destruct Hi with (StateLib.getIndexOfAddr shadow1 fstLevel) as
(Hve & Hgetve);trivial.

clear Hi.
destruct Hii as (va0 & Hvae & Hveq).
unfold isDerived.
unfold getTableAddrRoot in *.
destruct Hgetve as (_ & Hgetve).
assert(Hcursh1 :(exists entry : page, nextEntryIsPP currentPart sh1idx entry s /\ entry <> defaultPage)).
assert(Hpde :  partitionDescriptorEntry s).
unfold consistency in *.
intuition.
unfold partitionDescriptorEntry in *.
apply Hpde;trivial.
right;left;trivial.
destruct Hcursh1 as (cursh1 & Hcursh1 & Hsh1notnull).
rewrite nextEntryIsPPgetFstShadow in *.
rewrite Hcursh1.
rewrite <- nextEntryIsPPgetFstShadow in *.
apply Hgetve in Hcursh1.
destruct Hcursh1 as (l & Hl & stop & Hstop & Hgetva).
clear Hgetve.
unfold getVirtualAddressSh1.
rewrite <- Hl.
subst.
assert(Hgetind : getIndirection cursh1 shadow1 l (nbLevel - 1) s  = Some ptSh1ChildFromSh1).
apply getIndirectionStopLevelGT2 with (l+1);trivial.
abstract lia.
apply getNbLevelEq in Hl.
subst.
apply nbLevelEq.
rewrite Hgetind.
rewrite Hptfromsh1notnull.
unfold  isEntryVA in *.
unfold isVE in *.
unfold StateLib.readVirEntry.
case_eq(lookup ptSh1ChildFromSh1 (StateLib.getIndexOfAddr shadow1 fstLevel)
(memory s) beqPage beqIndex);intros * Hlookupsh1;rewrite Hlookupsh1 in *;
try now contradict Hve.
case_eq v;intros * Hvsh1;rewrite Hvsh1 in *;
try now contradict Hve.
subst.
unfold not;intros.
rewrite H in Hveq.
now contradict Hveq.
Qed.
Lemma phyNotDerived currentPart phySh1Child currentPD shadow1 (ptSh1Child : page)s :
(Nat.eqb defaultPage ptSh1Child) = false ->
~ isDerived currentPart shadow1 s ->
consistency s ->
In currentPart (getPartitions multiplexer s) ->
nextEntryIsPP currentPart PDidx currentPD s  ->
(forall idx : index,
StateLib.getIndexOfAddr shadow1 fstLevel = idx ->
isPE ptSh1Child idx s /\ getTableAddrRoot ptSh1Child PDidx currentPart shadow1 s) ->
isEntryPage ptSh1Child (StateLib.getIndexOfAddr shadow1 fstLevel) phySh1Child s ->
entryPresentFlag ptSh1Child (StateLib.getIndexOfAddr shadow1 fstLevel) true s ->
forall child : page,
In child (getChildren currentPart s) -> ~ In phySh1Child (getMappedPages child s).
Proof.
intros Hptnotnull HderivShadow1 Hcons Hcurparts Hcurpd Hget Hep Hpres child Hchild.
assert(H1 : physicalPageNotDerived s).
{ unfold consistency in *.
intuition. }
unfold physicalPageNotDerived in *.
rewrite nextEntryIsPPgetPd in *.
generalize (H1 currentPart shadow1 currentPD
phySh1Child Hcurparts Hcurpd HderivShadow1);clear H1;intros H1.
unfold getMappedPages.
case_eq (StateLib.getPd child (memory s) );intros;trivial.
unfold getMappedPagesAux.
rewrite filterOptionInIff.
unfold getMappedPagesOption.
rewrite in_map_iff.
unfold not in *.
intros.
destruct H0 as (x & Hx1 & Hx2).

apply H1 with child p x phySh1Child;trivial.
apply getMappedPageGetTableRoot
with ptSh1Child currentPart;intuition.
subst.
trivial.
subst.
trivial.
apply nextEntryIsPPgetPd;trivial.
unfold not;intros Hfalse;now contradict Hfalse.
Qed.


Lemma noDupAllVAddrWithOffset0 :
 NoDup getAllVAddrWithOffset0.
 Proof.
unfold getAllVAddrWithOffset0.
assert (Hnodupallvaddr : NoDup getAllVAddr) by apply noDupAllVaddr.
revert Hnodupallvaddr.
clear.
induction getAllVAddr;simpl;intros;trivial.
apply NoDup_cons_iff in Hnodupallvaddr.
case_eq(checkOffset0 a);intros.
constructor.
rewrite filter_In.
intuition.
apply IHl;intuition.
apply IHl;intuition.
Qed.

Lemma  checkVAddrsEqualityWOOffsetFalseEqOffset nbL a descChild:
StateLib.getNbLevel = Some nbL ->
a <> descChild ->
checkOffset0 descChild = true  ->
checkOffset0 a = true ->
StateLib.checkVAddrsEqualityWOOffset nbLevel a descChild nbL = false.
Proof.
intros.
unfold checkOffset0 in *.
   assert( nth nbLevel descChild defaultIndex =  nth nbLevel a defaultIndex).
 { case_eq (Nat.eqb (nth nbLevel a defaultIndex) (CIndex 0));intros Heq;rewrite Heq in *;
    try now contradict H1.
   case_eq(Nat.eqb (nth nbLevel descChild defaultIndex) (CIndex 0));intros Heq1;rewrite Heq1 in *;
   try now contradict H2.
   apply beq_nat_true in Heq.
   apply beq_nat_true in Heq1.
   destruct (nth nbLevel a defaultIndex);simpl in *;destruct (nth nbLevel descChild defaultIndex);simpl in *.
  subst. f_equal. apply proof_irrelevance. }
 rewrite H3 in *.
 clear H1 H2.
  assert(last a defaultIndex = last descChild defaultIndex).
 {  revert H0.
   intros.
   assert(forall l ,  nth ((length l)-1)  l defaultIndex = last l defaultIndex ).
   { clear.
    induction l.
    simpl;trivial.
    simpl.
    replace ( length l - 0 ) with (length l) by lia.
    case_eq(length l );intros.
    apply length_zero_iff_nil in H.
    subst;trivial.
    case_eq l.
    intros;subst.
    simpl in *.
    lia.
    intros.
    rewrite <- H0.
    rewrite H in IHl.
    rewrite  <- IHl.
    f_equal.
    lia. }
    rewrite <- H1.
   destruct a;simpl in *.
   destruct descChild;simpl in *.
   rewrite Hva.
   rewrite <- H1.
   rewrite NPeano.Nat.add_sub.
   rewrite Hva0.
   simpl.
   rewrite <- H3.
   f_equal.
   lia. }
   clear H1.
  (*  assert (Heql : nbLevel <= nbLevel) by lia. *)

assert(HnbLlt :nbL < nbLevel).
apply getNbLevelLt;trivial.
 assert(length a <= nbL +2).
{ destruct a;simpl. simpl in *.
rewrite Hva.
symmetry in H.
apply getNbLevelEq in H.
subst.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
simpl.
lia.
lia.
}
apply NNPP.
unfold not at 1; intros Hfalse.
 apply Bool.not_false_is_true in Hfalse.
 contradict H0.
  assert(forall predNbL : level, predNbL <= nbL ->
  StateLib.getIndexOfAddr a predNbL = StateLib.getIndexOfAddr descChild predNbL ).
  intros.
  apply checkVAddrsEqualityWOOffsetTrue' with  nbLevel nbL;trivial.
  clear Hfalse.

assert(Hmykey: forall pos, pos > nbL ->   nth pos descChild defaultIndex = nth pos a defaultIndex).
{ intros.
symmetry in H.

apply getNbLevelEq in H.
subst.
clear HnbLlt.
assert(length a = nbLevel +1).
destruct a.
simpl in *. lia.
assert (pos > nbLevel -1).
         unfold CLevel.
         case_eq( lt_dec (nbLevel - 1) nbLevel);intros.
         simpl.
         trivial.
         lia.
         lia.
clear H2.
assert (pos = nbLevel \/ pos > nbLevel) by lia.
destruct H2.
subst;trivial.
rewrite nth_overflow.
rewrite nth_overflow;trivial.
lia.
destruct descChild;simpl in *.
lia. }

unfold StateLib.getIndexOfAddr in *.
destruct a;destruct descChild;simpl in *.
assert(va = va0).
{ rewrite Hva in *.
  rewrite Hva0 in *.
  symmetry in H.
  apply getNbLevelEq in H.
  subst.
  assert(va = firstn (nbLevel-1) va ++ skipn (nbLevel-1) va).
  symmetry.
  apply firstn_skipn.
  rewrite H.

  assert(va0 = firstn (nbLevel-1) va0 ++ skipn (nbLevel-1) va0).
  symmetry.
  apply firstn_skipn.
  rewrite H2.
  f_equal.
  +
 clear Hmykey.
  assert(forall predNbL : level,
     predNbL <= nbLevel - 1 ->
     nth ((nbLevel - 1)  - predNbL ) va defaultIndex =
     nth ((nbLevel - 1) - predNbL ) va0 defaultIndex).
     { intros. generalize (H0 predNbL) ; clear H0;intros H0.
     assert((nbLevel - 1 - predNbL) = (nbLevel + 1 - (predNbL + 2))).
     lia.
     rewrite H5.
     apply H0.
     unfold CLevel.
     case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
     simpl.
     trivial.
     lia. }
     assert(length va = length va0) by lia.
      assert(Hlenva : length va > 0) by lia.
     clear H2 H HnbLlt H0 H3 Hva0 Hva H1.
     assert(Hx : forall pos : level,
     pos <= nbLevel - 1 ->
     nth pos va defaultIndex =
     nth pos va0 defaultIndex).
     {  intros.

     generalize(H4 (CLevel ((nbLevel - 1 ) - pos )));clear H4;
     intros H4.
     unfold
      CLevel in *.
      case_eq(lt_dec (nbLevel - 1 - pos) nbLevel );intros;
      rewrite H0 in *;simpl in *.
      assert (0 < nbLevel) by apply nbLevelNotZero.
      destruct pos.
      simpl in *.
      replace ((nbLevel - 1 - (nbLevel - 1 - l0))) with l0
      in *.
      apply H4. clear H4.
      lia.
      clear H0.
      clear H4 l .
      lia.
      assert(0 < nbLevel) by apply nbLevelNotZero.
      lia. }

     clear H4.




     revert dependent va; revert dependent va0.
     assert(0 < nbLevel) by apply nbLevelNotZero.

     assert(Hlevel : nbLevel -1 < nbLevel ) by lia.

     clear H.
     induction (nbLevel-1);intros.
     simpl;trivial.
     assert(firstn (S n) va =
     nth 0 va defaultIndex::  firstn n (tl va) ).
     revert Hlenva.
      clear .
     destruct va;simpl; intros;try lia.
     f_equal.
     rewrite H.
     assert(firstn (S n) va0 =
     nth 0 va0 defaultIndex::  firstn n (tl va0) ).
     {revert Hlenva.
     rewrite H5. clear .
     destruct va0;simpl; intros;try lia.
     f_equal. }
     rewrite H0.
     f_equal.
     generalize(Hx fstLevel );clear Hx;intros Hx.

     assert (fstLevel <= S n).
     unfold fstLevel.
     unfold CLevel.
     assert(0<nbLevel) by apply nbLevelNotZero.
     case_eq( lt_dec 0 nbLevel);intros;
     simpl; lia.
     apply Hx in H1. clear Hx.
     unfold fstLevel in H1.
     unfold CLevel in H1.
     assert(0<nbLevel) by apply nbLevelNotZero.
     case_eq( lt_dec 0 nbLevel);intros; rewrite H3 in *.
     simpl in  *;trivial. lia.
     assert(forall va: list index, (length va) -1 = length (tl va) ).
     { clear.
       induction va;intros.
       simpl;trivial.
       simpl.
       lia. }
     assert (Hor :  length  (tl va) = 0 \/ length (tl va) > 0) by lia.
     destruct
      Hor as [Hor | Hor].
      * subst.
      assert(length (tl va0) = 0).
      rewrite <- H1.
      rewrite <- H5.
      rewrite  H1;trivial.
      assert((tl va) = []).
      apply length_zero_iff_nil;trivial.
      rewrite H3.

      assert((tl va0) = []).
      apply length_zero_iff_nil;trivial.
      rewrite H4.
      trivial.
      *
     apply IHn.
     lia.


     rewrite <- H1.
     rewrite <- H1.
     f_equal.
     lia.
     trivial.
     intros.
     revert Hx H2 Hlevel.
     clear.
     intros.
     assert(forall va, nth pos (tl va) defaultIndex =
     nth (S pos) va defaultIndex).
     { clear .
     intros.
     revert pos.
     induction va.
     intros.
     simpl.
     destruct (l pos);trivial.
     simpl.
     intros;trivial. }
     rewrite H.
     rewrite H.
     generalize (Hx (CLevel (S pos)));clear Hx ; intros Hx.
     unfold CLevel in *.
     case_eq(lt_dec (S pos) nbLevel );intros;
     rewrite H0 in *;
     simpl in *.


     apply Hx.
     lia.
     lia.


     +
     generalize(H0 fstLevel );clear H0;intros Hx.
 assert (fstLevel <= CLevel (nbLevel - 1) ).
     unfold fstLevel.
     unfold CLevel.
     assert(0<nbLevel) by apply nbLevelNotZero.
     case_eq( lt_dec 0 nbLevel);intros;
     simpl; lia.
     apply Hx in H0. clear Hx.

     simpl in *.
     unfold fstLevel in H0.
     unfold CLevel in H0.
     assert(0<nbLevel) by apply nbLevelNotZero.
     case_eq( lt_dec 0 nbLevel);intros; rewrite H5 in *;
      intuition.
     simpl in  *;trivial.
     replace (nbLevel + 1 - 2) with (nbLevel -1)
     in * by lia.


     assert(forall pos : nat,
         pos > nbLevel - 1 ->
         nth pos va0 defaultIndex = nth pos va defaultIndex).
         intros.
         apply Hmykey.
         unfold CLevel.
         case_eq( lt_dec (nbLevel - 1) nbLevel);intros.
         simpl.
         trivial.
         lia.
         assert(Hx : length va = length va0) by lia.
         assert(Hii : length va <= (nbLevel -1) +2) by lia.
         clear Hmykey H1 H2 H HnbLlt.
         clear H3.
         clear Hva Hva0 H5.
         clear l H4.
         assert(forall pos, pos >= nbLevel -1 -> nth pos va0 defaultIndex = nth pos va defaultIndex).
         intros .
         assert(pos =  nbLevel - 1 \/ pos >  nbLevel - 1) by lia.
         clear H.
         destruct H1.
         subst;trivial.
         symmetry;trivial.
         apply H6;trivial.
         clear H6 H0.


         revert dependent va0.
         revert dependent va.
         induction (nbLevel-1);intros;trivial.
         simpl in *.
         revert dependent va.
         induction va0;simpl;intros;subst.
         apply length_zero_iff_nil;trivial.
         simpl in *.
         case_eq va;simpl;intros.
         subst.
         simpl in *.
         lia.
         f_equal.
         generalize(H 0);clear H;intros H.
         simpl in *.
         subst.
         simpl in *.
         symmetry.
         apply H; lia.
         apply IHva0.
         subst.
         simpl in *. lia.
         intros.
         subst. simpl in *;lia.
         intros.
         generalize (H (S pos));clear H;intros H.
         subst.
         simpl in *.
         apply H.
         lia.
         subst.
         simpl in *. (*
         lia.
         simpl. *)
         case_eq va;simpl;intros.
         subst.

         inversion Hx.
         symmetry in H1.
         apply length_zero_iff_nil in H1.
         subst.
         trivial.
         case_eq va0;intros.
         subst.
         simpl in *.
         now contradict Hx.
         apply IHn;trivial.
         intros.
         subst.
         simpl in *.
         lia.
         intros.
         subst.
         simpl in *.
         lia.
         intros.
         subst.

         generalize (H (S pos));clear H ; intros H.

         apply H;lia. }
         subst;f_equal;apply proof_irrelevance.
Qed.

Lemma getPDFlagGetPdsVAddr' sh1Childphy vaChild phyDescChild level s:
 nextEntryIsPP phyDescChild sh1idx sh1Childphy s ->
  getPDFlag sh1Childphy vaChild s = false ->
  StateLib.getNbLevel = Some level ->
  StateLib.getFstShadow phyDescChild (memory s) = Some sh1Childphy ->
  ~ In vaChild (getPdsVAddr phyDescChild level getAllVAddr s).
Proof.
unfold getPDFlag.
unfold getPdsVAddr.
rewrite filter_In.
intros Hpp Hpdflag Hlevel Hsh1 .
apply or_not_and.
right.
unfold not;intros.
unfold checkChild in *.
rewrite Hlevel in *.
rewrite Hsh1 in *.
rewrite Hpdflag in *.
now contradict H.
Qed.

Lemma isEntryPageReadPhyEntry2 table idx entry s:
StateLib.readPhyEntry table idx (memory s) = Some (pa entry) ->
isEntryPage table idx (pa entry) s.
Proof.
intros Hentrypage.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry in *.
destruct(lookup table idx (memory s) beqPage beqIndex );
try now contradict Hentrypage.
destruct v; try now contradict Hentrypage.
inversion Hentrypage;trivial.
Qed.

   Lemma isPresentNotDefaultIffTrue (s :state):
   forall (table : page) (idx : index) ,
   isPresentNotDefaultIff s ->
StateLib.readPresent table idx (memory s) = Some true ->
StateLib.readPhyEntry table idx (memory s) <> Some defaultPage.
Proof.
intros table idx Hi1. intros.
apply NNPP.
unfold not at 1;intros Hfalse.
contradict H.
assert(StateLib.readPresent table idx (memory s) = Some false).
generalize (Hi1 table idx);
clear Hi1; intros Hconspresent.
      apply Hconspresent.
       apply NNPP.
      unfold not at 1;intros Hfalse1.
      contradict Hfalse.
      trivial.
      rewrite H.
      unfold not;intros. now contradict H0.
Qed.
(** moins d'hypothèses *)
Lemma indirectionNotInPreviousMMULevel1 s ptVaChildpd idxvaChild (* phyVaChild *)
  pdChildphy (* currentPart *)
(* presentvaChild *) vaChild phyDescChild level entry:
 partitionDescriptorEntry s ->
 isPresentNotDefaultIff s ->
 noDupConfigPagesList s ->
configTablesAreDifferent s ->
(* In currentPart (getPartitions multiplexer s) ->  *)
True ->
(* In phyVaChild (getAccessibleMappedPages currentPart s) ->  *)
True ->
lookup ptVaChildpd idxvaChild (memory s) beqPage beqIndex = Some (PE entry) ->
StateLib.getNbLevel = Some level ->
(* negb presentvaChild = true ->  *)
True ->
In phyDescChild (getPartitions multiplexer s) ->
 isPE ptVaChildpd (StateLib.getIndexOfAddr vaChild fstLevel) s ->
 getTableAddrRoot ptVaChildpd PDidx phyDescChild vaChild s ->
 (Nat.eqb defaultPage ptVaChildpd) = false ->
 StateLib.getIndexOfAddr vaChild fstLevel = idxvaChild ->
 entryPresentFlag ptVaChildpd idxvaChild true s ->
nextEntryIsPP phyDescChild PDidx pdChildphy s ->
pdChildphy <> defaultPage ->
getIndirection pdChildphy vaChild level (nbLevel - 1) s =
            Some ptVaChildpd ->
            nbLevel -1 > 0 ->
~ In ptVaChildpd (getIndirectionsAux pdChildphy s (nbLevel - 1)).
Proof.
intros Hpde Hpresdef Hnodupconf Hconfigdiff Hparts Haccess Hlookup Hlevel
 Hnotpresent Hchildpart Hpe Htblroot Hdefaut Hidx Hentrypresent
Hpdchild Hpdchildnotnull Hindchild H0.
 {  assert(0<nbLevel) by apply nbLevelNotZero.
      assert(nbLevel - 1 + 1 = nbLevel) by lia.
 assert(Hprevious : exists prevtab,
      getIndirection pdChildphy vaChild level (nbLevel - 2) s =
            Some prevtab /\prevtab <> defaultPage /\  StateLib.readPhyEntry prevtab
  (StateLib.getIndexOfAddr vaChild (CLevel (level- ((nbLevel - 1) - 1)))) (memory s) =
Some ptVaChildpd).
{   revert Hindchild   Hdefaut  (*  H0 *).


  assert(Hstooo : level > (nbLevel - 1 -1)).
  { symmetry in Hlevel. apply getNbLevelEq in Hlevel.
    subst.
    unfold CLevel.
    case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
    simpl.
    lia. (*
    unfold CLevel in H0.
    rewrite H0 in *.
    simpl in *.
     *)
    lia. }


  assert(Htpp : 0 < nbLevel -1).
  { symmetry in Hlevel. apply getNbLevelEq in Hlevel.
    subst.
    unfold CLevel.
    case_eq(lt_dec (nbLevel - 1) nbLevel );intros.
    simpl.
    lia.
    lia.

     }
  assert(Hnotdef : pdChildphy <> defaultPage) by intuition.
  revert Hstooo Htpp Hnotdef.
  clear.
  replace (nbLevel -2) with (nbLevel -1 -1) by lia.
  revert pdChildphy level ptVaChildpd.
  induction (nbLevel-1);simpl.
  intros.
  lia.
  intros.
  case_eq(StateLib.Level.eqb level fstLevel);intros;
  rewrite H in *.
  apply levelEqBEqNatTrue0 in H.
  lia.
   case_eq(StateLib.readPhyEntry pdChildphy
                (StateLib.getIndexOfAddr vaChild level) (memory s));intros;
    rewrite H0 in *;try now contradict Hindchild.
    case_eq(Nat.eqb defaultPage p);intros;rewrite H1 in *.
    apply beq_nat_false in Hdefaut.
    inversion Hindchild.
    subst.
    now contradict Hdefaut.
    case_eq(StateLib.Level.pred level );intros;rewrite H2 in *.
    + replace (n-0) with n by lia.
    assert(Hooo : n = 0 \/ 0 < n) by lia.
    destruct Hooo.
    *
    subst.
    simpl in *.
    exists  pdChildphy;split;trivial.
    inversion Hindchild.
    subst.
    rewrite <- H0.
    split.  trivial.
    f_equal.
    f_equal.
    rewrite <- minus_n_O.
    apply CLevelIdentity1.
    * assert(Hii : l > n - 1  ) .
    apply levelPredMinus1 in H2.
    subst.
   unfold CLevel.
    case_eq( lt_dec (level - 1) nbLevel );intros.
    simpl.
    lia.
    destruct level.
    simpl in *.
    lia.
    trivial.
    assert(Hi1 : p <> defaultPage).
    apply beq_nat_false in H1.
    intuition.
    subst.
    now contradict H1.
      generalize(IHn p l ptVaChildpd Hii H3 Hi1 Hindchild Hdefaut
       );clear IHn ; intros iHn .
       destruct iHn as (prevtab & Hindprev & Hdef & Hread).
       exists prevtab;split;trivial.
       intros.
       assert(Hs :S(n-1) = n) by lia.
       rewrite <- Hs.
       simpl.
       rewrite H.
       rewrite H0.
       rewrite H1.
       rewrite H2;trivial.
       split;trivial.
       rewrite <- Hread.
       f_equal.
       f_equal.
       f_equal.
apply levelPredMinus1 in H2.
rewrite H2.
unfold CLevel.
case_eq(lt_dec (level - 1) nbLevel);intros.
simpl.
lia.
destruct level.
simpl in *.
lia.
trivial.
+ assert(Hnotnone : StateLib.Level.pred level <> None).
apply levelPredNone;trivial. now contradict Hnotnone.  }
destruct Hprevious as (prevtab & Hprevtable & Hprevnotnull & Hreadprev).
apply getIndirectionInGetIndirections2 with prevtab vaChild level;
simpl; subst;
trivial.
lia.
simpl.
rewrite <- Hprevtable.
f_equal.
lia.
rewrite H1.
assert(Hdup :   noDupConfigPagesList s) by intuition.
apply noDupConfigPagesListNoDupGetIndirections with phyDescChild PDidx;trivial.
apply Hdup;trivial.
left;trivial.
apply beq_nat_false in Hdefaut.
unfold not;intros;subst.
now contradict Hdefaut.
move Hlevel at bottom.
symmetry in Hlevel.

apply getNbLevelEq in Hlevel.
rewrite Hlevel.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);intros.
simpl.
lia.
lia.
}
Qed.
*)

Lemma beqAddrTrue a :
beqAddr a a= true.
Proof.
unfold beqAddr. rewrite PeanoNat.Nat.eqb_refl. trivial.
Qed.

(*Lemma CPaddrInjection addr1 addr2 :
addr1 <= maxAddr -> addr2 <= maxAddr
-> CPaddr addr1 = CPaddr addr2 -> addr1 = addr2.
Proof.
intros. unfold CPaddr in *.
destruct (le_dec addr1 maxAddr) eqn: Hj ; try congruence.
destruct (le_dec addr2 maxAddr) eqn: Hk ; try congruence.
Qed.*)

Lemma nullAddrIs0 :
nullAddr = CPaddr 0.
Proof.
intuition.
Qed.

Lemma isPDTMultiplexerEqPDT addr' newEntry s0:
isPDT multiplexer s0 ->
isPDT addr' s0 ->
isPDT multiplexer {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |}.
Proof.
intros.
unfold isPDT. simpl.
destruct (beqAddr addr' multiplexer) eqn:beqmultiaddr'; try(exfalso ; congruence).
- (* addr' = multiplexer *)
	trivial.
- (* addr' <> multiplexer *)
	rewrite removeDupIdentity ; intuition.
	subst addr'.
	rewrite <- beqAddrFalse in *.
	congruence.
Qed.

Lemma isPDTMultiplexerEqBE addr' newEntry s0:
isPDT multiplexer s0 ->
isBE addr' s0 ->
isPDT multiplexer {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}.
Proof.
intros.
unfold isPDT. simpl.
destruct (beqAddr addr' multiplexer) eqn:beqmultiaddr'; try(exfalso ; congruence).
- (* addr' = multiplexer *)
	rewrite <- DTL.beqAddrTrue in beqmultiaddr'.
	rewrite beqmultiaddr' in *.
	unfold isPDT in *.
	unfold isBE in *.
	destruct (lookup multiplexer (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> multiplexer *)
	rewrite removeDupIdentity ; intuition.
	subst addr'.
	rewrite <- beqAddrFalse in *.
	congruence.
Qed.

Lemma isPDTMultiplexerEqSCE addr' newEntry sh1entry0 s0:
isPDT multiplexer s0 ->
lookup addr' (memory s0) beqAddr = Some (SCE sh1entry0) ->
isPDT multiplexer {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |}.
Proof.
intros.
unfold isPDT. simpl.
destruct (beqAddr addr' multiplexer) eqn:beqmultiaddr'; try(exfalso ; congruence).
- (* addr' = multiplexer *)
	rewrite <- DTL.beqAddrTrue in beqmultiaddr'.
	rewrite beqmultiaddr' in *.
	unfold isPDT in *.
	rewrite H0 in *.
	exfalso ; congruence.
- (* addr' <> multiplexer *)
	rewrite removeDupIdentity ; intuition.
	subst addr'.
	unfold isPDT in *.
	rewrite H0 in *.
	exfalso ; congruence.
Qed.

Lemma isPDTMultiplexerEqSHE addr' newEntry sh1entry0 s0:
isPDT multiplexer s0 ->
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
isPDT multiplexer {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |}.
Proof.
intros.
unfold isPDT. simpl.
destruct (beqAddr addr' multiplexer) eqn:beqmultiaddr'; try(exfalso ; congruence).
- (* addr' = multiplexer *)
	rewrite <- DTL.beqAddrTrue in beqmultiaddr'.
	rewrite beqmultiaddr' in *.
	unfold isPDT in *.
	rewrite H0 in *.
	exfalso ; congruence.
- (* addr' <> multiplexer *)
	rewrite removeDupIdentity ; intuition.
	subst addr'.
	unfold isPDT in *.
	rewrite H0 in *.
	exfalso ; congruence.
Qed.


Lemma newFirstPDNotEq newBlockEntryAddr newFirstFreeSlotAddr pdinsertion x s :
lookup pdinsertion (memory s) beqAddr = Some (PDT x) ->
bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s ->
pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s ->
(exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr) ->
consistency s ->
newFirstFreeSlotAddr <> pdinsertion.
Proof.
intros HPDTs HbentryEnd Hfirstfree HfirstNotNull Hcons.
intro HnewFirstPDEq. (* pdinsertion would be in the free slots list so it would loop -> contradiction *)
assert(HfirstIsBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
specialize(HfirstIsBE pdinsertion x HPDTs).
destruct HfirstNotNull. unfold pdentryFirstFreeSlot in *.
rewrite HPDTs in *. intuition. subst.
specialize(HfirstIsBE H1). destruct (HfirstIsBE) as [_ HfreeNewFirst].
assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s)
	by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold NoDupInFreeSlotsList in *.
specialize(HNoDupInFreeSlotsList pdinsertion x HPDTs).
destruct HNoDupInFreeSlotsList.
unfold getFreeSlotsList in *. rewrite HPDTs in *.
destruct (beqAddr (firstfreeslot x) nullAddr) eqn:Hf.
rewrite <- DTL.beqAddrTrue in Hf. congruence.
assert(Hfreeslots : x0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot x) s (nbfreeslots x)) by intuition.
rewrite FreeSlotsListRec_unroll in Hfreeslots.
unfold getFreeSlotsListAux in *.
assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
rewrite Hiter1 in *.
destruct HfirstIsBE as [HfirstIsBE HfirstIsFreeSlot].
apply isBELookupEq in HfirstIsBE. destruct HfirstIsBE.
unfold bentryEndAddr in *.
rewrite H0 in *.
destruct (StateLib.Index.ltb (nbfreeslots x) zero) eqn:Hff ; try (subst ; cbn in * ; congruence).
destruct (StateLib.Index.pred (nbfreeslots x) ) eqn:Hfff ; try (exfalso ; intuition ; subst ; cbn in * ; congruence).
rewrite <- HbentryEnd in *.
subst x0.
assert(Hcontra : wellFormedFreeSlotsList
      (SomePaddr (firstfreeslot x) :: getFreeSlotsListRec maxIdx pdinsertion s i) <>
    False ) by intuition.
rewrite FreeSlotsListRec_unroll in Hcontra.
unfold getFreeSlotsListAux in *.
assert(Hiter2 : maxIdx = S (maxIdx - 1)).
{ assert(HEq : S (maxIdx - 1) = S maxIdx -1).
	{ assert(maxIdx > 0) by (apply maxIdxNotZero). lia. }
	rewrite HEq. lia.
}
rewrite Hiter2 in *.
rewrite HPDTs in *.
destruct (Index.ltb i zero) ; try (cbn in * ; congruence).
Qed.

(* DUP of newFirstPDNotEq *)
Lemma firstBlockPDNotEq firstFreeAddr pdinsertion x s :
lookup pdinsertion (memory s) beqAddr = Some (PDT x) ->
pdentryFirstFreeSlot pdinsertion firstFreeAddr s ->
(exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr) ->
consistency1 s ->
firstFreeAddr <> pdinsertion.
Proof.
intros HPDTs Hfirstfree HfirstNotNull Hcons.
intro HnewFirstPDEq. (* pdinsertion would be in the free slots list so it would loop -> contradiction *)
assert(HfirstIsBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
							by (unfold consistency1 in * ; intuition).
unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
specialize(HfirstIsBE pdinsertion x HPDTs).
destruct HfirstNotNull. unfold pdentryFirstFreeSlot in *.
rewrite HPDTs in *. intuition. subst x0. subst firstFreeAddr.
specialize(HfirstIsBE H1). destruct (HfirstIsBE) as [_ HfreeNewFirst].
assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s)
	by (unfold consistency1 in * ; intuition).
unfold NoDupInFreeSlotsList in *.
specialize(HNoDupInFreeSlotsList pdinsertion x HPDTs).
destruct HNoDupInFreeSlotsList.
unfold getFreeSlotsList in *. rewrite HPDTs in *.
destruct (beqAddr (firstfreeslot x) nullAddr) eqn:Hf.
rewrite <- DTL.beqAddrTrue in Hf. congruence.
assert(Hfreeslots : x0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot x) s (nbfreeslots x)) by intuition.
rewrite FreeSlotsListRec_unroll in Hfreeslots.
unfold getFreeSlotsListAux in *.
assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
rewrite Hiter1 in *.
destruct HfirstIsBE as [HfirstIsBE HfirstIsFreeSlot].
apply isBELookupEq in HfirstIsBE. destruct HfirstIsBE.
unfold bentryEndAddr in *.
rewrite H0 in *.
destruct (StateLib.Index.ltb (nbfreeslots x) zero) eqn:Hff ; try (subst ; cbn in * ; congruence).
Qed.

Lemma newFirstSCENotEq scentryaddr scentry newBlockEntryAddr newFirstFreeSlotAddr pdinsertion x s :
lookup pdinsertion (memory s) beqAddr = Some (PDT x) ->
lookup scentryaddr (memory s) beqAddr = Some (SCE scentry) ->
bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s ->
pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s ->
(exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr) ->
consistency s ->
newFirstFreeSlotAddr <> scentryaddr.
Proof.
intros HPDTs Hscentrys HbentryEnd Hfirstfree HfirstNotNull Hcons.
intro HnewFirstSCEEq. (* sceaddr would be in the free slots list so SCE and BE at the same time -> contradiction *)
assert(HfirstIsBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
							by (unfold consistency in * ; unfold consistency1 in *; intuition).
unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
specialize(HfirstIsBE pdinsertion x HPDTs).
destruct HfirstNotNull. unfold pdentryFirstFreeSlot in *.
rewrite HPDTs in *. intuition. subst x0.
specialize(HfirstIsBE H1). destruct (HfirstIsBE) as [_ HfreeNewFirst].
assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s)
	by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold NoDupInFreeSlotsList in *.
specialize(HNoDupInFreeSlotsList pdinsertion x HPDTs).
destruct HNoDupInFreeSlotsList.
assert(Hcontra : wellFormedFreeSlotsList x0 <> False) by intuition.
contradict Hcontra.
unfold getFreeSlotsList in *. rewrite HPDTs in *.
destruct (beqAddr (firstfreeslot x) nullAddr) eqn:Hf.
rewrite <- DTL.beqAddrTrue in Hf. congruence.
assert(Hfreeslots : x0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot x) s (nbfreeslots x)) by intuition.
rewrite FreeSlotsListRec_unroll in Hfreeslots.
unfold getFreeSlotsListAux in *.
assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
rewrite Hiter1 in *.
destruct HfirstIsBE as [HfirstIsBE HfirstIsFreeSlot].
apply isBELookupEq in HfirstIsBE. destruct HfirstIsBE.
unfold bentryEndAddr in *.
rewrite H0 in *.
destruct (StateLib.Index.ltb (nbfreeslots x) zero) eqn:Hff ; try (subst ; cbn in * ; congruence).
destruct (StateLib.Index.pred (nbfreeslots x) ) eqn:Hfff ; try (exfalso ; intuition ; subst ; cbn in * ; congruence).
rewrite <- Hfirstfree in *. rewrite H0 in *.
subst x0. rewrite <- HbentryEnd in *.
rewrite FreeSlotsListRec_unroll.
unfold getFreeSlotsListAux in *.
assert(Hiter2 : maxIdx = S (maxIdx - 1)).
{ assert(HEq : S (maxIdx - 1) = S maxIdx -1).
	{ assert(maxIdx > 0) by (apply maxIdxNotZero). lia. }
	rewrite HEq. lia.
}
rewrite Hiter2 in *.
destruct (Index.ltb i zero) ; try (cbn in * ; congruence).
cbn. rewrite HnewFirstSCEEq in *. rewrite Hscentrys. cbn. trivial.
Qed.

Lemma newFirstSHENotEq sh1entryaddr sh1entry newBlockEntryAddr newFirstFreeSlotAddr pdinsertion x s :
lookup pdinsertion (memory s) beqAddr = Some (PDT x) ->
lookup sh1entryaddr (memory s) beqAddr = Some (SHE sh1entry) ->
bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s ->
pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s ->
(exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr) ->
consistency s ->
newFirstFreeSlotAddr <> sh1entryaddr.
Proof.
intros HPDTs Hsh1entrys HbentryEnd Hfirstfree HfirstNotNull Hcons.
intro HnewFirstSHEEq. (* sh1addr would be in the free slots list so SHE and BE at the same time -> contradiction *)
assert(HfirstIsBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
specialize(HfirstIsBE pdinsertion x HPDTs).
destruct HfirstNotNull. unfold pdentryFirstFreeSlot in *.
rewrite HPDTs in *. intuition. subst x0.
specialize(HfirstIsBE H1). destruct (HfirstIsBE) as [_ HfreeNewFirst].
assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s)
	by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold NoDupInFreeSlotsList in *.
specialize(HNoDupInFreeSlotsList pdinsertion x HPDTs).
destruct HNoDupInFreeSlotsList.
assert(Hcontra : wellFormedFreeSlotsList x0 <> False) by intuition.
contradict Hcontra.
unfold getFreeSlotsList in *. rewrite HPDTs in *.
destruct (beqAddr (firstfreeslot x) nullAddr) eqn:Hf.
rewrite <- DTL.beqAddrTrue in Hf. congruence.
assert(Hfreeslots : x0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot x) s (nbfreeslots x)) by intuition.
rewrite FreeSlotsListRec_unroll in Hfreeslots.
unfold getFreeSlotsListAux in *.
assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
rewrite Hiter1 in *.
destruct HfirstIsBE as [HfirstIsBE HfirstIsFreeSlot].
apply isBELookupEq in HfirstIsBE. destruct HfirstIsBE.
unfold bentryEndAddr in *.
rewrite H0 in *.
destruct (StateLib.Index.ltb (nbfreeslots x) zero) eqn:Hff ; try (subst ; cbn in * ; congruence).
destruct (StateLib.Index.pred (nbfreeslots x) ) eqn:Hfff ; try (exfalso ; intuition ; subst ; cbn in * ; congruence).
rewrite <- Hfirstfree in *. rewrite H0 in *.
subst x0. rewrite <- HbentryEnd in *.
rewrite FreeSlotsListRec_unroll.
unfold getFreeSlotsListAux in *.
assert(Hiter2 : maxIdx = S (maxIdx - 1)).
{ assert(HEq : S (maxIdx - 1) = S maxIdx -1).
	{ assert(maxIdx > 0) by (apply maxIdxNotZero). lia. }
	rewrite HEq. lia.
}
rewrite Hiter2 in *.
destruct (Index.ltb i zero) ; try (cbn in * ; congruence).
cbn. rewrite HnewFirstSHEEq in *. rewrite Hsh1entrys. cbn. trivial.
Qed.

Lemma newFirstnewBlockNotEq newFirstFreeSlotAddr newBlockEntryAddr bentry pdinsertion x s :
lookup pdinsertion (memory s) beqAddr = Some (PDT x) ->
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) ->
bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s ->
pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s ->
(exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr) ->
consistency s ->
newFirstFreeSlotAddr <> newBlockEntryAddr.
Proof.
intros HPDTs HNewBs HbentryEnd Hfirstfree HfirstNotNull Hcons.
assert(HfirstIsBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
specialize(HfirstIsBE pdinsertion x HPDTs).
destruct HfirstNotNull. unfold pdentryFirstFreeSlot in *.
rewrite HPDTs in *. intuition. subst.
specialize(HfirstIsBE H2). destruct (HfirstIsBE) as [_ HfreeNewFirst].
assert(HNoDup: NoDupInFreeSlotsList s)
	by (unfold consistency in * ; unfold consistency1 in * ; intuition).
unfold NoDupInFreeSlotsList in *.
specialize(HNoDup pdinsertion x HPDTs).
destruct HNoDup.
unfold getFreeSlotsList in *.
rewrite HPDTs in *.
destruct (beqAddr (firstfreeslot x) nullAddr) eqn:HFirstNull ; try(exfalso ; congruence).
rewrite <- DTL.beqAddrTrue in HFirstNull. congruence.
remember (nbfreeslots x) as nbfreeslots.
remember (maxIdx + 1) as succMaxIdx.
assert(Hnbfreeslots : nbfreeslots < succMaxIdx).
{ destruct nbfreeslots. simpl;lia. }
revert Hnbfreeslots.
rewrite FreeSlotsListRec_unroll in*.
unfold getFreeSlotsListAux in *.
induction succMaxIdx.
* (* N=0 -> NotWellFormed *)
	simpl ; lia.
* (* N>0 *)
	clear IHsuccMaxIdx.
	destruct (Index.ltb nbfreeslots zero) eqn:Hf; intro; try(destruct H; subst x0; simpl in *; destruct H0;
    congruence).
	unfold bentryEndAddr in *.
	rewrite HNewBs in *.
	rewrite HbentryEnd in *. destruct H.
	destruct (Index.pred nbfreeslots) eqn:Hff ; (subst ; cbn in * ; intuition).
	(* Show cycle *)
	rewrite FreeSlotsListRec_unroll in*.
	unfold getFreeSlotsListAux in *.
	induction succMaxIdx.
	** (* N=0 -> NotWellFormed *)
			subst. intuition.
	** (* N>0 *)
		clear IHsuccMaxIdx.
		rewrite HNewBs in *.
		destruct (Index.ltb i zero) eqn:Hfff ; try(simpl in *; congruence).
		destruct (Index.pred i) eqn:Hffff ; try(simpl in *; congruence).
		subst. cbn in *.
		contradict H4.
		rewrite NoDup_cons_iff. intro Hcontra. apply Hcontra. simpl. left. reflexivity.
Qed.

Lemma getFreeSlotsListRecEqPDT freeslotaddr addr' newEntry s0 n nbfreeslotsleft:
(*lookup freeslotaddr (memory s0) beqAddr = Some (BE b) ->
(endAddr (blockrange b)) <> addr' ->*)
freeslotaddr <> addr' ->
~isBE addr' s0 ->
~isPADDR addr' s0 ->
	(*optionfreeslotslist = getFreeSlotsListRec n freeslotaddr s0 ->
	wellFormedFreeSlotsList optionfreeslotslist <> False ->
	NoDup (filterOption (optionfreeslotslist))
  ->*)
getFreeSlotsListRec n freeslotaddr {|
currentPartition := currentPartition s0;
memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} nbfreeslotsleft =
getFreeSlotsListRec n freeslotaddr s0 nbfreeslotsleft.
Proof.
revert n freeslotaddr nbfreeslotsleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	rewrite FreeSlotsListRec_unroll in *.
	unfold getFreeSlotsListAux in *.
	intuition.
- intros. subst.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct (beqAddr addr' freeslotaddr) eqn:Hnoteq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnoteq.	exfalso; congruence.
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlot ; intuition.
	destruct v eqn:Hv ; intuition.
	destruct (Index.pred nbfreeslotsleft) eqn:Hpred ; intuition.
	f_equal.
	specialize(IHn (endAddr (blockrange b)) i).
	destruct (beqAddr addr' (endAddr (blockrange b))) eqn:Hnexfreeslot ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnexfreeslot.
	rewrite <- Hnexfreeslot in *. intuition.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	destruct n ; intuition.
	destruct (Index.ltb i zero) eqn:iZero ; intuition.
	simpl.
	rewrite beqAddrTrue.
	unfold isBE in *.
	unfold isPADDR in *.
	destruct (lookup addr' (memory s0) beqAddr) eqn:Htest ; try(exfalso ; congruence).
	destruct v0 eqn:Hv0 ; intuition ; try(exfalso ; congruence).
	intuition.
rewrite <- beqAddrFalse in *.
destruct IHn ; intuition.
Qed.

Lemma getFreeSlotsListRecEqSCE freeslotaddr addr' newEntry s0 n nbfreeslotsleft:
(*lookup freeslotaddr (memory s0) beqAddr = Some (BE b) ->
(endAddr (blockrange b)) <> addr' ->*)
freeslotaddr <> addr' ->
~isBE addr' s0 ->
~isPADDR addr' s0 ->
	(*optionfreeslotslist = getFreeSlotsListRec n freeslotaddr s0 ->
	wellFormedFreeSlotsList optionfreeslotslist <> False ->
	NoDup (filterOption (optionfreeslotslist))
  ->*)
getFreeSlotsListRec n freeslotaddr {|
currentPartition := currentPartition s0;
memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} nbfreeslotsleft =
getFreeSlotsListRec n freeslotaddr s0 nbfreeslotsleft.
Proof.
revert n freeslotaddr nbfreeslotsleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	rewrite FreeSlotsListRec_unroll in *.
	unfold getFreeSlotsListAux in *.
	intuition.
- intros. subst.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct (beqAddr addr' freeslotaddr) eqn:Hnoteq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnoteq.	exfalso; congruence.
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlot ; intuition.
	destruct v eqn:Hv ; intuition.
	destruct (Index.pred nbfreeslotsleft) eqn:Hpred ; intuition.
	f_equal.
	specialize(IHn (endAddr (blockrange b)) i).
	intuition.
	destruct (beqAddr addr' (endAddr (blockrange b))) eqn:Hnexfreeslot ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnexfreeslot.
	rewrite <- Hnexfreeslot in *. intuition.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct n ; intuition.
	rewrite beqAddrTrue in *.
	unfold isBE in *.
	unfold isPADDR in *.
	destruct (lookup addr' (memory s0) beqAddr) eqn:Htest ; try(exfalso ; congruence).
	destruct v0 eqn:Hv0 ; intuition  ;try(exfalso ; congruence).
	intuition.
rewrite <- beqAddrFalse in *.
destruct IHn ; intuition.
Qed.

Lemma getFreeSlotsListRecEqSHE freeslotaddr addr' newEntry s0 n nbfreeslotsleft:
(*lookup freeslotaddr (memory s0) beqAddr = Some (BE b) ->
(endAddr (blockrange b)) <> addr' ->*)
freeslotaddr <> addr' ->
~isBE addr' s0 ->
~isPADDR addr' s0 ->
	(*optionfreeslotslist = getFreeSlotsListRec n freeslotaddr s0 ->
	wellFormedFreeSlotsList optionfreeslotslist <> False ->
	NoDup (filterOption (optionfreeslotslist))
  ->*)
getFreeSlotsListRec n freeslotaddr {|
currentPartition := currentPartition s0;
memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} nbfreeslotsleft =
getFreeSlotsListRec n freeslotaddr s0 nbfreeslotsleft.
Proof.
revert n freeslotaddr nbfreeslotsleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	rewrite FreeSlotsListRec_unroll in *.
	unfold getFreeSlotsListAux in *.
	intuition.
- intros. subst.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct (beqAddr addr' freeslotaddr) eqn:Hnoteq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnoteq.	exfalso; congruence.
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlot ; intuition.
	destruct v eqn:Hv ; intuition.
	destruct (Index.pred nbfreeslotsleft) eqn:Hpred ; intuition.
	f_equal.
	specialize(IHn (endAddr (blockrange b)) i).
	intuition.
	destruct (beqAddr addr' (endAddr (blockrange b))) eqn:Hnexfreeslot ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnexfreeslot.
	rewrite <- Hnexfreeslot in *. intuition.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct n ; intuition.
	rewrite beqAddrTrue in *.
	unfold isBE in *.
	unfold isPADDR in *.
	destruct (lookup addr' (memory s0) beqAddr) eqn:Htest ; try(exfalso ; congruence).
	destruct v0 eqn:Hv0 ; intuition  ;try(exfalso ; congruence).
	intuition.
rewrite <- beqAddrFalse in *.
destruct IHn ; intuition.
Qed.


Lemma getFreeSlotsListRecEqBE freeslotaddr addr' newEntry s0 n nbfreeslotsleft optionfreeslotslist:
(*lookup freeslotaddr (memory s0) beqAddr = Some (BE b) ->
(endAddr (blockrange b)) <> addr' ->*)

freeslotaddr <> addr' ->
isBE addr' s0 ->
	optionfreeslotslist = getFreeSlotsListRec n freeslotaddr s0 nbfreeslotsleft ->
	wellFormedFreeSlotsList optionfreeslotslist <> False ->
	NoDup (filterOptionPaddr (optionfreeslotslist)) ->
	~ In addr' (filterOptionPaddr optionfreeslotslist)
  ->
getFreeSlotsListRec n freeslotaddr {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} nbfreeslotsleft =
(*getFreeSlotsListRec n freeslotaddr s0.*)
optionfreeslotslist.
Proof.
assert(Hnbfreeslots : nbfreeslotsleft < maxIdx+1).
{ destruct nbfreeslotsleft. simpl ;lia. }
revert n nbfreeslotsleft freeslotaddr optionfreeslotslist Hnbfreeslots.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros. intuition.
- intros. subst.
	repeat rewrite FreeSlotsListRec_unroll.
	unfold getFreeSlotsListAux.
	simpl.
	destruct (beqAddr addr' freeslotaddr) eqn:Hnoteq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Hnoteq.	exfalso; congruence.
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlot ; intuition.
	destruct v eqn:Hv ; intuition.
	destruct (Index.pred nbfreeslotsleft) eqn:Hpred ; intuition.
	f_equal.
	specialize(IHn i (endAddr (blockrange b)) (getFreeSlotsListRec n (endAddr (blockrange b)) s0 i)).
	intuition.
	simpl in *. rewrite HfreeSlot in *. rewrite Hpred in *.
	apply IHn ; intuition.
	+ unfold Index.pred in *. destruct (gt_dec nbfreeslotsleft 0) ; intuition ; try congruence.
		inversion Hpred. simpl. lia.
	+	rewrite H1 in *.
		rewrite FreeSlotsListRec_unroll in *.
		unfold getFreeSlotsListAux in *.
		contradict H4.
		induction n ; intuition.
		unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Haddr' ; try(exfalso ; congruence).
		destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
		simpl. intuition.
		destruct (Index.ltb i zero) eqn:Hf ; try(cbn in * ; intuition).
		destruct (Index.pred i) eqn:Hff ; try(cbn in * ; intuition).
	+ assert(HNoDupEq : NoDup
       ([] ++ filterOptionPaddr
          (SomePaddr freeslotaddr
           :: getFreeSlotsListRec n (endAddr (blockrange b)) s0 i)) ->
						NoDup (filterOptionPaddr (getFreeSlotsListRec n (endAddr (blockrange b)) s0 i))).
	{ eapply NoDup_remove_1. }
	intuition. (*apply HNoDupEq. simpl. intuition. intuition.*)
+	contradict H4.
	apply in_cons. intuition.
Qed.
(* Previous statement true also if addr' in the list, but the endAddr does not point
	to a free slot like before -> maybe change the code to erase the entry before *)

Lemma getFreeSlotsListRecEqN addr s n1 n2 n3 freeslotslist:
freeslotslist = getFreeSlotsListRec n1 addr s n2 ->
n2 < n1 ->
(*forall (n3 : nat) (n4 : index),*)
n1 <= n3 ->
n2 < n3 ->
freeslotslist = getFreeSlotsListRec n3 addr s n2.
Proof.
revert freeslotslist addr n1 n3.
revert n2.
destruct n2.
induction i.
- intuition.
	destruct n3 ; intuition.
	+ simpl. intros.
		apply PeanoNat.Nat.nlt_0_r in H2. exfalso ; congruence.
	+	destruct n1 ; intuition.
		* simpl. intros.
			apply PeanoNat.Nat.nlt_0_r in H0. exfalso ; congruence.
- 	destruct n3 ; intuition.
	+ simpl. intros.
		apply PeanoNat.Nat.nlt_0_r in H2. exfalso ; congruence.
	+	destruct n1 ; intuition.
		* simpl. intros.
			apply PeanoNat.Nat.nlt_0_r in H0. exfalso ; congruence.
		*
			rewrite FreeSlotsListRec_unroll in *.
			unfold getFreeSlotsListAux in *.
			simpl in *.
destruct (lookup addr (memory s) beqAddr) eqn:Haddr ; try(exfalso ; congruence) ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.


assert(HimaxIdx : i <= maxIdx) by lia. destruct (Nat.succ_le_mono 0 i).
						specialize (IHi HimaxIdx (getFreeSlotsListRec n1 (endAddr (blockrange b)) s
         {|
           i := i - 0;
           Hi :=
             StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
         |}) (endAddr (blockrange b)) n1 n3 ).
					subst freeslotslist. f_equal.
					assert(getFreeSlotsListRec n1 (endAddr (blockrange b)) s
        {|
          i := i - 0;
          Hi :=
            StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
        |} = getFreeSlotsListRec n1 (endAddr (blockrange b)) s
  {|
    i := i - 0;
    Hi :=
      StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
  |}) by intuition.
					assert(getFreeSlotsListRec n3 (endAddr (blockrange b)) s {| i := i; Hi := HimaxIdx |} =
getFreeSlotsListRec n3 (endAddr (blockrange b)) s
  {|
    i := i - 0;
    Hi :=
      StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
  |}
). f_equal.
destruct i. f_equal. apply proof_irrelevance.
					 f_equal. apply proof_irrelevance.
					rewrite <- H3.


					eapply IHi ; try(assumption); try(lia). f_equal.
					destruct i. f_equal. apply proof_irrelevance.
					f_equal. apply proof_irrelevance.

Qed.

Lemma getKSEntriesInStructAuxEqPDT structure addr' newEntry s0 n entriesleft:
structure <> addr' ->
isPDT addr' s0 ->
getKSEntriesInStructAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} entriesleft =
getKSEntriesInStructAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesInStructAux in *.
	intuition.
- intros.
	unfold getKSEntriesInStructAux.
	fold getKSEntriesInStructAux.
	destruct (Index.ltb entriesleft zero) eqn:Hltbzero ; intuition.
	destruct (Paddr.addPaddrIdx structure entriesleft) eqn:Hentry ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isPDT in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqIdx entriesleft zero) eqn:Hiszero ; intuition.
	destruct (Index.pred entriesleft) eqn:Hpredentry ; intuition.
	f_equal.
	specialize (IHn structure i).
	destruct IHn ; intuition.
Qed.


Lemma getKSEntriesAuxEqPDT structure addr' newEntry s0 n:
structure <> addr' ->
isPDT addr' s0 ->
getKSEntriesAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getKSEntriesAux n structure s0.
Proof.
revert n structure.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesAux in *.
	intuition.
- intros.
	unfold getKSEntriesAux.
	fold getKSEntriesAux.
	destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isPDT in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqAddr addr' p0) eqn:Haddr'Eq0 ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq0.
	subst p0.
	unfold isPDT in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.
	assert(HlookupEq' : lookup p0 (memory s') beqAddr = lookup p0 (memory s0) beqAddr).
	{ unfold s'. cbn.
		rewrite Haddr'Eq0.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq'.

	destruct (lookup p0 (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.
	f_equal.
	apply getKSEntriesInStructAuxEqPDT ; intuition.
  specialize (IHn p0).
	destruct IHn ; intuition.
	subst p0. unfold isPDT in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	destruct (beqAddr p0 nullAddr) eqn:Hp0Null ; intuition.
	apply getKSEntriesInStructAuxEqPDT ; intuition.
Qed.

Lemma getKSEntriesEqPDT partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
StructurePointerIsKS s0 ->
(structure newEntry) = (structure pdentry0) ->
getKSEntries partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getKSEntries partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructKS HstructEq.
assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; trivial).
unfold getKSEntries.
unfold s' at 1. simpl lookup.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	subst addr'.
	rewrite Hlookuppds0.
	rewrite HstructEq.
	destruct (beqAddr (structure pdentry0) nullAddr) eqn:structNull ; intuition.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure pdentry0) s') =
  (getKSEntriesAux maxNbPrepare (structure pdentry0) s0)).
	{ apply getKSEntriesAuxEqPDT ; intuition.
		unfold StructurePointerIsKS in *.
		specialize (HstructKS partition pdentry0 Hlookuppds0).
		unfold isKS in *.
		subst partition.
		destruct (lookup (structure pdentry0) (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
    rewrite <- beqAddrFalse in *.
    intuition.
	}
	rewrite HEq.
	intuition.
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hlookupparts0 ; intuition.
	destruct v ; intuition.
	destruct (beqAddr (structure p) nullAddr) eqn:structNull ; intuition.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure p) s') =
  (getKSEntriesAux maxNbPrepare (structure p) s0)).
	{
		apply getKSEntriesAuxEqPDT ; intuition.
		unfold StructurePointerIsKS in *.
		specialize (HstructKS partition p Hlookupparts0).
		unfold isKS in *.
		subst addr'.
		unfold isPDT in *.
		destruct (lookup (structure p) (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
    rewrite <- beqAddrFalse in *.
    intuition.
	}
	rewrite HEq.
	intuition.
Qed.

Lemma getKSEntriesEqPDTNotInPart partition addr' newEntry s0:
isPDT addr' s0 ->
partition <> addr' ->
StructurePointerIsKS s0 ->
getKSEntries partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getKSEntries partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpartNotEq HstructKS.
unfold getKSEntries.
unfold s' at 1. simpl lookup.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	subst addr'.
	congruence.
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hlookupparts0 ; intuition.
	destruct v ; intuition.
	destruct (beqAddr (structure p) nullAddr) eqn:structNull ; intuition.
	fold s'.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure p) s') =
  (getKSEntriesAux maxNbPrepare (structure p) s0)).
	{
		apply getKSEntriesAuxEqPDT ; intuition.
		unfold StructurePointerIsKS in *.
		specialize (HstructKS partition p Hlookupparts0).
		unfold isKS in *.
		subst addr'.
		unfold isPDT in *.
		destruct (lookup (structure p) (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
    rewrite <- beqAddrFalse in *.
    intuition.
	}
	rewrite HEq.
	intuition.
Qed.

Lemma lastNotEmpty A (lastElem: A) el list default1 default2:
lastElem = last (el::list) default1
-> lastElem = last (el::list) default2.
Proof.
revert el. induction list.
- intros el Hlast. simpl in *. assumption.
- intros el Hlast. simpl in *. specialize(IHlist a Hlast). assumption.
Qed.

Lemma lastRec A (lastElem: A) el list default:
lastElem = last (el::list) default
-> lastElem = last list el.
Proof.
destruct list.
- intro Hlast. simpl in *. assumption.
- intro Hlast. assert(HlastNewDef: lastElem = last (el::a::list) el).
  {
    apply lastNotEmpty with default. assumption.
  }
  simpl in *. assumption.
Qed.

Lemma lastRecInc A (lastElem: A) list el default:
lastElem = last list el
-> lastElem = last (el::list) default.
Proof.
destruct list.
- intro Hlast. simpl in *. assumption.
- intro Hlast. assert(HlastNewDef: lastElem = last (a::list) default).
  {
    apply lastNotEmpty with el. assumption.
  }
  simpl in *. assumption.
Qed.

Lemma lastOfNotEmptyIsIn A (el: A) first list default:
el = last (first::list) default
-> In el (first::list).
Proof.
revert first default. induction list.
- simpl. intros first default Hlast. left. intuition.
- intros first default Hlast.
  assert(HlastRec1: el = last (a :: list) first).
  { apply lastRec with default. assumption. }
  assert(Hres: In el (a::list)).
  { apply IHlist with first. assumption. }
  simpl. simpl in Hres. intuition.
Qed.


Lemma isListOfKernelsAuxRec kernList (initKern: paddr) kernel newKern s:
newKern <> nullAddr
-> isListOfKernelsAux kernList initKern s
-> kernel = last kernList initKern
-> lookup (CPaddr (kernel + nextoffset)) (memory s) beqAddr = Some (PADDR newKern)
-> kernel + nextoffset <= maxAddr
-> isListOfKernelsAux (kernList ++ [newKern]) initKern s.
Proof.
intro HnewKernNotNull. revert initKern. induction kernList.
- simpl. intros initKern HkernList HkernelIsLast HlookupKernNext Hle. subst kernel. intuition.
- intros initKern HkernList HkernelIsLast HlookupKernNext Hle. simpl. simpl in HkernList.
  destruct HkernList as (HlookupInitNext & HleBis & HaNotNull & HkernListRec). split. assumption. split.
  assumption. split. assumption. apply IHkernList; try(assumption). apply lastRec with initKern. assumption.
Qed.

Lemma getKSEntriesAuxImplInRec block n (kernel nextkernel: paddr) s:
In block (filterOptionPaddr (getKSEntriesAux (S n) kernel s))
-> ~In block (filterOptionPaddr (getKSEntriesInStructAux (maxIdx + 1) kernel s
                            (CIndex (kernelStructureEntriesNb - 1))))
-> nextKSentry (CPaddr (kernel + nextoffset)) nextkernel s
-> In block (filterOptionPaddr (getKSEntriesAux n nextkernel s)).
Proof.
intros HblockInKSEntries HblockNotInFirst HnextKS. cbn -[kernelStructureEntriesNb] in HblockInKSEntries.
  unfold Paddr.addPaddrIdx in HblockInKSEntries. unfold nextKSentry in HnextKS. unfold CPaddr in HnextKS.
  destruct (le_dec (kernel + nextoffset) maxAddr) eqn:HleKernNext; try(cbn -[kernelStructureEntriesNb] in
          HblockInKSEntries; exfalso; congruence).
  set(blockKern := {|
                     p := kernel + nextoffset;
                     Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel nextoffset l
                   |}). fold blockKern in HblockInKSEntries.
  assert(HblockKern: blockKern = {| p := kernel + nextoffset;
                                    Hp := ADT.CPaddr_obligation_1 (kernel + nextoffset) l |}).
  { subst blockKern. f_equal. }
  rewrite <-HblockKern in HnextKS.
  destruct (lookup blockKern (memory s) beqAddr) eqn:HlookupBlockKern; try(cbn -[kernelStructureEntriesNb]
          in HblockInKSEntries; exfalso; congruence).
  destruct v; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence). subst nextkernel.
  destruct (lookup p (memory s) beqAddr) eqn:HlookupP; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries;
          exfalso; congruence).
  destruct v; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence).
  + rewrite filterOptionPaddrSplit in HblockInKSEntries. apply in_app_or in HblockInKSEntries.
    destruct HblockInKSEntries as [HblockInKern | Hrec]; try(exfalso; congruence). assumption.
  + destruct (beqAddr p {| p := 0; Hp := ADT.CPaddr_obligation_1 0 (PeanoNat.Nat.le_0_l maxAddr) |}); try(cbn
          -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence).
Qed.

Lemma getKSEntriesAuxImplInStruct block n (initKern kernel: paddr) s:
nullAddrExists s
-> In block (filterOptionPaddr (getKSEntriesAux n kernel s))
-> (exists kernList, isListOfKernelsAux kernList initKern s /\ kernel = last kernList initKern)
-> exists kern kernList, In block (filterOptionPaddr (getKSEntriesInStructAux (maxIdx + 1) kern s
                            (CIndex (kernelStructureEntriesNb - 1))))
    /\ isListOfKernelsAux kernList initKern s
    /\ kern = last kernList initKern.
Proof.
intro Hnull. revert kernel. revert initKern. induction n; try(simpl; intros; exfalso; congruence).
intros initKern kernel HblockInKSEntries HinitKern. cbn -[kernelStructureEntriesNb] in HblockInKSEntries.
unfold Paddr.addPaddrIdx in HblockInKSEntries. destruct HinitKern as [kernList (HkernList & HkernelIsLast)].
destruct (le_dec (kernel + nextoffset) maxAddr) eqn:HleKernNext; try(cbn -[kernelStructureEntriesNb] in
        HblockInKSEntries; exfalso; congruence).
set(blockKern := {|
                   p := kernel + nextoffset;
                   Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel nextoffset l
                 |}). fold blockKern in HblockInKSEntries.
destruct (lookup blockKern (memory s) beqAddr) eqn:HlookupBlockKern; try(cbn -[kernelStructureEntriesNb]
        in HblockInKSEntries; exfalso; congruence).
destruct v; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence).
destruct (lookup p (memory s) beqAddr) eqn:HlookupP; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries;
        exfalso; congruence).
destruct v; try(cbn -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence).
- rewrite filterOptionPaddrSplit in HblockInKSEntries. apply in_app_or in HblockInKSEntries.
  destruct HblockInKSEntries as [HblockInKern | Hrec].
  + exists kernel. exists kernList. simpl. intuition.
  + apply IHn with p. assumption. exists (kernList++[p]). split.
    apply isListOfKernelsAuxRec with kernel; try(assumption).
    * intro Hcontra. subst p. unfold nullAddrExists in Hnull. unfold isPADDR in Hnull. rewrite HlookupP in Hnull.
      congruence.
    * unfold CPaddr. rewrite HleKernNext.
      assert(Heq: blockKern = {| p := kernel + nextoffset;
                                 Hp := ADT.CPaddr_obligation_1 (kernel + nextoffset) l |}).
      { subst blockKern. f_equal. }
      rewrite <-Heq. assumption.
    * rewrite last_last. reflexivity.
- destruct (beqAddr p {| p := 0; Hp := ADT.CPaddr_obligation_1 0 (PeanoNat.Nat.le_0_l maxAddr) |}); try(cbn
        -[kernelStructureEntriesNb] in HblockInKSEntries; exfalso; congruence).
  exists kernel. exists kernList. simpl. intuition.
Qed.



(* DUP *)
Lemma getKSEntriesInStructAuxEqSCE structure addr' newEntry s0 n entriesleft:
isSCE addr' s0 ->
getKSEntriesInStructAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} entriesleft =
getKSEntriesInStructAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesInStructAux in *.
	intuition.
- intros.
	unfold getKSEntriesInStructAux.
	fold getKSEntriesInStructAux.
	destruct (Index.ltb entriesleft zero) eqn:Hltbzero ; intuition.
	destruct (Paddr.addPaddrIdx structure entriesleft) eqn:Hentry ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isSCE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqIdx entriesleft zero) eqn:Hiszero ; intuition.
	destruct (Index.pred entriesleft) eqn:Hpredentry ; intuition.
	f_equal.
	specialize (IHn structure i).
	destruct IHn ; intuition.
Qed.

(* DUP *)
Lemma getKSEntriesAuxEqSCE structure addr' newEntry s0 n:
isSCE addr' s0 ->
getKSEntriesAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getKSEntriesAux n structure s0.
Proof.
revert n structure.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesAux in *.
	intuition.
- intros.
	unfold getKSEntriesAux.
	fold getKSEntriesAux.
	destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isSCE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqAddr addr' p0) eqn:Haddr'Eq0 ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq0.
	subst p0.
	unfold isSCE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.
	assert(HlookupEq' : lookup p0 (memory s') beqAddr = lookup p0 (memory s0) beqAddr).
	{ unfold s'. cbn.
		rewrite Haddr'Eq0.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq'.

	destruct (lookup p0 (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.
	f_equal.
	apply getKSEntriesInStructAuxEqSCE ; intuition.
	specialize (IHn p0).
	destruct IHn ; intuition.
	destruct (beqAddr p0 nullAddr) eqn:Hp0Null ; intuition.
	apply getKSEntriesInStructAuxEqSCE ; intuition.
Qed.

(* DUP *)
Lemma getKSEntriesEqSCE partition addr' newEntry s0 pdentry0:
lookup partition (memory s0) beqAddr = Some (PDT pdentry0) ->
isSCE addr' s0 ->
getKSEntries partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getKSEntries partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HPDTaddrs0 (*HstructKS HstructEq*).
unfold getKSEntries.
unfold s' at 1. simpl lookup.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isSCE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	rewrite Hlookuppds0.
	destruct (beqAddr (structure pdentry0) nullAddr) eqn:structNull ; intuition.
	fold s'.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure pdentry0) s') =
  (getKSEntriesAux maxNbPrepare (structure pdentry0) s0)).
	{
		apply getKSEntriesAuxEqSCE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.

(* DUP *)
Lemma getKSEntriesInStructAuxEqSHE structure addr' newEntry s0 n entriesleft:
isSHE addr' s0 ->
getKSEntriesInStructAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} entriesleft =
getKSEntriesInStructAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesInStructAux in *.
	intuition.
- intros.
	unfold getKSEntriesInStructAux.
	fold getKSEntriesInStructAux.
	destruct (Index.ltb entriesleft zero) eqn:Hltbzero ; intuition.
	destruct (Paddr.addPaddrIdx structure entriesleft) eqn:Hentry ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isSHE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqIdx entriesleft zero) eqn:Hiszero ; intuition.
	destruct (Index.pred entriesleft) eqn:Hpredentry ; intuition.
	f_equal.
	specialize (IHn structure i).
	destruct IHn ; intuition.
Qed.

(* DUP *)
Lemma getKSEntriesAuxEqSHE structure addr' newEntry s0 n:
isSHE addr' s0 ->
getKSEntriesAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getKSEntriesAux n structure s0.
Proof.
revert n structure.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesAux in *.
	intuition.
- intros.
	unfold getKSEntriesAux.
	fold getKSEntriesAux.
	destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isSHE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqAddr addr' p0) eqn:Haddr'Eq0 ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq0.
	subst p0.
	unfold isSHE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.
	assert(HlookupEq' : lookup p0 (memory s') beqAddr = lookup p0 (memory s0) beqAddr).
	{ unfold s'. cbn.
		rewrite Haddr'Eq0.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq'.

	destruct (lookup p0 (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	f_equal.
	apply getKSEntriesInStructAuxEqSHE ; intuition.
	specialize (IHn p0).
	destruct IHn ; intuition.
	destruct (beqAddr p0 nullAddr) eqn:Hp0Null ; intuition.
	apply getKSEntriesInStructAuxEqSHE ; intuition.
Qed.

(* DUP *)
Lemma getKSEntriesEqSHE partition addr' newEntry s0 pdentry0:
lookup partition (memory s0) beqAddr = Some (PDT pdentry0) ->
isSHE addr' s0 ->
getKSEntries partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getKSEntries partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HPDTaddrs0.
unfold getKSEntries.
unfold s' at 1. simpl lookup.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isSHE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	rewrite Hlookuppds0.
	destruct (beqAddr (structure pdentry0) nullAddr) eqn:structNull ; intuition.
	fold s'.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure pdentry0) s') =
  (getKSEntriesAux maxNbPrepare (structure pdentry0) s0)).
	{
		apply getKSEntriesAuxEqSHE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.

Lemma getKSEntriesInStructAuxEqBE structure addr' newEntry s0 n entriesleft:
isBE addr' s0 ->
getKSEntriesInStructAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} entriesleft =
getKSEntriesInStructAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesInStructAux in *.
	intuition.
- intros.
	unfold getKSEntriesInStructAux.
	fold getKSEntriesInStructAux.
	destruct (Index.ltb entriesleft zero) eqn:Hltbzero ; intuition.
	destruct (Paddr.addPaddrIdx structure entriesleft) eqn:Hentry ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isBE in *.

	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue.

	destruct (beqIdx entriesleft zero) eqn:Hiszero ; intuition.
	destruct (Index.pred entriesleft) eqn:Hpredentry ; intuition.
	f_equal.
	specialize (IHn structure i).
	destruct IHn ; intuition.


	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqIdx entriesleft zero) eqn:Hiszero ; intuition.
	destruct (Index.pred entriesleft) eqn:Hpredentry ; intuition.
	f_equal.
	specialize (IHn structure i).
	destruct IHn ; intuition.
Qed.

Lemma getKSEntriesAuxEqBE structure addr' newEntry s0 n:
isBE addr' s0 ->
getKSEntriesAux n structure {|
currentPartition := currentPartition s0;
memory :=  add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getKSEntriesAux n structure s0.
Proof.
revert n structure.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getKSEntriesAux in *.
	intuition.
- intros.
	unfold getKSEntriesAux in *.
	fold getKSEntriesAux in *.
	destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
	destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
	rewrite <- DTL.beqAddrTrue in Haddr'Eq.
	subst p.
	unfold isBE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	assert(HlookupEq : lookup p (memory s') beqAddr = lookup p (memory s0) beqAddr).
	{ unfold s'. simpl.
		rewrite Haddr'Eq.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq.

	destruct (lookup p (memory s0) beqAddr) eqn:Hoffset' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	destruct (beqAddr addr' p0) eqn:Haddr'Eq0 ; try(exfalso ; congruence).
	+ (* addr' = p0 *)
	rewrite <- DTL.beqAddrTrue in Haddr'Eq0.
	subst p0.
	unfold isBE in *.
	destruct (lookup addr' (memory s0) beqAddr) eqn:Hlookups0 ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	unfold s' at 1. simpl. rewrite beqAddrTrue. trivial.

	
	f_equal.
	apply getKSEntriesInStructAuxEqBE ; intuition.
	unfold isBE. rewrite Hlookups0. trivial.
  specialize (IHn addr' ).
	destruct IHn ; intuition.
	+ (* addr' <> p0 *)
	assert(HlookupEq' : lookup p0 (memory s') beqAddr = lookup p0 (memory s0) beqAddr).
	{ unfold s'. cbn.
		rewrite Haddr'Eq0.
		rewrite <- beqAddrFalse in *.
	 	repeat rewrite removeDupIdentity ; intuition.
	}
	rewrite HlookupEq'.

	destruct (lookup p0 (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.

	
	f_equal. apply getKSEntriesInStructAuxEqBE ; intuition.
	specialize (IHn p0).
	destruct IHn ; intuition.

	destruct (beqAddr p0 nullAddr) eqn:Hp0Null ; intuition.
	apply getKSEntriesInStructAuxEqBE ; intuition.
Qed.

(* After state modification, type is still BE, so the kernel entries did not change
		which means the types we found at the same addresses as the previous structure
		are still the same, even if the content might have changed *)
Lemma getKSEntriesEqBE partition addr' newEntry s0:
isBE addr' s0 ->
getKSEntries partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}  =
getKSEntries partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0.
unfold getKSEntries.
unfold s' at 1. simpl lookup.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isBE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	trivial.
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence) ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.
	destruct (beqAddr (structure p) nullAddr) eqn:structNull ; intuition.
	assert(HEq :  (getKSEntriesAux maxNbPrepare (structure p) s') =
  (getKSEntriesAux maxNbPrepare (structure p) s0)).
	{	eapply getKSEntriesAuxEqBE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.

Lemma isListOfKernelsAuxEqBE partition addr' newEntry kernList s0:
isListOfKernelsAux kernList partition {|
                                        currentPartition := currentPartition s0;
                                        memory := add addr' (BE newEntry)
                                                    (memory s0) beqAddr
                                      |}
-> isListOfKernelsAux kernList partition s0.
Proof.
revert partition. induction kernList.
- intuition.
- intros partition HlistIsListOkKerns. simpl in *.
  destruct (beqAddr addr' (CPaddr (partition + nextoffset))) eqn:HbeqAddrNextOffset;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrNextOffset. rewrite removeDupIdentity in HlistIsListOkKerns; intuition.
Qed.

Lemma isListOfKernelsEqBE partition addr' newEntry kernList s0:
isListOfKernels kernList partition {|
                                     currentPartition := currentPartition s0;
                                     memory := add addr' (BE newEntry)
                                                 (memory s0) beqAddr
                                   |}
-> isListOfKernels kernList partition s0.
Proof.
intro HisKernLists. destruct kernList.
- intuition.
- simpl in *. destruct HisKernLists as [pdentry HisKernLists]. exists pdentry.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HisKernLists; intuition.
  apply isListOfKernelsAuxEqBE with addr' newEntry; assumption.
Qed.

Lemma isListOfKernelsAuxEqBERev partition addr' newEntry kernList s0:
isBE addr' s0
-> isListOfKernelsAux kernList partition s0
-> isListOfKernelsAux kernList partition {|
                                           currentPartition := currentPartition s0;
                                           memory := add addr' (BE newEntry)
                                                       (memory s0) beqAddr
                                         |}.
Proof.
intro HBE. revert partition. induction kernList.
- intuition.
- intros partition HlistIsListOkKerns0. simpl in *.
  destruct HlistIsListOkKerns0 as (HlookupNext & HnextNotNull & HaNotNull & HlistIsListOkKerns0Rec).
  destruct (beqAddr addr' (CPaddr (partition + nextoffset))) eqn:HbeqAddrNextOffset.
  {
    rewrite <-DTL.beqAddrTrue in HbeqAddrNextOffset. subst addr'. exfalso. unfold isBE in HBE.
    rewrite HlookupNext in HBE. congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrNextOffset. rewrite removeDupIdentity; intuition.
Qed.

Lemma isListOfKernelsEqBERev partition addr' newEntry kernList s0:
isListOfKernels kernList partition s0
-> isBE addr' s0
-> isListOfKernels kernList partition {|
                                        currentPartition := currentPartition s0;
                                        memory := add addr' (BE newEntry)
                                                    (memory s0) beqAddr
                                      |}.
Proof.
intros HisKernLists0 HBE. destruct kernList.
- intuition.
- simpl in *. destruct HisKernLists0 as [pdentry (HlookupPart & HstructNotNull & HstructIsP & HisKernLists0Rec)].
  exists pdentry.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  {
    unfold isBE in HBE. rewrite <-DTL.beqAddrTrue in HbeqAddrPart. subst addr'. rewrite HlookupPart in HBE.
    exfalso; congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; intuition.
  apply isListOfKernelsAuxEqBERev; assumption.
Qed.

Lemma isListOfKernelsAuxEqSCE partition addr' newEntry kernList s0:
isListOfKernelsAux kernList partition {|
                                        currentPartition := currentPartition s0;
                                        memory := add addr' (SCE newEntry)
                                                    (memory s0) beqAddr
                                      |}
-> isListOfKernelsAux kernList partition s0.
Proof.
revert partition. induction kernList.
- intuition.
- intros partition HlistIsListOkKerns. simpl in *.
  destruct (beqAddr addr' (CPaddr (partition + nextoffset))) eqn:HbeqAddrNextOffset;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrNextOffset. rewrite removeDupIdentity in HlistIsListOkKerns; intuition.
Qed.

Lemma isListOfKernelsEqSCE partition addr' newEntry kernList s0:
isListOfKernels kernList partition {|
                                     currentPartition := currentPartition s0;
                                     memory := add addr' (SCE newEntry)
                                                 (memory s0) beqAddr
                                   |}
-> isListOfKernels kernList partition s0.
Proof.
intro HisKernLists. destruct kernList.
- intuition.
- simpl in *. destruct HisKernLists as [pdentry HisKernLists]. exists pdentry.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HisKernLists; intuition.
  apply isListOfKernelsAuxEqSCE with addr' newEntry; assumption.
Qed.

Lemma isListOfKernelsAuxEqSHE partition addr' newEntry kernList s0:
isListOfKernelsAux kernList partition {|
                                        currentPartition := currentPartition s0;
                                        memory := add addr' (SHE newEntry)
                                                    (memory s0) beqAddr
                                      |}
-> isListOfKernelsAux kernList partition s0.
Proof.
revert partition. induction kernList.
- intuition.
- intros partition HlistIsListOkKerns. simpl in *.
  destruct (beqAddr addr' (CPaddr (partition + nextoffset))) eqn:HbeqAddrNextOffset;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrNextOffset. rewrite removeDupIdentity in HlistIsListOkKerns; intuition.
Qed.

Lemma isListOfKernelsEqSHE partition addr' newEntry kernList s0:
isListOfKernels kernList partition {|
                                     currentPartition := currentPartition s0;
                                     memory := add addr' (SHE newEntry)
                                                 (memory s0) beqAddr
                                   |}
-> isListOfKernels kernList partition s0.
Proof.
intro HisKernLists. destruct kernList.
- intuition.
- simpl in *. destruct HisKernLists as [pdentry HisKernLists]. exists pdentry.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HisKernLists; intuition.
  apply isListOfKernelsAuxEqSHE with addr' newEntry; assumption.
Qed.

Lemma isListOfKernelsAuxEqPDT partition addr' newEntry kernList s0:
isListOfKernelsAux kernList partition {|
                                        currentPartition := currentPartition s0;
                                        memory := add addr' (PDT newEntry)
                                                    (memory s0) beqAddr
                                      |}
-> isListOfKernelsAux kernList partition s0.
Proof.
revert partition. induction kernList.
- intuition.
- intros partition HlistIsListOkKerns. simpl in *.
  destruct (beqAddr addr' (CPaddr (partition + nextoffset))) eqn:HbeqAddrNextOffset;
        try(exfalso; intuition; congruence).
  rewrite <-beqAddrFalse in HbeqAddrNextOffset. rewrite removeDupIdentity in HlistIsListOkKerns; intuition.
Qed.

Lemma isListOfKernelsEqPDT partition addr' newEntry kernList pdentry s0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry) ->
structure pdentry = structure newEntry ->
isListOfKernels kernList partition {|
                                     currentPartition := currentPartition s0;
                                     memory := add addr' (PDT newEntry)
                                                 (memory s0) beqAddr
                                   |}
-> isListOfKernels kernList partition s0.
Proof.
intros HlookupAddr HstructureEq HisKernLists. destruct kernList.
- intuition.
- simpl in *. destruct HisKernLists as [newPdentry HisKernLists].
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  + destruct HisKernLists as [Hlookups HisKernLists]. injection Hlookups as HpdentriesEq. subst newPdentry.
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. subst addr'. rewrite <-HstructureEq in *.
    exists pdentry. intuition. apply isListOfKernelsAuxEqPDT with partition newEntry; assumption.
  + exists newPdentry. rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HisKernLists; intuition.
    apply isListOfKernelsAuxEqPDT with addr' newEntry; assumption.
Qed.


Lemma getConfigBlocksAuxEqPDT structure addr' newEntry s0 n entriesleft:
isPDT addr' s0 ->
getConfigBlocksAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} entriesleft =
getConfigBlocksAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getConfigBlocksAux in *.
	intuition.
- intros.
	unfold getConfigBlocksAux.
	fold getConfigBlocksAux.
	destruct (Index.ltb entriesleft zero) eqn:Hentriesleft ; intuition.
	unfold s' at 1. simpl.
	destruct (beqAddr addr' structure)eqn:beqstructaddr.
	-- (* addr' = structure *)
			rewrite <- DTL.beqAddrTrue in beqstructaddr.
			subst structure.
			unfold isPDT in *.
			destruct (lookup addr' (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.
	-- (* addr' <> structure *)
			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup structure (memory s0) beqAddr) eqn:Hoffset' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
			destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Haddr'Eq.
			subst p.
			unfold isPDT in *.
			destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.

			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup p (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Index.pred entriesleft) ; intuition.
			f_equal.
			specialize (IHn p0 i).
			destruct IHn ; intuition.
Qed.

Lemma getConfigBlocksEqPDT partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
isPDT partition s0 ->
(structure newEntry) = (structure pdentry0) ->
getConfigBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getConfigBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HPDTaddrs0 (*HstructKS*) HstructEq.
unfold getConfigBlocks.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *. rewrite Hlookuppds0.
	rewrite HstructEq.
	fold s'.
	assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s' (CIndex maxNbPrepare)) =
  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s0 (CIndex maxNbPrepare))).
	{ apply getConfigBlocksAuxEqPDT ; intuition.
	}
	rewrite HEq.
	intuition.
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure p) s' (CIndex maxNbPrepare)) =
  (getConfigBlocksAux (maxIdx + 1) (structure p) s0 (CIndex maxNbPrepare))).
	{
		apply getConfigBlocksAuxEqPDT ; intuition.
		unfold isPDT. rewrite Hlookuppds0. trivial.
	}
	rewrite HEq.
	intuition.
Qed.


Lemma getConfigBlocksEqPDTNotInPart partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
partition <> addr' ->
getConfigBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getConfigBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 Hpartaddr'NotEq (*HPDTaddrs0 (*HstructKS*) HstructEq*).
unfold getConfigBlocks.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
rewrite <- DTL.beqAddrTrue in beqpartaddr. congruence.
(* addr' <> partition *)
rewrite <- beqAddrFalse in *.
repeat rewrite removeDupIdentity ; intuition.
destruct (lookup partition (memory s0) beqAddr) ; intuition.
destruct v ; intuition.
fold s'.
assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure p) s' (CIndex maxNbPrepare)) =
(getConfigBlocksAux (maxIdx + 1) (structure p) s0 (CIndex maxNbPrepare))).
{
	apply getConfigBlocksAuxEqPDT ; intuition.
	unfold isPDT. rewrite Hlookuppds0. trivial.
}
rewrite HEq.
intuition.
Qed.



(* DUP *)
Lemma getConfigBlocksAuxEqSCE structure addr' newEntry s0 n entriesleft:
isSCE addr' s0 ->
getConfigBlocksAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} entriesleft =
getConfigBlocksAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getConfigBlocksAux in *.
	intuition.
- intros.
	unfold getConfigBlocksAux.
	fold getConfigBlocksAux.
	destruct (Index.ltb entriesleft zero) eqn:Hentriesleft ; intuition.
	unfold s' at 1. simpl.
	destruct (beqAddr addr' structure)eqn:beqstructaddr.
	-- (* addr' = structure *)
			rewrite <- DTL.beqAddrTrue in beqstructaddr.
			subst structure.
			unfold isSCE in *.
			destruct (lookup addr' (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.
	-- (* addr' <> structure *)
			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup structure (memory s0) beqAddr) eqn:Hoffset' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
			destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Haddr'Eq.
			subst p.
			unfold isSCE in *.
			destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.

			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup p (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Index.pred entriesleft) ; intuition.
			f_equal.
			specialize (IHn p0 i).
			destruct IHn ; intuition.
Qed.

(* DUP *)
Lemma getConfigBlocksEqSCE partition addr' newEntry s0 pdentry0:
lookup partition (memory s0) beqAddr = Some (PDT pdentry0) ->
isSCE addr' s0 ->
getConfigBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getConfigBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HPDTaddrs0 (*HstructKS HstructEq*).
unfold getConfigBlocks.
unfold s'. simpl.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isSCE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	rewrite Hlookuppds0.
	fold s'.
	assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s' (CIndex maxNbPrepare)) =
  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s0 (CIndex maxNbPrepare))).
	{
		apply getConfigBlocksAuxEqSCE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.


(* DUP *)
Lemma getConfigBlocksAuxEqSHE structure addr' newEntry s0 n entriesleft:
isSHE addr' s0 ->
getConfigBlocksAux n structure {|
currentPartition := currentPartition s0;
memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} entriesleft =
getConfigBlocksAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getConfigBlocksAux in *.
	intuition.
- intros.
	unfold getConfigBlocksAux.
	fold getConfigBlocksAux.
	destruct (Index.ltb entriesleft zero) eqn:Hentriesleft ; intuition.
	unfold s' at 1. simpl.
	destruct (beqAddr addr' structure)eqn:beqstructaddr.
	-- (* addr' = structure *)
			rewrite <- DTL.beqAddrTrue in beqstructaddr.
			subst structure.
			unfold isSHE in *.
			destruct (lookup addr' (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.
	-- (* addr' <> structure *)
			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup structure (memory s0) beqAddr) eqn:Hoffset' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
			destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Haddr'Eq.
			subst p.
			unfold isSHE in *.
			destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.

			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup p (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Index.pred entriesleft) ; intuition.
			f_equal.
			specialize (IHn p0 i).
			destruct IHn ; intuition.
Qed.

(* DUP *)
Lemma getConfigBlocksEqSHE partition addr' newEntry s0 pdentry0:
lookup partition (memory s0) beqAddr = Some (PDT pdentry0) ->
isSHE addr' s0 ->
getConfigBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getConfigBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HPDTaddrs0.
unfold getConfigBlocks.
unfold s'. simpl.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isSHE in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	rewrite Hlookuppds0.
	fold s'.
	assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s' (CIndex maxNbPrepare)) =
  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s0 (CIndex maxNbPrepare))).
	{
		apply getConfigBlocksAuxEqSHE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.


Lemma getConfigBlocksAuxEqBE structure addr' newEntry s0 n entriesleft:
isBE addr' s0 ->
getConfigBlocksAux n structure {|
currentPartition := currentPartition s0;
memory :=  add addr' (BE newEntry)
            (memory s0) beqAddr |} entriesleft =
getConfigBlocksAux n structure s0 entriesleft.
Proof.
revert n structure entriesleft.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getConfigBlocksAux in *.
	intuition.
- intros.
	unfold getConfigBlocksAux.
	fold getConfigBlocksAux.
	destruct (Index.ltb entriesleft zero) eqn:Hentriesleft ; intuition.
	unfold s' at 1. simpl.

	destruct (beqAddr addr' structure)eqn:beqstructaddr.
	-- (* addr' = structure *)
			rewrite <- DTL.beqAddrTrue in beqstructaddr.
			subst structure.

			unfold isBE in *.
			destruct (lookup addr' (memory s0) beqAddr) eqn:Hlookups0 ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			destruct (Paddr.addPaddrIdx addr' nextoffset) eqn:Hoffset ; intuition.
				destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
			+ (* addr' = p *)
				rewrite <- DTL.beqAddrTrue in Haddr'Eq.
				subst p.
				rewrite Hlookups0. trivial.
			+ (* addr' <> p *)
				rewrite <- beqAddrFalse in *.
			 	repeat rewrite removeDupIdentity ; intuition.

				destruct (lookup p (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
				destruct v ; try(exfalso ; congruence) ; intuition.

				destruct (Index.pred entriesleft) ; intuition.
				f_equal.
				specialize (IHn p0 i).
				destruct IHn ; intuition.
	-- (* addr' <> structure *)
			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup structure (memory s0) beqAddr) eqn:Hoffset' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Paddr.addPaddrIdx structure nextoffset) eqn:Hoffset ; intuition.
			destruct (beqAddr addr' p) eqn:Haddr'Eq ; try(exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Haddr'Eq.
			subst p.
			unfold isBE in *.
			destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			trivial.

			rewrite <- beqAddrFalse in *.
		 	repeat rewrite removeDupIdentity ; intuition.

			destruct (lookup p (memory s0) beqAddr) eqn:Hoffset'' ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct (Index.pred entriesleft) ; intuition.
			f_equal.
			specialize (IHn p0 i).
			destruct IHn ; intuition.
Qed.

(* After state modification, type is still BE, so the kernel entries did not change
		which means the types we found at the same addresses as the previous structure
		are still the same, even if the content might have changed *)
Lemma getConfigBlocksEqBE partition addr' newEntry s0:
isPDT partition s0 ->
isBE addr' s0 ->
getConfigBlocks partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}  =
getConfigBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 Hlookupaddr's0.
unfold getConfigBlocks.
unfold s'. simpl.
destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	rewrite <- beqpartaddr in *.
	unfold isBE in *. unfold isPDT in *.
	destruct (lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry0 Hlookuppds0].
	rewrite Hlookuppds0.
	fold s'.
	assert(HEq :  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s' (CIndex maxNbPrepare)) =
  (getConfigBlocksAux (maxIdx + 1) (structure pdentry0) s0 (CIndex maxNbPrepare))).
	{	eapply getConfigBlocksAuxEqBE ; intuition.
	}
	rewrite HEq.
	intuition.
Qed.

(* DUP *)
Lemma getConfigBlocksAuxEqN addr s n1 n2 n3 list:
list = getConfigBlocksAux n1 addr s n2 ->
n2 < n1 ->
n1 <= n3 ->
n2 < n3 ->
list = getConfigBlocksAux n3 addr s n2.
Proof.
revert list addr n1 n3.
revert n2.
destruct n2.
induction i.
- intuition.
	destruct n3 ; intuition.
	+ simpl. intros.
		apply PeanoNat.Nat.nlt_0_r in H2. exfalso ; congruence.
	+	destruct n1 ; intuition.
		* simpl. intros.
			apply PeanoNat.Nat.nlt_0_r in H0. exfalso ; congruence.
- 	destruct n3 ; intuition.
	+ simpl. intros.
		apply PeanoNat.Nat.nlt_0_r in H2. exfalso ; congruence.
	+	destruct n1 ; intuition.
		* simpl. intros.
			apply PeanoNat.Nat.nlt_0_r in H0. exfalso ; congruence.
		* unfold getConfigBlocksAux in * at 1. fold getConfigBlocksAux in *.
			simpl in *.
			destruct (lookup addr (memory s) beqAddr) eqn:Haddr ; try(exfalso ; congruence) ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			destruct(Paddr.addPaddrIdx addr nextoffset) ; intuition.
			destruct (lookup p (memory s) beqAddr) eqn:Hp ; try(exfalso ; congruence) ; intuition.
			destruct v ; try(exfalso ; congruence) ; intuition.

			assert(HimaxIdx : i <= maxIdx) by lia. destruct (Nat.succ_le_mono 0 i).
			specialize (IHi HimaxIdx (getConfigBlocksAux n1 p0 s
         {|
           i := i - 0;
           Hi :=
             StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
         |}) p0 n1 n3 ).
					subst list. f_equal.
					assert(getConfigBlocksAux n1 p0 s
        {|
          i := i - 0;
          Hi :=
            StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
        |} = getConfigBlocksAux n1 p0 s
  {|
    i := i - 0;
    Hi :=
      StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
  |}) by intuition.
					assert(getConfigBlocksAux n3 p0 s {| i := i; Hi := HimaxIdx |} =
getConfigBlocksAux n3 p0 s
  {|
    i := i - 0;
    Hi :=
      StateLib.Index.pred_obligation_1 {| i := S i; Hi := Hi |} (l (Nat.le_0_l i))
  |}
). f_equal.
destruct i. f_equal. apply proof_irrelevance.
					 f_equal. apply proof_irrelevance.
					rewrite <- H3.


					eapply IHi ; try(assumption); try(lia). f_equal.
					destruct i. f_equal. apply proof_irrelevance.
					f_equal. apply proof_irrelevance.

Qed.

Lemma filterPresentEqPDT addr' newEntry s0 blocklist:
isPDT addr' s0 ->
filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
filterPresent blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (present b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma filterPresentEqSCE addr' newEntry s0 blocklist:
isSCE addr' s0 ->
filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
filterPresent blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (present b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma filterPresentEqSHE addr' newEntry s0 blocklist:
isSHE addr' s0 ->
filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
filterPresent blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isSHE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (present b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.


Lemma filterAccessibleEqPDT addr' newEntry s0 blocklist:
isPDT addr' s0 ->
filterAccessible blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
filterAccessible blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (accessible b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma filterAccessibleEqBEAccessibleNoChange addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(accessible newEntry) = (accessible bentry0) ->
filterAccessible blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
filterAccessible blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HaccessibleEq.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		inversion Hlookupaddr's0 as [HBEEq].
		subst b.
		rewrite HaccessibleEq.
		destruct (accessible bentry0) eqn:beqpresent ; intuition.
		f_equal. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (accessible b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.


(* DUP *)
Lemma filterAccessibleEqSCE addr' newEntry s0 blocklist:
isSCE addr' s0 ->
filterAccessible blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
filterAccessible blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (accessible b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.


(* DUP *)
Lemma filterAccessibleEqSHE addr' newEntry s0 blocklist:
isSHE addr' s0 ->
filterAccessible blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
filterAccessible blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isSHE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (accessible b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.


(* After state modification, if the present flags all entries are the same,
	then the list didn't change *)
Lemma filterPresentEqBENoChange addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
filterPresent blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentEq.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		inversion Hlookupaddr's0 as [HBEEq].
		subst b.
		rewrite HpresentEq.
		destruct (present bentry0) eqn:beqpresent ; intuition.
		f_equal. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (present b) eqn:Hff ; intuition.
			f_equal. intuition.
Qed.

(* After state modification, if the modified entry is not in the list, no change *)
Lemma filterPresentEqBENotInListNoChange (*block*) addr' newEntry s0 (*bentry0*) blocklist:
(*lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->*)
(*(present newEntry) = (present bentry0) ->*)
~In addr' blocklist ->
(*In block ( *)
filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
(*In block ( *) filterPresent blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros (*Hlookupaddr's0 HpresentEq*) Haddr'NotInList.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. simpl in *. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; try(apply not_eq_sym; assumption).
			destruct (lookup a (memory s0) beqAddr) ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right;
        assumption).
			destruct v ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right; assumption).
			destruct (present b) eqn:Hff ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right; assumption).
			simpl in *. intuition.
			f_equal. intuition.
Qed.

(* After state modification, if the present flag of the modified entry change to true
		then it is added to the initial list with the rest taht didn't change *)
Lemma filterPresentEqBEChangePresentTrue block addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(*blocklist <> [] ->*)
NoDup blocklist ->
In addr' blocklist ->
(*NoDup (filterPresent blocklist s0) ->*)
In block
(filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) ->
In block (
addr'::filterPresent blocklist s0) /\ NoDup (addr'::filterPresent blocklist s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentNotEq Hpresent'true HNoDup HlistNotNull.
induction blocklist.
- exfalso. simpl in *. congruence.
- simpl.
	simpl in *.
	destruct HlistNotNull as [Haddr'aEq | Haddr'InList].
	--
	(*destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.*)
		subst a. rewrite beqAddrTrue.
		rewrite Hpresent'true.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		inversion Hlookupaddr's0 as [HBEEq].
		subst b.
		destruct (present bentry0) eqn:beqpresent ; intuition.
		f_equal.
		apply NoDup_cons_iff in HNoDup.
		simpl in *. intuition. right.
		assert(HfilterPresentEq : (filterPresent blocklist s') = (filterPresent blocklist s0)).
		{ apply filterPresentEqBENotInListNoChange ; intuition. }
		rewrite HfilterPresentEq in *; intuition.
		apply NoDup_cons_iff in HNoDup.
		destruct HNoDup as [HBlockNotInList HNoDupList].
		(*assert(HNoBlockNotInFilter : forall a l s , ~In a l -> ~In a (filterPresent l s)) by admit.
		specialize (HNoBlockNotInFilter addr' blocklist s0 HBlockNotInList).*)
		apply NotInListNotInFilterPresent with addr' blocklist s0 in HBlockNotInList.
 		apply NoDup_cons_iff. intuition.
		apply NoDupListNoDupFilterPresent with blocklist s0 in HNoDupList.
		(*assert(HNoDupListNoDupFilter : forall l s, NoDup l -> NoDup (filterPresent l s))
			by admit.
		specialize (HNoDupListNoDupFilter blocklist s0 HNoDupList).*)
		intuition.
	-- destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					subst a.
					apply NoDup_cons_iff in HNoDup. intuition.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff ; intuition.
					simpl in *. intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; intuition.
					destruct v ; intuition.
					destruct (present b) ; intuition.
					simpl in *. intuition.
					subst a.
					(*
					assert(HNoBlockNotInFilter : forall a l s , ~In a l -> ~In a (filterPresent l s)) by admit.
					specialize (HNoBlockNotInFilter block blocklist s0 H0).*)
					apply NotInListNotInFilterPresent with block blocklist s0 in H0.
			 		apply NoDup_cons_iff. rewrite NoDup_cons_iff.
					assert(HNoDupListNoDupFilter : NoDup (filterPresent blocklist s0)).
					{	apply NoDupListNoDupFilterPresent with blocklist s0 in H1. intuition. }
					(*assert(HNoDupListNoDupFilter : forall l s, NoDup l -> NoDup (filterPresent l s))
						by admit.
					specialize (HNoDupListNoDupFilter blocklist s0 H1).*)
					intuition.
					simpl in *. intuition.
					contradict H2.
					induction blocklist.
					* intuition.
					* simpl in *.
						destruct (beqAddr addr' a) eqn:Hf' ; try(exfalso ; congruence).
						** rewrite <- DTL.beqAddrTrue in Hf'.
								subst a.
								apply NoDup_cons_iff in H1.
								rewrite Hlookupaddr's0 in *.
								rewrite Hpresent'true in *.
								assert(Hpresentfalses0 : present bentry0 = false).
								{
									apply Bool.not_true_is_false. intuition.
								}
								rewrite Hpresentfalses0 in *.
								simpl in *. intuition ; try (exfalso ; congruence).
								assert(Haddr'NotInList : ~In addr' blocklist) by intuition.
								(*assert(HNoBlockNotInFilter' : forall a l s , ~In a l -> ~In a (filterPresent l s)) by admit.
								specialize (HNoBlockNotInFilter' addr' blocklist s0 Haddr'NotInList).*)
								apply NotInListNotInFilterPresent with addr' blocklist s0 in Haddr'NotInList.
								congruence.
						** 	rewrite <- beqAddrFalse in *.
								rewrite removeDupIdentity in *; intuition.
								simpl in *. intuition.
								apply NoDup_cons_iff in H1.
								destruct (lookup a (memory s0) beqAddr) ; intuition.
								destruct v ; intuition.
								destruct (present b0) eqn:Hff ; try(apply H4; assumption).
								simpl in *. intuition.
								apply NoDup_cons_iff in HNoDupListNoDupFilter. intuition.
					* subst.
						apply NoDup_cons_iff in H4.
						apply NoDup_cons_iff.
						rewrite NoDup_cons_iff. simpl.
						intuition.
						apply NotInListNotInFilterPresent with a blocklist s0 in H0.
						congruence.
					*
						apply NoDup_cons_iff in H4.
						apply NoDup_cons_iff.
						rewrite NoDup_cons_iff. simpl.
						intuition.
						apply NotInListNotInFilterPresent with a blocklist s0 in H0.
						congruence.
Qed.

(* After state modification, if the present flag of the modified entry change to true
		then it is added to the initial list with the rest taht didn't change *)
Lemma filterPresentEqBEChangePresentTrueEquivalenceOne block addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(*blocklist <> [] ->*)
NoDup blocklist ->
(*In addr' blocklist ->*)
(*NoDup (filterPresent blocklist s0) ->*)
In block
(filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) ->
In block (
addr'::filterPresent blocklist s0) /\ NoDup (addr'::filterPresent blocklist s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentNotEq Hpresent'true HNoDup.
split.
induction blocklist.
- exfalso. simpl in *. congruence.
- simpl.
	simpl in *.
  destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					subst a.
					apply NoDup_cons_iff in HNoDup. intuition.
					rewrite Hlookupaddr's0.
					rewrite Hpresent'true in *. simpl in *. intuition.
					assert(Hpresents0false : present bentry0 = false).
					{ destruct (present bentry0) eqn:Hff ; intuition. }
					rewrite Hpresents0false. intuition.
			--- rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in H ; intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff ; intuition.
					simpl in *. intuition.
- simpl. apply NoDup_cons_iff.
	induction blocklist.
	-- intuition.
	-- simpl in *.
		destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					subst a.
					apply NoDup_cons_iff in HNoDup.
					rewrite Hlookupaddr's0.
					rewrite Hpresent'true in *. simpl in *.
					assert(Hpresents0false : present bentry0 = false).
					{ destruct (present bentry0) eqn:Hff ; intuition. }
					rewrite Hpresents0false. intuition.
					apply NotInListNotInFilterPresent with addr' blocklist s0 in H0.
					congruence.
					apply NoDupListNoDupFilterPresent with blocklist s0 in H1.
					intuition.
			--- rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in H ; intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff ; intuition.
					simpl in *. intuition.
					subst a.
					assert(Hpresents0false : present bentry0 = false).
					{ destruct (present bentry0) eqn:Hff' ; intuition. }
					assert(Hpresents0true : present bentry0 = true).
					{
					induction blocklist.
					---- intuition.
					---- simpl in *. intuition.
								destruct (beqAddr addr' a) eqn:Hf' ; try(exfalso ; congruence).
								----- rewrite <- DTL.beqAddrTrue in Hf'.
										subst a.
										rewrite Hlookupaddr's0 in *.
										rewrite Hpresent'true in *.
										rewrite Hpresents0false in *.
										apply NoDup_cons_iff in H2.
										apply NotInListNotInFilterPresent with addr' blocklist s0 in H.
										intuition. intuition.
								-----
											apply NoDup_cons_iff in H2 ; intuition.
											apply H2 ; intuition.
											apply NotInListNotInFilterPresent with block blocklist s' in H4.
											congruence.
			 								apply NoDupListNoDupFilterPresent with blocklist s0 in H6.
											intuition.
											destruct (lookup a (memory s0) beqAddr) ; intuition.
											destruct v ; intuition.
											destruct (present b0) eqn:Hff' ; intuition.
											simpl in *. intuition.
											rewrite <- beqAddrFalse in *. congruence.
					}
					congruence.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff' ; intuition.
					simpl in *. intuition.
					subst a.
					apply NoDup_cons_iff. intuition.
					apply NotInListNotInFilterPresent with block blocklist s0 in H ; intuition.
					apply NoDupListNoDupFilterPresent ; intuition.
					apply NoDup_cons_iff. intuition.
					apply NotInListNotInFilterPresent with a blocklist s0 in H ; intuition.
Qed.

(* After state modification, if the present flag of the modified entry change to true
		then it is added to the initial list with the rest taht didn't change *)
Lemma filterPresentEqBEChangePresentTrueEquivalence block addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(*blocklist <> [] ->*)
NoDup blocklist ->
In addr' blocklist ->
(*NoDup (filterPresent blocklist s0) ->*)
In block
(filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) <->
In block (
addr'::filterPresent blocklist s0) /\ NoDup (addr'::filterPresent blocklist s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentNotEq Hpresent'true HNoDup HlistNotNull.
split.
induction blocklist.
- exfalso. simpl in *. congruence.
- simpl.
	simpl in *.
	destruct HlistNotNull as [Haddr'aEq | Haddr'InList].
	--
		subst a. rewrite beqAddrTrue.
		rewrite Hpresent'true in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		inversion Hlookupaddr's0 as [HBEEq].
		subst b.
		destruct (present bentry0) eqn:beqpresent ; intuition.
		f_equal.
		apply NoDup_cons_iff in HNoDup.
		simpl in *. intuition. right.
		assert(HfilterPresentEq : (filterPresent blocklist s') = (filterPresent blocklist s0)).
		{ apply filterPresentEqBENotInListNoChange ; intuition. }
		rewrite HfilterPresentEq in *; intuition.
		apply NoDup_cons_iff in HNoDup.
		destruct HNoDup as [HBlockNotInList HNoDupList].
		apply NotInListNotInFilterPresent with addr' blocklist s0 in HBlockNotInList.
 		apply NoDup_cons_iff. intuition.
		apply NoDupListNoDupFilterPresent with blocklist s0 in HNoDupList.
		intuition.
		-- destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					subst a.
					apply NoDup_cons_iff in HNoDup. intuition.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff ; intuition.
					simpl in *. intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; intuition.
					destruct v ; intuition.
					destruct (present b) ; intuition.
					simpl in *. intuition.
					subst a.
					apply NotInListNotInFilterPresent with block blocklist s0 in H0.
			 		apply NoDup_cons_iff. rewrite NoDup_cons_iff.
					assert(HNoDupListNoDupFilter : NoDup (filterPresent blocklist s0)).
					{	apply NoDupListNoDupFilterPresent with blocklist s0 in H1. intuition. }
					intuition.
					simpl in *. intuition.
					contradict H2.
					induction blocklist.
					* intuition.
					* simpl in *.
						destruct (beqAddr addr' a) eqn:Hf' ; try(exfalso ; congruence).
						** rewrite <- DTL.beqAddrTrue in Hf'.
								subst a.
								apply NoDup_cons_iff in H1.
								rewrite Hlookupaddr's0 in *.
								rewrite Hpresent'true in *.
								assert(Hpresentfalses0 : present bentry0 = false).
								{
									apply Bool.not_true_is_false. intuition.
								}
								rewrite Hpresentfalses0 in *.
								simpl in *. intuition ; try (exfalso ; congruence).
								assert(Haddr'NotInList : ~In addr' blocklist) by intuition.
								apply NotInListNotInFilterPresent with addr' blocklist s0 in Haddr'NotInList.
								congruence.
						** 	rewrite <- beqAddrFalse in *.
								rewrite removeDupIdentity in *; intuition.
								simpl in *. intuition.
								apply NoDup_cons_iff in H1.
								destruct (lookup a (memory s0) beqAddr) ; intuition.
								destruct v ; intuition.
								destruct (present b0) eqn:Hff ; try(apply H4; assumption).
								simpl in *. intuition.
								apply NoDup_cons_iff in HNoDupListNoDupFilter. intuition.
					* subst.
						apply NoDup_cons_iff in H4.
						apply NoDup_cons_iff.
						rewrite NoDup_cons_iff. simpl.
						intuition.
						apply NotInListNotInFilterPresent with a blocklist s0 in H0.
						congruence.
					*
						apply NoDup_cons_iff in H4.
						apply NoDup_cons_iff.
						rewrite NoDup_cons_iff. simpl.
						intuition.
						apply NotInListNotInFilterPresent with a blocklist s0 in H0.
						congruence.
- intro Hhyp. rewrite NoDup_cons_iff in Hhyp. simpl in *.
	induction blocklist.
	-- intuition.
	-- apply NoDup_cons_iff in HNoDup.
			destruct HNoDup as [HaNotInList IHNoDupList].
			assert(HaNotInFilterPresent : ~ In a (filterPresent blocklist s0)).
			{ apply NotInListNotInFilterPresent with a blocklist s0 in HaNotInList ; intuition. }
			assert(HaNotInFilterPresents' : ~ In a (filterPresent blocklist s')).
			{ apply NotInListNotInFilterPresent with a blocklist s' in HaNotInList ; intuition. }
 simpl in *.
		destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					rewrite Hf in *.
					rewrite Hpresent'true in *.
					rewrite Hlookupaddr's0 in *.
													assert(Hpresentfalses0 : present bentry0 = false).
								{
									apply Bool.not_true_is_false. intuition.
								}
								rewrite Hpresentfalses0 in *.
					intuition. simpl. left. intuition.
					simpl. right.
					induction (blocklist). (* 2nd induction for block *)
					---- intuition.
					---- simpl in *.
								rewrite Hf in *.
								destruct (beqAddr a a0) eqn:Hff ; try(exfalso ; congruence).
								----- rewrite <- DTL.beqAddrTrue in Hff.
										rewrite Hff in *.
										rewrite Hpresent'true in *.
										rewrite Hlookupaddr's0 in *.
													rewrite Hpresentfalses0 in *.
										subst a0. subst a.
										intuition.
								----- rewrite <- beqAddrFalse in *.
										rewrite removeDupIdentity in * ; intuition.
										apply NoDup_cons_iff in IHNoDupList.
										destruct (lookup a0 (memory s0) beqAddr) ; intuition.
										destruct v ; intuition.
										destruct (present b) eqn:Hfff ; try(apply H10; assumption).
										apply NoDup_cons_iff in H2.
										simpl in *. intuition.
			--- rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in *; try (apply not_eq_sym ; trivial).
          destruct HlistNotNull as [Hcontra | HlistNotNull]; try(exfalso; congruence).
					destruct (lookup a (memory s0) beqAddr) ; try(apply IHblocklist; assumption).
					destruct v ; try(apply IHblocklist; assumption).
					destruct (present b) eqn:Hff ; try(apply IHblocklist; assumption).
          destruct Hhyp as (HhypBlockFilts0 & HhypAddrFilts0 & HnoDupFilt).
					apply NoDup_cons_iff in HnoDupFilt.
					simpl in *. intuition.
Qed.

Lemma filterPresentEqBEChangePresentTrueLengthEquality addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
NoDup blocklist ->
In addr' blocklist ->
length (filterPresent blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) =
length (addr'::filterPresent blocklist s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentNotEq Hpresent'true HNoDup HlistNotNull.

induction blocklist.
- exfalso. simpl in *. congruence.
- simpl in *.
	destruct HlistNotNull as [Haddr'aEq | Haddr'InList].
	-- apply NoDup_cons_iff in HNoDup.
		subst a. rewrite beqAddrTrue.
		rewrite Hpresent'true in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		inversion Hlookupaddr's0 as [HBEEq].
		subst b.
		destruct (present bentry0) eqn:beqpresent ; intuition.
		simpl.
		f_equal.
		assert(HfilterPresent : filterPresent blocklist s' = filterPresent blocklist s0).
		{ eapply filterPresentEqBENotInListNoChange ; intuition. }
		rewrite HfilterPresent.
		trivial.
	-- destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
			--- rewrite <- DTL.beqAddrTrue in Hf.
					subst a.
					apply NoDup_cons_iff in HNoDup. intuition.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					apply NoDup_cons_iff in HNoDup.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) eqn:Hff ; intuition.
					simpl in *. intuition.
Qed.

(* After state modification, if the modified entry is not in the list, no change *)
Lemma filterAccessibleEqBENotInListNoChange addr' newEntry s0 blocklist:
~In addr' blocklist ->
filterAccessible blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
filterAccessible blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Haddr'NotInList.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. simpl in *. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; try(apply not_eq_sym; assumption).
			destruct (lookup a (memory s0) beqAddr) ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right;
        assumption).
			destruct v ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right; assumption).
			destruct (accessible b) eqn:Hff ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right;
        assumption).
			simpl in *. intuition.
			f_equal. intuition.
Qed.


Lemma getMappedBlocksEqPDT partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
StructurePointerIsKS s0 ->
(structure newEntry) = (structure pdentry0) ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructPtIsKS HstructEq.
assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; trivial).
unfold getMappedBlocks.
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqPDT with pdentry0; intuition.
	}
rewrite HEq.

eapply filterPresentEqPDT ; intuition.
Qed.

Lemma getMappedBlocksEqPDTNotInPart partition addr' newEntry s0:
isPDT addr' s0 ->
partition <> addr' ->
StructurePointerIsKS s0 ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpartNotEq HstructEq.
unfold getMappedBlocks.
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqPDTNotInPart ; intuition.
	}
rewrite HEq.

eapply filterPresentEqPDT ; intuition.
Qed.

(* After state modification, the mapped blocks list is changed only if the present
	flag of an existing entry is set, otherwise it is the same list *)
Lemma getMappedBlocksEqBENoChange partition addr' newEntry s0 bentry0:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentEq.
assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).
unfold getMappedBlocks.
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqBE ; intuition.
	}
rewrite HEq.

eapply filterPresentEqBENoChange with bentry0; intuition.
Qed.

Lemma getMappedBlocksInclBEPresentTrue block partition addr newEntry s0 bentry0:
isPDT partition s0 ->
lookup addr (memory s0) beqAddr = Some (BE bentry0) ->
present newEntry <> present bentry0 ->
(present newEntry) = true ->
noDupKSEntriesList s0 ->
In addr (filterOptionPaddr (getKSEntries partition s0)) ->
In block (addr::getMappedBlocks partition s0) ->
In block (getMappedBlocks partition {|
				                              currentPartition := currentPartition s0;
				                              memory := add addr (BE newEntry)
                                      (memory s0) beqAddr |}).
Proof.
set (s :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 Hlookupaddrs0 HpresentChange HpresentTrue HNoDupMapped HaddrInKSEntriess0 HBlockInMappeds.
assert(HBEs0: isBE addr s0) by (unfold isBE; rewrite Hlookupaddrs0 ; trivial).
unfold getMappedBlocks.
assert(HgetKSEq:  getKSEntries partition s = getKSEntries partition s0).
{ apply getKSEntriesEqBE ; intuition. }
rewrite HgetKSEq. apply filterPresentEqBEChangePresentTrueEquivalence with bentry0; try(assumption).
- apply HNoDupMapped. assumption.
- split. assumption.
  apply NoDup_cons. apply NotPresentNotInFilterPresent with bentry0; try(assumption).
  + rewrite HpresentTrue in HpresentChange. apply not_eq_sym in HpresentChange.
    apply Bool.not_true_is_false; assumption.
  + apply HNoDupMapped. assumption.
  + apply NoDupListNoDupFilterPresent; intuition.
Qed.

Lemma getMappedBlocksEqBEPresentChange block partition addr' newEntry s0 bentry0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
noDupKSEntriesList s0 ->
In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
In block (
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) ->
In block (
addr'::getMappedBlocks partition s0) /\ NoDup(addr'::getMappedBlocks partition s0)
/\ NoDup (getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 Hlookupaddr's0 HpresentNotEq HpresentTrue HNoDupMapped.
intros Haddr'InKSEntriess0 HBlockInMappeds'.
assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).
unfold getMappedBlocks.
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqBE ; intuition.
	}
unfold getMappedBlocks in HBlockInMappeds'.
rewrite HEq in *.
unfold noDupKSEntriesList in *. specialize (HNoDupMapped partition HPDTparts0).
apply and_assoc.
assert(Hassoc : (In block (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0) /\
 NoDup (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0))).
{ apply filterPresentEqBEChangePresentTrue with newEntry bentry0 ; intuition. }
intuition.

(* NoDup *)
induction ((filterOptionPaddr (getKSEntries partition s0))).
- intuition.
- simpl in *.
destruct (beqAddr addr' a) eqn:beqaddr'a ; try (exfalso ; congruence).
			-- (* addr' = a *)
					rewrite <- DTL.beqAddrTrue in beqaddr'a.
					rewrite <- beqaddr'a in *.
					simpl in *.
					rewrite HpresentTrue in *. rewrite Hlookupaddr's0 in *.
					assert(Hpresents0false : present bentry0 = false).
					{ apply Bool.not_true_iff_false.
						intuition.
					}
					rewrite Hpresents0false in *.
					simpl in *. subst a.
					apply NoDup_cons_iff.
					apply NoDup_cons_iff in HNoDupMapped.
					apply NoDup_cons_iff in H0.
					destruct HNoDupMapped as [HblockNotInl HNoDupL].
					apply NotInListNotInFilterPresent with addr' l s' in HblockNotInl.
					apply NoDupListNoDupFilterPresent with l s' in HNoDupL.
					intuition ; try (exfalso ; congruence).
			-- (* addr' <> a *)
					rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in * ; try(apply not_eq_sym; assumption). destruct H.
					apply NoDup_cons_iff in HNoDupMapped. destruct HNoDupMapped as [HBlockNotInCons HNoDupCons].
          destruct Haddr'InKSEntriess0 as [Hcontra | Haddr'InKSEntriess0]; try(exfalso; congruence).
					destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try(apply IHl; try(assumption); left;
              assumption).
					destruct v ; try(apply IHl; try(assumption); left; assumption).
					destruct (present b) ; try(apply IHl; try(assumption); left; assumption).
					simpl in *.
					apply NoDup_cons_iff in H0.
					apply NotInListNotInFilterPresent with a l s' in HBlockNotInCons.
					intuition. subst a. congruence.
					apply NoDup_cons_iff.
					apply NoDupListNoDupFilterPresent with l s' in HNoDupCons.
					intuition.

					assert(HNoDupBlockFilters0 : NoDup (addr' :: filterPresent l s0)).
					{
						destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try(assumption).
						destruct v ; try(assumption).
						destruct (present b) ; try(assumption).
						apply NoDup_cons_iff.
						apply NoDup_cons_iff in H0.
						destruct H0 as [Haddr'NotInCons HNoDupCons].
						apply NoDup_cons_iff in HNoDupCons. destruct HNoDupCons.
						split; try(assumption). contradict Haddr'NotInCons. simpl. right. assumption.
					}

					apply NoDup_cons_iff in H0.
					apply NoDup_cons_iff in HNoDupMapped.
					destruct HNoDupMapped as [HBlockNotInCons HNoDupCons].
					subst.

          destruct Haddr'InKSEntriess0 as [Hcontra | Haddr'InKSEntriess0]; try(exfalso; congruence).
					destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try(apply IHl; try(assumption); right;
            assumption).
					destruct v ; try(apply IHl; try(assumption); right; assumption).
					destruct (present b) ; try(apply IHl; try(assumption); right; assumption).
					apply NotInListNotInFilterPresent with a l s' in HBlockNotInCons.
					intuition.
					apply NoDup_cons_iff. intuition.
					apply NoDupListNoDupFilterPresent with l s' in HNoDupCons.
					intuition.
Qed.

Lemma getMappedBlocksEqBEPresentChangeEquivalence block partition addr' newEntry s0 bentry0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
noDupKSEntriesList s0 ->
In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
In block (
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) <->
In block (
addr'::getMappedBlocks partition s0) /\ NoDup(addr'::getMappedBlocks partition s0)
/\ NoDup (getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 Hlookupaddr's0 HpresentNotEq HpresentTrue HNoDupMapped.
intros Haddr'InKSEntriess0.
assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).
unfold getMappedBlocks.
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqBE ; intuition.
	}
unfold getMappedBlocks.
rewrite HEq in *.
unfold noDupKSEntriesList in *. specialize (HNoDupMapped partition HPDTparts0).
assert(HnewAssocGoal : In block (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s') <->
(In block (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0) /\
NoDup (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0)) /\
NoDup (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s') ->
In block (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s') <->
In block (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0) /\
NoDup (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0) /\
NoDup (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s')).
{ intros HnewHyp.
	split. intro HBlockInMappeds'.
	apply and_assoc. intuition.
	intro HBlockInMappeds'. apply and_assoc in HBlockInMappeds'.
	intuition.
}
apply HnewAssocGoal. clear HnewAssocGoal.

assert(Hassoc : In block (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s') <->(In block (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0) /\
 NoDup (addr' :: filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0))).
{
	eapply filterPresentEqBEChangePresentTrueEquivalence with bentry0  ; intuition.
 }
intuition.

(* NoDup *)
induction ((filterOptionPaddr (getKSEntries partition s0))).
- intuition.
- simpl in *.
destruct (beqAddr addr' a) eqn:beqaddr'a ; try (exfalso ; congruence).
			-- (* addr' = a *)
					rewrite <- DTL.beqAddrTrue in beqaddr'a.
					rewrite <- beqaddr'a in *.
					simpl in *.
					rewrite HpresentTrue in *. rewrite Hlookupaddr's0 in *.
					assert(Hpresents0false : present bentry0 = false).
					{ apply Bool.not_true_iff_false.
						intuition.
					}
					rewrite Hpresents0false in *.
					simpl in *. subst a.
					apply NoDup_cons_iff.
					apply NoDup_cons_iff in HNoDupMapped.
					apply NoDup_cons_iff in H3.
					destruct HNoDupMapped as [HblockNotInl HNoDupL].
					apply NotInListNotInFilterPresent with addr' l s' in HblockNotInl.
					apply NoDupListNoDupFilterPresent with l s' in HNoDupL.
					intuition ; try (exfalso ; congruence).
			-- (* addr' <> a *)
					rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in * ; try (apply not_eq_sym ; trivial).
					apply NoDup_cons_iff in HNoDupMapped. destruct HNoDupMapped as [HaNotInList HNoDupList].
          destruct Haddr'InKSEntriess0 as [Hcontra | Haddr'InKSEntriess0]; try(exfalso; congruence).
					destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try (apply IHl ; assumption).
					destruct v ; try (apply IHl ; assumption).
					destruct (present b) ; try (apply IHl ; assumption).
					simpl in *.
					apply NoDup_cons_iff in H3.
					destruct H3 as [Haddr'NotIn HNoDupa].
					apply NoDup_cons_iff in HNoDupa.
					apply NoDup_cons_iff.
					simpl in *. split.
					apply NotInListNotInFilterPresent ; intuition.
					apply NoDupListNoDupFilterPresent ; intuition.
Qed.

Lemma getMappedBlocksEqBENotInPart partition addr' newEntry s0:
isBE addr' s0 ->
(* not in mapped blocks not sufficient because it could have been filtered out by the present flag*)
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HBEs0 HNotInList.
unfold getMappedBlocks in *.
assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
{ apply getKSEntriesEqBE ; intuition.
}
rewrite HEq.

eapply filterPresentEqBENotInListNoChange ; intuition.
Qed.

(* DUP *)
Lemma getMappedBlocksEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 HSCEs0.

unfold getMappedBlocks.
apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry Hlookuppds0].
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqSCE with pdentry; intuition.
	}
rewrite HEq.
apply filterPresentEqSCE ; intuition.
Qed.

(* DUP *)
Lemma getMappedBlocksEqSHE partition addr' newEntry s0:
isPDT partition s0 ->
isSHE addr' s0 ->
getMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 HSHEs0.

unfold getMappedBlocks.
apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry Hlookuppds0].
	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqSHE with pdentry; intuition.
	}
rewrite HEq.
apply filterPresentEqSHE ; intuition.
Qed.


Lemma BlockPresentFalseNotMapped partition block bentry0 s0:
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present bentry0) = false ->
~In block (getMappedBlocks partition s0).
Proof.
intros Hlookupblocks0 HpresentFalse.
unfold getMappedBlocks.
induction (filterOptionPaddr (getKSEntries partition s0)).
- intuition.
- simpl in *.
	destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a. rewrite Hlookupblocks0 in *.
		rewrite HpresentFalse. intuition.
	-- (* addr' <> a*)
		rewrite <- beqAddrFalse in *.
		simpl in *.
		destruct (lookup a (memory s0) beqAddr) ; intuition.
		destruct v ; intuition.
		destruct (present b) ; intuition.
		simpl in *. intuition.
Qed.

Lemma BlockAccessibleFalseNotMapped partition block bentry0 s0:
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(accessible bentry0) = false ->
~In block (getAccessibleMappedBlocks partition s0).
Proof.
intros Hlookupblocks0 HpresentFalse.
unfold getMappedBlocks.
unfold getAccessibleMappedBlocks.
destruct (lookup partition (memory s0) beqAddr) ; try(intuition ; exfalso ; congruence).
destruct v ; try(intuition ; exfalso ; congruence).
induction (getMappedBlocks partition s0).
- intuition.
- simpl in *.
	destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a. rewrite Hlookupblocks0 in *.
		rewrite HpresentFalse. intuition.
	-- (* addr' <> a*)
		rewrite <- beqAddrFalse in *.
		simpl in *.
		destruct (lookup a (memory s0) beqAddr) ; intuition.
		destruct v ; intuition.
		destruct (accessible b) ; intuition.
		simpl in *. intuition.
Qed.


Lemma BlockNotMappedNotAccessible partition block s0:
~In block (getMappedBlocks partition s0) ->
~In block (getAccessibleMappedBlocks partition s0).
Proof.
intros HblockNotMapped.

unfold getAccessibleMappedBlocks.
destruct (lookup partition (memory s0) beqAddr) ; try(intuition ; exfalso ; congruence).
destruct v ; try(intuition ; exfalso ; congruence).
induction (getMappedBlocks partition s0).
- intuition.
- simpl in *.
	destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a. destruct (lookup block (memory s0) beqAddr) ; intuition.
	-- (* addr' <> a*)
		rewrite <- beqAddrFalse in *.
		simpl in *.
		destruct (lookup a (memory s0) beqAddr) ; intuition.
		destruct v ; intuition.
		destruct (accessible b) ; intuition.
		simpl in *. intuition.
Qed.

Lemma getAccessibleMappedBlocksEqPDT partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
StructurePointerIsKS s0 ->
(structure newEntry) = (structure pdentry0) ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructPtIsKS HstructEq.
assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; trivial).

unfold getAccessibleMappedBlocks.

assert(HmappedEq : getMappedBlocks partition s' = getMappedBlocks partition s0).
{
	eapply getMappedBlocksEqPDT with pdentry0 ; intuition.
}
rewrite HmappedEq.

unfold s'.
simpl.
destruct (beqAddr addr' partition) eqn:Hf.
	- (* = *)
		rewrite <- DTL.beqAddrTrue in Hf.
		rewrite Hf in *. rewrite Hlookuppds0.
		eapply filterAccessibleEqPDT ; intuition.
	- (* <> *)
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
		destruct (lookup partition (memory s0) beqAddr) ; intuition ; try(exfalso ; congruence).
		destruct v ; intuition ; try(exfalso ; congruence).
		eapply filterAccessibleEqPDT ; intuition.
Qed.


Lemma getAccessibleMappedBlocksEqPDTNotInPart partition addr' newEntry s0:
isPDT addr' s0 ->
partition <> addr' ->
StructurePointerIsKS s0 ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpartNotEq HstructEq.
unfold getAccessibleMappedBlocks.

assert(HlookuppdEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. cbn.
	destruct (beqAddr addr' partition) eqn:Hf.
	- (* = *)
		rewrite <- DTL.beqAddrTrue in Hf.
		rewrite Hf in *.
		congruence.
	- (* <> *)
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
}
rewrite HlookuppdEq.

destruct (lookup partition (memory s0) beqAddr) ; intuition ; try(exfalso ; congruence).
destruct v ; intuition ; try(exfalso ; congruence).

assert(HEq2 :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ apply getMappedBlocksEqPDTNotInPart ; intuition.
}
rewrite HEq2.

eapply filterAccessibleEqPDT ; intuition.
Qed.

Lemma getAccessibleMappedBlocksEqBENotInPart partition addr' newEntry s0:
isPDT partition s0 ->
isBE addr' s0 ->
(* not in mapped blocks not sufficient because it could have been filtered out by the present flag*)
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 HBEs0 HNotInList.
unfold getAccessibleMappedBlocks in *.
apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry Hlookuppds0].

assert(HlookuppdEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. cbn.
	destruct (beqAddr addr' partition) eqn:Hf.
	- (* = *)
		rewrite <- DTL.beqAddrTrue in Hf.
		rewrite Hf in *.
		unfold isBE in *.
		unfold isPDT in *.
		destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	- (* <> *)
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
}
rewrite HlookuppdEq. rewrite Hlookuppds0.

assert(HEq2 :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ apply getMappedBlocksEqBENotInPart ; intuition.
}
rewrite HEq2.

assert(Haddr'NotMapped : ~In addr' (getMappedBlocks partition s0)).
{
	unfold getMappedBlocks.
	induction (filterOptionPaddr (getKSEntries partition s0)).
	- intuition.
	- simpl.
		destruct (beqAddr addr' a) eqn:beqaddr'a ; try(exfalso ; congruence).
		-- (* addr' = a *)
			rewrite <- DTL.beqAddrTrue in beqaddr'a.
			subst a. exfalso. contradict HNotInList. simpl. left. reflexivity.
		-- (* addr' <> a*)
			rewrite <- beqAddrFalse in *.
			destruct (lookup a (memory s0) beqAddr) ; try(apply IHl; contradict HNotInList; simpl; right; assumption).
			destruct v ; try(apply IHl; contradict HNotInList; simpl; right; assumption).
			destruct (present b) ; try(apply IHl; contradict HNotInList; simpl; right; assumption).
			simpl in *. intuition.
}

eapply filterAccessibleEqBENotInListNoChange ; intuition.
Qed.

(* DUP of getMappedBlocksEqBENoChange
	After state modification, the mapped blocks list is changed only if the accessible
	flag of an existing entry is set, otherwise it is the same list *)
Lemma getAccessibleMappedBlocksEqBEAccessiblePresentNoChange partition addr' newEntry s0 bentry0:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
present newEntry = present bentry0 ->
(accessible newEntry) = (accessible bentry0) ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpresentEq HaccessibleEq.
assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).
unfold getAccessibleMappedBlocks.

unfold s'. cbn.
destruct (beqAddr addr' partition) eqn:beqaddr'part.
- (* = *)
	rewrite <- DTL.beqAddrTrue in beqaddr'part.
	rewrite beqaddr'part in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence) ; intuition.
	destruct v ; try(exfalso ; congruence) ; intuition.
- (* <> *)
	rewrite <- beqAddrFalse in *.
	rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.

	assert(HEq2 :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0; intuition.
	}
	rewrite HEq2.
	apply filterAccessibleEqBEAccessibleNoChange with bentry0; intuition.
Qed.


Lemma getAccessibleMappedBlocksEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq HpresentFalse.
intros HStartEq HendEq.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

unfold getAccessibleMappedBlocks.
assert(HpartEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. simpl.
	destruct (beqAddr addr' partition) eqn:beqblockpart.
	- rewrite <- DTL.beqAddrTrue in beqblockpart.
		subst addr'. unfold isPDT in *.
		rewrite Hlookupaddr's0 in *.
		exfalso ; congruence.
	- rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity in * ; intuition.
}
fold s'.
rewrite HpartEq.
destruct (lookup partition (memory s0) beqAddr) ; try (intuition ; exfalso ; congruence).
destruct v ; intuition.
assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ 
	eapply getMappedBlocksEqBENoChange with bentry0; intuition.
}
rewrite HEq.
apply filterAccessibleEqBENotInListNoChange ; intuition.
assert(present bentry0 = false) by (rewrite HpresentEq in * ; intuition).
eapply BlockPresentFalseNotMapped with partition addr' bentry0 s0 in H0 ; intuition.
Qed.



Lemma getAccessibleMappedBlocksEqBEPresentChangeAccessibleFalse partition addr' newEntry s0 bentry0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
accessible newEntry = accessible bentry0 ->
accessible newEntry = false ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 Hlookupaddr's0 HpresentNotEq HpresentTrue HaccessibleEq HaccessibleFalse.

assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).

	assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
	{ apply getKSEntriesEqBE ; intuition.
	}
assert(HpartEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. simpl.
	destruct (beqAddr addr' partition) eqn:beqblockpart.
	- rewrite <- DTL.beqAddrTrue in beqblockpart.
		subst addr'. unfold isPDT in *.
		rewrite Hlookupaddr's0 in *.
		exfalso ; congruence.
	- rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity in * ; intuition.
}

assert(Haddr'NotAccessibleMappeds' : ~In addr' (getAccessibleMappedBlocks partition s')).
{
	eapply BlockAccessibleFalseNotMapped with newEntry; intuition.
	unfold s'. simpl. rewrite beqAddrTrue. trivial.
}

assert(Haddr'NotAccessibleMappeds0 : ~In addr' (getAccessibleMappedBlocks partition s0)).
{
	eapply BlockAccessibleFalseNotMapped with bentry0; intuition.
	rewrite <- HaccessibleEq. intuition.
}

assert(Haddr'NotMappeds0 : ~In addr' (getMappedBlocks partition s0)).
{
	eapply BlockPresentFalseNotMapped with bentry0; intuition.
	rewrite HpresentTrue in *.
	apply Bool.not_true_iff_false.
	intuition.
}

unfold getAccessibleMappedBlocks in *.
rewrite HpartEq in *.

destruct (lookup partition (memory s0) beqAddr) ; try (intuition ; exfalso ; congruence).
destruct v ; intuition.

assert(HfilterEq1 : filterAccessible (getMappedBlocks partition s0) s' = filterAccessible (getMappedBlocks partition s0) s0).
{
	eapply filterAccessibleEqBEAccessibleNoChange with bentry0; intuition.
}
rewrite <- HfilterEq1 in *.

unfold getMappedBlocks in *.
rewrite HEq.

induction ((filterOptionPaddr (getKSEntries partition s0))).
- intuition.
- simpl in *.
	destruct (beqAddr addr' a) eqn:beqaddr'a ; try (exfalso ; congruence).
	-- (* addr' = a *)
			rewrite <- DTL.beqAddrTrue in beqaddr'a.
			rewrite <- beqaddr'a in *.
			simpl in *.
			rewrite HpresentTrue in *. rewrite Hlookupaddr's0 in *.
			assert(Hpresents0false : present bentry0 = false).
			{ apply Bool.not_true_iff_false.
				intuition.
			}
			rewrite Hpresents0false in *.
			simpl in *. rewrite beqAddrTrue.
			rewrite HaccessibleFalse.

			induction l.
			--- intuition.
			--- simpl in *.
					rewrite beqaddr'a in *.
					destruct (beqAddr a a0) eqn:beqaddr'a0 ; try (exfalso ; congruence).
					---- (* addr' = a0 *)
							rewrite <- DTL.beqAddrTrue in beqaddr'a0.
							rewrite <- beqaddr'a0 in *.
							simpl in *.
							rewrite HpresentTrue in *. rewrite Hlookupaddr's0 in *.
							rewrite Hpresents0false in *.
							simpl in *. rewrite beqaddr'a in *. rewrite beqAddrTrue in *.
							rewrite HaccessibleFalse in *.
							apply IHl0 ; intuition.
					---- (* addr' <> a0 *)
								rewrite <- beqAddrFalse in *.
								rewrite removeDupIdentity in * ; intuition.
								subst a. subst addr'.
								unfold isPDT in *.
								rewrite Hlookupaddr's0 in *.
								exfalso ; congruence.
	-- (* addr' <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (present b) ; try(apply IHl; assumption).
			simpl in *.
			destruct (beqAddr addr' a) eqn:Hf ; try (exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Hf. congruence.
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (accessible b0) ; try(apply IHl; assumption).
			f_equal. apply IHl ; try(assumption). contradict Haddr'NotAccessibleMappeds0. simpl. right. assumption.
			injection HfilterEq1. intuition.
			subst addr'.
			unfold isPDT in *.
			rewrite Hlookupaddr's0 in *.
			exfalso ; congruence.
Qed.

(* DUP *)
Lemma getAccessibleMappedBlocksEqBEPresentTrueNoChangeAccessibleTrueChangeEquivalence partition block addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) <> (accessible bentry0) ->
(accessible newEntry) = true ->
noDupMappedBlocksList s0 ->
In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
In block
(getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) <->
In block
(addr' :: getAccessibleMappedBlocks partition s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq Hpresenttrue HacccessibleNotEq Haccessibletrue.
intros HNoDupMappedBlocks HaddrInKSentriess0.
assert(HPDTs0' : isPDT partition s0) by intuition.
apply isPDTLookupEq in HPDTs0'. destruct HPDTs0' as [pdentry0 Hlookuppds0].

assert(Haddr'NotMapped : ~In addr' (getAccessibleMappedBlocks partition s0)).
{
	apply BlockAccessibleFalseNotMapped with bentry0; intuition.
	rewrite Haccessibletrue in *.
	apply Bool.not_true_iff_false.
	intuition.
}

assert(Haddr'Mapped : In addr' (getMappedBlocks partition s0)).
{ unfold getMappedBlocks.
	induction (filterOptionPaddr (getKSEntries partition s0)).
	- intuition.
	- simpl in *. intuition.
		-- (* a = block*)
			subst a.
			rewrite Hlookupaddr's0.
			rewrite <- HpresentEq. rewrite Hpresenttrue. simpl. left. reflexivity.
		-- (* a <> block *)
				destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; intuition.
				destruct v ; intuition.
				destruct (present b) ; try(simpl; right); assumption.
}

unfold getAccessibleMappedBlocks in *.

assert(Haccessibles0false : accessible bentry0 = false).
{ rewrite Haccessibletrue in *.
	apply Bool.not_true_iff_false.
	intuition.
}

assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).

assert(HKSEntriesEq : getKSEntries partition s' = getKSEntries partition s0).
{
	apply getKSEntriesEqBE ; intuition.
}

assert(HpartEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. simpl.
	destruct (beqAddr addr' partition) eqn:beqblockpart.
	- rewrite <- DTL.beqAddrTrue in beqblockpart.
		subst addr'.
		unfold isBE in *. unfold isPDT in *.
		rewrite Hlookuppds0 in *. exfalso ; congruence.
	- rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity in * ; intuition.
}


assert(HmappedEq : getMappedBlocks partition s' = getMappedBlocks partition s0).
{
	eapply getMappedBlocksEqBENoChange with bentry0; intuition.
}

rewrite HpartEq in *.
specialize (HNoDupMappedBlocks partition HPDTs0).

rewrite Hlookuppds0 in *.

rewrite HmappedEq in *.
clear HmappedEq.

induction (getMappedBlocks partition s0).
- intuition.
- simpl in *.
	destruct (beqAddr addr' a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* addr' = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a.
		rewrite Haccessibletrue in *.
		rewrite Hlookupaddr's0 in *.
		rewrite Haccessibles0false in *.
		simpl in *.

		apply NoDup_cons_iff in HNoDupMappedBlocks.

		assert(HlFilterNoChange : filterAccessible l s' = filterAccessible l s0).
		{
			eapply filterAccessibleEqBENotInListNoChange ; intuition.
		} (* cause block is not in l so remaining didn't change *)
		rewrite HlFilterNoChange in *.
		intuition.
	-- (* addr' <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			apply NoDup_cons_iff in HNoDupMappedBlocks. destruct HNoDupMappedBlocks.
      destruct Haddr'Mapped as [Hcontra | Haddr'Mapped]; try(exfalso; congruence).
			destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try (apply IHl ; assumption).
			destruct v ; try (apply IHl ; assumption).
			destruct (accessible b) ; try (apply IHl ; assumption).
			simpl in *.
			intuition.
			intro beqblockpart. rewrite beqblockpart in *.
			destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
Qed.


Lemma getAccessibleMappedBlocksEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 HSCEs0.

unfold getAccessibleMappedBlocks.
apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry Hlookuppds0].

assert(HlookuppdEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. cbn.
	destruct (beqAddr addr' partition) eqn:Hf.
	- (* = *)
		rewrite <- DTL.beqAddrTrue in Hf.
		rewrite Hf in *.
		unfold isSCE in *.
		destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	- (* <> *)
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
}
rewrite HlookuppdEq. rewrite Hlookuppds0.

assert(HEq2 :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ apply getMappedBlocksEqSCE ; intuition.
	unfold isPDT. rewrite Hlookuppds0. trivial.
}
rewrite HEq2.
apply filterAccessibleEqSCE ; intuition.
Qed.


Lemma getAccessibleMappedBlocksEqSHE partition addr' newEntry s0:
isPDT partition s0 ->
isSHE addr' s0 ->
getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedBlocks partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTparts0 HSHEs0.

unfold getAccessibleMappedBlocks.
apply isPDTLookupEq in HPDTparts0. destruct HPDTparts0 as [pdentry Hlookuppds0].

assert(HlookuppdEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. cbn.
	destruct (beqAddr addr' partition) eqn:Hf.
	- (* = *)
		rewrite <- DTL.beqAddrTrue in Hf.
		rewrite Hf in *.
		unfold isSHE in *.
		destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	- (* <> *)
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
}
rewrite HlookuppdEq. rewrite Hlookuppds0.

assert(HEq2 :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ apply getMappedBlocksEqSHE ; intuition.
	unfold isPDT. rewrite Hlookuppds0. trivial.
}
rewrite HEq2.
apply filterAccessibleEqSHE ; intuition.
Qed.


Lemma getPDsPaddrEqPDT addr' newEntry s0 pdlist:
isPDT addr' s0 ->
getPDsPaddr pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getPDsPaddr pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold getPDsPaddr.
unfold isPDT in *.
induction pdlist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		intuition.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; f_equal ; intuition.
Qed.

Lemma getPDsPaddrEqBEStartNoChange addr' newEntry s0 bentry0 pdlist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
getPDsPaddr pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPDsPaddr pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddrs0 HStartNoChange.
unfold getPDsPaddr.
induction pdlist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		inversion Hlookupaddrs0 as [HEq].
		subst b.
		intuition.
		intuition.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; f_equal ; intuition.
Qed.

Lemma getPDsPaddrEqBENotInList addr' newEntry s0 bentry0 pdlist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
~In addr' pdlist ->
getPDsPaddr pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPDsPaddr pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddrs0 Haddr'NotIn.
unfold getPDsPaddr.
induction pdlist.
- intuition.
- simpl in *.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. intuition.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; f_equal ; intuition.
Qed.

Lemma childFilterEqPDT addr' newEntry s0 blockentryaddr:
isPDT addr' s0 ->
childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} blockentryaddr =
childFilter s0 blockentryaddr.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold childFilter.
cbn.

	destruct (beqAddr addr' blockentryaddr) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst blockentryaddr.
		unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup blockentryaddr (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx blockentryaddr sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:Hff ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hff.
					subst p.
					unfold isPDT in *.
					destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
Qed.


(* DUP *)
Lemma childFilterEqSCE addr' newEntry s0 blockentryaddr:
isSCE addr' s0 ->
childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} blockentryaddr =
childFilter s0 blockentryaddr.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold childFilter.
cbn.

	destruct (beqAddr addr' blockentryaddr) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst blockentryaddr.
		unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup blockentryaddr (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx blockentryaddr sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:Hff ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hff.
					subst p.
					unfold isSCE in *.
					destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
Qed.

(* DUP *)
Lemma childFilterEqSHEPDflagNoChange addr' newEntry s0 blockentryaddr sh1entry0:
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
(PDflag newEntry) = (PDflag sh1entry0) ->
childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} blockentryaddr =
childFilter s0 blockentryaddr.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold childFilter.
cbn.

	destruct (beqAddr addr' blockentryaddr) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst blockentryaddr.
		unfold isSHE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		trivial.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup blockentryaddr (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx blockentryaddr sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:Hff ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hff.
					subst p.
					unfold isSHE in *.
					destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
					inversion HPDTaddrs0 as [HEq].
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
Qed.



Lemma childFilterEqBE addr' newEntry s0 blockentryaddr:
isBE addr' s0 ->
childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} blockentryaddr =
childFilter s0 blockentryaddr.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold childFilter.
cbn.

	destruct (beqAddr addr' blockentryaddr) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst blockentryaddr.
		unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		destruct (Paddr.addPaddrIdx addr' sh1offset) eqn:Hsh1 ; intuition.
		destruct (beqAddr addr' p) eqn:Hp ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hp.
					subst addr'. rewrite Hff. trivial.
		--- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup blockentryaddr (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx blockentryaddr sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:Hff ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hff.
					subst p.
					unfold isBE in *.
					destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
Qed.

(*
Lemma childFilterEqBEPDflagFalse addr' newEntry s0 blockentryaddr sh1entryaddr:
isBE addr' s0 ->
(*startAddr (blockrange newEntry) <> startAddr (blockrange bentry0) ->*)
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} blockentryaddr =
childFilter s0 blockentryaddr.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0 (*Hstartnochanges0*) Hsh1entryaddr Hsh1pdflag.
unfold childFilter.
cbn.

	destruct (beqAddr addr' blockentryaddr) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst blockentryaddr.
		unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		destruct (Paddr.addPaddrIdx addr' sh1offset) eqn:Hsh1 ; intuition.
		destruct (beqAddr addr' p) eqn:Hp ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hp.
					subst addr'. rewrite Hff. trivial.
		--- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
	--
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup blockentryaddr (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx blockentryaddr sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:Hff ; intuition.
			--- rewrite <- DTL.beqAddrTrue in Hff.
					subst p.
					unfold isBE in *.
					destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
Qed.*)


Lemma getPDsEqPDT addr' newEntry s0 pdlist:
isPDT addr' s0 ->
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold getPDs.
unfold s'. simpl.
fold s'.
induction pdlist.
- intuition.
- simpl.
	assert(HEq :  (childFilter s' a = (childFilter s0 a))).
	{ eapply childFilterEqPDT ; intuition.
	}
rewrite HEq.
destruct (childFilter s0 a) eqn:beqfilter ; intuition.
simpl.
destruct (beqAddr addr' a) eqn:Hf ; intuition.
-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		intuition.
-- rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	intuition.
Qed.

(* DUP *)
Lemma getPDsEqSCE addr' newEntry s0 pdlist:
isSCE addr' s0 ->
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddrs0.
unfold getPDs.
unfold s'. simpl.
fold s'.
induction pdlist.
- intuition.
- simpl.
	assert(HEq :  (childFilter s' a = (childFilter s0 a))).
	{ eapply childFilterEqSCE ; intuition.
	}
rewrite HEq.
destruct (childFilter s0 a) eqn:beqfilter ; intuition.
simpl.
destruct (beqAddr addr' a) eqn:Hf ; intuition.
-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		intuition.
-- rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	intuition.
Qed.


(* DUP *)
Lemma getPDsEqSHEPDflagNoChange addr' newEntry s0 pdlist sh1entry0:
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
(PDflag newEntry) = (PDflag sh1entry0) ->
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HPDflagEq.
unfold getPDs.
unfold s'. simpl.
fold s'.
induction pdlist.
- intuition.
- simpl.
	assert(HEq :  (childFilter s' a = (childFilter s0 a))).
	{ eapply childFilterEqSHEPDflagNoChange with sh1entry0; intuition.
	}
rewrite HEq.
destruct (childFilter s0 a) eqn:beqfilter ; intuition.
simpl.
destruct (beqAddr addr' a) eqn:Hf ; intuition.
-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		intuition.
-- rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	intuition.
Qed.

Lemma getPDsEqBENoStartChange addr' newEntry s0 bentry0 pdlist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HstartBEEq.
unfold getPDs.
unfold s'. simpl.
fold s'.
induction pdlist.
- intuition.
- simpl.
	assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; intuition).
	assert(HEq :  (childFilter s' a = (childFilter s0 a))).
	{ eapply childFilterEqBE ; intuition.
	}
rewrite HEq.
destruct (childFilter s0 a) eqn:beqfilter ; intuition.
simpl.
destruct (beqAddr addr' a) eqn:Hf ; intuition.
-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a.
		rewrite Hlookupaddr's0.
		f_equal.
		intuition. intuition.
-- rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	intuition.
Qed.

Lemma getPDsEqBENotInList addr' newEntry s0 bentry0 pdlist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
~In addr' pdlist ->
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 Haddr'NotInList.
unfold getPDs.
unfold s'. simpl.
fold s'.


assert(HchildFilterEq : forall block, childFilter s' block = childFilter s0 block).
{
	intros block.
	unfold childFilter.
	simpl.
	destruct (beqAddr addr' block) eqn:Hf ; intuition.
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst block.
		rewrite Hlookupaddr's0.
		destruct (Paddr.addPaddrIdx addr' sh1offset) ; intuition.
		destruct (beqAddr addr' p) eqn:beqaddr'p.
		--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
				subst p.
				rewrite Hlookupaddr's0.
				trivial.
		--- rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
	-- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup block (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx block sh1offset) ; intuition.
			destruct (beqAddr addr' p) eqn:beqaddr'p.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
					subst p.
					rewrite Hlookupaddr's0.
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
}
assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; intuition).
assert(HBEs : isBE addr' s').
{
	unfold isBE. unfold s'. simpl. rewrite beqAddrTrue. trivial.
}
induction pdlist.
- intuition.
- simpl in *.
	assert(HchildFilterEq' : childFilter s' a = childFilter s' a)
		by (specialize (HchildFilterEq a) ; trivial).
	rewrite HchildFilterEq.
	destruct (childFilter s0 a) ; intuition.
	simpl.
	destruct (beqAddr addr' a) eqn:beqaddr'p.
	-- rewrite <- DTL.beqAddrTrue in beqaddr'p.
			subst a.
			rewrite Hlookupaddr's0.
			unfold childFilter in HchildFilterEq.
			unfold isBE in *.
			destruct (lookup addr' (memory s') beqAddr) ; try(exfalso ; congruence).
	-- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; f_equal ; intuition.
Qed.

(* if the pdflag is false, whatever the changes of type BE, the list didn't change *)
Lemma getPDsEqBEPDflagFalse addr' newEntry s0 bentry0 sh1entryaddr pdlist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(*startAddr (blockrange newEntry) <> startAddr (blockrange bentry0) ->*)
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
(*(present newEntry) = (present bentry0) ->*)
getPDs pdlist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPDs pdlist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 Hsh1entryaddr Hsh1pdflagfalse.
unfold getPDs.
unfold s'. simpl.
fold s'.
induction pdlist.
- intuition.
- simpl.
	assert(HBEs0 : isBE addr' s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; intuition).
	assert(HEq :  (childFilter s' a = (childFilter s0 a))).
	{ eapply childFilterEqBE ; intuition.
	}
rewrite HEq.
destruct (childFilter s0 a) eqn:beqfilter ; intuition.
unfold childFilter in HEq.

simpl.
destruct (beqAddr addr' a) eqn:Hf ; intuition.
-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold sh1entryAddr in *. unfold sh1entryPDflag in *.
		rewrite Hlookupaddr's0 in *.
		subst sh1entryaddr.
		unfold s' in HEq. cbn in HEq. rewrite beqAddrTrue in *.

		unfold CPaddr in *. unfold Paddr.addPaddrIdx in *.

		destruct (le_dec (addr' + sh1offset) maxAddr) ; try(exfalso ; congruence).
		assert(HEq' : {|
                        p := addr' + sh1offset;
                        Hp := ADT.CPaddr_obligation_1 (addr' + sh1offset) l
                      |} = {|
              p := addr' + sh1offset;
              Hp := StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l
            |}) by (f_equal ; eapply proof_irrelevance).
		rewrite HEq' in *.
		set (sh1entry := {|
            p := addr' + sh1offset; Hp :=  StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l |}).
		fold sh1entry in HEq. fold sh1entry in Hsh1pdflagfalse.
		destruct (beqAddr addr' sh1entry) eqn:Hf ; try(exfalso ; congruence).
		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity in HEq ; intuition.
		destruct (lookup sh1entry (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; intuition.
		congruence.
-- rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	intuition.
Qed.


Lemma getChildrenEqPDT partition addr' newEntry s0 pdentry0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
(structure newEntry) = (structure pdentry0) ->
StructurePointerIsKS s0 ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructEq HStructPtIsKS.
unfold getChildren.
unfold s'. simpl.

assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; trivial).

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	rewrite Hlookuppds0.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ apply getMappedBlocksEqPDT with pdentry0 ; intuition.
	}
	rewrite HEq.
	apply getPDsEqPDT ; intuition.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqPDT with pdentry0 ; intuition.
	}
	rewrite HEq.
	apply getPDsEqPDT ; intuition.
Qed.


Lemma getChildrenEqPDTNotInPart partition addr' newEntry s0 pdentry0:
StructurePointerIsKS s0 ->
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
partition <> addr' ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HStructPtIsKSs0 Hlookupaddr's0 Haddr'partNotEq.
unfold getChildren.
unfold s'. simpl.

assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookupaddr's0 ; trivial).

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
rewrite <- DTL.beqAddrTrue in beqpartaddr. congruence.
(* addr' <> partition *)
rewrite <- beqAddrFalse in *.
repeat rewrite removeDupIdentity ; intuition.
destruct (lookup partition (memory s0) beqAddr) ; intuition.
destruct v ; intuition.
fold s'.
assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ eapply getMappedBlocksEqPDTNotInPart ; intuition.
}
rewrite HEq.
apply getPDsEqPDT ; intuition.
Qed.

(* if the entry changed but the start address and the present flag did not,
		then the list did not change *)
Lemma getChildrenEqBENoStartNoPresentChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
(present newEntry) = (present bentry0) ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 Hstarts0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0  ; intuition.
	}
	rewrite HEq.
	apply getPDsEqBENoStartChange with bentry0 ; intuition.
Qed.

(* if the entry changed but the present flag did not change and is false,
		then the list did not change *)
Lemma getChildrenEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present bentry0) = false ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 HpresentEq HpresentFalse.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0  ; intuition.
	}
	rewrite HEq.
	assert(~In addr' (getMappedBlocks partition s0)).
	{
		apply BlockPresentFalseNotMapped with bentry0; intuition.
	}
	apply getPDsEqBENotInList with bentry0 ; intuition.
Qed.

Lemma filterchildFilterEqBE addr' l newEntry bentry0 s0:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
filter (childFilter {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) l =
filter (childFilter s0) l.
Proof.
intros HBEs0.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).

assert(HchildFilterEq : forall block, childFilter s' block = childFilter s0 block).
{
	intros block.
	assert(isBE addr' s0).
	{ unfold isBE. rewrite HBEs0. trivial. }
	eapply childFilterEqBE ; intuition.
}
induction l.
- intuition.
- simpl.
	specialize (HchildFilterEq a).
	rewrite HchildFilterEq.
	destruct (childFilter s0 a) ; intuition.
	f_equal. intuition.
Qed.

(* if the content of the BE entry changed, but its pdflag was not set, then
		it doesn't participate in the children list and thus the list remains unchanged *)
Lemma getChildrenEqBEPDflagFalsePresentTrueChange partition addr' newEntry bentry0 sh1entryaddr s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
noDupKSEntriesList s0 ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 Haddr'IsMapped Hsh1addrs0 Hsh1pdflags0 HpresentNotEqs0 HpresentTrue.
intros HNoDupKSEntriess0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(forall block, In block (getMappedBlocks partition s') -> In block (
addr'::getMappedBlocks partition s0) /\ NoDup(addr'::getMappedBlocks partition s0)
/\ NoDup (getMappedBlocks partition s')).
	{ intros.
		unfold getMappedBlocks in *.
 		eapply getMappedBlocksEqBEPresentChange with bentry0 ; intuition.
	}
	unfold getMappedBlocks in *.
	assert(HKSEntriesEq : (getKSEntries partition s') = (getKSEntries partition s0)).
	{
		assert(isBE addr' s0) by (unfold isBE ; rewrite HBEs0 ; trivial).
		apply getKSEntriesEqBE ; intuition.
	}
	rewrite HKSEntriesEq in *.
	unfold noDupKSEntriesList in *.
	specialize (HNoDupKSEntriess0 partition HPDTs0).
assert(HchildFilterEq : forall block, childFilter s' block = childFilter s0 block).
{
	intros block.
	unfold childFilter.
	simpl.
	destruct (beqAddr addr' block) eqn:Hf ; intuition.
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst block.
		rewrite HBEs0.
		destruct (Paddr.addPaddrIdx addr' sh1offset) ; intuition.
		destruct (beqAddr addr' p0) eqn:beqaddr'p.
		--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
				subst p0.
				rewrite HBEs0.
				trivial.
		--- rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
	-- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup block (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx block sh1offset) ; intuition.
			destruct (beqAddr addr' p0) eqn:beqaddr'p.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
					subst p0.
					rewrite HBEs0.
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
}
		unfold getPDs.
		induction (filterOptionPaddr (getKSEntries partition s0)).
		-- simpl in *. intuition.
		-- simpl in *.
				destruct (beqAddr addr' a) eqn:beqaddr'a.
				--- rewrite <- DTL.beqAddrTrue in beqaddr'a.
						subst a.
						rewrite HpresentTrue in *.
						rewrite HBEs0 in *.
					assert(Hpresents0false : present bentry0 = false).
					{ apply Bool.not_true_iff_false.
						intuition.
					}
					rewrite Hpresents0false in *.
					specialize (H addr').
					assert(Haddr'Mapped : In addr' (addr' :: filterPresent l s')) by (simpl; left; reflexivity).
					destruct H ; trivial.
					destruct H0 as [HNoDup1 HNoDup2].
					apply NoDup_cons_iff in HNoDup1. apply NoDup_cons_iff in HNoDup2.
					apply NoDup_cons_iff in HNoDupKSEntriess0.
					simpl in *.	intuition.

					assert(filterPresentEq : filterPresent l s' = filterPresent l s0).
					{
						apply filterPresentEqBENotInListNoChange ; intuition.
					}
					rewrite filterPresentEq.
					unfold getPDs. simpl.
					assert(Haddr'FilteredOut : childFilter s' addr' = false).
					{
						unfold childFilter. unfold s'. simpl. rewrite beqAddrTrue.
						unfold sh1entryAddr in *. unfold sh1entryPDflag in *.
						rewrite HBEs0 in *.
						unfold Paddr.addPaddrIdx in *. unfold CPaddr in *.
						destruct (le_dec (addr' + sh1offset) maxAddr) ; intuition.
						assert(Hsh1entryaddrEq : {|
		                     p := addr' + sh1offset;
		                     Hp :=
		                       StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l0
		                   |} = sh1entryaddr).
						{
							subst sh1entryaddr. f_equal.
						}
						rewrite Hsh1entryaddrEq in *.
						destruct (beqAddr addr' sh1entryaddr) eqn:Hf ; try(exfalso ; congruence).
							- rewrite <- DTL.beqAddrTrue in Hf.
								subst addr'.
								destruct (lookup sh1entryaddr (memory s0) beqAddr ) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
							- rewrite <- beqAddrFalse in *.
								rewrite removeDupIdentity ; intuition.
								destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
								intuition.
					}
					rewrite Haddr'FilteredOut. intuition.
					assert(HfilterEq : (filter (childFilter s') (filterPresent l s0)) = (filter (childFilter s0) (filterPresent l s0))).
					{
							apply filterchildFilterEqBE with bentry0 ; intuition.
					}
					rewrite HfilterEq.
					apply getPDsPaddrEqBENotInList with bentry0 ; intuition.
					eapply NotInListNotInFilter with addr' (filterPresent l s0) s0 in H. intuition.
					intuition.
				---	rewrite <- beqAddrFalse in *.
						rewrite removeDupIdentity in * ; try(apply not_eq_sym; assumption).
						apply NoDup_cons_iff in HNoDupKSEntriess0.
            destruct Haddr'IsMapped as [Hcontra | Haddr'IsMapped]; try(exfalso; congruence).
            destruct HNoDupKSEntriess0.
						destruct (lookup a (memory s0) beqAddr) ; try(apply IHl; assumption).
						destruct v ; try(apply IHl; assumption).
						destruct (present b) ; try(apply IHl; assumption).
						specialize (H a). destruct H ; try(simpl; left; reflexivity). destruct H2.
						apply NoDup_cons_iff in H2. destruct H2.
						apply NoDup_cons_iff in H3. apply NoDup_cons_iff in H4.
						simpl in *. intuition.
						unfold getPDs. simpl.
						assert(HchildFilterEq' : childFilter s' a = childFilter s0 a).
						{
							specialize (HchildFilterEq a). intuition.
						}
						rewrite HchildFilterEq'. simpl in *.
						destruct (childFilter s0 a) ; intuition.
						* simpl.
							destruct (beqAddr addr' a) eqn:Hf.
							rewrite <- DTL.beqAddrTrue in Hf. congruence.
							rewrite <- beqAddrFalse in *.
							rewrite removeDupIdentity ; intuition.
							subst. f_equal.
							apply H8. intros.
						assert(HblockIn : In block (addr' :: filterPresent l s0) /\
       NoDup (addr' :: filterPresent l s0)).
						{
							eapply filterPresentEqBEChangePresentTrue with newEntry bentry0 ; intuition.
						}
						destruct HblockIn as [HBlockIn HNoDup].
						simpl in *. intuition.
						* apply H8. intros.
						assert(HblockIn : In block (addr' :: filterPresent l s0) /\
       NoDup (addr' :: filterPresent l s0)).
						{
							eapply filterPresentEqBEChangePresentTrue with newEntry bentry0 ; intuition.
						}
						destruct HblockIn as [HBlockIn HNoDup].
						simpl in *. intuition.
Qed.

(* if the content of the BE entry changed, but its pdflag was not set, then
		it doesn't participate in the children list and thus the list remains unchanged 
		(because here we change a BE entry and not a Sh1 entry) *)
Lemma getChildrenEqBEPDflagFalse partition addr' newEntry bentry0 sh1entryaddr s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
(*noDupKSEntriesList s0 ->*)
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 Hsh1addrs0 Hsh1pdflags0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HKSEntriesEq : (getKSEntries partition s') = (getKSEntries partition s0)).
	{
		assert(isBE addr' s0) by (unfold isBE ; rewrite HBEs0 ; trivial).
		apply getKSEntriesEqBE ; intuition.
	}
	unfold getMappedBlocks in *.
	rewrite HKSEntriesEq in *.
	(*unfold noDupKSEntriesList in *.
	specialize (HNoDupKSEntriess0 partition HPDTs0).*)
assert(HchildFilterEq : forall block, childFilter s' block = childFilter s0 block).
{
	intros block.
	unfold childFilter.
	simpl.
	destruct (beqAddr addr' block) eqn:Hf ; intuition.
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst block.
		rewrite HBEs0.
		destruct (Paddr.addPaddrIdx addr' sh1offset) ; intuition.
		destruct (beqAddr addr' p0) eqn:beqaddr'p.
		--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
				subst p0.
				rewrite HBEs0.
				trivial.
		--- rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
	-- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup block (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx block sh1offset) ; intuition.
			destruct (beqAddr addr' p0) eqn:beqaddr'p.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
					subst p0.
					rewrite HBEs0.
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
}
		unfold getPDs.
		induction (filterOptionPaddr (getKSEntries partition s0)).
		-- simpl in *. intuition.
		-- simpl in *.
			assert(Haddr'FilteredOut : childFilter s' addr' = false).
			{
				unfold childFilter. unfold s'. simpl. rewrite beqAddrTrue.
				unfold sh1entryAddr in *. unfold sh1entryPDflag in *.
				rewrite HBEs0 in *.
				unfold Paddr.addPaddrIdx in *. unfold CPaddr in *.
				destruct (le_dec (addr' + sh1offset) maxAddr) ; intuition.
				assert(Hsh1entryaddrEq : {|
                     p := addr' + sh1offset;
                     Hp :=
                       StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l0
                   |} = sh1entryaddr).
				{
					subst sh1entryaddr. f_equal.
				}
				rewrite Hsh1entryaddrEq in *.
				destruct (beqAddr addr' sh1entryaddr) eqn:Hf ; try(exfalso ; congruence).
					- rewrite <- DTL.beqAddrTrue in Hf.
						subst addr'.
						destruct (lookup sh1entryaddr (memory s0) beqAddr ) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					- rewrite <- beqAddrFalse in *.
						rewrite removeDupIdentity ; intuition.
						destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
			}

			assert(Haddr'FilteredOuts0 : childFilter s0 addr' = false).
			{
				unfold childFilter.
				unfold sh1entryAddr in *. unfold sh1entryPDflag in *.
				rewrite HBEs0 in *.
				unfold Paddr.addPaddrIdx in *. unfold CPaddr in *.
				destruct (le_dec (addr' + sh1offset) maxAddr) ; intuition.
				assert(Hsh1entryaddrEq : {|
                     p := addr' + sh1offset;
                     Hp :=
                       StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l0
                   |} = sh1entryaddr).
				{
					subst sh1entryaddr. f_equal.
				}
				rewrite Hsh1entryaddrEq in *.
				destruct (beqAddr addr' sh1entryaddr) eqn:Hf ; try(exfalso ; congruence).
					- rewrite <- DTL.beqAddrTrue in Hf.
						subst addr'.
						destruct (lookup sh1entryaddr (memory s0) beqAddr ) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					- destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
			}
			destruct (beqAddr addr' a) eqn:beqaddr'a.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'a.
					subst a.
					rewrite HBEs0 in *.
					destruct (present newEntry) eqn:HpresentNew ; try(exfalso ; congruence).
					---- destruct (present bentry0) eqn:Hpresent0 ; try(exfalso ; congruence).
								----- simpl.
											rewrite Haddr'FilteredOuts0. rewrite Haddr'FilteredOut.
											intuition.
								----- simpl. rewrite Haddr'FilteredOut. intuition.
					---- destruct (present bentry0) eqn:Hpresent0 ; try(exfalso ; congruence).
								----- simpl.
											rewrite Haddr'FilteredOuts0.
											intuition.
								----- simpl. intuition.
			---	rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity in * ; intuition.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) ; intuition.
					simpl.
					assert(HchildFilterEq' : childFilter s' a = childFilter s0 a).
					{
						specialize (HchildFilterEq a). intuition.
					}
					rewrite HchildFilterEq'. simpl in *.
					destruct (childFilter s0 a) ; intuition.
					simpl.
					destruct (beqAddr addr' a) eqn:Hf.
					rewrite <- DTL.beqAddrTrue in Hf. congruence.
					rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity ; intuition.
					subst. f_equal. intuition.
Qed.

Lemma getChildrenEqBEPDflagNoChangePresentNoChange partition addr' newEntry bentry0 sh1entryaddr s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
sh1entryAddr addr' sh1entryaddr s0 ->
lookup sh1entryaddr (memory {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) beqAddr = lookup sh1entryaddr (memory s0) beqAddr ->
(present newEntry) = (present bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
wellFormedFstShadowIfBlockEntry s0 ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 Hsh1addrs0 Hsh1pdflags0
HpresentEq HstartAddrEq.
intros HNoDupKSEntriess0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HKSEntriesEq : (getKSEntries partition s') = (getKSEntries partition s0)).
	{
		assert(isBE addr' s0) by (unfold isBE ; rewrite HBEs0 ; trivial).
		apply getKSEntriesEqBE ; intuition.
	}
	unfold getMappedBlocks in *.
	rewrite HKSEntriesEq in *.
assert(HchildFilterEq : forall block, childFilter s' block = childFilter s0 block).
{
	intros block.
	unfold childFilter.
	simpl.
	destruct (beqAddr addr' block) eqn:Hf ; intuition.
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst block.
		rewrite HBEs0.
		destruct (Paddr.addPaddrIdx addr' sh1offset) ; intuition.
		destruct (beqAddr addr' p0) eqn:beqaddr'p.
		--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
				subst p0.
				rewrite HBEs0.
				trivial.
		--- rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
	-- rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup block (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			destruct (Paddr.addPaddrIdx block sh1offset) ; intuition.
			destruct (beqAddr addr' p0) eqn:beqaddr'p.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'p.
					subst p0.
					rewrite HBEs0.
					trivial.
			--- rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
}
		assert(HBEaddr's0 : isBE addr' s0).
		{
			unfold isBE. rewrite HBEs0. trivial.
		}
		assert(HSHEs0 : isSHE sh1entryaddr s0).
		{
			specialize (HNoDupKSEntriess0 addr' HBEaddr's0).
			unfold sh1entryAddr in *. rewrite HBEs0 in *.
			subst sh1entryaddr. intuition.
		}
		unfold getPDs.
		induction (filterOptionPaddr (getKSEntries partition s0)).
		-- simpl in *. intuition.
		-- simpl in *.
			assert(Haddr'FilteredOutEq : childFilter s' addr' =  childFilter s0 addr').
			{
				unfold childFilter. unfold s'. simpl. rewrite beqAddrTrue.
				unfold sh1entryAddr in *. unfold sh1entryPDflag in *.
				rewrite HBEs0 in *.
				unfold Paddr.addPaddrIdx in *. unfold CPaddr in *.
				destruct (le_dec (addr' + sh1offset) maxAddr) ; intuition.
				assert(Hsh1entryaddrEq : {|
                     p := addr' + sh1offset;
                     Hp :=
                       StateLib.Paddr.addPaddrIdx_obligation_1 addr' sh1offset l0
                   |} = sh1entryaddr).
				{
					subst sh1entryaddr. f_equal.
				}
				rewrite Hsh1entryaddrEq in *.
				destruct (beqAddr addr' sh1entryaddr) eqn:Hf ; try(exfalso ; congruence).
					- rewrite <- DTL.beqAddrTrue in Hf.
						rewrite Hf in *.
						unfold isSHE in *. unfold isBE in *.
						rewrite HBEs0 in *.
						congruence.
					- rewrite <- beqAddrFalse in *.
						rewrite removeDupIdentity ; intuition.
			}
			destruct (beqAddr addr' a) eqn:beqaddr'a.
			--- rewrite <- DTL.beqAddrTrue in beqaddr'a.
					subst a.
					rewrite HBEs0 in *.
					rewrite <- HpresentEq.
					destruct (present newEntry) eqn:HpresentNew ; try(exfalso ; congruence).
					---- simpl.
							rewrite Haddr'FilteredOutEq.
							destruct (childFilter s0 addr') ; intuition.
							simpl. rewrite beqAddrTrue. rewrite HBEs0.
							rewrite HstartAddrEq. f_equal.
							intuition.
					---- intuition.
			--- assert(HaEq : lookup a (removeDup addr' (memory s0) beqAddr) beqAddr = lookup a (memory s0) beqAddr).
					{
						rewrite <- beqAddrFalse in *.
						rewrite removeDupIdentity in * ; intuition.
						subst. unfold isBE in *. unfold isSHE in *.
						destruct(lookup addr' (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					}
					rewrite HaEq.
					destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (present b) ; intuition.
					simpl.
					assert(HchildFilterEq' : childFilter s' a = childFilter s0 a).
					{
						specialize (HchildFilterEq a). intuition.
					}
					rewrite HchildFilterEq'.
					destruct (childFilter s0 a) ; intuition.
					simpl.
					destruct (beqAddr addr' a) eqn:Hf.
					rewrite <- DTL.beqAddrTrue in Hf. congruence.
					rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity  in *; intuition.
					rewrite HaEq. f_equal. intuition.
					subst. unfold isBE in *. unfold isSHE in *.
					destruct(lookup addr' (memory s0) beqAddr) ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
Qed.

(*
Lemma getChildrenEqBEPresentTrueChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 HpresentNotEq HpresentTrue.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0  ; intuition.
	}
	rewrite HEq.
	assert(~In addr' (getMappedBlocks partition s0)).
	{
		apply BlockPresentFalseNotMapped with bentry0; intuition.
	}
	apply getPDsEqBENotInList with bentry0 ; intuition.
Qed.*)

Lemma getChildrenEqBENotInPart partition addr' newEntry s0:
isBE addr' s0 ->
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HBEs0 Haddr'NotIns0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *. unfold isBE in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	reflexivity.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HKSEntriesEq : (getKSEntries partition s') = (getKSEntries partition s0)).
	{
		apply getKSEntriesEqBE ; intuition.
	}
	assert(HgetMappedBlocksEq : (getMappedBlocks partition s') = (getMappedBlocks partition s0)).
	{
		apply getMappedBlocksEqBENotInPart ; intuition.
	}
	rewrite HgetMappedBlocksEq.
	apply isBELookupEq in HBEs0. destruct HBEs0 as [bentry0 Hlookupbes0].
	eapply getPDsEqBENotInList with bentry0 ; intuition.
	unfold getMappedBlocks in *.
	eapply NotInListNotInFilterPresent with addr' ?[unknown] s0 in Haddr'NotIns0.
	congruence.
Qed.

(* DUP *)
Lemma getChildrenEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSCEs0.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSCE in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).
	intuition.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqSCE ; intuition.
	}
	rewrite HEq.
	apply getPDsEqSCE ; intuition.
Qed.


(* DUP *)
Lemma getChildrenEqSHE partition addr' newEntry s0 sh1entry0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
(PDflag newEntry) = (PDflag sh1entry0) ->
getChildren partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getChildren partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HPDflagEq.
unfold getChildren.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSHE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	destruct (lookup partition (memory s0) beqAddr) ; intuition.
	destruct v ; intuition.
	fold s'.
	assert(HSHEs0 : isSHE addr' s0) by (unfold isSHE ; rewrite Hlookupaddr's0 ; trivial).
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqSHE ; intuition.
	}
	rewrite HEq.
	apply getPDsEqSHEPDflagNoChange with sh1entry0; intuition.
Qed.

(* DUP *)
Lemma getAllPaddrConfigAuxEqPDT addr' newEntry kslist s0:
isPDT addr' s0 ->
getAllPaddrConfigAux kslist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAllPaddrConfigAux kslist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros (*HPDTs0*) HPDTs0 (*Hlookupaddr's0 HPDflagEq*).
induction kslist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getConfigPaddrEqPDT partition addr' newEntry pdentry0 s0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
isPDT partition s0 ->
(structure newEntry) = (structure pdentry0) ->
getConfigPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getConfigPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HPDTparts0 HStructEq.
unfold getConfigPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	rewrite Hlookupaddr's0.
	f_equal.
	assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
	{ eapply getConfigBlocksEqPDT with pdentry0 ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrConfigAuxEqPDT ; intuition.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	f_equal.
	fold s'.
	assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
	{ eapply getConfigBlocksEqPDT with pdentry0 ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrConfigAuxEqPDT ; intuition.
	unfold isPDT. rewrite Hlookupaddr's0. trivial.
Qed.

(* DUP *)
Lemma getConfigPaddrEqPDTNotInPart partition addr' newEntry pdentry0 s0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
partition <> addr' ->
getConfigPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getConfigPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTaddr's0 Hpartaddr'NotEq.
unfold getConfigPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
rewrite <- DTL.beqAddrTrue in beqpartaddr. congruence.
(* addr' <> partition *)
rewrite <- beqAddrFalse in *.
repeat rewrite removeDupIdentity ; intuition.
f_equal.
fold s'.
assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
{ eapply getConfigBlocksEqPDTNotInPart with pdentry0; intuition.
}
rewrite HEq.
apply getAllPaddrConfigAuxEqPDT ; intuition.
unfold isPDT. rewrite HPDTaddr's0. trivial.
Qed.


(* DUP *)
Lemma getAllPaddrConfigAuxEqBE addr' newEntry kslist s0:
isBE addr' s0 ->
getAllPaddrConfigAux kslist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrConfigAux kslist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HSBEs0.
induction kslist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		f_equal.
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getConfigPaddrEqBE partition addr' newEntry s0:
isPDT partition s0 ->
isBE addr' s0 ->
getConfigPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getConfigPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0.
unfold getConfigPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isBE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isBE in *.
	assert(HPDTs0' : isPDT partition s0) by trivial.
	apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pdentry Hlookuparts0].
	rewrite Hlookuparts0.
	fold s'. f_equal.
	assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
	{ eapply getConfigBlocksEqBE  ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrConfigAuxEqBE ; intuition.
Qed.

(* DUP *)
Lemma getAllPaddrConfigAuxEqSCE addr' newEntry kslist s0:
isSCE addr' s0 ->
getAllPaddrConfigAux kslist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrConfigAux kslist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HSHEs0.
induction kslist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getConfigPaddrEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getConfigPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getConfigPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0.
unfold getConfigPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSCE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSCE in *.
	apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pdentry Hlookuparts0].
	rewrite Hlookuparts0.
	fold s'. f_equal.
	assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
	{ eapply getConfigBlocksEqSCE with pdentry ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrConfigAuxEqSCE ; intuition.
Qed.


(* DUP *)
Lemma getAllPaddrConfigAuxEqSHE addr' newEntry kslist s0:
isSHE addr' s0 ->
getAllPaddrConfigAux kslist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrConfigAux kslist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HSHEs0.
induction kslist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isSHE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getConfigPaddrEqSHE partition addr' newEntry s0:
isPDT partition s0 ->
isSHE addr' s0 ->
getConfigPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getConfigPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0.
unfold getConfigPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSHE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSHE in *.
	apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pdentry Hlookuparts0].
	rewrite Hlookuparts0.
	fold s'. f_equal.
	assert(HEq :  getConfigBlocks partition s' = getConfigBlocks partition s0).
	{ eapply getConfigBlocksEqSHE with pdentry ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrConfigAuxEqSHE ; intuition.
Qed.

Lemma filterPresentSplit l1 l2 s:
filterPresent (l1 ++ l2) s = filterPresent l1 s ++ filterPresent l2 s.
Proof.
induction l1.
- simpl. reflexivity.
- simpl. rewrite IHl1. destruct (lookup a (memory s) beqAddr); try(reflexivity). destruct v; try(reflexivity).
  destruct (present b); reflexivity.
Qed.

Lemma getAllPaddrAuxSplit l1 l2 s:
getAllPaddrAux (l1 ++ l2) s = getAllPaddrAux l1 s ++ getAllPaddrAux l2 s.
Proof.
induction l1.
- simpl. reflexivity.
- simpl. rewrite IHl1. destruct (lookup a (memory s) beqAddr); try(reflexivity). destruct v; try(reflexivity).
  apply app_assoc.
Qed.


(* DUP *)
Lemma getAllPaddrAuxEqPDT addr' newEntry blocklist s0:
isPDT addr' s0 ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isPDT in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getAllPaddrAuxEqBEStartEndNoChange addr' newEntry bentry0 blocklist s0:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HstartEq HendEq.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isBE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		rewrite HstartEq. rewrite HendEq.
		inversion Hlookupaddr's0 as [Heq].
		subst b.
		f_equal. intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* After state modification, if the modified entry is not in the list, no change *)
Lemma getAllPaddrAuxEqBENoInList (*block*) addr' newEntry s0 (*bentry0*) blocklist:
~In addr' blocklist ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Haddr'NotInList.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. simpl in *. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; try(apply not_eq_sym; assumption).
			destruct (lookup a (memory s0) beqAddr) ;
        try(apply IHblocklist; contradict Haddr'NotInList; simpl; right; assumption).
			destruct v ; try(apply IHblocklist; contradict Haddr'NotInList; simpl; right; assumption).
			simpl in *. intuition. f_equal. intuition.
Qed.

Lemma getAllPaddrAuxEqBEStartNoChangeEndNoChange (*block*) addr' newEntry s0 bentry0 blocklist:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr' HstartEq HendEq.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	-- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. rewrite Hlookupaddr'. rewrite HstartEq. rewrite HendEq.
		f_equal. intuition.
	--	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.


(* DUP *)
Lemma getAllPaddrAuxEqSCE addr' newEntry blocklist s0:
isSCE addr' s0 ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HSCEs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isSCE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.

(* DUP *)
Lemma getAllPaddrAuxEqSHE addr' newEntry blocklist s0:
isSHE addr' s0 ->
getAllPaddrAux blocklist {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getAllPaddrAux blocklist s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HSHEs0.
induction blocklist.
- intuition.
- simpl.
	destruct (beqAddr addr' a) eqn:Hf ; try(exfalso ; congruence).
	--- rewrite <- DTL.beqAddrTrue in Hf.
		subst a. unfold isSHE in *.
		destruct (lookup addr' (memory s0) beqAddr) eqn:Hff ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
		intuition.
	---
	rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			destruct (lookup a (memory s0) beqAddr) ; intuition.
			destruct v ; intuition.
			f_equal. intuition.
Qed.


(* DUP *)
Lemma getMappedPaddrEqPDT partition addr' newEntry pdentry0 s0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
(structure newEntry) = (structure pdentry0) ->
StructurePointerIsKS s0 ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructEq HKSPtnIsKS.
unfold getMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqPDT with pdentry0  ; intuition.
	}
	rewrite HEq.
	assert(HPDTs0 : isPDT partition s0) by (unfold isPDT ; rewrite Hlookuppds0 ; intuition).
	apply getAllPaddrAuxEqPDT ; intuition.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqPDT with pdentry0  ; intuition.
	}
	rewrite HEq.
	assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; intuition).
	apply getAllPaddrAuxEqPDT ; intuition.
Qed.

Lemma getMappedPaddrEqPDTNotInPart partition addr' newEntry s0:
isPDT addr' s0 ->
partition <> addr' ->
StructurePointerIsKS s0 ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpartNotEq HstructEq.
unfold getMappedPaddr.
unfold s'. simpl.

assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqPDTNotInPart  ; intuition.
	}
fold s'.
rewrite HEq.
apply getAllPaddrAuxEqPDT ; intuition.
Qed.

(* DUP *)
Lemma getMappedPaddrEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present bentry0) = false ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq Hpresentfalse.
unfold getMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0; intuition.
	}
	rewrite HEq.
	assert(Haddr'NotMapped : ~In addr' (getMappedBlocks partition s0)).
	{
		unfold getMappedBlocks.
		induction (filterOptionPaddr (getKSEntries partition s0)).
		- intuition.
		- simpl.
			destruct (beqAddr addr' a) eqn:beqaddr'a ; try(exfalso ; congruence).
			-- (* addr' = a *)
				rewrite <- DTL.beqAddrTrue in beqaddr'a.
				subst a. rewrite Hlookupaddr's0.
				rewrite Hpresentfalse.
				intuition.
			-- (* addr' <> a*)
				rewrite <- beqAddrFalse in *.
				destruct (lookup a (memory s0) beqAddr) ; intuition.
				destruct v ; intuition.
				destruct (present b) ; intuition.
				simpl in *. intuition.
	}
	apply getAllPaddrAuxEqBENoInList ; intuition.
Qed.

(* DUP *)
Lemma getMappedPaddrEqBEPresentTrueChange partition block addr newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
noDupKSEntriesList s0 ->
noDupMappedBlocksList s0 ->
(*noDupUsedPaddrList s0 ->*)
In block (filterOptionPaddr (getKSEntries partition s0)) ->
In addr
(getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) ->
In addr
(getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getMappedPaddr partition s0)
(*/\ NoDup(getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getMappedPaddr partition s0)*)
(*/\ NoDup (getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |})*).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentNotEq Hpresenttrue HstartEq HendEq.
intros HNoDupKSEntries HNoDupMappedBlocks (*HNoDupUsedPaddr*) HaddrInKSentriess0 HaddrIsMapped (*HNotMappeds0*).

	assert(Haddr'NotMapped : ~In block (getMappedBlocks partition s0)).
	{
		apply BlockPresentFalseNotMapped with bentry0; intuition.
		assert(Hpresents0false : present bentry0 = false).
		{ rewrite Hpresenttrue in *.
			apply Bool.not_true_iff_false.
			intuition.
		}
		trivial.
	}

	unfold getMappedPaddr in *.

		assert(Hpresents0false : present bentry0 = false).
		{ rewrite Hpresenttrue in *.
			apply Bool.not_true_iff_false.
			intuition.
		}

assert(HBEs0 : isBE block s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).

assert(HKSEntriesEq : getKSEntries partition s' = getKSEntries partition s0).
	{
		apply getKSEntriesEqBE ; intuition.
	}
assert (Haddr'Ismapped : In block (getMappedBlocks partition s')).
{
	unfold getMappedBlocks.
	rewrite HKSEntriesEq.
	simpl.
		induction ((filterOptionPaddr (getKSEntries partition s0))).
		- intuition.
		- simpl in *. intuition.
			subst a. rewrite beqAddrTrue.
			rewrite Hpresenttrue. simpl. left. reflexivity.
			destruct (beqAddr block a) eqn:beqaddr'a ; try (exfalso ; congruence).
			-- rewrite Hpresenttrue. simpl. left. rewrite DTL.beqAddrTrue. rewrite beqAddrSym. assumption.
			--
				rewrite <- beqAddrFalse in *.
				rewrite removeDupIdentity ; intuition.
				destruct (lookup a (memory s0) beqAddr) ; intuition.
				destruct v ; intuition.
				destruct (present b) ; try(simpl; right); assumption.
}
		assert(HNoDupMappeds : NoDup (getMappedBlocks partition s')).
		{ specialize (getMappedBlocksEqBEPresentChange block partition block newEntry s0 bentry0).
			intuition.

}

specialize (HNoDupMappedBlocks partition HPDTs0).

assert(HMappedBlocksPresentTrueModif : In block (
block::getMappedBlocks partition s0) /\ NoDup(block::getMappedBlocks partition s0)
/\ NoDup (getMappedBlocks partition s')).
{ eapply getMappedBlocksEqBEPresentChange with bentry0 ; intuition. }

unfold getMappedBlocks in *.

unfold noDupKSEntriesList in *.
specialize (HNoDupKSEntries partition HPDTs0).
rewrite HKSEntriesEq in *.

induction ((filterOptionPaddr (getKSEntries partition s0))).
- intuition.
-
		assert(Haddrs0 : (getAllPaddrAux (filterPresent l s0) s') =  (getAllPaddrAux (filterPresent l s0) s0)).
		{
			eapply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.

		}

 simpl in *.
destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a.
		rewrite Hpresenttrue in *. rewrite Hlookupaddr's0 in *.
		rewrite Hpresents0false in *.
		simpl in *. rewrite beqAddrTrue in *.

 		apply NoDup_cons_iff in HNoDupMappeds.
		apply NoDup_cons_iff in HNoDupKSEntries.
		assert(HlFilterNoChange : filterPresent l s' = filterPresent l s0).
		{
			eapply filterPresentEqBENotInListNoChange ; intuition.
		} (* cause block is not in l so remaining didn't change *)
		rewrite HlFilterNoChange in *.

		rewrite HstartEq in*. rewrite HendEq in *.
		rewrite Haddrs0 in *.
		intuition.

	-- (* block <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; try(apply not_eq_sym; assumption).

			apply NoDup_cons_iff in HNoDupKSEntries. destruct HNoDupKSEntries as (_ & HNoDupKSEntries).
      destruct HaddrInKSentriess0 as [Hcontra | HaddrInKSentriess0]; try(exfalso; congruence).
			destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try(apply IHl; assumption).
			destruct v ; try(apply IHl; assumption).
			destruct (present b) ; try(apply IHl; assumption).
			simpl in *.
			destruct (beqAddr block a) eqn:Hf ; try(exfalso; rewrite beqAddrFalse in beqaddr'a; congruence).
      rewrite <-beqAddrFalse in Hf.
			rewrite removeDupIdentity in * ; intuition.
			rewrite Hlookupas0 in *.
			apply in_app_or in HaddrIsMapped.

			assert(HInEq : In addr (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))
					\/
  In addr (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrAux (filterPresent l s0) s0) ->
In addr
  (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
   getAllPaddrAux (filterPresent l s0) s0)).
			{
				intros HaddrIn.
				apply in_app_iff. rewrite in_app_iff.
				intuition.
				rewrite in_app_iff in H7. intuition.
			}
			apply HInEq.
			intuition. right.
			apply NoDup_cons_iff in HNoDupMappeds.
			apply NoDup_cons_iff in HNoDupMappedBlocks.
			simpl in *.
			assert(NoDup (block :: filterPresent l s0)).
			{ apply NoDup_cons_iff.
				rewrite NoDup_cons_iff in H1.  (*NoDup (block :: a :: filterPresent l s0) *)
				rewrite NoDup_cons_iff in H1. (*  NoDup (block :: a :: filterPresent l s0) *)
				intuition. }
			apply H ; intuition. (*IHl*)
Qed.


(* DUP *)
Lemma getMappedPaddrEqBEPresentTrueChangeEquivalence partition block addr newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
noDupKSEntriesList s0 ->
noDupMappedBlocksList s0 ->
In block (filterOptionPaddr (getKSEntries partition s0)) ->
In addr
(getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) <->
In addr
(getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getMappedPaddr partition s0)
(*/\ NoDup(getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getMappedPaddr partition s0)*)
(*/\ NoDup (getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |})*).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentNotEq Hpresenttrue HstartEq HendEq.
intros HNoDupKSEntries HNoDupMappedBlocks HaddrInKSentriess0 (*HaddrIsMapped*) (*HNotMappeds0*).


	assert(Haddr'NotMapped : ~In block (getMappedBlocks partition s0)).
	{
		apply BlockPresentFalseNotMapped with bentry0; intuition.
		assert(Hpresents0false : present bentry0 = false).
		{ rewrite Hpresenttrue in *.
			apply Bool.not_true_iff_false.
			intuition.
		}
		trivial.
	}

	unfold getMappedPaddr in *.

		assert(Hpresents0false : present bentry0 = false).
		{ rewrite Hpresenttrue in *.
			apply Bool.not_true_iff_false.
			intuition.
		}

assert(HBEs0 : isBE block s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).

assert(HKSEntriesEq : getKSEntries partition s' = getKSEntries partition s0).
	{
		apply getKSEntriesEqBE ; intuition.
	}
assert (Haddr'Ismapped : In block (getMappedBlocks partition s')).
{
	unfold getMappedBlocks.
	rewrite HKSEntriesEq.
	simpl.
		induction ((filterOptionPaddr (getKSEntries partition s0))).
		- intuition.
		- simpl in *. intuition.
			subst a. rewrite beqAddrTrue.
			rewrite Hpresenttrue. simpl. left. reflexivity.
			destruct (beqAddr block a) eqn:beqaddr'a ; try (exfalso ; congruence).
			-- rewrite Hpresenttrue. simpl. right. assumption.
			--
				rewrite <- beqAddrFalse in *.
				rewrite removeDupIdentity ; intuition.
				destruct (lookup a (memory s0) beqAddr) ; intuition.
				destruct v ; intuition.
				destruct (present b) ; try(simpl; right); assumption.
}
		assert(HNoDupMappeds : NoDup (getMappedBlocks partition s')).
		{ specialize (getMappedBlocksEqBEPresentChange block partition block newEntry s0 bentry0).
			intuition.
		}

specialize (HNoDupMappedBlocks partition HPDTs0).

assert(HMappedBlocksPresentTrueModif : In block (
block::getMappedBlocks partition s0) /\ NoDup(block::getMappedBlocks partition s0)
/\ NoDup (getMappedBlocks partition s')).
{ eapply getMappedBlocksEqBEPresentChange with bentry0 ; intuition. }

unfold getMappedBlocks in *.

unfold noDupKSEntriesList in *.
specialize (HNoDupKSEntries partition HPDTs0).
rewrite HKSEntriesEq in *.

induction ((filterOptionPaddr (getKSEntries partition s0))).
- intuition.
-
		assert(Haddrs0 : (getAllPaddrAux (filterPresent l s0) s') =  (getAllPaddrAux (filterPresent l s0) s0)).
		{
			eapply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
		}


 simpl in *.
destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a.
		rewrite Hpresenttrue in *. rewrite Hlookupaddr's0 in *.
		rewrite Hpresents0false in *.
		simpl in *. rewrite beqAddrTrue in *.

 		apply NoDup_cons_iff in HNoDupMappeds.

		apply NoDup_cons_iff in HNoDupKSEntries.

		assert(HlFilterNoChange : filterPresent l s' = filterPresent l s0).
		{
			eapply filterPresentEqBENotInListNoChange ; intuition.
		} (* cause block is not in l so remaining didn't change *)
		rewrite HlFilterNoChange in *.

		rewrite HstartEq in*. rewrite HendEq in *.
		(*apply in_or_app.*) rewrite in_app_iff.
		rewrite Haddrs0 in *. split; intro Hhyp.
    + apply in_or_app. assumption.
    + apply in_app_or in Hhyp. assumption.
	-- (* block <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			(*simpl in HNoDupAllPaddrs'.*) apply NoDup_cons_iff in HNoDupKSEntries.
      destruct HNoDupKSEntries as (HaNotIn & HNoDupKSEntries).
      destruct HaddrInKSentriess0 as [Hcontra | HaddrInKSentriess0]; try(exfalso; congruence).
			destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try (apply IHl ; assumption).
			destruct v ; try (apply IHl ; assumption).
			destruct (present b) ; try (apply IHl ; assumption).
			simpl in *.
			destruct (beqAddr block a) eqn:Hf ; try (exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Hf. congruence.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			rewrite Hlookupas0 in *.
			rewrite in_app_iff. rewrite in_app_iff.

			assert(HInEq : In addr (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))
					\/
  In addr (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrAux (filterPresent l s0) s0) ->
In addr
  (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
   getAllPaddrAux (filterPresent l s0) s0)).
			{
				intros HaddrIn.
				apply in_app_iff. rewrite in_app_iff.
				intuition.
				rewrite in_app_iff in H3. (*getAllPaddrBlock bentry0 ++ getAllPaddr*)
				intuition.
			}
			apply NoDup_cons_iff in HNoDupMappeds.
			apply NoDup_cons_iff in HNoDupMappedBlocks.
			simpl in *.
			assert(NoDup (block :: filterPresent l s0)).
			{ apply NoDup_cons_iff. intuition. }
      assert(Hcopy: NoDup (block :: filterPresent l s0)) by assumption.
      apply NoDup_cons_iff in H. destruct H. destruct HNoDupMappeds.
      destruct Haddr'Ismapped as [Hcontra | Haddr'Ismapped]; try(exfalso; congruence).
      assert((block = block \/ In block (filterPresent l s0)) /\ NoDup (block :: filterPresent l s0)
              /\ NoDup (filterPresent l s')).
      { split; try(left; reflexivity). split; assumption. }
      split; intro Hhyp.
      + destruct Hhyp as [Hblock | Hs']; try(right; apply in_or_app; left; assumption).
        apply IHl in Hs'; try(assumption).
        apply in_app_or in Hs'. destruct Hs' as [Hleft | Hright]; try(left; assumption). right. apply in_or_app.
        right. assumption.
      + destruct Hhyp as [Hright | Hhyp]; try(right; apply IHl; try(assumption); apply in_or_app; left;
          assumption). apply in_app_or in Hhyp.
        destruct Hhyp as [Hleft | Hright]; try(right; apply IHl; try(assumption); apply in_or_app; right;
          assumption). left. assumption.
Qed.


Lemma getMappedPaddrEqBEPresentTrueChangeLengthEquality partition block newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
noDupKSEntriesList s0 ->
noDupMappedBlocksList s0 ->
In block (filterOptionPaddr (getKSEntries partition s0)) ->
length (getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) =
length (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getMappedPaddr partition s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentNotEq Hpresenttrue HstartEq HendEq.
intros HNoDupKSEntries HNoDupMappedBlocks HaddrInKSentriess0.


assert(HBEs0 : isBE block s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).
unfold getMappedPaddr. unfold getMappedBlocks.
assert(HEq :  getKSEntries partition s' = getKSEntries partition s0).
{ apply getKSEntriesEqBE ; intuition.
}
unfold getMappedBlocks.
rewrite HEq in *.
unfold noDupKSEntriesList in *. specialize (HNoDupKSEntries partition HPDTs0).
assert(HfilterPresentLengthEq : length
     (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s') =
length
  (block :: (filterPresent (filterOptionPaddr (getKSEntries partition s0)) s0))).
{
	eapply filterPresentEqBEChangePresentTrueLengthEquality with bentry0 ; intuition.
}

induction ((filterOptionPaddr (getKSEntries partition s0))).
- simpl in *. exfalso; congruence.
- simpl in *.

 simpl in *.
	destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a.
		rewrite Hpresenttrue in *. rewrite Hlookupaddr's0 in *.
		assert(Hpresents0false : present bentry0 = false)
				by (apply Bool.not_true_is_false ; intuition).
		rewrite Hpresents0false in *.
		simpl in *. rewrite beqAddrTrue in *.


		apply NoDup_cons_iff in HNoDupKSEntries.

		assert(HlFilterNoChange : filterPresent l s' = filterPresent l s0).
		{
			eapply filterPresentEqBENotInListNoChange ; intuition.
		} (* cause block is not in l so remaining didn't change *)
		rewrite HlFilterNoChange in *.

		rewrite HstartEq in*. rewrite HendEq in *.
		assert(HallpaddrEq : getAllPaddrAux (filterPresent l s0) s' = getAllPaddrAux (filterPresent l s0) s0).
		{
			eapply getAllPaddrAuxEqBEStartEndNoChange with bentry0; intuition.
		}
		rewrite HallpaddrEq. intuition.
	-- (* block <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			apply NoDup_cons_iff in HNoDupKSEntries. destruct HNoDupKSEntries as (HaNotIn & HNoDupKSEntries).
      destruct HaddrInKSentriess0 as [Hcontra | HaddrInKSentriess0]; try(exfalso; congruence).
			destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try (apply IHl ; assumption).
			destruct v ; try (apply IHl ; assumption).
			destruct (present b) ; try (apply IHl ; assumption).
			simpl in *.
			destruct (beqAddr block a) eqn:Hf ; try (exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Hf. congruence.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			rewrite Hlookupas0 in *.
			assert(HNewGoal : length
						(getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
						 getAllPaddrAux (filterPresent l s') s') =
					length
						(getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
					(getAllPaddrBlock (startAddr (blockrange bentry0))
							 (endAddr (blockrange bentry0)) ++
						 getAllPaddrAux (filterPresent l s0) s0)) ->
					length
						(getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
						 getAllPaddrAux (filterPresent l s') s') =
					length
						(getAllPaddrBlock (startAddr (blockrange bentry0))
							 (endAddr (blockrange bentry0)) ++
						 getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
						 getAllPaddrAux (filterPresent l s0) s0)).
			{ repeat rewrite length_app.
				intro Hnew.
				assert(Hreassoc : length
						(getAllPaddrBlock (startAddr (blockrange bentry0))
							 (endAddr (blockrange bentry0))) +
					(length (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b))) +
					 length (getAllPaddrAux (filterPresent l s0) s0)) = 
					(length (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))) +
					length
						(getAllPaddrBlock (startAddr (blockrange bentry0))
							 (endAddr (blockrange bentry0))) +
					 length (getAllPaddrAux (filterPresent l s0) s0)).
				{
					rewrite Nat.add_shuffle3. apply Nat.add_assoc.
				}
				rewrite Hnew.
				rewrite Hreassoc.
				apply Nat.add_assoc.
		}
		apply HNewGoal. clear HNewGoal.
		repeat rewrite length_app. f_equal.
		rewrite <- length_app.
		apply IHl ; intuition.
Qed.

(* DUP *)
Lemma getMappedPaddrEqBEPresentNoChangeStartNoChangeEndNoChangeEquivalence partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq.
intros HStartEq HendEq.
unfold getMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENoChange with bentry0; intuition.
	}
	rewrite HEq.
	eapply getAllPaddrAuxEqBEStartNoChangeEndNoChange with bentry0; intuition.
Qed.



(* DUP *)
Lemma getMappedPaddrEqBENotInPart partition addr' newEntry s0:
isBE addr' s0 ->
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HBEs0 HNotIn.
unfold getMappedPaddr.
unfold s'. simpl.

assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqBENotInPart  ; intuition.
	}
fold s'.
rewrite HEq.
apply getAllPaddrAuxEqBENoInList ; intuition.
unfold getMappedBlocks in *.
eapply NotInListNotInFilterPresent with addr' (filterOptionPaddr (getKSEntries partition s0)) s0 in HNotIn ; intuition.
Qed.

(* DUP *)
Lemma getMappedPaddrEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSCEs0.
unfold getMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSCE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSCE in *.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqSCE  ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqSCE ; intuition.
Qed.

(* DUP *)
Lemma getMappedPaddrEqSHE partition addr' newEntry s0:
isPDT partition s0 ->
isSHE addr' s0 ->
getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0.
unfold getMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSHE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSHE in *.
	fold s'.
	assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
	{ eapply getMappedBlocksEqSHE  ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqSHE ; intuition.
Qed.


Lemma getAccessibleMappedPaddrEqPDTNotInPart partition addr' newEntry s0:
isPDT addr' s0 ->
partition <> addr' ->
StructurePointerIsKS s0 ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookupaddr's0 HpartNotEq HstructEq.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqPDTNotInPart  ; intuition.
	}
fold s'.
rewrite HEq.
apply getAllPaddrAuxEqPDT ; intuition.
Qed.

(* DUP *)
Lemma getAccessibleMappedPaddrEqBENotInPart partition addr' newEntry s0:
isPDT partition s0 ->
isBE addr' s0 ->
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HBEs0 HNotIn.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqBENotInPart  ; intuition.
	}
fold s'.
rewrite HEq.
apply getAllPaddrAuxEqBENoInList ; intuition.

assert(Haddr'NotMapped : ~In addr' (getMappedBlocks partition s0)).
{
	unfold getMappedBlocks.
	induction (filterOptionPaddr (getKSEntries partition s0)).
	- intuition.
	- simpl.
		destruct (beqAddr addr' a) eqn:beqaddr'a ; try(exfalso ; congruence).
		-- (* addr' = a *)
			rewrite <- DTL.beqAddrTrue in beqaddr'a.
			subst a. exfalso. apply HNotIn. simpl. left. reflexivity.
		-- (* addr' <> a*)
			rewrite <- beqAddrFalse in *.
			destruct (lookup a (memory s0) beqAddr); try(apply IHl; intro Hcontra; apply HNotIn; simpl; right;
        assumption).
			destruct v; try(apply IHl; intro Hcontra; apply HNotIn; simpl; right; assumption).
			destruct (present b) ; try(apply IHl; intro Hcontra; apply HNotIn; simpl; right; assumption).
			simpl in *. intuition.
}
unfold getAccessibleMappedBlocks in *.

apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pdentrys0 Hlookuppds0].
rewrite Hlookuppds0 in *.

eapply NotInListNotInFilterAccessible with addr' (getMappedBlocks partition s0) s0 in Haddr'NotMapped ; intuition.
Qed.


(* DUP *)
Lemma getAccessibleMappedPaddrEqPDT partition addr' newEntry pdentry0 s0:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
(structure newEntry) = (structure pdentry0) ->
StructurePointerIsKS s0 ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructEq HKSPtnIsKS.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ unfold getAccessibleMappedBlocks.
		unfold s'. simpl.
		rewrite beqAddrTrue.
		rewrite Hlookuppds0.

		assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
		{ eapply getMappedBlocksEqPDT with pdentry0  ; intuition.
		}
		fold s'.
		rewrite HEq. clear HEq.
		induction (getMappedBlocks partition s0).
		- intuition.
		- simpl in *.
			destruct (beqAddr partition a) eqn:beqparta ; try(exfalso ; congruence) ; intuition.
			-- rewrite <- DTL.beqAddrTrue in beqparta.
				subst a.
				rewrite Hlookuppds0.
				intuition.
			-- rewrite <- beqAddrFalse in *.
					rewrite removeDupIdentity ; intuition.
				destruct (lookup a (memory s0) beqAddr) ; intuition.
					destruct v ; intuition.
					destruct (accessible b) ; intuition.
					f_equal. intuition.
		}
		rewrite HEq.
		assert(HPDTs0 : isPDT partition s0) by (unfold isPDT ; rewrite Hlookuppds0 ; intuition).
		apply getAllPaddrAuxEqPDT ; intuition.

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ unfold getAccessibleMappedBlocks.
		unfold s'. simpl.
		destruct (beqAddr addr' partition) eqn:Hf ; try(exfalso ; congruence) ; intuition.
		rewrite <- DTL.beqAddrTrue in Hf. congruence.
 		rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity ; intuition.
		destruct (lookup partition (memory s0) beqAddr) ; intuition.
		destruct v ; intuition.
		fold s'.

		assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
		{ eapply getMappedBlocksEqPDT with pdentry0  ; intuition.
		}
		rewrite HEq. clear HEq.
		induction (getMappedBlocks partition s0).
		- intuition.
		- simpl in *.
			destruct (beqAddr partition a) eqn:beqparta ; try(exfalso ; congruence) ; intuition.
			-- rewrite <- DTL.beqAddrTrue in beqparta.
				subst a.
				destruct (beqAddr addr' partition) eqn:Hff ; try(exfalso ; congruence) ; intuition.
				rewrite <- DTL.beqAddrTrue in Hff. congruence.
		 		rewrite <- beqAddrFalse in *.
				rewrite removeDupIdentity ; intuition.
				destruct (lookup partition (memory s0) beqAddr) ; intuition.
				destruct v ; intuition.
				destruct (accessible b) ; intuition.
				f_equal. intuition.
			-- destruct (beqAddr addr' a) eqn:beqaddr'a ; try(exfalso ; congruence) ; intuition.
					--- rewrite <- DTL.beqAddrTrue in beqaddr'a.
							subst a.
							rewrite Hlookuppds0.
							intuition.
					--- rewrite <- beqAddrFalse in *.
							rewrite removeDupIdentity ; intuition.
							destruct (lookup a (memory s0) beqAddr) ; intuition.
							destruct v ; intuition.
							destruct (accessible b) ; intuition.
							f_equal. intuition.
		}
		rewrite HEq.
	assert(HPDTs0 : isPDT addr' s0) by (unfold isPDT ; rewrite Hlookuppds0 ; intuition).
	apply getAllPaddrAuxEqPDT ; intuition.
Qed.

(* DUP *)
Lemma getAccessibleMappedPaddrEqBEPresentTrueNoChangeAccessibleTrueChangeEquivalence partition block addr newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) <> (accessible bentry0) ->
(accessible newEntry) = true ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
noDupMappedBlocksList s0 ->
In block (filterOptionPaddr (getKSEntries partition s0)) ->
In addr
(getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) <->
In addr
(getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0))
++ getAccessibleMappedPaddr partition s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq Hpresenttrue HacccessibleNotEq Haccessibletrue HstartEq HendEq.
intros HNoDupMappedBlocks HaddrInKSentriess0.
assert(HPDTs0' : isPDT partition s0) by intuition.
apply isPDTLookupEq in HPDTs0'. destruct HPDTs0' as [pdentry0 Hlookuppds0].

assert(Haddr'NotMapped : ~In block (getAccessibleMappedBlocks partition s0)).
{
	apply BlockAccessibleFalseNotMapped with bentry0; intuition.
	rewrite Haccessibletrue in *.
	apply Bool.not_true_iff_false.
	intuition.
}

assert(Haddr'Mapped : In block (getMappedBlocks partition s0)).
{ unfold getMappedBlocks.
	induction (filterOptionPaddr (getKSEntries partition s0)).
	- intuition.
	- simpl in *. intuition.
		-- (* a = block*)
			subst a.
			rewrite Hlookupaddr's0.
			rewrite <- HpresentEq. rewrite Hpresenttrue. simpl. left. reflexivity.
		-- (* a <> block *)
				destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; intuition.
				destruct v ; intuition.
				destruct (present b) ; simpl; try(assumption). right. assumption.
}

unfold getAccessibleMappedPaddr in *.

assert(Haccessibles0false : accessible bentry0 = false).
{ rewrite Haccessibletrue in *.
	apply Bool.not_true_iff_false.
	intuition.
}

assert(HBEs0 : isBE block s0) by (unfold isBE ; rewrite Hlookupaddr's0 ; trivial).

assert(HpartEq : lookup partition (memory s') beqAddr = lookup partition (memory s0) beqAddr).
{
	unfold s'. simpl.
	destruct (beqAddr block partition) eqn:beqblockpart.
	- rewrite <- DTL.beqAddrTrue in beqblockpart.
		subst block.
		unfold isBE in *. unfold isPDT in *.
		rewrite Hlookuppds0 in *. exfalso ; congruence.
	- rewrite <- beqAddrFalse in *.
		rewrite removeDupIdentity in * ; intuition.
}


assert(HmappedEq : getMappedBlocks partition s' = getMappedBlocks partition s0).
{
	eapply getMappedBlocksEqBENoChange with bentry0; intuition.
}

unfold getAccessibleMappedBlocks in *.
rewrite HpartEq in *.
specialize (HNoDupMappedBlocks partition HPDTs0).

rewrite Hlookuppds0 in *.

assert(HNoDupMappeds : NoDup (getMappedBlocks partition s')).
{ rewrite HmappedEq. intuition. }
rewrite HmappedEq in *.
clear HmappedEq.

induction (getMappedBlocks partition s0).
- intuition.
-
	assert(Haddrs0 : (getAllPaddrAux (filterPresent l s0) s') =  (getAllPaddrAux (filterPresent l s0) s0)).
	{
		eapply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
	}


	simpl in *.
	destruct (beqAddr block a) eqn:beqaddr'a ; try(exfalso ; congruence).
	-- (* block = a *)
		rewrite <- DTL.beqAddrTrue in beqaddr'a.
		subst a.
		rewrite Haccessibletrue in *.
		rewrite Hlookupaddr's0 in *.
		rewrite Haccessibles0false in *.
		simpl in *. rewrite beqAddrTrue in *.
		rewrite HstartEq in*. rewrite HendEq in *.
 		apply NoDup_cons_iff in HNoDupMappeds.

		apply NoDup_cons_iff in HNoDupMappedBlocks.

		assert(HlFilterNoChange : filterAccessible l s' = filterAccessible l s0).
		{
			eapply filterAccessibleEqBENotInListNoChange ; intuition.
		} (* cause block is not in l so remaining didn't change *)
		rewrite HlFilterNoChange in *.

		rewrite in_app_iff.

		assert(HgetAllEq : getAllPaddrAux (filterAccessible l s0) s' = getAllPaddrAux (filterAccessible l s0) s0).
		{ clear IHl.
			eapply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
		}
		rewrite HgetAllEq. destruct HNoDupMappedBlocks as (HblockNotIn & HNoDupMappedBlocks). clear Haddr'Mapped.
    clear IHl. split; intro Hhyp.
    + apply in_or_app. assumption.
    + apply in_app_or in Hhyp. assumption.
	-- (* block <> a *)
			rewrite <- beqAddrFalse in *.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			apply NoDup_cons_iff in HNoDupMappeds. destruct HNoDupMappeds as (HaNotIn & HNoDupMappeds).
      destruct Haddr'Mapped as [Hcontra | Haddr'Mapped]; try(exfalso; congruence).
			destruct (lookup a (memory s0) beqAddr) eqn:Hlookupas0 ; try (apply IHl; try(assumption)).
			destruct v ; try (apply IHl ; try(assumption)).
			destruct (accessible b) ; try (apply IHl ; intuition).
			simpl in *.
			destruct (beqAddr block a) eqn:Hf ; try (exfalso ; congruence).
			rewrite <- DTL.beqAddrTrue in Hf. congruence.
			rewrite removeDupIdentity in * ; try apply not_eq_sym ; trivial.
			rewrite Hlookupas0 in *.
			rewrite in_app_iff. rewrite in_app_iff.

			assert(HInEq : In addr (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))
					\/
  In addr (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrAux (filterAccessible l s0) s0) ->
In addr
  (getAllPaddrBlock (startAddr (blockrange bentry0)) (endAddr (blockrange bentry0)) ++
   getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)) ++
   getAllPaddrAux (filterAccessible l s0) s0)).
			{
				intros HaddrIn.
				apply in_app_iff. rewrite in_app_iff.
				intuition.
				rewrite in_app_iff in H. (*getAllPaddrBlock bentry0 ++ getAllPaddr*)
				intuition.
			}
			apply NoDup_cons_iff in HNoDupMappedBlocks.
			simpl in *. apply not_or_and in Haddr'NotMapped. destruct Haddr'NotMapped as (HaNotBlock & Haddr'NotMapped).
      split; intro Hhyp.
      + apply in_app_or. apply HInEq. destruct Hhyp as [Hblock | Hs']; try(left; assumption). right.
        apply IHl; assumption.
      + specialize(IHl HNoDupMappeds Haddr'NotMapped Haddr'Mapped HNoDupMappeds).
        destruct Hhyp as [Hright | Hhyp]; try(right; apply <-IHl; try(assumption); apply in_or_app; left;
          assumption). apply in_app_or in Hhyp. destruct Hhyp as [Hleft | Hright]; try(left; assumption).
        right. apply IHl. apply in_or_app. right. assumption.
      + intro beqblockpart. rewrite beqblockpart in *.
			  destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
Qed.

Lemma presentIsInFilterPresent addr bentry addrList s:
lookup addr (memory s) beqAddr = Some(BE bentry)
-> present bentry = true
-> In addr addrList
-> In addr (filterPresent addrList s).
Proof.
intros Hlookup Hpresent HinList. induction addrList.
- (* addrList = [] *)
  simpl in HinList. exfalso; congruence.
- (* addrList = a::l *)
  simpl in HinList. destruct HinList as [HaIsAddr | Hrec].
  + (* a = addr *)
    subst a. simpl. rewrite Hlookup. rewrite Hpresent. simpl. left. reflexivity.
  + (* In addr addrList *)
    simpl. destruct (lookup a (memory s) beqAddr); try(apply IHaddrList; assumption).
    destruct v; try(apply IHaddrList; assumption).
    destruct (present b); try(apply IHaddrList; assumption).
    simpl. right. apply IHaddrList. assumption.
Qed.

Lemma accessibleIsInFilterAccessible addr bentry addrList s:
lookup addr (memory s) beqAddr = Some(BE bentry)
-> accessible bentry = true
-> In addr addrList
-> In addr (filterAccessible addrList s).
Proof.
intros Hlookup Haccess HinList. induction addrList.
- (* addrList = [] *)
  simpl in HinList. exfalso; congruence.
- (* addrList = a::l *)
  simpl in HinList. destruct HinList as [HaIsAddr | Hrec].
  + (* a = addr *)
    subst a. simpl. rewrite Hlookup. rewrite Haccess. simpl. left. reflexivity.
  + (* In addr addrList *)
    simpl. destruct (lookup a (memory s) beqAddr); try(apply IHaddrList; assumption).
    destruct v; try(apply IHaddrList; assumption).
    destruct (accessible b); try(apply IHaddrList; assumption).
    simpl. right. apply IHaddrList. assumption.
Qed.


(* DUP *)
Lemma getAccessibleMappedBlocksEqBEPresentTrueNoChangeAccessibleFalseChangeInclusion partition block addr
newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) <> (accessible bentry0) ->
(accessible newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
addr <> block ->
In block (getAccessibleMappedBlocks partition s0) ->
In block
(getAccessibleMappedBlocks partition {|
						currentPartition := currentPartition s0;
						memory := add addr (BE newEntry)
            (memory s0) beqAddr |}).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq Hpresenttrue HaccessibleNotEq HaccessibleFalse HstartEq
HendEq HblockAddrNotEq HblockInMappedBlockss0.
assert(HPDTs0' : isPDT partition s0) by intuition.
apply isPDTLookupEq in HPDTs0'. destruct HPDTs0' as [pdentry0 Hlookuppds0].

assert(HgetMappedEq: getMappedBlocks partition s' = getMappedBlocks partition s0).
{
  subst s'. apply getMappedBlocksEqBENoChange with bentry0; assumption.
}

unfold getAccessibleMappedBlocks in HblockInMappedBlockss0. unfold getAccessibleMappedBlocks.
subst s'. simpl.
destruct (beqAddr addr partition) eqn:HbeqAddrPart.
{
  rewrite <-DTL.beqAddrTrue in HbeqAddrPart. subst addr. rewrite Hlookuppds0 in Hlookupaddr's0.
  exfalso; congruence.
}
rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; try(intuition; congruence).
rewrite Hlookuppds0. rewrite HgetMappedEq. rewrite Hlookuppds0 in HblockInMappedBlockss0.
clear HgetMappedEq. induction (getMappedBlocks partition s0).
- (* getMappedBlocks partition s0 = [] *)
  simpl in HblockInMappedBlockss0. exfalso; congruence.
- (* getMappedBlocks partition s0 = a::l *)
  simpl in HblockInMappedBlockss0. simpl. destruct (beqAddr addr a) eqn:HbeqAddrA.
  + (* addr = a *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. subst a.
    rewrite Hlookupaddr's0 in HblockInMappedBlockss0. rewrite HaccessibleFalse in HaccessibleNotEq.
    apply not_eq_sym in HaccessibleNotEq. apply Bool.not_false_is_true in HaccessibleNotEq.
    rewrite HaccessibleNotEq in HblockInMappedBlockss0. simpl in HblockInMappedBlockss0.
    destruct HblockInMappedBlockss0 as [Hcontra | HblockInMappedBlockss0]; try(exfalso; congruence).
    rewrite HaccessibleFalse. specialize(IHl HblockInMappedBlockss0). assumption.
  + (* block <> a *)
    rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity; try(intuition; congruence).
    destruct (lookup a (memory s0) beqAddr) eqn:HlookupA; try(specialize(IHl HblockInMappedBlockss0); assumption).
    destruct v; try(specialize(IHl HblockInMappedBlockss0); assumption).
    destruct (accessible b); try(specialize(IHl HblockInMappedBlockss0); assumption).
    simpl in HblockInMappedBlockss0. simpl.
    destruct HblockInMappedBlockss0 as [HaddrInFirst | Hrec].
    * left. assumption.
    * right. apply IHl. assumption.
Qed.


(* DUP *)
Lemma getAccessibleMappedPaddrEqBEPresentTrueNoChangeAccessibleFalseInclusion partition block addr
newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
In addr
(getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) ->
In addr (getAccessibleMappedPaddr partition s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq Hpresenttrue HaccessibleFalse HstartEq
HendEq.
assert(HPDTs0' : isPDT partition s0) by intuition.
apply isPDTLookupEq in HPDTs0'. destruct HPDTs0' as [pdentry0 Hlookuppds0].

assert(Haddr'NotMapped : ~In block (getAccessibleMappedBlocks partition s')).
{
	apply BlockAccessibleFalseNotMapped with newEntry; intuition. subst s'. simpl. rewrite beqAddrTrue.
  reflexivity.
}

assert(HgetMappedEq: getMappedBlocks partition s' = getMappedBlocks partition s0).
{
  subst s'. apply getMappedBlocksEqBENoChange with bentry0; assumption.
}

intro HaddrMappeds'.
unfold getAccessibleMappedPaddr in HaddrMappeds'. unfold getAccessibleMappedBlocks in HaddrMappeds'.
subst s'. simpl in HaddrMappeds'.
destruct (beqAddr block partition) eqn:HbeqBlockPart; try(simpl in HaddrMappeds'; exfalso; congruence).
rewrite <-beqAddrFalse in HbeqBlockPart. rewrite removeDupIdentity in HaddrMappeds'; try(intuition; congruence).
rewrite Hlookuppds0 in HaddrMappeds'. rewrite HgetMappedEq in HaddrMappeds'.

unfold getAccessibleMappedBlocks in Haddr'NotMapped. simpl in Haddr'NotMapped.
rewrite beqAddrFalse in HbeqBlockPart. rewrite HbeqBlockPart in Haddr'NotMapped.
rewrite <-beqAddrFalse in HbeqBlockPart. rewrite removeDupIdentity in Haddr'NotMapped; try(intuition; congruence).
rewrite Hlookuppds0 in Haddr'NotMapped.

unfold getAccessibleMappedPaddr. unfold getAccessibleMappedBlocks. rewrite Hlookuppds0.
clear HgetMappedEq. induction (getMappedBlocks partition s0).
- (* getMappedBlocks partition s0 = [] *)
  simpl in HaddrMappeds'. exfalso; congruence.
- (* getMappedBlocks partition s0 = a::l *)
  simpl in HaddrMappeds'. destruct (beqAddr block a) eqn:HbeqBlockA.
  + (* block = a *)
    rewrite HaccessibleFalse in HaddrMappeds'. specialize(IHl HaddrMappeds'). simpl.
    rewrite <-DTL.beqAddrTrue in HbeqBlockA. subst a. rewrite Hlookupaddr's0.
    destruct (accessible bentry0).
    * simpl. rewrite Hlookupaddr's0. apply in_or_app. right. assumption.
    * assumption.
  + (* block <> a *)
    rewrite <-beqAddrFalse in HbeqBlockA. rewrite removeDupIdentity in HaddrMappeds'; try(intuition; congruence).
    simpl. destruct (lookup a (memory s0) beqAddr) eqn:HlookupA; try(specialize(IHl HaddrMappeds'); assumption).
    destruct v; try(specialize(IHl HaddrMappeds'); assumption).
    destruct (accessible b); try(specialize(IHl HaddrMappeds'); assumption). simpl in HaddrMappeds'. simpl.
    rewrite beqAddrFalse in HbeqBlockA. rewrite HbeqBlockA in HaddrMappeds'.
    rewrite <-beqAddrFalse in HbeqBlockA. rewrite removeDupIdentity in HaddrMappeds'; try(intuition; congruence).
    rewrite HlookupA in *. apply in_or_app. apply in_app_or in HaddrMappeds'.
    destruct HaddrMappeds' as [HaddrInFirst | Hrec].
    * left. assumption.
    * right. apply IHl. assumption.
Qed.


(* DUP *)
Lemma getAccessibleMappedPaddrEqBEPresentTrueNoChangeAccessibleFalseChangeInclusionRev partition block addr
newEntry bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) <> (accessible bentry0) ->
(accessible newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
In block (filterOptionPaddr (getKSEntries partition s0)) ->
In addr (getAccessibleMappedPaddr partition s0) ->
In addr
(getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |})
\/ In addr (getAllPaddrBlock (startAddr (blockrange newEntry)) (endAddr (blockrange newEntry))).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HlookupBlocks0 HpresentEq HpresentTrue HaccessibleNotEq HaccessibleFalse HstartEq HendEq
HblockInKSentriess0.
assert(HPDTs0Copy: isPDT partition s0) by intuition.
apply isPDTLookupEq in HPDTs0Copy. destruct HPDTs0Copy as [pdentry0 HlookupPds0].

assert(HblockNotMapped : ~In block (getAccessibleMappedBlocks partition s')).
{
	apply BlockAccessibleFalseNotMapped with newEntry; intuition. subst s'. simpl. rewrite beqAddrTrue.
  reflexivity.
}

assert(HgetMappedEq: getMappedBlocks partition s' = getMappedBlocks partition s0).
{
  subst s'. apply getMappedBlocksEqBENoChange with bentry0; assumption.
}

intro HaddrMappeds0.
unfold getAccessibleMappedPaddr. unfold getAccessibleMappedBlocks.
subst s'. simpl.
destruct (beqAddr block partition) eqn:HbeqBlockPart.
{
  rewrite <-DTL.beqAddrTrue in HbeqBlockPart. subst block. rewrite HlookupPds0 in HlookupBlocks0.
  exfalso; congruence.
}
rewrite <-beqAddrFalse in HbeqBlockPart. rewrite removeDupIdentity; try(intuition; congruence).
rewrite HlookupPds0. rewrite HgetMappedEq.

unfold getAccessibleMappedBlocks in HblockNotMapped. simpl in HblockNotMapped.
rewrite beqAddrFalse in HbeqBlockPart. rewrite HbeqBlockPart in HblockNotMapped.
rewrite <-beqAddrFalse in HbeqBlockPart. rewrite removeDupIdentity in HblockNotMapped; try(intuition; congruence).
rewrite HlookupPds0 in HblockNotMapped. rewrite HgetMappedEq in HblockNotMapped.

assert(HaccessibleTrues0: accessible bentry0 = true).
{
  rewrite HaccessibleFalse in HaccessibleNotEq. apply not_eq_sym in HaccessibleNotEq.
  apply Bool.not_false_is_true in HaccessibleNotEq. assumption.
}

unfold getAccessibleMappedPaddr in HaddrMappeds0. unfold getAccessibleMappedBlocks in HaddrMappeds0.
rewrite HlookupPds0 in HaddrMappeds0. clear HgetMappedEq.
induction (getMappedBlocks partition s0).
- (* getMappedBlocks partition s0 = [] *)
  simpl in HaddrMappeds0. exfalso; congruence.
- (* getMappedBlocks partition s0 = a::l *)
  simpl in *. destruct (beqAddr block a) eqn:HbeqBlockA.
  + (* block = a *)
    rewrite <-DTL.beqAddrTrue in HbeqBlockA. subst a. rewrite HlookupBlocks0 in HaddrMappeds0.
    rewrite HaccessibleTrues0 in HaddrMappeds0. simpl in HaddrMappeds0. rewrite HlookupBlocks0 in HaddrMappeds0.
    apply in_app_or in HaddrMappeds0. destruct HaddrMappeds0 as [Hright | HaddrMappeds0].
    * right. rewrite HstartEq. rewrite HendEq. assumption.
    * rewrite HaccessibleFalse in *. specialize(IHl HblockNotMapped HaddrMappeds0). assumption.
  + (* block <> a *)
    rewrite <-beqAddrFalse in HbeqBlockA. rewrite removeDupIdentity; try(intuition; congruence).
    rewrite removeDupIdentity in HblockNotMapped; try(intuition; congruence).
    destruct (lookup a (memory s0) beqAddr) eqn:HlookupA; try(specialize(IHl HblockNotMapped HaddrMappeds0);
          assumption).
    destruct v; try(specialize(IHl HblockNotMapped HaddrMappeds0); assumption).
    destruct (accessible b); try(specialize(IHl HblockNotMapped HaddrMappeds0); assumption).
    simpl in HaddrMappeds0. simpl. rewrite beqAddrFalse in HbeqBlockA. rewrite HbeqBlockA.
    rewrite <-beqAddrFalse in HbeqBlockA. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupA in *. apply in_app_or in HaddrMappeds0. destruct HaddrMappeds0 as [HaddrInFirst | Hrec].
    * left. apply in_or_app. left. assumption.
    * simpl in HblockNotMapped. apply not_or_and in HblockNotMapped.
      destruct HblockNotMapped as [HaNotBlock HblockNotMapped]. specialize(IHl HblockNotMapped Hrec).
      destruct IHl as [HaddrMappeds | HaddrInBlock].
      { left. apply in_or_app. right. assumption. }
      right. assumption.
Qed.

(* DUP *)
Lemma getAccessibleMappedPaddrEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentEq HpresentFalse.
intros HStartEq HendEq.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqBEPresentFalseNoChange with bentry0 ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
Qed.

Lemma getAccessibleMappedPaddrEqBEPresentAccessibleNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(accessible newEntry) = (accessible bentry0) ->
(present newEntry) = (present bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HaccessibleEq HpresentEq HstartEq HendEq.
unfold getAccessibleMappedPaddr.

assert(HgetAccessibleEq : getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
{	eapply getAccessibleMappedBlocksEqBEAccessiblePresentNoChange with bentry0; intuition. }
rewrite HgetAccessibleEq.

apply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
Qed.

(* DUP *)
Lemma getAccessibleMappedPaddrEqBEPresentTrueChangeAccessibleFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) <> (present bentry0) ->
(present newEntry) = true ->
(accessible newEntry) = (accessible bentry0) ->
(accessible newEntry) = false ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = (endAddr (blockrange bentry0)) ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HpresentNotEq HpresentTrue HaccessibleEq HaccessibleFalse.
intros HStartEq HendEq.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	fold s'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqBEPresentChangeAccessibleFalse with bentry0 ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqBEStartEndNoChange with bentry0 ; intuition.
Qed.


(* DUP *)
Lemma getAccessibleMappedPaddrEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSCEs0.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSCE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSCE in *.
	fold s'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqSCE  ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqSCE ; intuition.
Qed.

(* DUP *)
Lemma getAccessibleMappedPaddrEqSHE partition addr' newEntry s0:
isPDT partition s0 ->
isSHE addr' s0 ->
getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0.
unfold getAccessibleMappedPaddr.
unfold s'. simpl.

destruct (beqAddr addr' partition) eqn:beqpartaddr ; try(exfalso ; congruence).
- (* addr' = partition *)
	rewrite <- DTL.beqAddrTrue in beqpartaddr.
	fold s'.
	subst addr'.
	unfold isSHE in *. unfold isPDT in *.
	destruct (lookup partition (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
	destruct v ; try(exfalso ; congruence).

- (* addr' <> partition *)
	rewrite <- beqAddrFalse in *.
	repeat rewrite removeDupIdentity ; intuition.
	unfold isSHE in *.
	fold s'.
	assert(HEq :  getAccessibleMappedBlocks partition s' = getAccessibleMappedBlocks partition s0).
	{ eapply getAccessibleMappedBlocksEqSHE  ; intuition.
	}
	rewrite HEq.
	apply getAllPaddrAuxEqSHE ; intuition.
Qed.



Definition getAllPaddr: list paddr:=
map CPaddr (seq 0 (maxAddr+1) ).

Lemma PaddrListBoundedLength :
forall l:list paddr,
NoDup l ->
length(l) <= maxAddr+1.
Proof.
intros.

assert(AllPaddrAll : forall p : paddr, In p getAllPaddr).
{

intros.
unfold getAllPaddr.
apply in_map_iff.
exists p.
split.
unfold CPaddr.
case_eq (le_dec p maxAddr); intros.
destruct p.
simpl in *.
f_equal.
apply proof_irrelevance.
destruct p.
simpl in *. lia.
apply in_seq.
simpl.
assert (0 < maxAddr). apply maxAddrNotZero.
destruct p.
simpl.
lia.
}

intros.
assert (forall p : paddr, In p getAllPaddr) by apply AllPaddrAll.
assert (length getAllPaddr <= maxAddr+1).
unfold getAllPaddr.
rewrite length_map.
rewrite length_seq. trivial.
apply NoDup_incl_length with paddr l getAllPaddr in H.
lia.
unfold incl.
intros.
apply AllPaddrAll.
Qed.

Lemma lengthNoDupPartitions :
forall listPartitions : list paddr, NoDup listPartitions ->
length listPartitions <= maxAddr + 1.
Proof.
apply PaddrListBoundedLength ; intuition.
Qed.


(*
Lemma nextEntryIsPPgetParent partition pd s :
nextEntryIsPP partition PPRidx pd s <->
StateLib.getParent partition (memory s) = Some pd.
Proof.
split.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getParent in *.
destruct(StateLib.Index.succ PPRidx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
intros.
unfold nextEntryIsPP in *.
unfold  StateLib.getParent in *.
destruct(StateLib.Index.succ PPRidx); [| now contradict H].
unfold  StateLib.readPhysical in *.
destruct (lookup partition i (memory s) beqPage beqIndex); [| now contradict H].
destruct v ; try now contradict H.
inversion H; subst; trivial.
Qed.
*)


Lemma nbPartition s:
noDupPartitionTree s ->
length (getPartitions multiplexer s) <= (maxAddr+1).
Proof.
intros.
apply lengthNoDupPartitions.
trivial.
Qed.


Lemma childrenPartitionInPartitionList s phyVA parent:
noDupPartitionTree s ->
In parent (getPartitions multiplexer s ) ->
In phyVA (getChildren parent s) ->
In phyVA (getPartitions multiplexer s).
Proof.
intro Hnodup.
unfold getPartitions .
assert
(HH : length (getPartitions multiplexer s) <= (maxAddr+1)).
apply nbPartition;trivial.
assert
(length (getPartitions multiplexer s) < (maxAddr+2)).
lia. clear HH.
unfold getPartitions in H.
revert H.
generalize multiplexer.
induction (maxAddr+2); simpl.
+ intros. now contradict H.
+ intros.
  simpl in *.
  destruct H0.
  - rewrite H0 in *.
    clear H0.
    right.
    induction ((getChildren parent s)).
    * simpl. auto.
    * simpl in *.
      apply in_app_iff.
      destruct H1.
      subst.
      left.
      destruct n. simpl in *. lia.
      left. trivial.
      right. apply IHl.
      intros.
      apply IHn.
      lia.
      assumption.
      right.
      assumption.
      rewrite length_app in H.
      lia.
      assumption.
  - right.
    induction (getChildren p s); simpl in *.
    * now contradict H.
    * simpl in *.
      apply in_app_iff in H0.
      apply in_app_iff .
      destruct H0.
      left.
      apply IHn ; trivial.
      rewrite length_app in H.
      lia.
      right.
      apply IHl; trivial.
      assert(Hres: length (flat_map (fun p0 : paddr => getPartitionsAux n p0 s) l) < n).
      {
        apply <-Nat.succ_lt_mono in H.
        rewrite length_app in H.
        lia.
      }
      apply Nat.succ_lt_mono in Hres. assumption.
Qed.

Lemma childrenArePDT partition child s :
PDTIfPDFlag s ->
In child (getChildren partition s) ->
isPDT child s.
Proof.
intros HPDTIfPDFlag Hchild.
unfold getChildren in *.
destruct (lookup partition (memory s) beqAddr) eqn:Hparts ; try(simpl in * ; exfalso ; congruence).
destruct v ; try (simpl in * ; exfalso ; congruence).

induction (getMappedBlocks partition s).
- simpl in *.
	exfalso ; congruence.
- simpl in *.
	unfold getPDs in *.
	simpl in *.
	destruct (childFilter s a) eqn:Hcheck ; intuition.
	simpl in *.
	intuition.

	unfold childFilter in Hcheck.
	destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; try(exfalso ; congruence).
	destruct v eqn:Hv ; try(exfalso ; congruence).
	destruct (Paddr.addPaddrIdx a sh1offset) eqn:Hsh1offset ; try(exfalso; congruence).
	destruct (lookup p0 (memory s) beqAddr) eqn:Hlookupp0 ; try(exfalso ; congruence).
	destruct v0 eqn:Hv0 ; try(exfalso; congruence).

	unfold PDTIfPDFlag in *.
	specialize (HPDTIfPDFlag a p0).
	destruct HPDTIfPDFlag.
	-- 	unfold checkChild. unfold sh1entryAddr.
			rewrite Hlookupa. rewrite Hlookupp0.
			intuition.
			unfold Paddr.addPaddrIdx in *. unfold CPaddr.
			destruct (le_dec (a + sh1offset) maxAddr) eqn:Hle ; try(exfalso ; congruence).
			inversion Hsh1offset as [Hsh1offsetEq].
			f_equal.
	-- 	destruct H1. destruct H2 as [astartaddr (HastartAddr & HPDT)].
			unfold bentryStartAddr in *. 	unfold entryPDT in *.
			rewrite Hlookupa in *.
			subst astartaddr. subst child.
			unfold isPDT.
			destruct (lookup (startAddr (blockrange b)) (memory s) beqAddr) eqn:HstartPDT ; try(exfalso ; congruence).
			destruct v1 ; try(exfalso ; congruence).
			trivial.
Qed.

Lemma childrenArePDTAndChild parent child s :
PDTIfPDFlag s ->
In child (getChildren parent s) ->
exists bentryaddr sh1entryaddr,
isPDT child s /\
In bentryaddr (getMappedBlocks parent s) /\
true = StateLib.checkChild bentryaddr s sh1entryaddr /\
sh1entryAddr bentryaddr sh1entryaddr s.
Proof.
intros HPDTIfPDFlag Hchild.
unfold getChildren in *.
destruct (lookup parent (memory s) beqAddr) eqn:Hparts ; try(simpl in * ; exfalso ; congruence).
destruct v ; try (simpl in * ; exfalso ; congruence).

induction (getMappedBlocks parent s).
- simpl in *.
	exfalso ; congruence.
- simpl in *.
	unfold getPDs in *.
	simpl in *.
	destruct (childFilter s a) eqn:Hcheck ; intuition.

	simpl in *.
	intuition.

	unfold childFilter in Hcheck.
	destruct (lookup a (memory s) beqAddr) eqn:Hlookupa ; try(exfalso ; congruence).
	destruct v eqn:Hv ; try(exfalso ; congruence).
	destruct (Paddr.addPaddrIdx a sh1offset) eqn:Hsh1offset ; try(exfalso; congruence).
	destruct (lookup p0 (memory s) beqAddr) eqn:Hlookupp0 ; try(exfalso ; congruence).
	destruct v0 eqn:Hv0 ; try(exfalso; congruence).

	unfold PDTIfPDFlag in *.
	specialize (HPDTIfPDFlag a p0).
	destruct HPDTIfPDFlag.
	--- 	unfold checkChild. unfold sh1entryAddr.
			rewrite Hlookupa. rewrite Hlookupp0.
			intuition.
			unfold Paddr.addPaddrIdx in *. unfold CPaddr.
			destruct (le_dec (a + sh1offset) maxAddr) eqn:Hle ; try(exfalso ; congruence).
			inversion Hsh1offset as [Hsh1offsetEq].
			f_equal.
	--- 	destruct H1. destruct H2 as [astartaddr (HastartAddr & HPDT)].
			unfold bentryStartAddr in *. 	unfold entryPDT in *.

			rewrite Hlookupa in *.
			subst astartaddr. subst child.
			unfold isPDT.
			destruct (lookup (startAddr (blockrange b)) (memory s) beqAddr) eqn:HstartPDT ; try(exfalso ; congruence).
			destruct v1 ; try(exfalso ; congruence).
			eexists. eexists.
			split. trivial.
			split. left.
			intuition.
			unfold checkChild. unfold sh1entryAddr.
			rewrite Hlookupa. rewrite Hlookupp0.
			intuition.
			unfold Paddr.addPaddrIdx in *. unfold CPaddr.
			destruct (le_dec (a + sh1offset) maxAddr) eqn:Hle ; try(exfalso ; congruence).
			inversion Hsh1offset as [Hsh1offsetEq].
			f_equal.

	--- destruct H0 as [bentryaddr (sh1entryaddr & Hchild)].
			exists bentryaddr. exists sh1entryaddr.
			intuition.
---
		destruct H as [bentryaddr (sh1entryaddr & Hchild')].
			exists bentryaddr. exists sh1entryaddr.
			intuition.
Qed.

Lemma partitionsArePDT partition s :
(*NoDup (getPartitions root s) ->*)
PDTIfPDFlag s ->
multiplexerIsPDT s ->
In partition (getPartitions multiplexer s) ->
isPDT partition s.
Proof.
intros HPDTIfPDFlag HmultiIsPDT HpartInRoot.

unfold getPartitions in *.
assert(Hnext' : maxAddr+2 = S (maxAddr+1)).
{ lia. }
rewrite Hnext' in *. clear Hnext'.
assert(Hnext' : maxAddr+1 = S maxAddr).
{ lia. }
simpl in *.

intuition.
{ unfold multiplexerIsPDT in *.
	subst partition. assumption.
}
unfold multiplexerIsPDT in *.
clear HmultiIsPDT.

generalize dependent multiplexer.

rewrite Hnext'. clear Hnext'.

induction (S maxAddr).
- intros.
	unfold getPartitionsAux in *. intuition.
		induction (getChildren p s).
  + simpl in *. exfalso; congruence.
  + apply IHl. intuition.
- intros root HpartInRoot.
	simpl in *.

	assert(HchildPDT : In partition (getChildren root s) -> isPDT partition s).
	{ intros.
		apply childrenArePDT with root ; intuition.
	}
	induction (getChildren root s) ; intuition.
	simpl in *.
	intuition.
	apply in_app_or in H ; intuition.
	apply IHn with a ; intuition.
Qed.


Lemma currentPartIsPDT s:
currentPartitionInPartitionsList s ->
PDTIfPDFlag s ->
multiplexerIsPDT s ->
isPDT (currentPartition s) s.
Proof.
intros.
unfold currentPartitionInPartitionsList in *.
eapply partitionsArePDT ; intuition.
Qed.

Lemma getPartitionsAuxSbound s bound :
forall partition1 partition2, In partition1 (getPartitionsAux bound partition2 s) ->
In partition1 (getPartitionsAux (bound+1) partition2 s).
Proof.
induction bound;simpl; intros.
now contradict H.
destruct H.
left ;trivial.
right.
rewrite in_flat_map in *.
destruct H as (x & Hx & Hxx).
exists x;split;trivial.
apply IHbound;trivial.
Qed.



Lemma childparentNotEq parent child s:
noDupPartitionTree s ->
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
parent <> child.
Proof.
intros HNoDupPartTree.
unfold noDupPartitionTree in *.
generalize dependent multiplexer.
intros root HNoDupPartTree HparentTree Hchild.
intro Hf. subst parent.
rename child into partition.

assert(length (getPartitions root s) <= maxAddr + 1).
{
	apply PaddrListBoundedLength ; intuition.
}


unfold getPartitions in *.

generalize dependent root.

assert(Hnext' : maxAddr+2 = S (maxAddr+1)).
{ lia. }

rewrite Hnext' in *. simpl in *. (*clear Hnext.*)

generalize dependent partition.
clear Hnext'.
induction (maxAddr+1).
- lia.

- simpl in *.
	intuition.
	-- subst root.
			induction (getChildren partition s).
			---  intuition.
			--- simpl in *.
					intuition.
					---- 	subst a.
								unfold getPartitions in *.
								apply NoDup_cons_iff in HNoDupPartTree. destruct HNoDupPartTree as (Hcontra & _).
                simpl in Hcontra. contradict Hcontra. left. reflexivity.
					---- 	apply H1.
								assert((length
												 (flat_map
														(fun p : paddr =>
														 p :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s) (getChildren p s))
														l)) <=
												(length
													 (flat_map (fun p : paddr => getPartitionsAux n p s) (getChildren a s) ++
														flat_map
														  (fun p : paddr =>
														   p
														   :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s)
														        (getChildren p s)) l))).
								{ clear.
									repeat rewrite length_app. lia.
								} lia.
									apply NoDup_cons_iff in HNoDupPartTree.
									apply NoDup_cons_iff. destruct HNoDupPartTree as (HpartNotIn & HNoDupPartTree). split.
                  contradict HpartNotIn. simpl. right. apply in_or_app. right. assumption.
                  apply NoDup_cons_iff in HNoDupPartTree. intuition.
									apply Lib.NoDupSplit in H3. intuition.
	-- 	apply NoDup_cons_iff in HNoDupPartTree.
			destruct HNoDupPartTree as [HnotRootInPartTree HNoDupPartTree].
			clear HnotRootInPartTree.
			induction (getChildren root s).
			---  intuition.
			--- simpl in *.
					intuition.
					---- 	intuition.
								----- subst a.
											induction (getChildren partition s).
											------  intuition.
											------ simpl in *.
															intuition.
															------- subst a.
																			simpl in *.
																			destruct n. lia. simpl in *.
																			apply NoDup_cons_iff in HNoDupPartTree.
                                      destruct HNoDupPartTree as (HpartNotIn & HNoDupPartTree). simpl in *.
                                      apply IHl. intuition. intuition. intuition.
															------- intuition.
																				apply H1 ; intuition.
																				assert((length
																								(flat_map (fun p : paddr => getPartitionsAux n p s) l0 ++
																								 flat_map
																									 (fun p : paddr =>
																										p
																										:: flat_map (fun p0 : paddr => getPartitionsAux n p0 s) (getChildren p s))
																									 l)) <=
																									(length
																										 ((getPartitionsAux n a s ++
																											 flat_map (fun p : paddr => getPartitionsAux n p s) l0) ++
																											flat_map
																												(fun p : paddr =>
																												 p
																												 :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s)
																															(getChildren p s)) l))).
																				{ clear.
																					repeat rewrite length_app. lia.
																				}
																				lia.
																				apply NoDup_cons_iff in HNoDupPartTree. intuition.
																				apply NoDup_cons_iff. intuition.
																				intuition. apply H2. simpl. (*right.*)
																				apply in_app_or in H4. apply in_or_app. destruct H4; try(right; assumption).
                                        left. apply in_or_app. right. assumption.
																				assert(((getPartitionsAux n a s ++
																								 flat_map (fun p : paddr => getPartitionsAux n p s) l0) ++
																								flat_map
																									(fun p : paddr =>
																									 p
																									 :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s) (getChildren p s))
																									l) = getPartitionsAux n a s ++
																								 ((flat_map (fun p : paddr => getPartitionsAux n p s) l0) ++
																								flat_map
																									(fun p : paddr =>
																									 p
																									 :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s) (getChildren p s))
																									l)) by (apply eq_sym; apply app_assoc).
																				rewrite H4 in *.
																				apply Lib.NoDupSplit in H3 ; intuition.

					---- 	apply IHl ; intuition.
								apply NoDup_cons_iff in HNoDupPartTree. intuition.
								apply Lib.NoDupSplit in H2. intuition.
								assert((length
												 (flat_map
														(fun p : paddr =>
														 p :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s) (getChildren p s))
														l)) <=
												(length
														 (flat_map (fun p : paddr => getPartitionsAux n p s) (getChildren a s) ++
															flat_map
																(fun p : paddr =>
																 p
																 :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s)
																		  (getChildren p s)) l))).
								{ clear.
									repeat rewrite length_app. lia.
								} lia.
								apply in_app_or in H1 ; intuition.
								exfalso. apply IHn with partition a ; intuition.
								destruct n ; intuition. lia.
								apply NoDup_cons_iff in HNoDupPartTree. intuition.
								apply Lib.NoDupSplit in H2. intuition.
								apply NoDup_cons_iff. split; try(assumption). contradict H1. apply in_or_app. left. assumption.
								assert((length (flat_map (fun p : paddr => getPartitionsAux n p s) (getChildren a s)))
													<=
												(length
												 (flat_map (fun p : paddr => getPartitionsAux n p s) (getChildren a s) ++
												  flat_map
												    (fun p : paddr =>
												     p
												     :: flat_map (fun p0 : paddr => getPartitionsAux n p0 s)
												          (getChildren p s)) l))).
								{ clear.
									repeat rewrite length_app. lia.
								} lia.
Qed.


Lemma getPartitionsAuxEqPDT partition addr' newEntry pdentry0 s0 n:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
structure newEntry = structure pdentry0 ->
StructurePointerIsKS s0 ->
PDTIfPDFlag s0 ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |}  =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros partition Hlookupds0 HstructEq HStructPtnIsKSs0 HPDTIfPDflags0.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqPDT with pdentry0; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- apply IHn ; intuition.
			--- intuition.
Qed.

Lemma getPartitionsEqPDT partition addr' newEntry pdentry0 s0 :
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
(structure newEntry) = (structure pdentry0) ->
StructurePointerIsKS s0 ->
PDTIfPDFlag s0 ->
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Hlookuppds0 HstructEq HstructKSs0 HPDTIfPDflags0.
unfold getPartitions.
assert(HPartitionsEq : (getPartitionsAux (maxAddr + 2) partition s') =
													(getPartitionsAux (maxAddr + 2) partition s0)).
{
	apply getPartitionsAuxEqPDT with pdentry0 ; intuition.
}
rewrite HPartitionsEq.
trivial.

Qed.

Lemma getPartitionsAuxEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0 n :
isPDT partition s0 ->
PDTIfPDFlag s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present bentry0) = false ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqBEPresentFalseNoChange with bentry0; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- apply IHn ; intuition.
			--- intuition.
Qed.

(* DUP *)
(* alternative: use getPartitionsEqBEPDflagFalse if information is known *)
Lemma getPartitionsEqBEPresentFalseNoChange partition addr' newEntry bentry0 s0:
isPDT partition s0 ->
PDTIfPDFlag s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
(present newEntry) = (present bentry0) ->
(present bentry0) = false ->
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HPDTIfPDflags0 Hlookupaddr's0 HpresentEq HpresentFalse.
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqBEPresentFalseNoChange with bentry0; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.


Lemma getPartitionsAuxEqBEPDflagFalse partition addr' newEntry bentry0 sh1entryaddr s0 n :
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
PDTIfPDFlag s0 ->
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
(*noDupKSEntriesList s0 ->*)
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqBEPDflagFalse with bentry0 sh1entryaddr; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- eapply IHn ; intuition.
			--- intuition.
Qed.

Lemma getPartitionsEqBEPDflagFalse partition addr' newEntry bentry0 sh1entryaddr s0:
isPDT partition s0 ->
PDTIfPDFlag s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
(*noDupKSEntriesList s0 ->*)
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HPDTIfPDflags0 Hlookupaddr's0 Hsh1addrs0 Hpdflags0 (*HNoDupKSEntriess0*).
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqBEPDflagFalse with bentry0 sh1entryaddr ; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.


Lemma getPartitionsAuxEqBEPDflagNoChangePresentNoChangeStartNoChange partition addr' newEntry bentry0 sh1entryaddr s0 n :
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
PDTIfPDFlag s0 ->
sh1entryAddr addr' sh1entryaddr s0 ->
lookup sh1entryaddr (memory {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) beqAddr = lookup sh1entryaddr (memory s0) beqAddr ->
(present newEntry) = (present bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
wellFormedFstShadowIfBlockEntry s0 ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqBEPDflagNoChangePresentNoChange with bentry0 sh1entryaddr; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- eapply IHn ; intuition.
			--- intuition.
Qed.

Lemma getPartitionsEqBEPDflagNoChangePresentNoChangeStartNoChange partition addr' newEntry bentry0 sh1entryaddr s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
PDTIfPDFlag s0 ->
sh1entryAddr addr' sh1entryaddr s0 ->
lookup sh1entryaddr (memory {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |}) beqAddr = lookup sh1entryaddr (memory s0) beqAddr ->
(present newEntry) = (present bentry0) ->
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
wellFormedFstShadowIfBlockEntry s0 ->
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddr's0 HPDTIfPDflags0 Hsh1addrs0 Hsh1Eq HpresentEq HstartAddrEq
HwellFormedSh1s0.
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqBEPDflagNoChangePresentNoChangeStartNoChange with bentry0 sh1entryaddr ; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.

(*
Lemma getPartitionsAuxEqBENotInPart partition addr' newEntry s0 n :
isBE addr' s0 ->
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqBENotInPart ; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	(*assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}*)
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- eapply IHn ; intuition.
			--- intuition.
Qed.


Lemma getPartitionsEqBENotInPart partition addr' newEntry (*bentry0 sh1entryaddr*) s0:
isBE addr' s0 ->
(*isPDT partition s0 ->
PDTIfPDFlag s0 ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->*)
~In addr' (filterOptionPaddr (getKSEntries partition s0)) ->
(*sh1entryAddr addr' sh1entryaddr s0 ->
sh1entryPDflag sh1entryaddr false s0 ->
noDupKSEntriesList s0 ->*)
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (BE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
(*intros HPDTs0 HPDTIfPDflags0 Hlookupaddr's0 Hsh1addrs0 Hpdflags0 HNoDupKSEntriess0.*)
intros HBEs0 HNotIn.
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqBENotInPart with bentry0 sh1entryaddr ; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.*)

Lemma getPartitionsAuxEqSCE partition addr' newEntry s0 n :
isPDT partition s0 ->
isSCE addr' s0 ->
PDTIfPDFlag s0 ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqSCE ; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- apply IHn ; intuition.
			--- intuition.
Qed.

(* DUP *)
Lemma getPartitionsEqSCE partition addr' newEntry s0:
isPDT partition s0 ->
isSCE addr' s0 ->
PDTIfPDFlag s0 ->
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SCE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSCEs0 HPDTIfPDflags0.
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqSCE ; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.

(* DUP *)
Lemma getPartitionsAuxEqSHE partition addr' newEntry sh1entry0 s0 n :
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
(PDflag newEntry) = (PDflag sh1entry0) ->
PDTIfPDFlag s0 ->
getPartitionsAux n partition {|
currentPartition := currentPartition s0;
memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getPartitionsAux n partition s0.
Proof.
revert n partition.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
induction n.
- intros.
	unfold getPartitionsAux in *.
	intuition.
- intros.
	unfold getPartitionsAux.
	fold getPartitionsAux.
	f_equal.
	assert(HChildrenEq: (getChildren partition s') = (getChildren partition s0)).
	{
		apply getChildrenEqSHE with sh1entry0; intuition.
	}
	rewrite HChildrenEq.
	rewrite flat_map_concat_map. rewrite flat_map_concat_map.
	f_equal.
	clear HChildrenEq.
	assert(HchildrenArePDT : forall child, In child (getChildren partition s0) ->
					isPDT child s0).
	{ intros.
		apply childrenArePDT with partition ; intuition.
	}
	induction (getChildren partition s0).
	-- intuition.
	-- simpl in *. f_equal.
			--- apply IHn ; intuition.
			--- intuition.
Qed.

(* DUP *)
Lemma getPartitionsEqSHE partition addr' newEntry sh1entry0 s0:
isPDT partition s0 ->
lookup addr' (memory s0) beqAddr = Some (SHE sh1entry0) ->
(PDflag newEntry) = (PDflag sh1entry0) ->
PDTIfPDFlag s0 ->
getPartitions partition {|
						currentPartition := currentPartition s0;
						memory := add addr' (SHE newEntry)
            (memory s0) beqAddr |} =
getPartitions partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 HSHEs0 HPDflagEq HPDTIfPDflags0.
unfold getPartitions.

assert(HgetPartitionsAuxEq : (getPartitionsAux (maxAddr + 2) partition s') =
							(getPartitionsAux (maxAddr + 2) partition s0)).
{
	eapply getPartitionsAuxEqSHE with sh1entry0; intuition.
}
rewrite HgetPartitionsAuxEq in *.
trivial.
Qed.

(* no getPartitionsEq *)
Lemma NotInPartEqPDT_WO_getPartitions partition addr' newEntry pdentry0 s0 s:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
partition <> addr' ->
StructurePointerIsKS s0 ->
s = {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} ->
getKSEntries partition s = getKSEntries partition s0
/\ getMappedPaddr partition s = getMappedPaddr partition s0
/\ getConfigPaddr partition s = getConfigPaddr partition s0
/\ getChildren partition s = getChildren partition s0
/\ getMappedBlocks partition s = getMappedBlocks partition s0
/\ getAccessibleMappedBlocks partition s = getAccessibleMappedBlocks partition s0
/\ getAccessibleMappedPaddr partition s = getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Haddr'lookups0 Haddr'partNotEq HStructPointerIsKSs0 HsEq.
subst s.
assert(HPDTaddr's0 : isPDT addr' s0)
	by (unfold isPDT ; rewrite Haddr'lookups0 ; trivial).
intuition.
eapply getKSEntriesEqPDTNotInPart ; intuition.
eapply getMappedPaddrEqPDTNotInPart; intuition.
eapply getConfigPaddrEqPDTNotInPart with pdentry0 ; intuition.
eapply getChildrenEqPDTNotInPart with pdentry0; intuition.
eapply getMappedBlocksEqPDTNotInPart; intuition.
eapply getAccessibleMappedBlocksEqPDTNotInPart; intuition.
eapply getAccessibleMappedPaddrEqPDTNotInPart; intuition.
Qed.

Lemma getKSEntriesInStructAuxInside n m p block kernelstructure idx s:
consistency1 s ->
isKS kernelstructure s ->
i idx <= i p ->
i p < n ->
i p < m ->
p < kernelStructureEntriesNb ->
In block
  (filterOptionPaddr
     (getKSEntriesInStructAux n kernelstructure s idx)) ->
In block
  (filterOptionPaddr
     (getKSEntriesInStructAux m kernelstructure s p)).
Proof.
intros.
destruct p. destruct idx. simpl in *.
revert i0 i m Hi Hi0 H1 H2 H3 H4 H5.
induction n ; simpl in * ; intuition.
revert i m Hi H1 H2 H3 H4 H5.
induction i0.
- 	intros.
	revert m Hi H1 H2 H3 H4 H5.
	induction i ; simpl in * ; intuition.
	induction m ; simpl in * ; intuition. lia.
	induction m ; simpl in * ; intuition ; try lia.

	destruct (Paddr.addPaddrIdx kernelstructure {| i := S i; Hi := Hi |}) eqn:HaddPaddrIdx ; intuition.
	destruct (lookup p (memory s) beqAddr) eqn:Hlookup; intuition.
	destruct v ; intuition.
	assert(HiEq : i -0 = i) by lia.
	simpl. right. eapply IHn with (i := i-0)(Hi0:=Hi0) ; try lia.
	assert( 0 < n) by lia.
	assert(Hsn : exists n' : nat, n = S n').
	{ clear H5 IHi IHn. clear IHm. clear HaddPaddrIdx HiEq Hi H1 H2 H3 H4.
		induction n ; simpl in * ; try lia.
		exists n. intuition.
	}
	destruct Hsn as [n' Hsn]. rewrite Hsn. simpl. intuition. (*HERE*)
	(* impossible because range OK *)
	1,2,3,4,5, 6: 
	assert(HconsBlocksRanges : BlocksRangeFromKernelStartIsBE s)
		by (unfold consistency1 in *  ; intuition) ;
	unfold BlocksRangeFromKernelStartIsBE in * ;
	assert(HisKScurr : isKS kernelstructure s) by intuition ;
	assert(HInRange : S i < kernelStructureEntriesNb) by intuition ;
	specialize (HconsBlocksRanges 	kernelstructure
									{| i := S i; Hi := Hi |}
									HisKScurr HInRange);
	unfold isBE in * ;
	assert(HnullAddrs : nullAddrExists s)
		by (unfold consistency1 in * ; intuition) ;
	unfold nullAddrExists in * ; unfold isPADDR in * ;
	unfold nullAddr in * ; unfold CPaddr in * ;
	(destruct (le_dec 0 maxAddr) ; try(lia) );
	unfold Paddr.addPaddrIdx  in * ;
	(destruct (le_dec (kernelstructure + {| i := S i; Hi := Hi |}) maxAddr) ; try(lia)) ;
	inversion HaddPaddrIdx as [Heq].

	1,2,3,4,5 :
	subst p; simpl in * ;
	unfold StateLib.Paddr.addPaddrIdx_obligation_1 in * ;
	unfold ADT.CPaddr_obligation_1 in * ;
	(destruct (lookup
	{| p := kernelstructure + S i; Hp := l0 |}
	(memory s) beqAddr) eqn:HlookupFalse; try (exfalso ; congruence)) ;
	(destruct v ; try (exfalso ; congruence)) ;
	assert(HiEq'' : ADT.CPaddr_obligation_1 0 l0 = ADT.CPaddr_obligation_2)
		by apply proof_irrelevance ;
	rewrite HiEq'' in * ;
	(destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_2 |}
	(memory s) beqAddr) ; intuition );
	(destruct v in * ; intuition).

	assert(HiEq'' : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l)
		by (intros; apply proof_irrelevance) ;
	rewrite HiEq'' in * ;
	(destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l |}
	(memory s) beqAddr) ; intuition );
	(destruct v in * ; intuition).
- 	intros.
	assert(Hi0' : i0 <= maxIdx) by lia.
	destruct (Paddr.addPaddrIdx kernelstructure {| i := S i0; Hi := Hi0 |}) eqn:HaddPaddrIdx ; simpl in * ; intuition.
	destruct (lookup p (memory s) beqAddr) eqn:Hlookup; simpl in * ; intuition.
	destruct v ; simpl in * ; intuition.
	-- 	subst p.
		revert m H1 H2 H3.
		induction i ; simpl in * ; intuition ; try lia.
		induction m ; simpl in * ; intuition ; try lia.
		assert(Hconj : S i0 = S i \/ S i0 < S i) by lia.
		destruct Hconj as [HEq | Hle].
		* rewrite HEq in *.
			assert(HidxEq : {| i := S i0; Hi := Hi0 |} = {| i := S i; Hi := Hi |}).
			{  clear IHm IHi0 IHn. clear IHi.
				assert (i = i0) by lia. subst i.
			f_equal.
			apply proof_irrelevance. }
			rewrite HidxEq in *.
			rewrite HaddPaddrIdx. rewrite Hlookup. simpl. intuition.
		* clear H1.
		destruct (Paddr.addPaddrIdx kernelstructure {| i := S i; Hi := Hi |}) eqn:HaddPaddrIdx' ; intuition.
		destruct (lookup p (memory s) beqAddr) eqn:Hlookup'; intuition.
		destruct v ; intuition.
		assert(HiEq : i -0 = i) by lia.
		simpl. right. intuition.
		assert(Hi' : i<= maxIdx) by lia.
		eapply IHn with (i := i-0)(i0:=i)(Hi0:=Hi') ; try lia.
		(* DUP *)
		(* impossible because range OK *)
		1,2,3,4,5, 6: 
		assert(HconsBlocksRanges : BlocksRangeFromKernelStartIsBE s)
			by (unfold consistency1 in *  ; intuition) ;
		unfold BlocksRangeFromKernelStartIsBE in * ;
		assert(HisKScurr : isKS kernelstructure s) by intuition ;
		assert(HInRange : S i < kernelStructureEntriesNb) by intuition ;
		specialize (HconsBlocksRanges 	kernelstructure
										{| i := S i; Hi := Hi |}
										HisKScurr HInRange);
		unfold isBE in * ;
		assert(HnullAddrs : nullAddrExists s)
			by (unfold consistency1 in * ; intuition) ;
		unfold nullAddrExists in * ; unfold isPADDR in * ;
		unfold nullAddr in * ; unfold CPaddr in * ;
		(destruct (le_dec 0 maxAddr) ; try(lia) );
		unfold Paddr.addPaddrIdx  in * ;
		(destruct (le_dec (kernelstructure + {| i := S i; Hi := Hi |}) maxAddr) ; try(lia)) ;
		inversion HaddPaddrIdx' as [Heq].

		1,2,3,4,5 :
		subst p; simpl in *  ;
		unfold StateLib.Paddr.addPaddrIdx_obligation_1 in * ;
		unfold ADT.CPaddr_obligation_1 in *;
		(destruct (lookup
		{| p := kernelstructure + S i; Hp := l0 |}
		(memory s) beqAddr) eqn:HlookupFalse; try (exfalso ; congruence)) ;
		(destruct v ; try (exfalso ; congruence)). apply IHi; lia.

    simpl in *.
    subst p. assert(HiEq'': ADT.CPaddr_obligation_1 (p kernelstructure + S i) l0
                      = StateLib.Paddr.addPaddrIdx_obligation_1 kernelstructure {| i := S i; Hi := Hi |} l0)
      by apply proof_irrelevance. rewrite HiEq'' in *. rewrite Hlookup' in *. congruence.

    assert(HKSvalid: kernelEntriesAreValid s) by (unfold consistency1 in *; intuition). simpl.
    assert(HindexValid: S i <= CIndex (kernelStructureEntriesNb - 1)).
    {
      unfold CIndex. assert(kernelStructureEntriesNb < maxIdx - 1) by (apply KSEntriesNbLessThanMaxIdx).
      destruct (le_dec (kernelStructureEntriesNb - 1) maxIdx); try(lia). cbn -[kernelStructureEntriesNb]. lia.
    }
    specialize(HKSvalid kernelstructure (S i) H0 HindexValid). unfold Paddr.addPaddrIdx in HaddPaddrIdx'.
    unfold CPaddr in HKSvalid. simpl in HaddPaddrIdx'.
    destruct (le_dec (p kernelstructure + S i) maxAddr); try(congruence).
    assert(HnullEq: {| p := 0; Hp := ADT.CPaddr_obligation_2 (p kernelstructure + S i) n0 |} = nullAddr).
    {
      unfold nullAddr. unfold CPaddr. destruct (le_dec 0 maxAddr); try(lia). f_equal.
      apply proof_irrelevance.
    }
    rewrite HnullEq in HKSvalid. assert(Hnull: nullAddrExists s) by (unfold consistency1 in *; intuition).
    unfold nullAddrExists in Hnull. unfold CPaddr in Hnull. unfold isBE in HKSvalid. unfold isPADDR in Hnull.
    destruct (lookup nullAddr (memory s) beqAddr); try(congruence). destruct v; congruence.

	-- eapply IHi0 with (Hi0:= Hi0') ; try lia.
		eapply IHn with (m:= S n)(i0:=i0)(Hi0:=Hi0'); intuition ; try lia.
		assert(HiEq : i = i-0) by lia. destruct (Nat.succ_le_mono 0 i0).
		assert(HidxEq : {|
			i := i0 - 0;
			Hi :=
			StateLib.Index.pred_obligation_1 
				{| i := S i0; Hi := Hi0 |}
				(l (Nat.le_0_l i0))
			|} = {| i := i0; Hi := Hi0' |}).
			{	clear.
				assert(Hi0Eq : i0 = i0-0) by lia.
				induction i0 ; simpl in * ; intuition.
				f_equal.
				apply proof_irrelevance.
				f_equal.
				apply proof_irrelevance.
			}
			rewrite HidxEq in *.
			assumption.
Qed.

Lemma getKSEntriesInStructAuxEqFuelSuff n (kernel: paddr) s (idx: index):
kernel + idx <= maxAddr
-> n > idx
-> (forall i Hi, i <= idx -> isBE {| p := kernel + i; Hp := Hi |} s)
-> (filterOptionPaddr (getKSEntriesInStructAux (S n) kernel s idx))
    = (filterOptionPaddr (getKSEntriesInStructAux n kernel s idx)).
Proof.
revert idx. induction n.
- intros idx HidxIsValid HNGtIdx HallEntriesAreBE. exfalso; lia.
- intros idx HidxIsValid HNGtIdx HallEntriesAreBE. set(suc:= S n). cbn - [suc]. unfold Paddr.addPaddrIdx.
  destruct (le_dec (kernel + idx) maxAddr); try(lia).
  assert(HidxBE: isBE {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l |} s).
  { apply HallEntriesAreBE. lia. }
  unfold isBE in HidxBE.
  destruct (lookup {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l |}
      (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence). unfold indexEq.
  destruct (PeanoNat.Nat.eqb idx {| i := 0; Hi := ADT.CIndex_obligation_1 0 (PeanoNat.Nat.le_0_l maxIdx) |})
      eqn:HbeqIdxZero.
  + subst suc. simpl. unfold Paddr.addPaddrIdx. destruct (le_dec (kernel + idx) maxAddr); try(lia).
    assert(HidxBE0: isBE {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l0 |} s).
    { apply HallEntriesAreBE. lia. }
    unfold isBE in HidxBE0.
    destruct (lookup {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l0 |}
        (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence). unfold indexEq.
    unfold zero. unfold CIndex. destruct (le_dec 0 maxIdx); try(lia). simpl in HbeqIdxZero. simpl.
    rewrite HbeqIdxZero. simpl. f_equal. f_equal. apply proof_irrelevance.
  + unfold Index.pred. simpl in HbeqIdxZero. apply Nat.eqb_neq in HbeqIdxZero.
    destruct (gt_dec idx 0); try(lia). cbn -[suc].
    assert(Hrec: filterOptionPaddr (getKSEntriesInStructAux suc kernel s
                        {| i := idx - 1; Hi := StateLib.Index.pred_obligation_1 idx g |})
                  = filterOptionPaddr (getKSEntriesInStructAux n kernel s
                        {| i := idx - 1; Hi := StateLib.Index.pred_obligation_1 idx g |})).
    {
      subst suc. apply IHn; simpl; try(lia). intros i Hi HiBound. apply HallEntriesAreBE. lia.
    }
    rewrite Hrec. subst suc. simpl. unfold Paddr.addPaddrIdx. destruct (le_dec (kernel + idx) maxAddr); try(lia).
    assert(HidxBE0: isBE {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l0 |} s).
    { apply HallEntriesAreBE. lia. }
    unfold isBE in HidxBE0.
    destruct (lookup {| p := kernel + idx; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel idx l0 |}
        (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence). unfold indexEq.
    apply PeanoNat.Nat.eqb_neq in HbeqIdxZero. unfold zero. unfold CIndex. destruct (le_dec 0 maxIdx); try(lia).
    simpl. rewrite HbeqIdxZero. unfold Index.pred. apply Nat.eqb_neq in HbeqIdxZero.
    destruct (gt_dec idx 0); try(lia). simpl. f_equal.
    * f_equal. apply proof_irrelevance.
    * f_equal. f_equal. f_equal. apply proof_irrelevance.
Qed.

Lemma getKSEntriesInStructAuxEqFuelSuffGen n m (kernel: paddr) s (idx: index):
kernel + idx <= maxAddr
-> m >= n
-> n > idx
-> (forall i Hi, i <= idx -> isBE {| p := kernel + i; Hp := Hi |} s)
-> (filterOptionPaddr (getKSEntriesInStructAux m kernel s idx))
    = (filterOptionPaddr (getKSEntriesInStructAux n kernel s idx)).
Proof.
intro HidxIsValid. revert n. induction m.
- intros n HdiffPos HnBound HindicesValid. assert(n = 0) by lia. subst n. reflexivity.
- intros n HdiffPos HnBound HindicesValid.
  destruct (Nat.ltb n (S m)) eqn:Hlt.
  + apply PeanoNat.Nat.ltb_lt in Hlt.
    assert(Hsucc: filterOptionPaddr (getKSEntriesInStructAux (S m) kernel s idx)
                  = filterOptionPaddr (getKSEntriesInStructAux m kernel s idx)).
    {
      apply getKSEntriesInStructAuxEqFuelSuff; try(assumption). lia.
    }
    rewrite Hsucc. apply IHm; try(assumption). lia.
  + apply PeanoNat.Nat.ltb_ge in Hlt. assert(S m = n) by lia. subst n. reflexivity.
Qed.

Lemma getKSEntriesInStructAuxRec n (kern: paddr) s (iterleft: index):
n <= iterleft
-> kern + iterleft <= maxAddr
-> (forall idx Hprop, idx <= iterleft -> isBE {| p := kern + idx; Hp := Hprop |} s)
-> filterOptionPaddr (getKSEntriesInStructAux (S n) kern s iterleft)
  = filterOptionPaddr ((getKSEntriesInStructAux n kern s iterleft)
                        ++ (getKSEntriesInStructAux 1 kern s (CIndex(iterleft - n)))).
Proof.
revert iterleft. induction n.
- intros iterleft HnLeIter HentryValid HallIndicesAreBE. rewrite filterOptionPaddrSplit. simpl.
  rewrite PeanoNat.Nat.sub_0_r. rewrite indexEqId. reflexivity.
- intros iterleft HnLeIter HentryValid HallIndicesAreBE. rewrite filterOptionPaddrSplit. set(suc:= S n).
  set(lastElem:= getKSEntriesInStructAux 1 kern s (CIndex (iterleft - suc))). cbn - [suc lastElem].
  unfold Paddr.addPaddrIdx. destruct (le_dec (kern + iterleft) maxAddr); try(lia).
  assert(iterleft <= maxAddr) by lia.
  assert(HiterIsBE: isBE {| p := kern + iterleft;
                            Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kern iterleft l |} s).
  { apply HallIndicesAreBE. lia. }
  unfold isBE in HiterIsBE.
  destruct (lookup {| p := kern + iterleft; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kern iterleft l |}
      (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence). unfold indexEq.
  destruct (PeanoNat.Nat.eqb iterleft {| i := 0; Hi := ADT.CIndex_obligation_1 0 (PeanoNat.Nat.le_0_l maxIdx) |})
      eqn:HbeqIterZero.
  + simpl in HbeqIterZero. apply PeanoNat.Nat.eqb_eq in HbeqIterZero. exfalso; lia.
  + simpl in HbeqIterZero. apply Nat.eqb_neq in HbeqIterZero. unfold Index.pred.
    destruct (gt_dec iterleft 0); try(lia). cbn - [suc lastElem].
    assert(Hrec: filterOptionPaddr (getKSEntriesInStructAux suc kern s
                        {| i := iterleft - 1; Hi := StateLib.Index.pred_obligation_1 iterleft g |})
                  = filterOptionPaddr (getKSEntriesInStructAux n kern s
                          {| i := iterleft - 1; Hi := StateLib.Index.pred_obligation_1 iterleft g |}
                        ++ getKSEntriesInStructAux 1 kern s (CIndex (iterleft-1-n)))).
    {
      subst suc. apply IHn; simpl; try(lia). intros idx Hi HidxBound. apply HallIndicesAreBE. lia.
    }
    rewrite Hrec. rewrite filterOptionPaddrSplit.
    assert(Hlast: getKSEntriesInStructAux 1 kern s (CIndex (iterleft - 1 - n)) = lastElem).
    {
      subst lastElem. subst suc. assert(Heq: iterleft - 1 - n = iterleft - S n) by lia. rewrite Heq.
      reflexivity.
    }
    rewrite Hlast. cbn -[lastElem]. unfold Paddr.addPaddrIdx.
    destruct (le_dec (kern + iterleft) maxAddr); try(lia).
    assert(HiterIsBE0: isBE {| p := kern + iterleft;
                              Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kern iterleft l0 |} s).
    { apply HallIndicesAreBE. lia. }
    unfold isBE in HiterIsBE0.
    destruct (lookup {| p := kern + iterleft; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kern iterleft l0 |}
        (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence). unfold indexEq.
    cbn -[lastElem]. apply PeanoNat.Nat.eqb_neq in HbeqIterZero. rewrite HbeqIterZero.
    apply Nat.eqb_neq in HbeqIterZero. unfold Index.pred. destruct (gt_dec iterleft 0); try(lia).
    cbn -[lastElem]. f_equal.
    * f_equal. apply proof_irrelevance.
    * f_equal. f_equal. f_equal. f_equal. apply proof_irrelevance.
Qed.

Lemma blockInRangeInStruct blockEntryAddr (min : paddr) (idx : index) n s:
i idx < n ->
idx < kernelStructureEntriesNb ->
consistency s ->
StateLib.Paddr.leb min blockEntryAddr = true ->
StateLib.Paddr.leb blockEntryAddr (CPaddr (min+idx)) = true ->
isKS min s ->
isBE blockEntryAddr s ->
In blockEntryAddr
  (filterOptionPaddr
     (getKSEntriesInStructAux n min s idx)).
Proof.
revert n idx min.

unfold Paddr.leb in *.

induction n.
* intuition. simpl in *. lia.
* intros. simpl. unfold Paddr.addPaddrIdx.

  assert(HwellFormedSh1 : wellFormedFstShadowIfBlockEntry s)
    by (unfold consistency in * ; unfold consistency1 in * ; intuition).
  unfold wellFormedFstShadowIfBlockEntry.
  assert(HBE : isBE min s).
  {
    unfold isBE. unfold isKS in *.
    destruct (lookup min (memory s) beqAddr) ; intuition.
    destruct v ; intuition.
  }
  specialize (HwellFormedSh1 min HBE).
  unfold isSHE in *.

  unfold CPaddr in HwellFormedSh1.
  unfold sh1offset in *. unfold blkoffset in *.
  simpl in *.

  assert(HblockrangeLtMax : min + CIndex kernelStructureEntriesNb <= maxAddr).
  {	
    unfold CIndex in *.
    rewrite <- maxIdxEqualMaxAddr in *.
    assert(kernelStructureEntriesNb < maxIdx-1) by apply KSEntriesNbLessThanMaxIdx.
    destruct (le_dec kernelStructureEntriesNb maxIdx) ; intuition ; simpl ; try lia.
    unfold CPaddr in *. 
    destruct (le_dec
    (min +
     {|
       i := kernelStructureEntriesNb;
       Hi :=
         ADT.CIndex_obligation_1
           kernelStructureEntriesNb l
     |}) maxAddr) ; intuition ; simpl in * ; try lia.
     rewrite maxIdxEqualMaxAddr in *.
     lia.

    assert(HnullAddrExists : nullAddrExists s)
      by (unfold consistency in * ; unfold consistency1 in * ; intuition).
    unfold nullAddrExists in *. unfold isPADDR in *.
    unfold nullAddr in *. unfold CPaddr in *.
    destruct (le_dec 0 maxAddr) ; try lia.
    assert(HnullEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l0)
      by (intros; apply proof_irrelevance).
    rewrite HnullEq in *.
    destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l0 |}
    (memory s) beqAddr) ; try (exfalso ; congruence).
    destruct v ; try (exfalso ; congruence).
  }

  destruct (le_dec (min + CIndex kernelStructureEntriesNb) maxAddr) ; simpl ; try lia.

  assert(HBlocksrange : BlocksRangeFromKernelStartIsBE s)
    by (unfold consistency in * ; unfold consistency1 in * ; intuition).
  unfold BlocksRangeFromKernelStartIsBE in *.
  assert(HKS : isKS min s) by intuition.

  specialize (HBlocksrange min idx HKS H0).
  unfold isBE in *.
  unfold CPaddr in *.
  destruct (le_dec (min + idx) maxAddr) ; intuition.

  assert(HpEq : ADT.CPaddr_obligation_1 (min + idx) l0 = 
  StateLib.Paddr.addPaddrIdx_obligation_1 min idx l0)
    by apply proof_irrelevance.
  rewrite HpEq in *.

  destruct (lookup
  {|
    p := min + idx;
    Hp := StateLib.Paddr.addPaddrIdx_obligation_1 min idx l0
  |} (memory s) beqAddr) ; intuition.
  destruct v ; intuition.

  destruct (beqIdx idx zero) eqn:idxzeroEq.
  - (* idx = zero *)
    rewrite <- DTL.beqIdxTrue in idxzeroEq.
    rewrite idxzeroEq in *.
    simpl. left.
    unfold zero in *.
    unfold StateLib.Paddr.addPaddrIdx_obligation_1.

    unfold CIndex in idxzeroEq.
    destruct (le_dec 0 maxIdx) ; try(lia).
    simpl in *.
    
    subst. simpl in *.
    rewrite PeanoNat.Nat.add_0_r in *.
    destruct (le_dec min maxAddr) ; intuition ; try lia.
    simpl in *.
    rewrite PeanoNat.Nat.leb_le in *.

    destruct blockEntryAddr. destruct min.

    intuition. simpl in *.
    assert(p0 +0 = p) by lia.
    subst.
    assert(l0 = Hp).
    {
      apply proof_irrelevance.
    }
    subst.
    trivial.
  - (* idx <> zero *)
    rewrite <- beqIdxFalse in *.

    destruct (Index.pred idx) eqn:Hpred.
    -- (* true : pred exists *)
      simpl.
      unfold Index.pred in *.
      destruct (gt_dec idx 0) ; intuition ; try (exfalso ; congruence).
      inversion Hpred.
      rewrite PeanoNat.Nat.leb_le in *.
      rewrite PeanoNat.Nat.le_lteq in H3.
      intuition ; try lia ; try (exfalso ; congruence).
      --- right.
          eapply IHn with (min:=min); intuition ; simpl in * ; try lia.
          rewrite PeanoNat.Nat.leb_le in *. lia.
          destruct (le_dec (min + (idx - 1)) maxAddr) ; intuition ; try lia.
          simpl in *.
          rewrite PeanoNat.Nat.leb_le in *. lia.
      --- 
          left. intuition.
          destruct blockEntryAddr. destruct min. destruct idx.
          simpl in *.
          subst.
          f_equal. apply proof_irrelevance.

    -- (* false : pred does not exist *)
        unfold Index.pred in *.
        destruct idx ; intuition. simpl in *.
        unfold zero in *. unfold CIndex in idxzeroEq.
        destruct (le_dec 0 maxIdx) ; try(lia).
        simpl in *.
        destruct i ; intuition ; try lia.
        assert(Hi = ADT.CIndex_obligation_1 0 l1)
          by apply proof_irrelevance.
        subst. congruence.
        destruct (gt_dec (S i) 0); try (exfalso ; congruence). lia.
  - 
    assert(HnullAddrExists : nullAddrExists s)
      by (unfold consistency in * ; unfold consistency1 in * ; intuition).
    unfold nullAddrExists in *. unfold isPADDR in *.
    unfold nullAddr in *. unfold CPaddr in *.
    destruct (le_dec 0 maxAddr) ; try lia.
    assert(HnullEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l0)
      by (intros; apply proof_irrelevance).
    rewrite HnullEq in *.
    destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l0 |}
    (memory s) beqAddr) ; try (exfalso ; congruence).
    destruct v ; try (exfalso ; congruence).
Qed.

(*TODO is that the right place for these lemmas?*)
Lemma mappedAddrIsInMappedBlock addr partition s:
In addr (getMappedPaddr partition s)
-> exists block,
    In block (getMappedBlocks partition s)
    /\ In addr (getAllPaddrAux [block] s).
Proof.
unfold getMappedPaddr. intro HaddrIsMapped. induction (getMappedBlocks partition s).
- simpl in HaddrIsMapped. exfalso; congruence.
- simpl in HaddrIsMapped. destruct (lookup a (memory s) beqAddr) eqn:HlookupA; try(specialize(IHl HaddrIsMapped);
        destruct IHl as [block (HblockInL & HaddrInBlock)]; exists block; split; try(assumption); simpl; right;
        assumption).
  destruct v; try(specialize(IHl HaddrIsMapped); destruct IHl as [block (HblockInL & HaddrInBlock)];
        exists block; split; try(assumption); simpl; right; assumption).
  apply in_app_or in HaddrIsMapped. destruct HaddrIsMapped as [HaddrInBlock | HaddrIsMapped].
  + simpl. exists a. rewrite HlookupA. split. left. reflexivity. rewrite app_nil_r. assumption.
  + specialize(IHl HaddrIsMapped). destruct IHl as [block (HblockInL & HaddrInBlock)].
    exists block. split; try(assumption). simpl. right. assumption.
Qed.

Lemma mappedBlockIsBE block partition s:
In block (getMappedBlocks partition s)
-> exists bentry, lookup block (memory s) beqAddr = Some(BE bentry)
                  /\ present bentry = true.
Proof.
unfold getMappedBlocks. intro HblockIsMapped. induction (filterOptionPaddr (getKSEntries partition s)).
- simpl in HblockIsMapped. exfalso; congruence.
- simpl in HblockIsMapped.
  destruct (lookup a (memory s) beqAddr) eqn:HlookupA; try(specialize(IHl HblockIsMapped); assumption).
  destruct v; try(specialize(IHl HblockIsMapped); assumption).
  destruct (present b) eqn:Hpresent; try(specialize(IHl HblockIsMapped); assumption).
  simpl in HblockIsMapped.
  destruct HblockIsMapped as [HaIsBlock | HblockIsMapped]; try(specialize(IHl HblockIsMapped); assumption).
  subst a. exists b. intuition.
Qed.

Lemma getAllPaddrBlockAuxIncl (addr: paddr) pos offset count:
pos + offset <= addr
-> addr < count + offset + pos
-> In addr (getAllPaddrBlockAux pos offset count).
Proof.
revert pos. induction count.
- simpl. intros. lia.
- simpl. intros pos HaddrAfterStart HaddrBeforEnd.
  assert(HaddrLowerThanMax: addr <= maxAddr) by (apply Hp).
  destruct (le_dec (pos + offset) maxAddr); try(exfalso; lia). simpl.
  destruct (Nat.eqb addr (pos + offset)) eqn:HbeqAddrPosOffset.
  + apply Nat.eqb_eq in HbeqAddrPosOffset. destruct addr. simpl in *. subst p. left. f_equal.
    apply proof_irrelevance.
  + apply Nat.eqb_neq in HbeqAddrPosOffset. right.
    apply IHcount; lia.
Qed.

Lemma getAllPaddrBlockIncl (addr startaddr endaddr: paddr):
startaddr <= addr
-> addr < endaddr
-> startaddr < endaddr
-> In addr (getAllPaddrBlock startaddr endaddr).
Proof.
intros HstartLower HendHigher HstartLtEnd. unfold getAllPaddrBlock.
assert(HstartLtEndBis: endaddr - startaddr > 0) by lia.
destruct (endaddr - startaddr) eqn:Hinterval.
- lia.
- simpl. assert(startaddr <= maxAddr) by (apply Hp).
  destruct (le_dec startaddr maxAddr); try(lia). simpl. destruct (beqAddr startaddr addr) eqn:HbeqStartAddr.
  + left. rewrite <-DTL.beqAddrTrue in HbeqStartAddr. subst addr. destruct startaddr. simpl.
    f_equal. apply proof_irrelevance.
  + rewrite <-beqAddrFalse in HbeqStartAddr. right. apply getAllPaddrBlockAuxIncl; try(lia).
    assert(p startaddr <> p addr).
    {
      contradict HbeqStartAddr. destruct startaddr. destruct addr. simpl in *. subst p0. f_equal.
      apply proof_irrelevance.
    }
    lia.
Qed.

Lemma addrInAllPaddrBlockAuxIncl addr pos (start1 start2 end1 end2: paddr):
start1 <= end1
-> start2 <= end2
-> start2 <= start1
-> end2 >= end1
-> In addr (getAllPaddrBlockAux pos start1 (end1 - start1))
-> In addr (getAllPaddrBlockAux pos start2 (end2 - start2)).
Proof.
intros HwellFormed1 HwellFormed2 HstartLower HendHigher HaddrInBlock.
replace (end2 - start2) with (end2 - end1 + end1 - start1 + start1 - start2).
- set(count := end1 - start1). fold count in HaddrInBlock.
  replace (end2 - end1 + end1 - start1 + start1 - start2) with (end2 - end1 + count + start1 - start2);
      try(subst count; rewrite PeanoNat.Nat.add_sub_assoc; intuition; congruence).
  revert HaddrInBlock. revert pos. induction count.
  + simpl in *. intros. exfalso; congruence.
  + intros pos HaddrInBlock.
    replace (end2 - end1 + S count + start1 - start2) with (S (end2 - end1 + count + start1 - start2));
        try(rewrite PeanoNat.Nat.add_succ_r; rewrite PeanoNat.Nat.add_succ_l; rewrite PeanoNat.Nat.sub_succ_l;
            try(reflexivity); lia).
    simpl in *. destruct (le_dec (pos + start1) maxAddr); try(exfalso; intuition; congruence).
    destruct (le_dec (pos + start2) maxAddr); try(exfalso; lia). simpl in *.
    destruct HaddrInBlock as [HaddrIsFirst | HaddrInBlockRec].
    * destruct (beqAddr start1 start2) eqn:HbeqStart1Start2.
      -- rewrite <-DTL.beqAddrTrue in HbeqStart1Start2. subst start1. left. subst addr. f_equal.
         apply proof_irrelevance.
      -- right. rewrite <-beqAddrFalse in HbeqStart1Start2. subst addr.
         assert(S pos + start2 <= pos + start1).
         {
           rewrite PeanoNat.Nat.add_succ_comm. apply PeanoNat.Nat.add_le_mono_l. apply Nat.le_succ_l.
           assert(HbeqStart1Start2Field: p start1 <> p start2).
           {
             contradict HbeqStart1Start2. destruct start1 as [x Hx], start2 as [y Hy].
             simpl in HbeqStart1Start2. subst x. f_equal. apply proof_irrelevance.
           }
           lia.
         }
         apply getAllPaddrBlockAuxIncl; try(intuition; lia).
         rewrite PeanoNat.Nat.sub_add; try(lia).
         assert(pos + start1 < start1 + S pos) by lia. simpl.
         lia.
    * specialize(IHcount (S pos) HaddrInBlockRec). right. assumption.
- assert(HeqEnd: end2 - end1 + end1 = end2).
  { apply PeanoNat.Nat.sub_add. lia. }
  rewrite HeqEnd.
  assert(HeqStart: end2 - start1 + start1 = end2).
  { apply PeanoNat.Nat.sub_add. lia. }
  rewrite HeqStart. reflexivity.
Qed.

Lemma getAllPaddrBlockInclRevAux addr offset start rangeLen:
In addr (getAllPaddrBlockAux offset start rangeLen)
-> start + offset <= addr /\ addr < start + offset + rangeLen /\ rangeLen > 0.
Proof.
revert offset. induction rangeLen; try(simpl; intros; exfalso; congruence).
intros offset HaddrIn. simpl in HaddrIn. assert(HnotEmpty: ~In addr []) by (apply in_nil).
destruct (le_dec (offset + start) maxAddr); try(exfalso; congruence). simpl in HaddrIn.
destruct HaddrIn as [HaddrIsFirst | HaddrInRec].
- subst addr. simpl. split. lia. split; lia.
- specialize(IHrangeLen (S offset) HaddrInRec). destruct IHrangeLen as (HleftBound & HrightBound & HrangePos).
  split. lia. split; lia.
Qed.

Lemma getAllPaddrBlockInclRev (addr startaddr endaddr: paddr):
In addr (getAllPaddrBlock startaddr endaddr)
-> startaddr <= addr /\ addr < endaddr /\ startaddr < endaddr.
Proof.
intro HaddrIn. unfold getAllPaddrBlock in HaddrIn.
pose proof (getAllPaddrBlockInclRevAux addr 0 startaddr (endaddr - startaddr) HaddrIn) as Hres.
destruct Hres as (HleftBound & HrightBound & HrangePos). split. lia. split; lia.
Qed.

Lemma getAllPaddrBlockEqBEEndLower addr s0 s blocklist block blockBis bentry0 newEntry bentry0Bis:
s = {|
      currentPartition := currentPartition s0;
      memory := add block (BE newEntry) (memory s0) beqAddr
    |}
-> lookup block (memory s0) beqAddr = Some (BE bentry0)
-> lookup blockBis (memory s0) beqAddr = Some (BE bentry0Bis)
-> startAddr (blockrange newEntry) = startAddr (blockrange bentry0)
-> endAddr (blockrange newEntry) <= endAddr (blockrange bentry0)
-> ~In blockBis blocklist
-> In block blocklist
-> NoDup blocklist
-> (In addr (getAllPaddrBlock (endAddr (blockrange newEntry)) (endAddr (blockrange bentry0)))
    -> In addr (getAllPaddrAux [blockBis] s0))
-> In addr (getAllPaddrAux blocklist s0)
-> In addr ((getAllPaddrBlock (startAddr (blockrange bentry0Bis)) (endAddr (blockrange bentry0Bis)))
            ++ (getAllPaddrAux blocklist s)).
Proof.
intros Hs HlookupBlock HlookupBlockBis HstartEq HendLe HblockBisNotInList HblockInList HnoDup HaddrRedund.
induction blocklist; try(simpl in *; congruence). simpl in *. apply not_or_and in HblockBisNotInList.
destruct HblockBisNotInList as (HbeqaBlockBis & HblockBisNotInListRec). rewrite HlookupBlockBis in HaddrRedund.
rewrite app_nil_r in HaddrRedund. apply NoDup_cons_iff in HnoDup. destruct HnoDup as (HaNotInListRec & HnoDupRec).
destruct HblockInList as [HaIsBlock | HblockInListRec].
- subst a. rewrite HlookupBlock. assert(HlookupBlocks: lookup block (memory s) beqAddr = Some(BE newEntry)).
  { rewrite Hs. simpl. rewrite beqAddrTrue. reflexivity. }
  rewrite HlookupBlocks. rewrite HstartEq.
  assert(HgetAllPaddrEq: getAllPaddrAux blocklist s = getAllPaddrAux blocklist s0).
  { rewrite Hs. apply getAllPaddrAuxEqBENoInList. assumption. }
  rewrite HgetAllPaddrEq. intro HaddrMappeds0. apply in_app_or in HaddrMappeds0. apply in_or_app.
  destruct HaddrMappeds0 as [HaddrInBlock | HaddrMappeds0Rec]; try(right; apply in_or_app; right; assumption).
  apply getAllPaddrBlockInclRev in HaddrInBlock. destruct HaddrInBlock as (HaboveStart & HbelowEnd & Hbounds).
  destruct (PeanoNat.Nat.ltb addr (endAddr (blockrange newEntry))) eqn:HltAddrEnd.
  + apply PeanoNat.Nat.ltb_lt in HltAddrEnd. right. apply in_or_app. left. apply getAllPaddrBlockIncl; lia.
  + apply PeanoNat.Nat.ltb_ge in HltAddrEnd. left. apply HaddrRedund. apply getAllPaddrBlockIncl; try(lia).
- assert(HlookupAEq: lookup a (memory s) beqAddr = lookup a (memory s0) beqAddr).
  {
    rewrite Hs. simpl. destruct (beqAddr block a) eqn:HbeqaBlock.
    { rewrite <-DTL.beqAddrTrue in HbeqaBlock. subst a. exfalso; congruence. }
    rewrite <-beqAddrFalse in HbeqaBlock. rewrite removeDupIdentity; intuition.
  }
  rewrite HlookupAEq. destruct (lookup a (memory s0) beqAddr); try(apply IHblocklist; assumption).
  destruct v; try(apply IHblocklist; assumption). intro HaddrMappeds0. apply in_app_or in HaddrMappeds0.
  apply in_or_app. destruct HaddrMappeds0 as [HaddrInA | HaddrMappeds0Rec].
  + right. apply in_or_app. left. assumption.
  + specialize(IHblocklist HblockBisNotInListRec HblockInListRec HnoDupRec HaddrMappeds0Rec).
    apply in_app_or in IHblocklist.
    destruct IHblocklist as [HaddrInBlockBis | HaddrMappedsRec]; try(left; assumption). right. apply in_or_app.
    right. assumption.
Qed.

Lemma getAllPaddrBlockEqBEEndLowerRev addr s0 s blocklist block blockBis bentry0 newEntry bentry0Bis:
s = {|
      currentPartition := currentPartition s0;
      memory := add block (BE newEntry) (memory s0) beqAddr
    |}
-> lookup block (memory s0) beqAddr = Some (BE bentry0)
-> lookup blockBis (memory s0) beqAddr = Some (BE bentry0Bis)
-> startAddr (blockrange newEntry) = startAddr (blockrange bentry0)
-> endAddr (blockrange newEntry) <= endAddr (blockrange bentry0)
-> ~In blockBis blocklist
-> In block blocklist
-> NoDup blocklist
-> In addr (getAllPaddrAux blocklist s)
-> In addr (getAllPaddrAux blocklist s0).
Proof.
intros Hs HlookupBlock HlookupBlockBis HstartEq HendLe HblockBisNotInList HblockInList HnoDup HaddrMappeds.
induction blocklist; try(simpl in *; congruence). simpl in *. apply not_or_and in HblockBisNotInList.
destruct HblockBisNotInList as (HbeqaBlockBis & HblockBisNotInListRec). apply NoDup_cons_iff in HnoDup.
destruct HnoDup as (HaNotInListRec & HnoDupRec). destruct HblockInList as [HaIsBlock | HblockInListRec].
- subst a. rewrite HlookupBlock. assert(HlookupBlocks: lookup block (memory s) beqAddr = Some(BE newEntry)).
  { rewrite Hs. simpl. rewrite beqAddrTrue. reflexivity. }
  rewrite HlookupBlocks in HaddrMappeds. rewrite HstartEq in HaddrMappeds.
  assert(HgetAllPaddrEq: getAllPaddrAux blocklist s = getAllPaddrAux blocklist s0).
  { rewrite Hs. apply getAllPaddrAuxEqBENoInList. assumption. }
  rewrite HgetAllPaddrEq in HaddrMappeds. apply in_app_or in HaddrMappeds. apply in_or_app.
  destruct HaddrMappeds as [HaddrInBlock | HaddrMappedsRec]; try(right; assumption). left.
  apply getAllPaddrBlockInclRev in HaddrInBlock. destruct HaddrInBlock as (HaboveStart & HbelowEnd & Hbounds).
  apply getAllPaddrBlockIncl; lia.
- assert(HlookupAEq: lookup a (memory s) beqAddr = lookup a (memory s0) beqAddr).
  {
    rewrite Hs. simpl. destruct (beqAddr block a) eqn:HbeqaBlock.
    { rewrite <-DTL.beqAddrTrue in HbeqaBlock. subst a. exfalso; congruence. }
    rewrite <-beqAddrFalse in HbeqaBlock. rewrite removeDupIdentity; intuition.
  }
  rewrite HlookupAEq in HaddrMappeds. destruct (lookup a (memory s0) beqAddr); try(apply IHblocklist; assumption).
  destruct v; try(apply IHblocklist; assumption). apply in_app_or in HaddrMappeds.
  apply in_or_app. destruct HaddrMappeds as [HaddrInA | HaddrMappedsRec]; try(left; assumption). right.
  apply IHblocklist; assumption.
Qed.

Lemma getMappedPaddrEqBEEndLower partition block blockBis addr newEntry newEnd bentry0 bentry0Bis s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
lookup blockBis (memory s0) beqAddr = Some (BE bentry0Bis) ->
(present newEntry) = (present bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = newEnd ->
newEnd <= (endAddr (blockrange bentry0)) ->
blockBis <> block ->
(*noDupKSEntriesList s0 ->*)
noDupMappedBlocksList s0 ->
(forall addr', In addr' (getAllPaddrBlock newEnd (endAddr (blockrange bentry0)))
              -> In addr' (getAllPaddrAux [blockBis] s0)) ->
In block (getMappedBlocks partition s0) ->
In blockBis (getMappedBlocks partition s0) ->
In addr
(getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) <->
In addr (getMappedPaddr partition s0).
Proof.
set (s := {|
            currentPartition := currentPartition s0;
            memory := _ |}).
intros HpartIsPDT HlookupBlocks0 HlookupBlockBiss0 HpresentEq HstartEq HnewEnd HnewEndIsLower HbeqBlocks HnoDup
    HaddrRedund HblockMapped HblockBisMapped. specialize(HnoDup partition HpartIsPDT). unfold getMappedPaddr.
assert(HgetMappedEq: getMappedBlocks partition s = getMappedBlocks partition s0).
{
  unfold s. apply getMappedBlocksEqBENoChange with bentry0; assumption.
}
rewrite HgetMappedEq. clear HgetMappedEq. induction (getMappedBlocks partition s0); try(intuition; congruence).
simpl in HblockMapped. simpl in HblockBisMapped. apply NoDup_cons_iff in HnoDup.
destruct HnoDup as (HaNotInList & HnoDupRec). destruct HblockMapped as [HaIsBlock | HblockMappedRec].
- subst a. destruct HblockBisMapped as [HblockEq | HblockBisMappedRec]; try(exfalso; congruence).
  simpl. rewrite beqAddrTrue. rewrite HlookupBlocks0. rewrite HstartEq. subst newEnd.
  assert(HgetAllPaddrEq: getAllPaddrAux l s = getAllPaddrAux l s0).
  { unfold s. apply getAllPaddrAuxEqBENoInList. assumption. }
  rewrite HgetAllPaddrEq. split.
  + intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
    destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(right; assumption). left.
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    apply getAllPaddrBlockIncl; lia.
  + intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
    destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(right; assumption).
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    destruct (PeanoNat.Nat.ltb addr (endAddr (blockrange newEntry))) eqn:HltAddrEnd.
    * apply PeanoNat.Nat.ltb_lt in HltAddrEnd. left. apply getAllPaddrBlockIncl; lia.
    * apply PeanoNat.Nat.ltb_ge in HltAddrEnd. right.
      assert(HaddrInBlockBis: In addr (getAllPaddrAux [blockBis] s0)).
      { apply HaddrRedund. apply getAllPaddrBlockIncl; lia. }
      apply blockIsMappedAddrInPaddrList with blockBis; assumption.
- destruct HblockBisMapped as [HaIsBlockBis | HblockBisMappedRec].
  + subst a. simpl. rewrite beqAddrFalse in HbeqBlocks. rewrite beqAddrSym in HbeqBlocks. rewrite HbeqBlocks.
    rewrite <-beqAddrFalse in HbeqBlocks. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupBlockBiss0. subst newEnd.
    assert(Hs: s = {|
                     currentPartition := currentPartition s0; memory := add block (BE newEntry) (memory s0) beqAddr
                   |}) by (unfold s; reflexivity). specialize(HaddrRedund addr). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. revert HaddrMappeds0.
      revert HnoDupRec. revert HblockMappedRec. revert HaNotInList. revert HnewEndIsLower.
      apply getAllPaddrBlockEqBEEndLowerRev with bentry0Bis; assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption).
      pose proof (getAllPaddrBlockEqBEEndLower addr s0 s l block blockBis bentry0 newEntry bentry0Bis Hs
            HlookupBlocks0 HlookupBlockBiss0 HstartEq HnewEndIsLower HaNotInList HblockMappedRec HnoDupRec
            HaddrRedund HaddrMappeds0) as Hres. apply in_app_or in Hres. assumption.
  + specialize(IHl HnoDupRec HblockMappedRec HblockBisMappedRec). simpl.
    destruct (beqAddr block a) eqn:HbeqaBlock.
    {
      rewrite <-DTL.beqAddrTrue in HbeqaBlock. subst a. exfalso; congruence.
    }
    rewrite <-beqAddrFalse in HbeqaBlock. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    destruct (lookup a (memory s0) beqAddr); try(assumption). destruct v; try(assumption).
    destruct IHl as (Hleft & Hright). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply Hleft.
      assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply Hright.
      assumption.
Qed.

Lemma getAccessibleMappedPaddrEqBEEndLower partition block blockBis addr newEntry newEnd bentry0 bentry0Bis s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
lookup blockBis (memory s0) beqAddr = Some (BE bentry0Bis) ->
accessible newEntry = accessible bentry0 ->
accessible bentry0 = true ->
accessible bentry0Bis = true ->
(present newEntry) = (present bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = newEnd ->
newEnd <= (endAddr (blockrange bentry0)) ->
blockBis <> block ->
(*noDupKSEntriesList s0 ->*)
noDupMappedBlocksList s0 ->
(forall addr', In addr' (getAllPaddrBlock newEnd (endAddr (blockrange bentry0)))
              -> In addr' (getAllPaddrAux [blockBis] s0)) ->
In block (getMappedBlocks partition s0) ->
In blockBis (getAccessibleMappedBlocks partition s0) ->
In addr
(getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) <->
In addr (getAccessibleMappedPaddr partition s0).
Proof.
set (s := {|
            currentPartition := currentPartition s0;
            memory := _ |}).
intros HpartIsPDT HlookupBlocks0 HlookupBlockBiss0 Haccess HaccessBis HaccessEq HpresentEq HstartEq HnewEnd
    HnewEndIsLower HbeqBlocks HnoDup HaddrRedund HblockMapped HblockBisAccMapped.
specialize(HnoDup partition HpartIsPDT). unfold getAccessibleMappedPaddr.
assert(HgetAccMappedEq: getAccessibleMappedBlocks partition s = getAccessibleMappedBlocks partition s0).
{
  unfold s. apply getAccessibleMappedBlocksEqBEAccessiblePresentNoChange with bentry0; assumption.
}
rewrite HgetAccMappedEq. unfold getAccessibleMappedBlocks. unfold getAccessibleMappedBlocks in HblockBisAccMapped.
destruct (lookup partition (memory s0) beqAddr) eqn:HlookupPart; try(intuition; congruence).
destruct v; try(intuition; congruence). induction (getMappedBlocks partition s0); try(intuition; congruence).
simpl in HblockMapped. simpl in HblockBisAccMapped. apply NoDup_cons_iff in HnoDup.
destruct HnoDup as (HaNotInList & HnoDupRec). destruct HblockMapped as [HaIsBlock | HblockMappedRec].
- subst a. rewrite HlookupBlocks0 in HblockBisAccMapped.
  assert(HblockBisAccMappedRec: In blockBis (filterAccessible l s0)).
  {
    destruct (accessible bentry0).
    - simpl in HblockBisAccMapped.
      destruct HblockBisAccMapped as [HblockEq | HblockBisAccMappedRec]; try(exfalso; congruence). assumption.
    - assumption.
  }
  simpl. rewrite HlookupBlocks0.
  assert(HgetAllPaddrEq: getAllPaddrAux (filterAccessible l s0) s = getAllPaddrAux (filterAccessible l s0) s0).
  {
    unfold s. apply getAllPaddrAuxEqBENoInList. apply NotInListNotInFilterAccessible. assumption.
  }
  destruct (accessible bentry0); try(rewrite HgetAllPaddrEq; split; intro; assumption).
  simpl in HblockBisAccMapped. simpl. rewrite beqAddrTrue. rewrite HlookupBlocks0. rewrite HstartEq.
  rewrite HnewEnd. rewrite HgetAllPaddrEq. split.
  + intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
    destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(right; assumption). left.
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    apply getAllPaddrBlockIncl; lia.
  + intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
    destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(right; assumption).
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    destruct (PeanoNat.Nat.ltb addr (endAddr (blockrange newEntry))) eqn:HltAddrEnd.
    * apply PeanoNat.Nat.ltb_lt in HltAddrEnd. left. apply getAllPaddrBlockIncl; try(rewrite <-HnewEnd); lia.
    * apply PeanoNat.Nat.ltb_ge in HltAddrEnd. right.
      assert(HaddrInBlockBis: In addr (getAllPaddrAux [blockBis] s0)).
      { apply HaddrRedund. apply getAllPaddrBlockIncl; try(rewrite <-HnewEnd); lia. }
      apply blockIsMappedAddrInPaddrList with blockBis; assumption.
- simpl. specialize(IHl HnoDupRec HblockMappedRec).
  destruct (lookup a (memory s0) beqAddr) eqn:HlookupA; try(apply IHl; assumption).
  destruct v; try(apply IHl; assumption). destruct (accessible b); try(apply IHl; assumption). simpl.
  simpl in HblockBisAccMapped. rewrite HlookupA.
  destruct HblockBisAccMapped as [HaIsBlockBis | HblockBisMappedRec].
  + subst a. rewrite beqAddrFalse in HbeqBlocks. rewrite beqAddrSym in HbeqBlocks. rewrite HbeqBlocks.
    rewrite <-beqAddrFalse in HbeqBlocks. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupBlockBiss0. subst newEnd. rewrite HlookupBlockBiss0 in HlookupA. injection HlookupA as Hbeq.
    subst b.
    assert(Hs: s = {|
                     currentPartition := currentPartition s0;
                     memory := add block (BE newEntry) (memory s0) beqAddr
                   |}) by (unfold s; reflexivity). specialize(HaddrRedund addr). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. revert HaddrMappeds0.
      apply getAllPaddrBlockEqBEEndLowerRev with block blockBis bentry0 newEntry bentry0Bis; try(assumption).
      apply NotInListNotInFilterAccessible; assumption.
      apply accessibleIsInFilterAccessible with bentry0; assumption.
      apply NoDupFilterAccessible; assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption).
      assert(HaNotInAccList: ~ In blockBis (filterAccessible l s0)).
      { apply NotInListNotInFilterAccessible. assumption. }
      assert(HblockAccMappedRec: In block (filterAccessible l s0)).
      { apply accessibleIsInFilterAccessible with bentry0; assumption. }
      assert(HnoDupAccRec: NoDup (filterAccessible l s0)).
      { apply NoDupFilterAccessible; assumption. }
      pose proof (getAllPaddrBlockEqBEEndLower addr s0 s (filterAccessible l s0) block blockBis bentry0 newEntry
            bentry0Bis Hs HlookupBlocks0 HlookupBlockBiss0 HstartEq HnewEndIsLower HaNotInAccList
            HblockAccMappedRec HnoDupAccRec HaddrRedund HaddrMappeds0) as Hres. apply in_app_or in Hres.
      assumption.
  + specialize(IHl HblockBisMappedRec).
    destruct (beqAddr block a) eqn:HbeqaBlock.
    { rewrite <-DTL.beqAddrTrue in HbeqaBlock. subst a. exfalso; congruence. }
    rewrite <-beqAddrFalse in HbeqaBlock. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupA. destruct IHl as (Hleft & Hright). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply Hleft.
      assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply Hright.
      assumption.
Qed.

Lemma getAccessibleMappedPaddrEqBEEndLowerLax partition block blockBis addr newEntry newEnd bentry0 bentry0Bis s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
lookup blockBis (memory s0) beqAddr = Some (BE bentry0Bis) ->
accessible newEntry = accessible bentry0 ->
accessible bentry0Bis = true ->
(present newEntry) = (present bentry0) ->
(startAddr (blockrange newEntry)) = (startAddr (blockrange bentry0)) ->
(endAddr (blockrange newEntry)) = newEnd ->
newEnd <= (endAddr (blockrange bentry0)) ->
blockBis <> block ->
(*noDupKSEntriesList s0 ->*)
noDupMappedBlocksList s0 ->
(forall addr', In addr' (getAllPaddrBlock newEnd (endAddr (blockrange bentry0)))
              -> In addr' (getAllPaddrAux [blockBis] s0)) ->
In block (getMappedBlocks partition s0) ->
In blockBis (getAccessibleMappedBlocks partition s0) ->
In addr
(getAccessibleMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}) <->
In addr (getAllPaddrBlock (startAddr (blockrange bentry0Bis)) (endAddr (blockrange bentry0Bis))
          ++ getAccessibleMappedPaddr partition s0).
Proof.
set (s := {|
            currentPartition := currentPartition s0;
            memory := _ |}).
intros HpartIsPDT HlookupBlocks0 HlookupBlockBiss0 HaccessBis HaccessEq HpresentEq HstartEq HnewEnd
    HnewEndIsLower HbeqBlocks HnoDup HaddrRedund HblockMapped HblockBisAccMapped.
specialize(HnoDup partition HpartIsPDT). unfold getAccessibleMappedPaddr.
assert(HgetAccMappedEq: getAccessibleMappedBlocks partition s = getAccessibleMappedBlocks partition s0).
{
  unfold s. apply getAccessibleMappedBlocksEqBEAccessiblePresentNoChange with bentry0; assumption.
}
rewrite HgetAccMappedEq. unfold getAccessibleMappedBlocks. unfold getAccessibleMappedBlocks in HblockBisAccMapped.
destruct (lookup partition (memory s0) beqAddr) eqn:HlookupPart; try(exfalso; simpl in *; congruence).
destruct v; try(exfalso; simpl in *; congruence).
induction (getMappedBlocks partition s0); try(exfalso; simpl in *; congruence).
simpl in HblockMapped. simpl in HblockBisAccMapped. apply NoDup_cons_iff in HnoDup.
destruct HnoDup as (HaNotInList & HnoDupRec). destruct HblockMapped as [HaIsBlock | HblockMappedRec].
- subst a. rewrite HlookupBlocks0 in HblockBisAccMapped.
  assert(HblockBisAccMappedRec: In blockBis (filterAccessible l s0)).
  {
    destruct (accessible bentry0).
    - simpl in HblockBisAccMapped.
      destruct HblockBisAccMapped as [HblockEq | HblockBisAccMappedRec]; try(exfalso; congruence). assumption.
    - assumption.
  }
  simpl. rewrite HlookupBlocks0.
  assert(HgetAllPaddrEq: getAllPaddrAux (filterAccessible l s0) s = getAllPaddrAux (filterAccessible l s0) s0).
  {
    unfold s. apply getAllPaddrAuxEqBENoInList. apply NotInListNotInFilterAccessible. assumption.
  }
  destruct (accessible bentry0); try(rewrite HgetAllPaddrEq; split; intro Hside;
                                    try(apply in_app_or in Hside; destruct Hside as [Hres | Hside];
                                        try(assumption); apply blockIsMappedAddrInPaddrList with blockBis;
                                        try(assumption); simpl; rewrite HlookupBlockBiss0; rewrite app_nil_r;
                                        assumption);
                                    apply in_or_app; right; assumption).
  simpl in HblockBisAccMapped. simpl. rewrite beqAddrTrue. rewrite HlookupBlocks0. rewrite HstartEq.
  rewrite HnewEnd. rewrite HgetAllPaddrEq. split.
  + intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds. right. apply in_or_app.
    destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(right; assumption). left.
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    apply getAllPaddrBlockIncl; lia.
  + intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
    destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0];
        try(right; apply blockIsMappedAddrInPaddrList with blockBis; try(assumption); simpl;
            rewrite HlookupBlockBiss0; rewrite app_nil_r; assumption). apply in_app_or in HaddrMappeds0.
    destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(right; assumption).
    apply getAllPaddrBlockInclRev in HedgeCase. destruct HedgeCase as (HaboveStart & HbelowEnd & HblockNotEmpty).
    destruct (PeanoNat.Nat.ltb addr (endAddr (blockrange newEntry))) eqn:HltAddrEnd.
    * apply PeanoNat.Nat.ltb_lt in HltAddrEnd. left. apply getAllPaddrBlockIncl; try(rewrite <-HnewEnd); lia.
    * apply PeanoNat.Nat.ltb_ge in HltAddrEnd. right.
      assert(HaddrInBlockBis: In addr (getAllPaddrAux [blockBis] s0)).
      { apply HaddrRedund. apply getAllPaddrBlockIncl; try(rewrite <-HnewEnd); lia. }
      apply blockIsMappedAddrInPaddrList with blockBis; assumption.
- simpl. specialize(IHl HnoDupRec HblockMappedRec).
  destruct (lookup a (memory s0) beqAddr) eqn:HlookupA; try(apply IHl; assumption).
  destruct v; try(apply IHl; assumption). destruct (accessible b); try(apply IHl; assumption). simpl.
  simpl in HblockBisAccMapped. rewrite HlookupA.
  destruct HblockBisAccMapped as [HaIsBlockBis | HblockBisMappedRec].
  + subst a. rewrite beqAddrFalse in HbeqBlocks. rewrite beqAddrSym in HbeqBlocks. rewrite HbeqBlocks.
    rewrite <-beqAddrFalse in HbeqBlocks. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupBlockBiss0. subst newEnd. rewrite HlookupBlockBiss0 in HlookupA. injection HlookupA as Hbeq.
    subst b.
    assert(Hs: s = {|
                     currentPartition := currentPartition s0;
                     memory := add block (BE newEntry) (memory s0) beqAddr
                   |}) by (unfold s; reflexivity). specialize(HaddrRedund addr). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply in_or_app. right.
      (*assert(HgetPaddrEq: getAllPaddrAux (filterAccessible l s0) s = getAllPaddrAux (filterAccessible l s0) s0).
      {
        apply getAllPaddrAuxEqBENoInList.
      }*)
      destruct (accessible bentry0) eqn:Haccess.
      -- revert HaddrMappeds0.
         apply getAllPaddrBlockEqBEEndLowerRev with block blockBis bentry0 newEntry bentry0Bis; try(assumption).
         apply NotInListNotInFilterAccessible; assumption.
         apply accessibleIsInFilterAccessible with bentry0; assumption.
         apply NoDupFilterAccessible; assumption.
      -- assert(HgetPaddrEq: getAllPaddrAux (filterAccessible l s0) s
                             = getAllPaddrAux (filterAccessible l s0) s0).
         {
           apply getAllPaddrAuxEqBENoInList. apply NotAccNotInFilterAccessible with bentry0; assumption.
         }
         rewrite HgetPaddrEq in HaddrMappeds0. assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption).
      apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption).
      destruct (accessible bentry0) eqn:Haccess.
      -- assert(HaNotInAccList: ~ In blockBis (filterAccessible l s0)).
         { apply NotInListNotInFilterAccessible. assumption. }
         assert(HblockAccMappedRec: In block (filterAccessible l s0)).
         { apply accessibleIsInFilterAccessible with bentry0; assumption. }
         assert(HnoDupAccRec: NoDup (filterAccessible l s0)).
         { apply NoDupFilterAccessible; assumption. }
         pose proof (getAllPaddrBlockEqBEEndLower addr s0 s (filterAccessible l s0) block blockBis bentry0 newEntry
               bentry0Bis Hs HlookupBlocks0 HlookupBlockBiss0 HstartEq HnewEndIsLower HaNotInAccList
               HblockAccMappedRec HnoDupAccRec HaddrRedund HaddrMappeds0) as Hres. apply in_app_or in Hres.
         assumption.
      -- assert(HgetPaddrEq: getAllPaddrAux (filterAccessible l s0) s
                             = getAllPaddrAux (filterAccessible l s0) s0).
         {
           apply getAllPaddrAuxEqBENoInList. apply NotAccNotInFilterAccessible with bentry0; assumption.
         }
         rewrite HgetPaddrEq. right. assumption.
  + specialize(IHl HblockBisMappedRec).
    destruct (beqAddr block a) eqn:HbeqaBlock.
    { rewrite <-DTL.beqAddrTrue in HbeqaBlock. subst a. exfalso; congruence. }
    rewrite <-beqAddrFalse in HbeqaBlock. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
    rewrite HlookupA. destruct IHl as (Hleft & Hright). split.
    * intro HaddrMappeds. apply in_or_app. apply in_app_or in HaddrMappeds.
      destruct HaddrMappeds as [HedgeCase | HaddrMappeds0]; try(right; apply in_or_app; left; assumption).
      specialize(Hleft HaddrMappeds0). apply in_app_or in Hleft.
      destruct Hleft as [Hleftleft | Hleftright]; try(left; assumption). right. apply in_or_app. right.
      assumption.
    * intro HaddrMappeds0. apply in_or_app. apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(right; apply Hright; apply in_or_app; left;
          assumption). apply in_app_or in HaddrMappeds0.
      destruct HaddrMappeds0 as [HedgeCase | HaddrMappeds0]; try(left; assumption). right. apply Hright.
      apply in_or_app. right. assumption.
Qed.

Lemma blockInclImpliesAddrIncl s:
blockInChildHasAtLeastEquivalentBlockInParent s
-> wellFormedBlock s
-> childPaddrIsIntoParent s.
Proof.
intros HblockIncl HwellFormed. unfold blockInChildHasAtLeastEquivalentBlockInParent in HblockIncl.
unfold childPaddrIsIntoParent. intros parent child addr HparentIsPart HchildIsChild HaddrMappedInChild.
apply mappedAddrIsInMappedBlock in HaddrMappedInChild.
destruct HaddrMappedInChild as [block (HblockIsMappedChild & HaddrInBlock)].
assert(HlookupBlock: exists bentry, lookup block (memory s) beqAddr = Some(BE bentry) /\ present bentry = true).
{ apply mappedBlockIsBE with child; assumption. }
destruct HlookupBlock as [bentry (HlookupBlock & Hpresent)].
assert(HstartBlock: bentryStartAddr block (startAddr (blockrange bentry)) s).
{ unfold bentryStartAddr. rewrite HlookupBlock. reflexivity. }
assert(HendBlock: bentryEndAddr block (endAddr (blockrange bentry)) s).
{ unfold bentryEndAddr. rewrite HlookupBlock. reflexivity. }
assert(HPFlag: bentryPFlag block true s).
{
  unfold bentryPFlag. rewrite HlookupBlock. intuition.
}
specialize(HblockIncl parent child block (startAddr (blockrange bentry)) (endAddr (blockrange bentry))
            HparentIsPart HchildIsChild HblockIsMappedChild HstartBlock HendBlock HPFlag).
destruct HblockIncl as [blockParent [startParent [endParent (HblockParentIsMapped & HstartBlockParent &
                        HendBlockParent & HstartIsLower & HendIsHigher)]]].
apply addrInBlockIsMapped with blockParent; try(assumption). simpl.
assert(HlookupBlockParent: exists bentryParent, lookup blockParent (memory s) beqAddr = Some(BE bentryParent)
                                                /\ present bentryParent = true).
{ apply mappedBlockIsBE with parent; assumption. }
destruct HlookupBlockParent as [bentryParent (HlookupBlockParent & _)]. rewrite HlookupBlockParent.
rewrite app_nil_r.
simpl in HaddrInBlock. rewrite HlookupBlock in HaddrInBlock. rewrite app_nil_r in HaddrInBlock.
unfold bentryStartAddr in HstartBlockParent. unfold bentryEndAddr in HendBlockParent.
rewrite HlookupBlockParent in *. subst startParent. subst endParent.
unfold getAllPaddrBlock in *.
assert(startAddr (blockrange bentry) <= endAddr (blockrange bentry)).
{
  specialize(HwellFormed block (startAddr (blockrange bentry)) (endAddr (blockrange bentry)) HPFlag HstartBlock
      HendBlock). destruct HwellFormed as [HwellDefined _]. lia.
}
assert(HstartBlockParent: bentryStartAddr blockParent (startAddr (blockrange bentryParent)) s).
{ unfold bentryStartAddr. rewrite HlookupBlockParent. reflexivity. }
assert(HendBlockParent: bentryEndAddr blockParent (endAddr (blockrange bentryParent)) s).
{ unfold bentryEndAddr. rewrite HlookupBlockParent. reflexivity. }
assert(startAddr (blockrange bentryParent) <= endAddr (blockrange bentryParent)).
{
  assert(HPFlagParent: bentryPFlag blockParent true s).
  {
    assert(HbockPresent: In blockParent (filterOptionPaddr (getKSEntries parent s))
                          /\ bentryPFlag blockParent true s)
          by (apply InFilterPresentInListAndPresent; assumption). intuition.
  }
  specialize(HwellFormed blockParent (startAddr (blockrange bentryParent)) (endAddr (blockrange bentryParent))
      HPFlagParent HstartBlockParent HendBlockParent). destruct HwellFormed as [HwellDefined _]. lia.
}
apply addrInAllPaddrBlockAuxIncl with (startAddr (blockrange bentry)) (endAddr (blockrange bentry));
      assumption.
Qed.

(*Lemma isListOfKernelsEqBE kernList partition addr newEntry s0:
isListOfKernels kernList partition {|
					                           currentPartition := currentPartition s0;
					                           memory := add addr (BE newEntry) (memory s0) beqAddr
                                   |}
-> isListOfKernels kernList partition s0.
Proof.
destruct kernList as [ | kern nextKernList]; simpl.
- (* kernList = [] *)
  simpl. intuition.
- (* kernList = a::l *)
  simpl. intros HisKernLists1.
  destruct HisKernLists1 as [pdentry (HlookupPart & HstructNotNull & Hstruct & HindProp)].
  destruct (beqAddr addr partition) eqn:HbeqAddrPart; try(exfalso; congruence).
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HlookupPart; intuition.
  exists pdentry. intuition. clear Hstruct. clear HbeqAddrPart. revert HindProp. revert kern.
  induction nextKernList.
  + (* nextKernList = [] *)
    simpl. intuition.
  + (* nextKernList = a::l *)
    simpl. intros kern HpropsInd.
    destruct HpropsInd as [HlookupNextOffset (HaNotNull & HpropsInd)].
    destruct (beqAddr addr (CPaddr (kern + nextoffset))) eqn:HbeqAddNextKern; try(exfalso; congruence).
    rewrite <-beqAddrFalse in HbeqAddNextKern. rewrite removeDupIdentity in HlookupNextOffset; intuition.
Qed.*)

Lemma removeBlockFromPhysicalMPUAuxIncl block removedBlock MPU:
In block (MAL.removeBlockFromPhysicalMPUAux removedBlock MPU)
-> In block MPU.
Proof.
induction MPU.
- (* MPU = [] *)
  simpl. intuition.
- (* MPU = a::l *)
  intro HblockInNewMPU. simpl in HblockInNewMPU. destruct (beqAddr a removedBlock) eqn:HbeqElRemoved.
  + (* a = removedBlock *)
    simpl. right. assumption.
  + (* a <> removedBlock *)
    simpl in *. destruct HblockInNewMPU as [HaIsBlock | HblockInMPU].
    * left. assumption.
    * right. apply IHMPU. assumption.
Qed.

Lemma removeBlockFromPhysicalMPUAuxLenEq removedBlock MPU:
length (MAL.removeBlockFromPhysicalMPUAux removedBlock MPU) <= length MPU.
Proof.
induction MPU.
- (* MPU = [] *)
  simpl. lia.
- (* MPU = a::l *)
  simpl. destruct (beqAddr a removedBlock) eqn:HbeqElRemoved.
  + (* a = removedBlock *)
    simpl. lia.
  + (* a <> removedBlock *)
    simpl. lia.
Qed.

Lemma mappedBlocksEqStartEq block1 block2 partition start s:
noDupUsedPaddrList s
-> wellFormedBlock s
-> isPDT partition s
-> In block1 (getMappedBlocks partition s)
-> bentryStartAddr block1 start s
-> bentryPFlag block1 true s
-> In block2 (getMappedBlocks partition s)
-> bentryStartAddr block2 start s
-> bentryPFlag block2 true s
-> block1 = block2.
Proof.
intros HnoDup HwellFormed HpartIsPDT Hblock1Mapped Hstart1 HPFlag1 Hblock2Mapped Hstart2 HPFlag2.
destruct (beqAddr block1 block2) eqn:HbeqBlocks.
{ rewrite <-DTL.beqAddrTrue in HbeqBlocks. assumption. }
exfalso. rewrite <-beqAddrFalse in HbeqBlocks. specialize(HnoDup partition HpartIsPDT).
unfold getUsedPaddr in HnoDup. apply Lib.NoDupSplit in HnoDup. destruct HnoDup as [_ HnoDup].
unfold getMappedPaddr in HnoDup. induction (getMappedBlocks partition s).
{ simpl in Hblock1Mapped; congruence. }
simpl in *. destruct Hblock1Mapped as [HaIsBlock | Hblock1Rec].
- subst a. destruct Hblock2Mapped as [Hcontra | Hblock2Rec]; try(congruence).
  unfold bentryStartAddr in Hstart1.
  destruct (lookup block1 (memory s) beqAddr) eqn:HlookupBlock1; try(congruence). destruct v; try(congruence).
  apply Lib.NoDupSplitInclIff in HnoDup. destruct HnoDup as [_ Hdisjoint].
  unfold Lib.disjoint in Hdisjoint.
  (*might be interesting to put that in a separate lemma too*)
  assert(HentryInPaddrBlock: In (startAddr (blockrange b))
                                (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))).
  {
    assert(Hend: bentryEndAddr block1 (endAddr (blockrange b)) s).
    { unfold bentryEndAddr. rewrite HlookupBlock1. reflexivity. }
    assert(Hstart1Bis: bentryStartAddr block1 (startAddr (blockrange b)) s).
    { unfold bentryStartAddr. rewrite HlookupBlock1. reflexivity. }
    specialize(HwellFormed block1 (startAddr (blockrange b)) (endAddr (blockrange b)) HPFlag1
                Hstart1Bis Hend).
    destruct HwellFormed as [HwellFormed _]. clear Hend. clear Hdisjoint.
    unfold getAllPaddrBlock.
    assert(HwellFormedblock: 0 < endAddr (blockrange b) - (startAddr (blockrange b))) by lia.
    induction (endAddr (blockrange b) - (startAddr (blockrange b))).
    - exfalso; lia.
    - simpl. assert(HvalidPaddr: (startAddr (blockrange b)) <= maxAddr) by (apply Hp).
      destruct (Compare_dec.le_dec (startAddr (blockrange b)) maxAddr); try(lia). simpl. left.
      destruct (startAddr (blockrange b)). simpl.
      replace l0 with Hp. reflexivity. apply proof_irrelevance.
  }
  specialize(Hdisjoint (startAddr (blockrange b)) HentryInPaddrBlock). rewrite <-Hstart1 in *.
  assert(Hcontra: In start (getAllPaddrAux l s)).
  {
    clear Hdisjoint. clear IHl. induction l; intuition. simpl in *.
    destruct Hblock2Rec as [HsecondIsBlock2 | Hblock2Rec].
    - subst a. unfold bentryStartAddr in Hstart2.
      destruct (lookup block2 (memory s) beqAddr) eqn:HlookupBlock2; try(exfalso; congruence).
      destruct v; try(exfalso; congruence). apply in_or_app. left.
      assert(Hend: bentryEndAddr block2 (endAddr (blockrange b0)) s).
      { unfold bentryEndAddr. rewrite HlookupBlock2. reflexivity. }
      assert(Hstart2Bis: bentryStartAddr block2 (startAddr (blockrange b0)) s).
      { unfold bentryStartAddr. rewrite HlookupBlock2. reflexivity. }
      specialize(HwellFormed block2 (startAddr (blockrange b0)) (endAddr (blockrange b0))
                  HPFlag2 Hstart2Bis Hend).
      destruct HwellFormed as [HwellFormed _]. clear Hend.
      unfold getAllPaddrBlock.
      assert(HwellFormedblock: 0 < endAddr (blockrange b0) - (startAddr (blockrange b0))) by lia.
      induction (endAddr (blockrange b0) - (startAddr (blockrange b0))).
      + exfalso; lia.
      + simpl. assert(HvalidPaddr: (startAddr (blockrange b0)) <= maxAddr) by (apply Hp).
        destruct (Compare_dec.le_dec (startAddr (blockrange b0)) maxAddr); try(lia). simpl. left.
        rewrite Hstart2. destruct (startAddr (blockrange b0)). simpl.
        replace l0 with Hp. reflexivity. apply proof_irrelevance.
    - destruct (lookup a (memory s) beqAddr); try(apply IHl; assumption).
      destruct v; try(apply IHl; assumption). apply in_or_app. right. apply IHl. assumption.
  }
  congruence.
- destruct Hblock2Mapped as [HfirstIsBlock2 | Hblock2Rec].
  * subst a. simpl in HnoDup. unfold bentryStartAddr in Hstart2.
    destruct (lookup block2 (memory s) beqAddr) eqn:HlookupBlock2; try(exfalso; congruence).
    destruct v; try(exfalso; congruence). apply Lib.NoDupSplitInclIff in HnoDup.
    destruct HnoDup as [_ Hdisjoint]. unfold Lib.disjoint in Hdisjoint.
    (*might be interesting to put that in a separate lemma too*)
    assert(HentryInPaddrBlock: In (startAddr (blockrange b))
                                  (getAllPaddrBlock (startAddr (blockrange b)) (endAddr (blockrange b)))).
    {
      assert(Hend: bentryEndAddr block2 (endAddr (blockrange b)) s).
      { unfold bentryEndAddr. rewrite HlookupBlock2. reflexivity. }
      assert(HstartBis: bentryStartAddr block2 (startAddr (blockrange b)) s).
      { unfold bentryStartAddr. rewrite HlookupBlock2. reflexivity. }
      specialize(HwellFormed block2 (startAddr (blockrange b)) (endAddr (blockrange b)) HPFlag2 HstartBis Hend).
      destruct HwellFormed as [HwellFormed _]. clear Hend. clear Hdisjoint.
      unfold getAllPaddrBlock.
      assert(HwellFormedblock: 0 < endAddr (blockrange b) - (startAddr (blockrange b))) by lia.
      induction (endAddr (blockrange b) - (startAddr (blockrange b))).
      - exfalso; lia.
      - simpl. assert(HvalidPaddr: (startAddr (blockrange b)) <= maxAddr) by (apply Hp).
        destruct (Compare_dec.le_dec (startAddr (blockrange b)) maxAddr); try(lia). simpl. left.
        destruct (startAddr (blockrange b)). simpl.
        replace l0 with Hp. reflexivity. apply proof_irrelevance.
    }
    specialize(Hdisjoint (startAddr (blockrange b)) HentryInPaddrBlock). rewrite <-Hstart2 in *.
    assert(Hcontra: In start (getAllPaddrAux l s)).
    {
      clear Hdisjoint. clear IHl. induction l; intuition. simpl in *.
      destruct Hblock1Rec as [HsecondIsBlock | HblockRec].
      - subst a. unfold bentryStartAddr in Hstart1.
        destruct (lookup block1 (memory s) beqAddr) eqn:HlookupBlock1; try(exfalso; congruence).
        destruct v; try(exfalso; congruence). apply in_or_app. left.
        assert(Hend: bentryEndAddr block1 (endAddr (blockrange b0)) s).
        { unfold bentryEndAddr. rewrite HlookupBlock1. reflexivity. }
        assert(HstartBis: bentryStartAddr block1 (startAddr (blockrange b0)) s).
        { unfold bentryStartAddr. rewrite HlookupBlock1. reflexivity. }
        specialize(HwellFormed block1 (startAddr (blockrange b0)) (endAddr (blockrange b0))
                    HPFlag1 HstartBis Hend).
        destruct HwellFormed as [HwellFormed _]. clear Hend.
        unfold getAllPaddrBlock.
        assert(HwellFormedblock: 0 < endAddr (blockrange b0) - (startAddr (blockrange b0))) by lia.
        induction (endAddr (blockrange b0) - (startAddr (blockrange b0))).
        + exfalso; lia.
        + simpl. assert(HvalidPaddr: (startAddr (blockrange b0)) <= maxAddr) by (apply Hp).
          destruct (Compare_dec.le_dec (startAddr (blockrange b0)) maxAddr); try(lia). simpl. left.
          rewrite Hstart1. destruct (startAddr (blockrange b0)). simpl.
          replace l0 with Hp. reflexivity. apply proof_irrelevance.
      - destruct (lookup a (memory s) beqAddr); try(apply IHl; assumption).
        destruct v; try(apply IHl; assumption). apply in_or_app. right. apply IHl. assumption.
    }
    congruence.
  * simpl in HnoDup.
    destruct (lookup a (memory s) beqAddr); try(apply IHl; intuition).
    destruct v; try(intuition). apply Lib.NoDupSplit in HnoDup. intuition.
Qed.

Lemma addrInBlockNotAccIsNotAcc addr block bentry partition s:
noDupUsedPaddrList s
-> isPDT partition s
-> In addr (getAllPaddrAux [block] s)
-> lookup block (memory s) beqAddr = Some(BE bentry)
-> accessible bentry = false
-> In block (getMappedBlocks partition s)
-> ~In addr (getAccessibleMappedPaddr partition s).
Proof.
intros HnoDup HpartIsPDT HaddrInBlock HlookupBlock HblockNotAcc HblockMapped HaddrAcc.
specialize(HnoDup partition HpartIsPDT). unfold getUsedPaddr in HnoDup.
apply Lib.NoDupSplit in HnoDup. destruct HnoDup as [_ HnoDup]. unfold getMappedPaddr in HnoDup.
unfold getAccessibleMappedPaddr in HaddrAcc. unfold getAccessibleMappedBlocks in HaddrAcc.
destruct (lookup partition (memory s) beqAddr); try(simpl in HaddrAcc; congruence).
destruct v; try(simpl in HaddrAcc; congruence).
induction (getMappedBlocks partition s).
- simpl in HaddrAcc. congruence.
- simpl in *. destruct HblockMapped as [HaBlockEq | Hrec].
  + subst a. rewrite HlookupBlock in *. rewrite app_nil_r in HaddrInBlock. rewrite HblockNotAcc in HaddrAcc.
    apply Lib.NoDupSplitInclIff in HnoDup. destruct HnoDup as [(_ & HnoDupRec) HdisjointPaddr].
    specialize(HdisjointPaddr addr HaddrInBlock).
    apply NotInPaddrListNotInPaddrFilterAccessibleContra in HaddrAcc. congruence.
  + rewrite HlookupBlock in HaddrInBlock. rewrite app_nil_r in HaddrInBlock.
    destruct (lookup a (memory s) beqAddr) eqn:HlookupA; try(intuition; congruence).
    destruct v; try(intuition; congruence).
    apply Lib.NoDupSplitInclIff in HnoDup. destruct HnoDup as [(_ & HnoDupRec) HdisjointPaddr].
    destruct (accessible b) eqn:HaccessB; try(intuition; congruence).
    simpl in HaddrAcc. rewrite HlookupA in HaddrAcc. apply in_app_or in HaddrAcc.
    destruct HaddrAcc as [HaddrInA | HaddrAccRec]; try(intuition; congruence).
    specialize(HdisjointPaddr addr HaddrInA).
    assert(Hcontra: In addr (getAllPaddrAux l s)).
    {
      apply blockIsMappedAddrInPaddrList with block; try(assumption). simpl. rewrite HlookupBlock.
      rewrite app_nil_r. assumption.
    }
    congruence.
Qed.

(** Properties of isParentsList **)

Lemma isParentsListRec s0 pdbasepartition partition pdentryParent pdentryPart pdparent parentsList:
isParentsList s0 parentsList pdbasepartition
-> partition = last parentsList pdbasepartition
-> partition <> constantRootPartM
-> lookup pdparent (memory s0) beqAddr = Some(PDT pdentryParent)
-> lookup partition (memory s0) beqAddr = Some(PDT pdentryPart)
-> pdparent = parent pdentryPart
-> isParentsList s0 (parentsList ++ [pdparent]) pdbasepartition.
Proof.
revert pdbasepartition. induction parentsList.
- (* parentsList = [] *)
  simpl. intros pdbasepartition Htriv HbeqPartBase HpartNotRoot HlookupParent HlookupPart Hparent.
  rewrite HlookupParent. rewrite HbeqPartBase in *. intuition. exists pdentryPart. intuition.
- (* parentsList = a::l *)
  simpl. intros pdbasepartition HisParentsList HpartIsLast HpartNotRoot HlookupParent HlookupPart Hparent.
  destruct (lookup a (memory s0) beqAddr); try(exfalso; congruence).
  destruct v; try(exfalso; congruence). destruct HisParentsList as [HbaseNotRoot (HlookupBase & HisParentsList)].
  intuition.
  assert(HparentIsLast: partition = last parentsList a).
  {
    destruct parentsList.
    + simpl. assumption.
    + apply lastNotEmpty with pdbasepartition. assumption.
  }
  specialize(IHparentsList a HisParentsList HparentIsLast HpartNotRoot HlookupParent HlookupPart Hparent).
  assumption.
Qed.

Lemma isParentsListEqBERev partition addr' newEntry bentry0 parentsList s0:
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
parentOfPartitionIsPartition s0 ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (BE newEntry) (memory s0) beqAddr
              |} parentsList partition
-> isParentsList s0 parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HpartIsPDTs0 HaddrIsBEs0 HparentOfPart0. revert HpartIsPDTs0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs0 HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA; try(exfalso; congruence).
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity in HparentsLists1; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsBEs0 in HpartIsPDTs0.
    destruct HpartIsPDTs0 as [pdentry0 HpartIsPDTs0]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HlookupParts0; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqSCERev partition addr' newEntry scentry0 parentsList s0:
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
lookup addr' (memory s0) beqAddr = Some (SCE scentry0) ->
parentOfPartitionIsPartition s0 ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (SCE newEntry) (memory s0) beqAddr
              |} parentsList partition
-> isParentsList s0 parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HpartIsPDTs0 HaddrIsSCEs0 HparentOfPart0. revert HpartIsPDTs0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs0 HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA; try(exfalso; congruence).
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity in HparentsLists1; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsSCEs0 in HpartIsPDTs0.
    destruct HpartIsPDTs0 as [pdentry0 HpartIsPDTs0]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HlookupParts0; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqSHERev partition addr' newEntry shentry0 parentsList s0:
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
lookup addr' (memory s0) beqAddr = Some (SHE shentry0) ->
parentOfPartitionIsPartition s0 ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (SHE newEntry) (memory s0) beqAddr
              |} parentsList partition
-> isParentsList s0 parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HpartIsPDTs0 HaddrIsSHEs0 HparentOfPart0. revert HpartIsPDTs0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs0 HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA; try(exfalso; congruence).
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity in HparentsLists1; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsSHEs0 in HpartIsPDTs0.
    destruct HpartIsPDTs0 as [pdentry0 HpartIsPDTs0]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HlookupParts0; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqPADDRRev partition addr' newEntry paddrentry0 parentsList s0:
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
lookup addr' (memory s0) beqAddr = Some (PADDR paddrentry0) ->
parentOfPartitionIsPartition s0 ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (PADDR newEntry) (memory s0) beqAddr
              |} parentsList partition
-> isParentsList s0 parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HpartIsPDTs0 HaddrIsPADDRs0 HparentOfPart0. revert HpartIsPDTs0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs0 HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA; try(exfalso; congruence).
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity in HparentsLists1; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsPADDRs0 in HpartIsPDTs0.
    destruct HpartIsPDTs0 as [pdentry0 HpartIsPDTs0]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity in HlookupParts0; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqPDTSameParent partition addr newEntry parentsList s0 s1:
s1 = {|
       currentPartition := currentPartition s0;
       memory := add addr (PDT newEntry) (memory s0) beqAddr
     |} ->
(exists pdentry0 pdentry1 pdentryAddr,
                lookup partition (memory s0) beqAddr = Some (PDT pdentry0)
                /\ lookup partition (memory s1) beqAddr = Some (PDT pdentry1)
                /\ lookup addr (memory s0) beqAddr = Some(PDT pdentryAddr)
                /\ parent newEntry = parent pdentryAddr
                /\ (partition <> addr -> pdentry1 = pdentry0)
                /\ (partition = addr -> pdentry1 = newEntry /\ parent newEntry = parent pdentry0)) ->
parentOfPartitionIsPartition s0 ->
isParentsList s1 parentsList partition
-> isParentsList s0 parentsList partition.
Proof.
revert partition. induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition Hs1 HpartIsPDT HparentIsPart HparentsLists1.
  destruct HpartIsPDT as [pdentry [pdentry1 [pdentryAddr (HlookupParts0 & HlookupParts1 & HlookupAddrs0 &
                            HparentsAddrEq & HentriessEq & HparentsEq)]]].
  rewrite Hs1 in HparentsLists1. simpl in HparentsLists1.
  destruct (beqAddr addr a) eqn:HbeqAddrA.
  + (* addr = a *)
    destruct HparentsLists1 as [HpartNotRoot ((pdentry0 & (HpdentryEq & Ha)) & HparentsLists1)].
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. rewrite HbeqAddrA in *.
    destruct (beqAddr a partition) eqn:HbeqAPart.
    * (* a = partition *)
      rewrite <-DTL.beqAddrTrue in HbeqAPart. rewrite HbeqAPart in *. rewrite HlookupParts0.
      split. assumption. injection HpdentryEq as HnewEntry. subst pdentry0. split. exists pdentry. split.
      reflexivity. assert(Htriv: partition = partition) by reflexivity.
      specialize(HparentsEq Htriv). destruct HparentsEq as [HnewEntriessEq HparentsEq]. rewrite HparentsEq in Ha.
      assumption. rewrite <-Hs1 in HparentsLists1. apply IHparentsList; try(assumption).
      exists pdentry. exists pdentry1. exists pdentryAddr. intuition.
    * (* a <> partition *)
      rewrite <-beqAddrFalse in HbeqAPart. rewrite removeDupIdentity in HpdentryEq; intuition.
      assert(pdentry0 = pdentry).
      {
        rewrite HpdentryEq in HlookupParts0. injection HlookupParts0 as Heq. assumption.
      }
      subst pdentry0. subst a. subst pdentry1. subst addr.
      assert(parentOfPartitionIsPartition s0) by assumption.
      unfold parentOfPartitionIsPartition in HparentIsPart.
      specialize(HparentIsPart partition pdentry HlookupParts0).
      destruct HparentIsPart as [HparentOfPart _]. specialize(HparentOfPart HpartNotRoot).
      destruct HparentOfPart as ([parentEntry HparentOfPart] & _). rewrite HparentOfPart.
      split. assumption.
      split. exists pdentry. split. assumption. reflexivity.
      apply IHparentsList; try(assumption); try(rewrite Hs1); try(assumption).
      exists parentEntry. exists newEntry. exists pdentryAddr. split. assumption. split. simpl. rewrite beqAddrTrue.
      reflexivity. split. assumption. split. assumption. split. intro. exfalso. congruence. intro. split. reflexivity.
      rewrite HparentsAddrEq. rewrite HparentOfPart in HlookupAddrs0. injection HlookupAddrs0 as HpdentriesEq.
      subst parentEntry. reflexivity.
  + (* addr <> a *)
    rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity in HparentsLists1; intuition.
    destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
    destruct (beqAddr addr partition) eqn:HbeqAddrPart.
    * (* addr = partition *)
      rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *.
      destruct HparentsLists1 as [HpartNotRoot ((pdentry0 & (HpdentryEq & Ha)) & HparentsLists1)].
      injection HpdentryEq as Hentry. subst pdentry0. split. assumption. split. exists pdentry.
      split. assumption. assert(Htriv: partition = partition) by intuition.
      specialize(HparentsEq Htriv). destruct HparentsEq as [HnewEntriessEq HparentsEq]. rewrite HparentsEq in Ha.
      assumption. rewrite Ha in *.
      assert(Htriv: partition = partition) by intuition. specialize(HparentsEq Htriv).
      destruct HparentsEq as [HnewEntriessEq HparentsEq]. rewrite HparentsEq in *.
      assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry) (memory s0) beqAddr
                                                = Some (PDT parentEntry)).
      {
        unfold parentOfPartitionIsPartition in HparentIsPart.
        specialize(HparentIsPart partition pdentry HlookupParts0).
        destruct HparentIsPart as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
        intuition.
      }
      destruct HparentIsPDT as [parentEntry HlookupParents0].
      assert(HlookupParents1: lookup (parent pdentry) (memory s1) beqAddr = Some (PDT parentEntry)).
      {
        rewrite Hs1. simpl.
        assert(HbeqPartParent: beqAddr partition (parent pdentry) = false)
                by (rewrite <-beqAddrFalse; intuition).
        rewrite HbeqPartParent. rewrite removeDupIdentity; intuition.
      }
      assert(HparentIsPDT: exists pdentry0 pdentry1 pdentryAddr : PDTable,
                   lookup (parent pdentry) (memory s0) beqAddr = Some (PDT pdentry0)
                   /\ lookup (parent pdentry) (memory s1) beqAddr = Some (PDT pdentry1)
                   /\ lookup partition (memory s0) beqAddr = Some (PDT pdentryAddr)
                   /\ parent pdentry = parent pdentryAddr
                   /\ (((parent pdentry) <> partition) -> pdentry1 = pdentry0)
                   /\ ((parent pdentry) = partition -> pdentry1 = newEntry /\ parent pdentry = parent pdentry0)).
      {
        exists parentEntry. exists parentEntry. exists pdentryAddr. split. assumption. split. assumption. split.
        assumption. split. assumption. split. intro. reflexivity. intro. exfalso; congruence.
      }
      rewrite <-Hs1 in HparentsLists1.
      specialize(IHparentsList (parent pdentry) Hs1 HparentIsPDT HparentIsPart HparentsLists1). assumption.
    * (* addr <> partition *)
      destruct HparentsLists1 as [HpartNotRoot ((pdentry0 & (HpdentryEq & Ha)) & HparentsLists1)].
      rewrite <-beqAddrFalse in HbeqAddrPart.
      rewrite removeDupIdentity in HpdentryEq; try(intuition; congruence).
      rewrite HlookupParts0 in HpdentryEq. injection HpdentryEq as Hentry. subst pdentry0. split. assumption.
      split. exists pdentry. split. assumption. assumption. subst a.
      assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry) (memory s0) beqAddr
                                                = Some (PDT parentEntry)).
      {
        unfold parentOfPartitionIsPartition in HparentIsPart.
        specialize(HparentIsPart partition pdentry HlookupParts0).
        destruct HparentIsPart as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
        intuition.
      }
      destruct HparentIsPDT as [parentEntry HlookupParents0].
      assert(HlookupParents1: lookup (parent pdentry) (memory s1) beqAddr = Some (PDT parentEntry)).
      {
        rewrite Hs1. simpl.
        assert(HbeqPartParent: beqAddr addr (parent pdentry) = false) by (rewrite <-beqAddrFalse; intuition).
        rewrite HbeqPartParent. rewrite removeDupIdentity; intuition.
      }
      specialize(IHparentsList (parent pdentry) Hs1).
      apply IHparentsList; try(assumption); try(rewrite Hs1; assumption).
      exists parentEntry. exists parentEntry. exists pdentryAddr. split. assumption. split. assumption. split.
      assumption. split. assumption. split. intro. reflexivity. intro Hcontra. exfalso; congruence.
Qed.

Lemma partInParentsListIsPartition partition parentsList pdbasepartition s:
parentOfPartitionIsPartition s
-> isParentsList s parentsList pdbasepartition
-> In partition parentsList
-> In partition (getPartitions multiplexer s).
Proof.
intro HparentIsPart. revert pdbasepartition. induction parentsList.
- simpl. intros pdbasepartition HparentsList HpartIsAncestor. exfalso; congruence.
- simpl. intros pdbasepartition HparentsList HpartIsAncestor.
  destruct (lookup a (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
  destruct HparentsList as (HbaseNotRoot & HparentBase  & HparentsList).
  destruct HpartIsAncestor as [HpartIsParent | HpartIsAncestor].
  + subst a. destruct HparentBase as [pdentry (HlookupBase & Hparent)].
    specialize(HparentIsPart pdbasepartition pdentry HlookupBase).
    destruct HparentIsPart as (HparentIsPart & _). rewrite Hparent. specialize(HparentIsPart HbaseNotRoot). intuition.
  + apply IHparentsList with a; assumption.
Qed.

Lemma parentOfPartNotInParentsListsTail pdbasepartition parentsList s :
partitionTreeIsTree s
-> parentOfPartitionIsPartition s
-> isParentsList s parentsList pdbasepartition
-> NoDup parentsList.
Proof.
intros HpartTree HparentOfPart. revert pdbasepartition. induction parentsList.
- intros. apply NoDup_nil.
- simpl. intros pdbasepartition HparentsList.
  destruct (lookup a (memory s) beqAddr) eqn:HlookupA; try(exfalso; congruence).
  destruct v; try(exfalso; congruence). destruct HparentsList as (HbaseNotRoot & [pdentry (Hlookup & Ha)] & Hrec).
  apply NoDup_cons.
  + destruct parentsList.
    * intuition.
    * simpl. apply and_not_or. assert(HparentOfPartCopy: parentOfPartitionIsPartition s) by assumption.
      specialize(HparentOfPart a p HlookupA).
      destruct HparentOfPart as (HparentIsPart & HparentOfRoot & HparentNotA).
      simpl in Hrec. destruct (lookup p0 (memory s) beqAddr); try(exfalso; congruence).
      destruct v; try(exfalso; congruence).
      destruct Hrec as (HaNotRoot & [pdentryA (HlookupABis & Hparent)] & Hrec). subst p0.
      rewrite HlookupABis in HlookupA. injection HlookupA as Hres. subst pdentryA. split. assumption.
      apply HpartTree with (parent p); try(assumption).
      specialize(HparentOfPartCopy pdbasepartition pdentry Hlookup).
      destruct HparentOfPartCopy as [HparentIsPartCopy _]. specialize(HparentIsPartCopy HbaseNotRoot).
      subst a. intuition.
      unfold pdentryParent. rewrite HlookupABis. reflexivity.
  + apply IHparentsList with a; assumption.
Qed.

Lemma parentsListCons pdbasepartition parentsList1 lastPart parentsList2 s:
parentOfPartitionIsPartition s
-> isParentsList s parentsList2 lastPart
-> isParentsList s parentsList1 pdbasepartition
-> lastPart = last parentsList1 pdbasepartition
-> isParentsList s (parentsList1++parentsList2) pdbasepartition.
Proof.
intros HparentOfPart HparentsList2. revert pdbasepartition. induction parentsList1.
- simpl. intros pdbasepartition HparentsList1 HlastPartIsLast. subst lastPart. assumption.
- intros pdbasepartition HparentsList1 HlastPartIsLast. simpl. simpl in HparentsList1.
  destruct (lookup a (memory s) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsList1 as (HbaseNotRoot & HbaseParent & HparentsList1). split. assumption. split. assumption.
  apply IHparentsList1. assumption. apply lastRec with pdbasepartition. assumption.
Qed.

Lemma basePartNotLastInParentsLists pdbasepartition parentsList lastPart s :
partitionTreeIsTree s
-> parentOfPartitionIsPartition s
-> isParentsList s parentsList pdbasepartition
-> lastPart = last parentsList pdbasepartition
-> parentsList <> []
-> pdbasepartition <> lastPart.
Proof.
intros HpartTree HparentOfPart HparentsList HlastIsLast HlistNotEmpty. intro Hcontra. subst lastPart.
assert(HparentsListRec: isParentsList s (parentsList++parentsList) pdbasepartition).
{
  apply parentsListCons with pdbasepartition; assumption.
}
assert(HnoDup: NoDup (parentsList ++ parentsList)).
{
  apply parentOfPartNotInParentsListsTail with pdbasepartition s; assumption.
}
destruct parentsList.
- intros. intuition.
- simpl in HnoDup. apply NoDup_cons_iff in HnoDup. destruct HnoDup as [HnoDup _].
  assert(In p (parentsList ++ p :: parentsList)) by apply in_elt. congruence.
Qed.

Lemma headIsParentsList headList tailList partition s:
isParentsList s (headList++tailList) partition
-> isParentsList s headList partition.
Proof.
revert partition. induction headList.
- simpl. intros. trivial.
- simpl. intros partition HparentsList. destruct (lookup a (memory s) beqAddr); try(congruence).
  destruct v; try(congruence). destruct HparentsList as (HpartNotRoot & HpartProps & Hrec).
  split. assumption. split. assumption. apply IHheadList. assumption.
Qed.


Lemma basePartNotInParentsLists pdbasepartition pdentry parentsList s :
partitionTreeIsTree s
-> parentOfPartitionIsPartition s
-> lookup pdbasepartition (memory s) beqAddr = Some(PDT pdentry)
-> isParentsList s parentsList pdbasepartition
-> ~ In pdbasepartition parentsList.
Proof.
intros HpartTree HparentOfPart HlookupBase HparentsList Hcontra. apply in_split in Hcontra.
destruct Hcontra as [headParentsList [tail Hcontra]].
destruct (beqAddr pdbasepartition constantRootPartM) eqn:HbeqBaseRoot.
{
  rewrite <-DTL.beqAddrTrue in HbeqBaseRoot. subst pdbasepartition. destruct parentsList.
  - apply eq_sym in Hcontra. apply app_eq_nil in Hcontra. destruct Hcontra. congruence.
  - simpl in HparentsList. destruct (lookup p (memory s) beqAddr) eqn:HlookupParent; try(congruence).
    destruct v; try(congruence). destruct HparentsList. congruence.
}
assert(HparentOfPartCopy: parentOfPartitionIsPartition s) by assumption.
rewrite <-beqAddrFalse in HbeqBaseRoot. specialize(HparentOfPart pdbasepartition pdentry HlookupBase).
destruct HparentOfPart as (HparentIsPart & _ & HparentNotBase). specialize(HparentIsPart HbeqBaseRoot).
destruct HparentIsPart as ([parentEntry HlookupParent] & _).
assert(HparentIsFirst: exists tailHead, headParentsList = (parent pdentry)::tailHead).
{
  destruct headParentsList.
  - exfalso. rewrite app_nil_l in Hcontra. rewrite Hcontra in HparentsList. simpl in HparentsList.
    rewrite HlookupBase in HparentsList. destruct HparentsList as (_ & [pdentry0 (HentriesEq & Hparent)] & _).
    injection HentriesEq as HpdentriesEq. subst pdentry0. rewrite Hparent in HparentNotBase. congruence.
  - exists headParentsList. f_equal. rewrite Hcontra in HparentsList. simpl in HparentsList.
    destruct (lookup p (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
    destruct HparentsList as (_ & [pdentry0 (HlookupBase0 & Hparent)] & _). rewrite HlookupBase in HlookupBase0.
    injection HlookupBase0 as HentriesEq. subst pdentry0. assumption.
}
destruct HparentIsFirst as [tailHead HparentIsFirst].
assert(HheadIsParentsList: isParentsList s (headParentsList++[pdbasepartition]) pdbasepartition).
{
  apply headIsParentsList with tail. rewrite Hcontra in HparentsList. rewrite <-app_assoc. simpl.
  assumption.
}
assert(HdoubleIsParentsList: isParentsList s ((headParentsList++[pdbasepartition])
                                              ++ headParentsList++[pdbasepartition]) pdbasepartition).
{
  apply parentsListCons with pdbasepartition; try(assumption). apply eq_sym. apply last_last.
}
assert(HnoDup: NoDup ((headParentsList++[pdbasepartition]) ++ headParentsList++[pdbasepartition])).
{
  apply parentOfPartNotInParentsListsTail with pdbasepartition s; assumption.
}
apply Lib.NoDupSplitInclIff in HnoDup. destruct HnoDup as (_ & HnoDup).
assert(HbaseInList: In pdbasepartition (headParentsList ++ [pdbasepartition])).
{
  apply in_or_app. right. simpl. left. reflexivity.
}
specialize(HnoDup pdbasepartition HbaseInList). congruence.
Qed.

Lemma isParentsListEqBE partition addr' newEntry bentry0 parentsList s0:
lookup addr' (memory s0) beqAddr = Some (BE bentry0) ->
parentOfPartitionIsPartition s0 ->
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
isParentsList s0 parentsList partition ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (BE newEntry) (memory s0) beqAddr
              |} parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HaddrIsBEs0 HparentOfPart0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA.
  {
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. subst a. rewrite HaddrIsBEs0 in HparentsLists1. congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsBEs0 in HpartIsPDTs.
    destruct HpartIsPDTs as [pdentry0 HpartIsPDTs]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqSCE partition addr' newEntry scentry0 parentsList s0:
lookup addr' (memory s0) beqAddr = Some (SCE scentry0) ->
parentOfPartitionIsPartition s0 ->
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
isParentsList s0 parentsList partition ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (SCE newEntry) (memory s0) beqAddr
              |} parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HaddrIsSCEs0 HparentOfPart0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA.
  {
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. subst a. rewrite HaddrIsSCEs0 in HparentsLists1. congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsSCEs0 in HpartIsPDTs.
    destruct HpartIsPDTs as [pdentry0 HpartIsPDTs]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqSHE partition addr' newEntry shentry0 parentsList s0:
lookup addr' (memory s0) beqAddr = Some (SHE shentry0) ->
parentOfPartitionIsPartition s0 ->
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
isParentsList s0 parentsList partition ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (SHE newEntry) (memory s0) beqAddr
              |} parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HaddrIsSHEs0 HparentOfPart0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA.
  {
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. subst a. rewrite HaddrIsSHEs0 in HparentsLists1. congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsSHEs0 in HpartIsPDTs.
    destruct HpartIsPDTs as [pdentry0 HpartIsPDTs]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma isParentsListEqPADDR partition addr' newEntry paddrentry0 parentsList s0:
lookup addr' (memory s0) beqAddr = Some (PADDR paddrentry0) ->
parentOfPartitionIsPartition s0 ->
(exists pdentry, lookup partition (memory s0) beqAddr = Some (PDT pdentry)) ->
isParentsList s0 parentsList partition ->
isParentsList {|
						    currentPartition := currentPartition s0;
						    memory := add addr' (PADDR newEntry) (memory s0) beqAddr
              |} parentsList partition.
Proof.
set (s':= {|
            currentPartition := currentPartition s0;
            memory := _
          |}).
intros HaddrIsPADDRs0 HparentOfPart0. revert partition.
induction parentsList.
- (* parentsList = [] *)
  simpl. intros. trivial.
- (* parentsList = a::l *)
  simpl. intros partition HpartIsPDTs HparentsLists1.
  destruct (beqAddr addr' a) eqn:HbeqAddrA.
  {
    rewrite <-DTL.beqAddrTrue in HbeqAddrA. subst a. rewrite HaddrIsPADDRs0 in HparentsLists1. congruence.
  }
  rewrite <-beqAddrFalse in HbeqAddrA. rewrite removeDupIdentity; intuition.
  destruct (lookup a (memory s0) beqAddr); try(congruence). destruct v; try(congruence).
  destruct HparentsLists1 as [HpartNotRoot (HlookupParts0 & HparentsLists1)]. split. assumption.
  destruct (beqAddr addr' partition) eqn:HbeqAddrPart.
  { (* addr' = partition *)
    rewrite <-DTL.beqAddrTrue in HbeqAddrPart. rewrite HbeqAddrPart in *. rewrite HaddrIsPADDRs0 in HpartIsPDTs.
    destruct HpartIsPDTs as [pdentry0 HpartIsPDTs]. exfalso; congruence.
  }
  (* addr' <> partition *)
  rewrite <-beqAddrFalse in HbeqAddrPart. rewrite removeDupIdentity; intuition.
  destruct HlookupParts0 as [pdentry0 (HlookupParts0 & HpartIsParent)]. subst a.
  assert(HparentIsPDT: exists parentEntry, lookup (parent pdentry0) (memory s0) beqAddr
                                            = Some (PDT parentEntry)).
  {
    unfold parentOfPartitionIsPartition in HparentOfPart0.
    specialize(HparentOfPart0 partition pdentry0 HlookupParts0).
    destruct HparentOfPart0 as [HparentOfPart HparentOfRoot]. specialize(HparentOfPart HpartNotRoot).
    intuition.
  }
  specialize(IHparentsList (parent pdentry0) HparentIsPDT HparentsLists1). assumption.
Qed.

Lemma getKSEntriesAuxRemoveExtraFuel block kern len s:
nullAddrExists s
-> nextKernelIsValid s
-> isKS kern s
-> In block (filterOptionPaddr (getKSEntriesAux (S len) kern s))
-> (forall kernList, isListOfKernelsAux kernList kern s -> length kernList < len)
-> In block (filterOptionPaddr (getKSEntriesAux len kern s)).
Proof.
intros Hnull HnextValid. revert kern. induction len.
- intros kern _ HblockIn Hprop. assert(HkernList: isListOfKernelsAux [] kern s) by (simpl; trivial).
  specialize(Hprop [] HkernList). simpl in Hprop. lia.
- intros kern HkernIsKS HblockIn Hprop. cbn -[kernelStructureEntriesNb]. set(succ:= S len). fold succ in HblockIn.
  cbn -[succ kernelStructureEntriesNb] in HblockIn.
  destruct (Paddr.addPaddrIdx kern nextoffset) eqn:Hadd; try(simpl in HblockIn; exfalso; congruence).
  destruct (lookup p (memory s) beqAddr) eqn:HlookupNextAddr; try(simpl in HblockIn; exfalso; congruence).
  destruct v; try(simpl in HblockIn; exfalso; congruence).
  destruct (lookup p0 (memory s) beqAddr) eqn:HlookupNextKS; try(simpl in HblockIn; exfalso; congruence).
  assert(Hnext: nextKernelIsValid s) by assumption.
  specialize(Hnext kern HkernIsKS). destruct Hnext as (Hle & Hnext).
  destruct v; try(simpl in HblockIn; exfalso; congruence).
  + rewrite filterOptionPaddrSplit in *. apply in_app_or in HblockIn. apply in_or_app.
    destruct HblockIn as [Himmediate | HblockInRec]; try(left; assumption). right. subst succ.
    assert(HpropRec: forall kernList, isListOfKernelsAux kernList p0 s -> length kernList < len).
    {
      intros kernList HkernList. assert(HkernListExt: isListOfKernelsAux (p0::kernList) kern s).
      {
        simpl. assert(Hp: p = CPaddr (kern + nextoffset)).
        {
          unfold Paddr.addPaddrIdx in Hadd. unfold CPaddr.
          destruct (le_dec (kern + nextoffset) maxAddr); try(exfalso; congruence). injection Hadd as Hres.
          subst p. f_equal.
        }
        rewrite <-Hp. split. assumption. split. assumption. split; try(assumption). intro Hcontra. subst p0.
        unfold nullAddrExists in Hnull. unfold isPADDR in Hnull. rewrite HlookupNextKS in Hnull. congruence.
      }
      assert(HresExt: length (p0::kernList) < S len) by (apply Hprop; assumption).
      simpl in HresExt. lia.
    }
    assert(isKS p0 s).
    {
      destruct Hnext as [nextAddr (HlookupNext & HnextType)]. unfold Paddr.addPaddrIdx in Hadd.
      destruct (le_dec (kern + nextoffset) maxAddr); try(lia). injection Hadd as Hp.
      specialize(HlookupNext (StateLib.Paddr.addPaddrIdx_obligation_1 kern nextoffset l)).
      rewrite Hp in HlookupNext. rewrite HlookupNextAddr in HlookupNext. injection HlookupNext as Heq.
      subst p0. destruct HnextType as [Hres | Hcontra]; try(assumption). exfalso. unfold nullAddrExists in Hnull.
      unfold isPADDR in Hnull. subst nextAddr. rewrite HlookupNextKS in Hnull. congruence.
    }
    apply IHlen; assumption.
  + destruct (beqAddr p0 {| p := 0; Hp := ADT.CPaddr_obligation_1 0 (PeanoNat.Nat.le_0_l maxAddr) |});
        try(simpl in HblockIn; exfalso; congruence). assumption.
Qed.

Lemma blockInGetKSEntriesAuxIncl block (kernel: paddr) currKern kernList s:
nextKernelIsValid s
-> nullAddrExists s
-> NextKSIsKS s
-> isKS kernel s
-> In block (filterOptionPaddr (getKSEntriesInStructAux (maxIdx+1) currKern s
              (CIndex (kernelStructureEntriesNb-1))))
-> isListOfKernelsAux kernList kernel s
-> (forall kernList, isListOfKernelsAux kernList kernel s -> length kernList < maxNbPrepare)
-> currKern = last kernList kernel
-> In block (filterOptionPaddr (getKSEntriesAux maxNbPrepare kernel s)).
Proof.
intros HnextKernValid Hnull Hnext. unfold nullAddrExists in Hnull.
assert(HnbPrep: exists nbPrepMinus, maxNbPrepare = S nbPrepMinus).
{ unfold maxNbPrepare. simpl. exists 8. reflexivity. }
destruct HnbPrep as [nbPrepMinus HnbPrep]. rewrite HnbPrep. revert kernel. induction kernList.
- cbn -[kernelStructureEntriesNb]. intros kernel HKS HblockIn HkernList Hlength HcurrKern. subst currKern.
  specialize(HnextKernValid kernel HKS).
  destruct HnextKernValid as (HleNext & [nextAddr (HlookupNext & HnextType)]). unfold Paddr.addPaddrIdx.
  destruct (le_dec (kernel + nextoffset) maxAddr); try(lia). rewrite HlookupNext.
  destruct HnextType as [HnextIsKS | HnextIsNull].
  + unfold isKS in HnextIsKS. destruct (lookup nextAddr (memory s) beqAddr); try(exfalso; congruence).
    destruct v; try(exfalso; congruence). rewrite filterOptionPaddrSplit. apply in_or_app. left. assumption.
  + subst nextAddr. unfold isPADDR in Hnull.
    destruct (lookup nullAddr (memory s) beqAddr); try(exfalso; congruence).
    destruct v; try(exfalso; congruence).
    assert(HeqNull: nullAddr = {| p := 0; Hp := ADT.CPaddr_obligation_1 0 (PeanoNat.Nat.le_0_l maxAddr) |}).
    {
      unfold nullAddr. unfold CPaddr. destruct (le_dec 0 maxAddr); try(lia). f_equal. apply proof_irrelevance.
    }
    rewrite DTL.beqAddrTrue in HeqNull. rewrite HeqNull. assumption.
- intros kernel HKS HblockIn HkernList Hlength HcurrKern.
  simpl in HkernList. destruct HkernList as (HlookupNext & Hle & HaNotNull & HkernListRec).
  assert(HKSa: isKS a s).
  {
    unfold NextKSIsKS in Hnext. apply Hnext with kernel (CPaddr (kernel + nextoffset)); try(assumption).
    - unfold nextKSAddr. unfold isKS in HKS. destruct (lookup kernel (memory s) beqAddr); try(congruence).
      destruct v; try(congruence).
    - unfold nextKSentry. rewrite HlookupNext. reflexivity.
  }
  assert(Hrec: In block (filterOptionPaddr (getKSEntriesAux (S nbPrepMinus) a s))).
  {
    apply IHkernList; try(assumption). simpl in Hlength.
    - intros kernListBis HkernListBis.
      assert(HkernListBisExt: isListOfKernelsAux (a::kernListBis) kernel s).
      { simpl. intuition. }
      specialize(Hlength (a::kernListBis) HkernListBisExt). simpl in Hlength. lia.
    - apply lastRec with kernel. assumption.
  }
  assert(In block (filterOptionPaddr (getKSEntriesAux nbPrepMinus a s))).
  {
    apply getKSEntriesAuxRemoveExtraFuel; try(assumption). intros kernListBis HkernListBis.
    assert(HkernListBisExt: isListOfKernelsAux (a::kernListBis) kernel s).
    { simpl. intuition. }
    specialize(Hlength (a::kernListBis) HkernListBisExt). simpl in Hlength. lia.
  }
  cbn -[kernelStructureEntriesNb]. unfold Paddr.addPaddrIdx. unfold CPaddr in HlookupNext.
  destruct (le_dec (kernel + nextoffset) maxAddr) eqn:HleBis; try(lia).
  assert(Heq: {| p := kernel + nextoffset; Hp := ADT.CPaddr_obligation_1 (kernel + nextoffset) l |}
            = {| p := kernel + nextoffset; Hp := StateLib.Paddr.addPaddrIdx_obligation_1 kernel nextoffset l |}).
  { f_equal. }
  assert(HKSaCopy: isKS a s) by assumption.
  rewrite Heq in HlookupNext. rewrite HlookupNext. unfold isKS in HKSa.
  destruct (lookup a (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
  rewrite filterOptionPaddrSplit. apply in_or_app. right. apply getKSEntriesAuxRemoveExtraFuel; try(assumption).
  intros kernListBis HkernListBis.
  assert(HkernListBisExt: isListOfKernelsAux (a::kernListBis) kernel s).
  {
    simpl. unfold CPaddr. rewrite HleBis. rewrite Heq. intuition.
  }
  specialize(Hlength (a::kernListBis) HkernListBisExt). simpl in Hlength. lia.
Qed.

Lemma kernListsEq (kernel: paddr) kernList1 kernList2 s lastKern:
(forall kernList, isListOfKernelsAux kernList kernel s -> NoDup (kernel::kernList))
-> isListOfKernelsAux kernList1 kernel s
-> isListOfKernelsAux kernList2 kernel s
-> lastKern = last kernList1 kernel
-> lastKern = last kernList2 kernel
-> kernList1 = kernList2.
Proof.
revert kernel kernList2. induction kernList1.
- simpl. intros kernel kernList2 HnoDup HkernList1 HkernList2 Hlast1 Hlast2. subst lastKern.
  destruct kernList2; try(reflexivity). exfalso. specialize(HnoDup (p::kernList2) HkernList2).
  apply NoDup_cons_iff in HnoDup.
  assert(Hcontra: In kernel (p::kernList2)).
  { apply lastOfNotEmptyIsIn with kernel. assumption. }
  destruct HnoDup. congruence.
- intros kernel kernList2 HnoDup HkernList1 HkernList2 Hlast1 Hlast2. destruct kernList2.
  + exfalso. simpl in Hlast2. subst lastKern. specialize(HnoDup (a::kernList1) HkernList1).
    apply NoDup_cons_iff in HnoDup.
    assert(Hcontra: In kernel (a::kernList1)).
    { apply lastOfNotEmptyIsIn with kernel. apply eq_sym. assumption. }
    destruct HnoDup. congruence.
  + simpl in HkernList1. simpl in HkernList2.
    destruct HkernList1 as (HlookupNextOffa & Hadd & HaNotNull & HkernList1Rec).
    destruct HkernList2 as (HlookupNextOffp & _ & _ & HkernList2Rec). rewrite HlookupNextOffa in HlookupNextOffp.
    injection HlookupNextOffp as Heq. subst p. f_equal. apply IHkernList1 with a; try(assumption).
    intros kernlist HkernList.
    assert(Hrec: isListOfKernelsAux (a::kernlist) kernel s).
    { simpl. intuition. }
    specialize(HnoDup (a::kernlist) Hrec). apply NoDup_cons_iff in HnoDup. destruct HnoDup. assumption.
    apply lastRec with kernel. assumption. apply lastRec with kernel. assumption.
Qed.

Lemma kernListsEqNext (kernel: paddr) kernList1 kernList2 s (currKern: paddr) nextKern:
nextKSentry (CPaddr (currKern + nextoffset)) nextKern s
-> currKern + nextoffset <= maxAddr
-> nextKern <> nullAddr
-> (forall kernList, isListOfKernelsAux kernList kernel s -> NoDup (kernel::kernList))
-> isListOfKernelsAux kernList1 kernel s
-> isListOfKernelsAux kernList2 kernel s
-> currKern = last kernList1 kernel
-> nextKern = last kernList2 kernel
-> kernList2 = kernList1 ++ [nextKern].
Proof.
intros HnextKS Hadd HbeqNextNull. unfold nextKSentry in HnextKS.
destruct (lookup (CPaddr (currKern+nextoffset)) (memory s) beqAddr) eqn:HlookupNextOff; try(exfalso; congruence).
destruct v; try(exfalso; congruence). subst p. intros HnoDup HkernList1 HkernList2 HcurrIsLast1 HnextIsLast2.
  assert(HkernList2Bis: isListOfKernelsAux (kernList1 ++ [nextKern]) kernel s).
  { apply isListOfKernelsAuxRec with currKern; assumption. }
  assert(HnextIsLast2Bis: nextKern = last (kernList1 ++ [nextKern]) kernel).
  { rewrite last_last. reflexivity. }
  apply kernListsEq with kernel s nextKern; assumption.
Qed.

Lemma getConfigBlocksAuxFromNull n s idx:
nullAddrExists s
-> filterOptionPaddr (getConfigBlocksAux (S n) nullAddr s idx) = [].
Proof.
intro Hnull. simpl. unfold nullAddrExists in Hnull. unfold isPADDR in Hnull.
destruct (lookup nullAddr (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
destruct (beqAddr p nullAddr); simpl; reflexivity.
Qed.

Lemma NoDupAddrImpliesEq addr block1 block2 l s:
NoDup (getAllPaddrAux l s)
-> In addr (getAllPaddrAux [block1] s)
-> In addr (getAllPaddrAux [block2] s)
-> In block1 l
-> In block2 l
-> block1 = block2.
Proof.
intros HnoDup HaddrInBlock1 HaddrInBlock2 Hblock1 Hblock2.
destruct (beqAddr block1 block2) eqn:HbeqBlocks; try(rewrite <-DTL.beqAddrTrue in HbeqBlocks; assumption).
exfalso. rewrite <-beqAddrFalse in HbeqBlocks. induction l.
- simpl in Hblock1. congruence.
- simpl in *. assert(HinEmpty: forall [a : paddr], ~ In a []) by (apply in_nil).
  destruct (lookup block1 (memory s) beqAddr) eqn:HlookupBlock1; try(apply HinEmpty with block1; assumption).
  destruct v; try(apply HinEmpty with block1; assumption).
  destruct (lookup block2 (memory s) beqAddr) eqn:HlookupBlock2; try(apply HinEmpty with block2; assumption).
  destruct v; try(apply HinEmpty with block2; assumption). rewrite app_nil_r in *.
  destruct Hblock1 as [HaIsBlock1 | Hblock1Rec].
  + subst a. destruct Hblock2 as [Hcontra | Hblock2Rec]; try(congruence). rewrite HlookupBlock1 in HnoDup.
    apply Lib.NoDupSplitInclIff in HnoDup. destruct HnoDup as (_ & Hdisjoint).
    specialize(Hdisjoint addr HaddrInBlock1). contradict Hdisjoint. apply blockIsMappedAddrInPaddrList with block2.
    assumption. simpl. rewrite HlookupBlock2. rewrite app_nil_r. assumption.
  + destruct Hblock2 as [HaIsBlock2 | Hblock2Rec].
    * subst a. rewrite HlookupBlock2 in HnoDup. apply Lib.NoDupSplitInclIff in HnoDup.
      destruct HnoDup as (_ & Hdisjoint). specialize(Hdisjoint addr HaddrInBlock2). contradict Hdisjoint.
      apply blockIsMappedAddrInPaddrList with block1. assumption. simpl. rewrite HlookupBlock1. rewrite app_nil_r.
      assumption.
    * apply IHl; try(assumption). destruct (lookup a (memory s) beqAddr); try(assumption).
      destruct v; try(assumption). apply Lib.NoDupSplit in HnoDup. destruct HnoDup. assumption.
Qed.

Lemma getAllPaddrBlockAuxRecInv pos startaddr count H:
pos + startaddr + count <= maxAddr ->
getAllPaddrBlockAux pos startaddr count ++ [{| p := pos+startaddr+count; Hp := H |}]
= getAllPaddrBlockAux pos startaddr (S count).
Proof.
revert pos H. induction count.
- intros. simpl. destruct (le_dec (pos + startaddr) maxAddr); try lia. f_equal.
  assert(HaddNull: pos + startaddr + 0 = pos + startaddr).
  { apply eq_sym. apply plus_n_O. }
  rewrite HaddNull in *. apply paddrEqNatEqEquiv. simpl. lia.
- intros pos H HlebEndMax. set(succ := S count). cbn -[succ].
  destruct (le_dec (pos + startaddr) maxAddr) eqn:HposStart; try(lia). subst succ.
  assert(HendRec: S pos + startaddr + count <= maxAddr) by lia.
  specialize(IHcount (S pos) HendRec HendRec). rewrite <-IHcount. simpl. rewrite HposStart.
  rewrite <-app_comm_cons. f_equal. f_equal. f_equal. apply paddrEqNatEqEquiv. simpl. lia.
Qed.

Lemma getAllPaddrBlockAuxCut pos startaddr cutAddr endaddr:
startaddr <= cutAddr ->
cutAddr <= endaddr ->
pos + endaddr <= maxAddr ->
getAllPaddrBlockAux pos startaddr (cutAddr - startaddr) ++ getAllPaddrBlockAux pos cutAddr (endaddr - cutAddr)
= getAllPaddrBlockAux pos startaddr (endaddr - startaddr).
Proof.
intros HlebStartCut HltCutEnd HlebFinalPosMax. (*assert(endaddr - cutAddr >= 0) by lia.*)
assert(Hend: endaddr = cutAddr + (endaddr - cutAddr)) by lia. rewrite Hend. rewrite Hend in HlebFinalPosMax.
clear Hend. revert pos HlebFinalPosMax. induction (endaddr - cutAddr).
- simpl. intros. rewrite <-plus_n_O. rewrite Nat.sub_diag. simpl. rewrite app_nil_r. reflexivity.
- intros. simpl. assert(pos + cutAddr <= maxAddr) by lia.
  replace (cutAddr + S n - cutAddr) with (S n); try(lia).
  replace (cutAddr + S n - startaddr) with (S (cutAddr + n - startaddr)); try(lia). simpl.
  destruct (le_dec (pos + cutAddr) maxAddr); try(exfalso; lia).
  destruct (le_dec (pos + startaddr) maxAddr) eqn:HlebPosStartMax; try(lia).
  assert(HlebFinalPosMaxBis: S pos + (cutAddr + n) <= maxAddr) by lia.
  specialize(IHn (S pos) HlebFinalPosMaxBis). rewrite <-IHn.
  replace (cutAddr + n - cutAddr) with n; try(lia).
  assert(Hleft: getAllPaddrBlockAux pos startaddr (cutAddr - startaddr)
                  ++ {| p := pos + cutAddr; Hp := l |} :: getAllPaddrBlockAux (S pos) cutAddr n
                = (getAllPaddrBlockAux pos startaddr (cutAddr - startaddr) ++
                      [{| p := pos + cutAddr; Hp := l |}])
                  ++ getAllPaddrBlockAux (S pos) cutAddr n).
  { rewrite <-app_assoc. f_equal. }
  rewrite Hleft. clear Hleft.
  assert(Hright: {| p := pos + startaddr; Hp := l0 |}
                    :: getAllPaddrBlockAux (S pos) startaddr (cutAddr - startaddr)
                    ++ getAllPaddrBlockAux (S pos) cutAddr n
                  = ({| p := pos + startaddr; Hp := l0 |}
                      :: getAllPaddrBlockAux (S pos) startaddr (cutAddr - startaddr))
                    ++ getAllPaddrBlockAux (S pos) cutAddr n).
  { rewrite <-app_comm_cons. reflexivity. }
  rewrite Hright. clear Hright. f_equal.
  assert(HlebPosCutMax: pos + startaddr + (cutAddr - startaddr) <= maxAddr) by lia.
  pose proof (getAllPaddrBlockAuxRecInv pos startaddr (cutAddr - startaddr) HlebPosCutMax HlebPosCutMax)
      as Hres.
  assert(Hsubst: getAllPaddrBlockAux pos startaddr (cutAddr - startaddr)
                    ++ [{| p := pos + startaddr + (cutAddr - startaddr); Hp := HlebPosCutMax |}]
                  = getAllPaddrBlockAux pos startaddr (cutAddr - startaddr)
                    ++ [{| p := pos + cutAddr; Hp := l |}]).
  { f_equal. f_equal. apply paddrEqNatEqEquiv. simpl. lia. }
  rewrite Hsubst in Hres. clear Hsubst. rewrite Hres. simpl. rewrite HlebPosStartMax. reflexivity.
Qed.


Lemma getMappedPaddrEqBEEndLowerChangeLengthEquality partition block newEntry newEnd bentry0 s0:
isPDT partition s0 ->
lookup block (memory s0) beqAddr = Some (BE bentry0) ->
present newEntry = present bentry0 ->
(*present newEntry = true ->*)
startAddr (blockrange newEntry) = startAddr (blockrange bentry0) ->
endAddr (blockrange newEntry) = newEnd ->
newEnd <= endAddr (blockrange bentry0) ->
startAddr (blockrange bentry0) <= endAddr (blockrange newEntry) ->
noDupMappedBlocksList s0 ->
In block (getMappedBlocks partition s0) ->
length (getMappedPaddr partition {|
						currentPartition := currentPartition s0;
						memory := add block (BE newEntry)
            (memory s0) beqAddr |}
        ++ getAllPaddrBlock newEnd (endAddr (blockrange bentry0))) =
length (getMappedPaddr partition s0).
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros HPDTs0 Hlookupaddrs0 HpresentEq (*Hpresenttrue*) HstartEq HnewEnd HlebNewEndEnd.
intros HlebStartNewEnd HnoDup HaddrMappeds0.


assert(HBEs0 : isBE block s0) by (unfold isBE ; rewrite Hlookupaddrs0 ; trivial).
unfold getMappedPaddr.
specialize(HnoDup partition HPDTs0).
assert(HEq :  getMappedBlocks partition s' = getMappedBlocks partition s0).
{ apply getMappedBlocksEqBENoChange with bentry0; assumption.
}
rewrite HEq in *. apply in_split in HaddrMappeds0. destruct HaddrMappeds0 as [mappedLeft [mappedRight Hmapped]].
assert(HmappedBis: getMappedBlocks partition s0 = mappedLeft ++ [block] ++ mappedRight).
{ simpl. assumption. }
rewrite HmappedBis in *. rewrite getAllPaddrAuxSplit. rewrite getAllPaddrAuxSplit. rewrite getAllPaddrAuxSplit.
rewrite getAllPaddrAuxSplit. apply Lib.NoDupSplitInclIff in HnoDup.
destruct HnoDup as ((_ & HnoDupRest) & HdisjointLeftRest). apply Lib.NoDupSplitInclIff in HnoDupRest.
destruct HnoDupRest as (_ & HdisjointBlockRight).
assert(HblockInBlock: In block [block]) by (simpl; left; reflexivity).
specialize(HdisjointBlockRight block HblockInBlock).
assert(HblockNotInLeft: ~In block mappedLeft).
{
  intro Hcontra. specialize(HdisjointLeftRest block Hcontra). contradict HdisjointLeftRest. simpl.
  left. reflexivity.
}
assert(HmappedLeftEq: getAllPaddrAux mappedLeft s' = getAllPaddrAux mappedLeft s0).
{ apply getAllPaddrAuxEqBENoInList; assumption. }
assert(HmappedRightEq: getAllPaddrAux mappedRight s' = getAllPaddrAux mappedRight s0).
{ apply getAllPaddrAuxEqBENoInList; assumption. }
rewrite HmappedLeftEq. rewrite HmappedRightEq. rewrite length_app. rewrite length_app. rewrite length_app.
rewrite length_app. rewrite length_app.
replace (length (getAllPaddrAux mappedLeft s0)
        + (length (getAllPaddrAux [block] s') + length (getAllPaddrAux mappedRight s0))
        + length (getAllPaddrBlock newEnd (endAddr (blockrange bentry0))))
  with (length (getAllPaddrAux mappedLeft s0)
        + ((length (getAllPaddrAux [block] s') + length (getAllPaddrAux mappedRight s0))
          + length (getAllPaddrBlock newEnd (endAddr (blockrange bentry0))))); try(apply Nat.add_assoc).
apply <-Nat.add_cancel_l. rewrite Nat.add_shuffle0. apply Nat.add_cancel_r. simpl.
rewrite InternalLemmas.beqAddrTrue. rewrite Hlookupaddrs0. rewrite app_nil_r. rewrite app_nil_r. subst newEnd.
rewrite HstartEq. rewrite <-length_app. f_equal. unfold getAllPaddrBlock.
assert(endAddr (blockrange bentry0) <= maxAddr) by (apply Hp). apply getAllPaddrBlockAuxCut; lia.
Qed.



(*Lemma KSEntriesAuxConfigBlocksAuxEqAux :
n >= maxNbPrepare
-> filterOptionPaddr (getConfigBlocksAux (S n) (structure p) s (CIndex maxNbPrepare))
   = filterOptionPaddr (getKSEntriesAux maxNbPrepare (structure p) s).
Proof.

Qed.

Lemma KSEntriesAuxConfigBlocksAuxEq :
n >= maxNbPrepare
-> filterOptionPaddr (getConfigBlocksAux (S n) (structure p) s (CIndex maxNbPrepare))
   = filterOptionPaddr (getKSEntriesAux maxNbPrepare (structure p) s).
Proof.

Qed.

Lemma KSEntriesConfigBlocksEq part s:
consistency1 s
-> getConfigBlocks part s = filterOptionPaddr (getKSEntries part s).
Proof.
intro Hconsist. unfold getConfigBlocks. unfold getKSEntries.
destruct (lookup part (memory s) beqAddr) eqn:HlookupPart; try(simpl; reflexivity).
destruct v; try(simpl; reflexivity). rewrite MaxIdxNextEq.
destruct (beqAddr (structure p) nullAddr) eqn:HbeqStructNull.
- rewrite <-DTL.beqAddrTrue in HbeqStructNull. rewrite HbeqStructNull. simpl.
  apply getConfigBlocksAuxFromNull. unfold consistency1 in *; intuition.
- assert(maxNbPrepare < maxIdx - 1) by (apply maxNbPrepareNbLessThanMaxIdx).
  (*TODO HERE needs the lemma above*)
Qed.*)


(*
Lemma NotInPartEqPDT partition addr' newEntry pdentry0 s0 s:
lookup addr' (memory s0) beqAddr = Some (PDT pdentry0) ->
partition <> addr' ->
structure newEntry = structure pdentry0 ->
StructurePointerIsKS s0 ->
PDTIfPDFlag s0 ->
s = {|
						currentPartition := currentPartition s0;
						memory := add addr' (PDT newEntry)
            (memory s0) beqAddr |} ->

getMappedPaddr partition s = getMappedPaddr partition s0
/\ getConfigPaddr partition s = getConfigPaddr partition s0
/\ getPartitions partition s = getPartitions partition s0
/\ getChildren partition s = getChildren partition s0
/\ getMappedBlocks partition s = getMappedBlocks partition s0
/\ getAccessibleMappedPaddr partition s = getAccessibleMappedPaddr partition s0.
Proof.
set (s' :=   {|
currentPartition := currentPartition s0;
memory := _ |}).
intros Haddr'lookups0 Haddr'partNotEq  HStructEq HStructPointerIsKSs0
	HPDTIfPDflags0 HsEq.
subst s.
assert(HPDTaddr's0 : isPDT addr' s0)
	by (unfold isPDT ; rewrite Haddr'lookups0 ; trivial).
intuition.
eapply getMappedPaddrEqPDTNotInPart; intuition.
eapply getConfigPaddrEqPDTNotInPart with pdentry0 ; intuition.
(* cannot do withtout structure equality otherwise partition tree could have changed *)
eapply getPartitionsEqPDT with pdentry0 ; intuition.
eapply getChildrenEqPDTNotInPart with pdentry0; intuition.
eapply getMappedBlocksEqPDTNotInPart; intuition.
eapply getAccessibleMappedPaddrEqPDTNotInPart; intuition.
Qed.*)

(*
Lemma eqListTrueEq  :
forall a b,
eqList a b beqIndex= true -> a=b.
Proof.
induction a; simpl;intros.
case_eq b;intros;trivial.
rewrite H0 in *.
now contradict H.
case_eq b;intros;subst.
now contradict H.
case_eq( beqIndex a i);intros;rewrite H0 in *.
f_equal.
unfold beqIndex in H0.
apply beq_nat_true in H0;trivial.
destruct a. destruct i. simpl in *.

subst;trivial.
f_equal.
apply proof_irrelevance.
apply IHa;trivial.
now contradict H.
Qed.

Lemma beqVAddrTrueEq :
forall a b,
beqVAddr a b = true -> a=b.
Proof.
intros.
destruct a.
destruct b.
assert (va = va0).
apply eqListTrueEq.
simpl in *.
trivial.
subst.
f_equal.
apply proof_irrelevance.
Qed.
Lemma isAccessibleMappedPageGetTableRoot (phypage :page) entry sh2 descParent ptsh2 va pdAncestor ancestor  (vaInAncestor :vaddr) ptvaInAncestor s:
 nextEntryIsPP descParent sh2idx sh2 s ->
 isVA ptsh2 (StateLib.getIndexOfAddr va fstLevel) s ->
getTableAddrRoot ptsh2 sh2idx descParent va s ->
nextEntryIsPP descParent PPRidx ancestor s ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
isPE ptvaInAncestor  (StateLib.getIndexOfAddr vaInAncestor fstLevel) s ->
getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
 isAccessibleMappedPageInParent descParent va phypage s = true ->
  lookup ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) (memory s) beqPage beqIndex =
          Some (PE entry) ->
(Nat.eqb defaultPage ptsh2) = false ->

isVA' ptsh2 (StateLib.getIndexOfAddr va fstLevel) vaInAncestor s ->
phypage = pa entry.
Proof.
intros Hppsh2 Hva Hx Hppparent Hpppd Hve Hroot Hdef Hfalse Hlookup.
intros.
symmetry.
 assert (HgetVirt : getVirtualAddressSh2 sh2 s va  = Some vaInAncestor).
{ apply isVaInParent with descParent ptsh2;trivial.
  intros;subst.
  intuition. }
unfold isAccessibleMappedPageInParent in *.
apply nextEntryIsPPgetSndShadow in Hppsh2.
rewrite Hppsh2 in *.
rewrite HgetVirt in *.
rewrite nextEntryIsPPgetParent in * .
rewrite Hppparent in *.
apply nextEntryIsPPgetPd in Hpppd .
rewrite Hpppd in *.
case_eq(getAccessibleMappedPage pdAncestor s vaInAncestor);
intros * Hacce;
rewrite Hacce in *;try now contradict Hfalse.
unfold getAccessibleMappedPage in Hacce.
unfold getTableAddrRoot in *.
destruct Hroot as (_ & Hroot).
rewrite <- nextEntryIsPPgetPd in *.
apply Hroot in  Hpppd.
clear Hroot.
destruct Hpppd as (nbL & HnbL & stop & Hstop & Hind).
subst.
rewrite <- HnbL in *.
assert(Hgetind : getIndirection pdAncestor vaInAncestor nbL (nbLevel - 1) s
= Some ptvaInAncestor).
{ apply getIndirectionStopLevelGT2 with (nbL+1);trivial.
  lia.
  apply getNbLevelEq in HnbL.
  rewrite HnbL.
  unfold CLevel.
  case_eq(lt_dec (nbLevel - 1) nbLevel);intros.
  simpl;trivial.
  assert(0<nbLevel) by apply nbLevelNotZero.
  lia. }
  rewrite Hgetind in *.

rewrite Hdef in *.
destruct ( StateLib.readPresent ptvaInAncestor
(StateLib.getIndexOfAddr vaInAncestor fstLevel)
(memory s));try now contradict Hacce.
destruct b;try now contradict Hacce.
destruct ( StateLib.readAccessible ptvaInAncestor
(StateLib.getIndexOfAddr vaInAncestor fstLevel)
(memory s)); try now contradict Hacce.
destruct b; try now contradict Hacce.
unfold StateLib.readPhyEntry in *.

rewrite Hlookup in *.
apply beq_nat_true in Hfalse.
inversion Hacce.
subst.
destruct phypage; destruct (pa entry).
simpl in *.
subst.
f_equal; apply proof_irrelevance.
Qed.

Lemma isAccessibleMappedPage' part pdChild currentPD (ptPDChild : page)  entry s :
(Nat.eqb defaultPage ptPDChild ) = false ->
entryPresentFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
entryUserFlag ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) true s ->
lookup ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) (memory s) beqPage beqIndex =
    Some (PE entry) ->
 nextEntryIsPP part PDidx currentPD s ->
(forall idx : index,
StateLib.getIndexOfAddr pdChild fstLevel = idx ->
isPE ptPDChild idx s /\ getTableAddrRoot ptPDChild PDidx part pdChild s ) ->
getAccessibleMappedPage currentPD s pdChild = SomePage (pa entry).
Proof.
intros Hnotnull Hpe Hue Hlookup Hpp Hget .
assert ( isPE ptPDChild (StateLib.getIndexOfAddr pdChild fstLevel) s /\
        getTableAddrRoot ptPDChild PDidx part pdChild s) as (_ & Hroot).
apply Hget; trivial.
clear Hget.
unfold getAccessibleMappedPage.
unfold getTableAddrRoot in *.
destruct Hroot  as (_ & Hroot).
apply Hroot in Hpp; clear Hroot.
destruct Hpp as (nbL & HnbL & stop & Hstop & Hind).
rewrite <- HnbL.
subst.
assert (Hnewind : getIndirection currentPD pdChild nbL (nbLevel - 1) s= Some ptPDChild).
apply getIndirectionStopLevelGT2 with (nbL + 1);try lia;trivial.
apply getNbLevelEq in HnbL.
unfold CLevel in HnbL.
case_eq (lt_dec (nbLevel - 1) nbLevel); intros; rewrite H in *.
destruct nbL.
simpl in *.
inversion HnbL; trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hnewind.
apply entryPresentFlagReadPresent in Hpe.
rewrite Hpe.
apply entryUserFlagReadAccessible in Hue.
rewrite Hue.
unfold StateLib.readPhyEntry.
rewrite Hnotnull.
rewrite Hlookup; trivial.
Qed.



Lemma isAccessibleMappedPageInParentTruePresentAccessible s (va vaInAncestor:vaddr)
ptvaInAncestor entry descParent L sh2 (ptsh2 ancestor pdAncestor: page):
isAccessibleMappedPageInParent descParent va (pa entry) s = true ->
nextEntryIsPP descParent sh2idx sh2 s->
isPE ptvaInAncestor ( StateLib.getIndexOfAddr vaInAncestor fstLevel) s ->
getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s ->
(Nat.eqb defaultPage ptvaInAncestor) = false ->
Some L = StateLib.getNbLevel ->
(Nat.eqb defaultPage ptsh2) = false ->
isVA' ptsh2 (StateLib.getIndexOfAddr va fstLevel) vaInAncestor s ->
isVA ptsh2 (StateLib.getIndexOfAddr va fstLevel) s ->
getTableAddrRoot ptsh2 sh2idx descParent va s ->
nextEntryIsPP descParent PPRidx ancestor s ->
nextEntryIsPP ancestor PDidx pdAncestor s ->
entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s
/\ entryUserFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s.
Proof.
intros HaccessInParent Hcursh2 Hva Hget Hnotnull.
intros.
unfold isAccessibleMappedPageInParent in HaccessInParent.
apply nextEntryIsPPgetSndShadow in Hcursh2.
rewrite Hcursh2 in HaccessInParent.
assert(Hvainparent : getVirtualAddressSh2 sh2 s va = Some vaInAncestor).
apply getVirtualAddressSh2GetTableRoot with ptsh2 descParent L;trivial.
intros;split;subst;trivial.
rewrite Hvainparent in *.
assert(Hgetparent : StateLib.getParent descParent (memory s) = Some ancestor).
{ apply nextEntryIsPPgetParent;trivial. }
rewrite Hgetparent in *.
assert(Hgetpdparent : StateLib.getPd ancestor (memory s) = Some pdAncestor).
{ apply nextEntryIsPPgetPd;trivial. }
rewrite Hgetpdparent in *.
case_eq(getAccessibleMappedPage pdAncestor s vaInAncestor ); intros * Hi ;
rewrite Hi in *;try now contradict Hi.
unfold getAccessibleMappedPage in Hi.
assert(HnbL: Some L = StateLib.getNbLevel) by trivial.
rewrite <- HnbL in *.
unfold getTableAddrRoot in Hget.
destruct Hget as (_ & Hget).
apply nextEntryIsPPgetPd in Hgetpdparent.
apply Hget in Hgetpdparent.
destruct Hgetpdparent as (nbL & HnbL' & stop & Hstop & Hgettable).
clear Hget.
rewrite <- HnbL' in *.
inversion HnbL.
subst.
assert(Hind :getIndirection pdAncestor vaInAncestor nbL (nbLevel - 1) s = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL+1);trivial.
lia.
apply getNbLevelEq in HnbL'.
rewrite HnbL'.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);intros.
simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hind in *.
rewrite Hnotnull in *.
case_eq (StateLib.readPresent ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
(memory s));[intros pres Hpres|intros Hpres];rewrite Hpres in *; try now contradict Hi.
case_eq pres;intros;subst; try now contradict Hi.
rewrite entryPresentFlagReadPresent';split;trivial.
    case_eq (StateLib.readAccessible ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel)
(memory s));[intros pres Hacc|intros Hacc];rewrite Hacc in *; try now contradict Hi.
case_eq pres;intros;subst; try now contradict Hi.
rewrite entryUserFlagReadAccessible;trivial.
Qed.
 Lemma pdPartNotNull' phyDescChild pdChildphy s:
In phyDescChild (getPartitions multiplexer s) ->
nextEntryIsPP phyDescChild PDidx pdChildphy s ->
partitionDescriptorEntry s ->
(Nat.eqb defaultPage pdChildphy) = false.
Proof.
intros.
 unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild PDidx entry s /\ entry <> defaultPage)).
        apply H1;trivial.
        left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
assert(entryPd = pdChildphy).
apply getPdNextEntryIsPPEq  with phyDescChild s;trivial.
apply nextEntryIsPPgetPd;trivial.
subst;trivial.
apply PeanoNat.Nat.eqb_neq.
symmetrynot.
unfold not;intros.
apply Hnotnull.
destruct pdChildphy;simpl in *.
destruct defaultPage;simpl in *.
subst.

f_equal.
trivial.
apply proof_irrelevance.
Qed.

Lemma getAccessibleMappedPageInAncestor  descParent va entry pdAncestor s vaInAncestor sh2 ptsh2 ancestor:
isAccessibleMappedPageInParent descParent va (pa entry) s = true ->
 nextEntryIsPP descParent sh2idx sh2 s ->
  isVA ptsh2 (StateLib.getIndexOfAddr va fstLevel) s ->
        getTableAddrRoot ptsh2 sh2idx descParent va s ->
        isVA' ptsh2 (StateLib.getIndexOfAddr va fstLevel) vaInAncestor s ->
        (Nat.eqb defaultPage ptsh2) = false ->
         nextEntryIsPP descParent PPRidx ancestor s ->
         nextEntryIsPP ancestor PDidx pdAncestor s ->
 getAccessibleMappedPage pdAncestor s vaInAncestor = SomePage (pa entry)      .
 Proof.
 intros HaccessInParent Hcursh2 Hva Hgetva Hisva Hptnotnull.
 intros.
unfold isAccessibleMappedPageInParent in HaccessInParent.
(** Here we use the property already present into the precondition :
    *)
apply nextEntryIsPPgetSndShadow in Hcursh2.
rewrite Hcursh2 in HaccessInParent.
assert(Hvainparent : getVirtualAddressSh2 sh2 s va = Some vaInAncestor).
{

unfold getVirtualAddressSh2.
unfold getTableAddrRoot in Hgetva.
destruct Hgetva as (_ & Hgetva).
assert(HcurSh2 : nextEntryIsPP descParent sh2idx sh2 s).
rewrite  nextEntryIsPPgetSndShadow ;trivial.
apply Hgetva in HcurSh2.
destruct HcurSh2 as (nbL & HnbL & stop & Hstop & Hind).
rewrite <- HnbL.
subst.
assert(Hgetind : getIndirection sh2 va nbL (nbLevel - 1) s = Some ptsh2).
apply getIndirectionStopLevelGT2 with (nbL + 1);trivial.
lia.
apply getNbLevelEq in HnbL.
rewrite HnbL.
unfold CLevel.
case_eq(lt_dec (nbLevel - 1) nbLevel);intros.
simpl;trivial.
assert(0<nbLevel) by apply nbLevelNotZero.
lia.
rewrite Hgetind.
rewrite Hptnotnull.
unfold  isVA' in *.
unfold StateLib.readVirtual.
destruct(lookup ptsh2 (StateLib.getIndexOfAddr va fstLevel) (memory s) beqPage beqIndex );
try now contradict Hisva.
destruct v;try now contradict Hisva.
subst. trivial. }
rewrite Hvainparent in *.
assert(Hgetparent : StateLib.getParent descParent (memory s) = Some ancestor).
{ apply nextEntryIsPPgetParent;trivial. }
rewrite Hgetparent in *.
assert(Hgetpdparent : StateLib.getPd ancestor (memory s) = Some pdAncestor).
{ apply nextEntryIsPPgetPd;trivial. }
rewrite Hgetpdparent in *.
case_eq(getAccessibleMappedPage pdAncestor s vaInAncestor ); intros * Hi ;
rewrite Hi in *;try now contradict HaccessInParent.
f_equal.
apply beq_nat_true in HaccessInParent.
symmetry;trivial.
destruct p;simpl in *.
destruct (pa entry);simpl in *.
subst.
f_equal.
apply proof_irrelevance.
Qed.

Lemma parentMultNone descParent s:
true = StateLib.Page.eqb descParent multiplexer ->
consistency s ->
StateLib.getParent descParent (memory s) = None.
Proof.
intros Hmult Hcons.
unfold StateLib.Page.eqb in *.
assert(Hismult : true = (Nat.eqb descParent multiplexer)) by trivial.
symmetry in Hismult.
apply  beq_nat_true in Hismult.

unfold consistency in *.

assert(Hmultcons : multiplexerWithoutParent s) by intuition.
revert Hismult Hmultcons.
clear.
intros.
unfold multiplexerWithoutParent in *.
rewrite <- Hmultcons.
f_equal.
destruct  descParent; destruct multiplexer.
simpl in *.
subst.
f_equal.
apply proof_irrelevance.
Qed.

Lemma childAncestorConfigTablesAreDifferent s (child parent ancestor :page)(ptchild ptAncestor: page)
(vaInchild vaInAncestor: vaddr):
isAncestor  child parent s ->
consistency s ->
In child (getPartitions multiplexer s) ->
nextEntryIsPP parent PPRidx ancestor s ->
isPE ptchild (StateLib.getIndexOfAddr vaInchild fstLevel) s ->
getTableAddrRoot ptchild PDidx child vaInchild s->
(Nat.eqb defaultPage ptchild) = false ->
In ancestor (getPartitions multiplexer s) ->
isPE ptAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) s ->
getTableAddrRoot ptAncestor PDidx ancestor vaInAncestor s ->
(Nat.eqb defaultPage ptAncestor) = false ->
ptchild <> ptAncestor.
Proof.
intros   Hisancestor.
intros.
unfold isAncestor in *.
destruct Hisancestor as [Hisancestor | Hisancestor].
- subst.
(*             rewrite Hisancestor in *. *)
unfold consistency in *.
assert(parent <> ancestor).
{ assert(Hdiff : noCycleInPartitionTree s) by
  intuition.
  unfold noCycleInPartitionTree in *.
  unfold not;intros Hii;symmetry in Hii;contradict Hii.
  apply Hdiff;trivial.
  apply parentIsAncestor;trivial. }
assert(Hconfigdiff :configTablesAreDifferent s) by intuition.
unfold configTablesAreDifferent in *.
assert(Hdisjoint : disjoint (getConfigPages parent  s) (getConfigPages ancestor s)).
apply Hconfigdiff;trivial.
(*             assert(Hparet : parentInPartitionList s) by intuition.
unfold parentInPartitionList in *.
apply Hparet with (currentPartition s) ;trivial. *)
assert(Hin1 : In ptchild (getConfigPages parent  s)).
apply isConfigTable with vaInchild;trivial.
intuition.
 intros;subst;split;trivial.
assert(Hin2: In ptAncestor (getConfigPages ancestor s)).
apply isConfigTable with vaInAncestor;trivial.
intuition.
intros;subst;split;trivial.
unfold disjoint in *.
apply Hdisjoint in Hin1.
unfold not;intros; subst.
now contradict Hin2.
- unfold consistency in *.
subst.
assert(In child (getPartitions multiplexer s)).
unfold currentPartitionInPartitionsList in *.
intuition.
assert(child <> ancestor).
{  unfold not;intros Hii;symmetry in Hii;contradict Hii.
assert (Hnocycle : noCycleInPartitionTree s) by intuition.
unfold noCycleInPartitionTree in *.
apply Hnocycle;trivial.
unfold consistency in *.
apply isAncestorTrans2 with parent;trivial.
intuition. intuition.
unfold consistency in *. intuition.
apply nextEntryIsPPgetParent;trivial. }
assert(Hconfigdiff :configTablesAreDifferent s) by intuition.
unfold configTablesAreDifferent in *.
assert(Hdisjoint : disjoint (getConfigPages child s) (getConfigPages ancestor s)).
apply Hconfigdiff;trivial.
assert(Hin1 : In ptchild (getConfigPages child s)).
apply isConfigTable with vaInchild;trivial.
intuition.
intros;subst;split;trivial.

assert(Hin2: In ptAncestor (getConfigPages ancestor s)).
apply isConfigTable with vaInAncestor;trivial.
intuition.
intros;subst;split;trivial.
assert(Hparet : parentInPartitionList s) by intuition.
unfold parentInPartitionList in *.

unfold disjoint in *.
apply Hdisjoint in Hin1.
unfold not;intros; subst.
now contradict Hin2.
Qed.


Lemma structIndirectionIsnotnull (indSh2ToPrepare indMMUToPrepare phySh2Child descChildphy phyPDChild : page)
(vaToPrepare: vaddr) (l levelpred: level) idxroot s:
(idxroot = sh1idx \/ idxroot = sh2idx) ->
consistency s ->
(Nat.eqb defaultPage indMMUToPrepare) = false ->
indirectionDescription s descChildphy phyPDChild PDidx vaToPrepare l ->
indirectionDescription s descChildphy phySh2Child idxroot vaToPrepare l ->
   false = StateLib.Level.eqb l fstLevel ->
isEntryPage phyPDChild (StateLib.getIndexOfAddr vaToPrepare l) indMMUToPrepare s ->
StateLib.Level.pred l = Some levelpred ->
isEntryPage phySh2Child (StateLib.getIndexOfAddr vaToPrepare l) indSh2ToPrepare s ->
Some l = StateLib.getNbLevel ->
   In descChildphy (getPartitions multiplexer s) ->
(Nat.eqb defaultPage indSh2ToPrepare) = false.

Proof.
intros Hor Hconsistency Hmmunotnull Hmmu Hstruct Hnotfstlevel Hpemmu Hlvlpred Hpestruct Hlvl.
intros.
assert(Hcons : wellFormedShadows idxroot s ).
{ destruct Hor;subst;(unfold consistency in *;intuition). }
unfold indirectionDescription in Hmmu.
destruct Hmmu as ( mmuroot  & idxmmuroot & ( Hnotnullmm &
                    [(Hroot & Hlvlmmu) | (nbL & stop & Hnbl &Hstople &Hind & Hindnotnull & Hstop)])).
+ (* root *)
  subst.
  unfold indirectionDescription in Hstruct.
  destruct Hstruct as ( root  & idxrootstruct & ( Hnotnullstruct &
                  [(Hroot & Hlvlstruct) | (nbL & stop & Hnbl &Hstople &Hind & Hindnotnull & Hstop)])).
  - subst.
    unfold  wellFormedShadows in Hcons.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection phySh2Child vaToPrepare l 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy phyPDChild indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
    simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.

    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
  - subst. rewrite <- Hlvl in Hnbl.
    inversion Hnbl as (Hstop).
    assert(stop = 0).
    { apply ClevelMinus0Eq with nbL;trivial. }
    subst.
    simpl in *.
    inversion Hind.
    subst.
    unfold  wellFormedShadows in Hcons.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection phySh2Child vaToPrepare (CLevel (nbL - 0)) 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy phyPDChild indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
     simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.
    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
+ (* middle *)
  subst.
  unfold wellFormedShadows in Hcons.
  unfold indirectionDescription in Hstruct.
  destruct Hstruct as ( structroot  & idxrootstruct & ( Hnotnullstruct &
                  [(Hroot & Hlvlstruct) | (nbL1 & stop1 & Hnbl1 &Hstople1 &Hind1 & Hindnotnull1 & Hstop1)])).
  - subst phySh2Child.
    subst. rewrite <- Hlvl in Hnbl.
    inversion Hnbl as (Hstop).
    assert(stop = 0).
    { apply ClevelMinus0Eq with nbL;trivial. }
    subst.
    simpl in *.
    inversion Hind.
    subst phyPDChild.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection structroot vaToPrepare (CLevel (nbL - 0)) 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy mmuroot indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
     simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.
    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
  - rewrite <- Hnbl1 in Hnbl.
    inversion Hnbl.
    subst nbL1.
    assert(stop = stop1).
    { assert(nbL - stop = nbL -stop1).
      apply levelEqNat.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      destruct stop1. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia. trivial.
      lia. }
    subst stop1.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection structroot vaToPrepare nbL (stop+1) s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    { apply Hcons with descChildphy mmuroot indMMUToPrepare;trivial.
      apply nextEntryIsPPgetPd;trivial.
      apply getIndirectionStopS1 with phyPDChild;trivial.
      assert(stop < nbL).
      symmetry in Hnotfstlevel. apply levelEqBEqNatFalse0 in Hnotfstlevel.
      apply level_gt in Hnotfstlevel.
      lia.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      lia.
      simpl.
      simpl.
      rewrite <- Hnotfstlevel.
      apply isEntryPageReadPhyEntry1 in Hpemmu.
      rewrite Hpemmu.
      rewrite Hmmunotnull.
      rewrite Hlvlpred.
      trivial. }
      destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
      clear Hcons.
      assert(Hsamelevel: Some x = Some indSh2ToPrepare).
      {
      rewrite <- Hconsind.
      clear Hconsind.
      apply getIndirectionStopS1 with phySh2Child;trivial.
      assert(stop < nbL).
      symmetry in Hnotfstlevel. apply levelEqBEqNatFalse0 in Hnotfstlevel.
      apply level_gt in Hnotfstlevel.
      lia.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      lia.
      simpl.
      simpl.
      rewrite <- Hnotfstlevel.
      apply isEntryPageReadPhyEntry1 in Hpestruct.
      rewrite Hpestruct.
      case_eq(Nat.eqb defaultPage indSh2ToPrepare);intros Hnull.
      apply beq_nat_true in Hnull.
      f_equal. revert Hnull.
      clear. intros.
      destruct defaultPage;simpl in *.
      destruct indSh2ToPrepare;simpl in *.
      subst.
      f_equal.
      apply proof_irrelevance.
      rewrite Hlvlpred.
      trivial. }
      inversion Hsamelevel.
      subst;trivial.
Qed.
Lemma structIndirectionIsnotnullMiddle (indSh2ToPrepare indMMUToPrepare phySh2Child descChildphy phyPDChild : page)
(vaToPrepare: vaddr) (l levelpred: level) (stopl : nat) idxroot s:
(idxroot = sh1idx \/ idxroot = sh2idx) ->
consistency s ->
(Nat.eqb defaultPage indMMUToPrepare) = false ->
indirectionDescription s descChildphy phyPDChild PDidx vaToPrepare (CLevel (l - stopl)) ->
indirectionDescription s descChildphy phySh2Child idxroot vaToPrepare (CLevel (l - stopl)) ->
   false = StateLib.Level.eqb (CLevel (l - stopl)) fstLevel ->
isEntryPage phyPDChild (StateLib.getIndexOfAddr vaToPrepare (CLevel (l - stopl))) indMMUToPrepare s ->
StateLib.Level.pred (CLevel (l - stopl)) = Some levelpred ->
isEntryPage phySh2Child (StateLib.getIndexOfAddr vaToPrepare (CLevel (l - stopl))) indSh2ToPrepare s ->
Some l = StateLib.getNbLevel ->
stopl <= l ->
   In descChildphy (getPartitions multiplexer s) ->
(Nat.eqb defaultPage indSh2ToPrepare) = false.
Proof.
intros Hor Hconsistency Hmmunotnull Hmmu Hstruct Hnotfstlevel Hpemmu Hlvlpred Hpestruct Hlvl.
intros.
assert(Hcons : wellFormedShadows idxroot s ).
{ destruct Hor;subst;(unfold consistency in *;intuition). }
unfold indirectionDescription in Hmmu.
destruct Hmmu as ( mmuroot  & idxmmuroot & ( Hnotnullmm &
                    [(Hroot & Hlvlmmu) | (nbL & stop & Hnbl &Hstople &Hind & Hindnotnull & Hstop)])).
+ (* root *)
  subst.
  unfold indirectionDescription in Hstruct.
  destruct Hstruct as ( root  & idxrootstruct & ( Hnotnullstruct &
                  [(Hroot & Hlvlstruct) | (nbL & stop & Hnbl &Hstople &Hind & Hindnotnull & Hstop)])).
  - subst.
    unfold  wellFormedShadows in Hcons.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection phySh2Child vaToPrepare (CLevel (l - stopl)) 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy phyPDChild indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
    simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.
    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
  - rewrite <- Hnbl in Hlvl.
    inversion Hlvl.
    subst.
    assert(stop = stopl).
    { assert(nbL - stop = nbL -stopl).
      apply levelEqNat.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      destruct nbL.
      simpl in *.
      lia.
      symmetry;trivial.
      lia. }
    subst stopl.
    assert(stop = 0).
    { apply ClevelMinus0Eq with nbL;trivial.
    rewrite <- Hlvlmmu in  Hnbl.
    clear Hor.
    intuition.
     inversion Hnbl as (Hi).
     f_equal.
     rewrite <- Hi.
     lia. }
    subst.
    simpl in *.
    inversion Hind.
    subst.
    unfold  wellFormedShadows in Hcons.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection phySh2Child vaToPrepare (CLevel (nbL - 0)) 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy phyPDChild indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
     simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.
    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
+ (* middle *)
  subst.
  unfold wellFormedShadows in Hcons.
  unfold indirectionDescription in Hstruct.
  destruct Hstruct as ( structroot  & idxrootstruct & ( Hnotnullstruct &
                  [(Hroot & Hlvlstruct) | (nbL1 & stop1 & Hnbl1 &Hstople1 &Hind1 & Hindnotnull1 & Hstop1)])).
  - subst phySh2Child.
    subst. rewrite <- Hlvl in Hnbl.
    inversion Hnbl as (Hstopl).
    subst.
    assert(stop = stopl).
    { assert(l - stop = l -stopl).
      apply levelEqNat.
      clear.
      destruct stop. destruct l.
      simpl in *.
      lia.
      destruct l.
      simpl.
      lia.
      destruct l.
      simpl in *.
      lia.
      symmetry;trivial.
      lia. }
    subst stopl.
    assert(stop = 0).
    { apply ClevelMinus0Eq with l;trivial.
    rewrite <- Hlvlstruct in  Hlvl.
    clear Hor.
    intuition.
     inversion Hlvl as (Hi).
     f_equal.
     rewrite <- Hi.
     lia. }
    subst.
    simpl in *.
    inversion Hind.
    subst phyPDChild.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection structroot vaToPrepare (CLevel (l - 0)) 1 s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    apply Hcons with descChildphy mmuroot indMMUToPrepare;trivial.
    apply nextEntryIsPPgetPd;trivial.
     simpl.
    rewrite <- Hnotfstlevel.
    apply isEntryPageReadPhyEntry1 in Hpemmu.
    rewrite Hpemmu.
    rewrite Hmmunotnull.
    rewrite Hlvlpred.
    trivial.
    destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
    clear Hcons.
    simpl in *.
    rewrite <- Hnotfstlevel in Hconsind.
    apply isEntryPageReadPhyEntry1 in Hpestruct.
    rewrite Hpestruct in Hconsind.
    case_eq(Nat.eqb defaultPage indSh2ToPrepare) ; intros Hisdefaut;
    rewrite Hisdefaut in Hconsind.
    inversion Hconsind as (Hx).
    subst.
    rewrite <- Hconsindnotnull.
    symmetry.
    apply PeanoNat.Nat.eqb_refl.
    trivial.
  - rewrite <- Hnbl1 in Hnbl.
    inversion Hnbl.
    subst nbL1.
    rewrite <- Hnbl1 in Hlvl.
    inversion Hlvl.
    subst.
    rewrite Hstop1 in Hstop.
    symmetry in Hstop.
    assert(stop = stop1).
    { assert(nbL - stop = nbL -stop1).
      apply levelEqNat.
      clear.
      destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      trivial. destruct nbL.
      simpl in *.
      lia. }
    subst stop1.
    assert(stop = stopl).
    { assert(nbL - stop = nbL -stopl).
      apply levelEqNat.
      clear.
      destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      symmetry.
      trivial. destruct nbL.
      simpl in *.
      lia. }
    subst stopl.
    assert(Hconsinst: exists indirection2 : page,
    getIndirection structroot vaToPrepare nbL (stop+1) s = Some indirection2 /\
    (Nat.eqb defaultPage indirection2) = false).
    { apply Hcons with descChildphy mmuroot indMMUToPrepare;trivial.
      apply nextEntryIsPPgetPd;trivial.
      apply getIndirectionStopS1 with phyPDChild;trivial.
      assert(stop < nbL).
      symmetry in Hnotfstlevel. apply levelEqBEqNatFalse0 in Hnotfstlevel.
      apply level_gt in Hnotfstlevel.
      lia.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      lia.
      simpl.
      simpl.
      rewrite <- Hnotfstlevel.
      apply isEntryPageReadPhyEntry1 in Hpemmu.
      rewrite Hpemmu.
      rewrite Hmmunotnull.
      rewrite Hlvlpred.
      trivial. }
      destruct Hconsinst as (x & Hconsind & Hconsindnotnull).
      clear Hcons.
      assert(Hsamelevel: Some x = Some indSh2ToPrepare).
      {
      rewrite <- Hconsind.
      clear Hconsind.
      apply getIndirectionStopS1 with phySh2Child;trivial.
      assert(stop < nbL).
      symmetry in Hnotfstlevel. apply levelEqBEqNatFalse0 in Hnotfstlevel.
      apply level_gt in Hnotfstlevel.
      lia.
      clear.
      destruct stop. destruct nbL.
      simpl in *.
      lia.
      destruct nbL.
      simpl.
      lia.
      lia.
      simpl.
      simpl.
      rewrite <- Hnotfstlevel.
      apply isEntryPageReadPhyEntry1 in Hpestruct.
      rewrite Hpestruct.
      case_eq(Nat.eqb defaultPage indSh2ToPrepare);intros Hnull.
      apply beq_nat_true in Hnull.
      f_equal. revert Hnull.
      clear. intros.
      destruct defaultPage;simpl in *.
      destruct indSh2ToPrepare;simpl in *.
      subst.
      f_equal.
      apply proof_irrelevance.
      rewrite Hlvlpred.
      trivial. }
      inversion Hsamelevel.
      subst;trivial.
Qed.
Lemma proveInitPEntryTablePreconditionToPropagatePrepareProperties s userPage (pt:page) vaValue part nbL pdPart  :
consistency s ->
kernelDataIsolation s ->
In part (getPartitions multiplexer s) ->
(Nat.eqb defaultPage pt) = false ->
nextEntryIsPP part PDidx pdPart s ->
Some nbL = StateLib.getNbLevel ->
isPE pt (StateLib.getIndexOfAddr vaValue fstLevel) s /\ getTableAddrRoot pt PDidx part vaValue s ->
entryPresentFlag pt (StateLib.getIndexOfAddr vaValue fstLevel) true s ->
entryUserFlag pt (StateLib.getIndexOfAddr vaValue fstLevel) true s ->
isEntryPage pt (StateLib.getIndexOfAddr vaValue fstLevel) userPage s ->
initPEntryTablePreconditionToPropagatePrepareProperties s userPage.
Proof.
intros Hcons Hkdi.
unfold initPEntryTablePreconditionToPropagatePrepareProperties.
split.
+ intros.
unfold  consistency in *.
assert (Hcurpart : currentPartitionInPartitionsList s) by intuition.
unfold currentPartitionInPartitionsList in *; trivial.
assert (Hkernel : kernelDataIsolation s) by intuition.
unfold kernelDataIsolation in Hkernel.
unfold Lib.disjoint in Hkernel.
apply Hkernel with part; trivial.
intuition.
eapply physicalPageIsAccessible with pt vaValue (StateLib.getIndexOfAddr vaValue fstLevel)
true nbL true pdPart;intuition;subst;trivial.
+ apply phyPageNotDefault with pt(StateLib.getIndexOfAddr vaValue fstLevel) s;trivial.
unfold consistency in *;intuition.
Qed.


Lemma isPartitionFalseProof  idxRefChild
(currentShadow1 currentPart currentPD phyDescChild ptRefChild ptRefChildFromSh1:page) (descChild :vaddr) idx s :
consistency s ->
In currentPart (getPartitions multiplexer s) ->
nextEntryIsPP currentPart PDidx currentPD s ->
nextEntryIsPP currentPart sh1idx currentShadow1 s ->
(Nat.eqb defaultPage ptRefChild) = false ->
entryPresentFlag ptRefChild (StateLib.getIndexOfAddr descChild fstLevel) true s ->
entryUserFlag ptRefChild (StateLib.getIndexOfAddr descChild fstLevel) true s ->
isEntryPage ptRefChild (StateLib.getIndexOfAddr descChild fstLevel) phyDescChild s ->
nextEntryIsPP (currentPartition s) PDidx currentPD s ->
StateLib.getIndexOfAddr descChild fstLevel = idx ->
isPE ptRefChild idx s ->
getTableAddrRoot ptRefChild PDidx (currentPartition s) descChild s ->
(Nat.eqb ptRefChildFromSh1 defaultPage) = false ->
StateLib.getIndexOfAddr descChild fstLevel = idxRefChild ->
isVE ptRefChildFromSh1 (StateLib.getIndexOfAddr descChild fstLevel) s ->
getTableAddrRoot ptRefChildFromSh1 sh1idx currentPart descChild s ->
isPartitionFalse ptRefChildFromSh1 idxRefChild s.
Proof.
intros.
unfold isPartitionFalse.
unfold consistency in *.
assert(Haccessva : accessibleVAIsNotPartitionDescriptor s) by intuition.
unfold accessibleVAIsNotPartitionDescriptor in *.
assert (Hflag : getPDFlag currentShadow1 descChild s = false).
{ apply Haccessva with currentPart currentPD phyDescChild.
unfold consistency in *.
unfold currentPartitionInPartitionsList in *.
intuition.
apply nextEntryIsPPgetPd; intuition.
apply nextEntryIsPPgetFstShadow;intuition.
apply isAccessibleMappedPage2 with (currentPartition s) ptRefChild;intuition;subst;trivial. }
apply getPDFlagReadPDflag with currentShadow1 descChild currentPart;trivial.
intuition;subst;trivial.
Qed.

Lemma getMaxIndexNotNone :
StateLib.getMaxIndex <> None.
Proof.
unfold StateLib.getMaxIndex.
pose proof tableSizeBigEnough.
case_eq(gt_dec tableSize 0);intros;simpl.
unfold not;intros.
now contradict H1.
lia.
Qed.

Lemma readPhysicalIsPP' LLtable idx nextLLtable s:
isPP' LLtable idx nextLLtable s <->
StateLib.readPhysical LLtable idx (memory s) = Some nextLLtable.
Proof.
intros;
unfold isPP' in *;
unfold StateLib.readPhysical;
case_eq(lookup LLtable idx (memory s) beqPage beqIndex);[intros v Hv|intros Hv].
destruct v;split;intros Hx;try now contradict Hx.
 f_equal; trivial.
inversion Hx;subst;trivial.
split;intros;trivial;try now contradict H.
Qed.
 Lemma pdPartNotNone phyDescChild s:
In phyDescChild (getPartitions multiplexer s) ->
partitionDescriptorEntry s ->
StateLib.getPd phyDescChild (memory s) = None -> False.
Proof.
intros.
unfold partitionDescriptorEntry in *.
  assert(Hexist : (exists entry : page,
          nextEntryIsPP phyDescChild PDidx entry s /\ entry <> defaultPage)).
        apply H0;trivial.
        left;trivial.
        destruct Hexist as (entryPd & Hpp & Hnotnull).
apply nextEntryIsPPgetPd in Hpp.
rewrite Hpp in *.
now contradict H1.
Qed.

Lemma disjointSh2LLstruct tbl newLastLLable sh2 LL partition s:
StateLib.getSndShadow partition (memory s) = Some sh2 ->
StateLib.getConfigTablesLinkedList partition (memory s) = Some LL ->
consistency s ->
In partition (getPartitions multiplexer s) ->
In tbl (getIndirections sh2 s) ->
In newLastLLable (getLLPages LL s (nbPage + 1)) ->
NoDup (getConfigPagesAux partition s) -> tbl <> newLastLLable.
Proof.
intros Hsh2 HLL Hcons Hpart Hi1 Hi2 Hnodup.
unfold getConfigPagesAux in Hnodup.
case_eq(StateLib.getPd partition (memory s));intros pd Hpd.
2:{ assert False. apply pdPartNotNone with partition s;trivial.
    unfold consistency in *;intuition. auto. }
rewrite Hpd in Hnodup.
case_eq(StateLib.getFstShadow  partition (memory s));intros sh1 Hsh1.
2:{ assert False. apply sh1PartNotNone with partition s;trivial.
    unfold consistency in *;intuition. auto. }
rewrite Hsh1 in Hnodup.
rewrite Hsh2 in Hnodup.
rewrite HLL in Hnodup.
apply Lib.NoDupSplit in Hnodup.
destruct Hnodup as (_ & Hnodup).
apply Lib.NoDupSplit in Hnodup.
destruct Hnodup as (_ & Hnodup).
apply Lib.NoDupSplitInclIff in Hnodup.
destruct Hnodup as (_ &  Hdisjoint).
unfold Lib.disjoint in *.
contradict Hi2.
apply Hdisjoint;subst;trivial.
Qed.

Lemma index0Ltfalse (idx:index):
idx < CIndex 0 -> False.
Proof.
intros.
unfold CIndex in H.
case_eq (lt_dec 0 tableSize).
intros.
rewrite H0 in H.
simpl in *. lia.
intros.
contradict H0.
assert (tableSize > tableSizeLowerBound).
apply tableSizeBigEnough.
unfold tableSizeLowerBound in *.
lia.
Qed.

  Lemma InDecOrNot (A:Type) (l:list A ) (elt: A) (P: forall p1 p2 : A, p1 = p2 \/ p1 <> p2):
  In elt l \/ ~In elt l.
  Proof.
  revert elt.
  induction l;simpl.
    right;intuition.
    simpl.
    intros.
    subst.
    assert( a = elt \/ a <> elt )  by apply P.
    destruct H.
    do 2 left;trivial.
    generalize (IHl elt);clear IHl;intros IHl.
    destruct IHl.
    left.
    right;trivial.
    right.
    intuition.
 Qed.
Lemma isEntryPageReadPhyEntry2' table idx phy s:
isEntryPage table idx phy s ->
StateLib.readPhyEntry table idx (memory s) = Some phy.
Proof.
intros Hentrypage.
unfold isEntryPage in *.
unfold StateLib.readPhyEntry.
destruct(lookup table idx (memory s) beqPage beqIndex );
try now contradict Hentrypage.
destruct v; try now contradict Hentrypage.
f_equal;trivial.
Qed.

  Lemma notInGetAccessibleMappedPage ptvaInAncestor ancestor phypage pdAncestor vaInAncestor s  :
    noDupMappedPagesList s ->
    In ancestor (getPartitions multiplexer s) ->
  (forall idx : index,
   StateLib.getIndexOfAddr vaInAncestor fstLevel = idx ->
   isPE ptvaInAncestor idx s /\ getTableAddrRoot ptvaInAncestor PDidx ancestor vaInAncestor s) ->
  (Nat.eqb defaultPage ptvaInAncestor) = false ->
  isEntryPage ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) phypage s ->
  entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s ->
  entryUserFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) false s ->
  nextEntryIsPP ancestor PDidx pdAncestor s ->
    ~In phypage (getAccessibleMappedPages ancestor s).
    Proof.
  intros Hnodupmap Hpart Hget Hnotnull Hep Hpresent Huser Hpdparent.
destruct Hget with (StateLib.getIndexOfAddr vaInAncestor fstLevel)
as (Hpe2 & Hroot2);trivial.
clear Hget.
unfold getTableAddrRoot in Hroot2.
destruct Hroot2 as (_ & Htableroot).
unfold getMappedPages.
assert(Hpd : StateLib.getPd ancestor (memory s) = Some pdAncestor).
apply nextEntryIsPPgetPd;trivial.
apply Htableroot in Hpdparent.
 clear Htableroot.
destruct Hpdparent as (nbL & HnbL & stop & Hstop & Hind ).
unfold getAccessibleMappedPages.
rewrite Hpd.
unfold getAccessibleMappedPagesAux.
rewrite filterOptionInIff.
unfold getAccessibleMappedPagesOption.
rewrite in_map_iff.
unfold not;intros Hfalse.
destruct Hfalse as (x & Hx1 & Hx2).
assert( getMappedPage pdAncestor s vaInAncestor = SomePage phypage).
apply getMappedPageGetIndirection with ancestor ptvaInAncestor nbL;trivial.
apply entryPresentFlagReadPresent;trivial.
apply nextEntryIsPPgetPd;trivial.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
apply nbLevelEq.
rewrite Hnewind.
trivial.

apply isEntryPageReadPhyEntry2';trivial.
assert(getMappedPage pdAncestor s x = SomePage phypage).
apply accessiblePAgeIsMapped;trivial.

assert(Heqvars : exists va1, In va1 getAllVAddrWithOffset0 /\
StateLib.checkVAddrsEqualityWOOffset nbLevel vaInAncestor va1 ( CLevel (nbLevel -1) ) = true )
by apply AllVAddrWithOffset0.
destruct Heqvars as (va1 & Hva1 & Hva11).


assert(x = va1).
{ apply eqMappedPagesEqVaddrs with phypage pdAncestor s;trivial.
  rewrite <- H.
  symmetry.
  apply getMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
      apply getNbLevelEqOption.
  unfold noDupMappedPagesList in *.
  unfold getMappedPages in *.
  apply Hnodupmap in Hpart.
  rewrite Hpd in *.
  unfold getMappedPagesAux in *.
  trivial. }
subst x.

assert (  getAccessibleMappedPage pdAncestor s vaInAncestor = NonePage).
unfold getAccessibleMappedPage.
rewrite <- HnbL.
subst.
assert(Hnewind :getIndirection pdAncestor vaInAncestor nbL  (nbLevel - 1) s
 = Some ptvaInAncestor).
apply getIndirectionStopLevelGT2 with (nbL +1);trivial.
lia.
apply getNbLevelEq in HnbL.
subst.
apply nbLevelEq.
rewrite Hnewind.
rewrite Hnotnull.
apply entryPresentFlagReadPresent in Hpresent.
rewrite Hpresent.
apply entryUserFlagReadAccessible in Huser.
rewrite Huser;trivial.
assert(getAccessibleMappedPage pdAncestor s va1 = getAccessibleMappedPage pdAncestor s vaInAncestor).
symmetry.
apply getAccessibleMappedPageEq with (CLevel (nbLevel - 1)) ;trivial.
apply getNbLevelEqOption.
rewrite  H2 in *.
rewrite H1 in Hx1.
now contradict Hx1.
Qed.
Lemma multiplexerIsAncestor s :
 noDupPartitionTree s ->
 forall partition, parentInPartitionList s ->  partitionDescriptorEntry s ->  isParent s ->  In partition (getPartitions multiplexer s)
-> In partition (getPartitions multiplexer s) ->
    partition <> multiplexer ->
    In multiplexer (getAncestors partition s).
Proof.
intro Hnoduptree.
intro.
unfold getAncestors.
unfold getPartitions at 2.
intros Hparentintree Hpde Hisparent .
revert partition.
induction (nbPage+1);simpl;intuition.
case_eq(StateLib.getParent partition (memory s));[ intros parent Hparent | intros Hparent].
simpl.
assert(Hor : parent = multiplexer \/ parent <> multiplexer) by apply pageDecOrNot.
destruct Hor as [Hor | Hor].
left;trivial.
right.
apply IHn;trivial.
unfold parentInPartitionList in *.
apply Hparentintree with partition;trivial.
apply nextEntryIsPPgetParent;trivial.
apply getPartitionAuxMinus1 with partition;trivial.
unfold getPartitions.
destruct nbPage;left;trivial.
unfold partitionDescriptorEntry in *.
assert((exists entry : page,
nextEntryIsPP partition PPRidx entry s /\ entry <> defaultPage)).
apply Hpde;trivial.
do 4 right;left;trivial.
destruct H0 as (entry & Hi & _).
rewrite nextEntryIsPPgetParent in *.
rewrite Hi in Hparent. now contradict Hparent.
Qed.
Lemma nextIndirectionNotAccessibleInAnyPartition s nextIndirection
(currentPart currentPD: page) ptMMUvaNextInd (vaNextInd : vaddr) ptSh1VaNextInd:
writeAccessibleRecPreparePostcondition currentPart nextIndirection s ->
verticalSharing s ->
partitionsIsolation s ->
consistency s ->
(* noCycleInPartitionTree s ->
noDupMappedPagesList s ->  *)
In currentPart (getPartitions multiplexer s) ->
getTableAddrRoot ptMMUvaNextInd PDidx currentPart vaNextInd s ->
isPE ptMMUvaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) s  ->
entryUserFlag ptMMUvaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) false s ->
entryPresentFlag ptMMUvaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) true s ->
nextEntryIsPP currentPart PDidx currentPD s ->
(Nat.eqb defaultPage ptMMUvaNextInd) = false ->
isEntryPage ptMMUvaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) nextIndirection s ->
(exists va : vaddr,
   isEntryVA ptSh1VaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) va s /\
   beqVAddr defaultVAddr va = true) ->
(Nat.eqb defaultPage ptSh1VaNextInd) = false ->
getTableAddrRoot ptSh1VaNextInd sh1idx currentPart vaNextInd s ->
isVE ptSh1VaNextInd (StateLib.getIndexOfAddr vaNextInd fstLevel) s ->


forall partition1, In partition1 (getPartitions multiplexer s) ->
   ~ In nextIndirection (getAccessibleMappedPages partition1 s).
Proof.
intros * Hancesnotaccecc Hvs Hiso Hcons  Hcurpart Htbl Hpe Huser Hpres Hcurpd Hnotdef Hispage
Hshare Hshdef Htblsh1 Hve * Hpart.
assert( noCycleInPartitionTree s /\ noDupMappedPagesList s ) as (Hcycle & Hnodupmap) by (unfold consistency in *;intuition).
(* check if partition1 is an ancestor of currentPart **)
assert (Hances : In partition1 (getAncestors currentPart s) \/
  ~ In partition1 (getAncestors currentPart s)).
{ apply InDecOrNot.
  apply pageDecOrNot. }
destruct  Hances as [ Hances | Hances].
+ (** partition1 is ancestor of currentPart *)
  assert(Hor : partition1 <> currentPart).
  { unfold consistency in *.
    unfold noCycleInPartitionTree in *.
    apply Hcycle;trivial. }
  unfold writeAccessibleRecPreparePostcondition in *.
  apply Hancesnotaccecc;trivial.
+ (** partition1 is not ancestor of currentPart *)
  (* check if partition1 is the current part or not *)
  assert(Hor : currentPart = partition1 \/ currentPart <> partition1) by apply pageDecOrNot.
  destruct Hor as [Hor | Hor].
  - (** partition1 is the currentPart *)
    subst partition1.
    apply notInGetAccessibleMappedPage with  ptMMUvaNextInd currentPD vaNextInd;trivial.
    intros;subst;split;trivial.
  - (** partition1 is not the currentPart, is not an ancestor **)
    (** partition1 could be a descendent *)
    assert(Hin : In partition1 (getPartitionAux currentPart s (nbPage+1)) \/
            ~ In partition1 (getPartitionAux currentPart s (nbPage+1))).
    { apply InDecOrNot.
      apply pageDecOrNot. }
    destruct Hin as [Hin | Hin].
    * (** partition1 is a descendent *)
       destruct nbPage. simpl in *.
        revert Hin Hor. clear.
        intros.
        intuition. contradict H.
        induction (getChildren currentPart s);simpl; intuition.
        simpl in *.
        destruct Hin as [Hin | Hin]. intuition.
        rewrite in_flat_map in Hin.
        destruct Hin as (x & Hx1 & Hx2).
        assert (Hincl : incl (getAccessibleMappedPages partition1 s)
        (getMappedPages partition1 s)) by apply accessibleMappedPagesInMappedPages.
        unfold incl in *.
        assert(Hderivlist : ~ isDerived currentPart vaNextInd s ).
        { unfold not;intros Hgoal.
          intuition. subst.
          contradict Hgoal.
          eapply vaNotDerived with ptSh1VaNextInd ;trivial.
          intros;split;subst;trivial. }
        assert(Hlist : forall child, In child (getChildren currentPart s) ->
             ~ In nextIndirection (getMappedPages child s)).
        { intros.
          unfold not;intros Hgoal.
          intuition. subst.
          contradict Hgoal.
          apply phyNotDerived  with currentPart currentPD vaNextInd ptMMUvaNextInd ; trivial.
          intros;split;subst;trivial.  }
        unfold incl in *.
        unfold not;intros Hpg.
        apply Hincl in Hpg;clear Hincl.
        simpl .
        assert(Horx : x=partition1 \/ x<> partition1) by apply pageDecOrNot.
        destruct Horx as [Horx | Horx].
        ++ subst.
           apply Hlist in Hx1.
           now contradict Hx1.
        ++ unfold consistency in *.
           unfold noDupPartitionTree in *.
           assert( Hincl2 : incl (getMappedPages partition1 s) (getMappedPages x s)).
           apply verticalSharingRec with n;intuition.
           apply childrenPartitionInPartitionList with currentPart;trivial.
           unfold incl in Hincl2.
           apply Hincl2 in Hpg.
           apply Hlist in Hx1.
           now contradict Hx1.
      * (** partition1 is not a descendent, not the currentPart and not an ancestor *)
          (** continuer sur le fichier UpdatePDFlagTrue : ligne 5030 *)
        (* clear.
        Lemma pageNotAccessibleInCousins s (currentPart : page):
        forall nextIndirection partition1,
        ~ In partition1 (getPartitionAux multiplexer s (nbPage + 1)) ->
        consistency s ->
        In currentPart (getPartitions multiplexer s) ->
        ~ In nextIndirection (getAccessibleMappedPages partition1 s).
        Proof.
        intros * Hin.
        intros.   *)
        assert (Hok:  forall partition, parentInPartitionList s ->  partitionDescriptorEntry s ->  isParent s ->  In partition (getPartitions multiplexer s)
         -> In partition (getPartitions multiplexer s) ->
              partition <> multiplexer ->
              In multiplexer (getAncestors partition s)).
        apply multiplexerIsAncestor;trivial.
        unfold consistency in *. intuition.
        assert(Hnotanc : partition1 <> multiplexer).
        { assert(In multiplexer (getAncestors currentPart s)) .
          { unfold consistency in *; intuition.
            apply Hok;trivial.
            unfold not;intros Hfalse;subst.
            contradict Hin. unfold getPartitions in *;trivial.  }
            unfold not;intros Hfalse;subst.
           now contradict Hances.  }
        assert(Hmulteq :currentPart = multiplexer \/ currentPart <> multiplexer ) by apply pageDecOrNot.
        destruct Hmulteq as [Hmulteq | Hmulteq].
        ++ subst currentPart.
           unfold getPartitions in Hpart.
           now contradict Hin.
        ++ move Hcurpart at bottom.
         unfold consistency in *.
           assert(Hisparent : isParent s) by intuition.
           assert(Hmultnone : multiplexerWithoutParent s) by intuition.
           assert(Hnoduptree : noDupPartitionTree s) by intuition.
         assert( match  closestAncestor currentPart partition1 s with
                  | Some closestAnc =>  True
                  | None => False
         end
         ).
         { case_eq (closestAncestor currentPart partition1 s ); [intros  closestAnc Hclose|
           intros Hclose];trivial.
           revert Hmultnone Hnoduptree Hcurpart Hclose Hisparent  .
           clear.
           { unfold closestAncestor, getPartitions.
             intro. intro.
             revert currentPart partition1.
             assert(Hmult : StateLib.getParent multiplexer (memory s) = None) .
             intuition.
             induction nbPage.
             simpl.
            intros.
            destruct Hcurpart.
            subst.
            rewrite Hmult in *.
            now contradict Hclose.
            contradict H. clear.
            induction (getChildren multiplexer s); simpl; intuition.
            simpl .
            intros.
            destruct Hcurpart.
            subst.
            rewrite Hmult in *.
            now contradict Hclose.
            case_eq(StateLib.getParent currentPart (memory s) ); [intros parent Hparent | intros Hparent];
            rewrite Hparent in *; try now contradict Hclose.
            case_eq ( in_dec pageDec partition1 (getPartitionAux parent s (nbPage + 1)));
            intros i Hi; rewrite Hi in *.
            now contradict Hclose.
            apply IHn with parent partition1;trivial.
            assert (In currentPart (getPartitionAux multiplexer s (n + 2))).
            replace (n + 2) with (S n +1) by lia.
            simpl;right;trivial.
            apply getPartitionAuxMinus1 with currentPart;trivial.
            unfold getPartitions. destruct nbPage;simpl;left;trivial.
          } }
         case_eq(closestAncestor currentPart partition1 s); [intros  closestAnc Hclose|
          intros Hclose];
          rewrite Hclose in *; try now contradict H.
         assert(Hcloseintree : In closestAnc (getPartitions multiplexer s)).
          { revert Hclose Hcurpart.
            unfold consistency in *.
            assert(Hchild : isChild s) by intuition.
            assert(Hparent: isParent s) by intuition.
             assert(Hparenintreet: parentInPartitionList s) by intuition.
            revert Hchild Hparent Hparenintreet.
           clear. intro . intros Hisparent Hparentintree.
           revert currentPart partition1 closestAnc.
           unfold closestAncestor.
           induction (nbPage+1);simpl;intros. now contradict Hclose.
           case_eq( StateLib.getParent currentPart (memory s));[intros parent Hparent | intros Hparent];
           rewrite Hparent in *.
           - case_eq(in_dec pageDec partition1 (getPartitionAux parent s (nbPage + 1)));
           intros i Hi; rewrite Hi in *.
           * inversion Hclose;subst.
             unfold parentInPartitionList in *.
             apply Hparentintree with currentPart;trivial.
             apply nextEntryIsPPgetParent;trivial.
          * apply IHn with parent partition1;trivial.
           unfold parentInPartitionList in *.
           apply Hparentintree with currentPart;trivial.
           apply nextEntryIsPPgetParent;trivial.
        - inversion Hclose; subst. unfold getPartitions.
          destruct nbPage;simpl;left;trivial.
          }
         assert (Hinsubtree1 : In currentPart  (getPartitionAux closestAnc s (nbPage +1))).
          { assert (Hcurpart1 :In currentPart (getPartitions multiplexer s)) by trivial.
          revert Hnoduptree Hmultnone Hclose Hcurpart Hcurpart1.

            unfold consistency in *.
            assert(Hchild : isChild s) by intuition.
            assert(Hparent: isParent s) by intuition.
             assert(Hparenintreet: parentInPartitionList s) by intuition.
            revert Hchild Hparent Hparenintreet.
           clear. intro . intros Hisparent Hparentintree Hnoduptree.
           intro.
           revert currentPart partition1 closestAnc.
           unfold closestAncestor.
           unfold getPartitions  at 1.
           induction (nbPage+1);simpl;intros.
           trivial.
           assert(Hor : closestAnc = currentPart \/ closestAnc <> currentPart) by apply pageDecOrNot.
           destruct Hor as [Hor | Hor].
           left;trivial.
           destruct Hcurpart as [Hcurpart | Hcurpart].
           + subst. assert (Hmult :  StateLib.getParent multiplexer (memory s) = None) by intuition.
           rewrite Hmult in *.
           inversion Hclose. intuition.
           +
           right.
           case_eq( StateLib.getParent currentPart (memory s));[intros parent Hparent | intros Hparent];
           rewrite Hparent in *.
           - case_eq(in_dec pageDec partition1 (getPartitionAux parent s (nbPage + 1)));
           intros i Hi; rewrite Hi in *.
           * inversion Hclose;subst.
           rewrite in_flat_map.
           exists currentPart;split;trivial.
           unfold isChild in *.
           apply Hchild;trivial. destruct n;simpl in *.
           contradict Hcurpart.
           clear. induction   (getChildren multiplexer s) ;simpl;intuition.
           left;trivial.
           * assert(In parent  (getPartitionAux closestAnc s n)).
           apply IHn with partition1;trivial.
           apply getPartitionAuxMinus1 with currentPart;trivial.
           unfold getPartitions. destruct nbPage;simpl;left;trivial.
           unfold parentInPartitionList in *.
           apply Hparentintree with currentPart;trivial.
           apply nextEntryIsPPgetParent;trivial.
             apply getPartitionAuxSn with parent;trivial.
           - inversion Hclose; subst. trivial. }
                   assert (Hinsubtree2 : In partition1  (getPartitionAux closestAnc s (nbPage +1))).
         { assert (Hcurpart1 :In partition1 (getPartitions multiplexer s)) by trivial.
          revert Hclose Hcurpart Hcurpart1.
            unfold consistency in *.
            assert(Hchild : isChild s) by intuition.
            assert(Hparent: isParent s) by intuition.
             assert(Hparenintreet: parentInPartitionList s) by intuition.
            revert Hchild Hparent Hparenintreet.
           clear. intro . intros Hisparent Hparentintree.
           revert currentPart partition1 closestAnc.
           unfold closestAncestor.
(*            unfold getPartitions  at 1. *)
          assert(Hnbpage : nbPage <= nbPage) by lia.
          revert Hnbpage.
          generalize nbPage at 1 3.
           induction n;simpl;intros.
           trivial.
           + case_eq(StateLib.getParent currentPart (memory s));[intros parent Hparent | intros Hparent];
              rewrite Hparent in *.
              - case_eq(in_dec pageDec partition1 (getPartitionAux parent s (nbPage + 1)));
                intros i Hi; rewrite Hi in *.
               * inversion Hclose;subst. trivial.
               *  now contradict Hclose.
              -  inversion Hclose. subst. unfold getPartitions in *;trivial.
         + case_eq( StateLib.getParent currentPart (memory s));[intros parent Hparent | intros Hparent];
            rewrite Hparent in *.
            - case_eq(in_dec pageDec partition1 (getPartitionAux parent s (nbPage + 1)));
              intros i Hi; rewrite Hi in *.
              * inversion Hclose;subst. trivial.
              * apply IHn with parent;trivial. lia.
                unfold parentInPartitionList in *.
                apply Hparentintree with currentPart;trivial.
                apply nextEntryIsPPgetParent;trivial.
          - inversion Hclose; subst. trivial.  }
        assert(Heqclose : partition1 = closestAnc \/ partition1 <> closestAnc) by apply pageDecOrNot.
         destruct Heqclose as [Heqclose | Heqclose].
         **  subst closestAnc.
          assert( partitionDescriptorEntry s /\ parentInPartitionList s) as (Hpde & Hparent).
          { unfold consistency in *. intuition. }
           assert(Hfalse : In partition1 (getAncestors currentPart s)).
           { revert Hclose Hcurpart Hpde Hparent. clear .
           unfold  closestAncestor.
           unfold  getAncestors.
           revert currentPart partition1.
           induction (nbPage + 1).
           simpl in *. intros.
           now contradict Hclose.
           simpl.
           intros.
           case_eq(StateLib.getParent currentPart (memory s) );intros.
           rewrite H in *.
           case_eq ( in_dec pageDec partition1 (getPartitionAux p s (nbPage + 1)));intros;
           rewrite H0 in *.
           inversion Hclose.
           simpl;left;trivial.
           simpl.
           right.
           apply IHn;trivial.
           unfold parentInPartitionList in *.
           apply Hparent with currentPart;trivial.
           apply nextEntryIsPPgetParent;trivial.
            unfold partitionDescriptorEntry in *.
           assert((exists entry : page,
          nextEntryIsPP currentPart PPRidx entry s /\ entry <> defaultPage)).
          apply Hpde;trivial.
          do 4 right;left;trivial.
          destruct H0 as (entry & H1 & _).
          rewrite nextEntryIsPPgetParent in *.
          rewrite H1 in H. now contradict H1. }
        now contradict Hfalse.
        ** assert(Hsub1 : In currentPart
          (flat_map (fun p : page => getPartitionAux p s nbPage) (getChildren closestAnc s))).
         {  replace (nbPage +1) with (1 + nbPage) in * by lia.
             simpl in *.
             apply Classical_Prop.not_or_and in Hin as (_ & Hin).
               destruct  Hinsubtree1 as [Hsub1 | Hsub1]; subst.
      destruct  Hinsubtree2 as [Hsub2 | Hsub2]; subst.
             now contradict Heqclose.  now contradict Hsub2.
         destruct  Hinsubtree2 as [Hsub2 | Hsub2]; subst.
             now contradict Heqclose. trivial. }
      assert(Hsub2 : In partition1
          (flat_map (fun p : page => getPartitionAux p s nbPage) (getChildren closestAnc s))).
          {  replace (nbPage +1) with (1 + nbPage) in * by lia.
            simpl in *.
            apply Classical_Prop.not_or_and in Hin as (_ & Hin).
            destruct  Hinsubtree2 as [Hsub2 | Hsub2]; subst.
            destruct  Hinsubtree1 as [Hsub11 | Hsub11]; subst.
            now contradict Heqclose.  now contradict Heqclose.
            destruct  Hinsubtree1 as [Hsub11 | Hsub11]; subst.
            now contradict Heqclose. trivial. }

             rewrite in_flat_map in Hsub1 , Hsub2.
             destruct Hsub1 as (child1 & Hchild1 &  Hchild11).
             destruct Hsub2 as (child2 & Hchild2 &  Hchild22).
         assert(Horcurpart : child1 = currentPart \/ child1 <> currentPart ) by apply pageDecOrNot.
         destruct Horcurpart as [Horcurpart | Horcurpart].
          --- subst.
          assert (Htrue : currentPart <> child2 ).
          { unfold not;intros Hfasle;subst child2.
            contradict Hin.
            apply getPartitionAuxSbound;trivial.
            }
          assert(Hdisjoint : disjoint (getUsedPages currentPart s) (getUsedPages child2 s)).
          { unfold partitionsIsolation in *.
            apply Hiso with closestAnc;trivial. }
         assert (Hor1 : partition1 = child2 \/ partition1 <> child2) by apply pageDecOrNot.
         destruct Hor1 as [Hor1 |Hor1].
        {  subst child2.
        unfold not;intros Hfalse.
         assert(Hx : In nextIndirection (getMappedPages partition1 s)).
         apply accessibleMappedPagesInMappedPages; trivial. simpl.
        assert(Hincurpart: In nextIndirection (getMappedPages currentPart s)).
        { apply inGetMappedPagesGetTableRoot with vaNextInd ptMMUvaNextInd currentPD;
          trivial. intros ;split;subst;trivial. }
       unfold disjoint in Hdisjoint.
       contradict Hx.
       assert(Hgen : ~ In nextIndirection (getUsedPages partition1 s)).

       apply Hdisjoint. unfold getUsedPages. apply in_app_iff.
       right;trivial.
       contradict Hgen.
       unfold getUsedPages.
       apply in_app_iff.
       right;trivial. }
      { assert(Hincl2:  incl (getMappedPages partition1 s) (getMappedPages child2 s)).
        apply verticalSharingRec with (nbPage-1);trivial.
        unfold consistency in *.
        intuition.
        apply childrenPartitionInPartitionList with closestAnc; trivial.
        intuition.
        destruct nbPage.
        simpl in *. intuition.
        simpl.
        replace    (n - 0 + 1) with (S n) by lia.
        trivial.
        destruct nbPage.
        simpl in *. intuition.
        simpl.
        replace    (n - 0 + 1) with (S n) by lia.
        trivial.
        unfold disjoint in *.
       intros.
       unfold not;intros Hfalse.
       assert(Hx : In nextIndirection (getMappedPages partition1 s)).
       apply accessibleMappedPagesInMappedPages; trivial. simpl.
       unfold incl in *.
       apply Hincl2 in Hx.
       assert(Hincurpart: In nextIndirection (getMappedPages currentPart s)).
        { apply inGetMappedPagesGetTableRoot with vaNextInd ptMMUvaNextInd currentPD;
          trivial. intros ;split;subst;trivial. }
          assert(Hgen : ~ In nextIndirection (getUsedPages child2 s)).
        apply Hdisjoint. unfold getUsedPages. apply in_app_iff.
       right;trivial.
       contradict Hgen.
       unfold getUsedPages.
       apply in_app_iff.
       right;trivial. }
      --- assert(Horpart1 : child2 = partition1 \/ child2 <> partition1 ) by apply pageDecOrNot.
            destruct Horpart1 as [Horpart1 | Horpart1].
            +++ subst.
              assert (Htrue : partition1 <> child1 ).
               { unfold not;intros Hfasle;subst child1.
                contradict Hances.
                revert Hchild11 Horcurpart  Hpart Hcurpart .

                 assert( partitionDescriptorEntry s /\ parentInPartitionList s) as (Hpde & Hparentintree).
          { unfold consistency in *. intuition. }
                revert Hnoduptree Hisparent Hparentintree Hpde.
                clear.
                revert currentPart partition1.
                unfold getAncestors.
                induction nbPage;simpl. intuition.
                intros.
                destruct Hchild11. intuition.
              case_eq(StateLib.getParent currentPart (memory s) ); [intros parent Hparent | intros Hparent].
              simpl.
              assert(Hor : parent = partition1 \/ parent <> partition1) by apply pageDecOrNot.
              destruct Hor as [Hor | or].
              left;trivial.
              right.
              apply IHn;trivial.
              apply getPartitionAuxMinus1 with currentPart;trivial.
              intuition.
              unfold parentInPartitionList in *.
              apply Hparentintree with currentPart;trivial.
              apply nextEntryIsPPgetParent;trivial.
                 unfold partitionDescriptorEntry in *.
           assert((exists entry : page,
          nextEntryIsPP currentPart PPRidx entry s /\ entry <> defaultPage)).
          apply Hpde;trivial.
          do 4 right;left;trivial.
          destruct H0 as (entry & H1 & _).
          rewrite nextEntryIsPPgetParent in *.
          rewrite H1 in Hparent. now contradict H1. }
       assert(Hdisjoint : disjoint (getUsedPages partition1 s) (getUsedPages child1 s)).
          { unfold partitionsIsolation in *.
            apply Hiso with closestAnc;trivial. }
        { assert(Hincl2:  incl (getMappedPages currentPart s) (getMappedPages child1 s)).
           apply verticalSharingRec with (nbPage-1);trivial.
           unfold consistency in *.
           intuition.
           apply childrenPartitionInPartitionList with closestAnc; trivial.

           intuition.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
          unfold disjoint in *.
         intros.
         unfold not;intros Hfalse.
         assert(Hx : In nextIndirection (getMappedPages partition1 s)).
         apply accessibleMappedPagesInMappedPages; trivial.

         assert(Hgen : ~ In nextIndirection (getUsedPages child1 s)).
        apply Hdisjoint. unfold getUsedPages. apply in_app_iff.
       right;trivial.
        assert(Hincurpart: In nextIndirection (getMappedPages currentPart s)).
        { apply inGetMappedPagesGetTableRoot with vaNextInd ptMMUvaNextInd currentPD;
          trivial. intros ;split;subst;trivial. }
        unfold incl in *.
        apply Hincl2 in Hincurpart.
      contradict Hgen.
       unfold getUsedPages.
       apply in_app_iff.
       right;trivial. }
       +++

            assert(Horc : child1 = child2 \/ child1 <> child2) by apply pageDecOrNot.
           destruct Horc as [Horc | Horc].
            subst.
          { contradict Hclose.
          assert( partitionDescriptorEntry s /\ parentInPartitionList s) as (Hpde & Hparentintree).
          { unfold consistency in *. intuition. }
           clear Hinsubtree1 Hinsubtree2 .
           assert(Hnocycle : noCycleInPartitionTree s).
            { unfold consistency in *. intuition. }
           assert(Hchild2intree : In child2 (getPartitions multiplexer s)).
           { apply childrenPartitionInPartitionList with closestAnc;trivial. }
           revert dependent child2.
(*            revert dependent child1.  *)
           revert dependent partition1.
           assert( partitionsIsolation s /\ isChild s /\ verticalSharing s) as (His & Hischild ).
           { unfold consistency in *. intuition. }
           intros partition1 Htmp Htmp1.
           revert Hparentintree Hischild Hmultnone Hnoduptree Hisparent Hcurpart (* Hmulteq *).
           revert dependent closestAnc.
           revert Hpde  Hnocycle His  Hvs Htmp1.
           clear .
           revert currentPart  partition1.
           unfold closestAncestor.
           unfold getAncestors.
           assert(Hnbpage : nbPage <= nbPage) by lia.
           revert Hnbpage.
           generalize nbPage at 1 (* 3 4 5 *) 5    7.
           induction n.
           intros. simpl in *.
           intuition.
           simpl.
           intros.
           case_eq (StateLib.getParent currentPart (memory s));[intros parent Hparent| intros Hparent].
           +  destruct Hchild11 as [Hchild11 | Hchild11];subst.
             now contradict Horcurpart.
           (*  destruct Hchild22 as [Hchild22 | Hchild22];subst.
             now contradict Horpart1.
             apply Classical_Prop.not_or_and in Hin as (_ & Hin). *)
            case_eq (in_dec pageDec partition1
                  (getPartitionAux parent s (nbPage + 1)));intros i Hi.
            unfold not; intros; subst.
            inversion H.
            subst.
           - revert  Hparentintree Hischild Hmultnone Hnoduptree Hparent Hchild11 Hchild1 Horcurpart  His Hischild Hvs Hcurpart Hnocycle Hisparent Hcloseintree.
            clear .
            intros.
           assert(Hchild : In currentPart (getChildren closestAnc s) ).
           unfold isChild in *.
           intuition.  (* isChild *)
           clear Hparent.
         assert(Hii :  incl (getUsedPages currentPart s) (getMappedPages child2 s)).
          apply verticalSharingRec2 with n; trivial.
          apply childrenPartitionInPartitionList with closestAnc;trivial.
          replace (n+1) with (1+n) by lia.
          simpl.
          right;trivial.
           assert(Hmap : In currentPart (getMappedPages child2 s)).
           unfold getUsedPages in *.
           unfold getConfigPages in *.
           intuition.
           assert( disjoint (getUsedPages currentPart s) (getUsedPages child2 s)).
           unfold partitionsIsolation in *.
           apply His with closestAnc;trivial.
           unfold not;intros; subst.
           rewrite in_flat_map in Hchild11.
           destruct Hchild11 as (x & Hx1 & Hx11).
           contradict Hx11.

           apply noCycleInPartitionTree2;trivial.
           intuition.
            unfold disjoint in *.
            unfold getUsedPages in *.

            assert( ~ In currentPart (getConfigPages child2 s ++ getMappedPages child2 s) ).
            apply H.
           unfold getConfigPages.
           simpl;left;trivial.
           rewrite in_app_iff in H0.
           intuition.
           (** contradict Hparent, Hchild11 and Hchild1*)
           - apply IHn with  child2; trivial.
(*            * lia. *)
           * lia.

          * revert  Htmp1 Hparent Hpde Hisparent Hcurpart Hparentintree Hnoduptree Hmultnone.
             clear.
            revert currentPart partition1 parent.
            intros.
            contradict Htmp1.
            assert(Hmult : In multiplexer (getAncestors currentPart s)).
            { apply multiplexerIsAncestor;trivial.
              unfold not;intros; subst.
               assert(Hmult :   StateLib.getParent multiplexer (memory s) = None) by intuition.
              rewrite Hmult in *. now contradict Hparent. }
            unfold getAncestors in *.
            revert dependent currentPart.
            revert dependent partition1.
            revert parent.
            induction (nbPage+1); simpl. intuition.
            intros parent partition1 Hances.
            intros.
            rewrite Hparent in *.
            case_eq(StateLib.getParent parent (memory s) );[intros ances Hances1 | intros Hances1];
            rewrite Hances1 in *; try now contradict Hances.
            simpl in *.
            destruct Hmult as [Hmult | Hmult ].
            subst.
            assert(Hmultnoparent : StateLib.getParent multiplexer (memory s) = None) by intuition.
            rewrite Hances1 in *.
            now contradict Hmultnoparent.
            destruct Hances as [Hances | Hances].
            subst.
            right.
            destruct n;simpl in *; trivial.
            rewrite Hances1 in *.
            simpl;left;trivial.
            right.
            apply IHn with ances;trivial.
            unfold parentInPartitionList in *.
            apply Hparentintree with currentPart;trivial.
            apply nextEntryIsPPgetParent;trivial.
                       * unfold parentInPartitionList in *.
             apply Hparentintree with currentPart;trivial.
             apply nextEntryIsPPgetParent;trivial.
          * unfold not;intros.
            subst. clear Hi. contradict i.
            destruct nbPage;simpl;left;trivial.
            * revert Hchild11.

              revert Hparent Horcurpart Hisparent Hchild2intree Hcurpart
              Hnocycle Hnoduptree Hmultnone Hischild Hparentintree.
              clear.
              intros.
              destruct Hischild as (Hischild & Hvs).
              assert(In currentPart (getPartitionAux child2 s (1+n))).
              simpl.
              right;trivial.
              clear Hchild11.
              revert dependent currentPart.
              revert dependent child2.
              revert parent.
              induction n;
              simpl in * ;intros.
              intuition.
              contradict H0.
              clear.
              induction (getChildren child2 s);simpl in *;intuition.
              assert(child2 = parent \/ child2 <> parent) by apply pageDecOrNot.
              destruct H0.
              left;trivial.
              destruct H.
              intuition.
              right.
              rewrite in_flat_map in H.
              destruct H as (x & Hx & Hxx).
              simpl in *.
              destruct Hxx.
              subst.
              assert(StateLib.getParent currentPart (memory s) = Some child2).
              unfold isParent in Hisparent.
              apply Hisparent;trivial.
              rewrite H in Hparent.
              inversion Hparent. subst. now contradict H0.
              rewrite in_flat_map.
              exists x;split;trivial.
              apply IHn with currentPart;trivial.
              apply childrenPartitionInPartitionList with child2;trivial.
              unfold not;intros;subst.
              rewrite in_flat_map in H.
              destruct H as (x2 & Hx2 & Hx22).
              contradict Hx22.
              apply noCycleInPartitionTree2;trivial.
              right;trivial.
           * unfold not;intros. subst.
            contradict Hchild22.
            clear Hi.
            contradict i.
            revert i.
            clear.
            revert parent partition1.
            induction nbPage.
            simpl;intuition.
            simpl.
            intros.
            intuition.
            right.
            rewrite in_flat_map in *.
            destruct H as (x2 & Hx2 & Hx22).
            exists x2;split;trivial.
            apply IHn;trivial.
           +        unfold partitionDescriptorEntry in *.
           assert((exists entry : page,
          nextEntryIsPP currentPart PPRidx entry s /\ entry <> defaultPage)).
          apply Hpde;trivial.
          do 4 right;left;trivial.
          destruct H as (entry & H1 & _).
          rewrite nextEntryIsPPgetParent in *.
          rewrite H1 in Hparent. now contradict H1.  }
         assert(Hintree : In  closestAnc (getPartitions multiplexer s)) by trivial.
         assert(Horc1 : partition1 = child2 \/ partition1 <> child2) by apply pageDecOrNot.
         { destruct Horc1 as [Horc1 | Horc1].
           subst child2.
           **
           assert(Horc1 : currentPart = child1 \/ currentPart <> child1) by apply pageDecOrNot.
           destruct Horc1 as [Horc1 | Horc1].
           --- subst child1. now contradict Horpart1.
           --- now contradict Horpart1.

            ** assert(Horc2 : currentPart = child1 \/ currentPart <> child1) by apply pageDecOrNot.
           destruct Horc2 as [Horc2 | Horc2].
           --- subst child1. now contradict Horcurpart.
           ---   assert(Hincl1 :  incl (getMappedPages currentPart s) (getMappedPages child1 s)).
           apply verticalSharingRec with (nbPage-1);trivial.
           unfold consistency in *.
           intuition.
           apply childrenPartitionInPartitionList with closestAnc; trivial.
           intuition.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
            assert(Hincl2:  incl (getMappedPages partition1 s) (getMappedPages child2 s)).
           apply verticalSharingRec with (nbPage-1);trivial.
           unfold consistency in *.
           intuition.
           apply childrenPartitionInPartitionList with closestAnc; trivial.
           intuition.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
           destruct nbPage.
           simpl in *. intuition.
           simpl.
           replace    (n - 0 + 1) with (S n) by lia.
           trivial.
            assert(Hincurpart: In nextIndirection (getMappedPages currentPart s)).
        { apply inGetMappedPagesGetTableRoot with vaNextInd ptMMUvaNextInd currentPD;
          trivial. intros ;split;subst;trivial. }
           assert(Hdisjoint : disjoint (getUsedPages child1 s) (getUsedPages child2 s)).
           unfold partitionsIsolation in *.
           apply Hiso with closestAnc; trivial.
           unfold disjoint in *.
           intros.
           unfold not;intros Hx.
           assert(mapped1 : In nextIndirection (getMappedPages partition1 s)).
           apply accessibleMappedPagesInMappedPages; trivial.
           unfold incl in *.
           apply Hincl2 in mapped1.
           simpl.
           assert(Hmap: In nextIndirection (getUsedPages child1 s)).
           unfold getUsedPages.
           apply in_app_iff.
           right.
           apply Hincl1; trivial.
           apply Hdisjoint in Hmap.
           contradict Hmap.


           unfold getUsedPages.

           apply in_app_iff.
           right. trivial. }
Qed.
 *)
