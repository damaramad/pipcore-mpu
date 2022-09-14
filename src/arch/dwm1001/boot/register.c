/*******************************************************************************/
/*  © Université de Lille, The Pip Development Team (2015-2022)                */
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

#include <stdint.h>

#include "accessor.h"

const registerIdToAccessor_t REGISTER_ID_TO_ACCESSOR[] =
{
	{ (volatile uint32_t *) 0x10000060, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x100000a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x100000a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x100000a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000000c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000010, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000010c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000418, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000578, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000908, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000918, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000928, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000938, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000948, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000958, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000968, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40000978, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x400005a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001010, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000110c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001138, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001144, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001148, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001400, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000150c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000151c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001520, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000152c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001530, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001534, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001538, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000153c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001644, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001648, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001650, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001660, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000166c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40001ffc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000250c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40002524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000256c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003124, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x400034c4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000350c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003534, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003538, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003588, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003010, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003118, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40003554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004124, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x400044c4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000450c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004534, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004538, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004588, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004010, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004118, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40004554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006108, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000610c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006114, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006118, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000611c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000651c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006520, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40006528, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000652c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007008, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000700c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007114, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x400075f0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x400075f4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000762c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40007630, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000900c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009040, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009044, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009048, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000904c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009050, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009054, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009144, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009148, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000914c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009150, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009154, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000954c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40009554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a00c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a040, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a044, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a048, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a04c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a050, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a054, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a144, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a148, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a14c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a150, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a154, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a54c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000a554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000c000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000c004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000c100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000c508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4000d508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010400, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001050c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40010600, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40011540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001200c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012108, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001251c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012520, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40012528, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a00c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a040, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a044, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a048, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a04c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a050, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a054, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a144, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a148, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a14c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a150, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a154, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a54c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001a554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b00c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b040, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b044, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b048, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b04c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b050, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b054, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b144, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b148, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b14c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b150, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b154, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b200, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b54c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001b554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001e400, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001e504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001e508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001e540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f51c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f520, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f528, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f52c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f530, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f534, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f538, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f53c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f54c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f558, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f55c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f560, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f564, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f568, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f56c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f570, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f574, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f578, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f57c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f580, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f584, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f588, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f58c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f590, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f594, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f598, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f59c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f5a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f5a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f5a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x4001f5ac, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024000, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024004, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024140, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024304, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024308, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x40024540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000050c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000700, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000704, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000708, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000070c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000710, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000714, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000718, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000071c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000720, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000724, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000728, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000072c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000730, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000734, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000738, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000073c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000740, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000744, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000748, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000074c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000750, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000754, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000758, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000075c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000760, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000764, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000768, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000076c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000770, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000774, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x50000778, registerAccessReadWrite },
	{ (volatile uint32_t *) 0x5000077c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e100, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e104, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e108, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e10c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e110, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e114, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e118, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e11c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e120, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e124, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e128, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e12c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e130, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e134, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e138, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e13c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e180, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e184, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e188, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e18c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e190, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e194, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e198, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e19c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1ac, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1b0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1b4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1b8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e1bc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e280, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e284, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e288, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e28c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e290, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e294, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e298, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e29c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2ac, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2b0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2b4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2b8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e2bc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e400, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e404, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e408, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e40c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e410, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e414, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e418, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e41c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e420, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e424, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e428, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e42c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e430, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e434, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e438, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e43c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e440, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e444, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e448, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e44c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e450, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e454, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e458, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e45c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e460, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e464, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e468, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e46c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e470, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e474, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e478, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e47c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e480, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e484, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e488, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e48c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e490, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e494, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e498, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e49c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4ac, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4b0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4b4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4b8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4bc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4c0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4c4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4c8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4cc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4d0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4d4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4d8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4dc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4e0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4e4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4e8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4ec, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4f0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4f4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4f8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e4fc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e500, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e504, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e508, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e50c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e510, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e514, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e518, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e51c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e520, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e524, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e528, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e52c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e530, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e534, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e538, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e53c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e540, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e544, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e548, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e54c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e550, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e554, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e558, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e55c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e560, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e564, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e568, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e56c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e570, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e574, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e578, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e57c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e580, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e584, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e588, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e58c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e590, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e594, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e598, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e59c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5a0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5a4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5a8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5ac, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5b0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5b4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5b8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5bc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5c0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5c4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5c8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5cc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5d0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5d4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5d8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5dc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5e0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5e4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5e8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000e5ec, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed04, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed10, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed14, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed18, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed1c, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed20, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed28, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000ed88, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xe000edfc, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xf0000fe0, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xf0000fe4, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xf0000fe8, registerAccessReadWrite },
	{ (volatile uint32_t *) 0xf0000fec, registerAccessReadWrite },
};
