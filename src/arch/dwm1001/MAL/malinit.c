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

/*!
 * \file malinit.c
 *
 * \brief ARM memory abstraction layer initializer.
 */

#include <stdint.h>

#include "Internal.h"
#include "memlayout.h"
#include "stdio.h"
#include "mal.h"

/*!
 * \def PANIC
 *
 * \brief Print a message and loop forever.
 */
#define PANIC(...)                   \
	do                           \
	{                            \
		printf(__VA_ARGS__); \
		for (;;);            \
	} while (0)

/*!
 * \brief Returns the address passed as argument minus one.
 *
 * \param address The address from which to subtract one.
 *
 * \return The address passed as argument minus one.
 */
static inline void *
addressMinusOne(void *address)
{
	return ((void *)(((uintptr_t) address) - 1));
}

/*!
 * \brief Initialize the root partition descriptor structure.
 *
 * \param rootPartDesc The root partition structure to initialize.
 */
static inline void
initializeRootPartitionDescriptor(paddr rootPartDesc)
{
	paddr rootPartDescEndAddr = ((PDTable_t *) rootPartDesc) + 1;

	if (!eraseBlock(rootPartDesc, rootPartDescEndAddr))
	{
		PANIC("PIP: Failed to erase the root partition "
			"descriptor structure...\n");
	}

	initPDTable(rootPartDesc);
}

/*!
 * \brief Initialize the root kernel structure.
 *
 * \param rootKernStruct The root kernel structure to initialize.
 */
static inline void
initializeRootKernelStructure(paddr rootKernStruct)
{
	paddr rootKernStructEndAddr = ((KStructure_t *) rootKernStruct) + 1;

	if (!initStructure(rootKernStruct, rootKernStructEndAddr))
	{
		PANIC("PIP: Failed to initialize the root partition "
			"kernel structure...\n");
	}
}

/*!
 * \brief Prepare the root partition with a kernel structure.
 *
 * \param rootPartDesc The root partition to prepare.
 *
 * \param rootKernStruct The root kernel structure.
 */
static inline void
prepareRootPartition(paddr rootPartDesc, paddr rootKernStruct)
{
	writePDStructurePointer(rootPartDesc, rootKernStruct);
	writePDFirstFreeSlotPointer(rootPartDesc, rootKernStruct);
	writePDNbFreeSlots(rootPartDesc, KERNELSTRUCTUREENTRIESNB);
	writePDNbPrepare(rootPartDesc, 1);
}

/*!
 * \brief Create a new partition and register it as the root partition.
 */
static inline void
createAndRegisterRootPartition(void)
{
	/* Allocate space in the .data section for the root
	 * partition descriptor structure. */
	static PDTable_t rootPartDesc;

	/* Allocate space in the .data section for the root
	 * kernel structure. */
	static KStructure_t rootKernStruct;

	/* Initialize the root partition structures. */
	initializeRootPartitionDescriptor(&rootPartDesc);
	initializeRootKernelStructure(&rootKernStruct);
	prepareRootPartition(&rootPartDesc, &rootKernStruct);

#if !defined UNIT_TESTS

	paddr mpuRegion0Id = insertNewEntry(
		(paddr) &rootPartDesc,
		(paddr) &__mpuRegion0Start,
		(paddr) addressMinusOne(&__mpuRegion0End),
		(paddr) &__mpuRegion0Start,
		(bool) true,
		(bool) true,
		(bool) false,
		readPDNbFreeSlots(&rootPartDesc)
	);

	paddr mpuRegion1Id = insertNewEntry(
		(paddr) &rootPartDesc,
		(paddr) &__mpuRegion1Start,
		(paddr) addressMinusOne(&__mpuRegion1End),
		(paddr) &__mpuRegion1Start,
		(bool) true,
		(bool) true,
		(bool) false,
		readPDNbFreeSlots(&rootPartDesc)
	);

	paddr mpuRegion2Id = insertNewEntry(
		(paddr) &rootPartDesc,
		(paddr) &__mpuRegion2Start,
		(paddr) addressMinusOne(&__mpuRegion2End),
		(paddr) &__mpuRegion2Start,
		(bool) true,
		(bool) true,
		(bool) true,
		readPDNbFreeSlots(&rootPartDesc)
	);

	/* Map all blocks previously inserted into the kernel
	 * structure to the physical MPU. */
	enableBlockInMPU(&rootPartDesc, mpuRegion0Id, 0);
	enableBlockInMPU(&rootPartDesc, mpuRegion1Id, 1);
	enableBlockInMPU(&rootPartDesc, mpuRegion2Id, 2);

	/* Set the first MPU region as the current root partition
	 * VIDT region in the partition descriptor structure. */
	rootPartDesc.vidtAddr = (void *) &__rootVidtStart;

#endif /* UNIT_TESTS */

	/* Register the root partition to PIP. */
	updateRootPartition(&rootPartDesc);
}

/*!
 * \brief Initialize the Memory Abstraction Layer (MAL).
 */
extern void
malInit(void)
{
	if (checkMPU() < 0)
	{
		PANIC("PIP: No MPU found...\n");
	}

	if (initMPU() < 0)
	{
		PANIC("PIP: Failed to clear the MPU...\n");
	}

	createAndRegisterRootPartition();
}
