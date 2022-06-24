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
Proof.StateLib Proof.DependentTypeLemmas Proof.InternalLemmas.

Require Import Invariants checkChildOfCurrPart insertNewEntry.

Require Import Bool List EqNat Lia Compare_dec Coq.Logic.ProofIrrelevance.

Require Import Model.Monad.

Module WP := WeakestPreconditions.

(** * Summary
    This file contains the invariant of [addMemoryBlock].
    We prove that this PIP service preserves the isolation properties as well as
		the consistency properties *)

Lemma addMemoryBlock  (idPDchild idBlockToShare: paddr) (r w e : bool) :
{{fun s => consistency s /\ partitionsIsolation s  /\ kernelDataIsolation s /\ verticalSharing s }}
Services.addMemoryBlock idPDchild idBlockToShare r w e
{{fun _ s  => consistency s /\ partitionsIsolation s  /\ kernelDataIsolation s /\ verticalSharing s }}.
Proof.
unfold addMemoryBlock.
eapply WP.bindRev.
{ (** getCurPartition **)
	eapply WP.weaken. apply Invariants.getCurPartition.
	cbn. intros. split. exact H. intuition.
}
intro currentPart.
eapply WP.bindRev.
{ (** findBlockInKSWithAddr **)
	eapply weaken. eapply findBlockInKSWithAddr.findBlockInKSWithAddr.
	intros. simpl. split. apply H. intuition.
}
intro blockToShareInCurrPartAddr.
eapply WP.bindRev.
{ (** compareAddrToNull **)
	eapply weaken. apply Invariants.compareAddrToNull.
	intros. simpl. apply H.
}
intro addrIsNull.
case_eq addrIsNull.
- (* case_eq addrIsNull = true *)
	intros.
	{ (** ret **)
		eapply WP.weaken. apply WP.ret.
		simpl. intros. intuition.
	}
- (* case_eq addrIsNull = false *)
	intros.
	eapply bindRev.
	{ (** checkRights **)
		eapply weaken. apply Invariants.checkRights.
		intros. simpl. split.
		assert(HBTSNotNull : blockToShareInCurrPartAddr <> nullAddr).
		{ rewrite <- beqAddrFalse in *. intuition. }
		pose (Hconj := conj H0 HBTSNotNull).
		apply Hconj. rewrite <- beqAddrFalse in *. intuition.
		destruct H8. exists x. apply H5.
	}
	intro rcheck.
	case_eq (negb rcheck).
	+ (* case_eq negb rcheck = true *)
		intros.
		{ (** ret **)
			eapply WP.weaken. apply WP.ret.
			simpl. intros. intuition.
		}
	+ (* case_eq negb rcheck = false *)
		intros.
		eapply WP.bindRev.
		{ (** checkChildOfCurrPart **)
			eapply weaken. apply checkChildOfCurrPart.checkChildOfCurrPart.
			intros. simpl. split. apply H1. intuition.
		}
		intro isChildCurrPart.
		case_eq (negb isChildCurrPart).
		* (* case_eq negb isChildCurrPart = true *)
			intros.
			{ (** ret **)
				eapply WP.weaken. apply WP.ret.
				simpl. intros. intuition.
			}
		* (* case_eq negb isChildCurrPart = true *)
			intros.
			eapply WP.bindRev.
			{ (** readBlockStartFromBlockEntryAddr **)
				eapply weaken. apply Invariants.readBlockStartFromBlockEntryAddr.
				intros. simpl. split. apply H2.
				repeat rewrite <- beqAddrFalse in *. (* get rid of NULL conditions since we
				are in this branch *)
				rewrite negb_false_iff in *. (* get rif of trivial cases *)
				intuition.
				(* child has been checked, we know that idPDchild is valid and isBE *)
				destruct H10. (* exists sh1entryaddr ... checkChild ... *)
				destruct H4. (* isChildCurrPart = checkChild ... *)
				destruct H10. (* exists... lookup idPDchild... *)
				unfold isBE. intuition.
				assert(Hlookup : lookup idPDchild (memory s) beqAddr = Some (BE x0)) by intuition.
				rewrite Hlookup; trivial.
			}
			intro globalIdPDChild.
			eapply WP.bindRev.
			{ (** readPDNbFreeSlots **)
				eapply weaken. apply Invariants.readPDNbFreeSlots.
				intros. simpl.
				assert(HPDTGlobalIdPDChild : isPDT globalIdPDChild s).
				{
					(* globalIdPDChild is a PDT because it is the start address of idPDchild
							who is a child *)
					repeat rewrite <- beqAddrFalse in *. rewrite negb_false_iff in *. intuition.
					unfold bentryStartAddr in *.
					destruct H11 as [sh1entryaddr (Hcheckchild & ( idpdchildentry & (HlookupidPDchild & (sh1entry & (Hsh1entryaddr & Hlookupshe1entryaddr)))))].
					assert(HPDTIfPDFlag : PDTIfPDFlag s) by (unfold consistency in * ; intuition).
					unfold PDTIfPDFlag in *.
					unfold entryPDT in *.
					specialize (HPDTIfPDFlag idPDchild sh1entryaddr).
					rewrite HlookupidPDchild in *. subst.
					intuition.
					destruct H.
					unfold isPDT. destruct H.
					destruct (lookup (startAddr (blockrange idpdchildentry)) (memory s) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
					destruct v eqn:Hv ; try (exfalso ; congruence).
					trivial.
				}
				assert(HglobalIdPDChildNotNull : globalIdPDChild <> nullAddr).
				{
					assert(HnullAddrExists : nullAddrExists s)
						by (unfold consistency in * ; intuition).
					unfold nullAddrExists in *.
					unfold isPADDR in *.
					unfold isPDT in *.
					intro HglobalNull.
					rewrite HglobalNull in *.
					destruct (lookup nullAddr (memory s) beqAddr) eqn:Hf ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				}
				pose(Hconj1 := conj H2 HglobalIdPDChildNotNull).
				pose(Hconj2 := conj Hconj1 HPDTGlobalIdPDChild).
				split. apply Hconj2.
				assumption.
			}
			intro nbfreeslots.
			eapply bindRev.
			{ (** zero **)
				eapply weaken. apply Invariants.Index.zero.
				intros. simpl. apply H2.
			}
			intro zero.
			eapply bindRev.
			{ (** MALInternal.Index.leb nbfreeslots zero **)
				eapply weaken. apply Invariants.Index.leb.
				intros. simpl. apply H2.
			}
			intro isFull.
			case_eq (isFull).
			-- (* case_eq isFull = false *)
					intros.
					{ (** ret **)
						eapply weaken. apply WP.ret.
						intros. simpl. apply H3.
					}
			-- (*case_eq isFull = true *)
					intros.
					(* TODO :  remove next when link between nbfreeslots and actual list is done *)
					eapply bindRev.
					{ (** readPDFirstFreeSlotPointer *)
						eapply weaken. apply readPDFirstFreeSlotPointer.
						intros. simpl. split. apply H3.
						intuition.
					}
					intro childfirststructurepointer.
					eapply bindRev.
					{ (** compareAddrToNull **)
						eapply weaken. apply Invariants.compareAddrToNull.
						intros. simpl. apply H3.
					}
					intro slotIsNull.
					case_eq slotIsNull.
					------ (* case_eq slotIsNull = true *)
									intros.
									{ (** ret **)
										eapply WP.weaken. apply WP.ret.
										simpl. intros. intuition.
									}
					------ (* case_eq slotIsNull = false *)
									intros.
									eapply bindRev.
									{ (** readBlockAccessibleFromBlockEntryAddr *)
										eapply weaken. apply readBlockAccessibleFromBlockEntryAddr.
										intros. simpl. split. apply H4.
										repeat rewrite beqAddrFalse in *. rewrite negb_false_iff in *. subst.
										assert(HBE : exists entry : BlockEntry, lookup blockToShareInCurrPartAddr (memory s) beqAddr =
									 								Some (BE entry)) by intuition.
										destruct HBE as [blocktoshareentry HLookupblocktoshare].
										intuition ; (unfold isBE ; rewrite HLookupblocktoshare ; trivial).
									}
									intro addrIsAccessible.
									case_eq (negb addrIsAccessible).
									++ (*case_eq negb addrIsAccessible = true *)
											intros. simpl.
											{ (** ret **)
												eapply weaken. apply WP.ret.
												intros. simpl. intuition.
											}
									++ (*case_eq negb addrIsAccessible = false *)
											intros.
											eapply bindRev.
											{ (** readBlockPresentFromBlockEntryAddr **)
												eapply weaken. apply readBlockPresentFromBlockEntryAddr.
												intros. simpl. split. apply H5.
												repeat rewrite <- beqAddrFalse in *.
												unfold isBE. intuition.
												assert(HBE : exists entry : BlockEntry, lookup blockToShareInCurrPartAddr (memory s) beqAddr =
									 								Some (BE entry)) by intuition.
												destruct HBE as [blocktoshareentry HLookupblocktoshare].
												rewrite HLookupblocktoshare. trivial.
											}
											intro addrIsPresent.
											case_eq (negb addrIsPresent).
											** (*case_eq negb addrIsPresent = true *)
												intros. simpl.
												{ (** ret **)
													eapply weaken. apply WP.ret.
													intros. simpl. intuition.
												}
											** (*case_eq negb addrIsPresent = false *)
													intros.
													eapply bindRev.
												{	(** readPDVidt **)
													eapply weaken. apply readPDVidt.
													intros. simpl. split. apply H6.
													intuition.
												}
												intro vidtBlockGlobalId.
												destruct (beqAddr vidtBlockGlobalId blockToShareInCurrPartAddr) eqn:beqBToShareVIDT.
												--- (* vidtBlockGlobalId = blockToShareInCurrPartAddr *)
														intros. simpl.
														{ (** ret **)
															eapply weaken. apply WP.ret.
															intros. simpl. intuition.
														}
												--- (* vidtBlockGlobalId <> blockToShareInCurrPartAddr *)
														eapply bindRev.
														{	(** readBlockStartFromBlockEntryAddr **)
															eapply weaken. apply readBlockStartFromBlockEntryAddr.
															intros. simpl. split. apply H6.
															repeat rewrite <- beqAddrFalse in *.
															unfold isBE. intuition.
															assert(HblockToShare : exists entry : BlockEntry,
																	lookup blockToShareInCurrPartAddr (memory s) beqAddr = Some (BE entry) /\
																	blockToShareInCurrPartAddr = idBlockToShare)
																by intuition.
															destruct HblockToShare as [blocktoshareentry (Hlookupblocktoshare & HblocktoshqreEq)].
															subst. rewrite Hlookupblocktoshare. trivial.
														}
														intro blockstart.
														eapply bindRev.
														{	(** readBlockEndFromBlockEntryAddr **)
															eapply weaken. apply readBlockEndFromBlockEntryAddr.
															intros. simpl. split. apply H6.
															repeat rewrite <- beqAddrFalse in *.
															unfold isBE. intuition.
															assert(HblockToShare : exists entry : BlockEntry,
																	lookup blockToShareInCurrPartAddr (memory s) beqAddr = Some (BE entry) /\
																	blockToShareInCurrPartAddr = idBlockToShare)
																by intuition.
															destruct HblockToShare as [blocktoshareentry (Hlookupblocktoshare & HblocktoshqreEq)].
															subst. rewrite Hlookupblocktoshare. trivial.
														}
														intro blockend.

(* Start of structure modifications *)
eapply bindRev.
{ eapply weaken. apply insertNewEntry.insertNewEntry.
	intros. simpl.
	split. intuition. split. intuition. split. intuition.
	assert(HPDTGlobalIdPDChild : isPDT globalIdPDChild s) by intuition.
	apply isPDTLookupEq in HPDTGlobalIdPDChild.
	assert(HnfbfreeslotsNotZero : nbfreeslots > 0).
	{
		unfold StateLib.Index.leb in *.
		assert(Hnbfreeslots : PeanoNat.Nat.leb nbfreeslots zero = false) by intuition.
		apply PeanoNat.Nat.leb_gt. assert (Hzero : zero = CIndex 0) by intuition.
		subst. simpl in Hnbfreeslots. intuition.
	}
	split. intuition.
	split. intuition.
	(* TODO : to remove once NbFreeSlotsISNbFreeSlotsInList is proven *)
	split.
	{ unfold pdentryFirstFreeSlot.
		destruct HPDTGlobalIdPDChild as [globalpdentry Hlookupglobal].
		unfold pdentryFirstFreeSlot in *.
		rewrite Hlookupglobal in *.
		exists childfirststructurepointer.
		rewrite <- beqAddrFalse in *.
		intuition.
		rewrite <- beqAddrFalse in *. intuition.
	}
	apply H6.
}
intro blockToShareChildEntryAddr. simpl.
eapply bindRev.
{ (** MAL.writeSh1PDChildFromBlockEntryAddr **)
	eapply weaken. apply writeSh1PDChildFromBlockEntryAddr.
	intros. simpl.
	assert(HBEbts : isBE blockToShareInCurrPartAddr s).
	{ destruct H6 as [s0 Hprops].
		destruct Hprops as [Hprops0 (Hcons & Hprops)].
		destruct Hprops as [pdentry (pdentry0 & (pdentry1
												& (bentry & (bentry0 & (bentry1 & (bentry2 & (bentry3 & (bentry4 & (bentry5 & (bentry6
												& (sceaddr & (scentry
												& (newBlockEntryAddr & (newFirstFreeSlotAddr
												& (predCurrentNbFreeSlots & Hprops)))))))))))))))].
		assert(beqbtsnew : newBlockEntryAddr <> blockToShareInCurrPartAddr).
		{
			(* at s0, newBlockEntryAddr is a free slot, which is not the case of
					blockToShareInCurrPartAddr *)
			assert(HFirstFreeSlotPointerIsBEAndFreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; intuition).
			unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
			assert(HPDTchilds0 : isPDT globalIdPDChild s0) by intuition.
			apply isPDTLookupEq in HPDTchilds0.
			destruct HPDTchilds0 as [childpdentry Hlookupchilds0].
			specialize(HFirstFreeSlotPointerIsBEAndFreeSlot globalIdPDChild childpdentry Hlookupchilds0).
			assert(HfirstfreeNotNull : firstfreeslot childpdentry <> nullAddr).
			{
				assert(Hfirstfreechilds0 : pdentryFirstFreeSlot globalIdPDChild childfirststructurepointer s0 /\
               beqAddr nullAddr childfirststructurepointer = false) by intuition.
				unfold pdentryFirstFreeSlot in *. rewrite Hlookupchilds0 in *.
				rewrite <- beqAddrFalse in *.
				destruct Hfirstfreechilds0 as [HfirstfreeEq HfirstFreeNotNull].
				subst childfirststructurepointer. congruence.
			}
			specialize (HFirstFreeSlotPointerIsBEAndFreeSlot HfirstfreeNotNull).
			assert(HnewBEq : firstfreeslot childpdentry = newBlockEntryAddr).
			{ unfold pdentryFirstFreeSlot in *. rewrite Hlookupchilds0 in *. intuition. }
				rewrite HnewBEq in *.
				intro HBTSnewBEq. (* newB is a free slot, so its present flag is false
															blockToShareInCurrPartAddr is not a free slot,
															so the equality is a constradiction*)
				subst blockToShareInCurrPartAddr.
				assert(HwellFormedsh1newBs0 : wellFormedFstShadowIfBlockEntry s0)
					by (unfold consistency in * ; intuition).
				unfold wellFormedFstShadowIfBlockEntry in *.
				assert(HwellFormedSCnewBs0 : wellFormedShadowCutIfBlockEntry s0)
					by (unfold consistency in * ; intuition).
				unfold wellFormedShadowCutIfBlockEntry in *.
				assert(HBEs0 : isBE newBlockEntryAddr s0) by intuition.
				specialize (HwellFormedsh1newBs0 newBlockEntryAddr HBEs0).
				specialize (HwellFormedSCnewBs0 newBlockEntryAddr HBEs0).
				unfold isBE in *. unfold isSHE in *. unfold isSCE in *.
				unfold isFreeSlot in *.
				unfold bentryPFlag in *.
				destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hbe ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
				destruct (lookup (CPaddr (newBlockEntryAddr + sh1offset)) (memory s0) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
				destruct HwellFormedSCnewBs0 as [scentryaddr (HSCEs0 & HscentryEq)].
				subst scentryaddr.
				destruct (lookup (CPaddr (newBlockEntryAddr + scoffset))  (memory s0) beqAddr) eqn:Hsce ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
				intuition. subst addrIsPresent.
				assert(Hfalse : negb (present b) = true).
				{ assert(Htrue : present b = false) by intuition.
					rewrite Htrue. trivial.
				}
				congruence.
			}
			assert(HBEs0 : isBE blockToShareInCurrPartAddr s0).
			{
				assert(Hlookups0 : exists entry : BlockEntry,
                    lookup blockToShareInCurrPartAddr (memory s0) beqAddr = Some (BE entry))
					by intuition.
				destruct Hlookups0 as [btsentry Hlookups0].
				unfold isBE. rewrite Hlookups0. trivial.
			}
			assert(HidpdchildbtsNotEq : globalIdPDChild <> blockToShareInCurrPartAddr).
			{
				intro Heqfalse. rewrite Heqfalse in *.
				unfold isPDT in *.
				unfold isBE in *.
				destruct (lookup blockToShareInCurrPartAddr (memory s0) beqAddr) eqn:Hlookup ; try(intuition ; exfalso ; congruence).
				destruct v ; try(intuition ; exfalso ; congruence).
			}

			destruct Hprops as [Hs Hprops].
			assert(HlookupBTSs : lookup blockToShareInCurrPartAddr (memory s) beqAddr =
													lookup blockToShareInCurrPartAddr (memory s0) beqAddr).
			{
				rewrite Hs.
				cbn. rewrite Proof.InternalLemmas.beqAddrTrue.
				destruct (beqAddr sceaddr blockToShareInCurrPartAddr) eqn:beqscebts ; try(exfalso ; congruence).
				- (* sceaddr = blockToShareInCurrPartAddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebts.
					rewrite <- beqscebts in *.
					apply eq_sym.
					assert(HSCEs0 : isSCE sceaddr s0) by intuition.
					unfold isSCE in *.
					unfold isBE in *.
					destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				- (* sceaddr <> blockToShareInCurrPartAddr *)
					cbn.
					assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false)
						by (rewrite <- beqAddrFalse in *  ; intuition).
					rewrite HnewBsceNotEq. (*newBlock <> sce *)
					cbn.
					destruct (beqAddr newBlockEntryAddr blockToShareInCurrPartAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:Hfg ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfg. congruence.
					cbn.
					destruct (beqAddr globalIdPDChild blockToShareInCurrPartAddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
			}
			apply isBELookupEq in HBEs0. destruct HBEs0 as [btsentry0 Hlookups0].
			unfold isBE. rewrite HlookupBTSs. rewrite Hlookups0. trivial.
	}
	destruct H6 as [s0 Hprops].
	assert(HwellFormedFstShadowIfBlockEntry : wellFormedFstShadowIfBlockEntry s)
			by (unfold consistency in * ; intuition).
	specialize (HwellFormedFstShadowIfBlockEntry blockToShareInCurrPartAddr HBEbts).
	apply isSHELookupEq in HwellFormedFstShadowIfBlockEntry as [sh1entrybts HSHEbtss].
	exists sh1entrybts. split. intuition.
	assert(Hcons_conj : wellFormedFstShadowIfBlockEntry s
							/\ KernelStructureStartFromBlockEntryAddrIsKS s)
		by (unfold consistency in * ; intuition).
	destruct Hprops as [Hprops0 (Hcons & Hprops)].
		instantiate (1:= fun _ s =>
exists s0,
	(* s0 *)
	(partitionsIsolation s0 /\
                           kernelDataIsolation s0 /\
                           verticalSharing s0 /\ consistency s0 /\
                          consistency s0 /\
                          isPDT currentPart s0 /\
                          currentPart = currentPartition s0 /\
                         (blockToShareInCurrPartAddr = nullAddr \/
                          (exists entry : BlockEntry,
                             lookup blockToShareInCurrPartAddr
                               (memory s0) beqAddr =
                             Some (BE entry) /\
                             blockToShareInCurrPartAddr = idBlockToShare)) /\
                        beqAddr nullAddr blockToShareInCurrPartAddr =
                        false /\
                       (exists entry : BlockEntry,
                          lookup blockToShareInCurrPartAddr
                            (memory s0) beqAddr =
                          Some (BE entry)) /\
                      (isChildCurrPart = true ->
                       exists sh1entryaddr : paddr,
                         isChildCurrPart =
                         checkChild idPDchild s0 sh1entryaddr /\
                         (exists entry : BlockEntry,
                            lookup idPDchild (memory s0) beqAddr =
                            Some (BE entry) /\
                            (exists sh1entry : Sh1Entry,
                               sh1entryAddr idPDchild sh1entryaddr s0 /\
                               lookup sh1entryaddr (memory s0) beqAddr =
                               Some (SHE sh1entry)))) /\
                     bentryStartAddr idPDchild globalIdPDChild s0 /\
                    isPDT globalIdPDChild s0 /\
                   pdentryNbFreeSlots globalIdPDChild nbfreeslots s0 /\
                  zero = CIndex 0 /\
                 false = StateLib.Index.leb nbfreeslots zero /\
                pdentryFirstFreeSlot globalIdPDChild
                  childfirststructurepointer s0 /\
               beqAddr nullAddr childfirststructurepointer = false /\
              bentryAFlag blockToShareInCurrPartAddr addrIsAccessible s0 /\
             bentryPFlag blockToShareInCurrPartAddr addrIsPresent s0 /\
            pdentryVidt globalIdPDChild vidtBlockGlobalId s0 /\
           bentryStartAddr blockToShareInCurrPartAddr blockstart s0 /\
          bentryEndAddr blockToShareInCurrPartAddr blockend s0)

/\ (exists pdentry pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr : paddr, exists scentry : SCEntry,
		exists newBlockEntryAddr newFirstFreeSlotAddr : paddr,
		exists predCurrentNbFreeSlots : index,
		exists sh1eaddr : paddr, exists sh1entry sh1entry0 : Sh1Entry,

  s = {|
     currentPartition := currentPartition s0;
     memory := add sh1eaddr
                     (SHE
                        {|	PDchild := globalIdPDChild;
                        		PDflag := PDflag sh1entry;
                        		inChildLocation := inChildLocation sh1entry |})
							(add sceaddr
									(SCE {| origin := blockstart; next := next scentry |})
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) blockend)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock blockstart (endAddr (blockrange bentry)))))
								(add globalIdPDChild
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add globalIdPDChild
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := ADT.nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup sh1eaddr (memory s0) beqAddr = Some (SHE sh1entry)
/\ lookup sh1eaddr (memory s) beqAddr = Some (SHE sh1entry0) /\
sh1entry0 = {| PDchild := globalIdPDChild;
             	PDflag := PDflag sh1entry;
             	inChildLocation := inChildLocation sh1entry |}
/\ newBlockEntryAddr = blockToShareChildEntryAddr
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6)
/\
bentry6 = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
/\
bentry5 = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) blockend))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock blockstart (endAddr (blockrange bentry))))
/\ sceaddr = (CPaddr (newBlockEntryAddr + scoffset))
/\ lookup globalIdPDChild (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup globalIdPDChild (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := ADT.nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
	(* propagate new properties (copied from last step) *)
	/\ pdentryNbFreeSlots globalIdPDChild predCurrentNbFreeSlots s
	/\ StateLib.Index.pred nbfreeslots = Some predCurrentNbFreeSlots
	/\ blockindex bentry6 = blockindex bentry5
	/\ blockindex bentry5 = blockindex bentry4
	/\ blockindex bentry4 = blockindex bentry3
	/\ blockindex bentry3 = blockindex bentry2
	/\ blockindex bentry2 = blockindex bentry1
	/\ blockindex bentry1 = blockindex bentry0
	/\ blockindex bentry0 = blockindex bentry
	/\ blockindex bentry6 = blockindex bentry
	/\ isPDT globalIdPDChild s0
	/\ isPDT globalIdPDChild s
	/\ isBE newBlockEntryAddr s0
	/\ isBE newBlockEntryAddr s
	/\ isBE blockToShareInCurrPartAddr s0
	/\ isSCE sceaddr s0
	/\ isSCE sceaddr s
	/\ isSHE sh1eaddr s0
	/\ isSHE sh1eaddr s
	/\ sceaddr = CPaddr (newBlockEntryAddr + scoffset)
	/\ sh1eaddr = CPaddr (blockToShareInCurrPartAddr + sh1offset)
	/\ firstfreeslot pdentry1 = newFirstFreeSlotAddr
	/\ newBlockEntryAddr = (firstfreeslot pdentry)
	/\ newBlockEntryAddr <> blockToShareInCurrPartAddr
	/\ newFirstFreeSlotAddr <> globalIdPDChild
	/\ globalIdPDChild <> newBlockEntryAddr
	/\ globalIdPDChild <> blockToShareInCurrPartAddr
	/\ newFirstFreeSlotAddr <> newBlockEntryAddr
	/\ newFirstFreeSlotAddr <> sh1eaddr
	/\ sh1eaddr <> sceaddr
	/\ sh1eaddr <> newBlockEntryAddr
	/\ sh1eaddr <> globalIdPDChild
	/\ sh1eaddr <> blockToShareInCurrPartAddr
	/\ sceaddr <> newBlockEntryAddr
	/\ sceaddr <> globalIdPDChild
	/\ sceaddr <> newFirstFreeSlotAddr
	/\ sceaddr <> blockToShareInCurrPartAddr
	(* pdinsertion's new free slots list and relation with list at s0 *)
	/\ (exists (optionfreeslotslist : list optionPaddr) (s2 : state)
					(n0 n1 n2 : nat) (nbleft : index),
			nbleft = CIndex (nbfreeslots - 1) /\
			nbleft < maxIdx /\
			s =
			{|
				currentPartition := currentPartition s0;
				memory :=
					add sh1eaddr
                     (SHE
                        {|	PDchild := globalIdPDChild;
                        		PDflag := PDflag sh1entry;
                        		inChildLocation := inChildLocation sh1entry |})
						(memory s2) beqAddr
			|} /\
			optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
			getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
			optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
			n0 <= n1 /\
			nbleft < n0 /\
			n1 <= n2 /\
			nbleft < n2 /\
			n2 <= maxIdx + 1 /\
			(wellFormedFreeSlotsList optionfreeslotslist = False -> False) /\
			NoDup (filterOption optionfreeslotslist) /\
			(In newBlockEntryAddr (filterOption optionfreeslotslist) -> False))
		/\ lookup blockToShareInCurrPartAddr (memory s) beqAddr =
						lookup blockToShareInCurrPartAddr (memory s0) beqAddr

(* intermediate steps *)
/\ (exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11,
s1 = {|
     currentPartition := currentPartition s0;
     memory := add globalIdPDChild
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := ADT.nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |}
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add globalIdPDChild
		           (PDT
		              {|
		                structure := structure pdentry0;
		                firstfreeslot := firstfreeslot pdentry0;
		                nbfreeslots := predCurrentNbFreeSlots;
		                nbprepare := nbprepare pdentry0;
		                parent := parent pdentry0;
		                MPU := MPU pdentry0;
		                vidtBlock := vidtBlock pdentry0
		              |}
                 ) (memory s1) beqAddr |}
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry)
	                  (write bentry) (exec bentry)
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock blockstart (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |}
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0)
                     (write bentry0) (exec bentry0)
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) blockend))
                 ) (memory s3) beqAddr |}
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1)
                    (write bentry1) (exec bentry1)
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |}
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2)
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |}
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3)
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |}
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4)
                       (present bentry4) (accessible bentry4)
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |}
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e
                    (present bentry5) (accessible bentry5)
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |}
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr
								(SCE {| origin := blockstart; next := next scentry |}
                 ) (memory s9) beqAddr |}
/\ s11 = {|
     currentPartition := currentPartition s10;
     memory := add sh1eaddr
        (SHE
           {|
             PDchild := globalIdPDChild;
             PDflag := PDflag sh1entry;
             inChildLocation := inChildLocation sh1entry
           |}) (memory s10) beqAddr |}
/\ consistency s10))).
intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			destruct Hprops as [pdentry (pdentry0 & (pdentry1
												& (bentry & (bentry0 & (bentry1 & (bentry2 & (bentry3 & (bentry4 & (bentry5 & (bentry6
												& (sceaddr & (scentry
												& (newBlockEntryAddr & (newFirstFreeSlotAddr
												& (predCurrentNbFreeSlots & (Hs & Hprops))))))))))))))))].
			intuition. subst blockToShareChildEntryAddr.
			exists s0. intuition.
			exists pdentry. exists pdentry0. exists pdentry1.
			exists bentry. exists bentry0. exists bentry1. exists bentry2. exists bentry3.
			exists bentry4. exists bentry5. exists bentry6. exists sceaddr. exists scentry.
			exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
			exists (CPaddr (blockToShareInCurrPartAddr + sh1offset)).
			assert(HSHEbts0 : isSHE (CPaddr (blockToShareInCurrPartAddr + sh1offset)) s0).
			{
				assert(HwellFormedSh1s0 : wellFormedFstShadowIfBlockEntry s0)
				by (unfold consistency in * ; intuition).
				assert(HBEbtss0 : isBE blockToShareInCurrPartAddr s0).
				{
					assert(Hlookups0 : exists entry : BlockEntry,
      													lookup blockToShareInCurrPartAddr (memory s0) beqAddr = Some (BE entry))
						by intuition.
					destruct Hlookups0 as [btsentry Hlookups0].
					unfold isBE. rewrite Hlookups0. trivial.
				}
				specialize(HwellFormedSh1s0 blockToShareInCurrPartAddr HBEbtss0).
				assumption.
			}
			apply isSHELookupEq in HSHEbts0. destruct HSHEbts0 as [sh1entry Hsh1entry].
			exists sh1entry.
			assert(beqsh1pdchild : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) globalIdPDChild = false).
			{
				rewrite <- beqAddrFalse.
				intro Hsh1pdchildEq. rewrite Hsh1pdchildEq in *.
				unfold isPDT in *. unfold isSHE in *.
				destruct(lookup globalIdPDChild (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
			}
			assert(beqsh1newB : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) newBlockEntryAddr = false).
			{
				rewrite <- beqAddrFalse.
				intro Hsh1newBEq. rewrite Hsh1newBEq in *.
				unfold isBE in *. unfold isSHE in *.
				destruct(lookup globalIdPDChild (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
			}
			assert(beqsh1sce : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) sceaddr = false).
			{
				rewrite <- beqAddrFalse.
				intro Hsh1sceEq. rewrite Hsh1sceEq in *.
				unfold isSCE in *. unfold isSHE in *.
				destruct(lookup sceaddr (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
			}
			assert(Hlookupsh1btseq : lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s) beqAddr =
						lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s0) beqAddr).
			{
				rewrite Hs.
				cbn. rewrite beqAddrTrue.
				rewrite beqAddrSym in beqsh1sce.
				rewrite beqsh1sce.
				assert(HnewBsce : beqAddr newBlockEntryAddr sceaddr = false)
					by (rewrite <- beqAddrFalse ; intuition).
				rewrite HnewBsce.
				cbn.
				assert(HnewBsh1bts : beqAddr newBlockEntryAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) = false)
					by (rewrite <- beqAddrFalse in * ; intuition).
				rewrite HnewBsh1bts.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:Hf ; try (exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
				cbn.
				assert(Hpdchildsh1bts : beqAddr globalIdPDChild (CPaddr (blockToShareInCurrPartAddr + sh1offset)) = false)
					by (rewrite <- beqAddrFalse in * ; intuition).
				rewrite Hpdchildsh1bts.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			rewrite Hlookupsh1btseq in *.
			assert(HBEs0 : isBE blockToShareInCurrPartAddr s0).
			{
				assert(Hlookups0 : exists entry : BlockEntry,
		                lookup blockToShareInCurrPartAddr (memory s0) beqAddr = Some (BE entry))
					by intuition.
				destruct Hlookups0 as [btsentry Hlookups0].
				unfold isBE. rewrite Hlookups0. trivial.
			}
			assert(HidpdchildbtsNotEq : globalIdPDChild <> blockToShareInCurrPartAddr).
			{
				intro Heqfalse. rewrite Heqfalse in *.
				unfold isPDT in *.
				unfold isBE in *.
				destruct (lookup blockToShareInCurrPartAddr (memory s0) beqAddr) eqn:Hlookup ; try(intuition ; exfalso ; congruence).
				destruct v ; try(intuition ; exfalso ; congruence).
			}
			assert(Hsh1btsNotEq : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) blockToShareInCurrPartAddr = false).
			{ rewrite <- beqAddrFalse in *.
				intro Hsh1btsEqfalse.
				rewrite Hsh1btsEqfalse in *.
				unfold isSHE in *. unfold isBE in *.
				destruct (lookup blockToShareInCurrPartAddr (memory s0) beqAddr) ; try(intuition ; exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
			}

			assert(beqscebts : beqAddr sceaddr blockToShareInCurrPartAddr = false).
			{
				rewrite <- beqAddrFalse. intro Heqfalse.
				assert(HSCEs0 : isSCE sceaddr s0) by intuition.
				rewrite Heqfalse in *.
				unfold isSCE in *. unfold isBE in *.
				destruct (lookup blockToShareInCurrPartAddr (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
			}
			assert(beqnewBsh1 : beqAddr newBlockEntryAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) = false).
			{
				rewrite <- beqAddrFalse. intro Heqfalse.
				rewrite Heqfalse in *.
				unfold isSHE in *.
				intuition ; destruct (lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence) ;
				destruct v ; try(exfalso ; congruence).
			}
		assert(beqbtsnew : newBlockEntryAddr <> blockToShareInCurrPartAddr).
		{
			(* at s0, newBlockEntryAddr is a free slot, which is not the case of
					blockToShareInCurrPartAddr *)
			assert(HFirstFreeSlotPointerIsBEAndFreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; intuition).
			unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
			assert(HPDTchilds0 : isPDT globalIdPDChild s0) by intuition.
			apply isPDTLookupEq in HPDTchilds0.
			destruct HPDTchilds0 as [childpdentry Hlookupchilds0].
			specialize(HFirstFreeSlotPointerIsBEAndFreeSlot globalIdPDChild childpdentry Hlookupchilds0).
			assert(HfirstfreeNotNull : firstfreeslot childpdentry <> nullAddr).
			{
				assert(Hfirstfreechilds0 : pdentryFirstFreeSlot globalIdPDChild childfirststructurepointer s0 /\
               beqAddr nullAddr childfirststructurepointer = false) by intuition.
				unfold pdentryFirstFreeSlot in *. rewrite Hlookupchilds0 in *.
				rewrite <- beqAddrFalse in *.
				destruct Hfirstfreechilds0 as [HfirstfreeEq HfirstFreeNotNull].
				subst childfirststructurepointer. congruence.
			}
			specialize (HFirstFreeSlotPointerIsBEAndFreeSlot HfirstfreeNotNull).
			assert(Hlookuppdchilds0 : lookup globalIdPDChild (memory s0) beqAddr = Some (PDT pdentry)) by intuition.
			assert(HpdEq: childpdentry = pdentry).
			{ unfold pdentryFirstFreeSlot in *. rewrite Hlookuppdchilds0 in *.
				inversion Hlookupchilds0. intuition.
			}
			rewrite HpdEq in *.
			assert(HnewBEq : firstfreeslot pdentry = newBlockEntryAddr) by intuition.
			rewrite HnewBEq in *.
			intro HBTSnewBEq. (* newB is a free slot, so its present flag is false
														blockToShareInCurrPartAddr is not a free slot,
														so the equality is a constradiction*)
			subst blockToShareInCurrPartAddr.
			assert(HwellFormedsh1newBs0 : wellFormedFstShadowIfBlockEntry s0)
				by (unfold consistency in * ; intuition).
			unfold wellFormedFstShadowIfBlockEntry in *.
			assert(HwellFormedSCnewBs0 : wellFormedShadowCutIfBlockEntry s0)
				by (unfold consistency in * ; intuition).
			unfold wellFormedShadowCutIfBlockEntry in *.
			assert(HBEnewBs0 : isBE newBlockEntryAddr s0) by intuition.
			specialize (HwellFormedsh1newBs0 newBlockEntryAddr HBEnewBs0).
			specialize (HwellFormedSCnewBs0 newBlockEntryAddr HBEnewBs0).
			unfold isBE in *. unfold isSHE in *. unfold isSCE in *.
			unfold isFreeSlot in *.
			unfold bentryPFlag in *.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hbe ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			destruct (lookup (CPaddr (newBlockEntryAddr + sh1offset)) (memory s0) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			destruct HwellFormedSCnewBs0 as [scentryaddr (HSCEs0 & HscentryEq)].
			subst scentryaddr.
			destruct (lookup (CPaddr (newBlockEntryAddr + scoffset))  (memory s0) beqAddr) eqn:Hsce ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
			intuition. subst addrIsPresent.
			assert(Hfalse : negb (present b) = true).
			{
				assert(Htrue : present b = false) by intuition.
				rewrite Htrue. trivial.
			}
			congruence.
		}
			assert(HlookupBTSEq : lookup blockToShareInCurrPartAddr (memory s) beqAddr =
													lookup blockToShareInCurrPartAddr (memory s0) beqAddr).
			{
				rewrite Hs.
				cbn. rewrite beqAddrTrue.
				rewrite beqscebts.
						assert (HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by (rewrite <- beqAddrFalse in * ; intuition).
						rewrite HnewBsceNotEq. (*newBlock <> sce *)
						cbn.
						destruct (beqAddr newBlockEntryAddr blockToShareInCurrPartAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:Hfg ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hfg. congruence.
						cbn.
						destruct (beqAddr globalIdPDChild blockToShareInCurrPartAddr) eqn:Hfff ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
						rewrite beqAddrTrue.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
			}
			assert(newFsceNotEq : newFirstFreeSlotAddr <> (CPaddr (blockToShareInCurrPartAddr + sh1offset))).
			{
				intro HnewFirstsh1Eq.
				assert(HFirstFreeBE : FirstFreeSlotPointerIsBEAndFreeSlot s)
						by (unfold consistency in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				assert(Hlookuppdchild : lookup globalIdPDChild (memory s) beqAddr = Some (PDT pdentry1)) by intuition.
				specialize (HFirstFreeBE globalIdPDChild pdentry1 Hlookuppdchild).
				assert(HnewFEq : firstfreeslot pdentry1 = newFirstFreeSlotAddr).
				{ subst pdentry1. subst pdentry0. simpl. reflexivity. }
				rewrite HnewFEq in *.
				destruct HFirstFreeBE.
				- (* newFirstFreeSlotAddr = nullAddr *)
					intro HnewFNullEq.
					rewrite HnewFirstsh1Eq in *.
					rewrite HnewFNullEq in *.
					assert(HnullAddrExists : nullAddrExists s)
						by (unfold consistency in * ; intuition).
					unfold nullAddrExists in *. unfold isPADDR in *.
					destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				- (* newFirstFreeSlotAddr = nullAddr *)
					rewrite <- HnewFirstsh1Eq in *.
					unfold isBE in *. unfold isSHE in *.
					destruct (lookup newFirstFreeSlotAddr (memory s) beqAddr) ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
			}

			rewrite beqAddrTrue.
			assert(Hsh1entryEq : sh1entrybts = sh1entry).
			{ rewrite Hsh1entry in *. inversion HSHEbtss. trivial. }
			rewrite Hsh1entryEq in *.
			eexists. intuition.
			+ unfold s'. rewrite Hs. simpl. rewrite Hsh1entryEq in *. intuition.
			+ rewrite beqsh1newB.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold pdentryNbFreeSlots in *. unfold s'.
 				cbn.
				rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isPDT. unfold s'. cbn.
				rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isBE. unfold s'.
				cbn.
				rewrite beqsh1newB.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isSCE. unfold s'.
				cbn.
				rewrite beqsh1sce.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isSHE. rewrite Hsh1entry. trivial.
			+ unfold isSHE. unfold s'.
				cbn. rewrite beqAddrTrue. trivial.
			+ rewrite <- beqAddrFalse in *. congruence.
			+ rewrite <- beqAddrFalse in *. congruence.
			+ rewrite <- beqAddrFalse in *. congruence.
			+ rewrite <- beqAddrFalse in *. congruence.
			+ rewrite <- beqAddrFalse in *. congruence.
			+ destruct H75 as [optionfreeslotslist (s2 & (n0 & (n1 & (n2 & (nbleft & Hoptionfreeslotslist)))))].
				exists optionfreeslotslist. exists s. exists n0. exists n1. exists n2.
				exists nbleft. intuition.
				++ unfold s'. f_equal. rewrite Hs. simpl. intuition.
						rewrite Hsh1entryEq. f_equal.
				++ assert(HfreeSlotsEq : getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft =
      															optionfreeslotslist) by intuition.
					rewrite <- HfreeSlotsEq.
					apply eq_sym.
					eapply getFreeSlotsListRecEqN ; intuition.
					lia.
				++ assert(HfreeSlotsEq : getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft =
      															optionfreeslotslist) by intuition.
					unfold s'.
						rewrite <- HfreeSlotsEq.
						eapply getFreeSlotsListRecEqSHE ; intuition.
						+++ unfold isBE in *. unfold isSHE in *.
								destruct (lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						+++ unfold isPADDR in *. unfold isSHE in *.
								destruct (lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
			+	destruct (beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) blockToShareInCurrPartAddr) eqn:btssh1bts ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+	destruct H77 as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 & Hstates)))))))))].
				exists s1. exists s2. exists s3. exists s4. exists s5. exists s6.
				exists s7. exists s8. exists s9. exists s10. eexists. intuition.
				assert(HsEq : s = s10).
				{ subst s10. subst s9. subst s8. subst s7. subst s6. subst s5. subst s4.
					subst s3. subst s2. subst s1. simpl. subst s.
					f_equal.
				}
				rewrite <- HsEq. intuition.
} intros. simpl.
eapply bindRev.
{ (** MAL.writeSh1InChildLocationFromBlockEntryAddr **)
	eapply weaken. apply writeSh1InChildLocationFromBlockEntryAddr.
	intros. simpl.
destruct H6 as [s0 Hprops].
		destruct Hprops as [Hprops0 (*(HBEBTSChild & Hcons &*) Hprops].
		destruct Hprops as [pdentry (pdentry0 & (pdentry1
												& (bentry & (bentry0 & (bentry1 & (bentry2 & (bentry3 & (bentry4 & (bentry5 & (bentry6
												& (sceaddr & (scentry
												& (newBlockEntryAddr & (newFirstFreeSlotAddr
												& (predCurrentNbFreeSlots
												& (sh1eaddr & (sh1entry & (sh1entry0
												& Hprops))))))))))))))))))].
		assert(HSh1Offset : sh1eaddr = CPaddr (blockToShareInCurrPartAddr + sh1offset))
								by intuition.
		rewrite <- HSh1Offset in *.
		assert(HBEs0 : isBE blockToShareInCurrPartAddr s0) by intuition.
		assert(HlookupBTSs : lookup blockToShareInCurrPartAddr (memory s) beqAddr =
													lookup blockToShareInCurrPartAddr (memory s0) beqAddr)
			by intuition.
		assert(HBEbts : isBE blockToShareInCurrPartAddr s).
		{ unfold isBE. rewrite HlookupBTSs.
			apply isBELookupEq in HBEs0. destruct HBEs0 as [btsentry0 Hlookups0].
			rewrite Hlookups0. trivial.
		}
	assert(HSHEs : isSHE sh1eaddr s) by intuition.
	apply isSHELookupEq in HSHEs as [sh1entrybts HSHEs].
	exists sh1entrybts.
	assert(HSHEEq : sh1eaddr = CPaddr (blockToShareInCurrPartAddr + sh1offset)) by intuition.
	split. subst sh1eaddr. intuition.
		instantiate (1:= fun _ s =>
exists s0,
	(* s0 *)
	(partitionsIsolation s0 /\
                           kernelDataIsolation s0 /\
                           verticalSharing s0 /\ consistency s0 /\
                          consistency s0 /\
                          isPDT currentPart s0 /\
                          currentPart = currentPartition s0 /\
                         (blockToShareInCurrPartAddr = nullAddr \/
                          (exists entry : BlockEntry,
                             lookup blockToShareInCurrPartAddr
                               (memory s0) beqAddr =
                             Some (BE entry) /\
                             blockToShareInCurrPartAddr = idBlockToShare)) /\
                        beqAddr nullAddr blockToShareInCurrPartAddr =
                        false /\
                       (exists entry : BlockEntry,
                          lookup blockToShareInCurrPartAddr
                            (memory s0) beqAddr =
                          Some (BE entry)) /\
                      (isChildCurrPart = true ->
                       exists sh1entryaddr : paddr,
                         isChildCurrPart =
                         checkChild idPDchild s0 sh1entryaddr /\
                         (exists entry : BlockEntry,
                            lookup idPDchild (memory s0) beqAddr =
                            Some (BE entry) /\
                            (exists sh1entry : Sh1Entry,
                               sh1entryAddr idPDchild sh1entryaddr s0 /\
                               lookup sh1entryaddr (memory s0) beqAddr =
                               Some (SHE sh1entry)))) /\
                     bentryStartAddr idPDchild globalIdPDChild s0 /\
                    isPDT globalIdPDChild s0 /\
                   pdentryNbFreeSlots globalIdPDChild nbfreeslots s0 /\
                  zero = CIndex 0 /\
                 false = StateLib.Index.leb nbfreeslots zero /\
                pdentryFirstFreeSlot globalIdPDChild
                  childfirststructurepointer s0 /\
               beqAddr nullAddr childfirststructurepointer = false /\
              bentryAFlag blockToShareInCurrPartAddr addrIsAccessible s0 /\
             bentryPFlag blockToShareInCurrPartAddr addrIsPresent s0 /\
            pdentryVidt globalIdPDChild vidtBlockGlobalId s0 /\
           bentryStartAddr blockToShareInCurrPartAddr blockstart s0 /\
          bentryEndAddr blockToShareInCurrPartAddr blockend s0)

/\ (exists pdentry pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr : paddr, exists scentry : SCEntry,
		exists newBlockEntryAddr newFirstFreeSlotAddr : paddr,
		exists predCurrentNbFreeSlots : index,
		exists sh1eaddr : paddr, exists sh1entry sh1entry0 sh1entry1: Sh1Entry,

  s = {|
     currentPartition := currentPartition s0;
     memory := add sh1eaddr
                     (SHE
                        {|	PDchild := PDchild sh1entry0;
                        		PDflag := PDflag sh1entry0;
                        		inChildLocation := blockToShareChildEntryAddr |})
							(add sh1eaddr
                     (SHE
                        {|	PDchild := globalIdPDChild;
                        		PDflag := PDflag sh1entry;
                        		inChildLocation := inChildLocation sh1entry |})
							(add sceaddr
									(SCE {| origin := blockstart; next := next scentry |})
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) blockend)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock blockstart (endAddr (blockrange bentry)))))
								(add globalIdPDChild
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add globalIdPDChild
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := ADT.nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup sh1eaddr (memory s0) beqAddr = Some (SHE sh1entry)
/\ lookup sh1eaddr (memory s) beqAddr = Some (SHE sh1entry1) /\
sh1entry1 = {| PDchild := PDchild sh1entry0;
             	PDflag := PDflag sh1entry0;
             	inChildLocation := blockToShareChildEntryAddr |} /\
sh1entry0 = {| PDchild := globalIdPDChild;
             	PDflag := PDflag sh1entry;
             	inChildLocation := inChildLocation sh1entry |}
/\ newBlockEntryAddr = blockToShareChildEntryAddr
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6)
/\
bentry6 = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
/\
bentry5 = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) blockend))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock blockstart (endAddr (blockrange bentry))))
/\ sceaddr = (CPaddr (newBlockEntryAddr + scoffset))
/\ lookup globalIdPDChild (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup globalIdPDChild (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := ADT.nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
	(* propagate new properties (copied from last step) *)
	/\ pdentryNbFreeSlots globalIdPDChild predCurrentNbFreeSlots s
	/\ StateLib.Index.pred nbfreeslots = Some predCurrentNbFreeSlots
	/\ blockindex bentry6 = blockindex bentry5
	/\ blockindex bentry5 = blockindex bentry4
	/\ blockindex bentry4 = blockindex bentry3
	/\ blockindex bentry3 = blockindex bentry2
	/\ blockindex bentry2 = blockindex bentry1
	/\ blockindex bentry1 = blockindex bentry0
	/\ blockindex bentry0 = blockindex bentry
	/\ blockindex bentry6 = blockindex bentry
	/\ isPDT globalIdPDChild s0
	/\ isPDT globalIdPDChild s
	/\ isBE newBlockEntryAddr s0
	/\ isBE newBlockEntryAddr s
	/\ isBE blockToShareInCurrPartAddr s0
	/\ isSCE sceaddr s0
	/\ isSCE sceaddr s
	/\ isSHE sh1eaddr s0
	/\ isSHE sh1eaddr s
	/\ sceaddr = CPaddr (newBlockEntryAddr + scoffset)
	/\ sh1eaddr = CPaddr (blockToShareInCurrPartAddr + sh1offset)
	/\ firstfreeslot pdentry1 = newFirstFreeSlotAddr
	/\ newBlockEntryAddr = (firstfreeslot pdentry)
	/\ newBlockEntryAddr <> blockToShareInCurrPartAddr
	/\ newFirstFreeSlotAddr <> globalIdPDChild
	/\ newFirstFreeSlotAddr <> newBlockEntryAddr
	/\ newFirstFreeSlotAddr <> sh1eaddr
	/\ globalIdPDChild <> newBlockEntryAddr
	/\ globalIdPDChild <> blockToShareInCurrPartAddr
	/\ sh1eaddr <> sceaddr
	/\ sh1eaddr <> newBlockEntryAddr
	/\ sh1eaddr <> globalIdPDChild
	/\ sh1eaddr <> blockToShareInCurrPartAddr
	/\ sceaddr <> newBlockEntryAddr
	/\ sceaddr <> globalIdPDChild
	/\ sceaddr <> newFirstFreeSlotAddr
	/\ sceaddr <> blockToShareInCurrPartAddr
	(* pdinsertion's new free slots list and relation with list at s0 *)
	/\ (exists (optionfreeslotslist : list optionPaddr) (s2 : state)
					(n0 n1 n2 : nat) (nbleft : index),
			nbleft = CIndex (nbfreeslots - 1) /\
			nbleft < maxIdx /\
			s =
			{|
				currentPartition := currentPartition s0;
				memory :=
					add sh1eaddr
                     (SHE
                        {|	PDchild := PDchild sh1entry0;
                        		PDflag := PDflag sh1entry0;
                        		inChildLocation := blockToShareChildEntryAddr |})
						(memory s2) beqAddr
			|} /\
			optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
			getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
			optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
			n0 <= n1 /\
			nbleft < n0 /\
			n1 <= n2 /\
			nbleft < n2 /\
			n2 <= maxIdx + 1 /\
			(wellFormedFreeSlotsList optionfreeslotslist = False -> False) /\
			NoDup (filterOption optionfreeslotslist) /\
			(In newBlockEntryAddr (filterOption optionfreeslotslist) -> False))
	/\ lookup blockToShareInCurrPartAddr (memory s) beqAddr =
						lookup blockToShareInCurrPartAddr (memory s0) beqAddr

(* intermediate steps *)
/\ (exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12,
s1 = {|
     currentPartition := currentPartition s0;
     memory := add globalIdPDChild
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := ADT.nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |}
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add globalIdPDChild
		           (PDT
		              {|
		                structure := structure pdentry0;
		                firstfreeslot := firstfreeslot pdentry0;
		                nbfreeslots := predCurrentNbFreeSlots;
		                nbprepare := nbprepare pdentry0;
		                parent := parent pdentry0;
		                MPU := MPU pdentry0;
		                vidtBlock := vidtBlock pdentry0
		              |}
                 ) (memory s1) beqAddr |}
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry)
	                  (write bentry) (exec bentry)
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock blockstart (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |}
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0)
                     (write bentry0) (exec bentry0)
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) blockend))
                 ) (memory s3) beqAddr |}
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1)
                    (write bentry1) (exec bentry1)
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |}
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2)
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |}
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3)
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |}
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4)
                       (present bentry4) (accessible bentry4)
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |}
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e
                    (present bentry5) (accessible bentry5)
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |}
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr
								(SCE {| origin := blockstart; next := next scentry |}
                 ) (memory s9) beqAddr |}
/\ s11 = {|
     currentPartition := currentPartition s10;
     memory := add sh1eaddr
        (SHE
           {|
             PDchild := globalIdPDChild;
             PDflag := PDflag sh1entry;
             inChildLocation := inChildLocation sh1entry
           |}) (memory s10) beqAddr |}
/\ s12 = {|
     currentPartition := currentPartition s11;
     memory := add sh1eaddr
         (SHE
            {|	PDchild := PDchild sh1entry0;
            		PDflag := PDflag sh1entry0;
            		inChildLocation := blockToShareChildEntryAddr
           |}) (memory s11) beqAddr |}
/\ consistency s10))).
intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			destruct Hprops as [Hs Hprops].
			split.
			exists s0. split. intuition.
			exists pdentry. exists pdentry0. exists pdentry1.
			exists bentry. exists bentry0. exists bentry1. exists bentry2. exists bentry3.
			exists bentry4. exists bentry5. exists bentry6. exists sceaddr. exists scentry.
			exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
			exists sh1eaddr. exists sh1entry. exists sh1entry0.
			assert(beqsh1pdchild : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) globalIdPDChild = false)
					by (subst sh1eaddr; rewrite <- beqAddrFalse ; intuition).
			assert(beqsh1newB : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) newBlockEntryAddr = false)
					by (subst sh1eaddr; rewrite <- beqAddrFalse ; intuition).
			assert(beqsh1sce : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) sceaddr = false)
					by (subst sh1eaddr; rewrite <- beqAddrFalse ; intuition).

			assert(Hsh1btsNotEq : beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) blockToShareInCurrPartAddr = false).
			{ rewrite <- beqAddrFalse in *.
				intro Hsh1btsEqfalse.
				rewrite Hsh1btsEqfalse in *.
				unfold isSHE in *. unfold isBE in *.
				destruct (lookup blockToShareInCurrPartAddr (memory s0) beqAddr) ; try(intuition ; exfalso ; congruence).
			}

			rewrite beqAddrTrue.
			assert(Hsh1entryEq : sh1entrybts = sh1entry0).
			{ rewrite HSHEs in *.
				assert(HEq : Some (SHE sh1entrybts) = Some (SHE sh1entry0)) by intuition.
				inversion HEq. trivial. }
			rewrite Hsh1entryEq in *. subst sh1eaddr.
			assert(HbtsNotNull : blockToShareInCurrPartAddr <> nullAddr)
				by (rewrite <- beqAddrFalse in * ; intuition).
			eexists. intuition.
			+ unfold s'. rewrite Hs. simpl. rewrite Hsh1entryEq. intuition.
			+ rewrite beqsh1newB.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold pdentryNbFreeSlots in *. unfold s'.
 				cbn.
				rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isPDT. unfold s'. cbn.
				rewrite beqsh1pdchild.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isBE. unfold s'.
				cbn.
				rewrite beqsh1newB.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isSCE. unfold s'.
				cbn.
				rewrite beqsh1sce.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ unfold isSHE. unfold s'.
				cbn. rewrite beqAddrTrue. trivial.
			+ destruct H84 as [optionfreeslotslist (s2 & (n0 & (n1 & (n2 & (nbleft & Hoptionfreeslotslist)))))].
				exists optionfreeslotslist. exists s. exists n0. exists n1. exists n2.
				exists nbleft. intuition.
				++ unfold s'. f_equal. rewrite Hs. simpl. intuition.
						rewrite Hsh1entryEq. f_equal.
				++ assert(HfreeSlotsEq : getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft =
      															optionfreeslotslist) by intuition.
					rewrite <- HfreeSlotsEq.
					apply eq_sym.
					eapply getFreeSlotsListRecEqN ; intuition.
					lia.
				++ assert(HfreeSlotsEq : getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft =
      															optionfreeslotslist) by intuition.
					unfold s'.
					assert(newFsceNotEq : newFirstFreeSlotAddr <> (CPaddr (blockToShareInCurrPartAddr + sh1offset)))
							by intuition.
						rewrite <- HfreeSlotsEq.
						eapply getFreeSlotsListRecEqSHE ; intuition.
						+++ unfold isBE in *. unfold isSHE in *.
								destruct (lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						+++ unfold isPADDR in *. unfold isSHE in *.
								destruct (lookup (CPaddr (blockToShareInCurrPartAddr + sh1offset)) (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
			+	destruct (beqAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset)) blockToShareInCurrPartAddr) eqn:btssh1bts ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			+ destruct H87 as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 & (s11 & Hstates))))))))))].
				exists s1. exists s2. exists s3. exists s4. exists s5. exists s6.
				exists s7. exists s8. exists s9. exists s10. exists s11.
				eexists. intuition.
		+ assert(HbtsNotNull : blockToShareInCurrPartAddr <> nullAddr)
				by (rewrite <- beqAddrFalse in * ; intuition).
			intuition.
			++ (* wellFormedFstShadowIfBlockEntry *)
					(* DUP insertNewEntry *)
					unfold wellFormedFstShadowIfBlockEntry.
					intros pa HBEaddrs. intuition.

					(* check all possible values for pa in the modified state s
								-> only possible are newBlockEntryAddr and blockToShareInCurrPartAddr

						1) if pa == blockToShareInCurrPartAddr :
								so blockToShareInCurrPartAddr+sh1offset = sh1eaddr :
								-> still a SHE at s -> OK
						2) pa <> blockToShareInCurrPartAddr :
								3) if pa == newBlockEntryAddr :
										so pa+sh1offset :
										- is not modified -> leads to s0 -> OK
								4) if pa <> newBlockEntryAddr :
									- relates to another bentry than newBlockentryAddr
										(either in the same structure or another)
										- other entry not modified -> leads to s0 -> OK
					*)

					(* 1) isBE pa s in hypothesis: eliminate impossible values for pa *)
					destruct (beqAddr globalIdPDChild pa) eqn:beqpdpa in HBEaddrs ; try(exfalso ; congruence).
					* (* globalIdPDChild = pa *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpa.
						rewrite <- beqpdpa in *.
						unfold isPDT in *. unfold isBE in *.
						destruct (lookup globalIdPDChild (memory s) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
						destruct v eqn:Hv ; try(exfalso ; congruence).
					* (* globalIdPDChild <> pa *)
						destruct (beqAddr sceaddr pa) eqn:beqpasce ; try(exfalso ; congruence).
						** (* sceaddr <> pa *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpasce.
							rewrite <- beqpasce in *.
							unfold isSCE in *. unfold isBE in *.
							destruct (lookup sceaddr (memory s) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
							destruct v eqn:Hv ; try(exfalso ; congruence).
						** (* sceaddr = pa *)
							destruct (beqAddr sh1eaddr pa) eqn:beqsh1pa ; try(exfalso ; congruence).
							*** (* sh1eaddr = pa *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1pa.
									rewrite <- beqsh1pa in *.
									unfold isSHE in *. unfold isBE in *.
									destruct (lookup sh1eaddr (memory s) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
									destruct v eqn:Hv ; try(exfalso ; congruence).
							*** (* sh1eaddr <> pa *)
									destruct (beqAddr blockToShareInCurrPartAddr pa) eqn:beqbtspa ; try(exfalso ; congruence).
									**** (* 1) treat special case where blockToShareInCurrPartAddr = pa *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqbtspa.
											rewrite <- beqbtspa in *.
											unfold isSHE.
											rewrite Hs. cbn.
											subst sh1eaddr.
											rewrite beqAddrTrue. trivial.
									**** (* 2) blockToShareInCurrPartAddr <> pa *)
												destruct (beqAddr newBlockEntryAddr pa) eqn:beqnewblockpa in HBEaddrs ; try(exfalso ; congruence).
												***** (* 3) treat special case where newBlockEntryAddr = pa *)
															rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockpa.
															rewrite <- beqnewblockpa in *.
															assert(Hcons : wellFormedFstShadowIfBlockEntry s0)
																			by (unfold consistency in *; intuition).
															unfold wellFormedFstShadowIfBlockEntry in *.
															specialize (Hcons newBlockEntryAddr).
															unfold isBE in Hcons.
															assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
																		by intuition.
															rewrite HBE in *.
															apply isSHELookupEq.
															rewrite Hs. cbn.
															rewrite beqAddrTrue.
															(* eliminate impossible values for (CPaddr (newBlockEntryAddr + sh1offset)) *)
															destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqsceoffset ; try(exfalso ; congruence).
															++++ (* sceaddr = (CPaddr (newBlockEntryAddr + sh1offset)) *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceoffset.
																		assert(HwellFormedSHE : wellFormedShadowCutIfBlockEntry s0)
																						by (unfold consistency in *; intuition).
																		specialize(HwellFormedSHE newBlockEntryAddr).
																		unfold isBE in HwellFormedSHE.
																		rewrite HBE in *. destruct HwellFormedSHE ; trivial.
																		intuition. subst x.
																		unfold isSCE in *. unfold isSHE in *.
																		rewrite <- beqsceoffset in *.
																		destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
																		destruct v eqn:Hv ; try(exfalso ; congruence).
															++++ (*sceaddr <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																		repeat rewrite beqAddrTrue.
																		rewrite <- beqAddrFalse in *. intuition.
																		repeat rewrite removeDupIdentity; intuition.
																		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hfalse. (*proved before *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in Hfalse ; congruence.
																		cbn.
																		destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:newblocksh1offset.
																		+++++ (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr + sh1offset))*)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in newblocksh1offset.
																					rewrite <- newblocksh1offset in *.
																					unfold isSHE in *. rewrite HBE in *.
																					exfalso ; congruence.
																		+++++ (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																					cbn.
																					rewrite <- beqAddrFalse in *. intuition.
																					repeat rewrite removeDupIdentity; intuition.
																					destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:Hffalse. (*proved before *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in Hffalse ; congruence.
																					cbn.
																					destruct (beqAddr globalIdPDChild (CPaddr (newBlockEntryAddr + sh1offset))) eqn:pdsh1offset.
																					++++++ (* globalIdPDChild = (CPaddr (newBlockEntryAddr + sh1offset))*)
																									rewrite <- DependentTypeLemmas.beqAddrTrue in *.
																									rewrite <- pdsh1offset in *.
																									unfold isSHE in *. unfold isPDT in *.
																									destruct (lookup globalIdPDChild (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
																									destruct v eqn:Hv ; try(exfalso ; congruence).
																					++++++ (* globalIdPDChild <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																									destruct (beqAddr sh1eaddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqsh1newBsh1 ; try(exfalso ; congruence).
																									- (* sh1eaddr = (CPaddr (newBlockEntryAddr + scoffset)) *)
																										(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
																										subst sh1eaddr.
																										rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1newBsh1.
																										rewrite <- beqsh1newBsh1 in *.
																										assert(HnullAddrExistss0 : nullAddrExists s0)
																												by (unfold consistency in *; intuition).
																										unfold nullAddrExists in *. unfold isPADDR in *.
																										unfold CPaddr in beqsh1newBsh1.
																										destruct (le_dec (blockToShareInCurrPartAddr + sh1offset) maxAddr) eqn:Hj.
																										-- destruct (le_dec (newBlockEntryAddr + sh1offset) maxAddr) eqn:Hk.
																											--- simpl in *.
																												inversion beqsh1newBsh1 as [Heq].
																												rewrite PeanoNat.Nat.add_cancel_r in Heq.
																												apply CPaddrInjectionNat in Heq.
																												repeat rewrite paddrEqId in Heq.
																												congruence.
																											--- inversion beqsh1newBsh1 as [Heq].
																												rewrite Heq in *.
																												rewrite <- nullAddrIs0 in *.
																												rewrite <- beqAddrFalse in *. (* newBlockEntryAddr <> nullAddr *)
																												destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																												destruct v ; try(exfalso ; congruence).
																										-- assert(Heq : CPaddr(blockToShareInCurrPartAddr + sh1offset) = nullAddr).
																											{ rewrite nullAddrIs0.
																												unfold CPaddr. rewrite Hj.
																												destruct (le_dec 0 maxAddr) ; intuition.
																												f_equal. apply proof_irrelevance.
																											}
																											rewrite Heq in *.
																											destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																											destruct v ; try(exfalso ; congruence).
																							- (* sh1eaddr <> (CPaddr (newBlockEntryAddr + sh1offset)) *)
																								subst sh1eaddr.
																								destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqscesh1 ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1. congruence.
																								destruct (beqAddr sceaddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:beqscebtssh1 ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebtssh1. congruence.
																								cbn.
																								rewrite beqscesh1.
																								destruct (beqAddr newBlockEntryAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:beqnewsh1 ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1. congruence.
																								cbn.
																								destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqnewsh1new ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1new. congruence.
																								cbn.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																								destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:beqglobalnew ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqglobalnew. congruence.
																								cbn.
																								destruct (beqAddr globalIdPDChild (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqglobalnewsh1 ; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqglobalnewsh1. congruence.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																								assert(HSHEs0: isSHE (CPaddr (newBlockEntryAddr + sh1offset)) s0)
																									by intuition.
																								apply isSHELookupEq in HSHEs0. destruct HSHEs0 as [shentry HSHEs0].
																								(* leads to s0 *)
																								exists shentry. easy.
							***** (* newBlockEntryAddr <> pa *)
										(* 4) treat special case where pa is not equal to any modified entries*)
										assert(Hcons : wellFormedFstShadowIfBlockEntry s0)
														by (unfold consistency in *; intuition).
										unfold wellFormedFstShadowIfBlockEntry in *.
										specialize (Hcons pa).
										assert(HBEpaEq : isBE pa s = isBE pa s0).
										{	unfold isBE. rewrite Hs.
											cbn. rewrite beqAddrTrue.
											destruct (beqAddr sh1eaddr pa) eqn:Hsh1pa ; try(exfalso ; congruence).
											subst sh1eaddr.
											destruct (beqAddr sceaddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:Hscesh1 ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hscesh1. congruence.
											cbn.
											destruct (beqAddr sceaddr pa) eqn:Hscepa ; try(exfalso ; congruence).
											cbn.
											destruct (beqAddr newBlockEntryAddr sceaddr) eqn:HnewBsce ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in HnewBsce. congruence.
											cbn.
											destruct (beqAddr newBlockEntryAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:HnewBsh1 ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in HnewBsh1. congruence.
											cbn.
											destruct (beqAddr newBlockEntryAddr pa) eqn:HnewBpa ; try(exfalso ; congruence).
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity; intuition.
											destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:HpdchildnewB ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in HpdchildnewB. congruence.
											cbn.
											destruct (beqAddr globalIdPDChild pa) eqn:Hpdchildpa ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hpdchildpa. congruence.
											rewrite beqAddrTrue.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity; intuition.
										}
										assert(HBEpas0 : isBE pa s0) by (rewrite HBEpaEq in * ; intuition).
										specialize(Hcons HBEpas0).
										(* no modifictions of SHE so what is true at s0 is still true at s *)
										assert(HSHEpaEq : isSHE (CPaddr (pa + sh1offset)) s = isSHE (CPaddr (pa + sh1offset)) s0).
										{
											unfold isSHE. rewrite Hs.
											cbn. rewrite beqAddrTrue.
											destruct (beqAddr sh1eaddr (CPaddr (pa + sh1offset))) eqn:beqsh1pash1 ; try(exfalso ; congruence).
											- (* sh1eaddr = (CPaddr (pa + scoffset)) *)
												(* can't discriminate by type, must do by showing it must be equal to pa and creates a contradiction *)
												subst sh1eaddr.
												rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1pash1.
												rewrite <- beqsh1pash1 in *.
												assert(HnullAddrExistss0 : nullAddrExists s0)
														by (unfold consistency in *; intuition).
												unfold nullAddrExists in *. unfold isPADDR in *.
												unfold CPaddr in beqsh1pash1.
												destruct (le_dec (blockToShareInCurrPartAddr + sh1offset) maxAddr) eqn:Hj.
												-- destruct (le_dec (pa + sh1offset) maxAddr) eqn:Hk.
													--- simpl in *.
														inversion beqsh1pash1 as [Heq].
														rewrite PeanoNat.Nat.add_cancel_r in Heq.
														apply CPaddrInjectionNat in Heq.
														repeat rewrite paddrEqId in Heq.
														rewrite <- beqAddrFalse in *.
														congruence.
													--- inversion beqsh1pash1 as [Heq].
														rewrite Heq in *.
														rewrite <- nullAddrIs0 in *.
														rewrite <- beqAddrFalse in *. (* newBlockEntryAddr <> nullAddr *)
														destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
														destruct v ; try(exfalso ; congruence).
												-- assert(Heq : CPaddr(blockToShareInCurrPartAddr + sh1offset) = nullAddr).
													{ rewrite nullAddrIs0.
														unfold CPaddr. rewrite Hj.
														destruct (le_dec 0 maxAddr) ; intuition.
														f_equal. apply proof_irrelevance.
													}
													rewrite Heq in *.
													destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v ; try(exfalso ; congruence).
										- (* sh1eaddr <> (CPaddr (newBlockEntryAddr + sh1offset)) *)
											subst sh1eaddr.
											destruct (beqAddr sceaddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:Hscesh1 ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hscesh1. congruence.
											cbn.
											destruct (beqAddr sceaddr (CPaddr (pa + sh1offset))) eqn:Hsh1pa ; try(exfalso ; congruence).
											+ (* sceaddr = (CPaddr (pa + sh1offset)) *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hsh1pa.
												rewrite <- Hsh1pa in *.
												unfold isSHE in *. unfold isSCE in *.
												destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
												destruct v eqn:Hv ; try(exfalso ; congruence).
											+ (* sceaddr <> (CPaddr (pa + sh1offset)) *)
												destruct (beqAddr newBlockEntryAddr sceaddr) eqn:HnewBsce ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in HnewBsce. congruence.
												cbn.
												destruct (beqAddr newBlockEntryAddr (CPaddr (blockToShareInCurrPartAddr + sh1offset))) eqn:HnewBsh1 ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in HnewBsh1. congruence.
												cbn.
												destruct (beqAddr newBlockEntryAddr (CPaddr (pa + sh1offset))) eqn:HnewBsh1pa ; try(exfalso ; congruence).
												* (* newBlockEntryAddr = (CPaddr (pa + sh1offset)) *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in HnewBsh1pa.
													rewrite <- HnewBsh1pa in *.
													unfold isSHE in *. unfold isBE in *.
													destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
													destruct v eqn:Hv ; try(exfalso ; congruence).
												* (* newBlockEntryAddr <> (CPaddr (pa + sh1offset)) *)
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity; intuition.
													rewrite beqAddrTrue.
													destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:HpdchildnewB ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in HpdchildnewB. congruence.
													cbn.
													destruct (beqAddr globalIdPDChild (CPaddr (pa + sh1offset))) eqn:Hpdchildsh1pa ; try(exfalso ; congruence).
													-- (* globalIdPDChild = (CPaddr (pa + sh1offset)) *)
															rewrite <- DependentTypeLemmas.beqAddrTrue in Hpdchildsh1pa.
															rewrite <- Hpdchildsh1pa in *.
															unfold isSHE in *. unfold isPDT in *.
															destruct (lookup globalIdPDChild (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
															destruct v eqn:Hv ; try(exfalso ; congruence).
													-- (* globalIdPDChild <> (CPaddr (pa + sh1offset)) *)
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity; intuition.
										}
										(* leads to s0 *)
										rewrite HSHEpaEq. intuition.
				++ (* KernelStructureStartFromBlockEntryAddrIsKS *)
						unfold KernelStructureStartFromBlockEntryAddrIsKS.
						intros bentryaddr blockidx Hlookup Hblockidx.

						assert(Hcons0 : KernelStructureStartFromBlockEntryAddrIsKS s0) by (unfold consistency in * ; intuition).
						unfold KernelStructureStartFromBlockEntryAddrIsKS in Hcons0.

						(* check all possible values for bentryaddr in the modified state s
								-> only possible is newBlockEntryAddr
							1) if bentryaddr == newBlockEntryAddr :
									so KS is
									- still a BlockEntry in s, index not modified
										- kernelStart is newBlock -> still a BE
										- kernelStart is not modified -> leads to s0 -> OK
							2) if bentryaddr <> newBlockEntryAddr :
									- relates to another bentry than newBlockentryAddr
										(either in the same structure or another)
										- kernelStart is newBlock -> still a BE
										- kernelStart is not modified -> leads to s0 -> OK
					*)
						(* Check all values except newBlockEntryAddr *)
						destruct (beqAddr sceaddr bentryaddr) eqn:beqscebentry; try(exfalso ; congruence).
						-	(* sceaddr = bentryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebentry.
							rewrite <- beqscebentry in *.
							unfold isSCE in *.
							unfold isBE in *.
							destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
						-	(* sceaddr <> bentryaddr *)
							destruct (beqAddr globalIdPDChild bentryaddr) eqn:beqpdbentry; try(exfalso ; congruence).
							-- (* globalIdPDChild = bentryaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdbentry.
								rewrite <- beqpdbentry in *.
								unfold isPDT in *.
								unfold isBE in *.
								destruct (lookup globalIdPDChild (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
							-- (* globalIdPDChild <> bentryaddr *)
									destruct (beqAddr sh1eaddr bentryaddr) eqn:beqsh1bentry ; try(exfalso ; congruence).
									--- (* sh1eaddr = bentryaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1bentry.
											rewrite <- beqsh1bentry in *.
											unfold isSHE in *.
											unfold isBE in *.
											destruct (lookup sh1eaddr (memory s) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
									--- (* sh1eaddr <> bentryaddr *)
										destruct (beqAddr newBlockEntryAddr bentryaddr) eqn:newbentry ; try(exfalso ; congruence).
										---- (* newBlockEntryAddr = bentryaddr *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in newbentry.
												rewrite <- newbentry in *.
												unfold bentryBlockIndex in *.
												assert(HlookupnewBs : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6))
													by intuition.
												rewrite HlookupnewBs in *.
												destruct Hblockidx as [Hblockidx Hidxnb].
												assert(HBEnewBs0 : isBE newBlockEntryAddr s0) by intuition.
												specialize(Hcons0 newBlockEntryAddr blockidx HBEnewBs0).
												assert(HlookupnewBs0 : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
													by intuition.
												rewrite HlookupnewBs0 in *.
												assert(HblockidxEq : blockindex bentry6 = blockindex bentry) by intuition.
												rewrite HblockidxEq in *.
												intuition.
												rewrite <- Hblockidx in *.
												intuition.

											(* Check all possible values for CPaddr (newBlockEntryAddr - blockidx)
													-> only possible is newBlockEntryAddr when blockidx = 0
													1) if CPaddr (newBlockEntryAddr - blockidx) == newBlockEntryAddr :
															- still a BlockEntry in s with blockindex newBlockEntryAddr = 0 -> OK
													2) if CPaddr (newBlockEntryAddr - blockidx) <> newBlockEntryAddr :
															- relates to another bentry than newBlockentryAddr
																that was not modified
																(either in the same structure or another)
															- -> leads to s0 -> OK
											*)

											(* Check all values for KS *)
											destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
											*	(* sceaddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
												rewrite <- beqsceks in *.
												unfold isSCE in *.
												unfold isKS in *.
												destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
												destruct v ; try(exfalso ; congruence).
											*	(* sceaddr <> kernelstarts0 *)
												destruct (beqAddr globalIdPDChild (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
												** (* globalIdPDChild = (CPaddr (newBlockEntryAddr - blockidx)) *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
													rewrite <- beqpdks in *.
													unfold isPDT in *.
													unfold isKS in *.
													destruct (lookup globalIdPDChild (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v ; try(exfalso ; congruence).
												** (* pdinsertion <> (CPaddr (newBlockEntryAddr - blockidx)) *)
													destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
													*** (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
															rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
															rewrite <- beqnewks in *.
															intuition.
															unfold isKS in *. rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
															rewrite HblockidxEq. rewrite Hblockidx. intuition.
													*** (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr - blockidx)) *)
															destruct (beqAddr sh1eaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqsh1ks ; try(exfalso ; congruence).
															**** (* sh1eaddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1ks.
																		rewrite <- beqsh1ks in *.
																		unfold isSHE in *.
																		unfold isKS in *.
																		destruct (lookup sh1eaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
															**** (* sh1eaddr <> (CPaddr (newBlockEntryAddr - blockidx)) *)
																	(* true case: KS at s0 is still a KS at s -> leads to s0 *)
																	unfold isKS.
																	rewrite Hs.
																	cbn. rewrite beqAddrTrue.
																	rewrite beqsh1ks.
																	destruct (beqAddr sceaddr sh1eaddr) eqn:scesh1 ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in scesh1. congruence.
																	cbn.
																	rewrite beqsceks.
																	destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in newsce. congruence.
																	cbn.
																	rewrite beqAddrTrue.
																	destruct (beqAddr newBlockEntryAddr sh1eaddr) eqn:newBsh1 ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in newBsh1. congruence.
																	cbn.
																	rewrite beqnewks.
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
																	destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
																	cbn.
																	destruct (beqAddr globalIdPDChild (CPaddr (newBlockEntryAddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
									----	(* newBlockEntryAddr <> bentryaddr *)
												(* leads to s0 *)
												assert(HlookupbentryEq : lookup bentryaddr (memory s) beqAddr = lookup bentryaddr (memory s0) beqAddr).
												{ (* DUP *)
													rewrite Hs.
													cbn. rewrite beqAddrTrue.
													destruct (beqAddr sh1eaddr bentryaddr) eqn:sh1bentry ; try(exfalso ; congruence).
													destruct (beqAddr sceaddr sh1eaddr) eqn:scesh1 ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in scesh1. congruence.
													cbn.
													destruct (beqAddr sceaddr bentryaddr) eqn:scebentry ; try(exfalso ; congruence).
													cbn.
													destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in newsce. congruence.
													cbn.
													destruct (beqAddr newBlockEntryAddr sh1eaddr) eqn:newsh1 ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in newsh1. congruence.
													cbn.
													rewrite beqAddrTrue.
													cbn. rewrite newbentry.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
													destruct(beqAddr globalIdPDChild newBlockEntryAddr) eqn:pdchildnewB ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in pdchildnewB. congruence.
													cbn.
													destruct (beqAddr globalIdPDChild bentryaddr) eqn:pdchildbentry; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in pdchildbentry. congruence.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
												}
												assert(Hlookuppdentry : exists entry : BlockEntry,
																lookup bentryaddr (memory s) beqAddr = Some (BE entry))
														by (apply isBELookupEq in Hlookup ; intuition).
												destruct Hlookuppdentry as [bbentry Hlookuppdentry].
												assert(HblockEq : isBE bentryaddr s = isBE bentryaddr s0)
													by (unfold isBE ; rewrite HlookupbentryEq ; intuition) .
												assert(Hblocks0 : isBE bentryaddr s0) by (rewrite HblockEq in * ; intuition).
												apply isBELookupEq in Hlookup. destruct Hlookup as [blockentry Hlookup].
												unfold bentryBlockIndex in *.
												rewrite HlookupbentryEq in *. rewrite Hlookup in *.
												destruct Hblockidx as [Hblockidx Hidxnb].
												specialize(Hcons0 bentryaddr blockidx Hblocks0).
												rewrite Hlookup in *.
												assert(HblockIdx : blockidx = blockindex blockentry /\
    													 blockidx < kernelStructureEntriesNb) by intuition.
												specialize(Hcons0 HblockIdx).
												(* DUP *)
												(* Check all values *)
												destruct (beqAddr sceaddr (CPaddr (bentryaddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
												*	(* sceaddr = (CPaddr (bentryaddr - blockidx)) *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
													rewrite <- beqsceks in *.
													unfold isSCE in *.
													unfold isKS in *.
													destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v ; try(exfalso ; congruence).
												*	(* sceaddr <> (CPaddr (bentryaddr - blockidx)) *)
													destruct (beqAddr globalIdPDChild (CPaddr (bentryaddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
													** (* globalIdPDChild = (CPaddr (bentryaddr - blockidx)) *)
														rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
														rewrite <- beqpdks in *.
														unfold isPDT in *.
														unfold isKS in *.
														destruct (lookup globalIdPDChild (memory s0) beqAddr) ; try(exfalso ; congruence).
														destruct v ; try(exfalso ; congruence).
													** (* globalIdPDChild <> (CPaddr (bentryaddr - blockidx)) *)
														destruct (beqAddr newBlockEntryAddr (CPaddr (bentryaddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
														*** (* newBlockEntryAddr = (CPaddr (blockToShareInCurrPartAddr - blockidx)) *)
																rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
																rewrite <- beqnewks in *.
																intuition.
																assert(HlookupnewBs : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6))
																	by intuition.
																assert(HlookupnewBs0 : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
																	by intuition.
																assert(HblockidxEq : blockindex bentry6 = blockindex bentry)
																	by intuition.
																unfold isKS in *.
																rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
																rewrite HblockidxEq. intuition.
														*** (* newBlockEntryAddr <> (CPaddr (bentryaddr - blockidx)) *)
																destruct (beqAddr sh1eaddr (CPaddr (bentryaddr - blockidx))) eqn:beqsh1ks ; try(exfalso ; congruence).
																**** (* sh1eaddr = (CPaddr (bentryaddr - blockidx)) *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqsh1ks.
																			rewrite <- beqsh1ks in *.
																			unfold isSHE in *.
																			unfold isKS in *.
																			destruct (lookup sh1eaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																			destruct v ; try(exfalso ; congruence).
																**** 	(* sh1eaddr <> (CPaddr (bentryaddr - blockidx)) *)
																			(* true case: KS at s0 is still a KS at s -> leads to s0 *)
																			unfold isKS.
																			rewrite Hs.
																			cbn. rewrite beqAddrTrue.
																			rewrite beqsh1ks.
																			destruct (beqAddr sceaddr sh1eaddr) eqn:scesh1 ; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in scesh1. congruence.
																			cbn.
																			rewrite beqsceks.
																			destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in newsce. congruence.
																			cbn.
																			rewrite beqAddrTrue.
																			destruct (beqAddr newBlockEntryAddr sh1eaddr) eqn:newBsh1 ; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in newBsh1. congruence.
																			cbn.
																			rewrite beqnewks.
																			rewrite <- beqAddrFalse in *.
																			repeat rewrite removeDupIdentity ; intuition.
																			destruct (beqAddr globalIdPDChild newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
																			cbn.
																			destruct (beqAddr globalIdPDChild (CPaddr (bentryaddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
																			rewrite <- beqAddrFalse in *.
																			repeat rewrite removeDupIdentity ; intuition.
} intros.
	{ (** ret **)
		eapply weaken. apply WP.ret.
		intros. simpl.
		split. intuition.
		- (** consistency **)

}


----------------------------------------------------------
2: { intros.
		eapply bindRev.
		2: { intros. eapply weaken. eapply WP.ret.
		intros. simpl. exact H3.
			}
	intros. eapply weaken. eapply writeSh1InChildLocationFromBlockEntryAddr.
	intros. simpl. exact H3.
	}
	eapply weaken. apply writeSh1PDChildFromBlockEntryAddr.
	intros. simpl.
	unfold consistency in *. intuition.
	unfold wellFormedFstShadowIfBlockEntry in *.
	specialize (H6 blockToShareInCurrPartAddr H7).
	apply isSHELookupEq in H6.
	destruct H6. exists x.
	split. assumption.
	intuition. simpl. set (blockToShareAddrInSh1 := (CPaddr (blockToShareInCurrPartAddr + sh1offset))).
	eexists. assert(beqAddr blockToShareAddrInSh1 blockToShareAddrInSh1 = true).
 	destruct blockToShareAddrInSh1. simpl.
	unfold beqAddr. apply PeanoNat.Nat.eqb_refl.
	rewrite H14. split.
	f_equal. intuition.
- (*partitionsIsolation*)
	unfold partitionsIsolation. intros. simpl.
	unfold getUsedBlocks. unfold getConfigBlocks.
	unfold getMappedBlocks. set (s' := {|
       currentPartition := currentPartition s;
       memory := _ |}) in *.
	admit.
- (* kernelDataIsolation*)
	admit.
- unfold verticalSharing. intros. simpl.
	unfold getUsedBlocks. unfold getConfigBlocks.
	unfold getMappedBlocks.
	set (s' := {|
       currentPartition := currentPartition s;
       memory := _ |}) in *.
	destruct (monadToValue (readPDStructurePointer child) s') eqn:Hstucturepointer.
