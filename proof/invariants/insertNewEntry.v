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

(**  * Summary
    	Proof of insertNewEntry *)
Require Import Model.ADT Model.Monad Model.Lib
               Model.MAL.
Require Import Core.Internal Core.Services.
Require Import Proof.Consistency Proof.DependentTypeLemmas Proof.Hoare Proof.InternalLemmas
               Proof.Isolation Proof.StateLib Proof.WeakestPreconditions Proof.invariants.Invariants.
Require Import Coq.Logic.ProofIrrelevance Lia Setoid Compare_dec (*EqNat*) List Bool.

Module WP := WeakestPreconditions.

Lemma insertNewEntry 	(pdinsertion startaddr endaddr origin: paddr)
											(r w e : bool) (currnbfreeslots : index) (P : state -> Prop):
{{ fun s => partitionsIsolation s  (*/\ kernelDataIsolation s *) /\ verticalSharing s
/\ consistency s
(* to retrieve the fields in pdinsertion *)
/\ (exists pdentry, lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry))
(* to show the first free slot pointer is not NULL *)
/\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
		firstfreepointer <> nullAddr)
/\ P s
}}

Internal.insertNewEntry pdinsertion startaddr endaddr origin r w e currnbfreeslots

{{fun newentryaddr s =>
(exists s0, P s0 /\ consistency1 s (* only propagate the 1st batch*)
(* expected new state after memory writes and associated properties on the new state s *)
/\ (exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr, exists scentry : SCEntry,
		exists newBlockEntryAddr newFirstFreeSlotAddr predCurrentNbFreeSlots,
  s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |})
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
	/\ newBlockEntryAddr = newentryaddr
	/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
	/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6) /\
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
		                     (CBlock (startAddr (blockrange bentry0)) endaddr))
	/\
	bentry0 = (CBlockEntry (read bentry) (write bentry)
		                         (exec bentry) (present bentry) (accessible bentry)
		                         (blockindex bentry)
		                         (CBlock startaddr (endAddr (blockrange bentry))))
	/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
	/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
	pdentry1 = {|     structure := structure pdentry0;
		                  firstfreeslot := firstfreeslot pdentry0;
		                  nbfreeslots := predCurrentNbFreeSlots;
		                  nbprepare := nbprepare pdentry0;
		                  parent := parent pdentry0;
		                  MPU := MPU pdentry0;
											vidtBlock := vidtBlock pdentry0 |} /\
	pdentry0 = {|    structure := structure pdentry;
		                  firstfreeslot := newFirstFreeSlotAddr;
		                  nbfreeslots := nbfreeslots pdentry;
		                  nbprepare := nbprepare pdentry;
		                  parent := parent pdentry;
		                  MPU := MPU pdentry;
											vidtBlock := vidtBlock pdentry|}
	(* propagate new s0 properties *)
	 (*/\ partitionsIsolation s0   (*/\ kernelDataIsolation s0*) /\ verticalSharing s0
	/\ consistency s0
	/\ (exists pdentry, lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry))
	(* to show the first free slot pointer is not NULL *)
	/\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
	/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
			firstfreepointer <> nullAddr)
	/\ pdentryNbFreeSlots pdinsertion currnbfreeslots s0*)
	/\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0
	/\ bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
	(*/\ isPDT multiplexer s0*)


	(* propagate new properties (copied from last step) *)
	/\ pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s
	/\ StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots
	/\ blockindex bentry6 = blockindex bentry5
	/\ blockindex bentry5 = blockindex bentry4
	/\ blockindex bentry4 = blockindex bentry3
	/\ blockindex bentry3 = blockindex bentry2
	/\ blockindex bentry2 = blockindex bentry1
	/\ blockindex bentry1 = blockindex bentry0
	/\ blockindex bentry0 = blockindex bentry
	/\ blockindex bentry6 = blockindex bentry
	/\ isPDT pdinsertion s0
	/\ isPDT pdinsertion s
	/\ isBE newBlockEntryAddr s0
	/\ isBE newBlockEntryAddr s
	/\ isSCE sceaddr s0
	/\ isSCE sceaddr s
	/\ sceaddr = CPaddr (newBlockEntryAddr + scoffset)
	/\ firstfreeslot pdentry1 = newFirstFreeSlotAddr
	/\ newBlockEntryAddr = (firstfreeslot pdentry)
	/\ newFirstFreeSlotAddr <> pdinsertion
	/\ pdinsertion <> newBlockEntryAddr
	/\ newFirstFreeSlotAddr <> newBlockEntryAddr
	/\ sceaddr <> newBlockEntryAddr
	/\ sceaddr <> pdinsertion
	/\ sceaddr <> newFirstFreeSlotAddr
	(* pdinsertion's new free slots list and relation with list at s0 *)
	/\ (exists (optionfreeslotslist : list optionPaddr) (s2 : state)
					(n0 n1 n2 : nat) (nbleft : index),
	    nbleft = CIndex (currnbfreeslots - 1) /\
	    nbleft < maxIdx /\
	    s =
	    {|
	      currentPartition := currentPartition s0;
	      memory :=
	        add sceaddr (SCE {| origin := origin; next := next scentry |})
	          (memory s2) beqAddr
	    |} /\
		    ( optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
				  getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
				  optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
				  n0 <= n1 /\
				  nbleft < n0 /\
				  n1 <= n2 /\
				  nbleft < n2 /\
				  n2 <= maxIdx + 1 /\
				  (wellFormedFreeSlotsList optionfreeslotslist = False -> False) /\
				  NoDup (filterOptionPaddr optionfreeslotslist) /\
				  (In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist) -> False) /\
				  (exists optionentrieslist : list optionPaddr,
				     optionentrieslist = getKSEntries pdinsertion s2 /\
				     getKSEntries pdinsertion s = optionentrieslist /\
				     optionentrieslist = getKSEntries pdinsertion s0 /\
							(* newB in free slots list at s0, so in optionentrieslist *)
							In (SomePaddr newBlockEntryAddr) optionentrieslist)
				)

			/\ (	(*isPDT multiplexer s
					/\*) getPartitions multiplexer s2 = getPartitions multiplexer s0
					/\ getPartitions multiplexer s = getPartitions multiplexer s2
					/\ getChildren pdinsertion s2 = getChildren pdinsertion s0
					/\ getChildren pdinsertion s = getChildren pdinsertion s2
					/\ getConfigBlocks pdinsertion s2 = getConfigBlocks pdinsertion s0
					/\ getConfigBlocks pdinsertion s = getConfigBlocks pdinsertion s2
					/\ getConfigPaddr pdinsertion s2 = getConfigPaddr pdinsertion s0
					/\ getConfigPaddr pdinsertion s = getConfigPaddr pdinsertion s2
					/\ (forall block, In block (getMappedBlocks pdinsertion s2) <->
										In block (newBlockEntryAddr:: (getMappedBlocks pdinsertion s0)))
					/\ (forall block, In block (getMappedBlocks pdinsertion s) <->
										In block (newBlockEntryAddr:: (getMappedBlocks pdinsertion s0)))
					/\ (forall addr, In addr (getMappedPaddr pdinsertion s2) <->
								In addr (getAllPaddrBlock (startAddr (blockrange bentry6)) (endAddr (blockrange bentry6))
									 ++ getMappedPaddr pdinsertion s0))
					/\ (forall addr, In addr (getMappedPaddr pdinsertion s) <->
								In addr (getAllPaddrBlock (startAddr (blockrange bentry6)) (endAddr (blockrange bentry6))
									 ++ getMappedPaddr pdinsertion s0))

					/\ (* if not concerned *)
							(forall partition : paddr,
								partition <> pdinsertion ->
								isPDT partition s0 ->
								 getMappedPaddr partition s = getMappedPaddr partition s0)
					/\ (forall partition : paddr,
								partition <> pdinsertion ->
								isPDT partition s0 ->
								getConfigPaddr partition s = getConfigPaddr partition s0)
					/\ (forall partition : paddr,
															partition <> pdinsertion ->
															isPDT partition s0 ->
															getPartitions partition s = getPartitions partition s0)
					/\ (forall partition : paddr,
															partition <> pdinsertion ->
															isPDT partition s0 ->
															getChildren partition s = getChildren partition s0)
					/\ (forall partition : paddr,
															partition <> pdinsertion ->
															isPDT partition s0 ->
															getMappedBlocks partition s = getMappedBlocks partition s0)
					/\ (forall partition : paddr,
								partition <> pdinsertion ->
								isPDT partition s0 ->
								 getAccessibleMappedPaddr partition s = getAccessibleMappedPaddr partition s0)

				)
		)




(* intermediate steps *)
/\ exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10,
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |}
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |}
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
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
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |}
))
}}.
Proof.

unfold Internal.insertNewEntry.
eapply WP.bindRev.
{ (** readPDFirstFreeSlotPointer **)
	eapply weaken. apply readPDFirstFreeSlotPointer.
	intros. simpl. split. apply H.
	unfold isPDT. intuition.
	assert(Hpdinsertions : exists pdentry : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)) by trivial.
 	destruct Hpdinsertions as [pdentry Hpdinsertions].
	rewrite -> Hpdinsertions. trivial.
}
	intro newBlockEntryAddr.
	eapply bindRev.
{ (** readBlockEndFromBlockEntryAddr **)
	eapply weaken. apply readBlockEndFromBlockEntryAddr.
	intros. simpl. split. apply H.
	unfold isBE. intuition.
	assert(Hpdinsertions : exists pdentry : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)) by trivial.
 	destruct Hpdinsertions as [pdentry Hpdinsertions].
 	unfold consistency in * ; unfold consistency1 in *. intuition.
	assert(HfirstfreeslotBEs : FirstFreeSlotPointerIsBEAndFreeSlot s)
		by (unfold consistency in * ; unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
	specialize(HfirstfreeslotBEs pdinsertion pdentry Hpdinsertions).
	assert(newBlockEntryAddr = firstfreeslot pdentry).
	{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions in *. intuition. }
	assert(Hfirstfree : exists firstfreepointer : paddr,
       pdentryFirstFreeSlot pdinsertion firstfreepointer s /\
       (firstfreepointer = nullAddr -> False)) by trivial.
	destruct Hfirstfree as [firstfreeptn (HpdentryFirst & HfirstNotNull)].
	assert(firstfreeptn = firstfreeslot pdentry).
	{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions in *. intuition. }
	subst firstfreeptn.
	specialize (HfirstfreeslotBEs HfirstNotNull). subst newBlockEntryAddr.
	destruct HfirstfreeslotBEs as [HnewBisBE HnewBisFreeSlot].
	apply isBELookupEq in HnewBisBE. destruct HnewBisBE as [firstentry HnewBisBE].
	rewrite HnewBisBE ; trivial.
}
	intro newFirstFreeSlotAddr.
	eapply bindRev.
{	(** Index.pred **)
	eapply weaken. apply Index.pred.
	intros. simpl. split. apply H. intuition.
}
	intro predCurrentNbFreeSlots. simpl.
		eapply bindRev.
	{ (** MAL.writePDFirstFreeSlotPointer **)
		eapply weaken. apply WP.writePDFirstFreeSlotPointer.
		intros. simpl. intuition. destruct H5. exists x. split. assumption.
		assert(isBE newBlockEntryAddr s).
		{
			unfold isBE.
			assert(HfirstfreeslotBEs : FirstFreeSlotPointerIsBEAndFreeSlot s)
				by (unfold consistency in * ;unfold consistency in * ; unfold consistency1 in * ; intuition).
			unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
			specialize(HfirstfreeslotBEs pdinsertion x H5).
			assert(newBlockEntryAddr = firstfreeslot x).
			{ unfold pdentryFirstFreeSlot in *. rewrite H5 in *. intuition. }
			destruct H6.
			assert(x0 = firstfreeslot x).
			{ unfold pdentryFirstFreeSlot in *. rewrite H5 in *. intuition. }
			subst x0. destruct H6 as [HpdentryFirst HfirstNotNull].
			specialize (HfirstfreeslotBEs HfirstNotNull). subst newBlockEntryAddr.
			destruct HfirstfreeslotBEs as [HnewBisBE HnewBisFreeSlot].
			apply isBELookupEq in HnewBisBE. destruct HnewBisBE. rewrite H6 ; trivial.
	}
instantiate (1:= fun _ s =>
isBE newBlockEntryAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry newpdentry: PDTable,
		s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr |}
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT newpdentry) /\
newpdentry = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
newBlockEntryAddr <> nullAddr /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\ isBE newBlockEntryAddr s0
		/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
		/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
		/\ newFirstFreeSlotAddr <> pdinsertion
		/\ (exists optionfreeslotslist s1 n0 n1 nbleft,
	nbleft = (CIndex (currnbfreeslots - 1)) /\
	s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	getFreeSlotsListRec n1 newFirstFreeSlotAddr s1 nbleft = optionfreeslotslist /\
	n0 <= n1 /\ nbleft < n0 /\
	nbleft < maxIdx /\
	n1 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist)) /\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
  optionentrieslist = getKSEntries pdinsertion s0 /\
	getKSEntries pdinsertion s1 = optionentrieslist /\
	(* newB in free slots list at s0, so in optionentrieslist *)
	In (SomePaddr newBlockEntryAddr) optionentrieslist)
	/\ (		(*isPDT multiplexer s
					/\*) getPartitions multiplexer s = getPartitions multiplexer s0
					/\ getChildren pdinsertion s = getChildren pdinsertion s0
					/\ getConfigBlocks pdinsertion s = getConfigBlocks pdinsertion s0
					/\ getConfigPaddr pdinsertion s = getConfigPaddr pdinsertion s0
					/\ getMappedBlocks pdinsertion s = getMappedBlocks pdinsertion s0
					/\ getMappedPaddr pdinsertion s = getMappedPaddr pdinsertion s0
				)

	)
)

). intros. simpl.
			assert(HnewfirstPDNotEq : newFirstFreeSlotAddr <> pdinsertion).
			apply (@newFirstPDNotEq newBlockEntryAddr newFirstFreeSlotAddr pdinsertion x s) ; intuition.
			rewrite beqAddrTrue. intuition. 
			- unfold isBE. cbn.
				(* show pdinsertion <> newBlockEntryAddr *)
				unfold pdentryFirstFreeSlot in *. rewrite H5 in H3.
				assert(HBEs : isBE newBlockEntryAddr s) by intuition.
				apply isBELookupEq in HBEs. destruct HBEs.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. rewrite H11. trivial.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- exists s. exists x. eexists. intuition.
				assert(HnullAddrExistss : nullAddrExists s) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold nullAddrExists in *. unfold isBE in *. unfold isPADDR in *.
				subst newBlockEntryAddr. destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
				unfold isPDT. rewrite H5. trivial.
				eexists. eexists. eexists. eexists ?[n1]. eexists ?[nbleft].
				split. intuition. split. intuition. split. intuition. split.
				apply getFreeSlotsListRecEqPDT.
				apply (@newFirstPDNotEq newBlockEntryAddr newFirstFreeSlotAddr pdinsertion x s) ; intuition.
				unfold isBE. rewrite H5. intuition.
				unfold isPADDR. rewrite H5. intuition.
				assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold NoDupInFreeSlotsList in *.
				specialize(HNoDupInFreeSlotsList pdinsertion x H5).
				destruct HNoDupInFreeSlotsList.
				unfold getFreeSlotsList in *.
				rewrite H5 in *.
				destruct H6. unfold pdentryFirstFreeSlot in *. rewrite H5 in *.
				destruct(beqAddr (firstfreeslot x) nullAddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hf.	exfalso ; intuition ; congruence.
				rewrite <- H3 in *.
				assert(HnbleftLtMaxIdx : (nbfreeslots x) < maxIdx+1).
				{ set(i:= nbfreeslots x). destruct i. simpl ; intuition.
					apply Lt.le_lt_n_Sm in Hi.
					destruct maxIdx; intuition.
					assert(Hsucc: S (S n) = S n +1).
					rewrite PeanoNat.Nat.add_1_r. reflexivity.
					rewrite <- Hsucc. intuition.
				}
				rewrite FreeSlotsListRec_unroll in H11.
				unfold getFreeSlotsListAux in *.
				assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
				rewrite Hiter1 in *.
				apply isBELookupEq in H8. destruct H8.
				unfold bentryEndAddr in *.
				rewrite H6 in *. rewrite <- H2 in *.
				destruct (StateLib.Index.ltb (nbfreeslots x) zero) eqn:Hff ; try (subst ; cbn in * ; congruence).
				destruct (StateLib.Index.pred (nbfreeslots x) ) eqn:Hfff ; try (exfalso ; intuition ; subst ; cbn in * ; congruence).
				destruct H11. destruct H11. subst x0. cbn in H11.
				instantiate(n1:=maxIdx).
				assert(HnbLtmaxIdx : nbfreeslots x - 1 < maxIdx).
				{
					 apply Lt.lt_n_Sm_le in HnbleftLtMaxIdx.
						apply PeanoNat.Nat.le_lteq in HnbleftLtMaxIdx.
						intuition. apply PeanoNat.Nat.lt_lt_pred in H14.
						destruct (nbfreeslots x).
						+ destruct i0.
							* simpl. apply maxIdxNotZero.
							* cbn. rewrite PeanoNat.Nat.sub_0_r. cbn in H14. intuition.
						+ rewrite H14 in *. apply PeanoNat.Nat.sub_lt ; intuition.
							assert(1 < maxIdx). apply maxIdxBigEnough.
							intuition.
				}
				assert((CIndex (nbfreeslots x - 1)) = i).
				{ unfold CIndex.
					destruct (le_dec (nbfreeslots x - 1) maxIdx) ; simpl in * ; intuition ; try(exfalso ; congruence).
						unfold StateLib.Index.pred in *.
						destruct (gt_dec (nbfreeslots x) 0) ; try(exfalso ; congruence).
						inversion Hfff. f_equal. apply proof_irrelevance.
				}
				unfold pdentryNbFreeSlots in *. rewrite H5 in *. subst currnbfreeslots.
				rewrite H8 in *.
				assert(i < maxIdx).
				{ 
					unfold StateLib.Index.pred in *.
					destruct (gt_dec (nbfreeslots x) 0) ; try(exfalso ; congruence).
					inversion Hfff. simpl. intuition.
				}
				intuition.
				cbn in H12.
				apply NoDup_cons_iff in H12. intuition.
				apply NoDup_cons_iff in H12. intuition.
				(* KSEntries*)
				eexists. intuition.
				set (s' :=   {| currentPartition := currentPartition s;
												memory := _ |}
				).
				eapply getKSEntriesEqPDT with x; intuition.
				(* StructurePointerIsKS s *)
				unfold consistency in * ; unfold consistency1 in * ; intuition.
				(* In newB KSEntriesList*)
				assert(HnewBFreeSlots0 : In (SomePaddr newBlockEntryAddr) (getFreeSlotsList pdinsertion s)).
				{
					unfold getFreeSlotsList.
					rewrite H5. rewrite <- H3.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:HnewBNull ; try(exfalso ; congruence).
					rewrite FreeSlotsListRec_unroll.
					unfold getFreeSlotsListAux in *.
					rewrite Hiter1. rewrite Hff. rewrite H6. (*lookup newB .. s = *)
					rewrite Hfff.
					cbn. left. trivial.
				}
				assert(HinclFreeSlotsBlockEntries : inclFreeSlotsBlockEntries s)
						by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold inclFreeSlotsBlockEntries in *.
				assert(HPDTs : isPDT pdinsertion s)
					by (unfold isPDT ; rewrite H5 ; trivial).
				specialize (HinclFreeSlotsBlockEntries pdinsertion HPDTs).
				unfold incl in *.
				specialize (HinclFreeSlotsBlockEntries (SomePaddr newBlockEntryAddr) HnewBFreeSlots0).
				intuition.
				+ eapply getPartitionsEqPDT with x; intuition.
					++ { (* StructurePointerIsKS *)
								unfold consistency in * ; unfold consistency1 in * ; intuition.
						}
					++ { (*PDTIfPDFlag *)
							unfold consistency in * ; unfold consistency1 in * ; intuition.
							}
				+ eapply getChildrenEqPDT with x ; intuition.
					{ (* StructurePointerIsKS *)
								unfold consistency in * ; unfold consistency1 in * ; intuition.
						}
				+ eapply getConfigBlocksEqPDT with x ; intuition.
					unfold isPDT. rewrite H5. trivial.
				+ eapply getConfigPaddrEqPDT with x ; intuition.
					unfold isPDT. rewrite H5. trivial.
				+ eapply getMappedBlocksEqPDT with x ; intuition.
					{ (* StructurePointerIsKS *)
								unfold consistency in * ; unfold consistency1 in * ; intuition.
						}
				+ eapply getMappedPaddrEqPDT with x ; intuition.
					{ (* StructurePointerIsKS *)
								unfold consistency in * ; unfold consistency1 in * ; intuition.
						}
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writePDNbFreeSlots **)
		eapply weaken. apply WP.writePDNbFreeSlots.
		intros. intuition.
		destruct H2. destruct H1. destruct H1.
		exists x1. split. intuition.
instantiate (1:= fun _ s =>
isBE newBlockEntryAddr s /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable,
  exists pdentry0 newpdentry : PDTable, s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr |}
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT newpdentry) /\
newpdentry = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\ isBE newBlockEntryAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)

		/\ newFirstFreeSlotAddr <> pdinsertion

/\ (exists optionfreeslotslist s1 s2 n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr |} /\
	s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |}) (memory s1) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s1 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s2 nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist)) /\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s1 = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)

	/\ (		getPartitions multiplexer s1 = getPartitions multiplexer s0
					/\ getPartitions multiplexer s = getPartitions multiplexer s1
					/\ getChildren pdinsertion s1 = getChildren pdinsertion s0
					/\ getChildren pdinsertion s = getChildren pdinsertion s1
					/\ getConfigBlocks pdinsertion s1 = getConfigBlocks pdinsertion s0
					/\ getConfigBlocks pdinsertion s = getConfigBlocks pdinsertion s1
					/\ getConfigPaddr pdinsertion s1 = getConfigPaddr pdinsertion s0
					/\ getConfigPaddr pdinsertion s = getConfigPaddr pdinsertion s1
					/\ getMappedBlocks pdinsertion s1 = getMappedBlocks pdinsertion s0
					/\ getMappedBlocks pdinsertion s = getMappedBlocks pdinsertion s1
					/\ getMappedPaddr pdinsertion s1 = getMappedPaddr pdinsertion s0
					/\ getMappedPaddr pdinsertion s = getMappedPaddr pdinsertion s1
				)
	)

)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			split.
			- unfold isBE. cbn. intuition.
			(* DUP: show pdinsertion <> newBlockEntryAddr *)
				apply isBELookupEq in H0. destruct H0.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. rewrite H0. trivial.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- intuition. unfold pdentryNbFreeSlots in *. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. cbn. congruence.
				+ cbn. rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
					exists x. exists x0. exists x1. eexists.
					split. unfold s'. rewrite H2. intuition.
					rewrite beqAddrTrue. (*rewrite H2.*) simpl. intuition.
					destruct H19 as [Hoptionlist (olds & (n0 & (n1 & (nbleft & Hfreeslotsolds))))].
					eexists. exists olds. exists s'. exists n0. exists n1. eexists ?[n2]. exists nbleft.
					split. intuition. split. intuition. split. intuition. split. intuition.
					unfold s'. f_equal. subst olds. subst s. cbn. trivial.
					f_equal. subst olds. subst s. cbn. trivial.
					split. intuition.
					assert(Holds : s = olds).
					{ intuition. subst s. subst olds. f_equal. }
					assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
getFreeSlotsListRec n1 newFirstFreeSlotAddr olds nbleft).
					unfold s'. rewrite Holds.
					eapply getFreeSlotsListRecEqPDT. intuition.
					unfold isBE. rewrite <- Holds. rewrite H3. intuition.
					unfold isPADDR.  rewrite <- Holds. rewrite H3. intuition.
					split. intuition.
					split. intuition. rewrite <- H19. intuition.
					assert(HStructurePointerIsKSs : StructurePointerIsKS s).
					{
						unfold StructurePointerIsKS.
						intros pdentryaddr pdentry' Hlookup.

						assert(Hcons0 : StructurePointerIsKS x) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold StructurePointerIsKS in Hcons0.

						(* check all possible values for pdentryaddr in the modified state s
									-> only possible is pdinsertion
								1) if pdentryaddr == pdinsertion :
											- the structure pointer is not modified -> leads to s0 -> OK
								2) if pdentryaddr <> pdinsertion :
										- relates to another PD than pdinsertion,
											- the structure pointer is not modified -> leads to s0 -> OK
						*)
						(* Check all values *)

						destruct (beqAddr pdinsertion pdentryaddr) eqn:beqpdpdentry; try(exfalso ; congruence).
						--- (* pdinsertion = pdentryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpdentry.
							rewrite <- beqpdpdentry in *.
							assert(Hpdinsertions : lookup pdinsertion (memory s) beqAddr = Some (PDT x1)) by trivial.
							assert(Hpdinsertions0 : lookup pdinsertion (memory x) beqAddr = Some (PDT x0)) by trivial.
							assert(HpdentryEq : x1 = pdentry').
							{ rewrite Hpdinsertions in Hlookup. inversion Hlookup. trivial. }
							subst pdentry'.
							specialize(Hcons0 pdinsertion x0 Hpdinsertions0).
							assert(HstructureEq : (structure x1) = (structure x0)).
							{ subst x1. simpl. trivial. }
							rewrite HstructureEq.
							(* Check all values for structure pdentry  *)
								destruct (beqAddr pdinsertion (structure x0)) eqn:beqpdptn; try(exfalso ; congruence).
								** (* pdinsertion = (structure pdentry) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdptn.
									rewrite <- beqpdptn in *.
									unfold isPDT in *.
									unfold isKS in *.
									destruct (lookup pdinsertion (memory x) beqAddr) ; try(exfalso ; congruence).
									destruct v ; try(exfalso ; congruence).
								** (* pdinsertion <> (structure pdentry) *)
											unfold isKS.
											rewrite H2. (* s = .. *)
											cbn.
											rewrite beqpdptn.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity ; intuition.
							--- (* pdinsertion <> pdentryaddr *)
									assert(HPDEq : lookup pdentryaddr (memory s) beqAddr = lookup pdentryaddr (memory x) beqAddr).
									{
										rewrite H2. (* s = *)
										cbn.
										rewrite beqpdpdentry.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(Hlookups0 : lookup pdentryaddr (memory x) beqAddr = Some (PDT pdentry'))
										by (rewrite HPDEq in * ; intuition).
									specialize(Hcons0 pdentryaddr pdentry' Hlookups0).
									(* Check all values *)
										destruct (beqAddr pdinsertion (structure pdentry')) eqn:beqpdptn ; try(exfalso ; congruence).
										** (* pdinsertion = (inChildLocation sh1entry) *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdptn.
											rewrite <- beqpdptn in *.
											unfold isPDT in *.
											unfold isKS in *.
											destruct (lookup pdinsertion (memory x) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
										** (* pdinsertion <> (structure pdentry') *)
													unfold isKS.
													rewrite H2. (* s= *)
													cbn. rewrite beqpdptn.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
					}
					intuition. lia.
					intuition. rewrite H21 in *. (* getFreeSlotsListRec olds = Hoptionlist *)
					intuition.
					intuition. rewrite H21 in *. (* getFreeSlotsListRec olds = Hoptionlist *)
					intuition.
					rewrite H21 in *. intuition.
					++ (* KSEntries*)
							destruct H29 as [optionentrieslist Hoptionentrieslist]. (* exists optionentrieslist ...*)
							exists optionentrieslist. intuition.
							assert(HKSEntriesolds : getKSEntries pdinsertion olds = optionentrieslist) by trivial.
							rewrite <- HKSEntriesolds. (* getKSEntries pdinsertion olds = ...*)
							subst olds. apply eq_sym.
							eapply getKSEntriesEqPDT with x1; intuition.
					++ rewrite Holds in *.
							assumption.
					++ rewrite <- Holds.
							eapply getPartitionsEqPDT with x1; intuition.
							{ (* PDTIfPDFlag s *)
								(* DUP of final PDTIfPDflag removing useless parts *)
								assert(Hcons0 : PDTIfPDFlag x) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold PDTIfPDFlag.
								intros idPDchild sh1entryaddr HcheckChilds.
								destruct HcheckChilds as [HcheckChilds Hsh1entryaddr].
								(* develop idPDchild *)
								unfold checkChild in HcheckChilds.
								unfold entryPDT.
								unfold bentryStartAddr.

								(* Force BE type for idPDchild*)
								destruct(lookup idPDchild (memory s) beqAddr) eqn:Hlookup in HcheckChilds ; try(exfalso ; congruence).
								destruct v eqn:Hv ; try(exfalso ; congruence).
								rewrite Hlookup.
								(* check all possible values of idPDchild in s -> no match
												- lookup idPDchild s == lookup idPDchild s0
												- we didn't change the pdflag
												- explore all possible values of idPdchild's startaddr which must be a PDT
														- only possible match is with pdinsertion -> ok in this case, it means
															another entry in s0 points to pdinsertion
														- for the rest, PDTIfPDFlag at s0 prevales *)
								destruct (beqAddr pdinsertion idPDchild) eqn:beqpdidpd; try(exfalso ; congruence).
								*	(* pdinsertion = idPDchild *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidpd.
									rewrite beqpdidpd in *.
									congruence.
								* (* pdinsertion <> idPDchild *)
									assert(HidPDs0 : isBE idPDchild x).
									{ rewrite H2 in Hlookup. cbn in Hlookup.
										rewrite beqpdidpd in Hlookup.
											rewrite <- beqAddrFalse in *.
											rewrite removeDupIdentity in Hlookup; intuition.
											unfold isBE. rewrite Hlookup ; trivial.
									}
									(* PDflag was false at s0 *)
									assert(HfreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot x)
																	by (unfold consistency in * ; unfold consistency1 in *; intuition).
									unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
									assert(HPDTs0 : isPDT pdinsertion x) by assumption.
									apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
									assert(HfreeSlots0 : pdentryFirstFreeSlot pdinsertion newBlockEntryAddr x)
										 by intuition.
									specialize (HfreeSlot pdinsertion pds0 HPDTs0).
									unfold pdentryFirstFreeSlot in HfreeSlots0.
									rewrite HPDTs0 in HfreeSlots0.

									assert(Hsh1s0 : isSHE sh1entryaddr x).
									{ destruct (lookup sh1entryaddr (memory s) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
										destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
										(* prove flag didn't change *)
										rewrite H2 in Hsh1.
										cbn in Hsh1.
										destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
										(* pdinsertion <> sh1entryaddr *)
										cbn in Hsh1.
										rewrite <- beqAddrFalse in *.
										rewrite removeDupIdentity in Hsh1; intuition.
										unfold isSHE. rewrite Hsh1 in *. trivial.
									}
									specialize(Hcons0 idPDchild sh1entryaddr).
									unfold checkChild in Hcons0.
									apply isBELookupEq in HidPDs0. destruct HidPDs0 as [bentryidpd HidPDs0].
									rewrite HidPDs0 in Hcons0.
									apply isSHELookupEq in Hsh1s0. destruct Hsh1s0 as [sh1entryidpd Hsh1s0].
									rewrite Hsh1s0 in *.
									assert(HidPDchildEq : lookup idPDchild (memory s) beqAddr = lookup idPDchild (memory x) beqAddr).
									{
										rewrite H2.
										cbn.
										rewrite beqpdidpd.
										rewrite <- beqAddrFalse in *.
										rewrite removeDupIdentity ; intuition.
									}
									(* PDflag can only be true for anything except the modified state, because
											the only candidate is newBlockEntryAddr which was a free slot so
											flag is null -> contra*)
									destruct Hcons0 as [HAFlag (HPflag & HPDflag)]. (* extract the flag information at s0 *)
									{ rewrite H2 in HcheckChilds.
										cbn in HcheckChilds.
										rewrite <- beqAddrFalse in *.
										destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hfffff; try(exfalso ; congruence).
										cbn in HcheckChilds.
										rewrite <- beqAddrFalse in *.
										rewrite removeDupIdentity in HcheckChilds; intuition.
										rewrite Hsh1s0 in HcheckChilds.
										congruence.
										unfold sh1entryAddr.
										rewrite HidPDs0.
										unfold sh1entryAddr in Hsh1entryaddr.
										rewrite Hlookup in Hsh1entryaddr.
										assumption.
									}
									(* A & P flags *)
									unfold bentryAFlag in *.
									unfold bentryPFlag in *.
									rewrite HidPDchildEq.
									rewrite HidPDs0 in *. intuition.

									(* PDflag *)
									eexists. intuition.
									unfold bentryStartAddr in *. unfold entryPDT in *.
									rewrite HidPDs0 in *. intuition.
									assert(HbentryEq : b = bentryidpd).
									{
										rewrite HidPDchildEq in *.
										inversion Hlookup ; intuition.
									}
									subst b.
								(* explore all possible values for idPdchild's startAddr
										- only possible value is pdinsertion because must be a PDT
										-> ok in this case, it means another entry in s0 points to it *)
								destruct HPDflag as [startaddr' HPDflag].
								rewrite H2. cbn.
								destruct (beqAddr pdinsertion (startAddr (blockrange bentryidpd))) eqn:beqpdx0; try(exfalso ; congruence).
								--- (* pdinsertion = (startAddr (blockrange bentryidpd)) *)
										reflexivity.
								--- (* pdinsertion <> (startAddr (blockrange bentryidpd)) *)
										rewrite <- beqAddrFalse in *.
										rewrite removeDupIdentity; intuition.
										destruct (lookup (startAddr (blockrange bentryidpd)) (memory x) beqAddr) eqn:Hlookupx0 ; try (exfalso ; congruence).
										destruct v0 eqn:Hv0 ; try (exfalso ; congruence).
										reflexivity.
							} (* end PDTIfPDFlag*)
						++ rewrite <- Holds. assumption.
						++ rewrite <- Holds.
								eapply getChildrenEqPDT with x1; intuition.
						++ rewrite <- Holds. assumption.
						++ rewrite <- Holds.
								eapply getConfigBlocksEqPDT with x1; intuition.
								assert(HPDTlookups : lookup pdinsertion (memory s) beqAddr = Some (PDT x1))
									by assumption.
								unfold isPDT. rewrite HPDTlookups. trivial.
						++ rewrite <- Holds. assumption.
						++ rewrite <- Holds.
								eapply getConfigPaddrEqPDT with x1; intuition.
								assert(HPDTlookups : lookup pdinsertion (memory s) beqAddr = Some (PDT x1))
									by assumption.
								unfold isPDT. rewrite HPDTlookups. trivial.
						++ rewrite <- Holds. assumption.
						++ rewrite <- Holds.
								eapply getMappedBlocksEqPDT with x1; intuition.
						++ rewrite <- Holds. assumption.
						++ rewrite <- Holds.
								eapply getMappedPaddrEqPDT with x1; intuition.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockStartFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockStartFromBlockEntryAddr.
		intros. intuition.
		destruct H3. intuition. destruct H2. destruct H2. destruct H2.
		assert(HBE : isBE newBlockEntryAddr s) by intuition.
		apply isBELookupEq in HBE.
		destruct HBE as [Hbentry Hlookupbentry]. exists Hbentry.
		assert(HblockNotPD : beqAddr newBlockEntryAddr pdinsertion = false).
		{		destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
					* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						rewrite Hbeq in *. unfold isPDT in *. unfold isBE in *.
						destruct (lookup pdinsertion (memory s) beqAddr) eqn:Hfalse ; try(exfalso ; congruence).
						destruct v eqn:Hvfalse ; try(exfalso ; congruence). intuition. congruence.
					* reflexivity.
		}
		split.
		-- 	intuition.
		-- instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1 : PDTable,
		exists bentry newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry)
/\ newEntry = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\
isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))) (memory s2) beqAddr |} /\

  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0/\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x2. split.
			- destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. intuition.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
			* unfold pdentryNbFreeSlots in *. cbn.
			destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			* intuition.
				assert(HBEs0 : isBE newBlockEntryAddr x) by intuition.
				apply isBELookupEq in HBEs0. destruct HBEs0 as [Hbentry0 HBEs0].
				exists x. exists x0. exists x1. exists x2. eexists. eexists.
				rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ assert(newFnewBNotEq : newFirstFreeSlotAddr <> newBlockEntryAddr).
					{ 
					apply (@newFirstnewBlockNotEq newFirstFreeSlotAddr
																				newBlockEntryAddr Hbentry0
																				pdinsertion x0 x) ; intuition.
					}
					assert(HpdnewBNotEq : pdinsertion <> newBlockEntryAddr).
					{
						intro beqpdnew.
						rewrite beqpdnew in *.
						exfalso ; congruence.
					}
					rewrite removeDupIdentity ; intuition.
					unfold s'. rewrite H3. f_equal. intuition.
					assert(Hlookups0 : lookup newBlockEntryAddr (memory s) beqAddr = lookup newBlockEntryAddr (memory x) beqAddr).
					{ rewrite H3. cbn. rewrite <- beqAddrFalse in Hbeq.
						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf.
						unfold isBE in H0. rewrite <- Hf. congruence.
						rewrite beqAddrTrue. repeat rewrite removeDupIdentity ; intuition.
					}
					rewrite <- Hlookups0. intuition.
					rewrite <- beqAddrFalse in Hbeq. intuition.
					assert(newBpdNotEq : pdinsertion <> newBlockEntryAddr).
					{ intro beqnewpd. subst pdinsertion. unfold isBE in *.
						rewrite HBEs0 in *. congruence. }

					destruct H20 as [Hoptionlist (oldolds & (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds))))))].
					eexists. exists olds.
					exists n0. exists n1. eexists ?[n2]. exists nbleft.
					split. intuition. split. intuition. split. intuition.
					unfold s'. f_equal. subst s. cbn. trivial.
					f_equal. subst olds. subst s. subst oldolds. cbn. trivial.
					split. intuition.
					assert(Holds : s = olds). intuition. subst s. subst olds. subst oldolds. f_equal.
					assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
					eapply getFreeSlotsListRecEqN ; intuition.
					lia.
					assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
																			getFreeSlotsListRec n1 newFirstFreeSlotAddr olds nbleft).
					unfold s'. rewrite Holds.
					apply getFreeSlotsListRecEqBE.
					intuition.
					unfold isBE. rewrite <- Holds. rewrite H3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					rewrite <- beqAddrFalse in *. rewrite beqAddrTrue.
					repeat rewrite removeDupIdentity ; intuition.
					intuition.
					intuition. rewrite <- Holds in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. rewrite <- H25 in *. (* n2 s = Hoptionlist*)
					rewrite HslotsEqn1n2 in *. intuition.
					intuition. rewrite <- H24 in *. (*n2 s = Hoptionlist*)
					rewrite <- Holds in *. rewrite <- HslotsEqn1n2 in *. intuition.
					intuition. rewrite <- H25 in *. (* idem *) rewrite <- Holds in *. rewrite <- HslotsEqn1n2 in *. intuition.
					rewrite <- Holds in *.

					split. intuition.
					split. intuition. rewrite <- H24 in *. (* idem *) rewrite HslotsEqn1n2 in *. intuition.
					split. intuition. split. intuition. split. intuition.
					split. intuition. lia.
					split. intuition. lia.
					split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H25 in *. (* idem *) intuition.
					intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H24 in *. intuition.
					intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H24 in *. intuition.

					(* KSEntries *)
					destruct H35 as [optionentrieslist Hoptionentrieslist].
					exists optionentrieslist. intuition.
					assert(HKSEntriess : optionentrieslist = getKSEntries pdinsertion s) by trivial.
					rewrite HKSEntriess. (* getKSEntries pdinsertion olds = ...*)
					eapply getKSEntriesEqBE ; intuition.
					(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x2)) by trivial.
					unfold isPDT. rewrite Hlookuppds. trivial.*)
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockEndFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockEndFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		exists x5. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist)) /\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0/\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			intuition. exists x. split.
			- destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+	unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H24 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H28 in *. (* n2 s = Hoptionlist *)
							rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H27 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H28 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H27 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H28 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H27 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H27 in *. (*idem*) intuition.

							(* KSEntries *)
							destruct H38 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							assert(HlookupnewBs : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x5)) by trivial.
							unfold isBE. rewrite HlookupnewBs. trivial.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockAccessibleFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockAccessibleFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2.
		 exists x6. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0/\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H25 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H29 in *. (* n2 s = Hoptionlist *) rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H28 in *. (*idem *) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H29 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H28 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H29 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H28 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H28 in *. (*idem*) intuition.

							(* KSEntries *)
							destruct H39 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							unfold isBE. rewrite H4. trivial.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockPresentFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockPresentFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2.
		 exists x7. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H26 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H30 in *. (*n2 s = Hoptionlist*) rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H29 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H30 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H29 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H30 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H29 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H29 in *. (*idem*) intuition.

							(* KSEntries *)
							destruct H40 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							unfold isBE. rewrite H4. trivial.
}	intros. simpl.

eapply bindRev.
	{ (**  MAL.writeBlockRFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockRFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2.
		 exists x8. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist)) /\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H27 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H31 in *. (* n2 s = Hoptionlist *) rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H30 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H31 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H30 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H31 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H30 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H30 in *. (*idem*) intuition.

							(* KSEntries *)
							destruct H41 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							unfold isBE. rewrite H4. trivial.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockWFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockWFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2.
		 exists x9. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8. exists x9.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H28 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H32 in *. (* n2 s = Hoptionlist *) rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H31 in *. (*idem*) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H32 in *. (*idem*)rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H31 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H32 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H31 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H31 in *. (*idem *) intuition.

							(* KSEntries *)
							destruct H42 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							unfold isBE. rewrite H4. trivial.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeBlockXFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockXFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2.
		exists x10. intuition.

			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\

pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0,  exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 newEntry : BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
          /\
P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)

)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. intuition. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8. exists x9. exists x10.
							rewrite beqAddrTrue. eexists.
							intuition. unfold s'. rewrite H3. f_equal.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H29 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
							eexists. exists s.
							exists n0. exists n1. eexists ?[n2]. exists nbleft.
							split. intuition. split. intuition.
							split. intuition. f_equal. subst s. cbn. trivial.
							split. intuition.
							assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
							eapply getFreeSlotsListRecEqN ; intuition.
							lia.
							fold s'.
							assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
										getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
							unfold s'.
							apply getFreeSlotsListRecEqBE. intuition.
							unfold isBE. rewrite H3. cbn. rewrite beqAddrTrue. trivial.
							intuition.
							intuition.
							assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
							apply HwellFormed. rewrite <- H33 in *. (* n2 s = Hoptionlist *) rewrite HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H32 in *. (*idem *) rewrite <- HslotsEqn1n2 in *. intuition.
							intuition. rewrite <- H33 in *. (*idem *) rewrite <- HslotsEqn1n2 in *. intuition.

							split. intuition.
							split. intuition. rewrite <- H32 in *. (*idem*) rewrite HslotsEqn1n2 in *. intuition.
							split. intuition. split. intuition. split. intuition.
							split. intuition. lia.
							split. intuition. lia.
							split. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H33 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H32 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H32 in *. (*idem*)intuition.

							(* KSEntries *)
							destruct H43 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							eapply getKSEntriesEqBE ; intuition.
							(*assert(Hlookuppds : lookup pdinsertion (memory s) beqAddr = Some (PDT x3)) by trivial.
							unfold isPDT. rewrite Hlookuppds. trivial.*)
							unfold isBE. rewrite H4. trivial.
}	intros. simpl.
eapply bindRev.
	{ (**  MAL.writeSCOriginFromBlockEntryAddr **)
		eapply weaken. apply writeSCOriginFromBlockEntryAddr.
		intros. simpl. destruct H. destruct H.
		assert(HSCE : wellFormedShadowCutIfBlockEntry s).
		{ unfold wellFormedShadowCutIfBlockEntry. intros. simpl.
			exists (CPaddr (pa + scoffset)). intuition.

			intuition. destruct H4 as [s0].
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
			assert(HSCEEq : isSCE (CPaddr (pa + scoffset)) s = isSCE (CPaddr (pa + scoffset)) s0).
			{
				intuition. rewrite H3. (* s= *) unfold isSCE. cbn.
				destruct (beqAddr newBlockEntryAddr (CPaddr (pa + scoffset))) eqn:Hbeq.
			rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
			rewrite <- Hbeq.
			assert (HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
			rewrite HBE.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try (exfalso ; congruence).
			destruct v eqn:Hv ; try congruence. intuition.

			rewrite beqAddrTrue. trivial.
			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			unfold isPDT in *. unfold isBE in *. rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			cbn.

			destruct (beqAddr pdinsertion (CPaddr (pa + scoffset))) eqn:Hbeqpdpa ; try congruence.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			rewrite <- Hbeqpdpa. assert(HPDT : isPDT pdinsertion s0) by intuition.
			apply isPDTLookupEq in HPDT. destruct HPDT as [Hpdentry HPDT].
			rewrite HPDT. trivial.

				rewrite <- beqAddrFalse in *. rewrite beqAddrTrue.
				repeat rewrite removeDupIdentity ; intuition.
			}
			rewrite HSCEEq.
			assert(Hcons : wellFormedShadowCutIfBlockEntry s0) by
			(unfold consistency in * ; unfold consistency1 in * ; intuition).
			unfold wellFormedShadowCutIfBlockEntry in Hcons.
			assert(HBEEq : isBE pa s = isBE pa s0).
			{
				intuition. rewrite H3. unfold isBE. cbn. repeat rewrite beqAddrTrue.

				destruct (beqAddr newBlockEntryAddr pa) eqn:Hbeq.
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
				rewrite <- Hbeq.
				assert (HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
				rewrite HBE. trivial.

				rewrite <- beqAddrFalse in *.

				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
				unfold isPDT in *. unfold isBE in *. (* subst.*)
				destruct (lookup pa (memory s) beqAddr) eqn:Hpa ; try(exfalso ; congruence).
				repeat rewrite removeDupIdentity ; intuition.
				cbn.
				destruct (beqAddr pdinsertion pa) eqn:Hbeqpdpa.
				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
				rewrite <- Hbeqpdpa.
				assert(HPDT : isPDT pdinsertion s0) by intuition.
				apply isPDTLookupEq in HPDT. destruct HPDT as [Hpdentry HPDT].
				rewrite HPDT. trivial.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			rewrite HBEEq in *.
			specialize (Hcons pa H1).
			destruct Hcons as [scentryaddr (HSCEs0 & Hscentryaddr)]. intuition.
			rewrite Hscentryaddr in *. intuition.
}
intuition.
- 	destruct H3 as [s0].
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		apply isBELookupEq.
		assert(Hnewblocks : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x10)) by intuition.
		exists x10. intuition.
	- unfold KernelStructureStartFromBlockEntryAddrIsKS. intros. simpl.
		destruct H3 as [s0].
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		intuition.

		assert(Hblockindex1 : blockindex x10 = blockindex x8).
		{ subst x10. subst x9.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x8.
		intuition.
		}
		assert(Hblockindex2 : blockindex x8 = blockindex x6).
		{ subst x8. subst x7.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x6) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x6) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x6.
		intuition.
		}
		assert(Hblockindex3 : blockindex x6 = blockindex x4).
		{ subst x6. subst x5.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x4) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x4) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x4.
		intuition.
		}
		assert(Hblockindex4 : blockindex x4 = blockindex x3).
		{ subst x4.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x3) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x3) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. destruct blockentry_d. destruct x3.
		intuition.
		}
		assert(isKS (CPaddr (blockentryaddr - blockidx)) s = isKS (CPaddr (blockentryaddr - blockidx)) s0).
		{
			intuition. rewrite H3. unfold isKS. cbn. rewrite beqAddrTrue.

			destruct (beqAddr newBlockEntryAddr (CPaddr (blockentryaddr - blockidx))) eqn:Hbeq.
			rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
			rewrite <- Hbeq.
			assert (HBE :  lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
			rewrite HBE ; trivial.
			f_equal.
			assert(Hblockindex : blockindex x9 = blockindex x8).
			{ subst x9.
			 	unfold CBlockEntry.
				destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
				intuition. simpl. intuition.
				destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
				cbn. destruct blockentry_d. destruct x8.
				intuition.
			}
			rewrite <- Hblockindex4. rewrite <- Hblockindex3. rewrite <- Hblockindex2.
			rewrite <- Hblockindex. intuition.
			unfold CBlockEntry. destruct (lt_dec (blockindex x9) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
			intuition.
			destruct blockentry_d. destruct x9.
			intuition.

			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			unfold isPDT in *. unfold isKS in *. rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition. cbn.
			destruct (beqAddr pdinsertion (CPaddr (blockentryaddr - blockidx))) eqn:Hbeqpdpa ; try congruence.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			rewrite <- Hbeqpdpa.
			assert(HPDTs0 : isPDT pdinsertion s0) by intuition.
			apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
			rewrite HPDTs0. trivial.
			rewrite beqAddrTrue.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
		}
			rewrite H31.
			assert(Hcons0 : KernelStructureStartFromBlockEntryAddrIsKS s0)
				by (unfold consistency in * ; unfold consistency1 in *; intuition).
			unfold KernelStructureStartFromBlockEntryAddrIsKS in *.
			assert(HBEs : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x10)) by intuition.
			(* pdinsertion <> newBlockEntryAddr *)
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock ; try (exfalso ; congruence).
				++ (* pdinsertion = newBlockEntryAddr *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in *.
						assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
						unfold isPDT in *. rewrite Hbeqpdblock in *. rewrite HBE in *. intuition.
				++ (* pdinsertion <> newBlockEntryAddr *)
						destruct (beqAddr pdinsertion blockentryaddr) eqn:Hbeqpdaddr ; try (exfalso ; congruence).
					+++ (* pdinsertion = blockentryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in *.
							rewrite <- Hbeqpdaddr in *.
							unfold isPDT in *.
							unfold isBE in *.
							destruct(lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					+++ (* pdinsertion <> blockentryaddr *)
							destruct (beqAddr newBlockEntryAddr blockentryaddr) eqn:Hbeqnewblock ; try (exfalso ; congruence).
							++++ (* newBlockEntryAddr = blockentryaddr) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in *.
									rewrite <- Hbeqnewblock in *. intuition.
									assert(HBEs0 : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
									assert(HisBEs0 : isBE newBlockEntryAddr s0) by (unfold isBE ; rewrite HBEs0 ; trivial).
									assert (HbentryIdxEq : bentryBlockIndex newBlockEntryAddr blockidx s = bentryBlockIndex newBlockEntryAddr blockidx s0).
									{ unfold bentryBlockIndex. rewrite HBEs0. intuition.
										rewrite HBEs.
										f_equal. rewrite <- Hblockindex4. rewrite <- Hblockindex3.
										rewrite <- Hblockindex2. rewrite <- Hblockindex1. reflexivity.
									}
									assert(Hbentry : bentryBlockIndex newBlockEntryAddr blockidx s) by intuition.
									rewrite HbentryIdxEq in *.
									specialize (Hcons0 newBlockEntryAddr blockidx HisBEs0 Hbentry).
									intuition.
							++++ (* newBlockEntryAddr <> blockentryaddr) *)
									assert(HBEEq : isBE blockentryaddr s = isBE blockentryaddr s0).
									{ unfold isBE.
										rewrite H3.
										cbn.
										rewrite beqAddrTrue.
										rewrite Hbeqnewblock.
										cbn.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										cbn.
										destruct (beqAddr pdinsertion blockentryaddr) eqn:Hff ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn.
										rewrite beqAddrTrue.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(HBlocks0 : isBE blockentryaddr s0) by (rewrite HBEEq in * ; intuition).
									assert(HLookupEq: lookup blockentryaddr (memory s) beqAddr = lookup blockentryaddr (memory s0) beqAddr).
									{
										rewrite H3.
										cbn.
										rewrite beqAddrTrue.
										rewrite Hbeqnewblock.
										cbn.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										cbn.
										destruct (beqAddr pdinsertion blockentryaddr) eqn:Hff ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn.
										rewrite beqAddrTrue.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(HBentryIndexEq : bentryBlockIndex blockentryaddr blockidx s = bentryBlockIndex blockentryaddr blockidx s0).
									{
										apply isBELookupEq in H2. destruct H2 as [blockentrys HBlockLookups].
										apply isBELookupEq in HBlocks0. destruct HBlocks0 as [blockentrys0 HBlockLookups0].
										unfold bentryBlockIndex. rewrite HBlockLookups. rewrite HBlockLookups0.
										rewrite HLookupEq in *.
										rewrite HBlockLookups in HBlockLookups0.
										injection HBlockLookups0 as HblockentryEq.
										f_equal.
										rewrite HblockentryEq. reflexivity.
									}
									assert(HBentryIndex : bentryBlockIndex blockentryaddr blockidx s0)
										by (rewrite HBentryIndexEq in * ; intuition).
									specialize(Hcons0 blockentryaddr blockidx HBlocks0 HBentryIndex).
									intuition.
- (* we know newBlockEntryAddr is BE and that the ShadowCut is well formed, so we
			know SCE exists *)
		unfold wellFormedShadowCutIfBlockEntry in *.
		destruct H3 as [s0].
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		intuition.
		assert(HBE : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x10)) by intuition.
		specialize (HSCE newBlockEntryAddr).
		unfold isBE in HSCE. rewrite HBE in *. destruct HSCE as [scentryaddr (HSCE& Hsceeq)] ; trivial.
		intuition. apply isSCELookupEq in HSCE. destruct HSCE as [Hscentry HSCE].
		rewrite Hsceeq in *.
		exists Hscentry. intuition.
		instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr, exists scentry : SCEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |})
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6) /\
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
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ sceaddr = (CPaddr (newBlockEntryAddr + scoffset))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
/\ (exists firstfreepointer, pdentryFirstFreeSlot pdinsertion firstfreepointer s0 /\
		firstfreepointer <> nullAddr)
/\ newFirstFreeSlotAddr <> pdinsertion
/\ pdinsertion <> newBlockEntryAddr
/\ newFirstFreeSlotAddr <> newBlockEntryAddr
/\ (exists optionfreeslotslist s2 (*s3*) n0 n1 n2 nbleft,
nbleft = CIndex (currnbfreeslots - 1) /\
nbleft < maxIdx /\
	s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |}) (memory s2) beqAddr |} /\
  optionfreeslotslist = getFreeSlotsListRec n1 newFirstFreeSlotAddr s2 nbleft /\
	getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = optionfreeslotslist /\
	optionfreeslotslist = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft /\
	n0 <= n1 /\ nbleft < n0 /\
	n1 <= n2 /\ nbleft < n2 /\
	n2 <= maxIdx+1 /\
	wellFormedFreeSlotsList optionfreeslotslist <> False /\
	NoDup (filterOptionPaddr (optionfreeslotslist))/\
	~ In newBlockEntryAddr (filterOptionPaddr optionfreeslotslist)
	/\ (exists optionentrieslist,
		  optionentrieslist = getKSEntries pdinsertion s2 /\
			getKSEntries pdinsertion s = optionentrieslist /\
		  optionentrieslist = getKSEntries pdinsertion s0 /\
			(* newB in free slots list at s0, so in optionentrieslist *)
			In (SomePaddr newBlockEntryAddr) optionentrieslist)
)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			+ destruct (beqAddr (CPaddr (newBlockEntryAddr + scoffset)) pdinsertion) eqn:Hbeqpdx10.
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeqpdx10.
				unfold isPDT in *.
				rewrite Hbeqpdx10 in *. rewrite HSCE in *. exfalso. congruence.
				rewrite removeDupIdentity. intuition.
				rewrite beqAddrFalse in *. intuition.
				rewrite beqAddrSym. congruence.
				+ unfold pdentryNbFreeSlots in *. cbn. rewrite <- Hsceeq in *.
					destruct (beqAddr scentryaddr pdinsertion) eqn:Hbeq.
					* (* scentryaddr = pdinsertion *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						assert(HPDT : isPDT pdinsertion s0) by intuition.
						apply isPDTLookupEq in HPDT. destruct HPDT.
						rewrite Hbeq in *. congruence.
					* (* scentryaddr <> pdinsertion *)
						intuition.
						++ rewrite removeDupIdentity. assumption.
								rewrite <- beqAddrFalse in Hbeq. intuition.
						++ 	exists s0. exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
					exists x7. exists x8. exists x9. exists x10. exists scentryaddr. exists Hscentry.
					intuition.
					unfold s'. rewrite H2. (* s= *) rewrite <- Hsceeq in *.
					+++ intuition.
					+++ destruct (beqAddr scentryaddr newBlockEntryAddr) eqn:HnewSCEq ; try(exfalso ; congruence).
					** rewrite <- DependentTypeLemmas.beqAddrTrue in HnewSCEq.
						rewrite HnewSCEq in *. congruence.
					** rewrite <- beqAddrFalse in HnewSCEq.
						rewrite removeDupIdentity ; intuition.
					+++	rewrite removeDupIdentity ; intuition.
							subst pdinsertion. congruence.
						+++ subst scentryaddr.
								assert(newFsceNotEq : newFirstFreeSlotAddr <> (CPaddr (newBlockEntryAddr + scoffset))).
								{ assert(HwellFormedSCEs0 : wellFormedShadowCutIfBlockEntry s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									assert(HBEs0 : isBE newBlockEntryAddr s0).
									unfold isBE. rewrite H4. trivial.
									specialize (HwellFormedSCEs0 newBlockEntryAddr HBEs0).
									destruct HwellFormedSCEs0 as [scentryaddr (HSCEs0 & Hscentryaddr)].
									apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [scentrys0 HSCEs0].
									subst scentryaddr.
								apply (@newFirstSCENotEq (CPaddr (newBlockEntryAddr + scoffset))
																							scentrys0
																							newBlockEntryAddr
																							newFirstFreeSlotAddr
																							pdinsertion x0 s0) ; intuition.
								}

								destruct H30 as [Hoptionlist (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
								eexists. exists s.
								exists n0. exists n1. eexists ?[n2]. exists nbleft.
								split. intuition. split. intuition.
								split. intuition. unfold s'. f_equal. subst s. cbn. trivial.
								split. intuition.
								assert(HslotsEqn1n2 : getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft = getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
								eapply getFreeSlotsListRecEqN ; intuition.
								lia.
								fold s'.
								assert(HfreeslotslistEq : getFreeSlotsListRec ?n2 newFirstFreeSlotAddr s' nbleft =
											getFreeSlotsListRec n1 newFirstFreeSlotAddr s nbleft).
								unfold s'.
								apply getFreeSlotsListRecEqSCE. intuition.
								unfold isBE. rewrite HSCE. intuition.
								unfold isPADDR. rewrite HSCE. intuition.
								split. intuition.
								split. intuition. rewrite <- H34. (*Hoptionlist = n0 s0 *) rewrite <- H33. (*n2 s = Hoptionlist*) intuition.
							intuition. lia.
							intuition. lia.
							rewrite HslotsEqn1n2 in *. intuition. rewrite <- H33 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H33 in *. (*idem*) intuition.
							intuition. rewrite HslotsEqn1n2 in *. intuition. rewrite <- H33 in *. (*idem*) intuition.

							(* KSEntries *)
							destruct H44 as [optionentrieslist Hoptionentrieslist].
							exists optionentrieslist. intuition.
							assert(HKSEntriess : getKSEntries pdinsertion s =  optionentrieslist) by trivial. 
							rewrite <- HKSEntriess. (* getKSEntries pdinsertion s = ...*)
							(*set (sh1eaddr := (CPaddr (newBlockEntryAddr + scoffset))).
							unfold s'. fold sh1eaddr.*)
							eapply getKSEntriesEqSCE with x; intuition.
							unfold isSCE. rewrite HSCE. trivial.
}	intros. simpl.

	eapply weaken. apply ret.
	intros.
	destruct H as [newpd]. destruct H. destruct H0.
	destruct H1.
	destruct H2 as [s0 [pdentry [pdentry0 [pdentry1 [bentry [bentry0 [bentry1 [bentry2
		             [bentry3 [bentry4 [bentry5 [bentry6 [sceaddr [scentry [Hs Hpropag]]]]]]]]]]]]]]].

	(* Global knowledge on current state and at s0 *)
	assert(Hblockindex1 : blockindex bentry6 = blockindex bentry5).
	{ intuition. subst bentry6.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry5.
		intuition.
	}
	assert(Hblockindex2 : blockindex bentry5 = blockindex bentry4).
	{ intuition. subst bentry5.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry4) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry4.
		intuition.
	}
	assert(Hblockindex3 : blockindex bentry4 = blockindex bentry3).
	{ intuition. subst bentry4.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry3) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry3.
		intuition.
	}
	assert(Hblockindex4 : blockindex bentry3 = blockindex bentry2).
	{ intuition. subst bentry3.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry2) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry2.
		intuition.
	}
	assert(Hblockindex5 : blockindex bentry2 = blockindex bentry1).
	{ intuition. subst bentry2.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry1) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry1.
		intuition.
	}
	assert(Hblockindex6 : blockindex bentry1 = blockindex bentry0).
	{ intuition. subst bentry1.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry0) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry0.
		intuition.
	}
	assert(Hblockindex7 : blockindex bentry0 = blockindex bentry).
	{ intuition. subst bentry0.
	 	unfold CBlockEntry.
		destruct(lt_dec (blockindex bentry) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct blockentry_d. destruct bentry.
		intuition.
	}
	assert(Hblockindex : blockindex bentry6 = blockindex bentry).
	{ rewrite Hblockindex1. rewrite Hblockindex2. rewrite Hblockindex3.
		rewrite Hblockindex4. rewrite Hblockindex5. rewrite Hblockindex6.
		intuition.
	}

	assert(HBEs0 : isBE newBlockEntryAddr s0).
	{ intuition. unfold isBE. rewrite H2. intuition. }
	assert(HBEs : isBE newBlockEntryAddr s).
	{ intuition. unfold isBE. rewrite H4. intuition. }
	assert(HlookupnewBs0 : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)) by intuition.
	assert(HlookupnewBs : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6)) by intuition.


	assert(HPDTs0 : isPDT pdinsertion s0) by intuition.
	assert(HPDTs : isPDT pdinsertion s).
	{
		assert(Hpdinsertions : lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1)) by intuition.
		unfold isPDT. rewrite Hpdinsertions. intuition.
	}
	assert(Hpdinsertions0 : lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)) by intuition.
	assert(Hpdinsertions : lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1)) by intuition.

	assert(HSCEs0 : isSCE sceaddr s0).
	{ assert(Hsceaddr : sceaddr = CPaddr (newBlockEntryAddr + scoffset)) by intuition.
		rewrite Hsceaddr.
		assert(HSCE : wellFormedShadowCutIfBlockEntry s0)
										by (unfold consistency in * ; unfold consistency1 in *; intuition).
		specialize(HSCE newBlockEntryAddr).
		unfold isBE in HSCE.
		rewrite Hpdinsertions0 in *.
		destruct HSCE as [scentryaddr HSCES0] ; trivial.
		intuition. subst scentryaddr.
		rewrite <- Hsceaddr in *.
		unfold isSHE in *. unfold isSCE in *.
		congruence.
	}
	assert(beqAddr pdinsertion sceaddr = false).
	{
		destruct (beqAddr pdinsertion sceaddr) eqn:beqpdsce; try(exfalso ; congruence).
		*	(* pdinsertion = sceaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsce.
			rewrite beqpdsce in *.
			unfold isPDT in *.
			apply isSCELookupEq in HSCEs0.
			destruct HSCEs0 as [scentryaddr HSCES0] ; trivial.
			intuition.
			exfalso;congruence.
		* (* pdinsertion <> sceaddr *)
			reflexivity.
	}
	assert(HSCEs : isSCE sceaddr s).
	{
		unfold isSCE. rewrite Hs. cbn.
		rewrite beqAddrTrue. trivial.
	}
	assert(Hscentryaddr : sceaddr = CPaddr (newBlockEntryAddr + scoffset)) by intuition.

	assert(beqpdnewB : beqAddr pdinsertion newBlockEntryAddr = false).
	{
		destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock; try(exfalso ; congruence).
		*	(* pdinsertion = newBlockEntryAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnewblock.
			rewrite beqpdnewblock in *.
			unfold isPDT in *. unfold isBE in *.
			rewrite HlookupnewBs in *.
			congruence.
		* (* pdinsertion <> newBlockEntryAddr *)
			reflexivity.
	}
	assert(beqnewBsce : beqAddr newBlockEntryAddr sceaddr = false).
	{
		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewblocksce ; try(exfalso ; congruence).
		* (* newBlockEntryAddr = sceaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblocksce.
			rewrite beqnewblocksce in *.
			unfold isBE in *. unfold isSCE in *.
			rewrite HlookupnewBs0 in *. exfalso ; congruence.
		* (* newBlockEntryAddr <> sceaddr *)
			reflexivity.
	}

	assert(HnewFirstFree : firstfreeslot pdentry1 = newFirstFreeSlotAddr).
	{ intuition. subst pdentry1. subst pdentry0. simpl. reflexivity. }

	assert(HnewB : newBlockEntryAddr = (firstfreeslot pdentry)).
	{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }

	assert(HnullAddrExists : nullAddrExists s).
	{ (* nullAddrExists s *)
		assert(Hcons0 : nullAddrExists s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold nullAddrExists in Hcons0.
		unfold isPADDR in Hcons0.

		unfold nullAddrExists.
		unfold isPADDR.

		destruct (lookup nullAddr (memory s0) beqAddr) eqn:Hlookup ; try (exfalso ; congruence).
		destruct v eqn:Hv ; try (exfalso ; congruence).

		destruct (beqAddr sceaddr newBlockEntryAddr) eqn:beqscenew; try(exfalso ; congruence).
		-	(* sceaddr = newBlockEntryAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenew.
			rewrite <- beqscenew in *.
			unfold isSCE in *.
			unfold isBE in *.
			destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hlookup'; try (exfalso ; congruence).
			destruct v0 eqn:Hv' ; try (exfalso ; congruence).
		-	(* sceaddr <> newBlockEntryAddr *)
		(* check all possible values of nullAddr in s -> nothing changed a PADDR
				so nullAddrExists at s0 prevales *)
		destruct (beqAddr pdinsertion nullAddr) eqn:beqpdnull; try(exfalso ; congruence).
		*	(* pdinsertion = nullAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnull.
			rewrite beqpdnull in *.
			unfold isPDT in *.
			rewrite Hlookup in *.
			exfalso ; congruence.
		* (* pdinsertion <> nullAddr *)
			destruct (beqAddr sceaddr nullAddr) eqn:beqscenull; try(exfalso ; congruence).
			**	(* sceaddr = nullAddr *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenull.
				unfold isSCE in *.
				rewrite <- beqscenull in *.
				rewrite Hlookup in *.
				exfalso; congruence.
			** (* sceaddr <> nullAddr *)
						destruct (beqAddr newBlockEntryAddr nullAddr) eqn:beqnewnull; try(exfalso ; congruence).
						*** (* newBlockEntryAddr = nullAddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewnull.
							unfold isBE in *.
							rewrite <- beqnewnull in *.
							rewrite Hlookup in *.
							exfalso; congruence.
						*** (* newBlockEntryAddr <> nullAddr *)
							rewrite Hs.
							simpl.
							destruct (beqAddr sceaddr nullAddr) eqn:Hf; try(exfalso ; congruence).
							rewrite beqAddrTrue.
							rewrite beqAddrSym in beqscenew.
							rewrite beqscenew.
							rewrite beqAddrTrue.
							rewrite <- beqAddrFalse in *.
							simpl.
							rewrite beqAddrFalse in beqnewnull.
							rewrite beqnewnull.
							simpl.
							rewrite beqAddrFalse in *.
							assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false)
									by intuition.
							rewrite HpdnewNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							simpl.
							destruct (beqAddr pdinsertion nullAddr) eqn:Hff; try(exfalso ; congruence).
							contradict beqpdnull. { rewrite DependentTypeLemmas.beqAddrTrue. intuition. }
							repeat rewrite removeDupIdentity ; intuition.
							rewrite Hlookup. trivial.
	} (* end of nullAddrExists *)
	assert(HnewBNotNull : newBlockEntryAddr <> nullAddr).
	{
		intro HnewBNull. rewrite HnewBNull in *.
		unfold isBE in *. unfold nullAddrExists in *. unfold isPADDR in *.
		destruct (lookup nullAddr (memory s) beqAddr) eqn:Hlookup; try (exfalso ; congruence).
		destruct v eqn:Hv ; try (exfalso ; congruence).
	}

	(* Prove ret *)
	intuition.
	exists s0. intuition.
	- (* consistency1 -> only prove consistency1 since the shared information has not
				been written in parent yet -> to be done back in main file *)
		unfold consistency1.

		(* prove all properties outside to reuse them *)

		assert(HwellFormedFstShadowIfBlockEntrys : wellFormedFstShadowIfBlockEntry s).
		{ (* wellFormedFstShadowIfBlockEntry *)
			unfold wellFormedFstShadowIfBlockEntry.
			intros pa HBEaddrs.

			(* 1) isBE pa s in hypothesis: eliminate impossible values for pa *)
			destruct (beqAddr pdinsertion pa) eqn:beqpdpa in HBEaddrs ; try(exfalso ; congruence).
			* (* pdinsertion = pa *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpa.
				rewrite <- beqpdpa in *.
				unfold isPDT in *. unfold isBE in *. rewrite H in *.
				exfalso ; congruence.
			* (* pdinsertion <> pa *)
				apply isBELookupEq in HBEaddrs. rewrite Hs in HBEaddrs. cbn in HBEaddrs. destruct HBEaddrs as [entry HBEaddrs].
				destruct (beqAddr sceaddr pa) eqn:beqpasce in HBEaddrs ; try(exfalso ; congruence).
				(* sceaddr <> pa *)
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock in HBEaddrs ; try(exfalso ; congruence).
				(* pdinsertion <> newBlockEntryAddr *)
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewblocksce in HBEaddrs ; try(exfalso ; congruence).
				(* newBlockEntryAddr <> sceaddr *)
				repeat rewrite beqAddrTrue in HBEaddrs.
				cbn in HBEaddrs.
				destruct (beqAddr newBlockEntryAddr pa) eqn:beqnewblockpa in HBEaddrs ; try(exfalso ; congruence).
				**** 	(* 2) treat special case where newBlockEntryAddr = pa *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockpa.
							rewrite <- beqnewblockpa in *.
							assert(Hcons : wellFormedFstShadowIfBlockEntry s0)
											by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold wellFormedFstShadowIfBlockEntry in *.
							specialize (Hcons newBlockEntryAddr).
							unfold isBE in Hcons.
							assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
										by intuition.
							rewrite HBE in *.
							apply isSHELookupEq.
							rewrite Hs. cbn.
							(* 3) eliminate impossible values for (CPaddr (newBlockEntryAddr + sh1offset)) *)
							destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqsceoffset ; try(exfalso ; congruence).
							++++ (* sceaddr = (CPaddr (newBlockEntryAddr + sh1offset)) *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceoffset.
										assert(HwellFormedSHE : wellFormedShadowCutIfBlockEntry s0)
														by (unfold consistency in * ; unfold consistency1 in *; intuition).
										specialize(HwellFormedSHE newBlockEntryAddr).
										unfold isBE in HwellFormedSHE.
										rewrite HBE in *. destruct HwellFormedSHE ; trivial.
										intuition. subst x.
										unfold isSCE in *. unfold isSHE in *.
										rewrite <- beqsceoffset in *.
										rewrite <- Hscentryaddr in *.
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
													destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffalse. (*proved before *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hffalse ; congruence.
													cbn.
													destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + sh1offset))) eqn:pdsh1offset.
													++++++ (* pdinsertion = (CPaddr (newBlockEntryAddr + sh1offset))*)
																	rewrite <- DependentTypeLemmas.beqAddrTrue in *.
																	rewrite <- pdsh1offset in *.
																	unfold isSHE in *. unfold isPDT in *.
																	destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
																	destruct v eqn:Hv ; try(exfalso ; congruence).
													++++++ (* pdinsertion <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity; intuition.
																	assert(HSHEs0: isSHE (CPaddr (newBlockEntryAddr + sh1offset)) s0)
																		by intuition.
																	apply isSHELookupEq in HSHEs0. destruct HSHEs0 as [shentry HSHEs0].
																	(* 4) resolve the only true case *)
																	exists shentry. easy.

					**** (* 4) treat special case where pa is not equal to any modified entries*)
								(* newBlockEntryAddr <> pa *)
								cbn in HBEaddrs.
								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfalse ; try(exfalso ; congruence).
								rewrite <- beqAddrFalse in *.
								do 6 rewrite removeDupIdentity in HBEaddrs; intuition.
								cbn in HBEaddrs.
								destruct (beqAddr pdinsertion pa) eqn:Hffalse ; try(exfalso ; congruence).
								do 4 rewrite removeDupIdentity in HBEaddrs; intuition.
								(* no modifictions of SHE so what is true at s0 is still true at s *)
								assert(HSHEEq : isSHE (CPaddr (pa + sh1offset)) s = isSHE (CPaddr (pa + sh1offset)) s0).
								{
									assert(HSHE : wellFormedFstShadowIfBlockEntry s0)
																by (unfold consistency in * ; unfold consistency1 in *; intuition).
									specialize(HSHE pa).
									unfold isBE in HSHE.
									assert(HwellFormedSHE : wellFormedShadowCutIfBlockEntry s0)
																by (unfold consistency in * ; unfold consistency1 in *; intuition).
									specialize(HwellFormedSHE pa).
									unfold isBE in HwellFormedSHE.
									rewrite HBEaddrs in *.
									destruct HwellFormedSHE as [scentryaddr HwellFormedSHEs0] ; trivial.
									intuition. subst scentryaddr.
									rewrite Hs. unfold isSHE. cbn.
									repeat rewrite beqAddrTrue.
									rewrite <- beqAddrFalse in *. intuition.
									repeat rewrite removeDupIdentity; intuition.
									assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
																by intuition.
									(* eliminate impossible values for (CPaddr (pa + sh1offset)) *)
									destruct (beqAddr sceaddr (CPaddr (pa + sh1offset))) eqn:Hscesh1offset.
									 - 	(* sceaddr = (CPaddr (pa + sh1offset)) *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hscesh1offset.
											rewrite <- Hscesh1offset in *.
											apply isSCELookupEq in HSCEs0.
											destruct HSCEs0 as [scentryaddr HSCEs0].
											rewrite HSCEs0. trivial.
											(* almost DUP with previous step *)
										- (* sceaddr <> (CPaddr (pa + sh1offset))*)
												destruct(beqAddr newBlockEntryAddr sceaddr) eqn:Hnewblocksce. (* Proved before *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hnewblocksce ; congruence.
												cbn.
												rewrite <- beqAddrFalse in *.
												destruct (beqAddr newBlockEntryAddr (CPaddr (pa + sh1offset))) eqn:newblocksh1offset.
												+ (* newBlockEntryAddr = (CPaddr (pa + sh1offset))*)
													rewrite <- DependentTypeLemmas.beqAddrTrue in newblocksh1offset.
													rewrite <- newblocksh1offset in *.
													unfold isSHE in *. rewrite HBE in *.
													exfalso ; congruence.
												+ (* newBlockEntryAddr <> (CPaddr (pa + sh1offset))*)
													cbn.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity; intuition.
													destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffalse. (*proved before *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffalse ; congruence.
													cbn.
													destruct (beqAddr pdinsertion (CPaddr (pa + sh1offset))) eqn:pdsh1offset.
													* (* pdinsertion = (CPaddr (pa + sh1offset))*)
														rewrite <- DependentTypeLemmas.beqAddrTrue in *.
														rewrite <- pdsh1offset in *.
														unfold isSHE in *. unfold isPDT in *.
														destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
														destruct v eqn:Hv ; try(exfalso ; congruence).
													* (* pdinsertion <> (CPaddr (pa + sh1offset))*)
														rewrite <- beqAddrFalse in *.
														(* resolve the only true case *)
														repeat rewrite removeDupIdentity; intuition.
							}
							rewrite HSHEEq.
							assert(HwellFormedSHE : wellFormedFstShadowIfBlockEntry s0)
														by (unfold consistency in * ; unfold consistency1 in *; intuition).
							specialize(HwellFormedSHE pa).
							unfold isBE in HwellFormedSHE.
							rewrite HBEaddrs in *. intuition.
		}

		assert(HPDTIfPDFlags : PDTIfPDFlag s).
		{ (* PDTIfPDFlag s *)
			assert(Hcons0 : PDTIfPDFlag s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
			unfold PDTIfPDFlag.
			intros idPDchild sh1entryaddr HcheckChilds.
			destruct HcheckChilds as [HcheckChilds Hsh1entryaddr].
			(* develop idPDchild *)
			unfold checkChild in HcheckChilds.
			unfold entryPDT.
			unfold bentryStartAddr.

			(* Force BE type for idPDchild*)
			destruct(lookup idPDchild (memory s) beqAddr) eqn:Hlookup in HcheckChilds ; try(exfalso ; congruence).
			destruct v eqn:Hv ; try(exfalso ; congruence).
			rewrite Hlookup.
			(* check all possible values of idPDchild in s -> only newBlock is OK
					1) if idPDchild == newBlock then contradiction because
							- we read the pdflag value of newBlock which is not modified in s so equal to s0
							- at s0 newBlock was a freeSlot so the flag was default to false
							- here we look for a flag to true, so idPDchild can't be newBlock
					2) if idPDchild <> any modified address then
							- lookup idPDchild s == lookup idPDchild s0
							- we didn't change the pdflag
							- explore all possible values of idPdchild's startaddr which must be a PDT
									- only possible match is with pdinsertion -> ok in this case, it means
										another entry in s0 points to pdinsertion
									- for the rest, PDTIfPDFlag at s0 prevales *)
			destruct (beqAddr pdinsertion idPDchild) eqn:beqpdidpd; try(exfalso ; congruence).
			*	(* pdinsertion = idPDchild *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidpd.
				rewrite beqpdidpd in *.
				congruence.
			* (* pdinsertion <> idPDchild *)
				destruct (beqAddr sceaddr idPDchild) eqn:beqsceidpd; try(exfalso ; congruence).
				**	(* sceaddr = idPDchild *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidpd.
					unfold isSCE in *.
					rewrite <- beqsceidpd in *.
					rewrite Hlookup in *.
					exfalso; congruence.
				** (* sceaddr <> idPDchild *)
						assert(HidPDs0 : isBE idPDchild s0).
						{ rewrite Hs in Hlookup. cbn in Hlookup.
							rewrite beqAddrTrue in Hlookup.
							rewrite beqsceidpd in Hlookup.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq in Hlookup. (*newBlock <> sce *)
							assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewBNotEq in Hlookup. (*pd <> newblock*)
							rewrite beqAddrTrue in Hlookup.
							cbn in Hlookup.
							destruct (beqAddr newBlockEntryAddr idPDchild) eqn:beqnewidpd; try(exfalso ; congruence).
							* (* newBlockEntryAddr = idPDchild *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewidpd.
								rewrite <- beqnewidpd.
								apply isBELookupEq. exists bentry. intuition.
							* (* newBlockEntryAddr <> idPDchild *)
								assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
								rewrite HpdnewNotEq in Hlookup. (*pd <> newblock*)
								rewrite <- beqAddrFalse in *.
								do 6 rewrite removeDupIdentity in Hlookup; intuition.
								cbn in Hlookup.
								destruct (beqAddr pdinsertion idPDchild) eqn:Hff ;try (exfalso;congruence).
								do 4 rewrite removeDupIdentity in Hlookup; intuition.
								unfold isBE. rewrite Hlookup ; trivial.
						}
						(* PDflag was false at s0 *)
						assert(HfreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot s0)
														by (unfold consistency in * ; unfold consistency1 in *; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
						assert(HfreeSlots0 : pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0)
							 by intuition.
						specialize (HfreeSlot pdinsertion pds0 HPDTs0).
						unfold pdentryFirstFreeSlot in HfreeSlots0.
						rewrite HPDTs0 in HfreeSlots0.

						assert(Hsh1s0 : isSHE sh1entryaddr s0).
						{ destruct (lookup sh1entryaddr (memory s) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
							destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
							(* prove flag didn't change *)
							rewrite Hs in Hsh1.
							cbn in Hsh1.
							rewrite beqAddrTrue in Hsh1.
							destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
							assert(HnewsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewsceNotEq in *. (* newblock <> sce *)
							cbn in Hsh1.
							destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
							destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
							* (* pdinsertion = sh1entryaddr *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
									rewrite <- beqpdsh1 in *.
									rewrite beqAddrTrue in Hsh1.
									rewrite <- beqAddrFalse in *.
									do 7 rewrite removeDupIdentity in Hsh1; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqnewpd; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
									congruence.
									cbn in Hsh1.
									rewrite beqAddrTrue in Hsh1.
									congruence.
							* (* pdinsertion <> sh1entryaddr *)
									cbn in Hsh1.
									rewrite beqAddrTrue in Hsh1.
									rewrite <- beqAddrFalse in *.
									do 7 rewrite removeDupIdentity in Hsh1; intuition.
									cbn in Hsh1.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hfff ; try (exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqnewpd; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
									congruence.
									cbn in Hsh1; intuition.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffff; try(exfalso ; congruence).
									do 3 rewrite removeDupIdentity in Hsh1; intuition.
									unfold isSHE. rewrite Hsh1 in *. trivial.
						}
						specialize(Hcons0 idPDchild sh1entryaddr).
						unfold checkChild in Hcons0.
						apply isBELookupEq in HidPDs0. destruct HidPDs0 as [x HidPDs0].
						rewrite HidPDs0 in Hcons0.
						apply isSHELookupEq in Hsh1s0. destruct Hsh1s0 as [y Hsh1s0].
						rewrite Hsh1s0 in *.
						destruct (beqAddr newBlockEntryAddr idPDchild) eqn:beqnewidpd; try(exfalso ; congruence).
						*** (* 1) newBlockEntryAddr = idPDchild *)
								(* newBlockEntryAddr at s0 is firstfreeslot, so flag is false *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewidpd.
							rewrite <- beqnewidpd.
							rewrite <- HfreeSlots0 in *.
							destruct HfreeSlot as [HnewBisBE HnewBisfreeSlot]. intuition.

							unfold isFreeSlot in HnewBisfreeSlot.
							rewrite HlookupnewBs0 in HnewBisfreeSlot.
							unfold sh1entryAddr in Hsh1entryaddr.
							rewrite Hlookup in Hsh1entryaddr.
							rewrite <- beqnewidpd in Hsh1entryaddr.
							rewrite <- Hsh1entryaddr in HnewBisfreeSlot.
							rewrite Hsh1s0 in HnewBisfreeSlot.
							rewrite <- Hscentryaddr in HnewBisfreeSlot.
							apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [scentrys0 HSCEs0].
							rewrite HSCEs0 in HnewBisfreeSlot.

							exfalso. (* Prove false in hypothesis -> flag is false *)

							destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
							-- (* sceaddr = sh1entryaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
								rewrite <- beqscesh1 in *.
								apply isSCELookupEq in HSCEs. destruct HSCEs as [scentrys HSCEs].
								rewrite HSCEs in *; congruence.
							--	(* sceaddr <> sh1entryaddr *)
								destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
								--- (* newBlockEntryAddr = sh1entryaddr *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
										rewrite <- beqnewsh1 in *.
										congruence.
								--- (* newBlockEntryAddr <> sh1entryaddr *)
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity; intuition.
										cbn.
										destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
										---- (* pdinsertion = sh1entryaddr *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
												rewrite <- beqpdsh1 in *.
												unfold isPDT in *.
												exfalso ; congruence.
										---- (* pdinsertion <> sh1entryaddr *)
												rewrite Hs in HcheckChilds.
												cbn in HcheckChilds.
												rewrite <- beqAddrFalse in *.
												rewrite beqAddrTrue in HcheckChilds.
												repeat rewrite removeDupIdentity in HcheckChilds; intuition.
												cbn in HcheckChilds.
												destruct (beqAddr sceaddr sh1entryaddr) eqn:Hf; try(exfalso ; congruence).
												destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hff; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
												destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hfff; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
												cbn in HcheckChilds.
												destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hfffff; try(exfalso ; congruence).
												do 7 rewrite removeDupIdentity in HcheckChilds; intuition.
												destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
												cbn in HcheckChilds.
												destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffffff; try(exfalso ; congruence).
												rewrite beqAddrTrue in HcheckChilds.
												do 3 rewrite removeDupIdentity in HcheckChilds; intuition.
												rewrite Hsh1s0 in HcheckChilds.
												(* expected contradiction *)
												congruence.
							*** (* 2) newBlockEntryAddr <> idPDchild *)
									assert(HidPDchildEq : lookup idPDchild (memory s) beqAddr = lookup idPDchild (memory s0) beqAddr).
									{
										rewrite Hs.
										cbn.
										rewrite beqAddrTrue.
										rewrite beqsceidpd.
										assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false)
												by intuition.
										assert(HnewsceNotEq : beqAddr newBlockEntryAddr sceaddr = false)
												by intuition.
										rewrite HpdnewNotEq.
										cbn.
										rewrite HnewsceNotEq. cbn. rewrite beqnewidpd.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										cbn.
										destruct (beqAddr pdinsertion idPDchild) eqn:Hf; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										rewrite beqAddrTrue.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn. rewrite Hf.
										repeat rewrite removeDupIdentity ; intuition.
									}
									(* PDflag can only be true for anything except the modified state, because
											the only candidate is newBlockEntryAddr which was a free slot so
											flag is null -> contra*)
									destruct Hcons0 as [HAFlag (HPflag & HPDflag)]. (* extract the flag information at s0 *)
									{ rewrite Hs in HcheckChilds.
										cbn in HcheckChilds.
										rewrite <- beqAddrFalse in *.
										rewrite beqAddrTrue in HcheckChilds.
										destruct (beqAddr sceaddr sh1entryaddr) eqn:Hf; try(exfalso ; congruence).
										rewrite <- beqAddrFalse in *.
										cbn in HcheckChilds.
										destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hff; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn in HcheckChilds.
										destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hfff; try(exfalso ; congruence).
										cbn in HcheckChilds.
										rewrite <- beqAddrFalse in *.
										do 7 rewrite removeDupIdentity in HcheckChilds; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
										cbn in HcheckChilds.
										destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hfffff; try(exfalso ; congruence).
										cbn in HcheckChilds.
										rewrite beqAddrTrue in HcheckChilds.
										rewrite <- beqAddrFalse in *.
										do 3 rewrite removeDupIdentity in HcheckChilds; intuition.
										rewrite Hsh1s0 in HcheckChilds.
										congruence.
										unfold sh1entryAddr.
										rewrite HidPDs0.
										unfold sh1entryAddr in Hsh1entryaddr.
										rewrite Hlookup in Hsh1entryaddr.
										assumption.
									}
									(* A & P flags *)
									unfold bentryAFlag in *.
									unfold bentryPFlag in *.
									rewrite HidPDchildEq.
									rewrite HidPDs0 in *. intuition.

									(* PDflag *)
									eexists. intuition.
									unfold bentryStartAddr in *. unfold entryPDT in *.
									rewrite HidPDs0 in *. intuition.
									assert(HbentryEq : b = x).
									{
										rewrite HidPDchildEq in *.
										inversion Hlookup ; intuition.
									}
									subst b.
								(* explore all possible values for idPdchild's startAddr
										- only possible value is pdinsertion because must be a PDT
										-> ok in this case, it means another entry in s0 points to it *)
								destruct HPDflag as [startaddr' HPDflag].
								rewrite Hs. cbn.
								rewrite beqAddrTrue.
								destruct (beqAddr sceaddr (startAddr (blockrange x))) eqn:beqscex0; try(exfalso ; congruence).
								- (* sceaddr = (startAddr (blockrange x)) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqscex0.
									rewrite <- beqscex0 in *.
									apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [sceaddr' HSCEs0].
									rewrite HSCEs0 in *; intuition.
								-	(* sceaddr <> (startAddr (blockrange x)) *)
									rewrite <- beqscex0 in *. (* newblock <> sce *)
									cbn.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce; try(exfalso ; congruence).
									cbn.
									destruct (beqAddr newBlockEntryAddr (startAddr (blockrange x))) eqn:beqnewx0; try(exfalso ; congruence).
									-- (* newBlockEntryAddr = (startAddr (blockrange x)) *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewx0.
											rewrite <- beqnewx0 in *. rewrite HlookupnewBs0 in *.
											intuition.
									-- (* newBlockEntryAddr <> (startAddr (blockrange x)) *)
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnew; try(exfalso ; congruence).
											cbn.
											destruct (beqAddr pdinsertion (startAddr (blockrange x))) eqn:beqpdx0; try(exfalso ; congruence).
											--- (* pdinsertion = (startAddr (blockrange x)) *)
													reflexivity.
											--- (* pdinsertion <> (startAddr (blockrange x)) *)
													rewrite beqAddrTrue.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity; intuition.
													destruct (lookup (startAddr (blockrange x)) (memory s0) beqAddr) eqn:Hlookupx0 ; try (exfalso ; congruence).
													destruct v0 eqn:Hv0 ; try (exfalso ; congruence).
													reflexivity.
		} (* end PDTIfPDFlag*)

		assert(HAccessibleNoPDFlags : AccessibleNoPDFlag s).
		{ (* AccessibleNoPDFlag s *)
			assert(Hcons0 : AccessibleNoPDFlag s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
			unfold AccessibleNoPDFlag.
			intros block sh1entryaddr HBEblocks Hsh1entryAddr HAflag.
			unfold sh1entryPDflag.
			unfold sh1entryAddr in Hsh1entryAddr.
			unfold isBE in HBEblocks.

			(* Force BE type for block*)
			destruct(lookup block (memory s) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
			destruct v eqn:Hv ; try(exfalso ; congruence).

			(* check all possible values of block in s -> only newBlock is OK
					1) if block == newBlock then
							- we read the pdflag value of newBlock which is not modified in s so equal to s0
							- at s0 newBlock was a freeSlot so the flag was default to false
					2) if block <> any modified address then
							- lookup block s == lookup block s0
							- we didn't change the pdflag
							- explore all possible values of sh1entryaddr which didn't change
									- AccessibleNoPDFlag at s0 prevales depends on the A flag
										-- we never modified the A flag, so what holds at s0 holds at s *)
			destruct (beqAddr pdinsertion block) eqn:beqpdblock; try(exfalso ; congruence).
			*	(* pdinsertion = block *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdblock.
				rewrite beqpdblock in *.
				congruence.
			* (* pdinsertion <> block *)
				destruct (beqAddr sceaddr block) eqn:beqsceblock; try(exfalso ; congruence).
				**	(* sceaddr = idPDchild *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceblock.
					unfold isSCE in *.
					rewrite <- beqsceblock in *.
					rewrite Hlookup in *.
					exfalso; congruence.
				** (* sceaddr <> block *)
					assert(HBEblocks0 : isBE block s0).
					{ rewrite Hs in Hlookup. cbn in Hlookup.
						rewrite beqAddrTrue in Hlookup.
						rewrite beqsceblock in Hlookup.
						assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
						rewrite HnewBsceNotEq in Hlookup. (*newBlock <> sce *)
						assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
						rewrite HpdnewBNotEq in Hlookup. (*pd <> newblock*)
						rewrite beqAddrTrue in Hlookup.
						cbn in Hlookup.
						destruct (beqAddr newBlockEntryAddr block) eqn:beqnewblock; try(exfalso ; congruence).
						* (* newBlockEntryAddr = block *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblock.
							rewrite <- beqnewblock.
							apply isBELookupEq. exists bentry. intuition.
						* (* newBlockEntryAddr <> block *)
							assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewNotEq in Hlookup. (*pd <> newblock*)
							rewrite <- beqAddrFalse in *.
							do 6 rewrite removeDupIdentity in Hlookup; intuition.
							cbn in Hlookup.
							destruct (beqAddr pdinsertion block) eqn:Hff ;try (exfalso;congruence).
							do 4 rewrite removeDupIdentity in Hlookup; intuition.
							unfold isBE. rewrite Hlookup ; trivial.
						}
						(* sh1entryaddr existed at s0 *)
						assert(HwellFormedSh1 : wellFormedFstShadowIfBlockEntry s0)
														by (unfold consistency in * ; unfold consistency1 in *; intuition).
						unfold wellFormedFstShadowIfBlockEntry in *.
						specialize (HwellFormedSh1 block HBEblocks0).

						assert(Hsh1s0 : isSHE sh1entryaddr s0).
						{ rewrite Hsh1entryAddr in *. assumption. }

						destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
						***	(* pdinsertion = sh1entryaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
								rewrite beqpdsh1 in *.
								unfold isSHE in *. unfold isPDT in *.
								destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v0 ; try(exfalso ; congruence).
						*** (* pdinsertion <> sh1entryaddr *)
							destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
							****	(* sceaddr = sh1entryaddr *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
									unfold isSCE in *. unfold isSHE in *.
									rewrite beqscesh1 in *.
									destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
							**** (* sceaddr <> sh1entryaddr *)
										destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
										***** (* newBlockEntryAddr = sh1entryaddr *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
													unfold isSCE in *. unfold isSHE in *.
													rewrite beqnewsh1 in *.
													destruct (lookup sh1entryaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v0 ; try(exfalso ; congruence).
										***** (* newBlockEntryAddr <> sh1entryaddr *)
													assert(Hsh1entryaddrEq : lookup sh1entryaddr (memory s) beqAddr = lookup sh1entryaddr (memory s0) beqAddr).
													{
														rewrite Hs. cbn.
														rewrite beqAddrTrue.
														rewrite beqscesh1.
														assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
														rewrite HnewBsceNotEq. (*newBlock <> sce *)
														assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
														rewrite HpdnewBNotEq. (*pd <> newblock*)
														rewrite beqAddrTrue.
														cbn.
														rewrite beqnewsh1.
														assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
														rewrite HpdnewNotEq. (*pd <> newblock*)
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity; intuition.
														cbn.
														destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hff ;try (exfalso;congruence).
														rewrite DependentTypeLemmas.beqAddrTrue in *. congruence.
														repeat rewrite removeDupIdentity; intuition.
													}
													rewrite Hsh1entryaddrEq.
													unfold isSHE in Hsh1s0.
													destruct (lookup sh1entryaddr (memory s0) beqAddr) eqn:Hlookupsh1 ; try(exfalso ; congruence).
													destruct v0  ; try (exfalso ; congruence).

													assert(HSHEsh1s0 : isSHE sh1entryaddr s0).
													{ unfold isSHE. rewrite Hlookupsh1. trivial. }

													assert(Hsh1entryaddrs0 : sh1entryAddr block sh1entryaddr s0).
													{
														unfold sh1entryAddr.
														unfold isBE in HBEblocks0.
														destruct (lookup block (memory s0) beqAddr) ; try(exfalso ; congruence).
														destruct v0 ; try(exfalso ; congruence).
														assumption.
													}

													unfold AccessibleNoPDFlag in *.
													specialize(Hcons0 block sh1entryaddr HBEblocks0 Hsh1entryaddrs0).
													unfold sh1entryPDflag in *.
													rewrite Hlookupsh1 in *.

													(* either block is newB then it's PDflag was false at s0 and didn't change,
															else A flag didn't change so is still true*)

													destruct (beqAddr newBlockEntryAddr block) eqn:beqnewblock; try(exfalso ; congruence).
													****** (* newBlockEntryAddr = block *)
																	rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblock.
																	rewrite <- beqnewblock in *.
																	rewrite HlookupnewBs0 in *.
																	(* PDflag was false at s0 *)
																	assert(HfreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot s0)
																									by (unfold consistency in * ; unfold consistency1 in *; intuition).
																	unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
																	apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
																	assert(HfreeSlots0 : pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0)
																		 by intuition.
																	specialize (HfreeSlot pdinsertion pds0 HPDTs0).
																	unfold pdentryFirstFreeSlot in HfreeSlots0.
																	rewrite HPDTs0 in HfreeSlots0.
																	rewrite <- HfreeSlots0 in *.
																	destruct HfreeSlot as [HnewBisBE HnewBisfreeSlot]. intuition.
																	unfold isFreeSlot in HnewBisfreeSlot.
																	rewrite HlookupnewBs0 in HnewBisfreeSlot.
																	rewrite <- Hsh1entryAddr in *.
																	rewrite Hlookupsh1 in *.
																	rewrite <- Hscentryaddr in HnewBisfreeSlot.
																	apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [scentrys0 HSCEs0].
																	rewrite HSCEs0 in HnewBisfreeSlot.
																	intuition.
													****** (* newBlockEntryAddr <> block *)
																destruct Hcons0 ; trivial.

																unfold bentryAFlag in *.
																assert(HblockEq : lookup block (memory s) beqAddr = lookup block (memory s0) beqAddr).
																{
																	rewrite Hs. cbn.
																	rewrite beqAddrTrue.
																	rewrite beqsceblock.
																	assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
																	rewrite HnewBsceNotEq. (*newBlock <> sce *)
																	assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
																	rewrite HpdnewBNotEq. (*pd <> newblock*)
																	rewrite beqAddrTrue.
																	cbn.
																	rewrite beqnewblock.
																	assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
																	rewrite HpdnewNotEq. (*pd <> newblock*)
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity; intuition.
																	cbn.
																	destruct (beqAddr pdinsertion block) eqn:Hff ;try (exfalso;congruence).
																	rewrite DependentTypeLemmas.beqAddrTrue in *. congruence.
																	repeat rewrite removeDupIdentity; intuition.
																}
																rewrite <- HblockEq.
																destruct (lookup block (memory s) beqAddr) ; try(exfalso ; congruence).
																destruct v0 ; try(exfalso ; congruence).
																assumption.
		} (* end of AccessibleNoPDFlag *)

	(* Prove outside in order to use the proven properties to prove other ones *)
	assert(HFirstFreeIsBEAndFreeSlots : FirstFreeSlotPointerIsBEAndFreeSlot s).
	{ (* FirstFreeSlotPointerIsBEAndFreeSlot s *)
		assert(Hcons0 : FirstFreeSlotPointerIsBEAndFreeSlot s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold FirstFreeSlotPointerIsBEAndFreeSlot in Hcons0.

		unfold FirstFreeSlotPointerIsBEAndFreeSlot.
		intros entryaddrpd entrypd Hentrypd Hfirstfreeslotentrypd.

		(* check all possible values for entryaddrpd in the modified state s
				-> only possible is pdinsertion
			1) if entryaddrpd == pdinsertion :
					- newBlockEntryAddr was firstfreeslot at s0 and newFirstFreeSlotAddr is
						the new firstfreeslot at s
					- check all possible values for (firstfree pdinsertion) in the modified state s
							1.1) only possible is newblockEntryAddr but it can't be a
									FreeSlot because :
									we know newFirstFreeSlotAddr = endAddr newBlockEntryAddr
									1.1.1) BUT if newFirstFreeSlotAddr = newBlockEntryAddr
													-> newBlockEntryAddr = endAddr newBlockEntryAddr
													-> cycles in the free slots list -> impossible by consistency
									1.1.1.2)	newFirstFreeSlotAddr s = newFirstFreeSlot s0
													-> leads to s0 and isBE and isFreeSlot at s0 -> OK
			2) if entryaddrpd <> pdinsertion :
					- newBlockEntryAddr and newFirstFreeSlotAddr do not relate to entryaddrpd
							(firstfree pdinsertion <> firstfree entryaddrpd)
							-> newBlockEntryAddr <> (firstfree entryaddrpd) and
									newFirstFreeSlotAddr <> (firstfree entryaddrpd)
						since all the free slots list must be disjoint by consistency
					- check all possible values for (firstfreeslot entrypd) in the modified state s
							-> nothing possible -> leads to s0 because -> OK
*)
		(* Check all values except pdinsertion *)
		destruct (beqAddr sceaddr entryaddrpd) eqn:beqsceentry; try(exfalso ; congruence).
		-	(* sceaddr = entryaddrpd *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceentry.
			rewrite <- beqsceentry in *.
			unfold isSCE in *.
			rewrite Hentrypd in *.
			exfalso ; congruence.
		-	(* sceaddr <> entryaddrpd *)
			destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:beqnewblockentry; try(exfalso ; congruence).
			-- (* newBlockEntryAddr = entryaddrpd *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockentry.
					rewrite <- beqnewblockentry in *.
					unfold isBE in *.
					rewrite Hentrypd in *.
					exfalso ; congruence.
			-- (* newBlockEntryAddr <> entryaddrpd *)
					destruct (beqAddr pdinsertion entryaddrpd) eqn:beqpdentry; try(exfalso ; congruence).
					--- (* pdinsertion = entryaddrpd *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdentry.
							rewrite <- beqpdentry in *.
							specialize (Hcons0 pdinsertion pdentry Hpdinsertions0).
							destruct Hcons0 as [HRR HHH].
							* unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *.
							unfold bentryEndAddr in *. rewrite HlookupnewBs0 in *.
							congruence.
							* (* rewrite (firstfreeslot pdentry at s0) = newBlockEntryAddr *)
								assert(HnewFirstFrees0 : firstfreeslot pdentry = newBlockEntryAddr).
								{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
								assert(HnewFirstEq : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
									by intuition.
								rewrite HnewFirstFrees0 in *.
								unfold bentryEndAddr in HnewFirstEq. rewrite HlookupnewBs0 in *.
								(* develop free slots list s0 *)
								assert(Hpdeq : entrypd = pdentry1).
								{ rewrite Hpdinsertions in *.
									injection Hentrypd. intuition. }
								rewrite Hpdeq in *.
								rewrite HnewFirstFree in *.
								assert(HbentryEndAddrNewFirst : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
									by intuition.
								assert(HNewFirstFreeSlots0 : isFreeSlot newFirstFreeSlotAddr s0).
								{ assert(HfreeSlotsListIsFreeSlot : freeSlotsListIsFreeSlot s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold freeSlotsListIsFreeSlot in *.
									(* extract freeslotslist *)
									assert(HNoDupInFreeSlotsList : NoDupInFreeSlotsList s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold NoDupInFreeSlotsList in *.
									specialize(HNoDupInFreeSlotsList pdinsertion pdentry Hpdinsertions0).
									destruct HNoDupInFreeSlotsList as [Hoptionfreeslotslists0 (HfreeSlotsLists0 & Hwellformeds0 & HNoDups0)].
									specialize (HfreeSlotsListIsFreeSlot pdinsertion newFirstFreeSlotAddr Hoptionfreeslotslists0 (filterOptionPaddr Hoptionfreeslotslists0) HPDTs0).
									apply HfreeSlotsListIsFreeSlot ; intuition.
									(* unroll free slots list to find newFirstFreeSlotAddr *)
									subst Hoptionfreeslotslists0.
									unfold getFreeSlotsList in *. rewrite Hpdinsertions0 in *.
									rewrite HnewFirstFrees0 in *.
									destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf.
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									rewrite FreeSlotsListRec_unroll in *.
									unfold getFreeSlotsListAux in *.
									assert(Hiter1 : maxIdx +1 = S maxIdx). apply PeanoNat.Nat.add_1_r.
									rewrite Hiter1 in *.
									assert(Hnbfreeslots : (nbfreeslots pdentry) = currnbfreeslots).
									{ unfold pdentryNbFreeSlots in*. rewrite Hpdinsertions0 in *. intuition. }
									rewrite Hnbfreeslots in *. rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hfff ; try (cbn in * ; congruence).
									destruct (StateLib.Index.pred currnbfreeslots) eqn:Hffff ; try (exfalso ; congruence).
									unfold bentryEndAddr in * . rewrite HlookupnewBs0 in *.
									rewrite <- HbentryEndAddrNewFirst.
									rewrite FreeSlotsListRec_unroll in *.
									unfold getFreeSlotsListAux in *.
									assert(Hiter2 : maxIdx = S (maxIdx - 1)).
									{ assert(HEq : S (maxIdx - 1) = S maxIdx -1).
										{ apply Minus.minus_Sn_m. apply PeanoNat.Nat.lt_le_incl.
											apply maxIdxBigEnough.
										}
										rewrite HEq. lia.
									}
									rewrite Hiter2 in *.
									destruct (StateLib.Index.ltb i zero) ; try (cbn in * ; congruence).
									rewrite <- HbentryEndAddrNewFirst in *.
									destruct (lookup newFirstFreeSlotAddr (memory s0) beqAddr) eqn:Hlookupnewfirst ; try(exfalso ; cbn in * ; congruence).
									destruct v eqn:Hv ; try(exfalso ; cbn in * ; congruence).
									destruct (StateLib.Index.pred i) eqn:Hpred ; try(exfalso ; cbn in * ; congruence).
									cbn. intuition.
									destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:HnewFirstNull ; try(exfalso ; cbn in * ; congruence).
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *. unfold isPADDR in *.
									rewrite <- DependentTypeLemmas.beqAddrTrue in HnewFirstNull.
									rewrite HnewFirstNull in *.
									rewrite Hlookupnewfirst in *. exfalso ; congruence.
								}
								destruct (beqAddr sceaddr newFirstFreeSlotAddr) eqn:beqscefirstfree; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefirstfree.
						---- (* sceaddr = newFirstFreeSlotAddr *)
									rewrite <- beqscefirstfree in *.
									apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [Hsceaddr Hscelookup].
									unfold isFreeSlot in HNewFirstFreeSlots0.
									rewrite Hscelookup in *. exfalso ; congruence.
						---- (* sceaddr <> newFirstFreeSlotAddr *)
							destruct (beqAddr pdinsertion newFirstFreeSlotAddr) eqn:beqpdfirstfree; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfree.
							-----	(* pdinsertion = newFirstFreeSlotAddr *)
									rewrite beqpdfirstfree in *.
									unfold isFreeSlot in HNewFirstFreeSlots0.
									rewrite Hpdinsertions0 in *. exfalso ; congruence.
							----- (* pdinsertion <> newFirstFreeSlotAddr *)
										(* remaining is newBlockEntryAddr -> use noDup*)
										destruct (beqAddr newBlockEntryAddr newFirstFreeSlotAddr) eqn:beqnewfirstfree; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfree.
										------ (* newBlockEntryAddr = newFirstFreeSlotAddr *)
														congruence.
									------ (* newBlockEntryAddr <> newFirstFreeSlotAddr *)
													assert(HfirstfreeEq : lookup newFirstFreeSlotAddr (memory s) beqAddr = lookup newFirstFreeSlotAddr (memory s0) beqAddr).
													{
														rewrite Hs.
														rewrite <- beqAddrFalse in *.
														cbn.
														rewrite beqAddrTrue.
														destruct (beqAddr sceaddr newFirstFreeSlotAddr) eqn:Hf; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
														(* sceaddr <> newFirstFreeSlotAddr *)
														destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
														cbn. rewrite beqAddrTrue.
														destruct (beqAddr newBlockEntryAddr newFirstFreeSlotAddr) eqn:Hfff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
														cbn.
														destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity; intuition.
														cbn.
														destruct (beqAddr pdinsertion newFirstFreeSlotAddr) eqn:Hfffff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
														repeat rewrite removeDupIdentity; intuition.
													}
													split.
													** (* isBE *)
														unfold isBE. rewrite HfirstfreeEq.
														unfold isFreeSlot in HNewFirstFreeSlots0.
														destruct (lookup newFirstFreeSlotAddr (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
														destruct v eqn:Hv ; try(exfalso ; congruence).
														trivial.
													** (* isFreeSlot *)
															unfold isFreeSlot. rewrite HfirstfreeEq.
															unfold isFreeSlot in HNewFirstFreeSlots0.
															destruct (lookup newFirstFreeSlotAddr (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
															destruct v eqn:Hv ; try(exfalso ; congruence).

															assert(HnewFirstFreeSh1 : lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s) beqAddr = lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s0) beqAddr).
															{ rewrite Hs.
																cbn. rewrite beqAddrTrue.
																destruct (beqAddr sceaddr (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqscenewsh1 ; try(exfalso ; congruence).
																- (* sce = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																	rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsh1.
																	rewrite <- beqscenewsh1 in *.
																	unfold isSCE in *.
																	destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																	destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																- (* sce <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																	destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																	cbn.
																	destruct (beqAddr newBlockEntryAddr (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqnewfirstfreesh1 ; try(exfalso ; congruence).
																	-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesh1.
																		rewrite <- beqnewfirstfreesh1 in *.
																		unfold isBE in *.
																		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																		destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																	-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																			cbn.
																			rewrite <- beqAddrFalse in *.
																			repeat rewrite removeDupIdentity; intuition.
																			cbn.
																			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																			repeat rewrite removeDupIdentity; intuition.
																			cbn.
																			destruct (beqAddr pdinsertion (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqpdfirstfreesh1 ; try(exfalso ; congruence).
																			--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesh1.
																					rewrite <- beqpdfirstfreesh1 in *.
																					unfold isPDT in *.
																					destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																					destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																			--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					cbn. rewrite beqAddrTrue.
																					rewrite <- beqAddrFalse in *.
																					repeat rewrite removeDupIdentity; intuition.
																	}
																	rewrite HnewFirstFreeSh1.
																	destruct (lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s0) beqAddr) eqn:Hlookupfirstsh1 ; try(exfalso ; congruence).
																	destruct v0 eqn:Hv0 ; try(exfalso ; congruence).

																	assert(HnewFirstFreeSCE : lookup (CPaddr (newFirstFreeSlotAddr + scoffset)) (memory s) beqAddr = lookup (CPaddr (newFirstFreeSlotAddr + scoffset)) (memory s0) beqAddr).
																	{ rewrite Hs.
																		cbn. rewrite beqAddrTrue.
																		destruct (beqAddr sceaddr (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqscenewsc ; try(exfalso ; congruence).
																		- (* sce = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																			(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
																			rewrite <- beqscenewsc in *.
																			unfold isFreeSlot in HHH.
																			rewrite Hscentryaddr in *.
																			assert(HnullAddrExistss0 : nullAddrExists s0)
																					by (unfold consistency in * ; unfold consistency1 in *; intuition).
																			unfold nullAddrExists in *. unfold isPADDR in *.
																			unfold CPaddr in beqscenewsc.
																			destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
																			* destruct (le_dec (newFirstFreeSlotAddr + scoffset) maxAddr) eqn:Hk.
																				** simpl in *.
																					inversion beqscenewsc as [Heq].
																					rewrite PeanoNat.Nat.add_cancel_r in Heq.
																					rewrite <- beqAddrFalse in beqnewfirstfree.
																					apply CPaddrInjectionNat in Heq.
																					repeat rewrite paddrEqId in Heq.
																					congruence.
																				** inversion beqscenewsc as [Heq].
																					rewrite Heq in *.
																					rewrite <- nullAddrIs0 in *.
																					rewrite <- beqAddrFalse in *. (* newBlockEntryAddr <> nullAddr *)
																					destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																					destruct v1 ; try(exfalso ; congruence).
																			* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																				{ rewrite nullAddrIs0.
																					unfold CPaddr. rewrite Hj.
																					destruct (le_dec 0 maxAddr) ; intuition.
																					f_equal. apply proof_irrelevance.
																				}
																				rewrite Heq in *.
																				destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																				destruct v1 ; try(exfalso ; congruence).
																 	- (* sce <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																		cbn.
																		destruct (beqAddr newBlockEntryAddr (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqnewfirstfreesc ; try(exfalso ; congruence).
																		-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesc.
																			rewrite <- beqnewfirstfreesc in *.
																			unfold isBE in *.
																			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																			destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																		-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																				cbn.
																				rewrite <- beqAddrFalse in *.
																				repeat rewrite removeDupIdentity; intuition.
																				cbn.
																				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																				repeat rewrite removeDupIdentity; intuition.
																				cbn.
																				destruct (beqAddr pdinsertion (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqpdfirstfreesc ; try(exfalso ; congruence).
																				--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesc.
																						rewrite <- beqpdfirstfreesc in *.
																						unfold isPDT in *.
																						destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																						destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																				--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						cbn. rewrite beqAddrTrue.
																						rewrite <- beqAddrFalse in *.
																						repeat rewrite removeDupIdentity; intuition.
																}
																rewrite HnewFirstFreeSCE.
																destruct (lookup (CPaddr (newFirstFreeSlotAddr + scoffset))
																		      (memory s0) beqAddr) eqn:Hlookupfirstsc ; try(exfalso ; congruence).
																destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																intuition.
							--- (* pdinsertion <> entryaddrpd *)
									assert(HlookupEq : lookup entryaddrpd (memory s) beqAddr = lookup entryaddrpd (memory s0) beqAddr).
									{ rewrite Hs.
										cbn. rewrite beqAddrTrue.
										destruct (beqAddr sceaddr entryaddrpd) eqn:beqsceentrypd ; try(exfalso ; congruence).
										destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
										cbn.
										destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:beqnewentrypd ; try(exfalso ; congruence).
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock ; try(exfalso ; congruence).
										rewrite <- beqAddrFalse in *.
										rewrite beqAddrTrue.
										repeat rewrite removeDupIdentity ; intuition.
										cbn.
										destruct (beqAddr pdinsertion entryaddrpd) eqn:beqpdentrypd ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdentrypd.
										rewrite <- beqpdentrypd in *.
										congruence.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(Hentrypds0 : lookup entryaddrpd (memory s0) beqAddr = Some (PDT entrypd)).
									{ rewrite <- HlookupEq. intuition. }
									specialize (Hcons0 entryaddrpd entrypd Hentrypds0 Hfirstfreeslotentrypd).
									assert(HnewFirstEq : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
										by intuition.
									unfold bentryEndAddr in HnewFirstEq. rewrite HlookupnewBs0 in *.
									destruct (beqAddr sceaddr (firstfreeslot entrypd)) eqn:beqscefirstfree; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefirstfree.
									---- (* sceaddr = firstfreeslot entrypd *)
												rewrite <- beqscefirstfree in *.
												apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [Hsceaddr Hscelookup].
												unfold isBE in Hcons0. rewrite Hscelookup in *.
												intuition.
									---- (* sceaddr <> firstfreeslot entrypd *)
										destruct (beqAddr pdinsertion (firstfreeslot entrypd)) eqn:beqpdfirstfree; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfree.
										-----	(* pdinsertion = firstfreeslot entrypd *)
												rewrite beqpdfirstfree in *.
												unfold isBE in Hcons0.
												apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [Hpdaddr Hpdlookup].
												rewrite Hpdlookup in *.
												intuition.
										----- (* pdinsertion <> firstfreeslot entrypd *)
													(* remaining is newBlockEntryAddr -> use Disjoint *)
													destruct (beqAddr newBlockEntryAddr (firstfreeslot entrypd)) eqn:beqnewfirstfree; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfree.
													------ (* newBlockEntryAddr = firstfreeslot entrypd *)
															(* Case : other pdentry but firstfreeslot points to newBlockEntryAddr anyways -> impossible *)
															assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
																by (unfold consistency in * ; unfold consistency1 in *; intuition).
															unfold DisjointFreeSlotsLists in *.
															assert(HPDTentrypds0 : isPDT entryaddrpd s0).
															{ unfold isPDT. rewrite Hentrypds0. trivial. }
															rewrite <- beqAddrFalse in beqpdentry.
															pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion entryaddrpd HPDTs0 HPDTentrypds0 beqpdentry).
															destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
															destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
															unfold getFreeSlotsList in Hlistoption1.
															unfold getFreeSlotsList in Hlistoption2.
															rewrite Hpdinsertions0 in *.
															rewrite Hentrypds0 in *.
															rewrite <- beqnewfirstfree in *.
															assert(HnewFirstFrees0 : firstfreeslot pdentry = newBlockEntryAddr).
															{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
			 													rewrite HnewFirstFrees0 in *.
																rewrite FreeSlotsListRec_unroll in Hlistoption1.
																rewrite FreeSlotsListRec_unroll in Hlistoption2.
																unfold getFreeSlotsListAux in *.
																rewrite HlookupnewBs0 in *. rewrite <- HnewFirstEq in *.
																rewrite beqAddrFalse in Hfirstfreeslotentrypd.
															assert(Hnbfreeslotss0 : nbfreeslots pdentry = currnbfreeslots).
															{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
																induction (maxIdx+1). (* false induction because of fixpoint constraints *)
																** (* N=0 -> NotWellFormed *)
																	rewrite Hlistoption1 in *.
																	destruct(beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
																	cbn in HwellFormedList1.
																	congruence.
																** (* N>0 *)
																	clear IHn.
																	destruct(beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
																	cbn in *.
																	destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
																	destruct (StateLib.Index.pred (nbfreeslots entrypd)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
																	destruct (PeanoNat.Nat.eqb newFirstFreeSlotAddr nullAddr) eqn:newIsNull.
																	*** subst listoption1.
																			cbn in HwellFormedList1.
																			cbn in HwellFormedList2.
																			cbn in H_Disjoints0.
																			unfold Lib.disjoint in H_Disjoints0.
																			specialize(H_Disjoints0 newBlockEntryAddr).
																			simpl in H_Disjoints0.
																			intuition.
																	*** subst listoption1.
																			cbn in HwellFormedList1.
																			cbn in HwellFormedList2.
																			cbn in H_Disjoints0.
																			unfold Lib.disjoint in H_Disjoints0.
																			specialize(H_Disjoints0 newBlockEntryAddr).
																			simpl in H_Disjoints0.
																			intuition.
												------ (* newBlockEntryAddr <> firstfreeslot entrypd *)
																assert(HfirstfreeEq : lookup (firstfreeslot entrypd) (memory s) beqAddr = lookup (firstfreeslot entrypd) (memory s0) beqAddr).
																{
																	rewrite Hs. cbn. rewrite beqAddrTrue.
																	destruct (beqAddr sceaddr (firstfreeslot entrypd)) eqn:scefirst ; try(exfalso ; congruence).
																	destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
																	rewrite beqAddrTrue.
																	cbn.
																	destruct (beqAddr newBlockEntryAddr (firstfreeslot entrypd)) eqn:newfirst ; try(exfalso ; congruence).
																	destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
																	cbn.
																	destruct (beqAddr pdinsertion (firstfreeslot entrypd)) eqn:pdfirst ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in pdfirst.
																	congruence.
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
																}
																split.
																** (* isBE *)
																	unfold isBE. rewrite HfirstfreeEq. intuition.
																** (* isFreeSlot *)
																		unfold isFreeSlot. rewrite HfirstfreeEq.
																		unfold isFreeSlot in Hcons0. destruct Hcons0.
																		destruct (lookup (firstfreeslot entrypd) (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
																		destruct v eqn:Hv ; try(exfalso ; congruence).
																		(* DUP *)
																		assert(HnewFirstFreeSh1 : lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s) beqAddr = lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s0) beqAddr).
																		{ rewrite Hs.
																			cbn. rewrite beqAddrTrue.
																			destruct (beqAddr sceaddr (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqscenewsh1 ; try(exfalso ; congruence).
																			- (* sce = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																				rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsh1.
																				rewrite <- beqscenewsh1 in *.
																				unfold isSCE in *.
																				destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																				destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																			- (* sce <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																				cbn.
																				destruct (beqAddr newBlockEntryAddr (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqnewfirstfreesh1 ; try(exfalso ; congruence).
																				-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesh1.
																					rewrite <- beqnewfirstfreesh1 in *.
																					unfold isBE in *.
																					destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																					destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																				-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																						cbn.
																						rewrite <- beqAddrFalse in *.
																						repeat rewrite removeDupIdentity; intuition.
																						cbn.
																						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																						rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																						repeat rewrite removeDupIdentity; intuition.
																						cbn.
																						destruct (beqAddr pdinsertion (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqpdfirstfreesh1 ; try(exfalso ; congruence).
																						--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesh1.
																								rewrite <- beqpdfirstfreesh1 in *.
																								unfold isPDT in *.
																								destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																								destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																						--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																								cbn. rewrite beqAddrTrue.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																				}
																				rewrite HnewFirstFreeSh1.
																				destruct (lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s0) beqAddr) eqn:Hlookupfirstsh1 ; try(exfalso ; congruence).
																				destruct v0 eqn:Hv0 ; try(exfalso ; congruence).

																				assert(HnewFirstFreeSCE : lookup (CPaddr (firstfreeslot entrypd + scoffset)) (memory s) beqAddr = lookup (CPaddr (firstfreeslot entrypd + scoffset)) (memory s0) beqAddr).
																				{ rewrite Hs.
																					cbn. rewrite beqAddrTrue.
																					destruct (beqAddr sceaddr (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqscenewsc ; try(exfalso ; congruence).
																					- (* sce = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
																						rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
																						rewrite <- beqscenewsc in *.
																						rewrite Hscentryaddr in *.
																						assert(HnullAddrExistss0 : nullAddrExists s0)
																								by (unfold consistency in * ; unfold consistency1 in *; intuition).
																						unfold nullAddrExists in *. unfold isPADDR in *.
																						unfold CPaddr in beqscenewsc.
																						destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
																						* destruct (le_dec (firstfreeslot entrypd + scoffset) maxAddr) eqn:Hk.
																							** simpl in *.
																								inversion beqscenewsc as [Heq].
																								rewrite PeanoNat.Nat.add_cancel_r in Heq.
																								rewrite <- beqAddrFalse in beqnewfirstfree.
																								apply CPaddrInjectionNat in Heq.
																								repeat rewrite paddrEqId in Heq.
																								congruence.
																							** inversion beqscenewsc as [Heq].
																									rewrite Heq in *.
																									rewrite <- nullAddrIs0 in *.
																									rewrite <- beqAddrFalse in *. (* newBlockEntryAddr <> nullAddr *)
																								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																								destruct v1 ; try(exfalso ; congruence).
																						* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																							{ rewrite nullAddrIs0.
																								unfold CPaddr. rewrite Hj.
																								destruct (le_dec 0 maxAddr) ; intuition.
																								f_equal. apply proof_irrelevance.
																							}
																							rewrite Heq in *.
																							destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																							destruct v1 ; try(exfalso ; congruence).
																			 	- (* sce <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																						cbn.
																						destruct (beqAddr newBlockEntryAddr (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqnewfirstfreesc ; try(exfalso ; congruence).
																						-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesc.
																							rewrite <- beqnewfirstfreesc in *.
																							unfold isBE in *.
																							destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																							destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																						-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																								cbn.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																								cbn.
																								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																								repeat rewrite removeDupIdentity; intuition.
																								cbn.
																								destruct (beqAddr pdinsertion (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqpdfirstfreesc ; try(exfalso ; congruence).
																								--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesc.
																										rewrite <- beqpdfirstfreesc in *.
																										unfold isPDT in *.
																										destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																										destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																								--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																										cbn. rewrite beqAddrTrue.
																										rewrite <- beqAddrFalse in *.
																										repeat rewrite removeDupIdentity; intuition.
																			}
																			rewrite HnewFirstFreeSCE.
																			destruct (lookup (CPaddr (firstfreeslot entrypd + scoffset))
																								(memory s0) beqAddr) eqn:Hlookupfirstsc ; try(exfalso ; congruence).
																			destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																			intuition.
} (* end of FirstFreeSlotPointerIsBEAndFreeSlot *)

	assert(HcurrentPartitionInPartitionsLists : currentPartitionInPartitionsList s).
	{ (* currentPartitionInPartitionsList s *)
		assert(Hcons0 : currentPartitionInPartitionsList s0)
			by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold currentPartitionInPartitionsList in Hcons0.

		unfold currentPartitionInPartitionsList.
		assert(HcurrPartEq : currentPartition s = currentPartition s0).
		{
			rewrite Hs. simpl. trivial.
		}
		rewrite HcurrPartEq in *.
		assert(HparentEq : (getPartitions multiplexer s) = (getPartitions multiplexer s0))
			by admit. (* list equalities *)
		rewrite HparentEq.
		assumption.
	} (* end of currentPartitionInPartitionsList *)

assert(HwellFormedShadowCutIfBlockEntry : wellFormedShadowCutIfBlockEntry s).
{ (* wellFormedShadowCutIfBlockEntry s*)
	(* Almost DUP of wellFormedFstShadowIfBlockEntry *)
	unfold wellFormedShadowCutIfBlockEntry.
	intros pa HBEaddrs.

	(* Check all possible values for pa
			-> only possible is newBlockEntryAddr
			2) if pa == newBlockEntryAddr :
					-> exists scentryaddr in modified state -> OK
			3) if pa <> newBlockEntryAddr :
					- relates to another bentry than newBlockentryAddr
						that was not modified
						(either in the same structure or another)
					- pa + scoffset either is
								- scentryaddr -> newBlockEntryAddr = pa -> contradiction
								- some other entry -> leads to s0 -> OK
	*)

	(* 1) isBE pa s in hypothesis: eliminate impossible values for pa *)
	destruct (beqAddr pdinsertion pa) eqn:beqpdpa in HBEaddrs ; try(exfalso ; congruence).
	* (* pdinsertion = pa *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpa.
		rewrite <- beqpdpa in *.
		unfold isPDT in *. unfold isBE in *. rewrite H in *.
		exfalso ; congruence.
	* (* pdinsertion <> pa *)
		destruct (beqAddr sceaddr pa) eqn:beqpasce in HBEaddrs ; try(exfalso ; congruence).
		** (* sceaddr = pa *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpasce.
				rewrite <- beqpasce in *.
				unfold isSCE in *. unfold isBE in *.
				destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		** (* sceaddr <> pa *)
						destruct (beqAddr newBlockEntryAddr pa) eqn:beqnewblockpa in HBEaddrs ; try(exfalso ; congruence).
						*** 	(* 2) treat special case where newBlockEntryAddr = pa *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockpa.
									rewrite <- beqnewblockpa in *.
									exists sceaddr. intuition.
						*** (* Partial DUP of FirstFreeSlotPointerIsBEAndFreeSlot *)
									(* 3) treat special case where pa is not equal to any modified entries*)
									(* newBlockEntryAddr <> pa *)
									(* eliminate impossible values for (CPaddr (pa + scoffset)) *)
										destruct (beqAddr sceaddr (CPaddr (pa + scoffset))) eqn:beqscenewsc.
										 - 	(* sceaddr = (CPaddr (pa + scoffset)) *)
												(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
												rewrite <- beqscenewsc in *.
												rewrite Hscentryaddr in *.
												assert(HnullAddrExistss0 : nullAddrExists s0)
														by (unfold consistency in * ; unfold consistency1 in *; intuition).
												unfold nullAddrExists in *. unfold isPADDR in *.
												unfold CPaddr in beqscenewsc.
												destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
												-- destruct (le_dec (pa + scoffset) maxAddr) eqn:Hk.
													--- simpl in *.
															inversion beqscenewsc as [Heq].
															rewrite PeanoNat.Nat.add_cancel_r in Heq.
															rewrite <- beqAddrFalse in beqnewblockpa.
															apply CPaddrInjectionNat in Heq.
															repeat rewrite paddrEqId in Heq.
															congruence.
													--- inversion beqscenewsc as [Heq].
															rewrite Heq in *.
															rewrite <- nullAddrIs0 in *.
															rewrite <- beqAddrFalse in *. (* newBlockEntryAddr <> nullAddr *)
															apply CPaddrInjectionNat in Heq.
															repeat rewrite paddrEqId in Heq.
															rewrite <- nullAddrIs0 in Heq.
															unfold isSCE in *.
															destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
															destruct v ; try(exfalso ; congruence).
											--  assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
													{ rewrite nullAddrIs0.
														unfold CPaddr. rewrite Hj.
														destruct (le_dec 0 maxAddr) ; intuition.
														f_equal. apply proof_irrelevance.
													}
													rewrite Heq in *.
													unfold isSCE in *.
													destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v ; try(exfalso ; congruence).
									 - (* sce <> (CPaddr (pa + scoffset)) *)
											(* leads to s0 *)
											assert(Hcons0 : wellFormedShadowCutIfBlockEntry s0)
													by (unfold consistency in * ; unfold consistency1 in *; intuition).
											unfold wellFormedShadowCutIfBlockEntry in *.
											assert(HBEeq : isBE pa s = isBE pa s0).
											{
												unfold isBE.
												rewrite Hs. cbn.
												rewrite beqAddrTrue.
												rewrite beqpasce.
												assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
												rewrite HnewBsceNotEq. (*newBlock <> sce *)
												assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
												rewrite HpdnewBNotEq. (*pd <> newblock*)
												cbn in HBEaddrs. rewrite beqAddrTrue. cbn.
												rewrite beqnewblockpa. rewrite HpdnewBNotEq.
												rewrite <- beqAddrFalse in *.
												repeat rewrite removeDupIdentity; intuition.
												cbn.
												destruct (beqAddr pdinsertion pa) eqn:Hf ; try (exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
												repeat rewrite removeDupIdentity; intuition.
											}
											assert(HBEaddrs0 : isBE pa s0).
											{ rewrite <- HBEeq. assumption. }
											specialize(Hcons0 pa HBEaddrs0).
											destruct Hcons0 as [scentryaddr (HSCEs0' & Hsceq)].
											(* almost DUP with previous step *)
											destruct (beqAddr newBlockEntryAddr (CPaddr (pa + scoffset))) eqn:newblockscoffset.
											-- (* newBlockEntryAddr = (CPaddr (pa + scoffset))*)
												rewrite <- DependentTypeLemmas.beqAddrTrue in newblockscoffset.
												rewrite <- newblockscoffset in *.
												unfold isSCE in *. unfold isBE in *.
												rewrite Hsceq in *.
												destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
												destruct v ; try (exfalso ; congruence).
											-- (* newBlockEntryAddr <> (CPaddr (pa + sh1offset))*)
												destruct (beqAddr pdinsertion (CPaddr (pa + scoffset))) eqn:pdscoffset.
												--- (* pdinsertion = (CPaddr (pa + sh1offset))*)
													rewrite <- DependentTypeLemmas.beqAddrTrue in *.
													rewrite <- pdscoffset in *.
													unfold isSCE in *. unfold isPDT in *.
													rewrite Hsceq in *.
													destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
													destruct v eqn:Hv ; try(exfalso ; congruence).
												--- (* pdinsertion <> (CPaddr (pa + sh1offset))*)
													(* resolve the only true case *)
													exists scentryaddr. intuition.
													assert(HSCEeq : isSCE scentryaddr s = isSCE scentryaddr s0).
													{
														unfold isSCE.
														rewrite Hs.
														cbn. rewrite beqAddrTrue.
														rewrite <- Hsceq in *. rewrite beqscenewsc.
														assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
														rewrite HnewBsceNotEq. (*newBlock <> sce *)
														assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
														rewrite HpdnewBNotEq. (*pd <> newblock*)
														cbn.
														rewrite newblockscoffset.
														cbn.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity ; intuition.
														rewrite beqAddrTrue.
														destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
														cbn.
														destruct (beqAddr pdinsertion scentryaddr) eqn:Hff ; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity ; intuition.
													}
													rewrite HSCEeq. assumption.
} (* end of wellFormedShadowCutIfBlockEntry *)

assert(HBlocksRangeFromKernelStartIsBEs : BlocksRangeFromKernelStartIsBE s).
{ (* BlocksRangeFromKernelStartIsBE s*)
	unfold BlocksRangeFromKernelStartIsBE.
	intros kernelentryaddr blockidx HKSs Hblockidx.

	assert(Hcons0 : BlocksRangeFromKernelStartIsBE s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold BlocksRangeFromKernelStartIsBE in Hcons0.

	(* check all possible values for bentryaddr in the modified state s
	-> only possible is newBlockEntryAddr
	1) if bentryaddr == newBlockEntryAddr :
		- show CPaddr (bentryaddr + blockidx) didn't change
		- = newBlock -> when blockidx = 0 for example
			-> so isBE at s -> OK
		- <> newBlock
			- CPaddr (bentryaddr + blockidx)
				- = newBlock -> isBE -> OK
				- <> newBlock -> not modified -> leads to s0 in another structure -> OK
	2) if bentryaddr <> newBlockEntryAddr :
		- relates to another bentry than newBlockentryAddr
		(either in the same structure or another)
		- CPaddr (bentryaddr + blockidx)
			- = newBlock -> isBE -> OK
			- <> newBlock -> not modified -> leads to s0 in another structure -> OK
	*)

	(* Check all values except newBlockEntryAddr *)
	destruct (beqAddr sceaddr kernelentryaddr) eqn:beqscebentry; try(exfalso ; congruence).
	- (* sceaddr = kernelentryaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebentry.
		rewrite <- beqscebentry in *.
		unfold isSCE in *.
		unfold isKS in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	- (* sceaddr <> kernelentryaddr *)
		destruct (beqAddr pdinsertion kernelentryaddr) eqn:beqpdbentry; try(exfalso ; congruence).
		-- (* pdinsertion = kernelentryaddr *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdbentry.
				rewrite <- beqpdbentry in *.
				unfold isPDT in *.
				unfold isKS in *.
				destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> kernelentryaddr *)
				destruct (beqAddr newBlockEntryAddr kernelentryaddr) eqn:newbentry ; try(exfalso ; congruence).
				--- (* 1) newBlockEntryAddr = bentryaddr *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in newbentry.
						rewrite <- newbentry in *.
						destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr + blockidx))) eqn:newidx ; try(exfalso ; congruence).
						+++ (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr + blockidx) -> blockidx = 0 *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in newidx.
								rewrite <- newidx in *.
								intuition.
						+++ (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr + blockidx)) *)
								assert(HKSEq : isKS newBlockEntryAddr s = isKS newBlockEntryAddr s0).
								{
									unfold isKS. rewrite HlookupnewBs0. rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqscebentry.
									rewrite beqAddrSym in beqscebentry.
									rewrite beqscebentry.
									cbn. rewrite beqAddrTrue.
									f_equal. rewrite <- Hblockindex7. rewrite <- Hblockindex6.
									rewrite <- Hblockindex5. rewrite <- Hblockindex4.
									rewrite <- Hblockindex3. rewrite <- Hblockindex2.
									unfold CBlockEntry.
									destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
									intuition.
									destruct blockentry_d. destruct bentry5.
									intuition.
								}
								assert(HKSs0 : isKS newBlockEntryAddr s0) by (rewrite HKSEq in * ; intuition).
								(* specialize for newBlock *)
								specialize(Hcons0 newBlockEntryAddr blockidx HKSs0 Hblockidx).
								(* check all values *)
								destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + blockidx))) eqn:beqsceidx; try(exfalso ; congruence).
								+ (* sceaddr = (CPaddr (newBlockEntryAddr + blockidx) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidx.
									rewrite <- beqsceidx in *.
									unfold isSCE in *.
									unfold isBE in *.
									destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v ; try(exfalso ; congruence).
								+ (* sceaddr <> (CPaddr (newBlockEntryAddr + blockidx) *)
									destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + blockidx))) eqn:beqpdidx; try(exfalso ; congruence).
									++ (* pdinsertion = (CPaddr (newBlockEntryAddr + blockidx) *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidx.
											rewrite <- beqpdidx in *.
											unfold isPDT in *.
											unfold isBE in *.
											destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
									++ (* pdinsertion <> (CPaddr (newBlockEntryAddr + blockidx) *)
													unfold isBE.
													rewrite Hs.
													cbn. rewrite beqAddrTrue.
													rewrite beqsceidx.
													assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
													rewrite HnewBsceNotEq. (*newBlock <> sce *)
													assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
													rewrite HpdnewBNotEq. (*pd <> newblock*)
													cbn.
													rewrite newidx.
													rewrite beqAddrTrue.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
													destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
													cbn.
													destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + blockidx))) eqn:Hff ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
			--- (* 2) newBlockEntryAddr <> bentryaddr *)
					(* COPY previous step and wellFormedShadowCutIfBlockEntry *)
					assert(HKSeq : isKS kernelentryaddr s = isKS kernelentryaddr s0).
					{
						unfold isKS.
						rewrite Hs. cbn.
						rewrite beqAddrTrue.
						rewrite beqscebentry.
						assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
						rewrite HnewBsceNotEq. (*newBlock <> sce *)
						assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
						rewrite HpdnewBNotEq. (*pd <> newblock*)
						cbn in HBEs. rewrite beqAddrTrue. cbn.
						rewrite newbentry. rewrite HpdnewBNotEq.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity; intuition.
						cbn.
						destruct (beqAddr pdinsertion kernelentryaddr) eqn:Hf ; try (exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
						repeat rewrite removeDupIdentity; intuition.
					}
					assert(HKSs0 : isKS kernelentryaddr s0).
					{ rewrite <- HKSeq. assumption. }
					specialize(Hcons0 kernelentryaddr blockidx HKSs0 Hblockidx).
					destruct (beqAddr sceaddr (CPaddr (kernelentryaddr + blockidx))) eqn:beqsceidx; try(exfalso ; congruence).
					+ (* sceaddr = (CPaddr (kernelentryaddr + blockidx) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidx.
						rewrite <- beqsceidx in *.
						unfold isSCE in *.
						unfold isBE in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					+ (* sceaddr <> (CPaddr (kernelentryaddr + blockidx) *)
						destruct (beqAddr pdinsertion (CPaddr (kernelentryaddr + blockidx))) eqn:beqpdidx; try(exfalso ; congruence).
						++ (* pdinsertion = (CPaddr (kernelentryaddr + blockidx) *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidx.
								rewrite <- beqpdidx in *.
								unfold isPDT in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						++ (* pdinsertion <> (CPaddr (kernelentryaddr + blockidx) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (kernelentryaddr + blockidx))) eqn:newidx ; try(exfalso ; congruence).
							+++ (* newBlockEntryAddr = (CPaddr (kernelentryaddr + blockidx) -> blockidx = 0 *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in newidx.
									rewrite <- newidx in *.
									intuition.
							+++ (* newBlockEntryAddr <> (CPaddr (kernelentryaddr + blockidx)) *)
									(* leads to s0 *)
									unfold isBE.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqsceidx.
									assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
									rewrite HnewBsceNotEq. (*newBlock <> sce *)
									assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
									rewrite HpdnewBNotEq. (*pd <> newblock*)
									cbn.
									rewrite newidx.
									rewrite beqAddrTrue.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (kernelentryaddr + blockidx))) eqn:Hff ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of BlockEntryAddrInBlocksRangeIsBE *)

assert(HKernelStructureStartFromBlockEntryAddrIsKSs : KernelStructureStartFromBlockEntryAddrIsKS s).
{ (* KernelStructureStartFromBlockEntryAddrIsKS s *)
	unfold KernelStructureStartFromBlockEntryAddrIsKS.
	intros bentryaddr blockidx Hlookup Hblockidx.

	assert(Hcons0 : KernelStructureStartFromBlockEntryAddrIsKS s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold KernelStructureStartFromBlockEntryAddrIsKS in Hcons0.

	(* check all possible values for bentryaddr in the modified state s
			-> only possible is newBlockEntryAddr
		1) if bentryaddr == newBlockEntryAddr :
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
		destruct (beqAddr pdinsertion bentryaddr) eqn:beqpdbentry; try(exfalso ; congruence).
		-- (* pdinsertion = bentryaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdbentry.
			rewrite <- beqpdbentry in *.
			unfold isPDT in *.
			unfold isBE in *.
			destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> bentryaddr *)
			destruct (beqAddr newBlockEntryAddr bentryaddr) eqn:newbentry ; try(exfalso ; congruence).
			--- (* newBlockEntryAddr = bentryaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in newbentry.
					rewrite <- newbentry in *.
					unfold bentryBlockIndex in *. rewrite HlookupnewBs in *.
					destruct Hblockidx as [Hblockidx Hidxnb].
					specialize(Hcons0 newBlockEntryAddr blockidx HBEs0).
					rewrite HlookupnewBs0 in *. intuition. rewrite Hblockindex in *.
					intuition.

					(* Check all possible values for CPaddr (newBlockEntryAddr - blockidx)
							-> only possible is newBlockEntryAddr
							1) if CPaddr (newBlockEntryAddr - blockidx) == newBlockEntryAddr :
									- still a BlockEntry in s with blockindex newBlockEntryAddr = 0 -> OK
							2) if CPaddr (newBlockEntryAddr - blockidx) <> newBlockEntryAddr :
									- relates to another bentry than newBlockentryAddr
										that was not modified
										(either in the same structure or another)
									- -> leads to s0 -> OK
					*)

					(* Check all values except newBlockEntryAddr *)
					destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
					*	(* sceaddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
						rewrite <- beqsceks in *.
						unfold isSCE in *.
						unfold isKS in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> kernelstarts0 *)
						destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
						** (* pdinsertion = (CPaddr (newBlockEntryAddr - blockidx)) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
							rewrite <- beqpdks in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
						** (* pdinsertion <> (CPaddr (newBlockEntryAddr - blockidx)) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
									rewrite <- beqnewks in *.
									intuition.
									unfold isKS in *. rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
									rewrite Hblockindex. intuition.
							*** (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr - blockidx)) *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:sceks ; try(exfalso ; congruence).
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn.
									destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:newks ; try(exfalso ; congruence).
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdks ; try(exfalso ; congruence).
									cbn.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
			---	(* newBlockEntryAddr <> bentryaddr *)
					assert(HblockEq : isBE bentryaddr s = isBE bentryaddr s0).
					{ (* DUP *)
						unfold isBE.
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						destruct (beqAddr sceaddr bentryaddr) eqn:scebentry ; try(exfalso ; congruence).
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
						rewrite beqAddrTrue.
						cbn. rewrite newbentry.
						assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
						rewrite HpdnewBNotEq. (*pd <> newblock*)
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						cbn.
						destruct (beqAddr pdinsertion bentryaddr) eqn:pdbentry; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdbentry. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
					}
					assert(Hblocks0 : isBE bentryaddr s0) by (rewrite HblockEq in * ; intuition).
					apply isBELookupEq in Hlookup. destruct Hlookup as [blockentry Hlookup].
					unfold bentryBlockIndex in *. rewrite Hlookup in *.
					destruct Hblockidx as [Hblockidx Hidxnb].
					specialize(Hcons0 bentryaddr blockidx Hblocks0).
					apply isBELookupEq in Hblocks0. destruct Hblocks0 as [blockentrys0 Hblocks0].
					rewrite Hblocks0 in *. intuition.
					assert(HlookupEq : lookup bentryaddr (memory s) beqAddr = lookup bentryaddr (memory s0) beqAddr).
					{ (* DUP *)
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						destruct (beqAddr sceaddr bentryaddr) eqn:scebentry ; try(exfalso ; congruence).
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
						rewrite beqAddrTrue.
						cbn. rewrite newbentry.
						assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
						rewrite HpdnewBNotEq. (*pd <> newblock*)
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						cbn.
						destruct (beqAddr pdinsertion bentryaddr) eqn:pdbentry; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdbentry. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
					}
					assert(HlookupEq' : lookup bentryaddr (memory s0) beqAddr = Some (BE blockentry)).
					{ rewrite <- HlookupEq. intuition. }
					rewrite HlookupEq' in *. inversion Hblocks0.
					subst blockentrys0. intuition.
					(* DUP *)
					(* Check all values except newBlockEntryAddr *)
					destruct (beqAddr sceaddr (CPaddr (bentryaddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
					*	(* sceaddr = (CPaddr (bentryaddr - blockidx)) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
						rewrite <- beqsceks in *.
						unfold isSCE in *.
						unfold isKS in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> (CPaddr (bentryaddr - blockidx)) *)
						destruct (beqAddr pdinsertion (CPaddr (bentryaddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
						** (* pdinsertion = (CPaddr (bentryaddr - blockidx)) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
							rewrite <- beqpdks in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					** (* pdinsertion <> (CPaddr (bentryaddr - blockidx)) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (bentryaddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (CPaddr (bentryaddr - blockidx)) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
									rewrite <- beqnewks in *.
									unfold isKS in *. rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
									rewrite Hblockindex. intuition.
							*** (* newBlockEntryAddr <> kernelstarts0 *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqsceks.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn. rewrite beqnewks.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (bentryaddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of KernelStructureStartFromBlockEntryAddrIsKS *)

assert(Hsh1InChildLocationIsBEs : sh1InChildLocationIsBE s).
{ (* sh1InChildLocationIsBE s *)
	unfold sh1InChildLocationIsBE.
	intros sh1entryaddr sh1entry Hlookup Hsh1entryNotNull.

	assert(Hcons0 : sh1InChildLocationIsBE s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold sh1InChildLocationIsBE in Hcons0.

	(* check all possible values for sh1entryaddr in the modified state s
			-> no entry modifications correspond to SH1Entry type
			(inChildLocation sh1entry) only possible value is NewBlockEntryAddr
			- = NewBlockEntryAddr -> isBE at s so OK
			- <> NewBlockEntryAddr -> leads to s0 -> OK
*)
	(* Check all values *)
	destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1entry; try(exfalso ; congruence).
	-	(* sceaddr = sh1entryaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1entry.
		rewrite <- beqscesh1entry in *.
		unfold isSCE in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> sh1entryaddr *)
		destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1entry; try(exfalso ; congruence).
		-- (* pdinsertion = sh1entryaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1entry.
			rewrite <- beqpdsh1entry in *.
			destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
		-- (* pdinsertion <> sh1entryaddr *)
			destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:newsh1entry ; try(exfalso ; congruence).
			--- (* newBlockEntryAddr = sh1entryaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in newsh1entry.
					rewrite <- newsh1entry in *.
					destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
			--- (* newBlockEntryAddr <> sh1entryaddr *)
					assert(HSHEEq : lookup sh1entryaddr (memory s) beqAddr = lookup sh1entryaddr (memory s0) beqAddr).
					{
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						rewrite beqscesh1entry.
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
						rewrite beqAddrTrue.
						cbn. rewrite newsh1entry.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
						cbn.
						destruct (beqAddr pdinsertion sh1entryaddr) eqn:pdsh1entry; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdsh1entry. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
					}
					assert(Hlookups0 : lookup sh1entryaddr (memory s0) beqAddr = Some (SHE sh1entry))
						by (rewrite HSHEEq in * ; intuition).
					specialize(Hcons0 sh1entryaddr sh1entry Hlookups0 Hsh1entryNotNull).
					(* DUP *)
					(* Check all values *)
					destruct (beqAddr sceaddr (inChildLocation sh1entry)) eqn:beqscesh1; try(exfalso ; congruence).
					*	(* sceaddr = (inChildLocation sh1entry) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
						rewrite <- beqscesh1 in *.
						unfold isSCE in *.
						unfold isBE in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> (inChildLocation sh1entry) *)
						destruct (beqAddr pdinsertion (inChildLocation sh1entry)) eqn:beqpdsh1; try(exfalso ; congruence).
						** (* pdinsertion = (inChildLocation sh1entry) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
							rewrite <- beqpdsh1 in *.
							unfold isPDT in *.
							unfold isBE in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					** (* pdinsertion <> (inChildLocation sh1entry) *)
							destruct (beqAddr newBlockEntryAddr (inChildLocation sh1entry)) eqn:beqnewsh1 ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (inChildLocation sh1entry) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
									rewrite <- beqnewsh1 in *.
									intuition.
							*** (* newBlockEntryAddr <> (inChildLocation sh1entry) *)
									unfold isBE.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqscesh1.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn. rewrite beqnewsh1.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (inChildLocation sh1entry)) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of sh1InChildLocationIsBE *)

assert(HStructurePointerIsKSs : StructurePointerIsKS s).
{ (* StructurePointerIsKS s *)
	unfold StructurePointerIsKS.
	intros pdentryaddr pdentry' Hlookup.

	assert(Hcons0 : StructurePointerIsKS s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold StructurePointerIsKS in Hcons0.

(* check all possible values for pdentryaddr in the modified state s
			-> only possible is pdinsertion
		1) if pdentryaddr == pdinsertion :
				- the structure pointer can only be modified through NewBlockEntryAddr
					- structure pointer is newBlock -> still a KS at s0 -> OK
					- structure pointer is not modified -> leads to s0 -> OK
		2) if pdentryaddr <> pdinsertion :
				- relates to another PD than pdinsertion,
					the structure pointer can only be modified through NewBlockEntryAddr
					- structure pointer is newBlock
							- same proof as before -> still a KS at s0 -> OK
								but it means another PD can point to the same structure
								which shouldn't be possible (but may not be an issue for security)
					- structure pointer is not modified -> leads to s0 -> OK
*)
	(* Check all values except pdinsertion*)
	destruct (beqAddr sceaddr pdentryaddr) eqn:beqscepdentry; try(exfalso ; congruence).
	-	(* sceaddr = pdentryaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepdentry.
		rewrite <- beqscepdentry in *.
		unfold isSCE in *.
		rewrite Hlookup in *.
		exfalso ; congruence.
	-	(* sceaddr <> pdentryaddr *)
			destruct (beqAddr newBlockEntryAddr pdentryaddr) eqn:newpdentry ; try(exfalso ; congruence).
			-- (* newBlockEntryAddr = pdentryaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in newpdentry.
					rewrite <- newpdentry in *.
					unfold isBE in *.
					rewrite Hlookup in *.
					exfalso ; congruence.
			-- (* newBlockEntryAddr <> pdentryaddr *)
				destruct (beqAddr pdinsertion pdentryaddr) eqn:beqpdpdentry; try(exfalso ; congruence).
				--- (* pdinsertion = pdentryaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpdentry.
					rewrite <- beqpdpdentry in *.
					assert(HpdentryEq : pdentry1 = pdentry').
					{ rewrite Hpdinsertions in Hlookup. inversion Hlookup. trivial. }
					subst pdentry'.
					specialize(Hcons0 pdinsertion pdentry Hpdinsertions0).
					assert(HstructureEq : (structure pdentry1) = (structure pdentry)).
					{ subst pdentry1. subst pdentry0.  simpl. trivial. }
					rewrite HstructureEq.
					(* Check all values for structure pdentry except newBlockEntryAddr *)
					destruct (beqAddr sceaddr (structure pdentry)) eqn:beqsceptn; try(exfalso ; congruence).
					*	(* sceaddr = (structure pdentry) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceptn.
						rewrite <- beqsceptn in *.
						unfold isSCE in *.
						unfold isKS in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> (structure pdentry) *)
						destruct (beqAddr pdinsertion (structure pdentry)) eqn:beqpdptn; try(exfalso ; congruence).
						** (* pdinsertion = (structure pdentry) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdptn.
							rewrite <- beqpdptn in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
						** (* pdinsertion <> (structure pdentry) *)
							destruct (beqAddr newBlockEntryAddr (structure pdentry)) eqn:beqnewptn ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (structure pdentry) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewptn.
									rewrite <- beqnewptn in *.
									unfold isKS in *.
									rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
									rewrite Hblockindex. trivial.
							*** (* newBlockEntryAddr <> (structure pdentry) *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqsceptn.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn. rewrite beqnewptn.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (structure pdentry)) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
				--- (* pdinsertion <> pdentryaddr *)
						(* DUP *)
						assert(HPDEq : lookup pdentryaddr (memory s) beqAddr = lookup pdentryaddr (memory s0) beqAddr).
						{
							rewrite Hs.
							cbn. rewrite beqAddrTrue.
							rewrite beqscepdentry.
							destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
							rewrite beqAddrTrue.
							cbn. rewrite newpdentry.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
							cbn.
							destruct (beqAddr pdinsertion pdentryaddr) eqn:pdpdentry; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in pdpdentry. congruence.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
						}
						assert(Hlookups0 : lookup pdentryaddr (memory s0) beqAddr = Some (PDT pdentry'))
							by (rewrite HPDEq in * ; intuition).
						specialize(Hcons0 pdentryaddr pdentry' Hlookups0).
						(* Check all values *)
						destruct (beqAddr sceaddr (structure pdentry')) eqn:beqsceptn; try(exfalso ; congruence).
						*	(* sceaddr = (inChildLocation sh1entry) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceptn.
							rewrite <- beqsceptn in *.
							unfold isSCE in *.
							unfold isKS in *.
							destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
						*	(* sceaddr <> (structure pdentry') *)
							destruct (beqAddr pdinsertion (structure pdentry')) eqn:beqpdptn ; try(exfalso ; congruence).
							** (* pdinsertion = (inChildLocation sh1entry) *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdptn.
								rewrite <- beqpdptn in *.
								unfold isPDT in *.
								unfold isKS in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						** (* pdinsertion <> (structure pdentry') *)
								destruct (beqAddr newBlockEntryAddr (structure pdentry')) eqn:beqnewptn ; try(exfalso ; congruence).
								*** (* newBlockEntryAddr = (structure pdentry') *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewptn.
										rewrite <- beqnewptn in *.
										unfold isKS in *.
										rewrite HlookupnewBs. rewrite HlookupnewBs0 in *.
										rewrite Hblockindex. trivial.
								*** (* newBlockEntryAddr <> (inChildLocation sh1entry) *)
										unfold isKS.
										rewrite Hs.
										cbn. rewrite beqAddrTrue.
										rewrite beqsceptn.
										destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
										rewrite beqAddrTrue.
										cbn. rewrite beqnewptn.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
										cbn.
										destruct (beqAddr pdinsertion (structure pdentry')) eqn:pdpd; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in pdpd. congruence.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
} (* end of StructurePointerIsKS *)

assert(HNextKSIsKSs : NextKSIsKS s).
{ (* NextKSIsKS s *)
	unfold NextKSIsKS.
	intros ksaddr nextksaddr next HKS Hnextksaddr Hnext HnextNotNull.

	assert(Hcons0 : NextKSIsKS s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold NextKSIsKS in Hcons0.

	(* check all possible values for ksaddr in the modified state s
			-> only possible is newBlockEntryAddr
		but nextks and nextksaddr never modified
			-> leads to s0, even if nextksaddr == newB -> OK
*)
	(* Check all values except newBlockEntryAddr *)
	destruct (beqAddr sceaddr ksaddr) eqn:beqsceks; try(exfalso ; congruence).
	-	(* sceaddr = ksaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
		rewrite <- beqsceks in *.
		unfold isSCE in *.
		unfold isKS in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> ksaddr *)
		destruct (beqAddr pdinsertion ksaddr) eqn:beqpdks; try(exfalso ; congruence).
		-- (* pdinsertion = ksaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
			rewrite <- beqpdks in *.
			unfold isPDT in *.
			unfold isKS in *.
			destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> ksaddr *)
				(* COPY from BlocksRangeFromKernelStartIsBE *)
				assert(HKSEq : isKS ksaddr s = isKS ksaddr s0).
				{
					unfold isKS.
					destruct (beqAddr newBlockEntryAddr ksaddr) eqn:newks ; try(exfalso ; congruence).
					--- (* newBlockEntryAddr = ksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in newks.
							rewrite <- newks in *.
							rewrite HlookupnewBs0. rewrite Hs.
							cbn. rewrite beqAddrTrue.
							rewrite beqsceks.
							rewrite beqAddrSym in beqsceks.
							rewrite beqsceks.
							cbn. rewrite beqAddrTrue.
							f_equal. rewrite <- Hblockindex7. rewrite <- Hblockindex6.
							rewrite <- Hblockindex5. rewrite <- Hblockindex4.
							rewrite <- Hblockindex3. rewrite <- Hblockindex2.
							unfold CBlockEntry.
							destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
							intuition.
							destruct blockentry_d. destruct bentry5.
							intuition.
					--- (* newBlockEntryAddr <> ksaddr *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							rewrite beqsceks.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq. (*newBlock <> sce *)
							assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewBNotEq. (*pd <> newblock*)
							cbn. rewrite beqAddrTrue.
							rewrite newks. rewrite HpdnewBNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity; intuition.
							cbn.
							destruct (beqAddr pdinsertion ksaddr) eqn:Hf ; try (exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
							repeat rewrite removeDupIdentity; intuition.
					}
				assert(HKSs0 : isKS ksaddr s0) by (rewrite HKSEq in * ; intuition).
				assert(HnextaddrEq : nextKSAddr ksaddr nextksaddr s = nextKSAddr ksaddr nextksaddr s0).
				{
					unfold nextKSAddr.
					destruct (beqAddr newBlockEntryAddr ksaddr) eqn:newks ; try(exfalso ; congruence).
					--- (* newBlockEntryAddr = ksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in newks.
							rewrite <- newks in *.
							rewrite HlookupnewBs0. rewrite Hs.
							cbn. rewrite beqAddrTrue.
							rewrite beqsceks.
							rewrite beqAddrSym in beqsceks.
							rewrite beqsceks.
							cbn. rewrite beqAddrTrue. reflexivity.
					--- (* newBlockEntryAddr <> ksaddr *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							rewrite beqsceks.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq. (*newBlock <> sce *)
							assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewBNotEq. (*pd <> newblock*)
							cbn. rewrite beqAddrTrue.
							rewrite newks. rewrite HpdnewBNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity; intuition.
							cbn.
							destruct (beqAddr pdinsertion ksaddr) eqn:Hf ; try (exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
							repeat rewrite removeDupIdentity; intuition.
				}
				assert(Hnextaddrs0 : nextKSAddr ksaddr nextksaddr s0) by (rewrite HnextaddrEq in * ; intuition).
				assert(Hnextaddr : nextksaddr = CPaddr (ksaddr + nextoffset)).
				{
					unfold nextKSAddr in *. unfold isKS in *.
					destruct (lookup ksaddr (memory s) beqAddr) eqn:Hks ; try(exfalso ; congruence).
					destruct v eqn:Hv ; try(exfalso ; congruence).
					intuition.
				}
				assert(HnextEq : nextKSentry nextksaddr next s = nextKSentry nextksaddr next s0).
				{
					unfold nextKSentry.
					destruct (beqAddr newBlockEntryAddr nextksaddr) eqn:newks ; try(exfalso ; congruence).
					--- (* newBlockEntryAddr = nextksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in newks.
							rewrite <- newks in *.
							rewrite HlookupnewBs0. rewrite Hs.
							cbn. rewrite beqAddrTrue.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq. (*newBlock <> sce *)
							rewrite beqAddrSym in HnewBsceNotEq.
							rewrite HnewBsceNotEq.
							cbn. rewrite beqAddrTrue.
							reflexivity.
					--- (* newBlockEntryAddr <> ksaddr *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							assert(Hcons1 : NextKSOffsetIsPADDR s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
							unfold NextKSOffsetIsPADDR in *.
							specialize(Hcons1 ksaddr nextksaddr HKSs0 Hnextaddrs0).
							destruct (beqAddr sceaddr nextksaddr) eqn:beqscenextaddr ; try(exfalso;congruence).
							* rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenextaddr.
								rewrite beqscenextaddr in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								destruct(lookup nextksaddr (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
								destruct v eqn:Hv ; try(exfalso ; congruence).
							* assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
								rewrite HnewBsceNotEq. (*newBlock <> sce *)
								assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
								rewrite HpdnewBNotEq. (*pd <> newblock*)
								cbn. rewrite beqAddrTrue.
								rewrite newks. rewrite HpdnewBNotEq.
								rewrite <- beqAddrFalse in *.
								repeat rewrite removeDupIdentity; intuition.
								cbn.
								destruct (beqAddr pdinsertion nextksaddr) eqn:beqpdnextaddr ; try(exfalso;congruence).
								**	rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnextaddr.
										rewrite beqpdnextaddr in *.
										unfold isPDT in *.
										unfold isPADDR in *.
										destruct(lookup nextksaddr (memory s0) beqAddr) eqn:Hf ; try(exfalso ; congruence).
										destruct v eqn:Hv ; try(exfalso ; congruence).
								** 	rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity; intuition.
				}
				assert(Hnexts0 : nextKSentry nextksaddr next s0) by (rewrite HnextEq in * ; intuition).
				(* specialize for ksaddr *)
				specialize(Hcons0 ksaddr nextksaddr next HKSs0 Hnextaddrs0 Hnexts0 HnextNotNull).
				(* check all values *)
				destruct (beqAddr sceaddr next) eqn:beqscenext; try(exfalso ; congruence).
				+ (* sceaddr = nextksaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenext.
					rewrite <- beqscenext in *.
					unfold isSCE in *.
					unfold isKS in *.
					destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				+ (* sceaddr <> nextksaddr *)
					destruct (beqAddr pdinsertion next) eqn:beqpdnext; try(exfalso ; congruence).
					++ (* pdinsertion = nextksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnext.
							rewrite <- beqpdnext in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					++ (* pdinsertion <> nextksaddr *)
						destruct (beqAddr newBlockEntryAddr next) eqn:beqnewnext; try(exfalso ; congruence).
						+++ (* pdinsertion = nextksaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewnext.
								rewrite <- beqnewnext in *.
								unfold isKS in *. rewrite HlookupnewBs0 in *. rewrite HlookupnewBs in *.
								rewrite Hblockindex. intuition.
						+++ (* pdinsertion <> nextksaddr *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqscenext.
									assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
									rewrite HnewBsceNotEq. (*newBlock <> sce *)
									assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
									rewrite HpdnewBNotEq. (*pd <> newblock*)
									cbn.
									rewrite beqnewnext.
									rewrite beqAddrTrue.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									cbn.
									destruct (beqAddr pdinsertion next) eqn:Hff ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of NextKSIsKS *)

assert(HNextKSOffsetIsPADDRs: NextKSOffsetIsPADDR s).
{ (* NextKSOffsetIsPADDR s *)
	unfold NextKSOffsetIsPADDR.
	intros ksaddr nextksaddr HKS Hnextksaddr.

	assert(Hcons0 : NextKSOffsetIsPADDR s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold NextKSOffsetIsPADDR in Hcons0.

	(* check all possible values for ksaddr in the modified state s
			-> only possible is newBlockEntryAddr
		but nextks and nextksaddr never modified
			-> values for nextksaddr leads to s0 cause nothing matches -> OK
*)
	(* DUP of NextKSIsKS *)
	(* Check all values except newBlockEntryAddr *)
	destruct (beqAddr sceaddr ksaddr) eqn:beqsceks; try(exfalso ; congruence).
	-	(* sceaddr = ksaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
		rewrite <- beqsceks in *.
		unfold isSCE in *.
		unfold isKS in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> ksaddr *)
		destruct (beqAddr pdinsertion ksaddr) eqn:beqpdks; try(exfalso ; congruence).
		-- (* pdinsertion = ksaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
			rewrite <- beqpdks in *.
			unfold isPDT in *.
			unfold isKS in *.
			destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> ksaddr *)
				(* COPY from BlocksRangeFromKernelStartIsBE *)
				assert(HKSEq : isKS ksaddr s = isKS ksaddr s0).
				{
					unfold isKS.
					destruct (beqAddr newBlockEntryAddr ksaddr) eqn:newks ; try(exfalso ; congruence).
					--- (* newBlockEntryAddr = ksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in newks.
							rewrite <- newks in *.
							rewrite HlookupnewBs0. rewrite Hs.
							cbn. rewrite beqAddrTrue.
							rewrite beqsceks.
							rewrite beqAddrSym in beqsceks.
							rewrite beqsceks.
							cbn. rewrite beqAddrTrue.
							f_equal. rewrite <- Hblockindex7. rewrite <- Hblockindex6.
							rewrite <- Hblockindex5. rewrite <- Hblockindex4.
							rewrite <- Hblockindex3. rewrite <- Hblockindex2.
							unfold CBlockEntry.
							destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
							intuition.
							destruct blockentry_d. destruct bentry5.
							intuition.
					--- (* newBlockEntryAddr <> ksaddr *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							rewrite beqsceks.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq. (*newBlock <> sce *)
							assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewBNotEq. (*pd <> newblock*)
							cbn. rewrite beqAddrTrue.
							rewrite newks. rewrite HpdnewBNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity; intuition.
							cbn.
							destruct (beqAddr pdinsertion ksaddr) eqn:Hf ; try (exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
							repeat rewrite removeDupIdentity; intuition.
					}
				assert(HKSs0 : isKS ksaddr s0) by (rewrite HKSEq in * ; intuition).
				assert(HnextaddrEq : nextKSAddr ksaddr nextksaddr s = nextKSAddr ksaddr nextksaddr s0).
				{
					unfold nextKSAddr.
					destruct (beqAddr newBlockEntryAddr ksaddr) eqn:newks ; try(exfalso ; congruence).
					--- (* newBlockEntryAddr = ksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in newks.
							rewrite <- newks in *.
							rewrite HlookupnewBs0. rewrite Hs.
							cbn. rewrite beqAddrTrue.
							rewrite beqsceks.
							rewrite beqAddrSym in beqsceks.
							rewrite beqsceks.
							cbn. rewrite beqAddrTrue. reflexivity.
					--- (* newBlockEntryAddr <> ksaddr *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							rewrite beqsceks.
							assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
							rewrite HnewBsceNotEq. (*newBlock <> sce *)
							assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewBNotEq. (*pd <> newblock*)
							cbn. rewrite beqAddrTrue.
							rewrite newks. rewrite HpdnewBNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity; intuition.
							cbn.
							destruct (beqAddr pdinsertion ksaddr) eqn:Hf ; try (exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
							repeat rewrite removeDupIdentity; intuition.
				}
				assert(Hnextaddrs0 : nextKSAddr ksaddr nextksaddr s0) by (rewrite HnextaddrEq in * ; intuition).
				assert(Hnextaddr : nextksaddr = CPaddr (ksaddr + nextoffset)).
				{
					unfold nextKSAddr in *. unfold isKS in *.
					destruct (lookup ksaddr (memory s) beqAddr) eqn:Hks ; try(exfalso ; congruence).
					destruct v eqn:Hv ; try(exfalso ; congruence).
					intuition.
				}
				(* specialize for ksaddr *)
				specialize(Hcons0 ksaddr nextksaddr HKSs0 Hnextaddrs0).
				(* check all values *)
				destruct (beqAddr sceaddr nextksaddr) eqn:beqscenext; try(exfalso ; congruence).
				+ (* sceaddr = nextksaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenext.
					rewrite <- beqscenext in *.
					unfold isSCE in *.
					unfold isPADDR in *.
					destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				+ (* sceaddr <> nextksaddr *)
					destruct (beqAddr pdinsertion nextksaddr) eqn:beqpdnext; try(exfalso ; congruence).
					++ (* pdinsertion = nextksaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnext.
							rewrite <- beqpdnext in *.
							unfold isPDT in *.
							unfold isPADDR in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					++ (* pdinsertion <> nextksaddr *)
						destruct (beqAddr newBlockEntryAddr nextksaddr) eqn:beqnewnext; try(exfalso ; congruence).
						+++ (* pdinsertion = nextksaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewnext.
								rewrite <- beqnewnext in *.
								unfold isPADDR in *.
								destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						+++ (* pdinsertion <> nextksaddr *)
									unfold isPADDR.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqscenext.
									assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
									rewrite HnewBsceNotEq. (*newBlock <> sce *)
									assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
									rewrite HpdnewBNotEq. (*pd <> newblock*)
									cbn.
									rewrite beqnewnext.
									rewrite beqAddrTrue.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									cbn.
									destruct (beqAddr pdinsertion nextksaddr) eqn:Hff ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of NextKSOffsetIsPADDR *)

assert(HNoDupInFreeSlotsLists : NoDupInFreeSlotsList s).
{ (* NoDupInFreeSlotsList s *)
	unfold NoDupInFreeSlotsList.
	intros pd entrypd Hlookuppd.

	assert(Hcons0 : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold NoDupInFreeSlotsList in Hcons0.

	(* check all possible values for pd in the modified state s
			-> only possible is pdinsertion, we already proved we had no Dup
		if it is another pd, we must prove there are still noDup in that list
			by showing this list was never modified
			-> compute the list at each modified state and check not changed from s0 -> OK
*)
	(* Check all values except pdinsertion *)
	destruct (beqAddr sceaddr pd) eqn:beqscepd; try(exfalso ; congruence).
	-	(* sceaddr = pd *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd.
		rewrite <- beqscepd in *.
		unfold isSCE in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> pd *)
		destruct (beqAddr newBlockEntryAddr pd) eqn:beqnewpd ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = pd *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
				rewrite <- beqnewpd in *.
				unfold isBE in *.
				destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> pd *)
				destruct (beqAddr pdinsertion pd) eqn:beqpdpd; try(exfalso ; congruence).
				--- (* pdinsertion = pd *)
						(* case already proved step by step *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd.
						rewrite <- beqpdpd in *.
						specialize(Hcons0 pdinsertion pdentry Hpdinsertions0).
						destruct Hcons0 as [listoption (Hoptionlist & (Hwellformed & HNoDup))].
						unfold getFreeSlotsList in *. rewrite Hpdinsertions0 in *.
						rewrite Hpdinsertions.
						rewrite HnewFirstFree.
						rewrite <- HnewB in *.
						destruct(beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
						destruct H31 as [Hoptionlists (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
						exists Hoptionlists.
						destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
							---- (* newFirstFreeSlotAddr = nullAddr *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqfirstnull.
										rewrite beqfirstnull in *.
										intuition.
										assert(Hoption :  Hoptionlists = getFreeSlotsListRec n0 nullAddr s0 nbleft) by intuition.
										rewrite FreeSlotsListRec_unroll in Hoption.
										unfold getFreeSlotsListAux in Hoption.
										destruct n0.
										rewrite Hoption in *. cbn in *. congruence.
										destruct (StateLib.Index.ltb nbleft zero).
										rewrite Hoption in *. cbn in *. congruence.
										assert(HNullAddrExistss0 : nullAddrExists s0)
												by (unfold consistency in * ; unfold consistency1 in * ; intuition).
										unfold nullAddrExists in *.
										unfold isPADDR in *.
										destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
										destruct v ; try(exfalso ; congruence).
										destruct (beqAddr p nullAddr).
										rewrite Hoption in *. cbn in *. congruence.
										rewrite Hoption in *. cbn in *. congruence.
							---- (* newFirstFreeSlotAddr <> nullAddr *)
										intuition. subst pdentry1. (* pdentry1 *) cbn.
										assert(HpredNbLeftEq : predCurrentNbFreeSlots = nbleft).
										{ subst nbleft. unfold StateLib.Index.pred in *.
											destruct (gt_dec currnbfreeslots 0) ; intuition.
											inversion H1. (* Some ... = Some predCurrentNbFreeSlots *)
											unfold CIndex.
											assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
											{ 
												assert(HcurrLtmaxIdx : currnbfreeslots <= maxIdx).
												{ intuition. apply IdxLtMaxIdx. }
												lia.
											}
											destruct (le_dec (currnbfreeslots - 1) maxIdx) ; intuition.
											f_equal. apply proof_irrelevance.
										}
										rewrite HpredNbLeftEq.
										rewrite <- H34. (* n2 s = Hoptionlist *)
										eapply getFreeSlotsListRecEqN ; intuition.
					--- (* pdinsertion <> pd *)
							(* similarly, we must prove the list has not changed by recomputing each
									intermediate steps and check at that time *)
							specialize(Hcons0 pd).
							unfold getFreeSlotsList.
							destruct (lookup pd (memory s) beqAddr) eqn:Hpdentry ; try(exfalso ; congruence).
							destruct v eqn:Hv ; try(exfalso ; congruence).
							assert(HlookupEq : lookup pd (memory s) beqAddr = lookup pd (memory s0) beqAddr).
							{	(* check all values *)
								destruct (beqAddr sceaddr pd) eqn:beqscepdentry; try(exfalso ; congruence).
								(* sceaddr <> pd *)
								destruct (beqAddr newBlockEntryAddr pd) eqn:newpdentry ; try(exfalso ; congruence).
								(* newBlockEntryAddr <> pd *)
								destruct (beqAddr pdinsertion pd) eqn:beqpdpdentry; try(exfalso ; congruence).
								(* pdinsertion <> pd *)
								rewrite Hs.
								cbn. rewrite beqAddrTrue.
								rewrite beqscepdentry.
								assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
								rewrite HnewBsceNotEq. (*newBlock <> sce *)
								assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
								rewrite HpdnewBNotEq. (*pd <> newblock*)
								cbn.
								rewrite newpdentry.
								rewrite beqAddrTrue.
								rewrite <- beqAddrFalse in *.
								repeat rewrite removeDupIdentity ; intuition.
								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								cbn.
								destruct (beqAddr pdinsertion pd) eqn:Hff ; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
								rewrite <- beqAddrFalse in *.
								repeat rewrite removeDupIdentity ; intuition.
							}
							assert(Hlookups0: lookup pd (memory s0) beqAddr = Some (PDT p)).
							rewrite <- HlookupEq. intuition.
							specialize (Hcons0 p Hlookups0).
							unfold getFreeSlotsList in *. rewrite Hlookups0 in *.
							destruct (beqAddr (firstfreeslot p) nullAddr) ; try(exfalso ; congruence).
							---- (* optionfreeslotslist = NIL *) 
										destruct Hcons0 as [optionfreeslotslist (Hnil & HwellFormed & HNoDup)].
										exists optionfreeslotslist. intuition.
							---- (* optionfreeslotslist <> NIL *)
										(* show list equality between s0 and s*)
										assert(exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots p) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot p) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot p) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot p) s1 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v0 ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v0 ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s2 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s1 (nbfreeslots p)).
	{
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v0 ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v0 ; try(exfalso ; congruence).
				--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s3 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s2 (nbfreeslots p)).
	{
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s4 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s3 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s5 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s4 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s6 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s5 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s7 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s6 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s8 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s7 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s9 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s8 (nbfreeslots p)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- destruct Hcons0 as [Hoptionlist Hfreeslotss0].
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					---- (* firstfreeslot p = NULL *)
								(* if first free of other PD is NULL, then newB can't be in NIL -> False *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstfreeNull.
								contradict H30. (*  In newBlockEntryAddr (filterOptionPaddr
           												(getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p))) *)
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									assert(HnullAddrExistss0 : nullAddrExists s0)
										by (unfold consistency in * ; unfold consistency1 in * ; intuition).
									unfold nullAddrExists in *.
									unfold isPADDR in *.
									rewrite HfirstfreeNull in *.
									simpl.
									destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v0 ; try(exfalso ; congruence).
									destruct (beqAddr p0 nullAddr) eqn:HfirstfreeNullFinal ; intuition.
					---- (* firstfreeslot p <> NULL *)
								(* if first free of other PD is NOT NULL,
								then newB can't be in the two lists at s0 because of Disjoint -> False *)
								subst listoption2. subst listoption1.
								unfold Lib.disjoint in H_Disjoints0.
								specialize(H_Disjoints0 newBlockEntryAddr).
								destruct (H_Disjoints0).
								* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
									** (* N=0 -> NotWellFormed *)
											cbn in *.
											congruence.
									** (* N>0 *)
											clear IHn.
											simpl. rewrite HlookupnewBs0.
											assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
											{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
											rewrite <- HcurrNb in *.
											destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
											rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
								* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s10 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s9 (nbfreeslots p)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
						{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
							destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
							cbn.
							destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
							rewrite beqAddrTrue.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
						}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v0 ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v0 ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v0 ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v0 ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots p <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
destruct H30 as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
									(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
assert(HsEq : s10 = s).
{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
	subst s7. subst s8. subst s9. subst s10.
	rewrite Hs. f_equal.
}
rewrite HsEq in *.
assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot p) s (nbfreeslots p) =
											getFreeSlotsListRec (maxIdx+1) (firstfreeslot p) s0 (nbfreeslots p)).
{
	intuition.
	subst nbleft.
	(* rewrite all previous getFreeSlotsListRec equalities *)
	rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40. rewrite <- H42.
	rewrite <- H44. rewrite <- H46. rewrite <- H48. rewrite <- H50. rewrite <- H53.
	reflexivity.
}
assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot p) s (nbfreeslots p)
													= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s (nbfreeslots p)).
{ eapply getFreeSlotsListRecEqN ; intuition.
	subst nbleft. lia.
	assert (HnbLtmaxIdx : nbfreeslots p <= maxIdx) by apply IdxLtMaxIdx.
	lia.
}
rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq. intuition.
} (* end of NoDupInFreeSlotsList *)

assert(HfreeSlotsListIsFreeSlots : freeSlotsListIsFreeSlot s).
{ (* freeSlotsListIsFreeSlot s*)
	unfold freeSlotsListIsFreeSlot.
	intros pd freeslotaddr optionfreeslotslist freeslotslist HPDTpds.
	intros (HoptionfreeSlotsList&HwellFormedFreeSlots) (HfreeSlotsList & HfreeSlotInList).
	intro HfreeSlotNotNull.

	assert(Hcons0 : freeSlotsListIsFreeSlot s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold freeSlotsListIsFreeSlot in Hcons0.

	(* check all possible values for freeslotaddr in the modified state s
	-> only possible is newBlockEntryAddr
	1) if freeslotaddr == newBlockEntryAddr :
			-> not possible since newBlockEntryAddr doesn't belong to freeslotslist
	2) if freeslotaddr <> newBlockEntryAddr :
		- relates to another free slot than newBlockentryAddr
		(either in the same free slots list or from another pd)
		-> leads to s0 -> OK
	*)
(* Check all values for pd *)
	destruct (beqAddr sceaddr pd) eqn:beqscepd; try(exfalso ; congruence).
	-	(* sceaddr = pd *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd.
		rewrite <- beqscepd in *.
		unfold isSCE in *.
		unfold isPDT in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> pd *)
		destruct (beqAddr newBlockEntryAddr pd) eqn:beqnewpd ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = pd *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
				rewrite <- beqnewpd in *.
				unfold isBE in *.
				unfold isPDT in *.
				destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> pd *)
				destruct (beqAddr pdinsertion pd) eqn:beqpdpd; try(exfalso ; congruence).
				--- (* pdinsertion = pd *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd.
						rewrite <- beqpdpd in *.
						destruct H31 as [Hoptionlists (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
						specialize (Hcons0 pdinsertion freeslotaddr (SomePaddr newBlockEntryAddr :: Hoptionlists) (newBlockEntryAddr::freeslotslist) HPDTs0).
						assert(HslotslistEqs0 : SomePaddr newBlockEntryAddr :: Hoptionlists = getFreeSlotsList pdinsertion s0 /\
											 wellFormedFreeSlotsList (SomePaddr newBlockEntryAddr :: Hoptionlists) <> False).
						{ unfold getFreeSlotsList. rewrite Hpdinsertions0.
							rewrite <- HnewB.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- beqAddrFalse in *.
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
							rewrite FreeSlotsListRec_unroll.
							unfold getFreeSlotsListAux in *.
							assert(HMaxIdxNext : maxIdx + 1 = S maxIdx).
							{ lia. }
							rewrite HMaxIdxNext.
							assert(Hnbfreeslots : (nbfreeslots pdentry) = currnbfreeslots).
							{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
							rewrite Hnbfreeslots.
							destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
							* unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
							* rewrite HlookupnewBs0.
								destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								split.
								f_equal. intuition.
								rewrite H35. (* Hoptionlists = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft *)
								assert(HnewBEndIsNewFirst : (endAddr (blockrange bentry)) = newFirstFreeSlotAddr).
								{ unfold bentryEndAddr in *. rewrite HlookupnewBs0 in *. intuition. }
								rewrite HnewBEndIsNewFirst.
								assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
								{
										unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *.
										destruct currnbfreeslots.
										+ simpl. destruct i0.
											* simpl. apply maxIdxNotZero.
											* cbn. rewrite PeanoNat.Nat.sub_0_r. intuition.
								}
								assert((CIndex (currnbfreeslots - 1)) = i).
								{ unfold CIndex.
									destruct (le_dec (currnbfreeslots - 1) maxIdx) ; simpl in * ; intuition ; try(exfalso ; congruence).
										unfold StateLib.Index.pred in *.
										destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
										inversion Hpred. f_equal. apply proof_irrelevance.
								}
								unfold pdentryNbFreeSlots in *. rewrite H5 in *.
								rewrite H8 in *.
								assert(i < maxIdx).
								{	unfold StateLib.Index.pred in *.
									destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
									inversion Hpred. simpl. intuition.
								}
								assert(HEq : getFreeSlotsListRec maxIdx newFirstFreeSlotAddr s0 i =
																getFreeSlotsListRec (maxIdx+1) newFirstFreeSlotAddr s0 i).
								{
									eapply getFreeSlotsListRecEqN ; intuition.
								}
								rewrite HEq.
								subst nbleft. subst i.
								eapply getFreeSlotsListRecEqN ; intuition.
								{ lia. }
								intuition.
							}
							specialize (Hcons0 HslotslistEqs0).
							(* continue to break Hcons0 1) sceaddr and podinsertion -> go to s0 show isFreeSlot @ s0 is false
																					2) newB -> show not in free slots list so NOK *)
							assert(HslotsListEqs : newBlockEntryAddr::freeslotslist = filterOptionPaddr (SomePaddr newBlockEntryAddr :: Hoptionlists) /\
         														In freeslotaddr freeslotslist).
							{ intuition. cbn. f_equal. rewrite HfreeSlotsList.
								rewrite HoptionfreeSlotsList.
								unfold getFreeSlotsList. rewrite Hpdinsertions.
								rewrite HnewFirstFree. rewrite <- H36. (* getFreeSlotsListRec s .. = Hoptionlists *)

								destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:HfirstIsNull ; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in HfirstIsNull.
								rewrite HfirstIsNull.
								rewrite FreeSlotsListRec_unroll.
								unfold getFreeSlotsListAux.
								destruct n2. cbn. reflexivity.
								destruct (StateLib.Index.ltb nbleft zero) eqn:Hltb ; try(exfalso ; congruence).
								cbn. reflexivity.
								unfold nullAddrExists in *. unfold isPADDR in *.
								destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v eqn:Hv ; try(exfalso ; congruence).
								destruct (beqAddr p nullAddr) eqn:HpNull ; try(cbn ; reflexivity).
								assert(Hnbleft : nbfreeslots pdentry1 = nbleft).
								{ subst pdentry1. simpl.
									subst nbleft. (* nbleft = CIndex (currnbfreeslots - 1)*)
									destruct predCurrentNbFreeSlots.
									unfold StateLib.Index.pred in H1.
									destruct (gt_dec currnbfreeslots 0); try (exfalso ; congruence).
									unfold CIndex. inversion H1 as [Hpred].
									rewrite Hpred. destruct (le_dec i maxIdx) ; try(exfalso ; congruence).
									f_equal. apply proof_irrelevance.
								}
								rewrite Hnbleft.
								assert (HfreeSlotsEq : getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s nbleft =
																getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft).
								{ apply eq_sym.
									eapply getFreeSlotsListRecEqN ; intuition.
								}
								rewrite HfreeSlotsEq. reflexivity.
							}
							assert(HInFreeSlotExpand : In freeslotaddr freeslotslist ->
																					In freeslotaddr (newBlockEntryAddr :: freeslotslist)).
							{ intuition. }
							assert(HslotIn : newBlockEntryAddr :: freeslotslist =
																	filterOptionPaddr (SomePaddr newBlockEntryAddr :: Hoptionlists) /\
																	In freeslotaddr (newBlockEntryAddr :: freeslotslist)) by intuition.
							specialize (Hcons0 HslotIn HfreeSlotNotNull).
							(* 1) dismiss all impossible values for freeslotaddr except newB *)
							destruct (beqAddr sceaddr freeslotaddr) eqn:beqfscefree; try(exfalso ; congruence).
								---- (* sceaddr = freeslotaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqfscefree.
											rewrite <- beqfscefree in *.
											unfold isSCE in *.
											unfold isFreeSlot in *.
											destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
								---- (* sceaddr <> freeslotaddr *)
											destruct (beqAddr pdinsertion freeslotaddr) eqn:beqfpdfree; try(exfalso ; congruence).
											----- (* pdinsertion = freeslotaddr *)
														rewrite <- DependentTypeLemmas.beqAddrTrue in beqfpdfree.
														rewrite <- beqfpdfree in *.
														unfold isPDT in *.
														unfold isFreeSlot in *.
														destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
														destruct v ; try(exfalso ; congruence).
											----- (* pdinsertion <> freeslotaddr *)
														destruct (beqAddr newBlockEntryAddr freeslotaddr) eqn:beqfnewBfree; try(exfalso ; congruence).
														------ (* newBlockEntryAddr = freeslotaddr *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqfnewBfree.
																		rewrite <- beqfnewBfree in *.
																		(* 2) we already proved newB is not in the free slots list anymore *)
																		contradict HfreeSlotInList.
																		rewrite HfreeSlotsList. rewrite HoptionfreeSlotsList.
																		unfold getFreeSlotsList. rewrite Hpdinsertions.
																		rewrite HnewFirstFree.
																		destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:HnewNotNull ; try(exfalso ; congruence).
																		cbn. intuition.
																		assert(Hnbleft : nbfreeslots pdentry1 = nbleft).
																		{ (* DUP *)
																			subst pdentry1. simpl. intuition.
																			subst nbleft. (* nbleft = CIndex (currnbfreeslots - 1)*)
																			destruct predCurrentNbFreeSlots.
																			unfold StateLib.Index.pred in H1.
																			destruct (gt_dec currnbfreeslots 0); try (exfalso ; congruence).
																			unfold CIndex. inversion H1 as [Hpred].
																			rewrite Hpred. destruct (le_dec i maxIdx) ; try(exfalso ; congruence).
																			f_equal. apply proof_irrelevance.
																		}
																		rewrite Hnbleft.
																		assert(HfreeSlotsListEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s nbleft).
																		{ intuition.
																			rewrite <- H40. (* getFreeSlotsList s = Hoptionlists *)
																			eapply getFreeSlotsListRecEqN ; intuition.
																		}
																		rewrite <- HfreeSlotsListEq. intuition.
														------ (* newBlockEntryAddr <> freeslotaddr *)
																		(* no entry left to try out -> leads to s0 *)
																		rewrite Hs. unfold isFreeSlot.
																		cbn. rewrite beqAddrTrue.
																		rewrite beqfscefree.
																		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
																		rewrite beqAddrTrue.
																		cbn. rewrite beqfnewBfree.
																		rewrite <- beqAddrFalse in *.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
																		cbn.
																		destruct (beqAddr pdinsertion freeslotaddr) eqn:pdffentry; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in pdffentry. congruence.
																		rewrite <- beqAddrFalse in *.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		unfold isFreeSlot in Hcons0.
																		destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlots0 ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
																		destruct (beqAddr sceaddr (CPaddr (freeslotaddr + sh1offset))) eqn:beqscefreesh1 ; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefreesh1.
																		rewrite <- beqscefreesh1 in *.
																		unfold isFreeSlot in *.
																		unfold isSCE in *.
																		destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
																		destruct (beqAddr newBlockEntryAddr (CPaddr (freeslotaddr + sh1offset))) eqn:beqscefreesc ; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefreesc.
																		rewrite <- beqscefreesc in *.
																		unfold isFreeSlot in *.
																		unfold isBE in *.
																		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
																		rewrite <- beqAddrFalse in *.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnewB; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in pdnewB. congruence.
																		cbn.
																		destruct (beqAddr pdinsertion (CPaddr (freeslotaddr + sh1offset))) eqn:beqpdfreesh1 ; try(exfalso ; congruence).
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfreesh1.
																		rewrite <- beqpdfreesh1 in *.
																		unfold isFreeSlot in *.
																		unfold isPDT in *.
																		destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite removeDupIdentity ; try congruence.
																		rewrite <- beqAddrFalse in *.
																		rewrite removeDupIdentity ; try congruence.
																		destruct (lookup (CPaddr (freeslotaddr + sh1offset)) (memory s0) beqAddr) ; try(exfalso ; congruence).
																		destruct v ; try(exfalso ; congruence).
																		destruct (beqAddr sceaddr (CPaddr (freeslotaddr + scoffset))) eqn:beqscefssc ; try(exfalso ; congruence).
																		(* show sceaddr must be equal to freeslot which is false *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefssc.
																		assert(HSCEOffset : sceaddr = CPaddr (newBlockEntryAddr + scoffset)) by intuition.
																		rewrite HSCEOffset in beqscefssc.
																		contradict beqscefssc.
																		unfold nullAddrExists in *. unfold isPADDR in *.
																		unfold CPaddr.
																		destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
																		* destruct (le_dec (freeslotaddr + scoffset) maxAddr) eqn:Hk.
																			** simpl in *. intro Hfalse.
																				inversion Hfalse as [Heq].
																				rewrite PeanoNat.Nat.add_cancel_r in Heq.
																				apply CPaddrInjectionNat in Heq.
																				repeat rewrite paddrEqId in Heq.
																				congruence.
																			** 	intro Hfalse.
																					inversion Hfalse as [Heq].
																					assert(HeqNull : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																					{ rewrite nullAddrIs0.
																						apply CPaddrInjectionNat in Heq.
																						intuition.
																					}
																					rewrite HeqNull in *.
																					rewrite HSCEOffset in *.
																					unfold isSCE in *.
																					destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
																					destruct v ; try(exfalso ; congruence).
																		* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																			{ rewrite nullAddrIs0.
																				unfold CPaddr. rewrite Hj.
																				destruct (le_dec 0 maxAddr) ; intuition.
																				f_equal. apply proof_irrelevance.
																			}
																			rewrite Heq in *.
																			rewrite HSCEOffset in *.
																			unfold isSCE in *.
																			destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
																			destruct v ; try(exfalso ; congruence).
																		* destruct (beqAddr newBlockEntryAddr (CPaddr (freeslotaddr + scoffset))) eqn:beqnewBfssc ; try(exfalso ; congruence).
																			------- (* newBlockEntryAddr = (CPaddr (freeslotaddr + scoffset)) *)
																							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewBfssc.
																							rewrite <- beqnewBfssc in *.
																							destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																							destruct v ; try(exfalso ; congruence).
																			------- (* newBlockEntryAddr <> (CPaddr (freeslotaddr + scoffset)) *)
 																							rewrite <- beqAddrFalse in *.
																							repeat rewrite removeDupIdentity ; try congruence.
																							destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf; try(exfalso ; congruence).
																							rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
																							rewrite <- beqAddrFalse in *.
																							repeat rewrite removeDupIdentity ; try congruence.
																							cbn.
																							destruct (beqAddr pdinsertion (CPaddr (freeslotaddr + scoffset))) eqn:beqpdfssc ; try (exfalso ; congruence).
																							-------- (* pdinsertion = (CPaddr (freeslotaddr + scoffset)) *)
																												rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfssc.
																												rewrite <- beqpdfssc in *.
																												destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
																												destruct v ; try(exfalso ; congruence).
																							-------- (* pdinsertion <> (CPaddr (freeslotaddr + scoffset)) *)
																												rewrite <- beqAddrFalse in *.
																												repeat rewrite removeDupIdentity ; try congruence.
																												destruct (lookup (CPaddr (freeslotaddr + scoffset)) (memory s0) beqAddr) eqn:Hlookupsc ; try(exfalso ; congruence).
																												destruct v ; try(exfalso ; congruence).
																												intuition.
																		* intro Hf. rewrite <- beqAddrFalse in *. congruence.
			--- (* pdinsertion <> pd *)
					(* similarly, we must prove the list has not changed by recomputing each
							intermediate steps and check at that time *)
					(* show leads to s0 -> OK *)
					assert(HlookupEq : lookup pd (memory s) beqAddr = lookup pd (memory s0) beqAddr).
					{	(* check all values *)
						destruct (beqAddr sceaddr pd) eqn:beqscepdentry; try(exfalso ; congruence).
						(* sceaddr <> pd *)
						destruct (beqAddr newBlockEntryAddr pd) eqn:newpdentry ; try(exfalso ; congruence).
						(* newBlockEntryAddr <> pd *)
						destruct (beqAddr pdinsertion pd) eqn:beqpdpdentry; try(exfalso ; congruence).
						(* pdinsertion <> pd *)
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						rewrite beqscepdentry.
						assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
						rewrite HnewBsceNotEq. (*newBlock <> sce *)
						assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
						rewrite HpdnewBNotEq. (*pd <> newblock*)
						cbn.
						rewrite newpdentry.
						rewrite beqAddrTrue.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
						cbn.
						destruct (beqAddr pdinsertion pd) eqn:Hff ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
					}
					assert(HPDTpds0: isPDT pd s0).
					{ unfold isPDT in *. rewrite <- HlookupEq. intuition. }
					specialize(Hcons0 pd freeslotaddr ). (*optionfreeslotslist freeslotslist HPDTpds0).*)
					assert(HfreeSlotsListEq : optionfreeslotslist = getFreeSlotsList pd s0 /\
         						wellFormedFreeSlotsList optionfreeslotslist <> False).
					{
						unfold getFreeSlotsList.
						assert(Hlookups0: isPDT pd s0) by intuition.
						apply isPDTLookupEq in Hlookups0. destruct Hlookups0 as [p Hlookups0].
						unfold getFreeSlotsList in *. rewrite HlookupEq in *. rewrite Hlookups0 in *.
						destruct (beqAddr (firstfreeslot p) nullAddr) eqn: HpNotNull ; try(exfalso ; congruence).
						---- (* optionfreeslotslist = NIL *)
									intuition.
						---- (* optionfreeslotslist <> NIL *)
									(* show list equality between s0 and s*)
									assert(Hs' : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots p) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot p) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot p) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot p) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot p) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot p) s1 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s2 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s1 (nbfreeslots p)).
	{
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s3 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s2 (nbfreeslots p)).
	{			assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold NoDupInFreeSlotsList in *.
				specialize (HwellFormedNoDup pd p Hlookups0).
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
								by (unfold consistency in * ; unfold consistency1 in *; intuition).
							unfold DisjointFreeSlotsLists in *.
							assert(HPDTentrypds0 : isPDT pd s0).
							{ unfold isPDT. rewrite Hlookups0. trivial. }
							rewrite <- beqAddrFalse in beqpdpd.
							pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
							destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
							destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
							unfold getFreeSlotsList in Hlistoption1.
							unfold getFreeSlotsList in Hlistoption2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookups0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
								rewrite HnewBFirstFrees0PDT in *.
								rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
							(*rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.*)
								rewrite FreeSlotsListRec_unroll in Hlistoption1.
								rewrite FreeSlotsListRec_unroll in Hlistoption2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hlistoption1 in *.
											cbn in *.
											unfold Lib.disjoint in H_Disjoints0.
											specialize(H_Disjoints0 newBlockEntryAddr).
											simpl in H_Disjoints0.
											intuition.
									*** rewrite Hlistoption1 in *.
											cbn in HwellFormedList1.
											exfalso ; congruence.
			--- unfold isBE. cbn. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s4 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s3 (nbfreeslots p)).
	{
		(* DUP *)
		assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold NoDupInFreeSlotsList in *.
		specialize (HwellFormedNoDup pd p Hlookups0).
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s5 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s4 (nbfreeslots p)).
	{
		(* DUP *)
		assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold NoDupInFreeSlotsList in *.
		specialize (HwellFormedNoDup pd p Hlookups0).
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s6 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s5 (nbfreeslots p)).
	{
		(* DUP *)
		assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold NoDupInFreeSlotsList in *.
		specialize (HwellFormedNoDup pd p Hlookups0).
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s7 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s6 (nbfreeslots p)).
	{
		(* DUP *)
		assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
		unfold NoDupInFreeSlotsList in *.
		specialize (HwellFormedNoDup pd p Hlookups0).
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s8 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s7 (nbfreeslots p)).
	{
		(* DUP *)
				assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold NoDupInFreeSlotsList in *.
				specialize (HwellFormedNoDup pd p Hlookups0).
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s9 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s8 (nbfreeslots p)).
	{
		(* DUP *)
				assert(HwellFormedNoDup : NoDupInFreeSlotsList s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold NoDupInFreeSlotsList in *.
				specialize (HwellFormedNoDup pd p Hlookups0).
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot p = newBlockEntryAddr) by intuition.
						rewrite HnewBFirstFrees0PDT in *.
						rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hlistoption1.
						rewrite FreeSlotsListRec_unroll in Hlistoption2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hlistoption1 in *.
							cbn in HwellFormedList1.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots p)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hlistoption1 in *.
									cbn in *.
									unfold Lib.disjoint in H_Disjoints0.
									specialize(H_Disjoints0 newBlockEntryAddr).
									simpl in H_Disjoints0.
									intuition.
							*** rewrite Hlistoption1 in *.
									cbn in HwellFormedList1.
									exfalso ; congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : wellFormedFreeSlotsList Hoptionlist = False -> False) by intuition.
					apply HwellFormed. intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- destruct HwellFormedNoDup as [Hoptionlist Hfreeslotss0].
					assert(HFirstFreeSlotEq : getFreeSlotsList pd s0 = getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s0 (nbfreeslots p)).
					{ unfold getFreeSlotsList. rewrite Hlookups0. rewrite HpNotNull. reflexivity. }
					rewrite HFirstFreeSlotEq in *.
					assert(HwellFormed : NoDup (filterOptionPaddr  Hoptionlist)) by intuition.
					intuition. subst Hoptionlist.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
						by (unfold consistency in * ; unfold consistency1 in *; intuition).
					unfold DisjointFreeSlotsLists in *.
					assert(HPDTentrypds0 : isPDT pd s0).
					{ unfold isPDT. rewrite Hlookups0. trivial. }
					rewrite <- beqAddrFalse in beqpdpd.
					pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion pd HPDTs0 HPDTentrypds0 beqpdpd).
					destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
					destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
					unfold getFreeSlotsList in Hlistoption1.
					unfold getFreeSlotsList in Hlistoption2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookups0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot p) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in H_Disjoints0.
					specialize(H_Disjoints0 newBlockEntryAddr).
					destruct (H_Disjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s10 (nbfreeslots p) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s9 (nbfreeslots p)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd p Hlookups0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots p <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
destruct Hs' as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
									(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
assert(HsEq : s10 = s).
{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
	subst s7. subst s8. subst s9. subst s10.
	rewrite Hs. f_equal.
}
rewrite HsEq in *.
assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot p) s (nbfreeslots p) =
											getFreeSlotsListRec (maxIdx+1) (firstfreeslot p) s0 (nbfreeslots p)).
{
	intuition.
	subst nbleft.
	(* rewrite all previous getFreeSlotsListRec equalities *)
	rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40. rewrite <- H42.
	rewrite <- H44.	rewrite <- H46. rewrite <- H48. rewrite <- H50. rewrite <- H53.
	reflexivity.
}
assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot p) s (nbfreeslots p)
													= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot p) s (nbfreeslots p)).
{ eapply getFreeSlotsListRecEqN ; intuition.
	subst nbleft. lia.
	assert (HnbLtmaxIdx : nbfreeslots p <= maxIdx) by apply IdxLtMaxIdx.
	lia.
}
rewrite <- HfreeslotsEq. rewrite HfreeslotsEqn1. intuition.
}
specialize (Hcons0 optionfreeslotslist freeslotslist HPDTpds0 HfreeSlotsListEq).
assert(HInfreeSlot : freeslotslist = filterOptionPaddr optionfreeslotslist /\
         In freeslotaddr freeslotslist) by intuition.
specialize (Hcons0 HInfreeSlot HfreeSlotNotNull).
(* dismiss all impossible values for freeslotaddr except newB *)
destruct (beqAddr sceaddr freeslotaddr) eqn:beqfscefree; try(exfalso ; congruence).
	---- (* sceaddr = freeslotaddr *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqfscefree.
				rewrite <- beqfscefree in *.
				unfold isSCE in *.
				unfold isFreeSlot in *.
				destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
	---- (* sceaddr <> freeslotaddr *)
				destruct (beqAddr pdinsertion freeslotaddr) eqn:beqfpdfree; try(exfalso ; congruence).
				----- (* pdinsertion = freeslotaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqfpdfree.
							rewrite <- beqfpdfree in *.
							unfold isPDT in *.
							unfold isFreeSlot in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
				----- (* pdinsertion <> freeslotaddr *)
							destruct (beqAddr newBlockEntryAddr freeslotaddr) eqn:beqfnewBfree; try(exfalso ; congruence).
							------ (* newBlockEntryAddr = freeslotaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqfnewBfree.
											rewrite <- beqfnewBfree in *.
											(* if newB belongs to pd's free slots list, then it was the case at s0
													but that means newB was at the same time in pd's and pdinsertion's free slots list
													which is false because they are disjoint -> contradiction *)
											assert(H_Disjoints0 : DisjointFreeSlotsLists s0)
																by (unfold consistency in * ; unfold consistency1 in * ; intuition).
											unfold DisjointFreeSlotsLists in *.
											assert(HPDTNotEq : pdinsertion <> pd)
														by (rewrite <- beqAddrFalse in * ; intuition).
											specialize (H_Disjoints0 pdinsertion pd HPDTs0 HPDTpds0 HPDTNotEq).
											destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
											destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
											assert(Hcontra : In newBlockEntryAddr (filterOptionPaddr listoption1)).
											{ subst listoption1.
												unfold getFreeSlotsList in *.
												rewrite Hpdinsertions0 in *.
												rewrite <- HnewB in *.
												destruct (beqAddr newBlockEntryAddr nullAddr) eqn:HnewNotNull ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in HnewNotNull. congruence.
												rewrite FreeSlotsListRec_unroll.
												unfold getFreeSlotsListAux in *.
												induction (maxIdx+1). (* false induction because of fixpoint constraints *)
												** (* N=0 -> NotWellFormed *)
													cbn in *. congruence.
												** (* N>0 *)
													clear IHn.
													cbn in *.
													rewrite HlookupnewBs0 in *.
													destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
													*** cbn. intuition.
													*** cbn in *.
															exfalso ; congruence.
											}
											assert(HfreeSlotsListpdEq : getFreeSlotsList pd s0 = getFreeSlotsList pd s).
											{ subst optionfreeslotslist. intuition. }
											rewrite <- HfreeSlotsListpdEq in *.
											assert(Hcontra' : In newBlockEntryAddr (filterOptionPaddr listoption2)).
											{ subst listoption2.
												unfold getFreeSlotsList in *.
												apply isPDTLookupEq in HPDTpds0. destruct HPDTpds0 as [pdentrys0 Hlookuppds0].
												rewrite HlookupEq in *. rewrite Hlookuppds0 in *.
												destruct (beqAddr (firstfreeslot pdentrys0) nullAddr) eqn:HnewNotNull ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in HnewNotNull.
												subst optionfreeslotslist. subst freeslotslist. intuition.
												subst freeslotslist. subst optionfreeslotslist. intuition.
											}
											assert(HlistEq : optionfreeslotslist = listoption2).
											{ subst listoption2. intuition. }
											rewrite HlistEq in *.
											contradict H_Disjoints0.
											unfold Lib.disjoint. intuition.
											specialize (H30 newBlockEntryAddr Hcontra Hcontra'). congruence.
							------ (* newBlockEntryAddr <> freeslotaddr *)
											(* no entry left to try out -> leads to s0 *)
											rewrite Hs. unfold isFreeSlot.
											cbn. rewrite beqAddrTrue.
											rewrite beqfscefree.
											destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
											rewrite beqAddrTrue.
											cbn. rewrite beqfnewBfree.
											rewrite <- beqAddrFalse in *.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
											cbn.
											destruct (beqAddr pdinsertion freeslotaddr) eqn:pdffentry; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in pdffentry. congruence.
											rewrite <- beqAddrFalse in *.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											unfold isFreeSlot in Hcons0.
											destruct (lookup freeslotaddr (memory s0) beqAddr) eqn:HfreeSlots0 ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
											destruct (beqAddr sceaddr (CPaddr (freeslotaddr + sh1offset))) eqn:beqscefreesh1 ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefreesh1.
											rewrite <- beqscefreesh1 in *.
											unfold isFreeSlot in *.
											unfold isSCE in *.
											destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
											destruct (beqAddr newBlockEntryAddr (CPaddr (freeslotaddr + sh1offset))) eqn:beqscefreesc ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefreesc.
											rewrite <- beqscefreesc in *.
											unfold isFreeSlot in *.
											unfold isBE in *.
											destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
											rewrite <- beqAddrFalse in *.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnewB; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in pdnewB. congruence.
											cbn.
											destruct (beqAddr pdinsertion (CPaddr (freeslotaddr + sh1offset))) eqn:beqpdfreesh1 ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfreesh1.
											rewrite <- beqpdfreesh1 in *.
											unfold isFreeSlot in *.
											unfold isPDT in *.
											destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite removeDupIdentity ; try congruence.
											rewrite <- beqAddrFalse in *.
											rewrite removeDupIdentity ; try congruence.
											destruct (lookup (CPaddr (freeslotaddr + sh1offset)) (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
											destruct (beqAddr sceaddr (CPaddr (freeslotaddr + scoffset))) eqn:beqscefssc ; try(exfalso ; congruence).
											(* show sceaddr must be equal to freeslot which is false *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefssc.
											assert(HSCEOffset : sceaddr = CPaddr (newBlockEntryAddr + scoffset)) by intuition.
											rewrite HSCEOffset in beqscefssc.
											contradict beqscefssc.
											unfold nullAddrExists in *. unfold isPADDR in *.
											unfold CPaddr.
											destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
											* destruct (le_dec (freeslotaddr + scoffset) maxAddr) eqn:Hk.
												** simpl in *. intro Hfalse.
													inversion Hfalse as [Heq].
													rewrite PeanoNat.Nat.add_cancel_r in Heq.
													apply CPaddrInjectionNat in Heq.
													repeat rewrite paddrEqId in Heq.
													congruence.
												** 	intro Hfalse.
														inversion Hfalse as [Heq].
														assert(HeqNull : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
														{ rewrite nullAddrIs0.
															apply CPaddrInjectionNat in Heq.
															intuition.
														}
														rewrite HeqNull in *.
														rewrite HSCEOffset in *.
														unfold isSCE in *.
														destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
														destruct v ; try(exfalso ; congruence).
											* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
												{ rewrite nullAddrIs0.
													unfold CPaddr. rewrite Hj.
													destruct (le_dec 0 maxAddr) ; intuition.
													f_equal. apply proof_irrelevance.
												}
												rewrite Heq in *.
												rewrite HSCEOffset in *.
												unfold isSCE in *.
												destruct (lookup nullAddr (memory s) beqAddr) ; try(exfalso ; congruence).
												destruct v ; try(exfalso ; congruence).
											* destruct (beqAddr newBlockEntryAddr (CPaddr (freeslotaddr + scoffset))) eqn:beqnewBfssc ; try(exfalso ; congruence).
												------- (* newBlockEntryAddr = (CPaddr (freeslotaddr + scoffset)) *)
																rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewBfssc.
																rewrite <- beqnewBfssc in *.
																destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																destruct v ; try(exfalso ; congruence).
												------- (* newBlockEntryAddr <> (CPaddr (freeslotaddr + scoffset)) *)
																rewrite <- beqAddrFalse in *.
																repeat rewrite removeDupIdentity ; try congruence.
																destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf; try(exfalso ; congruence).
																rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
																rewrite <- beqAddrFalse in *.
																repeat rewrite removeDupIdentity ; try congruence.
																cbn.
																destruct (beqAddr pdinsertion (CPaddr (freeslotaddr + scoffset))) eqn:beqpdfssc ; try (exfalso ; congruence).
																-------- (* pdinsertion = (CPaddr (freeslotaddr + scoffset)) *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfssc.
																					rewrite <- beqpdfssc in *.
																					destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
																					destruct v ; try(exfalso ; congruence).
																-------- (* pdinsertion <> (CPaddr (freeslotaddr + scoffset)) *)
																					rewrite <- beqAddrFalse in *.
																					repeat rewrite removeDupIdentity ; try congruence.
																					destruct (lookup (CPaddr (freeslotaddr + scoffset)) (memory s0) beqAddr) eqn:Hlookupsc ; try(exfalso ; congruence).
																					destruct v ; try(exfalso ; congruence).
																					intuition.
											* intro Hf. rewrite <- beqAddrFalse in *. congruence.
} (* end of freeSlotsListIsFreeSlot *)


assert(HDisjointFreeSlotsListss : DisjointFreeSlotsLists s).
{ (* DisjointFreeSlotsLists s *)
	unfold DisjointFreeSlotsLists.
	intros pd1 pd2 HPDTpd1 HPDTpd2 Hpd1pd2NotEq.

	assert(Hcons0 : DisjointFreeSlotsLists s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold DisjointFreeSlotsLists in Hcons0.

	(* we must show all free slots list are disjoint
		check all possible values for pd1 AND pd2 in the modified state s
			-> only possible is pdinsertion
				1) - if pd1 = pdinsertion:
						-> show the pd1's new free slots list is a subset of the initial free slots list
								and that pd2's free slots list is identical at s and s0,
							-> if they were disjoint at s0, they are still disjoint at s -> OK
				2) - if pd1 <> pdinsertion, it is another pd, but pd2 could be pdinsertion
						3) - if pd2 = pdinsertion:
								same proof as with pd1
						4) - if pd2 <> pdinsertion: prove pd1's free slots list and pd2's free slot list
								have NOT changed in the modified state, so they are still disjoint
									-> compute the list at each modified state and check not changed from s0 -> OK
*)
	(* Check all values for pd1 and pd2 except pdinsertion *)
	destruct (beqAddr sceaddr pd1) eqn:beqscepd1; try(exfalso ; congruence).
	-	(* sceaddr = pd1 *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd1.
		rewrite <- beqscepd1 in *.
		unfold isSCE in *.
		unfold isPDT in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> pd1 *)
		destruct (beqAddr newBlockEntryAddr pd1) eqn:beqnewpd1 ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = pd1 *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd1.
				rewrite <- beqnewpd1 in *.
				unfold isBE in *.
				unfold isPDT in *.
				destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> pd1 *)
				destruct (beqAddr sceaddr pd2) eqn:beqscepd2; try(exfalso ; congruence).
				---	(* sceaddr = pd2 *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd2.
						rewrite <- beqscepd2 in *.
						unfold isSCE in *.
						unfold isPDT in *.
						destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				---	(* sceaddr <> pd2 *)
						destruct (beqAddr newBlockEntryAddr pd2) eqn:beqnewpd2 ; try(exfalso ; congruence).
					---- (* newBlockEntryAddr = pd2 *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd2.
								rewrite <- beqnewpd2 in *.
								unfold isPDT in *.
								unfold isBE in *.
								destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
					---- (* newBlockEntryAddr <> pd2 *)
								destruct (beqAddr pdinsertion pd1) eqn:beqpdpd1; try(exfalso ; congruence).
								----- (* 1) pdinsertion = pd1 *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd1.
										rewrite <- beqpdpd1 in *.
										destruct (beqAddr pdinsertion pd2) eqn:beqpdpd2; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd2. congruence.
										(* DUP *)
										assert(Hlookuppd2Eq : lookup pd2 (memory s) beqAddr = lookup pd2 (memory s0) beqAddr).
										{
											rewrite Hs. unfold isPDT.
											cbn. rewrite beqAddrTrue.
											rewrite beqscepd2.
											assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
											rewrite HnewBsceNotEq. (*newBlock <> sce *)
											assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
											rewrite HpdnewBNotEq. (*pd <> newblock*)
											cbn.
											rewrite beqnewpd2.
											rewrite beqAddrTrue.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity ; intuition.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
											cbn.
											destruct (beqAddr pdinsertion pd2) eqn:Hff ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity ; intuition.
										}
										assert(HPDTpd2Eq : isPDT pd2 s = isPDT pd2 s0).
										{ unfold isPDT. rewrite Hlookuppd2Eq. intuition. }
										assert(HPDTpd2s0 : isPDT pd2 s0) by (rewrite HPDTpd2Eq in * ; assumption).
										specialize(Hcons0 pdinsertion pd2 HPDTs0 HPDTpd2s0 Hpd1pd2NotEq).
										destruct Hcons0 as [listoption1 (listoption2 & (Hoptionlist1s0 & (Hwellformed1s0 & (Hoptionlist2s0 & (Hwellformed2s0 & HDisjoints0)))))].
										(* Show equality for pd2's free slot list
												so between listoption2 at s and listoption2 at s0 *)
										unfold getFreeSlotsList in Hoptionlist2s0.
										apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].
										rewrite Hlookuppd2s0 in *.
										destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
										------ (* listoption2 = NIL *)
													destruct H31 as [Hoptionlists (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
													exists Hoptionlists.
													exists listoption2.
													assert(Hlistoption2s : getFreeSlotsList pd2 s = nil).
													{
														unfold getFreeSlotsList.
														rewrite Hlookuppd2Eq. rewrite Hpd2Null. reflexivity.
													}
													rewrite Hlistoption2s in *.
													intuition.
													unfold getFreeSlotsList. rewrite Hpdinsertions.
													rewrite HnewFirstFree.
													assert(Hnbleft : nbfreeslots pdentry1 = nbleft).
													{ (* DUP *)
														subst pdentry1. simpl. intuition.
														rewrite H30. (* nbleft = CIndex (currnbfreeslots - 1)*)
														destruct predCurrentNbFreeSlots.
														unfold StateLib.Index.pred in H1.
														destruct (gt_dec currnbfreeslots 0); try (exfalso ; congruence).
														unfold CIndex. inversion H1 as [Hpred].
														rewrite Hpred. destruct (le_dec i maxIdx) ; try(exfalso ; congruence).
														f_equal. apply proof_irrelevance.
													}
													rewrite Hnbleft.
													assert(HfreeSlotsListEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s nbleft).
													{ intuition.
														rewrite <- H34. (* getFreeSlotsList s = Hoptionlists *)
														eapply getFreeSlotsListRecEqN ; intuition.
													}
													rewrite <- HfreeSlotsListEq.
													destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
													------- (* newFirstFreeSlotAddr = nullAddr *)
																	rewrite <- DependentTypeLemmas.beqAddrTrue in beqfirstnull.
																	rewrite beqfirstnull in *.
																	intuition.
																	assert(Hoption :  Hoptionlists = getFreeSlotsListRec n0 nullAddr s0 nbleft) by intuition.
																	rewrite FreeSlotsListRec_unroll in Hoption.
																	unfold getFreeSlotsListAux in Hoption.
																	destruct n0.
																	rewrite Hoption in *. cbn in *. congruence.
																	destruct (StateLib.Index.ltb nbleft zero).
																	rewrite Hoption in *. cbn in *. congruence.
																	assert(HNullAddrExistss0 : nullAddrExists s0)
																			by (unfold consistency in * ; unfold consistency1 in * ; intuition).
																	unfold nullAddrExists in *.
																	unfold isPADDR in *.
																	destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																	destruct v ; try(exfalso ; congruence).
																	destruct (beqAddr p nullAddr).
																	rewrite Hoption in *. cbn in *. congruence.
																	rewrite Hoption in *. cbn in *. congruence.
													------- (* newFirstFreeSlotAddr <> nullAddr *)
																	intuition.
													------- (* Disjoint : listoption2 = NIL *)
																	subst listoption2. cbn.
																	unfold Lib.disjoint. intuition.
										------ (* listoption2 <> NIL *)
														(* show equality between listoption2 at s and s0 
																+ if listoption2 has NOT changed, listoption1 at s is
																just a subset of listoption1 at s0 so they are
																still disjoint *)
														assert(Hfreeslotspd2Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots pd2entry) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot pd2entry) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry)).
	{
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry)).
	{
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot pd2entry *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
						rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hoptionlist1s0 in *.
									cbn in *.
									unfold Lib.disjoint in HDisjoints0.
									specialize(HDisjoints0 newBlockEntryAddr).
									simpl in HDisjoints0.
									intuition.
							*** rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									exfalso ; congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)

					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
						rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hoptionlist1s0 in *.
									cbn in *.
									unfold Lib.disjoint in HDisjoints0.
									specialize(HDisjoints0 newBlockEntryAddr).
									simpl in HDisjoints0.
									intuition.
							*** rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									exfalso ; congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
						rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hoptionlist1s0 in *.
									cbn in *.
									unfold Lib.disjoint in HDisjoints0.
									specialize(HDisjoints0 newBlockEntryAddr).
									simpl in HDisjoints0.
									intuition.
							*** rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									exfalso ; congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
						rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							cbn in *.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									rewrite Hoptionlist1s0 in *.
									cbn in *.
									unfold Lib.disjoint in HDisjoints0.
									specialize(HDisjoints0 newBlockEntryAddr).
									simpl in HDisjoints0.
									intuition.
							*** rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									exfalso ; congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *. rewrite Hpd2Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s10 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
						{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
							destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
							cbn.
							destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
							rewrite beqAddrTrue.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
						}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots pd2entry <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
										destruct Hfreeslotspd2Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																			(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
										assert(HsEq : s10 = s).
										{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
											subst s7. subst s8. subst s9. subst s10.
											rewrite Hs. f_equal.
										}
										rewrite HsEq in *.
										(* listoption2 didn't change *)
										assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot pd2entry) s (nbfreeslots pd2entry) =
																					getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
										{
											intuition.
											subst nbleft.
											(* rewrite all previous getFreeSlotsListRec equalities *)
											rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40.
											rewrite <- H42. rewrite <- H44. rewrite <- H46. rewrite <- H48.
											rewrite <- H50. rewrite <- H53.
											reflexivity.
										}
										assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot pd2entry) s (nbfreeslots pd2entry)
																							= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s (nbfreeslots pd2entry)).
										{ eapply getFreeSlotsListRecEqN ; intuition.
											subst nbleft. lia.
											assert (HnbLtmaxIdx : nbfreeslots pd2entry <= maxIdx) by apply IdxLtMaxIdx.
											lia.
										}
										unfold getFreeSlotsList in *.
										rewrite Hlookuppd2Eq in *.
										rewrite Hpdinsertions0 in *. rewrite Hpdinsertions.
										rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq.
										rewrite HnewFirstFree.
										rewrite <- HnewB in *.
										destruct(beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										destruct(beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hff ; try(exfalso ; congruence).
										destruct H31 as [Hoptionlists (olds & (n0' & (n1' & (n2' & (nbleft' & Hfreeslotsolds')))))].
										exists Hoptionlists. exists listoption2.
										destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
										------- (* newFirstFreeSlotAddr = nullAddr *)
														rewrite <- DependentTypeLemmas.beqAddrTrue in beqfirstnull.
														rewrite beqfirstnull in *.
														assert(HoptionlistsNull : Hoptionlists = nil).
														{
															intuition.
															assert(Hoption :  Hoptionlists = getFreeSlotsListRec n0' nullAddr s0 nbleft') by intuition.
															rewrite FreeSlotsListRec_unroll in Hoption.
															unfold getFreeSlotsListAux in Hoption.
															destruct n0'.
															rewrite Hoption in *. cbn in *. congruence.
															destruct (StateLib.Index.ltb nbleft' zero).
															rewrite Hoption in *. cbn in *. congruence.
															assert(HNullAddrExistss0 : nullAddrExists s0)
																	by (unfold consistency in * ; unfold consistency1 in * ; intuition).
															unfold nullAddrExists in *.
															unfold isPADDR in *.
															destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
															destruct v ; try(exfalso ; congruence).
															rewrite beqAddrTrue in Hoption.
															rewrite Hoption in *. cbn in *. congruence.
														}
														intuition.
														rewrite HoptionlistsNull in *.
														unfold Lib.disjoint. intros. intuition.
										------- (* newFirstFreeSlotAddr <> nullAddr *)
														assert(HoptionlistEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s (nbfreeslots pdentry1)).
														{ subst pdentry1. (* pdentry1 *) cbn.
														assert(HpredNbLeftEq : predCurrentNbFreeSlots = nbleft').
														{ intuition. subst nbleft'. unfold StateLib.Index.pred in *.
															destruct (gt_dec currnbfreeslots 0) ; intuition.
															inversion H1. (* Some ... = Some predCurrentNbFreeSlots *)
															unfold CIndex.
															assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
															{ 
																assert(HcurrLtmaxIdx : currnbfreeslots <= maxIdx).
																{ intuition. apply IdxLtMaxIdx. }
																lia.
															}
															destruct (le_dec (currnbfreeslots - 1) maxIdx) ; intuition.
															f_equal. apply proof_irrelevance.
														}
														rewrite HpredNbLeftEq.
														assert(HoptionlistEq : getFreeSlotsListRec n2' newFirstFreeSlotAddr s nbleft' = Hoptionlists) by intuition.
														rewrite <- HoptionlistEq. (* n2 s = Hoptionlist *)
														eapply getFreeSlotsListRecEqN ; intuition.
														}
														(* we know listoption2 and Hoptionlist haven't changed
																and as Hoptionlist is a subset of listoption1
															and from the beginning they were disjoint, so still disjoint at s *)
														assert(HIncl : incl (filterOptionPaddr Hoptionlists) (filterOptionPaddr listoption1)).
														{
															rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
															unfold getFreeSlotsListAux in Hoptionlist1s0.
															assert(HMaxIdxNext : maxIdx + 1 = S maxIdx).
															{ lia. }
															rewrite HMaxIdxNext in *.
															assert(Hnbfreeslots : (nbfreeslots pdentry) = currnbfreeslots).
															{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
															rewrite Hnbfreeslots in *.
															destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
															* unfold StateLib.Index.ltb in Hltb.
																apply PeanoNat.Nat.ltb_lt in Hltb.
																contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
															* rewrite HlookupnewBs0 in *.
																destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
																assert(Hoptionlists0 : Hoptionlists =
                  												getFreeSlotsListRec n0' newFirstFreeSlotAddr s0 nbleft') by intuition.
																rewrite Hoptionlists0.
																assert(HnewBEndIsNewFirst : (endAddr (blockrange bentry)) = newFirstFreeSlotAddr).
																{ unfold bentryEndAddr in *. rewrite HlookupnewBs0 in *. intuition. }
																rewrite HnewBEndIsNewFirst in *.
																assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
																{
																		unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *.
																		destruct currnbfreeslots.
																		+ simpl. destruct i0.
																			* simpl. apply maxIdxNotZero.
																			* cbn. rewrite PeanoNat.Nat.sub_0_r. intuition.
																}
																assert((CIndex (currnbfreeslots - 1)) = i).
																{ unfold CIndex.
																	destruct (le_dec (currnbfreeslots - 1) maxIdx) ; simpl in * ; intuition ; try(exfalso ; congruence).
																		unfold StateLib.Index.pred in *.
																		destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
																		inversion Hpred. f_equal. apply proof_irrelevance.
																}
																unfold pdentryNbFreeSlots in *. rewrite H5 in *.
																rewrite H8 in *.
																assert(i < maxIdx).
																{	unfold StateLib.Index.pred in *.
																	destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
																	inversion Hpred. simpl. intuition.
																}
																assert(HEq : getFreeSlotsListRec maxIdx newFirstFreeSlotAddr s0 i =
																								getFreeSlotsListRec (maxIdx+1) newFirstFreeSlotAddr s0 i).
																{
																	eapply getFreeSlotsListRecEqN ; intuition.
																}
																rewrite HEq in *.
																subst nbleft. subst listoption1.
																assert(HnbleftEq': nbleft' = i).
																{ intuition. subst nbleft'. intuition. }
																rewrite HnbleftEq' in *.
																assert(HEq' : getFreeSlotsListRec n0' newFirstFreeSlotAddr s0 i =
																										getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s0 i).
																{
																	eapply getFreeSlotsListRecEqN ; intuition.
																	{ lia. }
																}
																rewrite HEq'. intuition.
																cbn. intuition.
														}
														intuition.
														eapply Lib.inclDisjoint.
														apply HDisjoints0. intuition. intuition.
									----- (* 2) pdinsertion <> pd1 *)
											(* similarly, we must prove optionfreeslotslist1 is strictly
													the same at s than at s0 by recomputing each
													intermediate steps and check at that time *)
											assert(Hlookuppd1Eq : lookup pd1 (memory s) beqAddr = lookup pd1 (memory s0) beqAddr).
											{
												rewrite Hs.
												cbn. rewrite beqAddrTrue.
												rewrite beqscepd1.
												assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
												rewrite HnewBsceNotEq. (*newBlock <> sce *)
												cbn.
												rewrite beqnewpd1. (*pd1 <> newblock*)
												rewrite beqAddrTrue.
												rewrite <- beqAddrFalse in *.
												repeat rewrite removeDupIdentity ; intuition.
												destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
												cbn.
												destruct (beqAddr pdinsertion pd1) eqn:Hff ; try(exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
												rewrite <- beqAddrFalse in *.
												repeat rewrite removeDupIdentity ; intuition.
											}
										assert(HPDTpd1Eq : isPDT pd1 s = isPDT pd1 s0).
										{ unfold isPDT. rewrite Hlookuppd1Eq. intuition. }
										assert(HPDTpd1s0 : isPDT pd1 s0) by (rewrite HPDTpd1Eq in * ; assumption).
											(* DUP of previous steps to show strict equality of listoption2
												at s and s0 *)
										destruct (beqAddr pdinsertion pd2) eqn:beqpdpd2; try(exfalso ; congruence).
										------ (* 3) pdinsertion = pd2 *)
													(* DUP of pdinsertion = pd1 *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd2.
													rewrite <- beqpdpd2 in *.
													(* DUP with pd1 instead of pd2 *)
													assert(Hpd1pd2NotEq' : pdinsertion <> pd1 ) by intuition.
													specialize(Hcons0 pdinsertion pd1 HPDTs0 HPDTpd1s0 Hpd1pd2NotEq').
													destruct Hcons0 as [listoption1 (listoption2 & (Hoptionlist1s0 & (Hwellformed1s0 & (Hoptionlist2s0 & (Hwellformed2s0 & HDisjoints0)))))].
													(* Show equality between listoption2 at s and listoption2 at s0 *)
													unfold getFreeSlotsList in Hoptionlist2s0.
													apply isPDTLookupEq in HPDTpd1s0. destruct HPDTpd1s0 as [pd1entry Hlookuppd1s0].
													rewrite Hlookuppd1s0 in *.
													destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:Hpd1Null ; try(exfalso ; congruence).
													------- (* listoption2 = NIL *)
																destruct H31 as [Hoptionlists (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
																exists listoption2. exists Hoptionlists.
																assert(Hlistoption2s : getFreeSlotsList pd1 s = nil).
																{
																	unfold getFreeSlotsList.
																	rewrite Hlookuppd1Eq. rewrite Hpd1Null. reflexivity.
																}
																rewrite Hlistoption2s in *. intuition.
																unfold getFreeSlotsList. rewrite Hpdinsertions.
																rewrite HnewFirstFree.
																assert(Hnbleft : nbfreeslots pdentry1 = nbleft).
																{ (* DUP *)
																	subst pdentry1. simpl. intuition.
																	rewrite H30. (* nbleft = CIndex (currnbfreeslots - 1)*)
																	destruct predCurrentNbFreeSlots.
																	unfold StateLib.Index.pred in H1.
																	destruct (gt_dec currnbfreeslots 0); try (exfalso ; congruence).
																	unfold CIndex. inversion H1 as [Hpred].
																	rewrite Hpred. destruct (le_dec i maxIdx) ; try(exfalso ; congruence).
																	f_equal. apply proof_irrelevance.
																}
																rewrite Hnbleft.
																assert(HfreeSlotsListEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s nbleft).
																{ intuition.
																	rewrite <- H34. (* getFreeSlotsList s = Hoptionlists *)
																	eapply getFreeSlotsListRecEqN ; intuition.
																}
																rewrite <- HfreeSlotsListEq.
																destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
																-------- (* newFirstFreeSlotAddr = nullAddr *)
																				rewrite <- DependentTypeLemmas.beqAddrTrue in beqfirstnull.
																				rewrite beqfirstnull in *.
																				intuition.
																				assert(Hoption :  Hoptionlists = getFreeSlotsListRec n0 nullAddr s0 nbleft) by intuition.
																				rewrite FreeSlotsListRec_unroll in Hoption.
																				unfold getFreeSlotsListAux in Hoption.
																				destruct n0.
																				rewrite Hoption in *. cbn in *. congruence.
																				destruct (StateLib.Index.ltb nbleft zero).
																				rewrite Hoption in *. cbn in *. congruence.
																				assert(HNullAddrExistss0 : nullAddrExists s0)
																						by (unfold consistency in * ; unfold consistency1 in * ; intuition).
																				unfold nullAddrExists in *.
																				unfold isPADDR in *.
																				destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																				destruct v ; try(exfalso ; congruence).
																				destruct (beqAddr p nullAddr).
																				rewrite Hoption in *. cbn in *. congruence.
																				rewrite Hoption in *. cbn in *. congruence.
																-------- (* newFirstFreeSlotAddr <> nullAddr *)
																				intuition.
																-------- (* Disjoint : listoption2 = NIL *)
																				subst listoption2. cbn.
																				unfold Lib.disjoint. intuition.
													------- (* listoption2 <> NIL *)
																	(* show equality between listoption2 at s and s0 
																			+ if listoption2 has NOT changed, listoption1 at s is
																			just a subset of listoption1 at s0 so they are
																			still disjoint *)
																	assert(Hfreeslotspd1Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots pd1entry) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd1entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot pd1entry) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot pd1entry) s1 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s0 (nbfreeslots pd1entry)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s2 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s1 (nbfreeslots pd1entry)).
	{
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s3 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s2 (nbfreeslots pd1entry)).
	{
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot pd1entry *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s4 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s3 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s5 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s4 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s6 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s5 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s7 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s6 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s8 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s7 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s9 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s8 (nbfreeslots pd1entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							unfold getFreeSlotsList in Hoptionlist1s0.
							unfold getFreeSlotsList in Hoptionlist2s0.
							rewrite Hpdinsertions0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									cbn in *.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											rewrite Hoptionlist1s0 in *.
											cbn in *.
											unfold Lib.disjoint in HDisjoints0.
											specialize(HDisjoints0 newBlockEntryAddr).
											simpl in HDisjoints0.
											intuition.
									*** rewrite Hoptionlist1s0 in *.
											cbn in Hwellformed1s0.
											exfalso ; congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd1s0 in *. rewrite Hpd1Null in *.
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					unfold getFreeSlotsList in Hoptionlist1s0.
					unfold getFreeSlotsList in Hoptionlist2s0.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
								cbn in *.
								congruence.
						** (* N>0 *)
								clear IHn.
								simpl. rewrite HlookupnewBs0.
								assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
								{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
								rewrite <- HcurrNb in *.
								destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred ; try(exfalso ; congruence).
								rewrite <- HcurrNb in *. rewrite Hpred. cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s10 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s9 (nbfreeslots pd1entry)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
	}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots pd1entry <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
									destruct Hfreeslotspd1Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																		(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
									assert(HsEq : s10 = s).
									{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
										subst s7. subst s8. subst s9. subst s10.
										rewrite Hs. f_equal.
									}
									rewrite HsEq in *.
									assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot pd1entry) s (nbfreeslots pd1entry) =
																				getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd1entry) s0 (nbfreeslots pd1entry)).
									{
										intuition.
										subst nbleft.
										(* rewrite all previous getFreeSlotsListRec equalities *)
										rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40.
										rewrite <- H42. rewrite <- H44. rewrite <- H46. rewrite <- H48.
										rewrite <- H50. rewrite <- H53.
										reflexivity.
									}
									assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot pd1entry) s (nbfreeslots pd1entry)
																						= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s (nbfreeslots pd1entry)).
									{ eapply getFreeSlotsListRecEqN ; intuition.
										subst nbleft. lia.
										assert (HnbLtmaxIdx : nbfreeslots pd1entry <= maxIdx) by apply IdxLtMaxIdx.
										lia.
									}
									unfold getFreeSlotsList in *.
									rewrite Hlookuppd1Eq in *.
									rewrite Hpdinsertions0 in *. rewrite Hpdinsertions.
									rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq.
									rewrite HnewFirstFree.
									rewrite <- HnewB in *.
									destruct(beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									destruct(beqAddr (firstfreeslot pd1entry) nullAddr) eqn:Hff ; try(exfalso ; congruence).
									destruct H31 as [Hoptionlists (olds & (n0' & (n1' & (n2' & (nbleft' & Hfreeslotsolds')))))].
									exists listoption2. exists Hoptionlists. (* inverse as we treat pd2 and not pd1 *)
									destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
									-------- (* newFirstFreeSlotAddr = nullAddr *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqfirstnull.
													rewrite beqfirstnull in *.
													assert(HoptionlistsNull : Hoptionlists = nil).
													{
														intuition.
														assert(Hoption :  Hoptionlists = getFreeSlotsListRec n0' nullAddr s0 nbleft') by intuition.
														rewrite FreeSlotsListRec_unroll in Hoption.
														unfold getFreeSlotsListAux in Hoption.
														destruct n0'.
														rewrite Hoption in *. cbn in *. congruence.
														destruct (StateLib.Index.ltb nbleft' zero).
														rewrite Hoption in *. cbn in *. congruence.
														assert(HNullAddrExistss0 : nullAddrExists s0)
																by (unfold consistency in * ; unfold consistency1 in * ; intuition).
														unfold nullAddrExists in *.
														unfold isPADDR in *.
														destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
														destruct v ; try(exfalso ; congruence).
														rewrite beqAddrTrue in Hoption.
														rewrite Hoption in *. cbn in *. congruence.
													}
													intuition.
													rewrite HoptionlistsNull in *.
													unfold Lib.disjoint. intros. intuition.
									-------- (* newFirstFreeSlotAddr <> nullAddr *)
													assert(HoptionlistEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s (nbfreeslots pdentry1)).
													{ subst pdentry1. (* pdentry1 *) cbn.
													assert(HpredNbLeftEq : predCurrentNbFreeSlots = nbleft').
													{ intuition. subst nbleft'. unfold StateLib.Index.pred in *.
														destruct (gt_dec currnbfreeslots 0) ; intuition.
														inversion H1. (* Some ... = Some predCurrentNbFreeSlots *)
														unfold CIndex.
														assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
														{ 
															assert(HcurrLtmaxIdx : currnbfreeslots <= maxIdx).
															{ intuition. apply IdxLtMaxIdx. }
															lia.
														}
														destruct (le_dec (currnbfreeslots - 1) maxIdx) ; intuition.
														f_equal. apply proof_irrelevance.
													}
													rewrite HpredNbLeftEq.
													assert(HoptionlistEq : getFreeSlotsListRec n2' newFirstFreeSlotAddr s nbleft' = Hoptionlists) by intuition.
													rewrite <- HoptionlistEq. (* n2 s = Hoptionlist *)
													eapply getFreeSlotsListRecEqN ; intuition.
													}
													(* we know listoption2 and Hoptionlist haven't changed
															and as Hoptionlist is a subset of listoption1
														and from the beginning they were disjoint, so still disjoint  *)
													assert(HIncl : incl (filterOptionPaddr Hoptionlists) (filterOptionPaddr listoption1)).
													{
														rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
														unfold getFreeSlotsListAux in Hoptionlist1s0.
														assert(HMaxIdxNext : maxIdx + 1 = S maxIdx).
														{ lia. }
														rewrite HMaxIdxNext in *.
														assert(Hnbfreeslots : (nbfreeslots pdentry) = currnbfreeslots).
														{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
														rewrite Hnbfreeslots in *.
														destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
														* unfold StateLib.Index.ltb in Hltb.
															apply PeanoNat.Nat.ltb_lt in Hltb.
															contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
														* rewrite HlookupnewBs0 in *.
															destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
															assert(Hoptionlists0 : Hoptionlists =
                												getFreeSlotsListRec n0' newFirstFreeSlotAddr s0 nbleft') by intuition.
															rewrite Hoptionlists0.
															assert(HnewBEndIsNewFirst : (endAddr (blockrange bentry)) = newFirstFreeSlotAddr).
															{ unfold bentryEndAddr in *. rewrite HlookupnewBs0 in *. intuition. }
															rewrite HnewBEndIsNewFirst in *.
															assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
															{
																	unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *.
																	destruct currnbfreeslots.
																	+ simpl. destruct i0.
																		* simpl. apply maxIdxNotZero.
																		* cbn. rewrite PeanoNat.Nat.sub_0_r. intuition.
															}
															assert((CIndex (currnbfreeslots - 1)) = i).
															{ unfold CIndex.
																destruct (le_dec (currnbfreeslots - 1) maxIdx) ; simpl in * ; intuition ; try(exfalso ; congruence).
																	unfold StateLib.Index.pred in *.
																	destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
																	inversion Hpred. f_equal. apply proof_irrelevance.
															}
															unfold pdentryNbFreeSlots in *. rewrite H5 in *.
															rewrite H8 in *.
															assert(i < maxIdx).
															{	unfold StateLib.Index.pred in *.
																destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
																inversion Hpred. simpl. intuition.
															}
															assert(HEq : getFreeSlotsListRec maxIdx newFirstFreeSlotAddr s0 i =
																							getFreeSlotsListRec (maxIdx+1) newFirstFreeSlotAddr s0 i).
															{
																eapply getFreeSlotsListRecEqN ; intuition.
															}
															rewrite HEq in *.
															subst nbleft. subst listoption1.
															assert(HnbleftEq': nbleft' = i).
															{ intuition. subst nbleft'. intuition. }
															rewrite HnbleftEq' in *.
															assert(HEq' : getFreeSlotsListRec n0' newFirstFreeSlotAddr s0 i =
																									getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s0 i).
															{
																eapply getFreeSlotsListRecEqN ; intuition.
																{ lia. }
															}
															rewrite HEq'. intuition.
															cbn. intuition.
													}
													intuition. apply Lib.disjointPermut.
													eapply Lib.inclDisjoint.
													apply HDisjoints0. intuition. intuition.

										------ (* 4) pdinsertion <> pd2 *)
														(* show strict equality of listoption1 at s and s0
																and listoption2 at s and s0 because no list changed 
																	as only pdinsertion's free slots list changed *)
														(* DUP *)
														(* show list equality between s0 and s*)
														(* similarly, we must prove optionfreeslotslist1 
															and optionfreeslotslist2 are strictly
															the same at s than at s0 by recomputing each
															intermediate steps and check at that time *)
														assert(Hlookuppd2Eq : lookup pd2 (memory s) beqAddr = lookup pd2 (memory s0) beqAddr).
														{
															rewrite Hs.
															cbn. rewrite beqAddrTrue.
															rewrite beqscepd2.
															assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
															rewrite HnewBsceNotEq. (*newBlock <> sce *)
															cbn.
															rewrite beqnewpd2. (*pd2 <> newblock*)
															rewrite beqAddrTrue.
															rewrite <- beqAddrFalse in *.
															repeat rewrite removeDupIdentity ; intuition.
															destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
															rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
															cbn.
															destruct (beqAddr pdinsertion pd2) eqn:Hff ; try(exfalso ; congruence).
															rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
															rewrite <- beqAddrFalse in *.
															repeat rewrite removeDupIdentity ; intuition.
														}
														assert(HPDTpd2Eq : isPDT pd2 s = isPDT pd2 s0).
														{ unfold isPDT. rewrite Hlookuppd2Eq. intuition. }
														assert(HPDTpd2s0 : isPDT pd2 s0) by (rewrite HPDTpd2Eq in * ; assumption).
															(* DUP of previous steps to show strict equality of listoption2
																at s and s0 *)
														specialize (Hcons0 pd1 pd2 HPDTpd1s0 HPDTpd2s0 Hpd1pd2NotEq).
														destruct Hcons0 as [listoption1 (listoption2 & (Hoptionlist1s0 & (Hwellformed1s0 & (Hoptionlist2s0 & (Hwellformed2s0 & HDisjoints0)))))].
														assert(Hpdpd1NotEq : pdinsertion <> pd1) by (rewrite <- beqAddrFalse in * ; intuition).
														assert(Hpdpd2NotEq : pdinsertion <> pd2) by (rewrite <- beqAddrFalse in * ; intuition).
														assert(HDisjointpdpd1s0 : DisjointFreeSlotsLists s0)
															by (unfold consistency in * ; unfold consistency1 in * ; intuition).
														unfold DisjointFreeSlotsLists in *.
														specialize (HDisjointpdpd1s0 pdinsertion pd1 HPDTs0 HPDTpd1s0 Hpdpd1NotEq).
														assert(HDisjointpdpd2s0 : DisjointFreeSlotsLists s0)
															by (unfold consistency in * ; unfold consistency1 in * ; intuition).
														unfold DisjointFreeSlotsLists in *.
														specialize (HDisjointpdpd2s0 pdinsertion pd2 HPDTs0 HPDTpd2s0 Hpdpd2NotEq).

														(* Show equality between listoption1 at s and listoption1 at s0 *)
														unfold getFreeSlotsList in Hoptionlist1s0.
														apply isPDTLookupEq in HPDTpd1s0. destruct HPDTpd1s0 as [pd1entry Hlookuppd1s0].
														rewrite Hlookuppd1s0 in *.
														destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:Hpd1Null ; try(exfalso ; congruence).
														------- (* listoption1 = NIL *)
																	exists listoption1. exists listoption2.
																	assert(Hlistoption1s : getFreeSlotsList pd1 s = nil).
																	{
																		unfold getFreeSlotsList.
																		rewrite Hlookuppd1Eq. rewrite Hpd1Null. reflexivity.
																	}
																	rewrite Hlistoption1s in *. intuition.
																	unfold getFreeSlotsList in *. rewrite Hlookuppd2Eq in *.
																	apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].
																	rewrite Hlookuppd2s0 in *.
																	destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
																	-------- (* (firstfreeslot pd2entry) = nullAddr *)
																					intuition.
																	-------- (* (firstfreeslot pd2entry) <> nullAddr *)
																		(* show equality between listoption2 at s and s0
																				-> if listoption2 has NOT changed, they are
																				still disjoint at s because lisoption1 is NIL *)
assert(Hfreeslotspd2Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots pd2entry) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot pd2entry) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry)).
	{
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry)).
	{
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot pd2entry *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd1Eq in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist2s0 in *.
									cbn in Hwellformed2s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd1Eq in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist2s0 in *.
									cbn in Hwellformed2s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd1Eq in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist2s0 in *.
									cbn in Hwellformed2s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd1Eq in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist2s0 in *.
									cbn in Hwellformed2s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry)).
	{
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd1Eq in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist2s0 in *.
									cbn in Hwellformed2s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1Eq in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist2s0 in *.
							cbn in Hwellformed2s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd2s0.
												specialize(HDisjointpdpd2s0 newBlockEntryAddr).
												simpl in HDisjointpdpd2s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd2s0.
												specialize(HDisjointpdpd2s0 newBlockEntryAddr).
												simpl in HDisjointpdpd2s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *. congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1Eq in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist2s0 in *.
							cbn in Hwellformed2s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd2s0.
												specialize(HDisjointpdpd2s0 newBlockEntryAddr).
												simpl in HDisjointpdpd2s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd2s0.
												specialize(HDisjointpdpd2s0 newBlockEntryAddr).
												simpl in HDisjointpdpd2s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
												cbn in *. congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2.
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s10 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots pd2entry <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
														destruct Hfreeslotspd2Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																							(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
														assert(HsEq : s10 = s).
														{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
															subst s7. subst s8. subst s9. subst s10.
															rewrite Hs. f_equal.
														}
														rewrite HsEq in *.
														assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot pd2entry) s (nbfreeslots pd2entry) =
																									getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
														{
															intuition.
															subst nbleft.
															(* rewrite all previous getFreeSlotsListRec equalities *)
															rewrite <- H33. rewrite <- H36. rewrite <- H38.
															rewrite <- H40. rewrite <- H42. rewrite <- H44.
															rewrite <- H46. rewrite <- H48. rewrite <- H50.
															rewrite <- H53.
															reflexivity.
														}
														assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot pd2entry) s (nbfreeslots pd2entry)
																											= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s (nbfreeslots pd2entry)).
														{ eapply getFreeSlotsListRecEqN ; intuition.
															subst nbleft. lia.
															assert (HnbLtmaxIdx : nbfreeslots pd2entry <= maxIdx) by apply IdxLtMaxIdx.
															lia.
														}
														rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq. intuition.

										------- (* listoption1 <> NIL *)
														(* show equality beween listoption1 at s0 and at s
																-> if equality, then show listoption2 has not changed either
																		-> if listoption1 and listoption2 stayed the same
																				and they were disjoint at s0, then they
																				are still disjoint at s*)

														assert(Hfreeslotspd1Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots pd1entry) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd1entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1(firstfreeslot pd1entry) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot pd1entry) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd1entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot pd1entry) s1 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s0 (nbfreeslots pd1entry)).
	{
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s2 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s1 (nbfreeslots pd1entry)).
	{
		apply getFreeSlotsListRecEqPDT.
		--- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				---- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				---- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		--- unfold isBE. unfold s1. cbn. rewrite beqAddrTrue. intuition.
		--- unfold isPADDR. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s3 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s2 (nbfreeslots pd1entry)).
	{
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot pd1entry *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s3. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s4 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s3 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s4. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s5 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s4 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s5. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s6 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s5 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s6. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s7 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s6 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s7. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s8 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s7 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s8. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s9 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s8 (nbfreeslots pd1entry)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].

					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					rewrite Hlookuppd1s0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					assert(HnewBFirstFrees0P : firstfreeslot pd1entry = newBlockEntryAddr) by intuition.
					rewrite HnewBFirstFrees0PDT in *.
					rewrite HnewBFirstFrees0P in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd1.
						unfold getFreeSlotsListAux in *.
						induction (maxIdx+1). (* false induction because of fixpoint constraints *)
						** (* N=0 -> NotWellFormed *)
							rewrite Hoptionlist1s0 in *.
							cbn in Hwellformed1s0.
							congruence.
						** (* N>0 *)
							clear IHn.
							rewrite HlookupnewBs0 in *.
							destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
							destruct (StateLib.Index.ltb (nbfreeslots pd1entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
							destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
							*** destruct (StateLib.Index.pred (nbfreeslots pd1entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *.
												unfold Lib.disjoint in HDisjointpdpd1s0.
												specialize(HDisjointpdpd1s0 newBlockEntryAddr).
												simpl in HDisjointpdpd1s0.
												intuition.
									**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd1.
												cbn in *. congruence.
			--- unfold isBE. unfold s9. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption1.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd1 pd1entry Hlookuppd1s0).
					destruct H_NoDups0 as [optionlist1 (Hoptionlist1 & HwellFormed1' & HNoDup1)].
					unfold getFreeSlotsList in Hoptionlist1.
					rewrite Hlookuppd1s0 in *.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr)  ; try(exfalso ; congruence).
					subst optionlist1. subst listoption1.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd1s0 as [optionfreeslotslistpd (optionfreeslotslistpd1 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & HDisjointpdpd1s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					rewrite Hlookuppd1s0 in *.
					unfold Lib.disjoint in HDisjointpdpd1s0.
					specialize(HDisjointpdpd1s0 newBlockEntryAddr).
					destruct (HDisjointpdpd1s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd1.
						destruct (beqAddr (firstfreeslot pd1entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s10 (nbfreeslots pd1entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s9 (nbfreeslots pd1entry)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd1 pd1entry Hlookuppd1s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots pd1entry <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
														destruct Hfreeslotspd1Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																													(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
														assert(HsEq : s10 = s).
														{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
															subst s7. subst s8. subst s9. subst s10.
															rewrite Hs. f_equal.
														}
														rewrite HsEq in *.
														assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot pd1entry) s (nbfreeslots pd1entry) =
																									getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd1entry) s0 (nbfreeslots pd1entry)).
														{
															intuition.
															subst nbleft.
															(* rewrite all previous getFreeSlotsListRec equalities *)
															rewrite <- H33. rewrite <- H36. rewrite <- H38.
															rewrite <- H40. rewrite <- H42. rewrite <- H44.
															rewrite <- H46. rewrite <- H48. rewrite <- H50.
															rewrite <- H53.
															reflexivity.
														}
														assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot pd1entry) s (nbfreeslots pd1entry)
																											= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd1entry) s (nbfreeslots pd1entry)).
														{ eapply getFreeSlotsListRecEqN ; intuition.
															subst nbleft. lia.
															assert (HnbLtmaxIdx : nbfreeslots pd1entry <= maxIdx) by apply IdxLtMaxIdx.
															lia.
														}
														(* specialize disjoint for pd1 and pd2 at s0 *)
														assert(HDisjointpd1pd2s0 : DisjointFreeSlotsLists s0)
															by (unfold consistency in * ; unfold consistency1 in * ; intuition).
														unfold DisjointFreeSlotsLists in *.
														assert(HPDTpd1s0 : isPDT pd1 s0) by (unfold isPDT ; rewrite Hlookuppd1s0 ; intuition).
														specialize (HDisjointpd1pd2s0 pd1 pd2 HPDTpd1s0 HPDTpd2s0 Hpd1pd2NotEq).
														apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].

														destruct HDisjointpd1pd2s0 as [optionfreeslotslistpd1 (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd1 & (Hwellformedpd1s0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0 & HDisjointpd1pd2s0)))))].
														(* we expect identical lists at s0 and s *)
														exists optionfreeslotslistpd1. exists optionfreeslotslistpd2.
														unfold getFreeSlotsList.
														unfold getFreeSlotsList in Hoptionfreeslotslistpd1.
														unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
														rewrite Hlookuppd1Eq. rewrite Hlookuppd2Eq.
														rewrite Hlookuppd1s0 in *.
														rewrite Hlookuppd2s0 in *.
														destruct (beqAddr (firstfreeslot pd1entry) nullAddr) eqn:HfirstfreeNullpd1 ; try(exfalso ; congruence).
														destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNullpd2 ; try(exfalso ; congruence).
														+ (* listoption2 = NIL *)
															(* always disjoint with nil *)
															subst optionfreeslotslistpd1.
															intuition.
															(* we are in the case listoption1 is equal at s and s0 *)
															rewrite <- HfreeslotsEqn1. subst nbleft.
															rewrite H53. rewrite H50. rewrite H48. rewrite H46.
															rewrite H44. rewrite H42. rewrite H40. rewrite H38.
															rewrite H36. rewrite H33.
															reflexivity.
														+ (* listoption2 = NIL *)
															(* show list equality for listoption2 *)
															subst optionfreeslotslistpd1. subst optionfreeslotslistpd2.
															intuition.
															rewrite <- HfreeslotsEqn1. subst nbleft.
															rewrite H53. rewrite H50. rewrite H48. rewrite H46.
															rewrite H44. rewrite H42. rewrite H40. rewrite H38.
															rewrite H36. rewrite H33.
															reflexivity.

															(* state already cut into intermediate states *)
															assert(Hfreeslotspd2Eq : exists n1 nbleft,
nbleft = (nbfreeslots pd2entry) /\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s1 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s2 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s3 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s4 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s5 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s6 nbleft
/\
getFreeSlotsListRec n1(firstfreeslot pd2entry) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s7 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s8 nbleft
/\
getFreeSlotsListRec n1 (firstfreeslot pd2entry) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot pd2entry) s9 nbleft
).
{
	eexists ?[n1]. eexists.
	split. intuition.
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
	{	subst s1.
		apply getFreeSlotsListRecEqPDT.
		-- 	intro Hfirstpdeq.
				assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
				specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
				destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
				--- intro HfirstfreeNull.
						assert(HnullAddrExistss0 : nullAddrExists s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold nullAddrExists in *.
						unfold isPADDR in *.
						rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
						destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- rewrite Hfirstpdeq in *.
						unfold isBE in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
		-- unfold isBE. rewrite Hpdinsertions0. intuition.
		-- unfold isPADDR. rewrite Hpdinsertions0. intuition.
	}
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s1 (nbfreeslots pd2entry)).
	{ subst s2.
				apply getFreeSlotsListRecEqPDT.
				--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. subst s1. cbn. rewrite beqAddrTrue. intuition.
				--- unfold isPADDR. subst s1. cbn. rewrite beqAddrTrue. intuition.
	}
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s2 (nbfreeslots pd2entry)).
	{	subst s3.
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot pd2entry *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *. intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s3 (nbfreeslots pd2entry)).
	{	subst s4.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. intuition.
			--- rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s4 (nbfreeslots pd2entry)).
	{	subst s5.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s4. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *. intuition.
			--- rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s5 (nbfreeslots pd2entry)).
	{	subst s6.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. intuition.
			--- rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s6 (nbfreeslots pd2entry)).
	{	subst s7.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s6. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *. intuition.
			--- rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s7 (nbfreeslots pd2entry)).
	{	subst s8.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s7.
					subst s6. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. intuition.
			--- rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s8 (nbfreeslots pd2entry)).
	{ subst s9.
		(* DUP *)
				apply getFreeSlotsListRecEqBE ; intuition.
				---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].

							unfold getFreeSlotsList in Hoptionfreeslotslistpd.
							unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
							rewrite Hpdinsertions0 in *.
							rewrite Hlookuppd2s0 in *.
							assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
							{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
							assert(HnewBFirstFrees0P : firstfreeslot pd2entry = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd.
								rewrite FreeSlotsListRec_unroll in Hoptionfreeslotslistpd2.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots pd2entry) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots pd2entry)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *.
														unfold Lib.disjoint in HDisjointpdpd2s0.
														specialize(HDisjointpdpd2s0 newBlockEntryAddr).
														simpl in HDisjointpdpd2s0.
														intuition.
											**** 	subst optionfreeslotslistpd. subst optionfreeslotslistpd2.
														cbn in *. congruence.
			--- unfold isBE. subst s8. subst s7.
					subst s6. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- subst listoption2.
					rewrite <- Hfreeslotss1 in *. rewrite <- Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd2 pd2entry Hlookuppd2s0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppd2s0 in *.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst listoption2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite <- Hfreeslotss3 in *. rewrite <- Hfreeslotss4 in *.
					rewrite <- Hfreeslotss5 in *. rewrite <- Hfreeslotss6 in *.
					rewrite <- Hfreeslotss7 in *. rewrite <- Hfreeslotss8 in *. intuition.
			--- rewrite <- Hfreeslotss8 in *. rewrite <- Hfreeslotss7 in *.
					rewrite <- Hfreeslotss6 in *. rewrite <- Hfreeslotss5 in *.
					rewrite <- Hfreeslotss4 in *. rewrite <- Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					destruct HDisjointpdpd2s0 as [optionfreeslotslistpd (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd & (Hwellformedpds0 & (Hoptionfreeslotslistpd2 & (Hwellformedpd2s0' & HDisjointpdpd2s0)))))].
					unfold getFreeSlotsList in Hoptionfreeslotslistpd.
					unfold getFreeSlotsList in Hoptionfreeslotslistpd2.
					rewrite Hpdinsertions0 in *.
					assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
					{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot pd2entry) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst listoption2. subst listoption1.
					unfold Lib.disjoint in HDisjointpdpd2s0.
					specialize(HDisjointpdpd2s0 newBlockEntryAddr).
					destruct (HDisjointpdpd2s0).
					* subst optionfreeslotslistpd.
						rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* subst optionfreeslotslistpd2. rewrite Hlookuppd2s0.
						destruct (beqAddr (firstfreeslot pd2entry) nullAddr) ; try(exfalso ; congruence).
						intuition.
}
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s10 (nbfreeslots pd2entry) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s9 (nbfreeslots pd2entry)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. subst s9. subst s8. subst s7. subst s6. subst s5.
					subst s4. subst s3. subst s2. subst s1. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				subst s10. rewrite H51. (* s = currentPartition s9  ...*)
				apply getFreeSlotsListRecEqSCE.
				--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd2 pd2entry Hlookuppd2s0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
	}
	intuition.
	assert(HcurrLtmaxIdx : nbfreeslots pd2entry <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	intuition.
	assert(Hmax : maxIdx + 1 = S maxIdx) by (apply MaxIdxNextEq).
	rewrite Hmax. apply Lt.le_lt_n_Sm. intuition.
}
															destruct Hfreeslotspd2Eq as [n1' (nbleft' & Hstates)].
															rewrite HsEq in *.
															assert(HfreeslotsEqpd2 : getFreeSlotsListRec n1' (firstfreeslot pd2entry) s (nbfreeslots pd2entry) =
																										getFreeSlotsListRec (maxIdx+1) (firstfreeslot pd2entry) s0 (nbfreeslots pd2entry)).
															{
																intuition.
																subst nbleft'.
																(* rewrite all previous getFreeSlotsListRec equalities *)
																rewrite H66. rewrite H64. rewrite H63. rewrite H62.
																rewrite H61. rewrite H60. rewrite H59. rewrite H58.
																rewrite H57. rewrite H55.
																reflexivity.
															}
															assert (HfreeslotsEqn1' : getFreeSlotsListRec n1' (firstfreeslot pd2entry) s (nbfreeslots pd2entry)
																												= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot pd2entry) s (nbfreeslots pd2entry)).
															{ eapply getFreeSlotsListRecEqN ; intuition.
																subst nbleft'. lia.
																assert (HnbLtmaxIdx : nbfreeslots pd2entry <= maxIdx) by apply IdxLtMaxIdx.
																lia.
															}
															rewrite <- HfreeslotsEqn1'. rewrite HfreeslotsEqpd2. intuition.
} (* end of DisjointFreeSlotsLists *)


assert(HinclFreeSlotsBlockEntriess : inclFreeSlotsBlockEntries s).
{ (* inclFreeSlotsBlockEntries s *)
	unfold inclFreeSlotsBlockEntries.
	intros pd HPDT.

	assert(Hcons0 : inclFreeSlotsBlockEntries s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold inclFreeSlotsBlockEntries in Hcons0.

	(* we must show the free slots list is included in the ks entries list of the same pd
		check all possible values for pd in the modified state s
			-> only possible is pdinsertion
				1) - if pd = pdinsertion:
						-> show the pd1's new free slots list is a subset of the initial free slots list
								and that ks entries list is identical at s and s0,
							-> if the free slots list was included at s0,
									then the sublist is still included at s -> OK
				2) - if pd <> pdinsertion, it is another pd
						-> prove pd's free slots list and ksentries list have NOT changed
								in the modified state, so the free slots list is still included
									-> compute the lists at each modified state and check not changed from s0 -> OK
	*)
	(* Check all values for pd  *)
	destruct (beqAddr sceaddr pd) eqn:beqscepd; try(exfalso ; congruence).
	-	(* sceaddr = pd *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd.
		rewrite <- beqscepd in *.
		unfold isSCE in *.
		unfold isPDT in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> pd1 *)
		destruct (beqAddr newBlockEntryAddr pd) eqn:beqnewpd ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = pd *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
				rewrite <- beqnewpd in *.
				unfold isBE in *.
				unfold isPDT in *.
				destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> pd *)
				destruct (beqAddr pdinsertion pd) eqn:beqpdpd; try(exfalso ; congruence).
				--- (* 1) pdinsertion = pd *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd.
						rewrite <- beqpdpd in *.
						specialize (Hcons0 pdinsertion HPDTs0).
						(* develop getFreeSlotsList *)
						unfold getFreeSlotsList.
						rewrite Hpdinsertions.
						rewrite HnewFirstFree.
						destruct (beqAddr newFirstFreeSlotAddr nullAddr) eqn:newFNull.
						---- (* getFreeSlots = nil *)
									apply incl_nil_l.
						---- (* getFreeSlots <> nil *)
									destruct H31 as [Hoptionlists (olds & (n0 & (n1 & (n2 & (nbleft & Hfreeslotsolds)))))].
									assert(HoptionlistEq : Hoptionlists = getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s (nbfreeslots pdentry1)).
									{ subst pdentry1. (* pdentry1 *) cbn.
									assert(HpredNbLeftEq : predCurrentNbFreeSlots = nbleft).
									{ intuition. subst nbleft. unfold StateLib.Index.pred in *.
										destruct (gt_dec currnbfreeslots 0) ; intuition.
										inversion H1. (* Some ... = Some predCurrentNbFreeSlots *)
										unfold CIndex.
										assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
										{ 
											assert(HcurrLtmaxIdx : currnbfreeslots <= maxIdx).
											{ intuition. apply IdxLtMaxIdx. }
											lia.
										}
										destruct (le_dec (currnbfreeslots - 1) maxIdx) ; intuition.
										f_equal. apply proof_irrelevance.
									}
									rewrite HpredNbLeftEq.
									assert(HoptionlistEq : getFreeSlotsListRec n2 newFirstFreeSlotAddr s nbleft = Hoptionlists) by intuition.
									rewrite <- HoptionlistEq. (* n2 s = Hoptionlist *)
									eapply getFreeSlotsListRecEqN ; intuition.
									}
									rewrite <- HoptionlistEq.
									unfold getFreeSlotsList in Hcons0.
									rewrite Hpdinsertions0 in *.
									rewrite <- HnewB in *.
									destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf; try (exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.

									(* we prove inclusion of lists *)
									assert(HIncl : incl Hoptionlists (getFreeSlotsListRec (maxIdx + 1) newBlockEntryAddr s0 (nbfreeslots pdentry))).
									{ 
										rewrite FreeSlotsListRec_unroll.
										unfold getFreeSlotsListAux.
										assert(HMaxIdxNext : maxIdx + 1 = S maxIdx).
										{ lia. }
										rewrite HMaxIdxNext in *.
										destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
										* unfold StateLib.Index.ltb in Hltb.
											apply PeanoNat.Nat.ltb_lt in Hltb.
											contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
										* rewrite HlookupnewBs0 in *.
											assert(Hcurr : (nbfreeslots pdentry) = currnbfreeslots).
											{
												unfold pdentryNbFreeSlots in *.
												rewrite Hpdinsertions0 in *.
												intuition.
											}
											rewrite Hcurr in *.
											destruct (StateLib.Index.ltb currnbfreeslots zero) ; try(exfalso ; congruence).

											destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
											assert(HnewBEndIsNewFirst : (endAddr (blockrange bentry)) = newFirstFreeSlotAddr).
											{ unfold bentryEndAddr in *.
												rewrite HlookupnewBs0 in *.
												intuition.
											}
											rewrite HnewBEndIsNewFirst in *.

											assert(Hoptionlists0 : Hoptionlists = getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft)
												by intuition.
											rewrite Hoptionlists0.

											assert(HnbLtmaxIdx : currnbfreeslots - 1 < maxIdx).
											{
													unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *.
													destruct currnbfreeslots.
													+ simpl. destruct i0.
														* simpl. apply maxIdxNotZero.
														* cbn. rewrite PeanoNat.Nat.sub_0_r. intuition.
											}
											assert((CIndex (currnbfreeslots - 1)) = i).
											{ unfold CIndex.
												destruct (le_dec (currnbfreeslots - 1) maxIdx) ; simpl in * ; intuition ; try(exfalso ; congruence).
													unfold StateLib.Index.pred in *.
													destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
													inversion Hpred. f_equal. apply proof_irrelevance.
											}
											unfold pdentryNbFreeSlots in *. rewrite H5 in *.
											rewrite H8 in *.
											assert(i < maxIdx).
											{	unfold StateLib.Index.pred in *.
												destruct (gt_dec currnbfreeslots 0) ; try(exfalso ; congruence).
												inversion Hpred. simpl. intuition.
											}
											assert(Hnbleft : nbleft = CIndex (currnbfreeslots - 1)) by intuition.
											rewrite Hnbleft.
											subst i. rewrite <- Hnbleft.

											assert(HEq : getFreeSlotsListRec n0 newFirstFreeSlotAddr s0 nbleft =
																			getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s0 nbleft).
											{
												eapply getFreeSlotsListRecEqN ; intuition.
												lia.
											}

											assert(HEq' : getFreeSlotsListRec maxIdx newFirstFreeSlotAddr s0 nbleft =
																			getFreeSlotsListRec (maxIdx + 1) newFirstFreeSlotAddr s0 nbleft).
											{
												eapply getFreeSlotsListRecEqN ; intuition.
											}
											rewrite HEq in *. rewrite HEq' in *.
											intuition.
									}
									(* inclusion of lists *)
									eapply incl_tran.
									instantiate (1:= (getFreeSlotsListRec (maxIdx + 1) newBlockEntryAddr s0
									 (nbfreeslots pdentry))).
									trivial.

									(* develop getKSEntries and show equality with list at s0 *)
									intuition.
									destruct H45 as [optionentrieslist Hoptionentrieslist].
									destruct Hoptionentrieslist as [HEntriesolds (HEntriess & (HEntriess0 & HnewBInEntrieslist))].
									rewrite HEntriess. rewrite HEntriess0.
									intuition.

				--- (* pdinsertion <> pd *)
						unfold getFreeSlotsList.
						unfold getKSEntries.
						assert(HlookuppdEq : lookup pd (memory s) beqAddr = lookup pd (memory s0) beqAddr).
						{ rewrite Hs. simpl. rewrite beqAddrTrue.
							rewrite beqscepd.
							destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
							simpl.
							rewrite beqnewpd.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
							simpl.
							destruct (beqAddr pdinsertion pd) eqn:Hfff ; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
							simpl.
							rewrite beqAddrTrue.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
						}
						rewrite HlookuppdEq.
						assert(HPDTs' : isPDT pd s) by trivial.
						apply isPDTLookupEq in HPDTs'. destruct HPDTs' as [entrypds Hlookuppds].
						assert(HPDTpdEq : isPDT pd s = isPDT pd s0).
						{ unfold isPDT. rewrite <- HlookuppdEq.
							rewrite Hlookuppds. trivial.
						}
						assert(HPDTpds0 : isPDT pd s0) by (rewrite HPDTpdEq in * ; trivial).
						specialize (Hcons0 pd HPDTpds0).
						unfold getFreeSlotsList in Hcons0. unfold getKSEntries in Hcons0.
						apply isPDTLookupEq in HPDTpds0. destruct HPDTpds0 as [entrypd0 Hlookuppds0].
						rewrite Hlookuppds0 in *.
						destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:firstfreeNull ; intuition.
						---- (* freeslots = NIL *)
									apply incl_nil_l.
						---- (* freeslots <> NIL *)
									assert(HfreeslotslistEq : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s (nbfreeslots entrypd0) =
																						getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s0 (nbfreeslots entrypd0)).
									{
											assert(HksentriespdEq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (nbfreeslots entrypd0) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s1 nbleft =
getFreeSlotsListRec (maxIdx+1) (firstfreeslot entrypd0) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s2 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s3 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s4 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s5 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s6 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s7 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s8 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s9 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getFreeSlotsListRec n1 (firstfreeslot entrypd0) s10 nbleft =
			getFreeSlotsListRec n1 (firstfreeslot entrypd0) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	assert(HPDTpds0 : isPDT pd s0) by (rewrite HPDTpdEq in * ; intuition).
	assert(HpdpdinsertionNotEq : pdinsertion <> pd)
		by (rewrite <- beqAddrFalse in * ; intuition).
	assert(HDisjoints0 : DisjointFreeSlotsLists s0)
		by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	specialize (HDisjoints0 pdinsertion pd HPDTs0 HPDTpds0 HpdpdinsertionNotEq).
	destruct HDisjoints0 as [optionfreeslotslist1 (optionfreeslotslist2 & (Hoptionlist1s0 & (Hwellformed1s0 & (Hoptionlist2s0 & (Hwellformed2s0 & HDisjoints0)))))].
	unfold getFreeSlotsList in Hoptionlist1s0.
	unfold getFreeSlotsList in Hoptionlist2s0.
	rewrite Hpdinsertions0 in *.
	rewrite Hlookuppds0 in *.
	assert(HnewBFirstFrees0PDT : firstfreeslot pdentry = newBlockEntryAddr).
	{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getFreeSlotsListRec ?n1 (firstfreeslot entrypd0) s1 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s0 (nbfreeslots entrypd0)).
	{
		apply getFreeSlotsListRecEqPDT.
		--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd entrypd0 Hlookuppds0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								rewrite beqAddrTrue in *.
								congruence.
						---- rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. subst s1. cbn. intuition.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				--- unfold isPADDR. subst s1. cbn. intuition.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s2 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s1 (nbfreeslots entrypd0)).
	{
		(* DUP *)
		apply getFreeSlotsListRecEqPDT.
		--- 	intro Hfirstpdeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd entrypd0 Hlookuppds0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstpdeq in *.
								rewrite beqAddrTrue in *.
								congruence.
						----  rewrite Hfirstpdeq in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. subst s1. cbn. intuition. rewrite beqAddrTrue in *.
						intuition.
				--- unfold isPADDR. subst s1. cbn. intuition. rewrite beqAddrTrue in *.
						destruct (lookup pdinsertion (memory s0) beqAddr) ; try (exfalso ; congruence).
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s3 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s2 (nbfreeslots entrypd0)).
	{
		apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					intuition.
			--- rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s4 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s3 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *.
					intuition.
			--- rewrite Hfreeslotss3 in *. rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s5 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s4 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *. rewrite Hfreeslotss4 in *.
					intuition.
			--- rewrite Hfreeslotss4 in *. rewrite Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s6 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s5 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *. rewrite Hfreeslotss4 in *.
					rewrite Hfreeslotss5 in *. intuition.
			--- rewrite Hfreeslotss5 in *.
					rewrite Hfreeslotss4 in *. rewrite Hfreeslotss3 in *.
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s7 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s6 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *. rewrite Hfreeslotss4 in *.
					rewrite Hfreeslotss5 in *. rewrite Hfreeslotss6 in *. intuition.
			--- rewrite Hfreeslotss6 in *. rewrite Hfreeslotss5 in *.
					rewrite Hfreeslotss4 in *. rewrite Hfreeslotss3 in *. 
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s8 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s7 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *. rewrite Hfreeslotss4 in *.
					rewrite Hfreeslotss5 in *. rewrite Hfreeslotss6 in *. 
					rewrite Hfreeslotss7 in *. intuition.
			--- rewrite Hfreeslotss7 in *.
					rewrite Hfreeslotss6 in *. rewrite Hfreeslotss5 in *.
					rewrite Hfreeslotss4 in *. rewrite Hfreeslotss3 in *. 
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s9 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s8 (nbfreeslots entrypd0)).
	{
		(* DUP *)
	apply getFreeSlotsListRecEqBE ; intuition.
		---	(* Lists are disjoint at s0, so newB <> firstfreeslot p *)
							assert(HnewBFirstFrees0P : firstfreeslot entrypd0 = newBlockEntryAddr) by intuition.
							rewrite HnewBFirstFrees0PDT in *.
							rewrite HnewBFirstFrees0P in *.
							destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
								rewrite FreeSlotsListRec_unroll in Hoptionlist1s0.
								rewrite FreeSlotsListRec_unroll in Hoptionlist2s0.
								unfold getFreeSlotsListAux in *.
								induction (maxIdx+1). (* false induction because of fixpoint constraints *)
								** (* N=0 -> NotWellFormed *)
									rewrite Hoptionlist1s0 in *.
									cbn in Hwellformed1s0.
									congruence.
								** (* N>0 *)
									clear IHn.
									rewrite HlookupnewBs0 in *.
									destruct (StateLib.Index.ltb (nbfreeslots pdentry) zero) eqn:Hltb ; try(cbn in * ; congruence).
									destruct (StateLib.Index.ltb (nbfreeslots entrypd0) zero) eqn:Hltb' ; try(cbn in * ; congruence).
									destruct (StateLib.Index.pred (nbfreeslots pdentry)) eqn:Hpred1 ; try(exfalso ; congruence).
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
									*** destruct (StateLib.Index.pred (nbfreeslots entrypd0)) eqn:Hpred2 ; try(subst listoption2 ; intuition).
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *.
														unfold Lib.disjoint in HDisjoints0.
														specialize(HDisjoints0 newBlockEntryAddr).
														simpl in HDisjoints0.
														intuition.
											**** 	subst optionfreeslotslist1. subst optionfreeslotslist2.
														cbn in *. congruence.
			--- unfold isBE. simpl.
					destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
					rewrite beqAddrTrue.
					cbn.
					repeat rewrite removeDupIdentity ; intuition.
			--- rewrite firstfreeNull in *.
					subst optionfreeslotslist2. congruence.
			--- assert(H_NoDups0 : NoDupInFreeSlotsList s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
					unfold NoDupInFreeSlotsList in *.
					specialize (H_NoDups0 pd entrypd0 Hlookuppds0).
					destruct H_NoDups0 as [optionlist2 (Hoptionlist2 & HwellFormed2' & HNoDup2)].
					unfold getFreeSlotsList in Hoptionlist2.
					rewrite Hlookuppds0 in *.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
					subst optionlist2. subst optionfreeslotslist2.
					rewrite Hfreeslotss1 in *. rewrite Hfreeslotss2 in *.
					rewrite Hfreeslotss3 in *. rewrite Hfreeslotss4 in *.
					rewrite Hfreeslotss5 in *. rewrite Hfreeslotss6 in *.
					rewrite Hfreeslotss7 in *. rewrite Hfreeslotss8 in *. intuition.
			--- rewrite Hfreeslotss8 in *. rewrite Hfreeslotss7 in *.
					rewrite Hfreeslotss6 in *. rewrite Hfreeslotss5 in *.
					rewrite Hfreeslotss4 in *. rewrite Hfreeslotss3 in *. 
					rewrite Hfreeslotss2 in *. rewrite Hfreeslotss1 in *.
					(* newB is in freeslots list of pdinsertion, so can't be in other list
							because of Disjoint *)
					(* DUP from previous step *)
					rewrite HnewBFirstFrees0PDT in *.
					destruct (beqAddr newBlockEntryAddr nullAddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
					destruct (beqAddr (firstfreeslot entrypd0) nullAddr) eqn:HfirstfreeNull ; try(exfalso ; congruence).
					(* firstfreeslot p <> NULL *)
					(* if first free of other PD is NOT NULL,
					then newB can't be in the two lists at s0 because of Disjoint -> False *)
					subst optionfreeslotslist2. subst optionfreeslotslist1.
					unfold Lib.disjoint in HDisjoints0.
					specialize(HDisjoints0 newBlockEntryAddr).
					destruct (HDisjoints0).
					* rewrite FreeSlotsListRec_unroll.
						unfold getFreeSlotsListAux.
						assert(HmaxIdxNextEq :	maxIdx + 1 = S maxIdx) by apply MaxIdxNextEq.
						rewrite HmaxIdxNextEq.
						rewrite HlookupnewBs0.
						assert(HcurrNb : currnbfreeslots = nbfreeslots pdentry).
						{ unfold pdentryNbFreeSlots in *. rewrite Hpdinsertions0 in *. intuition. }
						rewrite <- HcurrNb in *.
						destruct (StateLib.Index.ltb currnbfreeslots zero) eqn:Hltb ; try(exfalso ; congruence).
						** unfold StateLib.Index.ltb in Hltb.
								apply PeanoNat.Nat.ltb_lt in Hltb.
								contradict Hltb. apply PeanoNat.Nat.lt_asymm. intuition.
						**	destruct (StateLib.Index.pred currnbfreeslots) eqn:Hpred ; try(exfalso ; congruence).
								cbn. intuition.
					* intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s10 (nbfreeslots entrypd0) =
getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s9 (nbfreeslots entrypd0)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getFreeSlotsListRecEqSCE.
			--- 	intro Hfirstsceeq.
						assert(HFirstFreeSlotPointerIsBEAndFreeSlots0 : FirstFreeSlotPointerIsBEAndFreeSlot s0)
							by (unfold consistency in * ; unfold consistency1 in * ; intuition).
						unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
						specialize (HFirstFreeSlotPointerIsBEAndFreeSlots0 pd entrypd0 Hlookuppds0).
						destruct HFirstFreeSlotPointerIsBEAndFreeSlots0.
						---- intro HfirstfreeNull.
								assert(HnullAddrExistss0 : nullAddrExists s0)
									by (unfold consistency in * ; unfold consistency1 in * ; intuition).
								unfold nullAddrExists in *.
								unfold isSCE in *.
								unfold isPADDR in *.
								rewrite HfirstfreeNull in *. rewrite <- Hfirstsceeq in *.
								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						---- rewrite Hfirstsceeq in *.
								unfold isSCE in *.
								unfold isBE in *.
								destruct (lookup sceaddr (memory s0) beqAddr) ; try (exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
				--- unfold isBE. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
				--- unfold isPADDR. unfold isSCE in HSCEs9.
						destruct (lookup sceaddr (memory s9) beqAddr) eqn:Hlookupsces9 ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
						intuition.
	}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : (nbfreeslots entrypd0) <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
									destruct HksentriespdEq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																		(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
									assert(HsEq : s10 = s).
									{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
										subst s7. subst s8. subst s9. subst s10.
										rewrite Hs. f_equal.
									}
									rewrite HsEq in *.
									(* listoption2 didn't change *)
									assert(HfreeslotsEq : getFreeSlotsListRec n1 (firstfreeslot entrypd0) s (nbfreeslots entrypd0) =
																				getFreeSlotsListRec (maxIdx+1) (firstfreeslot entrypd0) s0 (nbfreeslots entrypd0)).
									{
										intuition.
										subst nbleft.
										(* rewrite all previous getFreeSlotsListRec equalities *)
										rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40.
										rewrite <- H42. rewrite <- H44. rewrite <- H46. rewrite <- H48.
										rewrite <- H50. rewrite <- H53.
										reflexivity.
									}
									assert (HfreeslotsEqn1 : getFreeSlotsListRec n1 (firstfreeslot entrypd0) s (nbfreeslots entrypd0)
																						= getFreeSlotsListRec (maxIdx + 1) (firstfreeslot entrypd0) s (nbfreeslots entrypd0)).
									{ eapply getFreeSlotsListRecEqN ; intuition.
										subst nbleft. lia.
										assert (HnbLtmaxIdx : (nbfreeslots entrypd0) <= maxIdx) by apply IdxLtMaxIdx.
										lia.
									}
									rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq.
									intuition.
								}
								rewrite HfreeslotslistEq in *.
								destruct (beqAddr (structure entrypd0) nullAddr) eqn:HstructNull ; try(exfalso ; congruence).
								intuition.

								assert(HKSEntriesEq :   (getKSEntriesAux (maxIdx + 1) (structure entrypd0) s
     (CIndex maxNbPrepare)) =   (getKSEntriesAux (maxIdx + 1) (structure entrypd0) s0
     (CIndex maxNbPrepare))).
									{
										assert(HksentriespdEq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = CIndex maxNbPrepare /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure entrypd0) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s2 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s3 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s4 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s5 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s6 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s7 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getKSEntriesAux n1(structure entrypd0) s8 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s9 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getKSEntriesAux n1 (structure entrypd0) s10 nbleft =
			getKSEntriesAux n1 (structure entrypd0) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure entrypd0) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s0 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd entrypd0 Hlookuppds0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s1 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd entrypd0 Hlookuppds0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		--	unfold isPDT. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s2 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s3 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s4 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s5 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s6 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s7 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s8 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure entrypd0) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure entrypd0) s9 (CIndex maxNbPrepare)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getKSEntriesAuxEqSCE ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : CIndex maxNbPrepare <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
										destruct HksentriespdEq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																			(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
										assert(HsEq : s10 = s).
										{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
											subst s7. subst s8. subst s9. subst s10.
											rewrite Hs. f_equal.
										}
										rewrite HsEq in *.
										(* listoption2 didn't change *)
										assert(HksentriesEq : getKSEntriesAux n1 (structure entrypd0) s (CIndex maxNbPrepare) =
																					getKSEntriesAux (maxIdx+1) (structure entrypd0) s0 (CIndex maxNbPrepare)).
										{
											intuition.
											subst nbleft.
											(* rewrite all previous getKSEntriesAux equalities *)
											rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40.
											rewrite <- H42. rewrite <- H44. rewrite <- H46. rewrite <- H48.
											rewrite <- H50. rewrite <- H53.
											reflexivity.
										}
										assert (HksentriesEqn1 : getKSEntriesAux n1 (structure entrypd0) s (CIndex maxNbPrepare)
																							= getKSEntriesAux (maxIdx + 1) (structure entrypd0) s (CIndex maxNbPrepare)).
										{ eapply getKSEntriesAuxEqN ; intuition.
											subst nbleft. lia.
											assert (HnbLtmaxIdx : CIndex maxNbPrepare <= maxIdx) by apply IdxLtMaxIdx.
											lia.
										}
										rewrite <- HksentriesEqn1. rewrite HksentriesEq. intuition.
									}
									rewrite HKSEntriesEq in *. intuition.
} (* end of inclFreeSlotsBlockEntries *)

assert(HDisjointKSEntriess : DisjointKSEntries s).
{ (* DisjointKSEntries s *)
	unfold DisjointKSEntries.
	intros pd1 pd2 HPDTpd1 HPDTpd2 Hpd1pd2NotEq.

	assert(Hcons0 : DisjointKSEntries s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
	unfold DisjointKSEntries in Hcons0.

	(* we must show all KSEntries lists are disjoint
		check all possible values for pd1 AND pd2 in the modified state s
			-> only possible is pdinsertion
				1) - if pd1 = pdinsertion:
						-> show the pd1's new free slots list is a subset of the initial free slots list
								and that pd2's free slots list is identical at s and s0,
							-> if they were disjoint at s0, they are still disjoint at s -> OK
				2) - if pd1 <> pdinsertion, it is another pd, but pd2 could be pdinsertion
						3) - if pd2 = pdinsertion:
								same proof as with pd1
						4) - if pd2 <> pdinsertion: prove pd1's free slots list and pd2's free slot list
								have NOT changed in the modified state, so they are still disjoint
									-> compute the list at each modified state and check not changed from s0 -> OK
*)
	(* Check all values for pd1 and pd2 except pdinsertion *)
	destruct (beqAddr sceaddr pd1) eqn:beqscepd1; try(exfalso ; congruence).
	-	(* sceaddr = pd1 *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd1.
		rewrite <- beqscepd1 in *.
		unfold isSCE in *.
		unfold isPDT in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> pd1 *)
		destruct (beqAddr newBlockEntryAddr pd1) eqn:beqnewpd1 ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = pd1 *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd1.
				rewrite <- beqnewpd1 in *.
				unfold isBE in *.
				unfold isPDT in *.
				destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> pd1 *)
				destruct (beqAddr sceaddr pd2) eqn:beqscepd2; try(exfalso ; congruence).
				---	(* sceaddr = pd2 *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd2.
						rewrite <- beqscepd2 in *.
						unfold isSCE in *.
						unfold isPDT in *.
						destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
				---	(* sceaddr <> pd2 *)
						destruct (beqAddr newBlockEntryAddr pd2) eqn:beqnewpd2 ; try(exfalso ; congruence).
					---- (* newBlockEntryAddr = pd2 *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd2.
								rewrite <- beqnewpd2 in *.
								unfold isPDT in *.
								unfold isBE in *.
								destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
					---- (* newBlockEntryAddr <> pd2 *)
								destruct (beqAddr pdinsertion pd1) eqn:beqpdpd1; try(exfalso ; congruence).
								----- (* 1) pdinsertion = pd1 *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd1.
										rewrite <- beqpdpd1 in *.
										destruct (beqAddr pdinsertion pd2) eqn:beqpdpd2; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd2. congruence.
										(* DUP *)
										assert(Hlookuppd2Eq : lookup pd2 (memory s) beqAddr = lookup pd2 (memory s0) beqAddr).
										{
											rewrite Hs. unfold isPDT.
											cbn. rewrite beqAddrTrue.
											rewrite beqscepd2.
											assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
											rewrite HnewBsceNotEq. (*newBlock <> sce *)
											assert(HpdnewBNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
											rewrite HpdnewBNotEq. (*pd <> newblock*)
											cbn.
											rewrite beqnewpd2.
											rewrite beqAddrTrue.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity ; intuition.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
											cbn.
											destruct (beqAddr pdinsertion pd2) eqn:Hff ; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
											rewrite <- beqAddrFalse in *.
											repeat rewrite removeDupIdentity ; intuition.
										}
										assert(HPDTpd2Eq : isPDT pd2 s = isPDT pd2 s0).
										{ unfold isPDT. rewrite Hlookuppd2Eq. intuition. }
										assert(HPDTpd2s0 : isPDT pd2 s0) by (rewrite HPDTpd2Eq in * ; assumption).
										specialize(Hcons0 pdinsertion pd2 HPDTs0 HPDTpd2s0 Hpd1pd2NotEq).
										destruct Hcons0 as [optionentrieslist1 (optionentrieslist2 & (Hoptionlist1s0 & (Hoptionlist2s0 & HDisjoints0)))].
										(* Show equality for pd2's free slot list
												so between listoption2 at s and listoption2 at s0 *)
										unfold getKSEntries in Hoptionlist2s0.
										apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].
										rewrite Hlookuppd2s0 in *.

										destruct (beqAddr (structure pd2entry) nullAddr) eqn:Hpd2Null ; try(exfalso ; congruence).
										------ (* listoption2 = NIL *)
													destruct H31 as [Hoptionfreeslotslists (olds & (n0 & (n1 & (n2 & (nbleft & Hlists)))))].
													intuition.
													destruct H45 as [optionentrieslist Hoptionksentrieslist].

													exists optionentrieslist.
													exists optionentrieslist2.
													assert(Hlistoption2s : getKSEntries pd2 s = nil).
													{
														unfold getKSEntries.
														rewrite Hlookuppd2Eq. rewrite Hpd2Null. reflexivity.
													}
													rewrite Hlistoption2s in *.
													intuition. rewrite Hoptionlist2s0 in *.
													assert(HKSEntriess : getKSEntries pdinsertion s = optionentrieslist) by trivial.
													rewrite <- HKSEntriess.
													unfold getKSEntries. rewrite Hpdinsertions.

													(* disjoint at s0, still now *)

													rewrite Hoptionlist1s0 in HDisjoints0.
													assert(HKSEntriess0 : optionentrieslist = getKSEntries pdinsertion s0) by trivial.
													rewrite <- HKSEntriess0 in HDisjoints0.
													rewrite <- HKSEntriess in HDisjoints0.
													unfold getKSEntries in HDisjoints0.
													rewrite Hpdinsertions in *.
													cbn.
													cbn in HDisjoints0.
													intuition.

										------ (* listoption2 <> NIL *)
														(* show equality between listoption2 at s and s0 
																+ if listoption2 has NOT changed, listoption1 at s is
																just a subset of listoption1 at s0 so they are
																still disjoint *)
														assert(Hksentriespd2Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = CIndex maxNbPrepare /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s2 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s3 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s4 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s5 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s6 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s7 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getKSEntriesAux n1(structure pd2entry) s8 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s9 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s10 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure pd2entry) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s1 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		--	unfold isPDT. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getKSEntriesAuxEqSCE ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : CIndex maxNbPrepare <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
														destruct Hksentriespd2Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																			(n1 & (nbleft & (Hnbleft & Hstates))))))))))))].
														assert(HsEq : s10 = s).
														{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
															subst s7. subst s8. subst s9. subst s10.
															rewrite Hs. f_equal.
														}
														rewrite HsEq in *.
														(* listoption2 didn't change *)
														assert(HksentriesEq : getKSEntriesAux n1 (structure pd2entry) s (CIndex maxNbPrepare) =
																									getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
														{
															intuition.
															subst nbleft.
															(* rewrite all previous getKSEntriesAux equalities *)
															rewrite <- H33. rewrite <- H36. rewrite <- H38. rewrite <- H40.
															rewrite <- H42. rewrite <- H44. rewrite <- H46. rewrite <- H48.
															rewrite <- H50. rewrite <- H53.
															reflexivity.
														}
														assert (HksentriesEqn1 : getKSEntriesAux n1 (structure pd2entry) s (CIndex maxNbPrepare)
																											= getKSEntriesAux (maxIdx + 1) (structure pd2entry) s (CIndex maxNbPrepare)).
														{ eapply getKSEntriesAuxEqN ; intuition.
															subst nbleft. lia.
															assert (HnbLtmaxIdx : CIndex maxNbPrepare <= maxIdx) by apply IdxLtMaxIdx.
															lia.
														}
														unfold getKSEntries in *.
														rewrite Hlookuppd2Eq in *.
														rewrite Hpdinsertions0 in *. rewrite Hpdinsertions in *.
														rewrite <- HksentriesEqn1. rewrite HksentriesEq.
														rewrite Hpd2Null.
														destruct H31 as [Hoptionlists (olds & (n0' & (n1' & (n2' & (nbleft' & Hfreeslotsolds')))))].
														intuition.
														destruct H59 as [optionentrieslists (Hoptionlistolds & (Hoptionlistss & (Hoptionlists0 & HnewBInEntrieslist)))].
														exists optionentrieslists. exists optionentrieslist2.
														destruct (beqAddr (structure pdentry1) nullAddr) eqn:beqstructnull; try(exfalso ; congruence).
														------- (* (structure pdentry1) = nullAddr *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqstructnull.
																		intuition.
																		rewrite <- Hoptionlistss in *.
																		unfold Lib.disjoint. intros. intuition.
														------- (*  (structure pdentry1) <> nullAddr *)
																		destruct (beqAddr (structure pdentry) nullAddr) eqn:beqstructpd ; try(exfalso ; congruence).
																		* (* (structure pdentry) = nullAddr *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqstructpd.
																			rewrite beqstructpd in *.
																			intuition.
																			rewrite Hoptionlists0 in *.
																			unfold Lib.disjoint. intros. intuition.
																		* (* (structure pdentry) <> nullAddr *)
																			intuition.
																			rewrite Hoptionlists0 in *.
																			rewrite <- Hoptionlist1s0 in *.
																			intuition.
									----- (* 2) pdinsertion <> pd1 *)
												(* similarly, we must prove optionfreeslotslist1 is strictly
														the same at s than at s0 by recomputing each
														intermediate steps and check at that time *)
												assert(Hlookuppd1Eq : lookup pd1 (memory s) beqAddr = lookup pd1 (memory s0) beqAddr).
												{
													rewrite Hs.
													cbn. rewrite beqAddrTrue.
													rewrite beqscepd1.
													assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
													rewrite HnewBsceNotEq. (*newBlock <> sce *)
													cbn.
													rewrite beqnewpd1. (*pd1 <> newblock*)
													rewrite beqAddrTrue.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
													destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
													cbn.
													destruct (beqAddr pdinsertion pd1) eqn:Hff ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
												}
												assert(HPDTpd1Eq : isPDT pd1 s = isPDT pd1 s0).
												{ unfold isPDT. rewrite Hlookuppd1Eq. intuition. }
												assert(HPDTpd1s0 : isPDT pd1 s0) by (rewrite HPDTpd1Eq in * ; assumption).
													(* DUP of previous steps to show strict equality of listoption2
														at s and s0 *)
												destruct (beqAddr pdinsertion pd2) eqn:beqpdpd2; try(exfalso ; congruence).
												------ (* 3) pdinsertion = pd2 *)
															(* DUP of pdinsertion = pd1 *)
															rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd2.
															rewrite <- beqpdpd2 in *.
															(* DUP with pd1 instead of pd2 *)
															assert(Hpd1pd2NotEq' : pdinsertion <> pd1 ) by intuition.
															assert(HPDTpd2Eq : isPDT pd1 s = isPDT pd1 s0).
															{ unfold isPDT. rewrite Hlookuppd1Eq. intuition. }
															specialize(Hcons0 pdinsertion pd1 HPDTs0 HPDTpd1s0 Hpd1pd2NotEq').
															destruct Hcons0 as [optionentrieslist1 (optionentrieslist2 & (Hoptionlist1s0 & (Hoptionlist2s0 & HDisjoints0)))].

															(* Show equality between listoption1 at s and listoption1 at s0 *)
															destruct H31 as [Hoptionfreeslotslists (olds & (n0 & (n1 & (n2 & (nbleft & Hlists)))))].
															intuition.
															destruct H45 as [optionentrieslist Hoptionksentrieslist].
															assert(HoptionentrieslistEq : optionentrieslist = optionentrieslist1).
															{ rewrite Hoptionlist1s0. intuition.
															}
															subst optionentrieslist1.

															exists optionentrieslist2.
															exists optionentrieslist.

															unfold getKSEntries at 1.
															rewrite Hlookuppd1Eq.
															unfold getKSEntries in Hoptionlist2s0.
															apply isPDTLookupEq in HPDTpd1s0. destruct HPDTpd1s0 as [pd1entry Hlookuppd1s0].
															rewrite Hlookuppd1s0 in *.

															destruct (beqAddr (structure pd1entry) nullAddr) eqn:Hpd1Null ; try(exfalso ; congruence).
															------- (* listoption2 = NIL *)

																		rewrite Hoptionlist2s0 in *.
																		intuition.
																		assert(HKSEntriess0 : optionentrieslist = getKSEntries pdinsertion s0) by trivial.
																		rewrite HKSEntriess0.
																		intuition.
																		apply Lib.disjointPermut. intuition.

															------- (* listoption2 <> NIL *)
																			(* show equality between listoption2 at s and s0 
																					+ if listoption2 has NOT changed, listoption1 at s is
																					equal to listoption1 at s0 so they are
																					still disjoint *)
																			assert(Hksentriespd1Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = CIndex maxNbPrepare /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure pd1entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s2 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s3 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s4 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s5 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s6 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s7 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getKSEntriesAux n1(structure pd1entry) s8 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s9 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s10 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure pd1entry) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s0 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd1 pd1entry Hlookuppd1s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s1 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd1 pd1entry Hlookuppd1s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		--	unfold isPDT. unfold s1. cbn. rewrite beqAddrTrue. intuition.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s2 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s3 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s4 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s5 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s6 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s7 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s8 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue. trivial.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s9 (CIndex maxNbPrepare)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getKSEntriesAuxEqSCE ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : CIndex maxNbPrepare <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
															destruct Hksentriespd1Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																			(n1' & (nbleft' & (Hnbleft & Hstates))))))))))))].
															assert(HsEq : s10 = s).
															{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
																subst s7. subst s8. subst s9. subst s10.
																rewrite Hs. f_equal.
															}
															rewrite HsEq in *.
															(* listoption2 didn't change *)
															assert(HksentriesEq : getKSEntriesAux n1' (structure pd1entry) s (CIndex maxNbPrepare) =
																										getKSEntriesAux (maxIdx+1) (structure pd1entry) s0 (CIndex maxNbPrepare)).
															{
																intuition.
																subst nbleft'.
																(* rewrite all previous getKSEntriesAux equalities *)
																rewrite <- H45. rewrite <- H53. rewrite <- H55. rewrite <- H57.
																rewrite <- H59. rewrite <- H61. rewrite <- H63. rewrite <- H65.
																rewrite <- H67. rewrite <- H70.
																reflexivity.
															}
															assert (HksentriesEqn1 : getKSEntriesAux n1' (structure pd1entry) s (CIndex maxNbPrepare)
																												= getKSEntriesAux (maxIdx + 1) (structure pd1entry) s (CIndex maxNbPrepare)).
															{ eapply getKSEntriesAuxEqN ; intuition.
																subst nbleft'. lia.
																assert (HnbLtmaxIdx : CIndex maxNbPrepare <= maxIdx) by apply IdxLtMaxIdx.
																lia.
															}
															rewrite <- HksentriesEqn1. rewrite HksentriesEq.
															rewrite HoptionentrieslistEq.
															assert(HKSEntries : getKSEntries pdinsertion s0 = getKSEntries pdinsertion s).
															{
																intuition. subst optionentrieslist. intuition.
															}
															intuition.
															apply Lib.disjointPermut. intuition.

															------ (* 4) pdinsertion <> pd2 *)
																			(* show strict equality of listoption1 at s and s0
																					and listoption2 at s and s0 because no list changed 
																						as only pdinsertion's free slots list changed *)
																			(* DUP *)
																			(* show list equality between s0 and s*)
																			(* similarly, we must prove optionfreeslotslist1 
																				and optionfreeslotslist2 are strictly
																				the same at s than at s0 by recomputing each
																				intermediate steps and check at that time *)
																			assert(Hlookuppd2Eq : lookup pd2 (memory s) beqAddr = lookup pd2 (memory s0) beqAddr).
																			{
																				rewrite Hs.
																				cbn. rewrite beqAddrTrue.
																				rewrite beqscepd2.
																				assert(HnewBsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
																				rewrite HnewBsceNotEq. (*newBlock <> sce *)
																				cbn.
																				rewrite beqnewpd2. (*pd2 <> newblock*)
																				rewrite beqAddrTrue.
																				rewrite <- beqAddrFalse in *.
																				repeat rewrite removeDupIdentity ; intuition.
																				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
																				rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
																				cbn.
																				destruct (beqAddr pdinsertion pd2) eqn:Hff ; try(exfalso ; congruence).
																				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
																				rewrite <- beqAddrFalse in *.
																				repeat rewrite removeDupIdentity ; intuition.
																			}
																			assert(HPDTpd2Eq : isPDT pd2 s = isPDT pd2 s0).
																			{ unfold isPDT. rewrite Hlookuppd2Eq. intuition. }
																			assert(HPDTpd2s0 : isPDT pd2 s0) by (rewrite HPDTpd2Eq in * ; assumption).
																				(* DUP of previous steps to show strict equality of listoption2
																					at s and s0 *)
																			specialize (Hcons0 pd1 pd2 HPDTpd1s0 HPDTpd2s0 Hpd1pd2NotEq).
																			destruct Hcons0 as [optionentrieslist1 (optionentrieslist2 & (Hoptionlist1s0 & (Hoptionlist2s0 & HDisjoints0)))].

																			destruct H31 as [Hoptionfreeslotslists (olds & (n0 & (n1 & (n2 & (nbleft & Hlists)))))].
																			intuition.
																			destruct H45 as [optionentrieslist Hoptionksentrieslist].

																			assert(Hpdpd1NotEq : pdinsertion <> pd1) by (rewrite <- beqAddrFalse in * ; intuition).
																			assert(Hpdpd2NotEq : pdinsertion <> pd2) by (rewrite <- beqAddrFalse in * ; intuition).
																			assert(HDisjointpdpd1s0 : DisjointFreeSlotsLists s0)
																				by (unfold consistency in * ; unfold consistency1 in * ; intuition).
																			unfold DisjointFreeSlotsLists in *.
																			specialize (HDisjointpdpd1s0 pdinsertion pd1 HPDTs0 HPDTpd1s0 Hpdpd1NotEq).
																			assert(HDisjointpdpd2s0 : DisjointFreeSlotsLists s0)
																				by (unfold consistency in * ; unfold consistency1 in * ; intuition).
																			unfold DisjointFreeSlotsLists in *.
																			specialize (HDisjointpdpd2s0 pdinsertion pd2 HPDTs0 HPDTpd2s0 Hpdpd2NotEq).

																			(* Show equality between listoption1 at s and listoption1 at s0 *)
																			unfold getFreeSlotsList in Hoptionlist1s0.
																			apply isPDTLookupEq in HPDTpd1s0. destruct HPDTpd1s0 as [pd1entry Hlookuppd1s0].
																			rewrite Hlookuppd1s0 in *.

																			unfold getKSEntries at 1.
																			rewrite Hlookuppd1Eq.

																			destruct (beqAddr (structure pd1entry) nullAddr) eqn:Hpd1Null ; try(exfalso ; congruence).
																			------- (* listoption1 = NIL *)
																							exists optionentrieslist1.
																							exists optionentrieslist2.
																							assert(Hlistoption1s0 : getKSEntries pd1 s0 = nil).
																							{
																								unfold getKSEntries.
																								rewrite Hlookuppd1s0.
																								rewrite Hpd1Null. reflexivity.
																							}
																							rewrite Hoptionlist2s0 in *.
																							rewrite Hlistoption1s0 in *. intuition.
																							unfold getKSEntries in *. rewrite Hlookuppd2Eq in *.
																							apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].
																							rewrite Hlookuppd2s0 in *.
																							destruct (beqAddr (structure pd2entry) nullAddr) eqn:beqfirstnull; try(exfalso ; congruence).
																							-------- (* (firstfreeslot pd2entry) = nullAddr *)
																											intuition.
																							-------- (* (firstfreeslot pd2entry) <> nullAddr *)
																												(* show equality between listoption2 at s and s0
																														-> if listoption2 has NOT changed, they are
																														still disjoint at s because lisoption1 is NIL *)
																												assert(Hfreeslotspd2Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = (CIndex maxNbPrepare) /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s2 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s3 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s4 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s5 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s6 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s7 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getKSEntriesAux n1(structure pd2entry) s8 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s9 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getKSEntriesAux n1 (structure pd2entry) s10 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure pd2entry) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s1 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- unfold isPDT. unfold s1. simpl. rewrite beqAddrTrue. trivial.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getKSEntriesAuxEqSCE ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : CIndex maxNbPrepare <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
														destruct Hfreeslotspd2Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																							(n1' & (nbleft' & (Hnbleft & Hstates))))))))))))].
														assert(HsEq : s10 = s).
														{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
															subst s7. subst s8. subst s9. subst s10.
															rewrite Hs. f_equal.
														}
														rewrite HsEq in *.
														assert(HfreeslotsEq : getKSEntriesAux n1' (structure pd2entry) s (CIndex maxNbPrepare) =
																									getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
														{
															intuition.
															subst nbleft'.
															(* rewrite all previous getKSEntriesAux equalities *)
															rewrite <- H50. rewrite <- H53. rewrite <- H55. rewrite <- H57.
															rewrite <- H59. rewrite <- H61. rewrite <- H63. rewrite <- H65.
															rewrite <- H67. rewrite <- H70.
															reflexivity.
														}
														assert (HfreeslotsEqn1 : getKSEntriesAux n1' (structure pd2entry) s (CIndex maxNbPrepare)
																											= getKSEntriesAux (maxIdx + 1) (structure pd2entry) s (CIndex maxNbPrepare)).
														{ eapply getKSEntriesAuxEqN ; intuition.
															subst nbleft'. lia.
															assert (HnbLtmaxIdx : CIndex maxNbPrepare <= maxIdx) by apply IdxLtMaxIdx.
															lia.
														}
														rewrite <- HfreeslotsEqn1. rewrite HfreeslotsEq. intuition.

										------- (* listoption1 <> NIL *)
														(* show equality beween listoption1 at s0 and at s
																-> if equality, then show listoption2 has not changed either
																		-> if listoption1 and listoption2 stayed the same
																				and they were disjoint at s0, then they
																				are still disjoint at s*)

														assert(Hfreeslotspd1Eq : exists s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 n1 nbleft,
nbleft = CIndex maxNbPrepare /\
s1 = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                (PDT
                   {|
                     structure := structure pdentry;
                     firstfreeslot := newFirstFreeSlotAddr;
                     nbfreeslots := nbfreeslots pdentry;
                     nbprepare := nbprepare pdentry;
                     parent := parent pdentry;
                     MPU := MPU pdentry;
                     vidtBlock := vidtBlock pdentry
                   |}) (memory s0) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure pd1entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\ s2 = {|
     currentPartition := currentPartition s1;
     memory := add pdinsertion
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
                 ) (memory s1) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s2 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s1 nbleft
/\ s3 = {|
     currentPartition := currentPartition s2;
     memory := add newBlockEntryAddr
	            (BE
	               (CBlockEntry (read bentry) 
	                  (write bentry) (exec bentry) 
	                  (present bentry) (accessible bentry)
	                  (blockindex bentry)
	                  (CBlock startaddr (endAddr (blockrange bentry))))
                 ) (memory s2) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s3 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s2 nbleft
/\ s4 = {|
     currentPartition := currentPartition s3;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry0) 
                     (write bentry0) (exec bentry0) 
                     (present bentry0) (accessible bentry0)
                     (blockindex bentry0)
                     (CBlock (startAddr (blockrange bentry0)) endaddr))
                 ) (memory s3) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s4 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s3 nbleft
/\ s5 = {|
     currentPartition := currentPartition s4;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry1) 
                    (write bentry1) (exec bentry1) 
                    (present bentry1) true (blockindex bentry1)
                    (blockrange bentry1))
                 ) (memory s4) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s5 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s4 nbleft
/\ s6 = {|
     currentPartition := currentPartition s5;
     memory := add newBlockEntryAddr
               (BE
                  (CBlockEntry (read bentry2) (write bentry2) 
                     (exec bentry2) true (accessible bentry2)
                     (blockindex bentry2) (blockrange bentry2))
                 ) (memory s5) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s6 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s5 nbleft
/\ s7 = {|
     currentPartition := currentPartition s6;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry r (write bentry3) (exec bentry3)
                    (present bentry3) (accessible bentry3) 
                    (blockindex bentry3) (blockrange bentry3))
                 ) (memory s6) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s7 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s6 nbleft
/\ s8 = {|
     currentPartition := currentPartition s7;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) 
                       (present bentry4) (accessible bentry4) 
                       (blockindex bentry4) (blockrange bentry4))
                 ) (memory s7) beqAddr |} /\
getKSEntriesAux n1(structure pd1entry) s8 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s7 nbleft
/\ s9 = {|
     currentPartition := currentPartition s8;
     memory := add newBlockEntryAddr
              (BE
                 (CBlockEntry (read bentry5) (write bentry5) e 
                    (present bentry5) (accessible bentry5) 
                    (blockindex bentry5) (blockrange bentry5))
                 ) (memory s8) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s9 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s8 nbleft
/\ s10 = {|
     currentPartition := currentPartition s9;
     memory := add sceaddr 
								(SCE {| origin := origin; next := next scentry |}
                 ) (memory s9) beqAddr |} /\
getKSEntriesAux n1 (structure pd1entry) s10 nbleft =
			getKSEntriesAux n1 (structure pd1entry) s9 nbleft
).
{
	eexists ?[s1]. eexists ?[s2]. eexists ?[s3]. eexists ?[s4]. eexists ?[s5].
	eexists ?[s6]. eexists ?[s7]. eexists ?[s8]. eexists ?[s9].
	eexists ?[s10]. eexists ?[n1]. eexists.
	split. intuition.
	split. intuition.
	set (s1 := {| currentPartition := _ |}).
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure pd1entry) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s0 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd1 pd1entry Hlookuppd1s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	set (s2 := {| currentPartition := _ |}).
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s1 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd1 pd1entry Hlookuppd1s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- unfold isPDT. unfold s1. simpl. rewrite beqAddrTrue. trivial.
	}
	set (s3 := {| currentPartition := _ |}).
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s2 (CIndex maxNbPrepare)).
	{
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	set (s4 := {| currentPartition := currentPartition ?s3; memory := _ |}). simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s3 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
} fold s1. fold s2. fold s3. fold s4.
	set (s5 := {| currentPartition := currentPartition ?s4; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s4 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5.
	set (s6 := {| currentPartition := currentPartition ?s5; memory := _ |}).
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s5 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6.
	set (s7 := {| currentPartition := currentPartition ?s6; memory := _ |}).
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s6 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7.
	set (s8 := {| currentPartition := currentPartition ?s7; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s7 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8.
	set (s9 := {| currentPartition := currentPartition ?s8; memory := _ |}).
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s8 (CIndex maxNbPrepare)).
	{
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. unfold s2. unfold s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	set (s10 := {| currentPartition := currentPartition ?s9; memory := _ |}).
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure pd1entry) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd1entry) s9 (CIndex maxNbPrepare)).
	{		assert(HSCEs9 : isSCE sceaddr s9).
			{ unfold isSCE. unfold s9. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
				cbn.
				destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
				rewrite beqAddrTrue.
				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			apply getKSEntriesAuxEqSCE ; intuition.
}
	fold s1. fold s2. fold s3. fold s4. fold s5. fold s6. fold s7. fold s8. fold s9.
	fold s10.

	intuition.
	assert(HcurrLtmaxIdx : CIndex maxNbPrepare <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	lia.
}
														destruct Hfreeslotspd1Eq as [s1 (s2 & (s3 & (s4 & (s5 & (s6 & (s7 & (s8 & (s9 & (s10 &
																													(n1' & (nbleft' & (Hnbleft & Hstates))))))))))))].
														assert(HsEq : s10 = s).
														{ intuition. subst s1. subst s2. subst s3. subst s4. subst s5. subst s6.
															subst s7. subst s8. subst s9. subst s10.
															rewrite Hs. f_equal.
														}
														rewrite HsEq in *.
														assert(HfreeslotsEq : getKSEntriesAux n1' (structure pd1entry) s (CIndex maxNbPrepare) =
																									getKSEntriesAux (maxIdx+1) (structure pd1entry) s0 (CIndex maxNbPrepare)).
														{
															intuition.
															subst nbleft'.
															(* rewrite all previous getKSEntriesAux equalities *)
															rewrite <- H45. rewrite <- H53. rewrite <- H55. rewrite <- H57.
															rewrite <- H59. rewrite <- H61. rewrite <- H63. rewrite <- H65.
															rewrite <- H67. rewrite <- H70.
															reflexivity.
														}
														assert (HfreeslotsEqn1 : getKSEntriesAux n1' (structure pd1entry) s (CIndex maxNbPrepare)
																											= getKSEntriesAux (maxIdx + 1) (structure pd1entry) s (CIndex maxNbPrepare)).
														{ eapply getKSEntriesAuxEqN ; intuition.
															subst nbleft'. lia.
															assert (HnbLtmaxIdx : (CIndex maxNbPrepare) <= maxIdx) by apply IdxLtMaxIdx.
															lia.
														}
														(* specialize disjoint for pd1 and pd2 at s0 *)
														assert(HDisjointpd1pd2s0 : DisjointKSEntries s0)
															by (unfold consistency in * ; unfold consistency1 in * ; intuition).
														unfold DisjointKSEntries in *.
														assert(HPDTpd1s0 : isPDT pd1 s0) by (unfold isPDT ; rewrite Hlookuppd1s0 ; intuition).
														specialize (HDisjointpd1pd2s0 pd1 pd2 HPDTpd1s0 HPDTpd2s0 Hpd1pd2NotEq).
														apply isPDTLookupEq in HPDTpd2s0. destruct HPDTpd2s0 as [pd2entry Hlookuppd2s0].

														destruct HDisjointpd1pd2s0 as [optionfreeslotslistpd1 (optionfreeslotslistpd2 & (Hoptionfreeslotslistpd1 & (Hoptionfreeslotslistpd2 & HDisjointpd1pd2s0)))].
														(* we expect identical lists at s0 and s *)
														exists optionfreeslotslistpd1. exists optionfreeslotslistpd2.
														unfold getKSEntries.
														unfold getKSEntries in Hoptionfreeslotslistpd1.
														unfold getKSEntries in Hoptionfreeslotslistpd2.
														(*rewrite Hlookuppd1Eq. *)rewrite Hlookuppd2Eq.
														rewrite Hlookuppd1s0 in *.
														rewrite Hlookuppd2s0 in *.
														(*destruct (beqAddr (structure pd1entry) nullAddr) eqn:HfirstfreeNullpd1 ; try(exfalso ; congruence).*)
														destruct (beqAddr (structure pd2entry) nullAddr) eqn:HfirstfreeNullpd2 ; try(exfalso ; congruence).
														+ (* listoption2 = NIL *)
															(* always disjoint with nil *)
															subst optionfreeslotslistpd1.
															intuition.
															(* we are in the case listoption1 is equal at s and s0 *)
															rewrite <- HfreeslotsEqn1. subst nbleft'.
															rewrite Hpd1Null.
															rewrite <- H45. rewrite <- H53. rewrite <- H55. rewrite <- H57.
															rewrite <- H59. rewrite <- H61. rewrite <- H63. rewrite <- H65.
															rewrite <- H67. rewrite <- H70.
															reflexivity.
														+ (* listoption2 = NIL *)
															(* show list equality for listoption2 *)
															subst optionfreeslotslistpd1. subst optionfreeslotslistpd2.
															intuition.
															rewrite <- HfreeslotsEqn1. subst nbleft'.
															rewrite Hpd1Null.
															rewrite <- H45. rewrite <- H53. rewrite <- H55. rewrite <- H57.
															rewrite <- H59. rewrite <- H61. rewrite <- H63. rewrite <- H65.
															rewrite <- H67. rewrite <- H70.
															reflexivity.

															(* state already cut into intermediate states *)
															assert(Hfreeslotspd2Eq : exists n1 nbleft,
nbleft = (CIndex maxNbPrepare) /\
getKSEntriesAux n1 (structure pd2entry) s1 nbleft =
getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 nbleft
			 /\
	n1 <= maxIdx+1 /\ nbleft < n1
/\
getKSEntriesAux n1 (structure pd2entry) s2 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s1 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s3 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s2 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s4 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s3 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s5 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s4 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s6 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s5 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s7 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s6 nbleft
/\
getKSEntriesAux n1(structure pd2entry) s8 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s7 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s9 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s8 nbleft
/\
getKSEntriesAux n1 (structure pd2entry) s10 nbleft =
			getKSEntriesAux n1 (structure pd2entry) s9 nbleft
).
{
	eexists ?[n1]. eexists.
	split. intuition.
	(* prove outside *)
	assert(Hfreeslotss1 : getKSEntriesAux ?n1 (structure pd2entry) s1 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
{		subst s1.
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- trivial.
	}
	assert(Hfreeslotss2 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s1 (CIndex maxNbPrepare)).
	{ subst s2.
		apply getKSEntriesAuxEqPDT.
		-- (* prove wrong type if equality *)
				intro Hfirstpdeq.
				assert(HStructurePointerIsKSs0 : StructurePointerIsKS s0)
					by (unfold consistency in * ; unfold consistency1 in * ; intuition).
				unfold StructurePointerIsKS in *.
				specialize (HStructurePointerIsKSs0 pd2 pd2entry Hlookuppd2s0).
				unfold isKS in *.
				rewrite Hfirstpdeq in *.
				rewrite Hpdinsertions0 in *. congruence.
		-- unfold isPDT. subst s1. simpl. rewrite beqAddrTrue. trivial.
	}
	assert(Hfreeslotss3 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s2 (CIndex maxNbPrepare)).
	{	subst s3.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s4. simpl in s3.
	assert(Hfreeslotss4 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s3 (CIndex maxNbPrepare)).
	{	subst s4.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s4.
	assert(Hfreeslotss5 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s4 (CIndex maxNbPrepare)).
	{	subst s5.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s4. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s4.
	assert(Hfreeslotss6 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s5 (CIndex maxNbPrepare)).
	{	subst s6.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s5. simpl in s6.
	assert(Hfreeslotss7 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s6 (CIndex maxNbPrepare)).
	{	subst s7.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s6. subst s5. subst s4. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s7.
	assert(Hfreeslotss8 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s7 (CIndex maxNbPrepare)).
	{	subst s8.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s7. subst s6. subst s5.
				subst s4. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s7.
	assert(Hfreeslotss9 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s8 (CIndex maxNbPrepare)).
	{ subst s9.
		(* DUP *)
		apply getKSEntriesAuxEqBE ; intuition.
		--- unfold isBE. subst s8. subst s7. subst s6. subst s5.
				subst s4. subst s3. subst s2. subst s1. cbn.
				destruct (beqAddr pdinsertion newBlockEntryAddr) ; try(exfalso ; congruence).
				rewrite beqAddrTrue.
				cbn.
				repeat rewrite removeDupIdentity ; intuition.
}
	simpl in s8. simpl in s9.
	assert(Hfreeslotss10 : getKSEntriesAux (maxIdx + 1) (structure pd2entry) s10 (CIndex maxNbPrepare) =
getKSEntriesAux (maxIdx + 1) (structure pd2entry) s9 (CIndex maxNbPrepare)).
	{			assert(HSCEs9 : isSCE sceaddr s9).
				{ unfold isSCE. subst s9. subst s8. subst s7. subst s6. subst s5.
					subst s4. subst s3. subst s2. subst s1. cbn. rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf ; try(exfalso ; congruence).
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
					destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
					cbn.
					destruct (beqAddr pdinsertion sceaddr) eqn:Hfff ; try(exfalso ; congruence).
					rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
					rewrite beqAddrTrue.
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
				}
				subst s10. rewrite H68. (* s = currentPartition s9  ...*)
			apply getKSEntriesAuxEqSCE ; intuition.
	}
	intuition.
	assert(HcurrLtmaxIdx : (CIndex maxNbPrepare) <= maxIdx).
	{ intuition. apply IdxLtMaxIdx. }
	intuition.
	assert(Hmax : maxIdx + 1 = S maxIdx) by (apply MaxIdxNextEq).
	rewrite Hmax. apply Lt.le_lt_n_Sm. intuition.
}
															destruct Hfreeslotspd2Eq as [n1'' (nbleft'' & Hstates)].
															rewrite HsEq in *.
															assert(HfreeslotsEqpd2 : getKSEntriesAux n1'' (structure pd2entry) s (CIndex maxNbPrepare) =
																										getKSEntriesAux (maxIdx+1) (structure pd2entry) s0 (CIndex maxNbPrepare)).
															{
																intuition.
																subst nbleft''.
																(* rewrite all previous getKSEntriesAux equalities *)
																rewrite H83. rewrite H81. rewrite H80. rewrite H79.
																rewrite H78. rewrite H77. rewrite H76. rewrite H75.
																rewrite H74. rewrite H72.
																reflexivity.
															}
															assert (HfreeslotsEqn1' : getKSEntriesAux n1'' (structure pd2entry) s (CIndex maxNbPrepare)
																												= getKSEntriesAux (maxIdx + 1) (structure pd2entry) s (CIndex maxNbPrepare)).
															{ eapply getKSEntriesAuxEqN ; intuition.
																subst nbleft''. lia.
																assert (HnbLtmaxIdx : (CIndex maxNbPrepare) <= maxIdx) by apply IdxLtMaxIdx.
																lia.
															}
															rewrite <- HfreeslotsEqn1'. rewrite HfreeslotsEqpd2. intuition.
} (* end of DisjointKSEntries *)

	assert(HnoDupPartitionTrees : noDupPartitionTree s).
	{ (* noDupPartitionTree s *)
		(* WIP *)
		(* equality of list getPartitions already proven so immediate proof *)
		admit.
	} (* end of noDupPartitionTree *)

	assert(HisParents : isParent s).
	{ (* isParent s *)
		(* equality of lists getPartitions and getChildren for any partition already proven
			+ no change of pdentry so immediate proof *)
			assert(Hcons0 : isParent s0) by (unfold consistency in * ; unfold consistency1 in * ; intuition).
			unfold isParent.
			intros pd parent HparentInPartTree HpartChild.
			assert(HpdPDT : isPDT pd s).
			{
				apply childrenArePDT with parent; intuition.
			}
			unfold pdentryParent.
			apply isPDTLookupEq in HpdPDT. destruct HpdPDT as [partpdentry Hlookuppds].
			rewrite Hlookuppds.

			(* Check all values for pd *)
			destruct (beqAddr sceaddr pd) eqn:beqscepd; try(exfalso ; congruence).
			-	(* sceaddr = pd *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqscepd.
				rewrite <- beqscepd in *.
				unfold isSCE in *.
				unfold isPDT in *.
				destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
			-	(* sceaddr <> pd *)
				destruct (beqAddr newBlockEntryAddr pd) eqn:beqnewpd ; try(exfalso ; congruence).
				-- (* newBlockEntryAddr = pd *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
						rewrite <- beqnewpd in *.
						unfold isBE in *.
						unfold isPDT in *.
						destruct (lookup newBlockEntryAddr (memory s) beqAddr) ; try(exfalso ; congruence).
				-- (* newBlockEntryAddr <> pd *)
						destruct (beqAddr pdinsertion pd) eqn:beqpdpd; try(exfalso ; congruence).
						--- (* pdinsertion = pd *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpd.
								rewrite <- beqpdpd in *.
								assert(HpdentryEq : partpdentry = pdentry1).
								{
									rewrite Hlookuppds in *. inversion Hpdinsertions. trivial.
								}
								rewrite HpdentryEq.
								subst pdentry1. cbn.
								subst pdentry0. cbn. trivial.
								assert(HparentInPartTrees0 : In parent (getPartitions multiplexer s0))
									by admit. (* after lists propagation*)
								assert(HpartChilds0 : In pdinsertion (getChildren parent s0))
									by admit. (* after lists propagation*)
								unfold isParent in *.
								specialize (Hcons0 pdinsertion parent HparentInPartTrees0 HpartChilds0).
								unfold pdentryParent in *.
								rewrite Hpdinsertions0 in *.
								assumption.
						--- (* pdinsertion <> pd *)
								assert(HlookuppsEq : lookup pd (memory s) beqAddr = lookup pd (memory s0) beqAddr).
								{
									admit.
								}
								assert(HparentInPartTrees0 : In parent (getPartitions multiplexer s0))
									by admit. (* after lists propagation*)
								assert(HpartChilds0 : In pd (getChildren parent s0))
									by admit.
								unfold isParent in *.
								specialize (Hcons0 pd parent HparentInPartTrees0 HpartChilds0).
								unfold pdentryParent in *.
								rewrite HlookuppsEq in *.
								rewrite Hlookuppds in *.
								assumption.
	} (* end of isParent *)

	assert(HisChilds : isChild s).
	{ (* isChild s *)
		(* equality of lists getPartitions and getChildren for any partition already proven
			+ no change of pdentry so immediate proof *)
		admit.
	} (* end of isChild *)

	assert(HaccessibleChildPaddrIsAccessibleIntoParents : accessibleChildPaddrIsAccessibleIntoParent s).
	{ (* accessibleChildPaddrIsAccessibleIntoParent s *)
		(* similar to vertical sharing *)
		admit.
	} (* end of accessibleChildPaddrIsAccessibleIntoParent *)

	assert(HnoDupKSEntriesLists : noDupKSEntriesList s).
	{ (* noDupKSEntriesList s *)
		admit.
	} (* end of noDupKSEntriesList *)

	assert(HnoDupMappedBlocksLists : noDupMappedBlocksList s).
	{ (* noDupMappedBlocksList s *)
		admit.
	} (* end of noDupMappedBlocksList *)

	assert(HnoDupUsedPaddrLists : noDupUsedPaddrList s).
	{ (* noDupUsedPaddrList s *)
		(* equality of lists getPartitions and getChildren for already proven any partition
				except globalidPDchild whose NoDup property is already proven so immediate proof *)
		admit.
	} (* end of noDupUsedPaddrList *)

	intuition.

	- (* Final state *)
		exists pdentry. exists pdentry0. exists pdentry1.
		exists bentry. exists bentry0. exists bentry1. exists bentry2. exists bentry3.
		exists bentry4. exists bentry5. exists bentry6. exists sceaddr. exists scentry.
		exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
		intuition.
		(*-- (* isPDT multiplexer s0 *)
				admit.*)
		-- (* sceaddr = newBlockEntryAddr *)
				assert(Hfalse : sceaddr = newBlockEntryAddr) by intuition.
				rewrite <- Hfalse in *.
				unfold isSCE in *.
				destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* sceaddr = pdinsertion *)
				assert(Hfalse : sceaddr = pdinsertion) by intuition.
				rewrite <- Hfalse in *.
				unfold isSCE in *.
				unfold isPDT in *.
				destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- 	(* sceaddr = newFirstFreeSlotAddr *)
				assert(newFsceNotEq : newFirstFreeSlotAddr <> sceaddr).
				{ apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [scentrys0 HSCEs0].
					subst sceaddr.
					apply (@newFirstSCENotEq (CPaddr (newBlockEntryAddr + scoffset))
																		scentrys0
																		newBlockEntryAddr
																		newFirstFreeSlotAddr
																		pdinsertion pdentry s0) ; intuition.
				}
				congruence.
		-- (* lists *)
				admit.
		-- (* intermediate steps *)
				eexists. eexists. eexists. eexists. eexists. eexists. eexists. eexists.
				eexists. eexists.
				intuition.
Admitted.
