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
    This file contains some internal functions used by services *)
Require Import Model.Hardware Model.ADT Model.MAL Bool Arith List Coq.Init.Peano.
Definition N := 100.

Import MAL.
Open Scope mpu_state_scope.
  
(** The [getPd] function returns the page directory of a given partition *)
Definition getPd partition :=
  readPDTable partition.

(** The [compareAddrToNull] returns true if the given addr is equal to the fixed
    default addr (null) *) 
Definition compareAddrToNull (p : paddr) : LLI bool :=
  perform nullAddr := getNullAddr in
  getBeqAddr nullAddr p.

(*
    def __find_block_in_MPU_rec(self, next_kernel_structure, id_block_to_find):
        """Recursive search by going through the structure list and search for the <id_block_to_find>
        Stop conditions:
            1: reached end of structure list (maximum number of iterations)
            2: found <id_block_to_find>
        Recursive calls: until the end of the list
        """
        # Stop condition 1: reached end of structure list
        if next_kernel_structure == 0:  # TODO: NULL
            # end of structure list, stop
            return -1

        # Stop condition 2: found block
        for i in range(self.constants.kernel_structure_entries_nb):
            entry_i_address = i*self.constants.MPU_entry_length + next_kernel_structure
            if self.helpers.get_MPU_present_from_MPU_entry_address(entry_i_address) == 0:
                # empty slot, don't consider the value
                continue
            entry_i_start = self.helpers.get_MPU_start_from_MPU_entry_address(entry_i_address)
            if entry_i_start == id_block_to_find:
                # the block has been found
                block_in_MPU = entry_i_address
                return block_in_MPU

        # RECURSIVE call: check next kernel structure
        next_kernel_structure = self.helpers.get_kernel_structure_next_from_kernel_structure_start(next_kernel_structure)
        return self.__find_block_in_MPU_rec(next_kernel_structure, id_block_to_find)

    def __find_block_in_MPU(self, PD_to_find_in, id_block_to_find):
        """Go through the kernel structure linked list searching in the MPU structure for the <id_block_to_find>
        :return: block address / NOK (-1)"""
        # Check that PD is OK done before

        # go through the MPU structure finding the block (== start address of MPU entry)
        next_kernel_structure = self.helpers.get_PD_pointer_to_MPU_linked_list(PD_to_find_in)
        return self.__find_block_in_MPU_rec(next_kernel_structure, id_block_to_find)
*)
(*
Fixpoint findBlockInMPURec (currentidx : PipMPU.index) (currentkernelstructure idblock: paddr) : PipMPU.LLI paddr := 
	match currentidx with
		| Build_index n => if beq n O then 
		| 0 => PipMPU.getNullAddr
		| S timeout1 => 
										perform maxindex :=  Constants.getKernelStructureEntriesNb in (** Our last index is table size - 1, as we're indexed on zero*)
										perform islastidx := PipMPU.eqbIdx currentidx maxindex in
										if (islastidx)
										then
											perform nextkernelstructure := readPDNextFromKernelStructureStart currentkernelstructure in
											perform nullAddr :=  PipMPU.getNullAddr in
											perform isnull :=  PipMPU.eqbAddr nextkernelstructure nullAddr in
											if isnull 
											then PipMPU.getNullAddr
											else
												findBlockInMPURec timeout1 nextkernelstructure idblock (** Recursive call on the next table *)
									else
											perform entryaddr := currentkernelstructure + currentidx*Constants.MPUEntryLength in
											perform ispresent := readMPUPresentFromMPUEntryAddr entryaddr in
											perform mpustart := readMPUStartFromMPUEntryAddr entryaddr in
											if ispresent && PipMPU.beqAddr mpustart idblock then
												ret entryaddr
											else 
												findBlockInMPURec timeout1 currentkernelstructure idblock (** Recursive call on the next table **)
	end.*)


Fixpoint findBlockInMPUAux (timeout : nat) (currentidx : index) (currentkernelstructure idblock: paddr) : LLI paddr := 
	match timeout with
		| O => getNullAddr
		| S timeout1 => 
										perform maxindex := getKernelStructureEntriesNb in (** Our last index is table size - 1, as we're indexed on zero*)
										perform islastidx := getBeqIdx currentidx (CIndex maxindex) in
										if (islastidx)
										then
											perform nextkernelstructure := readNextFromKernelStructureStart currentkernelstructure in
											perform nullAddr :=  getNullAddr in
											perform isnull :=  getBeqAddr nextkernelstructure nullAddr in
											if isnull
											then getNullAddr
											else
												findBlockInMPUAux timeout1 (CIndex 0) nextkernelstructure idblock (** Recursive call on the next table *)
									else
											perform entryaddr := getMPUEntryAddrAtIndexFromKernelStructureStart currentkernelstructure currentidx in
											perform ispresent := readMPUPresentFromMPUEntryAddr entryaddr in
											perform mpustart := readMPUStartFromMPUEntryAddr entryaddr in
											if ispresent && beqAddr mpustart idblock then
												ret entryaddr
											else 
												perform nextidx := Index.succ currentidx in
												findBlockInMPUAux timeout1 currentidx currentkernelstructure idblock (** Recursive call on the next table**)
	end.



(* TODO: return Some MPUentry or None *)
(** The [findBlockInMPU] function fixes the timeout value of [findBlockInMPURec] *)
Definition findBlockInMPU (currentPartition : paddr) (idBlock: paddr) : LLI paddr := 
	perform kernelstructurestart := readPDStructurePointer currentPartition in
	perform zero := Index.zero in
	findBlockInMPUAux N zero kernelstructurestart idBlock.

Print findBlockInMPU.


(* 
    def __write_accessible_to_ancestors_rec(self, PD_base_partition, id_base_block, accessible_bit):
        """Write the accessible bit of value <accessible_bit> to the block identified as
            <id_base_block> to all ancestors of <PD_base_partition>"""
        if PD_base_partition == self.root_partition:
            # root partition, no ancestor, stop
            return 1
        else:
            # get parent partition
            PD_parent_partition = self.helpers.get_PD_parent(PD_base_partition)
            # find block in MPU structure
            block_in_parent_MPU_address = self.__find_block_in_MPU(PD_parent_partition, id_base_block)
            if block_in_parent_MPU_address == -1:
                # block not found, shouldn't happen TODO: write accessible could fail
                return 0

            self.helpers.set_MPU_accessible_from_MPU_entry_address(block_in_parent_MPU_address, accessible_bit)

            # recursive call until we reached the root partition
            return self.__write_accessible_to_ancestors_rec(PD_parent_partition, id_base_block, accessible_bit)
*)

Fixpoint writeAccessibleRec timeout (pdbasepartition idblock : paddr) (accessiblebit : bool) : LLI bool :=
	match timeout with
		| 0 => ret false
		| S timeout1 => 	if beqAddr pdbasepartition Constants.rootPart then
												ret true
											else
												perform pdparent := readPDParent pdbasepartition in
												perform blockInParentPartitionAddr := findBlockInMPU pdparent idblock in
												perform addrIsNull := compareAddrToNull	blockInParentPartitionAddr in
												if addrIsNull then ret false (*Shouldn't happen *) else
												writeMPUAccessibleFromMPUEntryAddr blockInParentPartitionAddr accessiblebit ;;
												writeAccessibleRec timeout1 pdparent idblock accessiblebit
	end.



Definition writeAccessibleRecAux (pdbasepartition idblock : paddr) (accessiblebit : bool) : LLI bool :=
	writeAccessibleRec N pdbasepartition idblock accessiblebit.
Print writeAccessibleRec.

Definition writeAccessibleToAncestorsIfNoCut 	(pdbasepartition idblock mpublockaddr : paddr)
																							(origin next : paddr)
																							(accessiblebit : bool) : LLI bool :=
		perform blockOrigin := readSCOriginFromMPUEntryAddr mpublockaddr in
		perform blockStart := readMPUStartFromMPUEntryAddr mpublockaddr in
		perform blockNext := readSCNextFromMPUEntryAddr mpublockaddr in
		if beqAddr blockStart blockOrigin  && beqAddr blockNext nullAddr then
			(* Block hasn't been cut previously, adjust accessible bit *)
			writeAccessibleRecAux pdbasepartition idblock accessiblebit ;;
			ret true
		else ret true.

(*     def __insert_new_entry(self, PD_insertion, entry_to_insert, block_origin):
        """Insert the entry <entry_to_insert> in the partition <PD_insertion> with block origin <block_origin>
        Used in cutMemoryBlock and addMemoryBlock"""
        # insérerEntrée(idPDinsertion, entrée à insérer, origine bloc) : insère l’entrée au 1er emplacement libre dans la MPU de idPDinsertion et précise l’origine du bloc, retourne l’emplacement MPU où l’entrée a été insérée (O(1))
        # Checks have been done before: PD is correct, MPU_entry is correct, block_origin is correct, there is one or
        # more free slots

        # entrée MPU libre <- idPDinsertion[pointeur libre] (récupérer la 1ère entrée libre)
        new_entry_address = self.helpers.get_PD_first_free_slot_address(PD_insertion)

        # // Ajuster le pointeur libre
        # Adjust the free slot pointer and count
        # Ecrire idPDinsertion[pointeur libre]->end à idPDinsertion[pointeur libre] (changer le pointeur libre vers la prochaine entrée MPU libre)
        new_first_free_slot_address = self.helpers.get_MPU_end_from_MPU_entry_address(new_entry_address)
        self.helpers.set_PD_first_free_slot_address(PD_insertion, new_first_free_slot_address)

        # Ecrire (idPDinsertion[compteur]–1) à idPDinsertion[compteur] (enlever 1 au compteur d’entrées libres)
        self.helpers.set_PD_nb_free_slots(PD_insertion, self.helpers.get_PD_nb_free_slots(PD_insertion) - 1)

        # // Insérer l’entrée au 1er emplacement libre
        # Ecrire (entrée à insérer) à @(entrée MPU libre) (insérer l’entrée à l’emplacement libre)
        self.helpers.write_MPU_entry(new_entry_address, entry_to_insert[1], entry_to_insert[2], entry_to_insert[3], entry_to_insert[4])

        # Ecrire (origine bloc) à SC[entrée MPU libre]->origin (indiquer que le bloc est l’origine des coupes futures, soit le start du bloc qui a été donné)
        self.helpers.set_SC_origin_from_MPU_entry_address(new_entry_address, block_origin)

        # RET @(entrée MPU libre)
        return new_entry_address
*)
(** The [insertNewEntry] function inserts the entry (<startaddr>, <endaddr>, true, true)
 	in the partition <pdinsertion> with block origin <origin>.
	Used in cutMemoryBlock and addMemoryBlock
	Returns the inserted entry's MPU address
	 *)
Definition insertNewEntry (pdinsertion startaddr endaddr origin: paddr) : LLI paddr :=
(** Checks have been done before: PD is correct, MPU_entry is correct, block_origin is correct, there is one or more free slots *)
	perform newEntryMPUAddr := readPDFirstFreeSlotAddr pdinsertion in
	(** Adjust the free slot pointer to the next free slot*)
	perform newFirstFreeSlotAddr := readMPUEndFromMPUEntryAddr newEntryMPUAddr in
	writePDFirstFreeSlotAddr pdinsertion newFirstFreeSlotAddr ;;
	(** Adjust the free slots count to count - 1*)
	perform currentNbFreeSlots := readPDNbFreeSlots pdinsertion in
	writePDNbFreeSlots pdinsertion (currentNbFreeSlots - 1) ;;

	(** Insert the new MPU entry in the free slot*)
	writeMPUStartFromMPUEntryAddr newEntryMPUAddr startaddr ;;
	writeMPUEndFromMPUEntryAddr newEntryMPUAddr endaddr ;;
	writeMPUAccessibleFromMPUEntryAddr newEntryMPUAddr true ;;(** TODO accessible by default else no cut no add*)
	writeMPUPresentFromMPUEntryAddr newEntryMPUAddr true ;;(** TODO present by default*)
	(* TODO : set the block's RWX rights here ?*)
	writeSCOriginFromMPUEntryAddr newEntryMPUAddr origin ;;

	ret newEntryMPUAddr.

Module Helpers.


Definition readPDChildFromMPUEntry (paddr : paddr) : LLI ADT.paddr :=
(* if MPU_entry_address == 0:
				  print("Error in get_Sh1_PDchild_from_MPU_entry_address")
					exit(108)
   return self.memory.memory_getint(
        self.get_address_Sh1_PDchild_from_MPU_entry_address(MPU_entry_address)
        )*)
	perform addrIsNull := compareAddrToNull paddr in
	if addrIsNull then undefined 50 else
	readSh1PDChildFromMPUEntryAddr paddr.

Definition sizeOfBlock (memblock : block) : LLI paddr :=
	ret (CPaddr (memblock.(endAddr) - memblock.(startAddr))). 

Definition initPDTable (pdtablepaddr : paddr) : LLI unit :=
	perform emptytable := getEmptyPDTable in
	writePDTable pdtablepaddr emptytable.

Fixpoint eraseBlockRec (startAddr currentAddr : nat): LLI unit :=
match currentAddr with
| O => ret tt (*Address 0 is the low-limit*)
| S n => 	eraseAddr (CPaddr currentAddr) ;; (*erase the current address*)
					if Nat.eqb currentAddr startAddr then
						(*Reached start address, no more addresses to erase*)
						ret tt
					else
						(*Continue to erase lower addresses*)
						eraseBlockRec startAddr n 
end.


(* Transform paddr into nat *)
Definition eraseBlock (b : block) : LLI unit :=
	match b.(startAddr) with
	| Build_paddr s => match b.(endAddr) with
										| Build_paddr e => eraseBlockRec s e
										end
	end.

End Helpers.