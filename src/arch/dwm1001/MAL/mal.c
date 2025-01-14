/*******************************************************************************/
/*  © Université de Lille, The Pip Development Team (2015-2024)                */
/*  Copyright (C) 2020-2024 Orange                                             */
/*                                                                             */
/*  This software is a computer program whose purpose is to run a minimal,     */
/*  hypervisor relying on proven properties such as memory isolation.          */
/*                                                                             */
/*  This software is governed by the CeCILL license under French law and       */
/*  abiding by the rules of distribution of free software.  You can  use,      */
/*  modify and/ or redistribute the software under the terms of the CeCILL     */
/*  license as circulated by CEA, CNRS and INRIA at the following URL          */
/*  "http://www.cecill.info".                                                  */
/*                                                                             */
/*  As a counterpart to the access to the source code and  rights to copy,     */
/*  modify and redistribute granted by the license, users are provided only    */
/*  with a limited warranty  and the software's author,  the holder of the     */
/*  economic rights,  and the successive licensors  have only  limited         */
/*  liability.                                                                 */
/*                                                                             */
/*  In this respect, the user's attention is drawn to the risks associated     */
/*  with loading,  using,  modifying and/or developing or reproducing the      */
/*  software by the user in light of its specific status of free software,     */
/*  that may mean  that it is complicated to manipulate,  and  that  also      */
/*  therefore means  that it is reserved for developers  and  experienced      */
/*  professionals having in-depth computer knowledge. Users are therefore      */
/*  encouraged to load and test the software's suitability as regards their    */
/*  requirements in conditions enabling the security of their systems and/or   */
/*  data to be ensured and,  more generally, to use and operate it in the      */
/*  same conditions as regards security.                                       */
/*                                                                             */
/*  The fact that you are presently reading this means that you have had       */
/*  knowledge of the CeCILL license and that you accept its terms.             */
/*******************************************************************************/

/**
 * \file mal.c
 * \brief ARM memory abstraction layer
 */

#include <stddef.h>
#include <stdint.h>

#include "mal.h"
#include "memlayout.h"
#include "mpu.h"
#include "stdio.h"

paddr current_partition = NULL; /* Current partition, default root */
paddr constantRootPartM = NULL; /* Multiplexer's partition descriptor, default 0*/

static const PDTable_t DEFAULT_PD_TABLE = {NULL, NULL, 0, 0, NULL}; // BEWARE : LUT not initialized


/*!
 * \fn paddr getKernelStructureStartAddr(paddr blockentryaddr, uint32_t blockentryindex)
 * \brief Gets the kernel structure start address from the block entry.
 * \param blockentryaddr The address of the block entry
 * \param blockentryindex The index of the block entry
 * \return The start of the kernel structure frame
 */
paddr getKernelStructureStartAddr(paddr blockentryaddr, uint32_t blockentryindex)
{
	return (paddr) ((BlockEntry_t*) blockentryaddr- blockentryindex); // TODO: Over/underflow ?
}

/*!
 * \fn paddr getBlockEntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
 * \brief Gets the address where to find the block entry corresponding to the given index.
 * \param kernelstartaddr The address where the kernel structure starts
 * \param blockentryindex The index of the block entry
 * \return The address of the block entry
 */
paddr getBlockEntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
{
	KStructure_t* structure = (KStructure_t*) kernelstartaddr;
	return (paddr) &structure->blocks[blockentryindex];
}

/*!
 * \fn paddr getSh1EntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
 * \brief Gets the address where to find the Shadow 1 entry corresponding to the given index.
 * \param kernelstartaddr The address where the kernel structure starts
 * \param blockentryindex The index of the block entry
 * \return The address of the shadow 1 entry
 */
paddr getSh1EntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
{
	KStructure_t* structure = (KStructure_t*) kernelstartaddr;
	return (paddr) &structure->sh1[blockentryindex];
}

/*!
 * \fn paddr getSCEntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
 * \brief Gets the address where to find the Shadow Cut entry corresponding to the given index.
 * \param kernelstartaddr The address where the kernel structure starts
 * \param blockentryindex The index of the block entry
 * \return The address of the shadow cut entry
 */
paddr getSCEntryAddrFromKernelStructureStart(paddr kernelstartaddr, uint32_t blockentryindex)
{
	KStructure_t* structure = (KStructure_t*) kernelstartaddr;
	return (paddr) &structure->sc[blockentryindex];
}

/*!
 * \fn paddr readPDStructurePointer(paddr pdaddr)
 * \brief Gets the first kernel structure.
 * \param pdaddr The address of the PD
 * \return the pointer to the first kernel structure
 */
paddr readPDStructurePointer(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr; // TODO: Exception ? Only called with current partition

	//MALDBG("readPDStructurePointer(%d) -> %d\r\n", pdaddr, pd);
	//printf("readPDStructurePointer(%x) -> %d\r\n", pdaddr, pd);

	// Return the pointer to the first kernel structure
	return pd->structure;
}

/*!
 * \fn void writePDStructurePointer(paddr pdaddr, paddr value)
 * \brief Sets the first kernel structure.
 * \param pdaddr The address of the PD
 * \param value The new value
 * \return void
 */
void writePDStructurePointer(paddr pdaddr, paddr value)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// write the structure pointer
	pd->structure = value;
	return;
}

/*!
 * \fn paddr readPDFirstFreeSlotPointer(paddr pdaddr)
 * \brief Gets the first free slot's address
 * \param pdaddr The address of the PD
 * \return the pointer to the first free slot
 */
paddr readPDFirstFreeSlotPointer(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr; // TODO: Exception ? Only called with current partition

	// Return the pointer to the first free slot
	return pd->firstfreeslot;
}

/*!
 * \fn void writePDFirstFreeSlotPointer(paddr pdaddr, paddr value)
 * \brief Sets the first free slot's address.
 * \param pdaddr The address of the PD
 * \param value The new value
 * \return void
 */
void writePDFirstFreeSlotPointer(paddr pdaddr, paddr value)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// write the first free slot pointer
	pd->firstfreeslot = value;
	return;
}

/*!
 * \fn uint32_t readPDNbFreeSlots(paddr pdaddr)
 * \brief Gets the number of free slots left.
 * \param pdaddr The address of the PD
 * \return the number of free slots left
 */
uint32_t readPDNbFreeSlots(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// Return the number of free slots left
	return pd->nbfreeslots;
}

/*!
 * \fn void writePDNbFreeSlots(paddr pdaddr, uint32_t value)
 * \brief Sets the number of free slots left.
 * \param pdaddr The address of the PD
 * \param value The new value
 * \return void
 */
void writePDNbFreeSlots(paddr pdaddr, uint32_t value)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// write the number of free slots left
	pd->nbfreeslots = value;
	return;
}

/*!
 * \fn uint32_t readPDNbPrepare(paddr pdaddr)
 * \brief Gets the number of prepare done util then.
 * \param pdaddr The address of the PD
 * \return the number of prepare
 */
uint32_t readPDNbPrepare(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// Return the number of prepare
	return pd->nbprepare;
}

/*!
 * \fn void writePDNbPrepare(paddr pdaddr, uint32_t value)
 * \brief Sets the number of prepare done util then.
 * \param pdaddr The address of the PD
 * \param value The new value
 * \return void
 */
void writePDNbPrepare(paddr pdaddr, uint32_t value)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// write the number of prepare
	pd->nbprepare = value;
	return;
}

/*!
 * \fn paddr readPDParent(paddr pdaddr)
 * \brief Gets the parent PD's address.
 * \param pdaddr The address of the PD
 * \return the pointer to the parent
 */
paddr readPDParent(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// Return the parent
	return pd->parent;
}

/*!
 * \fn void writePDParent(paddr pdaddr, paddr value)
 * \brief Sets the parent PD's address.
 * \param pdaddr The address of the PD
 * \param value The new value
 * \return void
 */
void writePDParent(paddr pdaddr, paddr value)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pd = (PDTable_t*)pdaddr;

	// write the number of prepare
	pd->parent = value;
	return;
}

/*!
 * \brief Read the address of the VIDT from a partition descriptor
 *        structure.
 *
 * \param partDescAddr The ID of the block containing a partition
 *        descriptor structure from which the VIDT address is to be
 *        read.
 *
 * \return The address of the VIDT.
 */
paddr readPDVidt(paddr partDescAddr)
{
	PDTable_t *partDesc = (PDTable_t *) partDescAddr;

	return partDesc->vidtAddr;
}

/*!
 * \brief Write the address of the VIDT to a partition descriptor
 *        structure.
 *
 * \param partDescAddr The ID of the block containing a partition
 *        descriptor structure from which the VIDT address is to be
 *        written.
 *
 * \param vidtAddr The address of the VIDT to write to the partition
 *        descriptor structure.
 */
void writePDVidt(paddr partDescAddr, paddr vidtAddr)
{
	PDTable_t *partDesc = (PDTable_t *) partDescAddr;

	partDesc->vidtAddr = vidtAddr;
}

/*!
 * \fn paddr readBlockStartFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the block's start address from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return the block's start address
 */
paddr readBlockStartFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the start address
	return (blockentry->blockrange).startAddr;
}

/*!
 * \fn void writeBlockStartFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the block's start address.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockStartFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the block's start address
	(blockentry->blockrange).startAddr = value;
	return;
}

/*!
 * \fn paddr readBlockEndFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the block's end address from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return the block's end address
 */
paddr readBlockEndFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the end address
	return (blockentry->blockrange).endAddr;
}

/*!
 * \fn void writeBlockEndFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the block's end address.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockEndFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the block's end address
	(blockentry->blockrange).endAddr = value;
	return;
}

/*!
 * \fn bool readBlockAccessibleFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the Accessible flag from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return 1 if the page is user-mode accessible, 0 else
 */
bool readBlockAccessibleFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	//MALDBG("readBlockAccessibleFromBlockEntryAddr(%d) -> %d\r\n", blockentryaddr, blockentry->accessible);
	//printf("readBlockAccessibleFromBlockEntryAddr(%x) -> %d\r\n", blockentryaddr, blockentry->accessible);

	// Return the accessible flag
	return blockentry->accessible;
}

/*!
 * \fn void writeBlockAccessibleFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Sets a memory block as accessible or not.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockAccessibleFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the flag
	blockentry->accessible = value;
	return;
}

/*!
 * \fn bool readBlockPresentFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the Present flag from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return 1 if the block is present, 0 else
 */
bool readBlockPresentFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	//MALDBG("readBlockPresentFromBlockEntryAddr(%d) -> %d\r\n", blockentryaddr, blockentry->present);
	//printf("readBlockPresentFromBlockEntryAddr(%x) -> %d\r\n", blockentryaddr, blockentry->present);

	// Return the present flag
	return blockentry->present;
}

/*!
 * \fn void writeBlockPresentFromBlockEntryAddr(paddr blockentryaddr, bool value)
 * \brief Sets a memory block as present or not.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockPresentFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the flag
	blockentry->present = value;
	return;
}

/*!
 * \fn uint32_t readBlockIndexFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the Block index from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return the Block index
 */
uint32_t readBlockIndexFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the Block index
	return (uint32_t) (blockentry->blockindex).i;
}

/*!
 * \fn void writeBlockIndexFromBlockEntryAddr(paddr blockentryaddr, uint32_t value)
 * \brief Sets the Block index.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockIndexFromBlockEntryAddr(paddr blockentryaddr, uint32_t value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the block index
	(blockentry->blockindex).i = value;
	return;
}

/*!
 * \fn bool readBlockRFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the Present flag from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return 1 if the read flag is set, 0 else
 */
bool readBlockRFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the read flag
	return blockentry->read;
}

/*!
 * \fn void writeBlockRFromBlockEntryAddr(paddr blockentryaddr, bool value)
 * \brief Sets a memory block as readable or not.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockRFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the read flag
	blockentry->read = value;
	return;
}

/*!
 * \fn bool readBlockWFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the write flag from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return 1 if the write flag is set, 0 else
 */
bool readBlockWFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the write flag
	return blockentry->write;
}

/*!
 * \fn void writeBlockWFromBlockEntryAddr(paddr blockentryaddr, bool value)
 * \brief Sets a memory block as writable or not.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockWFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the flag
	blockentry->write = value;
	return;
}

/*!
 * \fn bool readBlockXFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the exec flag from the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return 1 if the exec flag is set, 0 else
 */
bool readBlockXFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the exec flag
	return blockentry->exec;
}

/*!
 * \fn void writeBlockXFromBlockEntryAddr(paddr blockentryaddr, bool value)
 * \brief Sets a memory block as executable or not.
 * \param blockentryaddr The address of the block entry to write in
 * \param value The new value
 * \return void
 */
void writeBlockXFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// write the flag
	blockentry->exec = value;
	return;
}

/*!
 * \fn BlockEntry_t readBlockEntryFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the block entry at the given entry.
 * \param blockentryaddr The address of the block entry to read from
 * \return the block entry
 */
BlockEntry_t readBlockEntryFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	// Return the block entry
	return *blockentry;
}

/*!
 * \brief Copies block structures at the given addresses
 */
void copyBlock(paddr blockTarget, paddr blockSource) {
    ((blockOrError *)blockTarget)->blockAttr.blockentryaddr = blockSource;
    ((blockOrError *)blockTarget)->blockAttr.blockrange.startAddr = ((BlockEntry_t *)blockSource)->blockrange.startAddr;
    ((blockOrError *)blockTarget)->blockAttr.blockrange.endAddr = ((BlockEntry_t *)blockSource)->blockrange.endAddr;
    ((blockOrError *)blockTarget)->blockAttr.read = ((BlockEntry_t *)blockSource)->read;
    ((blockOrError *)blockTarget)->blockAttr.write = ((BlockEntry_t *)blockSource)->write;
    ((blockOrError *)blockTarget)->blockAttr.exec = ((BlockEntry_t *)blockSource)->exec;
    ((blockOrError *)blockTarget)->blockAttr.accessible = ((BlockEntry_t *)blockSource)->accessible;
}

/*!
 * \brief Sets the block entry.
 * \param blockentryaddr The address of the block entry to write in
 * \param index Index of the slot in the kernel structure containing it
 * \param startAddr The block's start address
 * \param endAddr The block's end address (or pointer to the next free slot if it is one)
 * \param accessible Block accessible
 * \param present Block present
 * \param read Read permission
 * \param write Write permission
 * \param exec Exec permission
 */
void writeBlockEntryFromBlockEntryAddr(paddr blockentryaddr, uint32_t index,
	paddr startAddr, paddr endAddr, bool accessible, bool present,
	bool read, bool write, bool exec)
{
	writeBlockStartFromBlockEntryAddr(blockentryaddr, startAddr);
	writeBlockEndFromBlockEntryAddr(blockentryaddr, endAddr);
	writeBlockAccessibleFromBlockEntryAddr(blockentryaddr, accessible);
	writeBlockPresentFromBlockEntryAddr(blockentryaddr, present);
	writeBlockRFromBlockEntryAddr(blockentryaddr, read);
	writeBlockWFromBlockEntryAddr(blockentryaddr, write);
	writeBlockXFromBlockEntryAddr(blockentryaddr, exec);
	writeBlockIndexFromBlockEntryAddr(blockentryaddr, index);
	return;
}

/*!
 * \fn paddr getSh1EntryAddrFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the Sh1 entry from the block entry.
 * \param blockentryaddr The address of the reference block entry
 * \return the corresponding SH1 entry address to the given block entry
 */
paddr getSh1EntryAddrFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	uint32_t entryindex = (blockentry->blockindex).i;// TODO protect from NULL access ?

	paddr kernelStartAddr = getKernelStructureStartAddr(blockentryaddr, entryindex);

	// Return the SH1 entry address
	return getSh1EntryAddrFromKernelStructureStart(kernelStartAddr, entryindex);
}

/*!
 * \fn paddr readSh1PDChildFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the child's PD from the given entry.
 * \param blockentryaddr The address of the reference block entry
 * \return the child PD if shared, NULL otherwise
 */
paddr readSh1PDChildFromBlockEntryAddr(paddr blockentryaddr)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// Return the child PD
	return sh1entry->PDchild;
}

/*!
 * \fn void writeSh1PDChildFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the entry's child PD.
 * \param blockentryaddr The address of the reference block entry
 * \param value The new value
 * \return void
 */
void writeSh1PDChildFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// write the child PD
	sh1entry->PDchild = value;
	return;
}

/*!
 * \fn bool readSh1PDFlagFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the child's PD from the given entry.
 * \param blockentryaddr The address of the reference block entry
 * \return 1 if child is PD, NULL otherwise
 */
bool readSh1PDFlagFromBlockEntryAddr(paddr blockentryaddr)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// Return the PD flag
	return sh1entry->PDflag;
}

/*!
 * \fn void writeSh1PDFlagFromBlockEntryAddr(paddr blockentryaddr, bool value)
 * \brief Sets the entry's PD flag.
 * \param blockentryaddr The address of the reference block entry
 * \param value The new value
 * \return void
 */
void writeSh1PDFlagFromBlockEntryAddr(paddr blockentryaddr, bool value)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// write the flag
	sh1entry->PDflag = value;
	return;
}

/*!
 * \fn paddr readSh1InChildLocationFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the location of the block in the child.
 * \param blockentryaddr The address of the reference block entry
 * \return the location of the block in the child if shared, NULL otherwise
 */
paddr readSh1InChildLocationFromBlockEntryAddr(paddr blockentryaddr)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// Return the location in the child
	return sh1entry->inChildLocation;
}

/*!
 * \fn void writeSh1InChildLocationFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the block's location in the child.
 * \param blockentryaddr The address of the reference block entry
 * \param value The new value
 * \return void
 */
void writeSh1InChildLocationFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Get the corresponding Sh1 entry addres
	paddr sh1entryaddr = getSh1EntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a Sh1Entry_t structure
	Sh1Entry_t* sh1entry = (Sh1Entry_t*)sh1entryaddr;

	// write the block's location in the child
	sh1entry->inChildLocation = value;
	return;
}

/*!
 * \brief Sets the block's SH1 entry.
 * \param blockentryaddr The address of the reference block entry
 * \param pdChild Pointer to the child the block is shared with
 * \param pdFlag Block content is a PD
 * \param inChildLocation Pointer to the slot where the block lies in the child partition
 * \return void
 */
void writeSh1EntryFromBlockEntryAddr(paddr blockentryaddr, paddr pdChild, bool pdFlag, paddr inChildLocation)
{
	writeSh1PDChildFromBlockEntryAddr(blockentryaddr, pdChild);
	writeSh1PDFlagFromBlockEntryAddr(blockentryaddr, pdFlag);
	writeSh1InChildLocationFromBlockEntryAddr(blockentryaddr, inChildLocation);

	return;
}

/*!
 * \fn paddr getSCEntryAddrFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the SC entry from the block entry.
 * \param blockentryaddr The address of the reference block entry
 * \return the corresponding SC entry address to the given block entry
 */
paddr getSCEntryAddrFromBlockEntryAddr(paddr blockentryaddr)
{
	// Cast it into a BlockEntry_t structure
	BlockEntry_t* blockentry = (BlockEntry_t*)blockentryaddr;

	uint32_t entryindex = (blockentry->blockindex).i;// TODO protect from NULL access ?

	paddr kernelStartAddr = getKernelStructureStartAddr(blockentryaddr, entryindex);

	// Return the SC entry address
	return getSCEntryAddrFromKernelStructureStart(kernelStartAddr, entryindex);
}

/*!
 * \fn paddr readSCOriginFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the block's origin.
 * \param blockentryaddr The address of the reference block entry
 * \return the block origin if block is present, NULL otherwise
 */
paddr readSCOriginFromBlockEntryAddr(paddr blockentryaddr)
{
	// Get the corresponding SC entry addres
	paddr scentryaddr = getSCEntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a SCEntry_t structure
	SCEntry_t* scentry = (SCEntry_t*)scentryaddr;

	// Return the block's origin
	return scentry->origin;
}

/*!
 * \fn void writeSCOriginFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the block's origin.
 * \param blockentryaddr The address of the reference block entry
 * \param value The new value
 * \return void
 */
void writeSCOriginFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Get the corresponding SC entry addres
	paddr scentryaddr = getSCEntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a SCEntry_t structure
	SCEntry_t* scentry = (SCEntry_t*)scentryaddr;

	// write the block's origin
	scentry->origin = value;
	return;
}

/*!
 * \fn paddr readSCNextFromBlockEntryAddr(paddr blockentryaddr)
 * \brief Gets the block's next subblock.
 * \param blockentryaddr The address of the reference block entry
 * \return the block origin if block is present, NULL otherwise
 */
paddr readSCNextFromBlockEntryAddr(paddr blockentryaddr)
{
	// Get the corresponding SC entry addres
	paddr scentryaddr = getSCEntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a SCEntry_t structure
	SCEntry_t* scentry = (SCEntry_t*)scentryaddr;

	// Return the block's next subblock
	return scentry->next;
}

/*!
 * \fn void writeSCNextFromBlockEntryAddr(paddr blockentryaddr, paddr value)
 * \brief Sets the block's next subblock.
 * \param blockentryaddr The address of the reference block entry
 * \param value The new value
 * \return void
 */
void writeSCNextFromBlockEntryAddr(paddr blockentryaddr, paddr value)
{
	// Get the corresponding SC entry addres
	paddr scentryaddr = getSCEntryAddrFromBlockEntryAddr(blockentryaddr);

	// Cast it into a SCEntry_t structure
	SCEntry_t* scentry = (SCEntry_t*)scentryaddr;

	// write the block's next subblock
	scentry->next = value;
	return;
}

/*!
 * \brief Sets the block's SC entry.
 * \param blockentryaddr The address of the reference block entry
 * \param origin Pointer to the original (sub)block
 * \param next Pointer to the next subblock
 */
void writeSCEntryFromBlockEntryAddr(paddr blockentryaddr, paddr origin, paddr next)
{
	writeSCOriginFromBlockEntryAddr(blockentryaddr, origin);
	writeSCNextFromBlockEntryAddr(blockentryaddr, next);

	return;
}

/*!
 * \fn paddr getNextAddrFromKernelStructureStart(paddr structureaddr)
 * \brief Gets pointer to the next pointer.
 * \param structureaddr The address of the kernel structure
 * \return the address of the structure's next pointer
 */
paddr getNextAddrFromKernelStructureStart(paddr structureaddr)
{
	KStructure_t* ks = (KStructure_t*) structureaddr;
	return &ks->next;
}

/*!
 * \fn paddr readNextFromKernelStructureStart(paddr structureaddr)
 * \brief Gets the pointer to the next Kstructure of the current <structureaddr> structure.
 * \param structureaddr The address of the kernel structure
 * \return the pointer to the next KStructure, NULL otherwise
 */
paddr readNextFromKernelStructureStart(paddr structureaddr)
{
	uint32_t* nextaddr = (uint32_t*) getNextAddrFromKernelStructureStart(structureaddr);
	return (paddr) *nextaddr;
}

/*!
 * \fn void writeNextFromKernelStructureStart(paddr structureaddr, paddr newnextstructure)
 * \brief Sets the pointer to the next Kstructure of the current <structureaddr> structure.
 * \param structureaddr The address of the kernel structure
 * \param newnextstructure The new next structure pointer
 * \return void
 */
void writeNextFromKernelStructureStart(paddr structureaddr, paddr newnextstructure)
{
	uint32_t** nextaddr = (uint32_t**) getNextAddrFromKernelStructureStart(structureaddr);

	// modify the pointer to the next KStructure
	*nextaddr = newnextstructure;
	return;
}

/*!
 * \fn bool eraseBlock (paddr startAddr, paddr endAddr)
 * \brief Erases the memory block defined by (startAddr, endAddr).
 * \param startAddr The block's start address
 * \param endAddr The block's end address
 * \return 0 if the block has been sucessfully erased, -1 otherwise
 */
bool eraseBlock (paddr startAddr, paddr endAddr)
{
	if (endAddr <= startAddr) return false;
	for (paddr curraddr = endAddr -1 ; startAddr <= curraddr ; curraddr--)
	{
		*(uint8_t*)curraddr = 0;
	}
	return true;
}

/*!
 * \fn void initPDTable(paddr)
 * \brief Initialises PD table at paddr with a default PD table
 */
void initPDTable(paddr pdtablepaddr) {
	PDTable_t* pdtable = (PDTable_t*)pdtablepaddr;
	*pdtable = DEFAULT_PD_TABLE;
	clear_LUT(pdtable->LUT);
}

/*!
 * \fn paddr getPDStructurePointerAddrFromPD(paddr pdaddr)
 * \brief Gets the structure pointer of the given PD.
 * \param pdaddr The PD where to find the structure pointer
 * \return the kernel structure pointer if exists, otherwise NULL
 */
paddr getPDStructurePointerAddrFromPD(paddr pdaddr)
{
	// Cast it into a PDTable_t structure
	PDTable_t* pdtable = (PDTable_t*)pdaddr;
	return (paddr) &(pdtable->structure);
}

/*!
 * \fn void readBlockFromPhysicalMPU(paddr pd, uint32_t MPURegionNb)
 * \brief 	Reads the block configured at the given region of the physical MPU.
 * \param pd The PD to read from
 * \param MPURegionNb The physical MPU region to read
 * \return the block's address in BLK
 */
paddr readBlockFromPhysicalMPU(paddr pd, uint32_t MPURegionNb)
{
	PDTable_t* PDT = (PDTable_t*) pd;
	return PDT->mpu[MPURegionNb];
}

/*!
 * \fn void removeBlockFromPhysicalMPU(paddr pd, paddr blockentryaddr)
 * \brief 	Removes the given block from the set to be configured in the MPU for the given pd.
 * \param pd The PD where the block should be removed from
 * \param blockentryaddr The block to remove
 * \return void
 */
void removeBlockFromPhysicalMPU(paddr pd, paddr blockentryaddr)
{
	PDTable_t* PDT = (PDTable_t*) pd;
	// Find and remove the block in the MPU
	for (int i=0; i < MPU_REGIONS_NB ; i++)
	{
		if (PDT->mpu[i] == (BlockEntry_t*)blockentryaddr)
		{
			// block is configured in the physical MPU and is removed
			//clear_LUT_entry(PDT->LUT, i);
			configure_LUT_entry(PDT->LUT, i, NULL, NULL);
			PDT->mpu[i] = NULL;
		}
	}
}

/*!
 * \fn void removeBlockFromPhysicalMPUIfNotAccessible(paddr pd, paddr blockentryaddr, bool accessiblebit)
 * \brief 	Removes the given block from the set to be configured in the MPU for the given pd.
 *			Should only be removed if the block becomes not accessible, otherwise doesn't break the MPU consistency.
 * \param pd The PD where the block should be removed from
 * \param blockentryaddr The block to remove
 * \param accessiblebit The accessible bit of the block
 * \return void
 */
void removeBlockFromPhysicalMPUIfNotAccessible(paddr pd, paddr blockentryaddr, bool accessiblebit)
{
	if (!accessiblebit)
	{
		// the block is not accessible and should be removed from the physical MPU
		removeBlockFromPhysicalMPU(pd, blockentryaddr);
	}

}

/* TODO: don't call full mpu replacement for a single block */
/*!
 * \fn void replaceBlockInMPU(paddr pd, paddr blockblockentryaddr, index MPURegionNb)
 * \brief Replaces a block in the physical MPU of the given partition
 * \param pd the PD where to reconfigure the physical MPU
 * \param blockblockentryaddr The new block's entry
 * \param MPURegionNb The physical MPU region where the block will be configured
 * \return void
 */
void replaceBlockInPhysicalMPU(paddr pd, paddr blockblockentryaddr, uint32_t MPURegionNb)
{
	// replace the given LUT entry with the new block
	PDTable_t* PDT = (PDTable_t*) pd;
	PDT->mpu[MPURegionNb] = (BlockEntry_t*)blockblockentryaddr;
	configure_LUT_entry(PDT->LUT, MPURegionNb, blockblockentryaddr, PDT->mpu[MPURegionNb]->blockrange.startAddr);

	/* Reconfigure the MPU from LUT if and only if the partition
	 * descriptor passed as argument is the partition descriptor of
	 * the current partition. */
	if (pd == getCurPartition())
	{
		mpu_configure_from_LUT(PDT->LUT);
	}
}


/*!
 * \fn uint32_t findBlockIdxInPhysicalMPU(paddr pd, paddr blockToFound, uint32_t defaultnb)
 * \brief Finds a block's MPU region number in the physical MPU of the given partition
 * \param pd the PD where to search the physical MPU
 * \param blockToFind The block to find
 * \param defaultnb The default region number to return in case of fail
 * \return the MPU region where the block is configured, defaultnb if not found
 */
uint32_t findBlockIdxInPhysicalMPU(paddr pd, paddr blockToFind, uint32_t defaultnb)
{
	// Find the block in the blocks' list
	PDTable_t* PDT = (PDTable_t*) pd;
	for(uint32_t i=0 ; i < MPU_REGIONS_NB ; i++)
	{
		if(PDT->mpu[i] == blockToFind)
		{
			// Block found, return the MPU region number
			return i;
		}
	}
	// else return the default number
	return defaultnb;

}


/*! \fn paddr getCurPartition()
 	\brief get the current page directory
	\return the current page directory
 */
paddr getCurPartition(void)
{
	return current_partition;
}

/*! \fn void updateCurPartition()
 \brief Set current partition paddr
 \param partition Current partition paddr
 */
void
updateCurPartition (paddr descriptor)
{
	current_partition = descriptor;
	//DEBUG(TRACE, "Registered partition descriptor %x.\n", descriptor);
	//printf("DEBUG: Registered partition descriptor %p.\n", descriptor);
}

/*! \fn paddr getRootPartition()
 \brief get the root partition
	\return the root partition
 */
paddr getRootPartition(void)
{
	return constantRootPartM;
}

/*! \fn paddr updateRootPartition(paddr partition)
 \brief Set new root partition
 \param partition Root partition
 */
void
updateRootPartition(paddr partition)
{
	constantRootPartM = partition;
}

/*!
 * \fn bool checkEntry(uint32_t* kstructurestart, uint32_t* blockentryaddr)
 * \brief Checks the given address is a valid BLK structure entry
 *			With a misalignment, the index won't match the real index
 *	 		in the kernel structure
 * \param kstructurestart the kernel structure holding the entry
 * \param blockentryaddr The entry to check
 * \return True if entry is aligned with a kernel entry/False otherwise
 */
bool checkEntry(paddr kstructurestart, paddr blockentryaddr)
{
	// blockentryaddr checked before and lies within the kernel structure
	KStructure_t* ks = (KStructure_t*) kstructurestart;
	uint32_t index = (BlockEntry_t*) blockentryaddr - ks->blocks;//blockentryaddr - kstructurestart;
	return (&ks->blocks[index] == blockentryaddr) ? true : false;
}

/*!
 * \fn bool checkBlockInRAM(paddr blockentryaddr)
 * \brief Checks whether the block lies in RAM or not
 * \param blockentryaddr The block entry to check
 * \return True if the block is entirely defined in the RAM/False otherwise
 */
bool checkBlockInRAM(paddr blockentryaddr)
{
	// blockentryaddr checked before and lies within the kernel structure
	BlockEntry_t* block = (BlockEntry_t*) blockentryaddr;
	int startInRAM = ((void *) &__ramStart) <= block->blockrange.startAddr;
	int endInRAM = block->blockrange.endAddr <=  ((void *) &__ramEnd);
	return (startInRAM && endInRAM);
}

/*!
 * \fn bool check32Aligned(paddr addrToCheck)
 * \brief Checks whether the address is 32-bytes aligned or not
 * \param addrToCheck The address to check
 * \return True if the address is 32-bytes aligned/False otherwise
 */
bool check32Aligned(paddr addrToCheck)
{
	return ((uint32_t) addrToCheck & 0x1F) == 0;
}

/*!
 * \fn blockOrError blockAttr(paddr blockentryaddr, BlockEntry_t blockentry)
 * \brief Wrapper to create a blockAttr inside the blockOrError union
 * \param blockentryaddr The block's address
 * \param blockentry the block's attributes to set
 * \return the given block's public attributes
 */
blockOrError blockAttr(paddr blockentryaddr, BlockEntry_t blockentry)
{
	blockAttr_t block = {blockentryaddr, blockentry.blockrange, blockentry.read, blockentry.write,
						blockentry.exec, blockentry.accessible};
	return (blockOrError){ .blockAttr = block };
}

/* activate:
 * switch to given partition address space
 * the partition must already be validated */
void activate(paddr desc)
{
	PDTable_t* PDT = (PDTable_t*) desc;
	if (PDT == NULL)
	{
		printf("ERROR: can't activate %p\r\n", desc);
		while(1);
	}

	//printf("DEBUG: activate %p: loading MPU...\r\n", desc);

	if (mpu_configure_from_LUT(PDT->LUT) < 0)
	{
		printf("ERROR: can't activate %p\r\n", desc);
		while(1);
	}

	//printf("DEBUG: activate %p: MPU loaded\r\n", desc);
}

void updateCurPartAndActivate(paddr calleePartDescGlobalId)
{
	updateCurPartition(calleePartDescGlobalId);
	activate(calleePartDescGlobalId);
}
