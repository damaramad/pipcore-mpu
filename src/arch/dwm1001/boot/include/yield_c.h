/*******************************************************************************/
/*  © Université de Lille, The Pip Development Team (2015-2021)                */
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

#ifndef __YIELD_C_H__
#define __YIELD_C_H__

#include <stdint.h>
#include "mal.h"

/*!
 * \brief Enumeration of the possible return codes for the yield system
 *        call.
 */
typedef enum yield_return_code_e
{
	/*!
	 * \brief The system call succeeds without error.
	 *
	 * \warning This value is never returned by the yield system
	 *          call, but is required for a future implementation
	 *          of the service in Coq.
	 */
	YIELD_SUCCESS = 0,

	/*!
	 * \brief The VIDT index of the callee is greater than 32.
	 */
	CALLEE_INVALID_VIDT_INDEX = 1,

	/*!
	 * \brief The VIDT index of the caller is greater than 32.
	 */
	CALLER_INVALID_VIDT_INDEX = 2,

	/*!
	 * \brief The callee is not a child of the caller.
	 */
	CALLEE_NOT_CHILD_OF_CALLER = 3,

	/*!
	 * \brief The root partition tried to call its parent.
	 */
	CALLEE_IS_PARENT_OF_ROOT = 4,

	/*!
	 * \brief The address of the block containing the VIDT of the
	 *        caller is null.
	 */
	CALLER_VIDT_IS_NULL = 5,

	/*!
	 * \brief The block containing the VIDT of the caller does not
	 *        have the present flag.
	 */
	CALLER_VIDT_IS_NOT_PRESENT = 6,

	/*!
	 * \brief The block containing the VIDT of the caller does not
	 *        have the accessible flag.
	 */
	CALLER_VIDT_IS_NOT_ACCESSIBLE = 7,

	/*!
	 * \brief The address of the block containing the VIDT of the
	 *        callee is null.
	 */
	CALLEE_VIDT_IS_NULL = 8,

	/*!
	 * \brief The block containing the VIDT of the callee does not
	 *        have the present flag.
	 */
	CALLEE_VIDT_IS_NOT_PRESENT = 9,

	/*!
	 * \brief The block containing the VIDT of the callee does not
	 *        have the accessible flag.
	 */
	CALLEE_VIDT_IS_NOT_ACCESSIBLE = 10,

	/*!
	 * \brief No block were found in the caller's address space
	 *        that match the context address read from the VIDT.
	 */
	CALLER_CONTEXT_BLOCK_NOT_FOUND = 11,

	/*!
	 * \brief The block containing the address to which the context
	 *        of the caller is to be written does not have the
	 *        present flag.
	 */
	CALLER_CONTEXT_BLOCK_IS_NOT_PRESENT = 12,

	/*!
	 * \brief The block containing the address to which the context
	 *        of the caller is to be written does not have the
	 *        accessible flag.
	 */
	CALLER_CONTEXT_BLOCK_IS_NOT_ACCESSIBLE = 13,

	/*!
	 * \brief The block containing the address to which the context
	 *        of the caller is to be written does not have the
	 *        writable flag.
	 */
	CALLER_CONTEXT_BLOCK_IS_NOT_WRITABLE = 14,

	/*!
	 * \brief The address of the caller's context, added to the
	 *        size of a context, exceeds the end of the block.
	 */
	CALLER_CONTEXT_EXCEED_BLOCK_END = 15,

	/*!
	 * \brief The address to which the caller's context should be
	 *        written is not aligned on a 4-byte boundary.
	 */
	CALLER_CONTEXT_MISALIGNED = 16,

	/*!
	 * \brief No block were found in the callee's address space
	 *        that match the context address read from the VIDT.
	 */
	CALLEE_CONTEXT_BLOCK_NOT_FOUND = 17,

	/*!
	 * \brief The block containing the address at which the context
	 *        of the callee is to be read does not have the present
	 *        flag.
	 */
	CALLEE_CONTEXT_BLOCK_IS_NOT_PRESENT = 18,

	/*!
	 * \brief The block containing the address at which the context
	 *        of the callee is to be read does not have the
	 *        accessible flag.
	 */
	CALLEE_CONTEXT_BLOCK_IS_NOT_ACCESSIBLE = 19,

	/*!
	 * \brief The block containing the address at which the context
	 *        of the callee is to be read does not have the readable
	 *        flag.
	 */
	CALLEE_CONTEXT_BLOCK_IS_NOT_READABLE = 20,

	/*!
	 * \brief The address of the callee's context, added to the size
	 *        of a context, exceeds the end of the block.
	 */
	CALLEE_CONTEXT_EXCEED_BLOCK_END = 21,

	/*!
	 * \brief The address at which the callee's context should be
	 *        read is not aligned on a 4-byte boundary.
	 */
	CALLEE_CONTEXT_MISALIGNED = 22

} yield_return_code_t;

typedef uint32_t uservalue_t;
typedef uint32_t int_mask_t;

/*!
 * \brief System call that yield from the current partition (the
 *        caller), to its parent or one of its childs (the callee).
 * \param svc_ctx Registers stacked by the SVC handler.
 * \param calleePartDescBlockId The ID of the block containing the
 *        partition descriptor structure of a child of the current
 *        partition, or an ID equals to 0 for the partition descriptor
 *        structure of its parent.
 * \param userTargetInterrupt The index of the VIDT, which contains the
 *        address pointing to the location where the current context is
 *        to be restored.
 * \param userCallerContextSaveIndex The index of the VIDT, which
 *        contains the address pointing to the location where the
 *        current context is to be stored. If this address is zero, the
 *        context is not stored.
 * \param flagsOnYield The state the partition wishes to be on yield.
 * \param flagsOnWake The state the partition wishes to be on wake.
 * \return If the system call succeeds, no value is returned to the
 *         caller. If an error occurs, the system call returns an error
 *         code indicating the nature of the error. If the context is
 *         restored, the return value should be ignored.
 */
yield_return_code_t yieldGlue(
	context_svc_t *svc_ctx,
	paddr calleePartDescAddr,
	uservalue_t userTargetInterrupt,
	uservalue_t userCallerContextSaveIndex,
	int_mask_t flagsOnYield,
	int_mask_t flagsOnWake
);

/*!
 * \brief Yield to another partition.
 * \warning This function is publicly exposed only to start the root
 *          partition.
 * \param calleePartDesc The ID of the block containing the partition
 *        descriptor structure of the partition on which to yield.
 * \param flagsOnYield The state the partition wishes to be on yield.
 * \param ctx The context from which to restore the processor registers.
 * \return Although the function has a return type, it never returns to
 *         the caller. This return type is required for a future
 *         implementation of the service in Coq.
 */
yield_return_code_t switchContextCont(
	paddr calleePartDesc,
	int_mask_t flagsOnYield,
	user_context_t *ctx
);

#endif /* __YIELD_C_H__ */