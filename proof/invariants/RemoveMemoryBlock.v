(*******************************************************************************)
(*  © Université de Lille, The Pip Development Team (2015-2021)                *)
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

Require Import Model.ADT Model.Lib Model.MAL.
Require Import Core.Services.

Require Import Proof.Isolation Proof.Hoare Proof.Consistency Proof.WeakestPreconditions
Proof.StateLib (*Proof.InternalLemmas Proof.InternalLemmas2 Proof.DependentTypeLemmas)*).

Require Import Invariants (*GetTableAddr UpdateShadow2Structure UpdateShadow1Structure
               PropagatedProperties MapMMUPage*) findBlockInKSWithAddr.

Require Import Bool List EqNat.

Require Import Model.Monad.

Module WP := WeakestPreconditions.

(** * Summary 
    This file contains the invariant of [addVaddr]. 
    We prove that this PIP service preserves the isolation property *)

Lemma removeMemoryBlock (idBlockToRemove: paddr) :
{{fun s => partitionsIsolation s   /\ kernelDataIsolation s /\ verticalSharing s /\ consistency s }} 
removeMemoryBlock idBlockToRemove
{{fun _ s  => partitionsIsolation s   /\ kernelDataIsolation s /\ verticalSharing s /\ consistency s }}.
Proof.
unfold removeMemoryBlock.
(** getCurPartition **)
eapply WP.bindRev.
eapply WP.weaken. 
eapply Invariants.getCurPartition.
cbn.
intros.
intuition.
pose proof (HP := conj H0 (conj H H1)).
exact HP.
intro currentPart.
(** findBlockInKSWithAddr **)
eapply WP.bindRev.
eapply findBlockInKSWithAddr.findBlockInKSWithAddr.
intro blockToShareInCurrPartAddr.
(** compareAddrToNull **)
eapply WP.bindRev.
eapply Invariants.compareAddrToNull.
intro addrIsNull.
case_eq addrIsNull.
{ (* case_eq addrIsNull = true *)
	intros. eapply WP.weaken.
  eapply WP.ret.
  simpl. intros.
  intuition.
}
	(* case_eq addrIsNull = false *)
	intros.
	(* Internal.removeBlockInChildAndDescendants *)
	eapply bindRev.
{





(*(** compareVAddrToNull **) 
eapply WP.bindRev.
eapply Invariants.compareVAddrToNull.
intro vaInCurrentPartitionIsnull. simpl.
case_eq vaInCurrentPartitionIsnull.
{ intros.
  eapply WP.weaken.
  eapply WP.ret .
  simpl. intros.
  intuition. }
intros HvaInCurrentPartition. 
subst.
  (** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.compareVAddrToNull.
intro descChildIsnull. simpl.
case_eq descChildIsnull.
{ intros.
  eapply WP.weaken.
  eapply WP.ret .
  simpl. intros.
  intuition. }
intros HdescChildIsnull. 
subst.  
(** checkKernelMap *)
eapply WP.bindRev.
eapply WP.weaken.   
eapply Invariants.checkKernelMap.
intros. simpl. pattern s in H. eexact H. 
intro.
repeat (eapply WP.bindRev; [ eapply WP.weaken ; 
              [ apply Invariants.checkKernelMap | intros; simpl; pattern s in H; eexact H ]
                                | simpl; intro ]).
                                simpl.
case_eq (negb a && negb a0 );[|intros;eapply weaken;[ eapply WP.ret;trivial|
  intros;simpl;intuition]].
intro Hkmap.
repeat rewrite andb_true_iff in Hkmap.
try repeat rewrite and_assoc in Hkmap.
repeat rewrite negb_true_iff in Hkmap. 
intuition.
subst.*)
(** checkRights **)

eapply WP.bindRev.
{
eapply weaken.
eapply Invariants.checkRights.
simpl.
intros.
split.
apply H0.
intuition.
destruct H3 ; destruct H3. exists x. apply H3.
}


(*destruct H1.
simpl in *.
 eexact H.
intros right.
case_eq right; intros Hright;[|intros;eapply weaken;[ eapply WP.ret;trivial|
  intros;simpl;intuition]].
subst.
(** getCurPartition **)
eapply WP.bindRev.
eapply WP.weaken. 
eapply Invariants.getCurPartition .
cbn. 
intros. 
pattern s in H. 
eexact H.
intro currentPart.
(** getNbLevel **)
eapply WP.bindRev.
eapply weaken.
eapply Invariants.getNbLevel.
simpl. intros.
pattern s in H.
eexact H.
intros level.
simpl.*)
intro rcheck.
destruct rcheck.
2 : {
simpl.
eapply weaken. eapply WP.ret;trivial. intuition.
}

simpl in *.
(** checkChildOfCurrPart **)
eapply WP.bindRev.
{ eapply weaken.
 	apply checkChildOfCurrPart.checkChildOfCurrPart.
	intros. simpl. split. apply H0. apply H0. (* destruct H0 as (HP & HcurrPart). destruct HP as (Hblock & HH).
	destruct Hblock as (HA & Hbeq). destruct HA as (HQ&Hc).
	apply HQ.*)
	(*split. apply HQ. split. unfold consistency in HQ. intuition.
 intuition.*)
}

intro isChildCurrPart. simpl.
destruct isChildCurrPart.
2 : { simpl. eapply weaken. apply WP.ret. intros. simpl. apply H0. }
(** readBlockStartFromBlockEntryAddr*)
eapply WP.bindRev.
{
	eapply weaken.
-	apply Invariants.readBlockStartFromBlockEntryAddr.
-	intros. simpl. split. apply H0.
	unfold isBE. destruct H0. destruct H1. destruct H2. destruct H2. destruct H3.
	destruct H3.
	rewrite -> H3. trivial.
	(*unfold checkChild in H2.
	Search (true = _).
	apply Is_true_eq_right in H2. unfold Is_true in H2.
	
	assert(H'' := 

destruct H2. destruct H3. destruct H3.  rewrite -> H3. trivial.*)
}

intro globalIdPDChild. simpl.
(** readPDNbFreeSlots *)
eapply WP.bindRev.
{
	eapply weaken.
-	apply Invariants.readPDNbFreeSlots.
- intros. simpl. split. apply H0. intuition. unfold isPDT.
	unfold consistency in *. destruct H11. destruct H11.
	intuition. unfold PDTIfPDFlag in *. destruct H5. destruct H0 with idPDchild x.
	destruct H5. assumption. destruct H14.



unfold entryStartAddr in *. unfold entryPDT in *. rewrite -> H14 in H16.
rewrite H14 in H2. rewrite <- H2 in H16.
destruct (lookup globalIdPDChild (memory s) beqAddr) eqn:Hlookup.
	destruct v eqn:Hv. repeat trivial. trivial. repeat trivial. trivial.
	trivial. trivial.
}

	intro nbfreeslots. eapply bindRev. apply zero.

	intro zero.

	eapply bindRev.
{ (*MALInternal.Index.leb nbfreeslots zero *)
	eapply weaken. apply Invariants.leb.
	intros. simpl. apply H0.
}
	intro isFull.
	case_eq (isFull).
	{ (*case_eq isFull = false *)
		intros. eapply weaken. apply WP.ret.
		intros. simpl. apply H1.
	}
	(*case_eq isFull = true *)
	intros. eapply bindRev.
{
	eapply weaken. apply readBlockAccessibleFromBlockEntryAddr. 
	intros. simpl. split. apply H1.
	unfold isBE. intuition. destruct H8.
	rewrite -> H8. trivial.

}
	intro addrIsAccessible.
	case_eq (addrIsAccessible).
	2 : { (*case_eq addrIsAccessible = false *)
		intros. simpl. eapply weaken. apply WP.ret.
		intros. simpl. apply H2.
	}
	(*case_eq addrIsAccessible = true *)
	intros. simpl. eapply bindRev.

{ eapply weaken. apply readBlockPresentFromBlockEntryAddr.
	intros. simpl. split. apply H2.
	unfold isBE. intuition. destruct H10.
	rewrite -> H10. trivial.
}
	
	intro addrIsPresent.
	case_eq (addrIsPresent).
	2 : { (*case_eq addrIsPresent = false *)
		intros. simpl. eapply weaken. apply WP.ret.
		intros. simpl. apply H3.
	}
	(*case_eq addrIsPresent = true *)
	intros. simpl. eapply bindRev.
{	eapply weaken. apply readBlockStartFromBlockEntryAddr.
	intros. simpl. split. apply H3.
	unfold isBE. intuition. destruct H15. destruct H15.
	rewrite -> H15. trivial.
}

	intro blockstart.
	eapply bindRev.
{	eapply weaken. apply readBlockEndFromBlockEntryAddr.
	intros. simpl. split. apply H3.
	unfold isBE. intuition. destruct H16. destruct H16.
	rewrite -> H16. trivial.
}
	intro blockend.

(* Start of structure modifications *)
	
eapply weaken.

(* 1) traiter les instructions de modifications en paquet *)


	intro blockToShareChildEntryAddr.




 now exists a.  }
  rewrite assoc.
  eapply bindRev.
  (** getFstShadow **)
  eapply WP.weaken. 
  eapply Invariants.getFstShadow. cbn.
  intros s H.
  split.
  pattern s in H.
  eexact H.
  unfold consistency in *.
  unfold partitionDescriptorEntry in *.
  intuition.
  simpl.
  intros currentShadow1.
  rewrite assoc.
  (** StateLib.getIndexOfAddr **)                
  eapply WP.bindRev.
  eapply WP.weaken.
  eapply Invariants.getIndexOfAddr.
  { simpl. intros.
    pattern s in H.
    eexact H.  }
  intro idxDescChild. simpl.
  rewrite assoc.
  (** getTableAddr **)
  eapply WP.bindRev.
  eapply WP.weaken. 
  apply getTableAddr.
  simpl.
  intros s H.
  split.
  pattern s in H. 
  eexact H. subst.
  split. 
  intuition.
  split. 
  instantiate (1:= currentPart).
  intuition. 
  subst.
  unfold consistency in *. 
  unfold  currentPartitionInPartitionsList in *. 
  intuition.
  instantiate (1:= sh1idx).
  split. intuition.
  assert(Hcons : consistency s) by intuition.
  assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
  assert(Hcp : currentPart = currentPartition s) by intuition.
  assert (H0 : nextEntryIsPP currentPart sh1idx currentShadow1 s) by intuition.
  exists currentShadow1.
  split. intuition.
  
  unfold consistency in *.
  destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
  unfold partitionDescriptorEntry in Hpd.
  assert (sh1idx = PDidx \/ sh1idx = sh1idx \/ sh1idx = sh2idx \/  sh1idx  = sh3idx
  \/  sh1idx  = PPRidx \/  sh1idx = PRidx) as Htmp 
  by auto.
      generalize (Hpd  (currentPartition s)  Hpr); clear Hpd; intros Hpd.
  generalize (Hpd sh1idx Htmp); clear Hpd; intros Hpd.
  destruct Hpd as (Hidxpd & _& Hentry). 
  destruct Hentry as (page1 & Hpd & Hnotnull).
  subst.
  split.
  unfold nextEntryIsPP in *.
  destruct (StateLib.Index.succ sh1idx); try now contradict H0.
  destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex);
  try now contradict H0.
  destruct v ; try now contradict H0.
  subst; assumption.
  subst. left. split;intuition.
  intro ptDescChild. simpl.
  (** simplify the new precondition **)     
  eapply WP.weaken.
  intros.
  2: {
  intros.
  destruct H as (H0 & H1).
  assert ( (getTableAddrRoot' ptDescChild sh1idx currentPart descChild s /\ ptDescChild = defaultPage) \/
  (forall idx : index,
  StateLib.getIndexOfAddr descChild fstLevel = idx ->
  isVE ptDescChild idx s /\ getTableAddrRoot ptDescChild sh1idx currentPart descChild s  )).
  { destruct H1 as [H1 |(Hi & Hi1 & H1)].
    + left. trivial. 
    + right. intros idx Hidx.
      generalize (H1 idx Hidx);clear H1;intros H1.
      destruct H1 as [(Hpe &Htrue) |[ (_& Hfalse) | (_&Hfalse) ]].
      - split; assumption.
      - contradict Hfalse. 
        symmetrynot. 
        apply idxSh2idxSh1notEq.
      - contradict Hfalse. 
        symmetrynot. apply idxPDidxSh1notEq.  }
  assert (HP := conj H0 H).
  pattern s in HP.
  eapply HP. }
  rewrite assoc.
  (** comparePageToNull **) 
  eapply WP.bindRev.
  eapply Invariants.comparePageToNull.
  intro ptDescChildIsnull. simpl.
  case_eq ptDescChildIsnull.
  { intros.
    eapply WP.weaken.
    eapply WP.ret .
    simpl. intros.
    intuition. }
  intros HptDescChildIsnull. 
  subst.
  (* readPDflag *)
  eapply bindRev.
  eapply weaken.
  eapply Invariants.readPDflag.
  simpl;intros.
  split.
  destruct H as (((Ha1 & Ha2) & Ha3) & Ha4).
  assert (Hnewget : isVE ptDescChild (StateLib.getIndexOfAddr descChild fstLevel) s /\
       getTableAddrRoot ptDescChild sh1idx currentPart descChild s /\ 
       (Nat.eqb defaultPage ptDescChild) = false).
  { destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
    + subst.
      apply beq_nat_false in Ha4.
      now contradict Ha4.
    + destruct Ha3 with (StateLib.getIndexOfAddr descChild fstLevel);trivial.
      intuition. }
  assert (HP := conj (conj Ha1 Ha2) Hnewget).
  pattern s in HP.
  eexact HP.
  destruct H as (H & Htrue).
  destruct H as (H & Hor).
  destruct Hor as [(Hor & Hfalse) | Hor].
  subst.
  apply beq_nat_false in Htrue.
  now contradict Htrue.
  destruct H as (H & Hidx).
  subst.
  destruct Hor with (StateLib.getIndexOfAddr descChild fstLevel);
  trivial.
  intros ischild;simpl in *.
  intros.
  case_eq ischild; intros Hischild;[|intros;eapply weaken;[ eapply WP.ret;trivial|
  intros;simpl;intuition]].
  subst.
(** end checkChild *)
(** getFstShadow **)
eapply bindRev.
eapply WP.weaken. 
eapply Invariants.getFstShadow. cbn.
intros s H.
split.
pattern s in H.
eexact H.
unfold consistency in *.
unfold partitionDescriptorEntry in *.
intuition.
simpl.
intros currentShadow.
(** getTableAddr **)
eapply WP.bindRev.
eapply WP.weaken. 
apply getTableAddr.
simpl.
intros s H.  
assert(Hsh1eq : currentShadow = currentShadow1).
apply getSh1NextEntryIsPPEq with currentPart s;trivial.
intuition.
apply nextEntryIsPPgetFstShadow;intuition.
subst currentShadow1.
destruct H as (H & _).
split. 
pattern s in H. 
eexact H. subst.
split. 
intuition.
split. 
instantiate (1:= currentPart).
unfold consistency in *. 
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
intuition.
instantiate (1:= sh1idx).
split. intuition.
assert(Hcons : consistency s) by intuition.
assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
assert(Hcp : currentPart = currentPartition s) by intuition.
assert (H0 : nextEntryIsPP currentPart sh1idx currentShadow s) by intuition.
exists currentShadow.
split. intuition.
unfold consistency in *.
destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
unfold partitionDescriptorEntry in Hpd.
assert (sh1idx = PDidx \/ sh1idx = sh1idx \/ sh1idx = sh2idx \/  sh1idx  = sh3idx
\/  sh1idx  = PPRidx \/  sh1idx = PRidx) as Htmp 
by auto.
    generalize (Hpd  (currentPartition s)  Hpr); clear Hpd; intros Hpd.
generalize (Hpd sh1idx Htmp); clear Hpd; intros Hpd.
destruct Hpd as (Hidxpd & _& Hentry). 
destruct Hentry as (page1 & Hpd & Hnotnull).
subst.
split.
unfold nextEntryIsPP in *.
destruct (StateLib.Index.succ sh1idx); try now contradict H0.
destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex);
try now contradict H0.
destruct v ; try now contradict H0.
subst; assumption.
subst. left. split;intuition.
intro ptVaInCurPart. simpl.
(** simplify the new precondition **)     
eapply WP.weaken.
intros.
2: {
intros.
destruct H as (H0 & H1).
assert ( (getTableAddrRoot' ptVaInCurPart sh1idx currentPart vaInCurrentPartition s /\ ptVaInCurPart = defaultPage) \/
(forall idx : index,
StateLib.getIndexOfAddr vaInCurrentPartition fstLevel = idx ->
isVE ptVaInCurPart idx s /\ getTableAddrRoot ptVaInCurPart sh1idx currentPart vaInCurrentPartition s  )).
{ destruct H1 as [H1 |(Hi & Hi1 & H1)].
  + left. trivial. 
  + right. intros idx Hidx.
    generalize (H1 idx Hidx);clear H1;intros H1.
    destruct H1 as [(Hpe &Htrue) |[ (_& Hfalse) | (_&Hfalse) ]].
    - split; assumption.
    - contradict Hfalse. 
      symmetrynot. 
      apply idxSh2idxSh1notEq.
    - contradict Hfalse. 
      symmetrynot. apply idxPDidxSh1notEq.  }
assert (HP := conj H0 H).
pattern s in HP.
eapply HP. }
(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.comparePageToNull.
intro childListSh1Isnull. simpl.
case_eq childListSh1Isnull.
{ intros. eapply WP.weaken.  eapply WP.ret . simpl. intros.
 pattern false, s in H0.
 eapply H0. }
intros HptVaInCurPartNotNull. clear HptVaInCurPartNotNull.
(** StateLib.getIndexOfAddr **)                
eapply WP.bindRev.
eapply WP.weaken.
eapply Invariants.getIndexOfAddr.
{ simpl. intros.
    destruct H as ((Ha1  & Ha3) & Ha4).
  assert (Hnewget : isVE ptVaInCurPart (
  StateLib.getIndexOfAddr vaInCurrentPartition fstLevel) s /\
       getTableAddrRoot ptVaInCurPart sh1idx currentPart vaInCurrentPartition s /\ 
       (Nat.eqb defaultPage ptVaInCurPart) = false).
  { destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
    + subst.
      apply beq_nat_false in Ha4.
      now contradict Ha4.
    + destruct Ha3 with (StateLib.getIndexOfAddr vaInCurrentPartition fstLevel);trivial.
      intuition. }
   subst.
  assert (HP := conj Ha1 Hnewget).
  pattern s in HP.
  eexact HP.  }
intro idxvaInCurPart.
simpl. 
(** checkDerivation **)
unfold Internal.checkDerivation.
rewrite assoc.
(** readVirEntry **)
eapply WP.bindRev.
eapply WP.weaken.
eapply Invariants.readVirEntry. 
{ simpl. intros.
  split.
  pattern s in H.
  eexact H.
  intuition. subst;trivial. }
intros vainve.
(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.compareVAddrToNull.
intro isnotderiv. simpl.
(** getPd **)
eapply bindRev.
eapply WP.weaken. 
eapply Invariants.getPd.
cbn.
intros s H.
split.
pattern s in H.
eexact H.
split.
unfold consistency in *.
unfold partitionDescriptorEntry in *.
intuition.
simpl.
unfold consistency in *.
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
intuition.
intros currentPD.
(** getTableAddr **)
eapply WP.bindRev.
eapply WP.weaken. 
apply getTableAddr.
simpl.
intros s H.  
split. 
pattern s in H. 
eexact H. subst.
split. 
intuition.
split. 
instantiate (1:= currentPart).
unfold consistency in *. 
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
intuition.
instantiate (1:= PDidx).
split. intuition.
assert(Hcons : consistency s) by intuition.
assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
assert(Hcp : currentPart = currentPartition s) by intuition.
assert (H0 : nextEntryIsPP currentPart PDidx currentPD s) by intuition.
exists currentPD.
split. intuition.
unfold consistency in *.
destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
unfold partitionDescriptorEntry in Hpd.
assert (PDidx = PDidx \/ PDidx = sh1idx \/ PDidx = sh2idx \/  PDidx  = sh3idx
\/  PDidx  = PPRidx \/  PDidx = PRidx) as Htmp 
by auto.
    generalize (Hpd  (currentPartition s)  Hpr); clear Hpd; intros Hpd.
generalize (Hpd PDidx Htmp); clear Hpd; intros Hpd.
destruct Hpd as (Hidxpd & _& Hentry). 
destruct Hentry as (page1 & Hpd & Hnotnull).
subst.
split.
unfold nextEntryIsPP in *.
destruct (StateLib.Index.succ PDidx); try now contradict H0.
destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex);
try now contradict H0.
destruct v ; try now contradict H0.
subst; assumption.
subst. left. split;intuition.
intro ptVaInCurPartpd. simpl.
(** simplify the new precondition **)     
eapply WP.weaken.
intros.
2: {
intros.
destruct H as (H0 & H1).
assert ( (getTableAddrRoot' ptVaInCurPartpd PDidx currentPart vaInCurrentPartition s /\ ptVaInCurPartpd = defaultPage) \/
(forall idx : index,
StateLib.getIndexOfAddr vaInCurrentPartition fstLevel = idx ->
isPE ptVaInCurPartpd idx s /\ getTableAddrRoot ptVaInCurPartpd PDidx currentPart vaInCurrentPartition s  )).
{ destruct H1 as [H1 |(Hi & Hi1 & H1)].
  + left. trivial. 
  + right. intros idx Hidx.
    generalize (H1 idx Hidx);clear H1;intros H1.
    destruct H1 as [(Hpe &Htrue) |[ (Hpe& Hfalse) | (Hpe&Hfalse) ]].
    - (*  split; assumption.
    - *) contradict Htrue.
      apply idxPDidxSh1notEq.
    - contradict Hfalse.
      apply idxPDidxSh2notEq.
    - split;trivial. }
assert (HP := conj H0 H).
pattern s in HP.
eapply HP. }
(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.comparePageToNull.
intro ptVaInCurPartpdIsnull. simpl.
case_eq ptVaInCurPartpdIsnull.
{ intros. eapply WP.weaken.
  eapply WP.ret . simpl.
  intros. intuition. }
intros HptVaInCurPartpdNotNull. subst.
(** readAccessible **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readAccessible. simpl.
  intros.
  destruct H as ((Ha1 & Ha3) & Ha4).
  assert (Hnewget : isPE ptVaInCurPartpd (
  StateLib.getIndexOfAddr vaInCurrentPartition fstLevel) s /\
       getTableAddrRoot ptVaInCurPartpd PDidx currentPart
         vaInCurrentPartition s /\ 
       (Nat.eqb defaultPage ptVaInCurPartpd) = false).
  { destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
    + subst.
      apply beq_nat_false in Ha4.
      now contradict Ha4.
    + destruct Ha3 with (StateLib.getIndexOfAddr vaInCurrentPartition fstLevel);trivial.
      intuition. }
   subst.
 split.
  assert (HP := conj Ha1 Hnewget).
  pattern s in HP.
  eexact HP. clear Ha3. 
  intuition. subst;trivial. }
intros accessiblesrc. simpl.
(** readPresent **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readPresent. simpl.
  intros.
  split.
  pattern s in H.
  eexact H. 
  intuition. subst;trivial. }
intros presentmap. simpl.
(** getTableAddr : to return the physical page of the descChild   **)
eapply WP.bindRev.
eapply WP.weaken. 
apply getTableAddr.
simpl.
intros s H.  
split. 
pattern s in H. 
eexact H. subst.
split. 
intuition.
split. 
instantiate (1:= currentPart).
unfold consistency in *. 
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
intuition.
instantiate (1:= PDidx).
split. intuition.
assert(Hcons : consistency s) by intuition.
assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
assert(Hcp : currentPart = currentPartition s) by intuition.
assert (H0 : nextEntryIsPP currentPart PDidx currentPD s) by intuition.
exists currentPD.
split. intuition.
unfold consistency in *.
destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
unfold partitionDescriptorEntry in Hpd.
assert (PDidx = PDidx \/ PDidx = sh1idx \/ PDidx = sh2idx \/  PDidx  = sh3idx
\/  PDidx  = PPRidx \/  PDidx = PRidx) as Htmp 
by auto.
    generalize (Hpd  (currentPartition s)  Hpr); clear Hpd; intros Hpd.
generalize (Hpd PDidx Htmp); clear Hpd; intros Hpd.
destruct Hpd as (Hidxpd & _& Hentry). 
destruct Hentry as (page1 & Hpd & Hnotnull).
subst.
split.
unfold nextEntryIsPP in *.
destruct (StateLib.Index.succ PDidx); try now contradict H0.
destruct (lookup (currentPartition s) i (memory s) beqPage beqIndex);
try now contradict H0.
destruct v ; try now contradict H0.
subst; assumption.
subst. left. split;intuition.
intro ptDescChildpd. simpl.
(** simplify the new precondition **)     
eapply WP.weaken.
intros.
2: {
intros.
destruct H as (H0 & H1).
assert ( (getTableAddrRoot' ptDescChildpd PDidx currentPart descChild s /\ ptDescChildpd = defaultPage) \/
(forall idx : index,
StateLib.getIndexOfAddr descChild fstLevel = idx ->
isPE ptDescChildpd idx s /\ getTableAddrRoot ptDescChildpd PDidx currentPart descChild s  )).
{ destruct H1 as [H1 |(Hi & Hi1 & H1)].
  + left. trivial. 
  + right. intros idx Hidx.
    generalize (H1 idx Hidx);clear H1;intros H1.
    destruct H1 as [(Hpe &Htrue) |[ (Hpe& Hfalse) | (Hpe&Hfalse) ]].
    - (*  split; assumption.
    - *) contradict Htrue.
      apply idxPDidxSh1notEq.
    - contradict Hfalse.
      apply idxPDidxSh2notEq.
    - split;trivial. }
assert (HP := conj H0 H).
pattern s in HP.
exact HP. }
(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.comparePageToNull.
intro ptDescChildpdIsnull. simpl.
case_eq ptDescChildpdIsnull.
{ intros. eapply WP.weaken.
  eapply WP.ret . simpl.
  intros. intuition. }
intros HptDescChildpdNotNull. subst.
(** StateLib.getIndexOfAddr **)                
eapply WP.bindRev.
eapply WP.weaken.
eapply Invariants.getIndexOfAddr.
{ simpl. intros.
  destruct H as ((Ha1 & Ha3) & Ha4).
  assert (Hnewget : isPE ptDescChildpd 
  (StateLib.getIndexOfAddr descChild fstLevel) s /\
       getTableAddrRoot ptDescChildpd PDidx currentPart descChild s /\ 
       (Nat.eqb defaultPage ptDescChildpd) = false).
  { destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
    + subst.
      apply beq_nat_false in Ha4.
      now contradict Ha4.
    + destruct Ha3 with (StateLib.getIndexOfAddr descChild fstLevel);trivial.
      intuition. }
   subst.
  assert (HP := conj Ha1 Hnewget).
  pattern s in HP.
  eexact HP. }
intro idxDescChild1.
simpl. 
(** readPresent **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readPresent. simpl.
  intros.
  split.
  pattern s in H.
  eexact H. 
  intuition. subst;trivial. }
intros presentDescPhy. simpl.
case_eq (negb presentDescPhy);intros Hlegit;subst.
eapply weaken. eapply WP.ret. 
simpl. intros;intuition.
(** readPhyEntry **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readPhyEntry. simpl.
  intros.
  split.
  pattern s in H.
  eapply H. 
  subst.
  intuition;subst;trivial. }
intros phyDescChild. simpl.
(** getPd **)
eapply bindRev.
eapply WP.weaken. 
eapply Invariants.getPd.
cbn.
intros s H.
(** descChild is a child *)
assert(Hchildren : In phyDescChild (getChildren (currentPartition s) s)).
{ 
 apply inGetChildren with level currentPD ptDescChildpd ptDescChild currentShadow descChild;
  intuition;subst;trivial.
      apply negb_false_iff in Hlegit.
  subst;trivial.
   }
  

split. 
assert(Hnew := conj H Hchildren).  
pattern s in Hnew.
eexact Hnew.
split.
unfold consistency in *.
unfold partitionDescriptorEntry in *.
intuition.
simpl.
unfold consistency in *.
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
apply childrenPartitionInPartitionList with (currentPartition s); intuition.
intros pdChildphy.
simpl.
(** getTableAddr : to check if the virtual address is available to map a new page  **)
eapply WP.bindRev.
eapply WP.weaken. 
apply getTableAddr.
simpl.
intros s H.  
split. 
pattern s in H. 
eexact H. subst.
split. 
intuition.
assert(Hchildpart : In phyDescChild (getPartitions multiplexer s)). 
{ unfold consistency in *. 
  apply childrenPartitionInPartitionList with currentPart; intuition.
  unfold consistency in *. 
  unfold  currentPartitionInPartitionsList in *.
  assert( currentPart = currentPartition s) by intuition.
  subst.
  intuition.
  subst;trivial. }
split. 
instantiate (1:= phyDescChild );trivial.
instantiate (1:= PDidx).
split. intuition.
assert(Hcons : consistency s) by intuition.
assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
assert(Hcp : currentPart = currentPartition s) by intuition.
assert (H0 : nextEntryIsPP phyDescChild PDidx pdChildphy s) by intuition.
exists pdChildphy.
split. intuition.
unfold consistency in *.
destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
unfold partitionDescriptorEntry in Hpd.
assert (PDidx = PDidx \/ PDidx = sh1idx \/ PDidx = sh2idx \/  PDidx  = sh3idx
\/  PDidx  = PPRidx \/  PDidx = PRidx) as Htmp 
by auto.
    generalize (Hpd  phyDescChild  Hchildpart); clear Hpd; intros Hpd.
generalize (Hpd PDidx Htmp); clear Hpd; intros Hpd.
destruct Hpd as (Hidxpd & _& Hentry). 
destruct Hentry as (page1 & Hpd & Hnotnull).
subst.
split.
unfold nextEntryIsPP in *; destruct (StateLib.Index.succ PDidx); [|now contradict H0];
destruct (lookup phyDescChild i (memory s) beqPage beqIndex) ; [|now contradict H0];
destruct v ; try now contradict H0.
subst; assumption.
subst. left. split;intuition.
intro ptVaChildpd. simpl.
(** simplify the new precondition **)     
eapply WP.weaken.
intros.
2: {
intros.
destruct H as (H0 & H1).
assert ( (getTableAddrRoot' ptVaChildpd PDidx phyDescChild vaChild s /\ ptVaChildpd = defaultPage) \/
(forall idx : index,
StateLib.getIndexOfAddr vaChild fstLevel = idx ->
isPE ptVaChildpd idx s /\ getTableAddrRoot ptVaChildpd PDidx phyDescChild vaChild s  )).
{ destruct H1 as [H1 |(Hi & Hi1 & H1)].
  + left. trivial. 
  + right. intros idx Hidx.
    generalize (H1 idx Hidx);clear H1;intros H1.
    destruct H1 as [(Hpe &Htrue) |[ (Hpe& Hfalse) | (Hpe&Hfalse) ]].
    - (*  split; assumption.
    - *) contradict Htrue.
      apply idxPDidxSh1notEq.
    - contradict Hfalse.
      apply idxPDidxSh2notEq.
    - split;trivial. }
assert (HP := conj H0 H).
pattern s in HP.
exact HP. }

(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.comparePageToNull.
intro ptVaChildpdIsnull. simpl.
case_eq ptVaChildpdIsnull.
{ intros. eapply WP.weaken.
  eapply WP.ret . simpl.
  intros. intuition. }
intros HptVaChildpdIsnull. subst.
(** StateLib.getIndexOfAddr **)                
eapply WP.bindRev.
eapply WP.weaken.
eapply Invariants.getIndexOfAddr.
{ simpl. intros.
  destruct H as ((Ha1 & Ha3) & Ha4).
  assert (Hnewget : isPE ptVaChildpd 
  (StateLib.getIndexOfAddr vaChild fstLevel) s /\
       getTableAddrRoot ptVaChildpd PDidx phyDescChild vaChild s /\ 
       (Nat.eqb defaultPage ptVaChildpd) = false).
  { destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
    + subst.
      apply beq_nat_false in Ha4.
      now contradict Ha4.
    + destruct Ha3 with (StateLib.getIndexOfAddr vaChild fstLevel);trivial.
      intuition. }
   subst.
  assert (HP := conj Ha1 Hnewget).
  pattern s in HP.
  eexact HP. }
intro idxvaChild.
simpl. 
(** readPresent **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readPresent. simpl.
  intros.
  split.
  pattern s in H.
  eexact H. 
  intuition. subst;trivial. }
intros presentvaChild. simpl.
case_eq (isnotderiv && accessiblesrc && presentmap && negb presentvaChild);intros Hlegit1;subst;[|intros;eapply weaken;[ eapply WP.ret;trivial|
  intros;simpl;intuition]].
(** readPhyEntry **)
eapply WP.bindRev.
{ eapply WP.weaken.
  eapply Invariants.readPhyEntry. simpl.
  intros.
  split.
  pattern s in H.
  eapply H. 
  subst.
  intuition;subst;trivial. }
intros phyVaChild. simpl.
(** getSndShadow **)
eapply bindRev.
eapply weaken.
eapply Invariants.getSndShadow.
simpl;intros.
split. 

pattern s in H. 
exact H.
split. trivial.
unfold consistency in *.
unfold partitionDescriptorEntry in *.
intuition.
simpl.
unfold consistency in *.
unfold  currentPartitionInPartitionsList in *.
assert( currentPart = currentPartition s) by intuition.
subst.
apply childrenPartitionInPartitionList with (currentPartition s); intuition.
intros sh2Childphy.
simpl.
(** getTableAddr : to access to the second shadow page table  **)
eapply WP.bindRev.
eapply WP.weaken. 
apply getTableAddr.
simpl.
intros s H.  
split. 
pattern s in H. 
eexact H. subst.
split. 
intuition.
assert(Hchildpart : In phyDescChild (getPartitions multiplexer s)). 
{ unfold consistency in *. 
  apply childrenPartitionInPartitionList with currentPart; intuition.
  unfold consistency in *. 
  unfold  currentPartitionInPartitionsList in *.
  assert( currentPart = currentPartition s) by intuition.
  subst.
  intuition.
  subst;trivial. }
split. 
instantiate (1:= phyDescChild );trivial.
instantiate (1:= sh2idx).
split. intuition.
assert(Hcons : consistency s) by intuition.
assert(Hlevel : Some level = StateLib.getNbLevel) by intuition. 
assert(Hcp : currentPart = currentPartition s) by intuition.
assert (H0 : nextEntryIsPP phyDescChild sh2idx sh2Childphy s) by intuition.
exists sh2Childphy.
split. intuition.
unfold consistency in *.
destruct Hcons as (Hpd & _ & _ &_  & Hpr & _). 
unfold partitionDescriptorEntry in Hpd.
assert (sh2idx = PDidx \/ sh2idx = sh1idx \/ sh2idx = sh2idx \/  sh2idx  = sh3idx
\/  sh2idx  = PPRidx \/  sh2idx = PRidx) as Htmp 
by auto.
generalize (Hpd  phyDescChild  Hchildpart); clear Hpd; intros Hpd.
generalize (Hpd sh2idx Htmp); clear Hpd; intros Hpd.
destruct Hpd as (Hidxpd & _& Hentry). 
destruct Hentry as (page1 & Hpd & Hnotnull).
subst.
split.
unfold nextEntryIsPP in *;
destruct (StateLib.Index.succ sh2idx); [|now contradict H0];
destruct (lookup phyDescChild i (memory s) beqPage beqIndex); [|now contradict H0];
destruct v ; try now contradict H0.
subst; assumption.
subst. left. split;intuition.
intro ptVaChildsh2. simpl.
(** simplify the new precondition **)     
eapply WP.weaken.
intros.
2: {
intros.
destruct H as (H0 & H1).
assert ( (getTableAddrRoot' ptVaChildsh2 sh2idx phyDescChild vaChild s /\ ptVaChildsh2 = defaultPage) \/
(forall idx : index,
StateLib.getIndexOfAddr vaChild fstLevel = idx ->
isVA ptVaChildsh2 idx s /\ getTableAddrRoot ptVaChildsh2 sh2idx phyDescChild vaChild s  )).
{ destruct H1 as [H1 |(Hi & Hi1 & H1)].
  + left. trivial. 
  + right. intros idx Hidx.
    generalize (H1 idx Hidx);clear H1;intros H1.
    destruct H1 as [(Hpe &Htrue) |[ (Hpe& Hfalse) | (Hpe&Hfalse) ]].
    - (*  split; assumption.
    - *) contradict Htrue.
      apply idxSh2idxSh1notEq.
    - split;trivial.
    - contradict Hfalse.
      symmetrynot.
      apply idxPDidxSh2notEq. }
assert (HP := conj H0 H).
pattern s in HP.
exact HP. }
(** comparePageToNull **) 
eapply WP.bindRev.
eapply Invariants.comparePageToNull.
intro ptVaChildpdIsnull. simpl.
case_eq ptVaChildpdIsnull.
{ intros. eapply WP.weaken.
  eapply WP.ret . simpl.
  intros. intuition. }
intros HptVaChildpdIsnull. subst.
(** write virtual **)
eapply WP.bindRev.
eapply WP.weaken.
eapply writeVirtualInv.
intros.
exact Hlegit1.
exact Hlegit.
intros.
destruct H as ((Ha1 & Ha3) & Ha4).
try repeat rewrite and_assoc in Ha1.
unfold propagatedPropertiesAddVaddr.
split.
exact Ha1.
{ destruct Ha3 as [(Ha3 & Hfalse) | Ha3].
  subst.
  apply beq_nat_false in Ha4.
  now contradict Ha4.
  destruct Ha3 with (StateLib.getIndexOfAddr vaChild fstLevel);trivial.
  intuition. } 
intros [].
(** writeVirEntry **)
eapply bindRev.
eapply weaken.
eapply writeVirEntryAddVaddr;trivial.
intros.
exact Hlegit1.
exact Hlegit.
intros.
simpl.
exact H.
intros [].
(** writeVirEntry **)
eapply bindRev.
eapply weaken.
apply writePhyEntryMapMMUPage.
instantiate (1:= presentDescPhy);trivial.
instantiate (1:= presentvaChild);trivial.
  try repeat rewrite andb_true_iff in *. 
  intuition.
  eapply Hlegit1.
  intros;simpl.
  eapply H.
  intros. eapply weaken.
  eapply WP.ret;trivial.
  intros;trivial.
Qed.