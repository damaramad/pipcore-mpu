(*******************************************************************************)
(*  © Université Lille 1, The Pip Development Team (2015-2018)                 *)
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
    This file contains PIP memory services : [createPartition],
      [deletePartition], [addVAddr], [removeVAddr], [countToMap],
      [prepare] and [collect].

    The definitions of recursive functions like [countToMap], [prepare] and
      [collect] match the same form :
      - part 1 : <<functionNameRec>> is the recursive funtion
      - part 2 : <<functionNameAux>> fixes the sufficient timeout value for recursion
                 to complete
      - part 3 : <<funtionName>> is the PIP service. It calls <<functionNameAux>>
                with the required parameters *)

Require Import Model.Monad Model.MAL Core.Internal.
Import Bool Arith List List.ListNotations.

Open Scope mpu_state_scope.

(** ** The createPartition PIP MPU service

    The [createPartition] system call creates a new child (sub-partition of the
    current partition), e.g. initializes the block <idBlock> as a PD block and 
		sets the current partition as the parent partition.
		Returns true:OK/false:NOK

    <<idBlock>>       	The block to become the child Partition Descriptor 
												(id = start field of an existing block)
*)
Definition createPartition (idBlock: paddr) : LLI bool :=
    (** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in

(*	# entrée MPU <- ChercherBlocDansMPU(idPartitionCourante, idBloc)
    block_in_current_partition_address = self.__find_block_in_MPU(self.current_partition, idBlock)
    *)
		(** Find the block in the current partition *)
    perform blockInCurrentPartitionAddr := findBlockInMPU currentPart idBlock in
		
		(** Check the block exists and not shared and size > minimum MPU region size ELSE NOK*)
(*
    if block_in_current_partition_address == -1:
        # no block found, stop
        return 0*)
		perform addrIsNull := compareAddrToNull	blockInCurrentPartitionAddr in
		if addrIsNull then(** no block found, stop *) ret false else
		(*block_MPU_entry = self.helpers.get_MPU_entry(block_in_current_partition_address) *)

(*
    if not block_MPU_entry[3]:
        # block is inaccessible
        return 0
		*)
		(* TODO check present ?*)
		perform addrIsAccessible := readMPUAccessibleFromMPUEntryAddr	blockInCurrentPartitionAddr in
		if negb addrIsAccessible then (** block is inaccessible *) ret false else
(*
    if (block_MPU_entry[2] - block_MPU_entry[1]) < self.constants.MPU_region_min_size:
        # block is smaller than the MPU region constraint
        return 0 
*)
		perform blockSize := sizeOfBlock blockInCurrentPartitionAddr in
		perform minBlockSize := getMinBlockSize in
		perform isBlockTooSmall := Paddr.leb blockSize minBlockSize in
		if isBlockTooSmall then (** block is smaller than the minimum  *) ret false 
		else

(*
    if self.helpers.get_Sh1_PDchild_from_MPU_entry_address(block_in_current_partition_address) != 0:
        # block is already shared with a child partition
        return 0  # TODO: return NULL*)
		(* if accessible, then PDflag can't be set, we just need to check PDchild *)
		perform PDChildAddr := readSh1PDChildFromMPUEntryAddr	blockInCurrentPartitionAddr in
		perform PDChildAddrIsNull := compareAddrToNull PDChildAddr in
		if negb PDChildAddrIsNull (*shouldn't be null*) then ret false else

(*

    # // Initialiser bloc PD enfant
    # blocPD <- RécupérerBloc(entrée MPU)
    new_PD_block = self.helpers.get_MPU_start_from_MPU_entry_address(block_in_current_partition_address)*)
		perform newPDBlockStartAddr := readMPUStartFromMPUEntryAddr blockInCurrentPartitionAddr in
		perform newPDBlockEndAddr := readMPUEndFromMPUEntryAddr blockInCurrentPartitionAddr in
(*
    # Mettre à 0 le blocPD entier (ou jusqu’à index pointeur libre-> cas où le bloc est très grand)
    for i in range(self.helpers.get_MPU_start_from_MPU_entry_address(block_in_current_partition_address),
                   self.helpers.get_MPU_end_from_MPU_entry_address(block_in_current_partition_address)):
        self.memory.write_bit(i, 0)*)
		(** Erase the future Partition Descriptor content*)
		eraseBlock newPDBlockStartAddr newPDBlockEndAddr;;

(*
    # Ecrire NULL à blocPD[index MPU]
    self.helpers.set_PD_pointer_to_MPU_linked_list(new_PD_block, 0)*)
		(* create PD Table by setting the structure to the default values *)
		initPDTable newPDBlockStartAddr ;;
		perform nullAddr := getNullAddr in
		writePDStructurePointer newPDBlockStartAddr nullAddr ;;


		perform zero := MALInternal.Index.zero in
(*
    # Ecrire 0 à blocPD[compteur libre]
    self.helpers.set_PD_nb_free_slots(new_PD_block, 0)*)
		writePDNbFreeSlots newPDBlockStartAddr zero ;;
(*
    # Ecrire NULL à blocPD[pointeur libre]
    self.helpers.set_PD_first_free_slot_address(new_PD_block, 0)*)
		writePDFirstFreeSlotAddr newPDBlockStartAddr nullAddr ;;

(*
    # Ecrire 0 à blocPD[compteur nbPrepare]
    self.helpers.set_PD_nb_prepare(new_PD_block, 0)*)
		writePDNbPrepare newPDBlockStartAddr zero ;;
(*
    # //Lier PD enfant à la partition courante
    # Ecrire PDcourant à blocPD[parent]
    self.helpers.set_PD_parent(new_PD_block, self.current_partition)*)
		writePDParent newPDBlockStartAddr currentPart ;;

(*
    # Ecrire FALSE dans MPUcourant[entrée MPU]->Accessible (bloc inaccessible pour la partition courante)
    self.helpers.set_MPU_accessible_from_MPU_entry_address(block_in_current_partition_address, False)*)
		(** Reflect the child Partition Description creation in the current partition *)
		(** set the block as not available anymore*)
		writeMPUAccessibleFromMPUEntryAddr blockInCurrentPartitionAddr false ;;
(*
    # Ecrire TRUE dans Shadow1courant[entrée MPU]->PDflag (bloc marqué comme PD dans la partition courante)
    self.helpers.set_Sh1_PDflag_from_MPU_entry_address(block_in_current_partition_address, True)*)
		(** set the block as a PD block in shadow 1*)
		writeSh1PDFlagFromMPUEntryAddr blockInCurrentPartitionAddr true ;;
(*
    # Si SCcourant[entrée MPU]->origine == (entrée MPU)->start || SC[courant[entrée MPU]->suivant == NULL alors (si le bloc n’a pas été coupé auparavant, il faut le rendre inaccessible aux ancêtres)
    if (self.helpers.get_SC_origin_from_MPU_entry_address(block_in_current_partition_address)
            == self.helpers.get_MPU_start_from_MPU_entry_address(block_in_current_partition_address))\
            and (self.helpers.get_SC_next_from_MPU_entry_address(block_in_current_partition_address) == 0):
        # Ecrire FALSE dans (ancêtres).Accessible (O(p) parait acceptable pour un createPartition, sinon besoin de stocker l’adresse du bloc dans les ancêtres)
        self.__write_accessible_to_ancestors_rec(self.current_partition, idBlock, False)*)
		(** set the block as not accessible anymore to the ancestors *)
		perform blockOrigin := readSCOriginFromMPUEntryAddr blockInCurrentPartitionAddr in
		perform blockStart := readMPUStartFromMPUEntryAddr blockInCurrentPartitionAddr in
		perform blockNext := readSCNextFromMPUEntryAddr blockInCurrentPartitionAddr in
		if beqAddr blockOrigin blockStart && beqAddr blockNext nullAddr then
			(* Block hasn't been cut previously, need to be set unaccessible for the ancestors *)
			writeAccessibleRec currentPart idBlock false ;;
			ret true 
		else
(*
    #
    # RET OK
    return 1*)
		ret true.

(** ** The cutMemoryBlock PIP MPU service

    The [cutMemoryBlock] system call cuts the memory block <idBlockToCut> 
		at <cutAddress> which creates a new subbblock at that address.
		Returns the new created subblock's MPU address:OK/NULL:NOK

    <<idBlockToCut>>		the block to cut
												(id = start field of an existing block)
		<<cutAddress>>			the address where to cut the <idBlockToCut> block, 
												becomes the id of the created block
*)
Definition cutMemoryBlock (idBlockToCut cutAddr : paddr) : LLI paddr :=
(*    def cutMemoryBlock(self, idBlockToCut, cutAddress):
    """Cuts the memory block <idBlockToCut> and creates a new block at <cutAddress>
    :param idBlockToCut: the block to cut
    :param cutAddress: the address where to cut the <idBlockToCut> block, becomes the id of the created block
    :return: address of the created block's MPU location:OK/0:NOK
    """*)
    (** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in
(*
    # check that there is a free slot left
    if self.helpers.get_PD_nb_free_slots(self.current_partition) <= 0:
        # no free slot, stop
        return 0  # TODO: return NULL*)
		(** Check that there is a free slot left*)
		perform nbFreeSlots := readPDNbFreeSlots currentPart in
		perform zero := Index.zero in
		perform isFull := Index.leb nbFreeSlots zero in
		if isFull then ret nullAddr else
(*
    # find the block in the current partition's MPU structure
    block_to_cut_MPU_address= self.__find_block_in_MPU(self.current_partition, idBlockToCut)
    if block_to_cut_MPU_address == -1:
        # no block found, stop
        return 0 # TODO: return NULL*)
		(** Find the block in the current partition *)
    perform blockToCutMPUAddr := findBlockInMPU currentPart idBlockToCut in
		perform addrIsNull := compareAddrToNull	blockToCutMPUAddr in
		if addrIsNull then(** no block found, stop *) ret nullAddr else

(*
    block_to_cut_MPU_entry = self.helpers.get_MPU_entry(block_to_cut_MPU_address)
    block_to_cut_Sh1_entry = self.helpers.get_Sh1_entry_from_MPU_entry_address(block_to_cut_MPU_address)
    # check that the block is accessible + not shared
    if block_to_cut_MPU_entry[3] == False \
        or block_to_cut_Sh1_entry[0] != 0 \
        or block_to_cut_Sh1_entry[1] == True:
        # root is always 0 so an entry 0 in shared is default
        return 0 # TODO: return NULL*)
		(** Check the block to cut is accessible *)
		perform blockIsAccessible := readMPUAccessibleFromMPUEntryAddr blockToCutMPUAddr in
		if negb blockIsAccessible then (** block is inaccessible *) ret nullAddr else

		(** Check the block is not shared TODO: changed condition *)
		(* if accessible, then PDflag can't be set, we just need to check PDchild is null*)
		perform PDChildAddr := readSh1PDChildFromMPUEntryAddr	blockToCutMPUAddr in
		perform PDChildAddrIsNull := compareAddrToNull PDChildAddr in
		if negb PDChildAddrIsNull (*shouldn't be null*) then ret nullAddr else

(*
    # Check that the cut address lies between the start and the end address
    if cutAddress < block_to_cut_MPU_entry[1] or cutAddress > block_to_cut_MPU_entry[2]:
        # cutAddress outside bounds
        return 0  # TODO: return NULL*)
		(** Check the cut address lies between the start and the end address *)
		perform blockToCutStartAddr := readMPUStartFromMPUEntryAddr blockToCutMPUAddr in
		perform isCutAddrBelowStart := Paddr.leb cutAddr blockToCutStartAddr in
		if isCutAddrBelowStart then (**cutAddress outside bounds*) ret nullAddr else

		perform blockToCutEndAddr := readMPUEndFromMPUEntryAddr blockToCutMPUAddr in
		perform isCutAddrAboveEnd := Paddr.leb blockToCutEndAddr cutAddr in
		if isCutAddrAboveEnd then (**cutAddress outside bounds*) ret nullAddr else
(*
    # check that the new subblockS is at least 32 bytes (don't care if power of 2 because could be intermdiary)*)
		(** Check that the block is greater than the minimum MPU region size*)
		perform blockSize := sizeOfBlock blockToCutMPUAddr in
		perform minBlockSize := getMinBlockSize in
		perform isBlockTooSmall := Paddr.leb blockSize minBlockSize in
		if isBlockTooSmall then (** block is smaller than the minimum  *) ret nullAddr 
		else
(*
    # // Parent et ancêtres : si on coupe le bloc pour la 1ère fois, on rend ce bloc inaccessible aux ancêtres
    # Ecrire FALSE à MPU[ancêtres].accessible (O(p) car recherche dans p ancêtres, sinon besoin de stocker l’adresse du bloc dans l’ancêtre direct pour O(p))
    block_origin = self.helpers.get_SC_origin_from_MPU_entry_address(block_to_cut_MPU_address)
    if (self.helpers.get_SC_next_from_MPU_entry_address(block_to_cut_MPU_address) == 0) and \
            (block_origin == idBlockToCut):
        self.__write_accessible_to_ancestors_rec(self.current_partition, block_to_cut_MPU_entry[1], False)*)
		(** Parents and ancestors: set the block unaccessible if this is the block's first cut*)
		perform blockOrigin := readSCOriginFromMPUEntryAddr blockToCutMPUAddr in
		perform blockNext := readSCNextFromMPUEntryAddr blockToCutMPUAddr in
		writeAccessibleToAncestorsIfNoCut currentPart idBlockToCut blockToCutMPUAddr
																			false ;;
(*
    # // Enfant : on créé un sous-bloc dérivé du bloc initial
    # adresse MPU insertion <- insérerEntrée(idPDcourant, entrée à insérer, SC[entrée MPU courant]->origin) (insérer le nouveau bloc créé avec la même origine que le bloc initial)
    new_entry = block_to_cut_MPU_entry
    # the new entry has the same characteristics as the initial block except the start address becomes cutAddress
    new_entry[1] = cutAddress  # index 1 is start address
    new_entry_MPU_address = self.__insert_new_entry(
        self.current_partition,
        new_entry,
        block_origin
    )*)
		(** Child: create the new subblock at cutAddr and insert it in the kernel structure*)
		perform blockEndAddr := readMPUEndFromMPUEntryAddr blockToCutMPUAddr in
		perform newSubblockMPUAddr := insertNewEntry currentPart cutAddr blockEndAddr blockOrigin in

(*
    # // Modifier le bloc initial
    # modify initial block: the end address becomes (cutAddress - 1)
    self.helpers.set_MPU_end_from_MPU_entry_address(block_to_cut_MPU_address, cutAddress - 1)*)
		(** Modify initial block: the end address becomes (cutAddress - 1)*)
		perform predCutAddr := Paddr.pred cutAddr in
		writeMPUEndFromMPUEntryAddr blockToCutMPUAddr predCutAddr ;;

(*
    #  // Indiquer coupe dans Shadow Cut : bloc pourrait déjà être coupé auquel cas on doit l’insérer correctement dans la liste chaînée SC
    # sous-bloc suivant <- SC[entrée MPU courant]->suivant (récupérer le pointeur vers le sous-bloc suivant, NULL si 1ère coupe ou fin de liste)
    next_subblock = self.helpers.get_SC_next_from_MPU_entry_address(block_to_cut_MPU_address)
		# Ecrire (sous-bloc suivant) à SC[adresse MPU insertion]->suivant (faire pointer le nouveau sous-bloc vers le sous-bloc suivant, NULL si 1ère coupe)
    self.helpers.set_SC_next_from_MPU_entry_address(new_entry_MPU_address, next_subblock)
		# Ecrire (adresse MPU insertion) à SC[entrée MPU courant]->suivant (faire pointer le bloc coupé vers le nouveau sous-bloc créé)
    self.helpers.set_SC_next_from_MPU_entry_address(block_to_cut_MPU_address, new_entry_MPU_address)

*)
		(** Register the cut in the Shadow Cut: insert in middle if needed*)
		perform originalNextSubblock := readSCNextFromMPUEntryAddr blockToCutMPUAddr in
		writeSCNextFromMPUEntryAddr newSubblockMPUAddr originalNextSubblock ;;
		writeSCNextFromMPUEntryAddr blockToCutMPUAddr newSubblockMPUAddr ;;
(*
    #  RET @coupe
    return new_entry_MPU_address*)
		ret newSubblockMPUAddr.


(** ** The mergeMemoryBlocks PIP MPU service

    The [mergeMemoryBlocks] system call merges <idBlockToMerge1> and
		<idBlockToMerge2> together.
		The two blocks have been cut before so idBlockToMerge1 < idBlockToMerge2.

		Returns idBlockToMerge1:OK/NULL:NOK

    <<idBlockToMerge1>>	the block to merge in becomes the id of the merged blocks
												(id = start field of an existing block)
		<<idBlockToMerge2>>	the block to be merged disappears from the lits of blocks
												(id = start field of an existing block)
*)
Definition mergeMemoryBlocks (idBlockToMerge1 idBlockToMerge2 : paddr) : LLI paddr :=
(*    def mergeMemoryBlocks(self, idBlockToMerge1, idBlockToMerge2):
    """Merge <idBlockToMerge1> and <idBlockToMerge2> together
    """*)
    (** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in
(*
    """fusionne 2 blocs dont le deuxième a été obtenu à partir du premier (@bloc1 < @bloc2) (O(p))"""
    # entrée MPU courant 1 <- ChercherBlocDansMPU(idPDcourant, idBlocAFusionner1)
    block_to_merge1_address = self.__find_block_in_MPU(self.current_partition, idBlockToMerge1)
    if block_to_merge1_address == -1:
        # no block found, stop
        return 0  # TODO: return NULL
*)
		(* Find idBlockToMerge1 in the current partition *)
    perform block1InCurrPartAddr := findBlockInMPU currentPart idBlockToMerge2 in
		perform addrIsNull := compareAddrToNull	block1InCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret nullAddr else
(*
    # entrée MPU courant 2 <- ChercherBlocDansMPU(idPDcourant, idBlocAFusionner2)
    block_to_merge2_address = self.__find_block_in_MPU(self.current_partition, idBlockToMerge2)
    if block_to_merge2_address == -1:
        # no block found, stop
        return 0  # TODO: return NULL
*)
		(* Find idBlockToMerge2 in the current partition *)
    perform block2InCurrPartAddr := findBlockInMPU currentPart idBlockToMerge2 in
		perform addrIsNull := compareAddrToNull	block2InCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret nullAddr else

		(** Checks**)
(*
    # Vérifier que les blocs ne sont pas partagés et accessibles (voir Sh1)
    # Check blocks are accessible
    if (self.helpers.get_MPU_accessible_from_MPU_entry_address(block_to_merge1_address) is False
            or self.helpers.get_MPU_accessible_from_MPU_entry_address(block_to_merge2_address) is False):
        # one/both blocks not accessible, stop
        return 0  # TODO: return NULL
*)
		(* Check blocks are accessible *)
		perform isBlock1Accessible := readMPUAccessibleFromMPUEntryAddr block1InCurrPartAddr in
		perform isBlock2Accessible := readMPUAccessibleFromMPUEntryAddr block2InCurrPartAddr in
		if negb (isBlock1Accessible && isBlock2Accessible)
		then (* one/both blocks not accessible, stop *) ret nullAddr
		else
(*
    # Check blocks are not shared
    if ((self.helpers.get_Sh1_PDchild_from_MPU_entry_address(block_to_merge1_address) != 0
            or self.helpers.get_Sh1_PDflag_from_MPU_entry_address(block_to_merge1_address) is True)
        or (self.helpers.get_Sh1_PDchild_from_MPU_entry_address(block_to_merge2_address) != 0
            or self.helpers.get_Sh1_PDflag_from_MPU_entry_address(block_to_merge2_address) is True)):
        # one/both blocks shared
        return 0  # TODO: return NULL
*)
		(* Check blocks are not shared TODO changed condition*)
		(* if accessible, then PDflag can't be set, we just need to check PDchild *)
		perform block1PDChildAddr := readSh1PDChildFromMPUEntryAddr	block1InCurrPartAddr in
		perform block1PDChildAddrIsNull := compareAddrToNull block1PDChildAddr in
		perform block2PDChildAddr := readSh1PDChildFromMPUEntryAddr	block2InCurrPartAddr in
		perform block2PDChildAddrIsNull := compareAddrToNull block2PDChildAddr in
		if block1PDChildAddrIsNull || block2PDChildAddrIsNull
		then (* one/both blocks shared, stop *) ret nullAddr
		else

		(* Check block 2 follows block 1 TODO changed check order with following instruction*)
(*
    else:
        # block 2 does not follow block 1, no merge possible, stop
        return 0  # TODO: return NULL*)
		perform block1Next := readSCNextFromMPUEntryAddr block1InCurrPartAddr in
		perform isBlock2Next := getBeqAddr idBlockToMerge2 block1Next in
		if isBlock2Next then (* no merge possible, stop*) ret nullAddr else

		(** Merge block 2 in block 1 *)
(*
    # SI SC[entrée MPU courant1]->suivant == entrée MPU courant 2 ALORS (le 1er sous-bloc pointe vers le 2e)
    if self.helpers.get_SC_next_from_MPU_entry_address(block_to_merge1_address) == block_to_merge2_address:
        # Block2 is block1's next cut -> Merge both blocks
        # // Fusionner les données entre les blocs
        # Ecrire SC[entrée MPU courant 2] ->suivant à SC[entrée MPU courant 1]->suivant (faire pointer le sous-bloc 1 vers le suivant du sous-bloc 2)
        self.helpers.set_SC_next_from_MPU_entry_address(
            block_to_merge1_address,
            self.helpers.get_SC_next_from_MPU_entry_address(block_to_merge2_address)
        )
*)
		(* replace block 1's next subblock with block 2's next subblock *)
		perform block2Next := readSCNextFromMPUEntryAddr block2InCurrPartAddr in
		writeSCNextFromMPUEntryAddr block1InCurrPartAddr block2Next ;;

(*
        # Ecrire MPUcourant[entrée MPU courant 2]->end à MPUcourant[entrée MPU courant 1]->end (fusionner le sous-bloc 2 dans le sous-bloc 1)
        self.helpers.set_MPU_end_from_MPU_entry_address(
            block_to_merge1_address,
            self.helpers.get_MPU_end_from_MPU_entry_address(block_to_merge2_address)
        )
*)
		(* replace block 1's end address with block 2's end address *)
		perform block2MPUEnd := readMPUEndFromMPUEntryAddr block2InCurrPartAddr in
		writeMPUEndFromMPUEntryAddr block1InCurrPartAddr block2MPUEnd ;;

(*
        # // Supprimer le bloc 2
        # Remove block 2
        # libérerEmplacement(PD courant, entrée MPU courant 2)
        self.__free_slot(self.current_partition, block_to_merge2_address)
*)
		(* remove block 2 entry TODO *)
		freeSlot currentPart block2InCurrPartAddr ;;
(*
        # //Parent : remet le bloc accessible si plus aucun sous-blocs
        # Parent : set block back to accessible if no more subblocks
        # SI SC[entrée MPU courant 1]->origine == (entrée MPU courant 1)->start ET SC[entrée MPU courant 1]->suivant == NULL ALORS (Plus de sous-blocs)
        if self.helpers.get_SC_origin_from_MPU_entry_address(block_to_merge1_address) == idBlockToMerge1 and \
                self.helpers.get_SC_next_from_MPU_entry_address(block_to_merge1_address) == 0:
            # back to initial block before cut
            # Ecrire TRUE à MPU[ancêtres].accessible (O(p) car recherche dans p ancêtres, sinon besoin de stocker l’adresse du bloc dans l’ancêtre direct pour O(p))
            self.__write_accessible_to_ancestors_rec(self.current_partition, idBlockToMerge1, True)
        # SINON rien
*)
		(** Parents and ancestors: set the block accessible again if there are no
		subblocks anymore of block 1 TODO rename with RecAux ?*)
		perform blockOrigin := readSCOriginFromMPUEntryAddr block1InCurrPartAddr in
		perform blockNext := readSCNextFromMPUEntryAddr block1InCurrPartAddr in
		writeAccessibleToAncestorsIfNoCut currentPart
																			idBlockToMerge1 block1InCurrPartAddr
																			true ;;
(*
    # RET @bloc 1
    return block_to_merge1_address
*)
		ret idBlockToMerge1.


(** ** The prepare PIP MPU service

    The [prepare] system call prepares the partition <idPD> (current partition 
		or child) to receive <projectedSlotsNb> of blocks and use the 
		<idRequisitionedBlock> as a metadata structure, e.g. this will prepare 
		<idRequisitionedBlock> to be a kernel structure added to the kernel structure 
		list of the partition <idPD>
        - if enough free slots to receive <projectedSlotsNb> then won't do anything
				- if not enough free slots then prepare the block
        - if <projectedSlotsNb> == nb of kernel structure entries then will 
				prepare anyways the block
		Returns true:OK/false:NOK

    <<idPD>>									the block to prepare (current partition or a child)
															(id = start field of an existing block)
		<<projectedSlotsNb>>			the number of requested slots
		<<idRequisitionedBlock>>	the block used as the new kernel structure
*)
Definition prepare (idPD : paddr) (projectedSlotsNb : index)
									(idRequisitionedBlock : paddr) : LLI bool :=
		(** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in

		(** Checks**)
(*
    # Vérifier que idPD est soit lui-même soit un enfant + nbPrepare<=MaxNbPrepare SINON RET NOK
    if idPD != self.current_partition and self.__checkChild(self.current_partition, idPD) == 0:
        # idPD is not itself or a child partition, stop
        return 0  # TODO: return NULL*)
		(* Check idPD is the current partition or one of its child*)
		perform isCurrentPart := getBeqAddr idPD currentPart in
		perform isChildCurrPart := checkChild currentPart idPD in
		if negb isCurrentPart && negb isChildCurrPart
		then (* idPD is not itself or a child partition, stop*) ret false 
		else

(*
    if self.helpers.get_PD_nb_prepare(idPD) + 1 > self.constants.nb_prepare_max:
        # idPD has reached the maximum nb of allowed prepare, stop
        return 0  # TODO: return NULL*)
		(* Check the max number of prepare hasn't been reached yet*)
		perform nbPrepare := readPDNbPrepare idPD in
		perform maxnbprepare := getMaxNbPrepare in
		perform isMaxPrepare := Index.leb maxnbprepare nbPrepare in
		if isMaxPrepare
		then (* reached maximum nb of allowed prepare, stop*) ret false 
		else
(*
		current_free_slots_nb = self.helpers.get_PD_nb_free_slots(idPD)
    # Vérifier que nbSlotsPlanifié == 8  || (nbSlotsPlanifié == 8 & nbSlotsPlanifié > idPD[compteur libre]) SINON RET NOK // soit demande d’un bloc entier de 8 soit besoin de moins et on effectue le prepare si pas assez de libes
    # Check that there is a need for a prepare (nb of free slots not enough to hold the projected slots)
    # Check that no more than the max entries of a new kernel structure is planned
    if projectedSlotsNb <= current_free_slots_nb and projectedSlotsNb != self.constants.kernel_structure_entries_nb:
        # no need for a prepare, stop
        return 0  # TODO: return NULL*)
		(* Check that there is a need for a prepare (nb of free slots not enough to hold the projected slots) *)
		(* Check that no more than the max entries of a new kernel structure is planned*)
		perform currentFreeSlotsNb := readPDNbFreeSlots idPD in
		perform isEnoughFreeSlots := Index.leb projectedSlotsNb currentFreeSlotsNb in
		perform kernelentriesnb := getKernelStructureEntriesNb in
		perform isForcedPrepare :=  getBeqIdx currentFreeSlotsNb kernelentriesnb in
		if isEnoughFreeSlots && negb isForcedPrepare
		then (* no need for a prepare, stop*) ret false 
		else

(*
    # Check that the nb of projected slots aren't superior to the max entries that a prepare can offer (max kernel entries)
    if projectedSlotsNb > self.constants.kernel_structure_entries_nb:
        # bad arguments, stop
        return 0  # TODO: return NULL*)
		(* Check that the nb of projected slots aren't superior to the max entries that a prepare can offer (max kernel entries)*)
		perform isOutsideBound := Index.ltb kernelentriesnb projectedSlotsNb in
		if isOutsideBound
		then (* bad arguments, stop*) ret false
		else 

		(** The requisioned block becomes a kernel structure*)
(*
    # entrée MPU <- ChercherBlocDansMPU(PD courant, idBlocRéquisitionné) (trouver le bloc en parcourant MPU courant (pour le mettre inaccessible) en O(m))
    requisitioned_block_in_current_partition_address = self.__find_block_in_MPU(self.current_partition,
                                                                                idRequisitionedBlock)
    if requisitioned_block_in_current_partition_address == -1:
        # no block found, stop
        return 0  # TODO: return NULL
    requisitioned_block_entry = self.helpers.get_MPU_entry(requisitioned_block_in_current_partition_address)*)
		(* Find the requisitioned block in the current partition *)
    perform requisitionedBlockInCurrPartAddr := findBlockInMPU currentPart
																										idRequisitionedBlock in
		perform addrIsNull := compareAddrToNull	requisitionedBlockInCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret false else

(*
    # Vérifier taille bloc réquisitionné > MinBlcoPrepare
    if (requisitioned_block_entry[2] - requisitioned_block_entry[1]) < self.constants.kernel_structure_total_length:
        # block is smaller than the MPU region constraint
        return 0  # TODO: return NULL*)
		(* Check the block is big enough to hold a kernel structure*)
		perform blockSize := sizeOfBlock requisitionedBlockInCurrPartAddr in
		perform kStructureTotalLength := getKernelStructureTotalLength in
		perform isBlockTooSmall := Paddr.leb blockSize kStructureTotalLength in
		if isBlockTooSmall then (* block is smaller than the minimum  *) ret false 
		else

(*
    # Check block is accessible and present
    if requisitioned_block_entry[3] is False or requisitioned_block_entry[4] is False:
        # requisitioned block is not accessible or not present
        return 0  # TODO: return NULL*)
		(* Check block is accessible and present*)
		perform addrIsAccessible := readMPUAccessibleFromMPUEntryAddr
																	requisitionedBlockInCurrPartAddr in
		if negb addrIsAccessible then (* block is inaccessible *) ret false else
		perform addrIsPresent := readMPUPresentFromMPUEntryAddr
																	requisitionedBlockInCurrPartAddr in
		if negb addrIsPresent then (** block is not present *) ret false else

(*
    # // Init MPU + Sh1 + SC : construire la liste des emplacements libres + default
    # Ecrire NULL à @idBlocRéquisitionné[0]->start (traiter la 1ère ligne : couper la liste chaînée libre)
    # Ecrire @idBlocRéquisitionné[1] à @idBlocRequisitionné[0]->end (traiter la 1ère ligne : la ligne suivante est le prochain emplacement libre)
    # Ecrire default à Sh1[@idBlocRéquisitionné][i] (traiter la 1ère ligne : mettre default dans le Shadow 1 du bloc)
    # Ecrire default à SC[@idBlocRéquisitionné][i] (traiter la 1ère ligne : mettre default dans le Shadow Cut du bloc)
    # Pour i de 1 à MaxEntrees -2 : (parcourir le bloc entier de la ligne 2 à l’avant-dernière ligne)
    # Ecrire @idBlocRéquisitionné[i-1] à @idBlocRéquisitionné[i]->start (le bloc précédent est l’emplacement libre précédent de lia liste chaînée des libres)
    # Ecrire @idBlocRéquisitionné[i+1] à @idBlocRéquisitionné[i]->end (le bloc suivant est l’emplacement libre suivant)
    # Ecrire default à Sh1[idBlocRéquisitionné][i] (mettre la ligne correspondante Shadow 1 à default)
    # Ecrire default à SC[idBlocRéquisitionné][i] (mettre la ligne correspondante à Shadow Cut à default)
    # i <- i+1
    # Ecrire @idBlocRéquisitionné[MaxEntrees-1] à @idBlocRéquisitionné[MaxEntrees]->start (Traiter la dernière ligne 1)
    # intializes the MPU structure requisitioned block
    self.init_MPU(requisitioned_block_entry[1], 0, self.constants.kernel_structure_entries_nb)
    self.init_Sh1(requisitioned_block_entry[1], 0, self.constants.kernel_structure_entries_nb)
    self.init_SC(requisitioned_block_entry[1], 0, self.constants.kernel_structure_entries_nb)
*)
		(*TODO inits : set to zero*)
		perform requisitionedBlockStart := readMPUStartFromMPUEntryAddr 
																						requisitionedBlockInCurrPartAddr in
		initMPUStructure requisitionedBlockStart ;;
		initSh1Structure requisitionedBlockStart ;;
		initSCStructure requisitionedBlockStart ;;

		perform newKStructurePointer := getAddr requisitionedBlockStart in
(*
    # // Mettre le bloc inaccessible là d’où il provient (parent ou enfant même traitement)
    # Ecrire FALSE à (entrée MPU->accessible)
    self.helpers.set_MPU_accessible_from_MPU_entry_address(requisitioned_block_in_current_partition_address, False)
    # SI SC[entrée MPU]->suivant == NULL ET SC[entrée MPU]->origin == @idBlocRéquisitionné ALORS (si bloc pas coupé alors propager aux ancêtres)
    if ((self.helpers.get_SC_next_from_MPU_entry_address(requisitioned_block_in_current_partition_address) == 0) \
            and (
                    self.helpers.get_SC_origin_from_MPU_entry_address(requisitioned_block_in_current_partition_address)
                    == idRequisitionedBlock
            )):
            # Ecrire FALSE dans MPU[parent]->accessible
            # Ecrire FALSE dans MPU[ancêtres]->accessible (O(p) car recherche dans p ancêtres, sinon besoin de stocker l’adresse du bloc dans l’ancêtre direct pour O(p))
            # mark the block as inaccessible to all ancestors
            self.__write_accessible_to_ancestors_rec(self.current_partition, idRequisitionedBlock, False)*)
		(** Set the requisitioned block inaccessible*)
		writeMPUAccessibleFromMPUEntryAddr requisitionedBlockInCurrPartAddr false;;
		(** Parent and ancestors: set the block unaccessible if the block is not cut*)
		writeAccessibleToAncestorsIfNoCut currentPart idRequisitionedBlock 
																				requisitionedBlockInCurrPartAddr false ;;

		(** Change idPD *)
(*
		# // Insérer le bloc réquisitionné au début de la liste des structures
    # Ecrire idPD[pointeur MPU] à MPUblocRéquisitionné[MaxEntrees]->next (faire pointer la fin du bloc au prochain nœud de structure MPU)
    self.helpers.set_kernel_structure_next_from_kernel_structure_start(
        requisitioned_block_entry[1],
        self.helpers.get_PD_pointer_to_MPU_linked_list(idPD)
    )
    # Ecrire @MPUblocRéquisitionné à idPD[pointeur MPU] (mettre à jour le pointeur MPU de la partition vers le MPU du bloc réquisitionné)
    self.helpers.set_PD_pointer_to_MPU_linked_list(idPD, requisitioned_block_entry[1])
*)
		(** Insert the requisitioned block in the kernel structure list *)
		perform oldKStructurePointer := readPDStructurePointer idPD in
		writeNextFromKernelStructureStart newKStructurePointer 
																			oldKStructurePointer;;
		writePDStructurePointer idPD newKStructurePointer;;
(*
		# // Ajuster le pointeur libre
    # Ecrire PD[pointeur libre] à MPUblocRéquisitionné[i]->end (Traiter la dernière ligne 2 : relier les emplacements libres du bloc à la liste chaînée des emplacements libres, vide normalement ou alors prepare sans avoir besoin, sens ->)
    self.helpers.set_MPU_end_from_MPU_entry_address(
        requisitioned_block_entry[1] + (self.constants.kernel_structure_entries_nb - 1)*self.constants.MPU_entry_length,
        self.helpers.get_PD_first_free_slot_address(idPD)
    )
   # Ecrire MPUblocRéquisitionné à PD[pointeur libre] (faire pointer le pointeur libre vers la première ligne du bloc)
    self.helpers.set_PD_first_free_slot_address(idPD, requisitioned_block_entry[1])
    # Ecrire (PD[compteur]+MaxEntrees) à PD[compteur] (+MaxEntrees au compteur)
    self.helpers.set_PD_nb_free_slots(idPD, self.helpers.get_PD_nb_free_slots(idPD) + self.constants.kernel_structure_entries_nb)
    # Ecrire (nbPrepare+1) à PD[nbPrepare] (+1 au nombre de Prepare)
    self.helpers.set_PD_nb_prepare(idPD, self.helpers.get_PD_nb_prepare(idPD) + 1)
*)
		(** Adjust the free slot pointer to the next free slot*)
		perform lastidx := Index.pred kernelentriesnb in
		perform lastMPUEntryAddr := getMPUEntryAddrFromKernelStructureStart 
																		newKStructurePointer
																		lastidx in
		perform currFirstFreeSlot := readPDFirstFreeSlotAddr idPD in
		writeMPUEndFromMPUEntryAddr lastMPUEntryAddr currFirstFreeSlot ;;
		(* set the first free slot addr to the first entry of the new kernel structure*)
		writePDFirstFreeSlotAddr idPD newKStructurePointer ;;
		(* new count = (count + number of new entries)*)
		perform currentNbFreeSlots := readPDNbFreeSlots idPD in
		writePDNbFreeSlots idPD (CIndex (currentNbFreeSlots + kernelentriesnb)) ;;
		(* new nbprepare = nbprepare + 1*)
		perform currentNbPrepare := readPDNbPrepare idPD in
		perform succCurrentNbPrepare := Index.succ currentNbPrepare in
		writePDNbPrepare idPD succCurrentNbPrepare ;;

(*    #// Traitement spécial si prepare pour un enfant -> mettre le bloc partagé dans le parent
    # SI idPD != PDcourant ALORS (prepare pour autre que soit)
    if idPD != self.current_partition:
        # prepare is done for another partition than itself
        # Ecrire idPD à Sh1courant[entrée MPU]
        self.helpers.set_Sh1_PDchild_from_MPU_entry_address(requisitioned_block_in_current_partition_address, idPD)*)
		(** Special treatment for a prepare on a child: set the block as shared in 
				the parent*)
		if isChildCurrPart 
		then (*prepare is done for another partition than itself*)
			writeSh1PDChildFromMPUEntryAddr requisitionedBlockInCurrPartAddr idPD ;; 
			(* # RET OK
    		return 1*)
			ret true
		else ret true.

(** ** The addMemoryBlock PIP MPU service

    The [addMemoryBlock] system call adds a block to a child partition (slower
		version).
		The block is still accessible from the current partition (shared memory).
    This variant finds the block to share by going through all entries of each 
		structure in search for the block.

		Returns the child's MPU entry address used to store the shared block:OK/NULL:NOK

    <<idPDchild>>				the child partition to share with
		<<idBlockToShare>>	the block to share
*)
Definition addMemoryBlock (idPDchild idBlockToShare: paddr) : LLI paddr :=
		(** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in

(*def addMemoryBlock(self, idPDchild, idBlockToShare):
    """Adds a block to a child partition (slow)
    The block is still accessible from the current partition (shared memory)
    This variant finds the block to share by going through all entries of each structure in search for the block
    :param idPDchild: the child partition to share with
    :param idBlockToShare: the block to share
    :return:the child's MPU entry address where the block has been added
    """*)
(*
    # entrée MPU courant <- ChercherBlocDansMPU(PD courant, idBlocADonner) (trouver le bloc en parcourant MPU en O(m))
    # find and check idBlockToShare
    block_to_share_in_current_partition_address = self.__find_block_in_MPU(self.current_partition, idBlockToShare)
    if block_to_share_in_current_partition_address == -1:
        # no block found, stop
        return 0  # TODO: return NULL*)
		(* Find the block to share in the current partition *)
    perform blockInCurrPartAddr := findBlockInMPU 	currentPart
																									idBlockToShare in
		perform addrIsNull := compareAddrToNull	blockInCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret nullAddr else
(*
    return self.__add_memory_block(idPDchild, block_to_share_in_current_partition_address)*)
		(** Call the internal addMemoryBlock function shared with the faster interface*)
		addMemoryBlockCommon idPDchild blockInCurrPartAddr.

(** ** The addMemoryBlockFast PIP MPU service

    The [addMemoryBlockFast] system call adds a block to a child partition (faster
		version).
		The block is still accessible from the current partition (shared memory).
    This variant finds the block to share by directly checking the provided index,
		thus faster than going through all entries of each structure

		Returns the child's MPU entry address used to store the shared block:OK/NULL:NOK

    <<idPDchild>>							the child partition to share with
		<<idBlockToShare>>				the block to share
		<MPUAddressBlockToShare>>	the MPU address where the block <idBlocktoShare> lies
*)
Definition addMemoryBlockFast (idPDchild idBlockToShare MPUAddressBlockToShare: paddr)
																																	: LLI paddr :=
		(** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in

(*
def addMemoryBlockFast(self, idPDchild, idBlockToShare, MPUAddressBlockToShare):
    """Adds a block to a child partition (fast)
    The block is still accessible from the current partition (shared memory)
    This variant finds the block to share by directly checking the provided index, thus faster than going through
    all entries of each structure
    :param idPDchild: the child partition to share with
    :param idBlockToShare: the block to share
    :param MPUAddressBlockToShare: the MPU address where the block <idBlocktoShare> lies
    :return:the child's MPU entry address where the block has been added
    """
    # entrée MPU courant <- ChercherBlocDansMPU(PD courant, idBlocADonner) (trouver le bloc en parcourant MPU en O(m))
    # find and check idBlockToShare and MPUAddressBlockToShare
    block_to_share_in_current_partition_address = self.__find_block_in_MPU_with_address(self.current_partition,
                                                                                          idBlockToShare,
																																													MPUAddressBlockToShare)
		if block_to_share_in_current_partition_address == -1:
		    # no block found, stop
		    return 0  # TODO: return NULL
*)
		(* Find the block to share in the current partition (with MPU address) *)
    perform blockInCurrPartAddr := findBlockInMPUWithAddr 	currentPart
																													idBlockToShare
																													MPUAddressBlockToShare in
		perform addrIsNull := compareAddrToNull	blockInCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret nullAddr else
(*
		return self.__add_memory_block(idPDchild, block_to_share_in_current_partition_address)*)
		(** Call the internal addMemoryBlock function shared with the faster interface*)
		addMemoryBlockCommon idPDchild blockInCurrPartAddr.

(** ** The removeMemoryBlock PIP MPU service

    The [removeMemoryBlock] system call removes a block from a child partition
		(slower version).
		This variant finds the block to remove by going through all entries of each
		structure in search for the block
    The block could be cut in the child partition but with all subblocks still
		accessible
    This operation succeeds for any shared memory block previously added, but
		fails if the purpose of the block is not shared memory anymore, in particular
		in such cases:
          - The block can't be removed if the child or its descendants used it
						(or part of it) as a kernel structure
          - The block can't be removed if the child's descendants cut the block

		Returns true:OK/false:NOK

    <<idPDchild>>				the child partition to remove from
		<<idBlockToRemove>>	the block to remove
*)
Definition removeMemoryBlock (idPDchild idBlockToRemove: paddr) : LLI bool :=
		(** Get the current partition (Partition Descriptor) *)
    perform currentPart := getCurPartition in
(*
    def removeMemoryBlock(self, idPDchild, idBlockToRemove):
        """
        Removes a block from a child partition
        This variant finds the block to remove by going through all entries of each structure in search for the block
        The block could be cut in the child partition but all subblocks still accessible
        This operation succeeds for any shared memory block previously added, but fails if the purpose of the block is
        not shared memory anymore, in particular in such cases:
            - The block can't be removed if the child or its descendants used it (or part of it) as a kernel structure
            - The block can't be removed if the child's descendants cut the block
        :param idPDchild: the child partition to remove from
        :param idBlockToRemove: the block to remove
        :return: OK(1)/NOK(0)
        """
*)
(*
        # entrée MPU courant <- ChercherBlocDansMPU(PD courant, idBlocARetirer) (trouver le bloc en parcourant MPU COURANT en O(m))
        block_to_remove_in_current_partition_address = self.__find_block_in_MPU(self.current_partition, idBlockToRemove)
        if block_to_remove_in_current_partition_address == -1:
            # no block found, stop
            return 0  # TODO: return NULL*)
		(* Find the block to remove in the current partition *)
    perform blockToRemoveInCurrPartAddr := findBlockInMPU 	currentPart
																									idBlockToRemove in
		perform addrIsNull := compareAddrToNull	blockToRemoveInCurrPartAddr in
		if addrIsNull then(* no block found, stop *) ret false else
(*
    return self.__remove_memory_block(idPDchild, block_to_remove_in_current_partition_address)*)
		removeMemoryBlockCommon idPDchild idBlockToRemove blockToRemoveInCurrPartAddr.