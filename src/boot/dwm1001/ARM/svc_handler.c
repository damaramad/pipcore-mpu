#include "ExceptionHandlers.h"
#include "Services.h"
#include "nrf52.h"
#include "core_cm4.h"

extern void
  SVC_Handler (void);


void __attribute__ ((section(".after_vectors"),weak))
SVC_Handler (void)
{
  __asm(
    ".global SVC_Handler_Main\n"
    "TST lr, #4\n"
    "ITE EQ\n"
    "MRSEQ r0, MSP\n"
    "MRSNE r0, PSP\n"
    "B SVC_Handler_Main\n"
  ) ;
}

void SVC_Handler_Main( unsigned int *svc_args )
{
#if defined(DEBUG)
  __DEBUG_BKPT();
#endif

  unsigned int svc_number;
  // TODO : disable interrupts

  /*
  * Stack contains:
  * r0, r1, r2, r3, r12, r14, the return address and xPSR
  * First argument (r0) is svc_args[0]
  */
  svc_number = ( ( char * )svc_args[ 6 ] )[ -2 ] ;
  uint32_t * sp = svc_args;
  uint32_t * orig_sp = NULL;
  uint32_t psr = sp[7];  /* Program status register. */
  /* Reconstruct original stack pointer before fault occurred */
  orig_sp = sp + 8;
#ifdef SCB_CCR_STKALIGN_Msk
  if (psr & SCB_CCR_STKALIGN_Msk) {
      /* Stack was not 8-byte aligned */
      orig_sp += 1;
      printf("Stack was not 8-byte aligned\r\n");
  }
#endif /* SCB_CCR_STKALIGN_Msk */
  switch( svc_number )
  {
    case 0:
      sp[0] = createPartition((uint32_t *)svc_args[0]); //paddr idBlock
      break;
    case 1:
      sp[0] = cutMemoryBlock((uint32_t *)svc_args[0], //paddr idBlockToCut,
                                (uint32_t *)svc_args[1], //paddr cutAddr,
                                svc_args[2] //index mPURegionNb)
                                );
      break;
    case 2:
      sp[0] = mergeMemoryBlocks((uint32_t *)svc_args[0], //paddr idBlockToMerge1,
                                (uint32_t *)svc_args[1], //paddr idBlockToMerge2,
                                svc_args[2] //index mPURegionNb)
                                );
      break;
    case 3:
      sp[0] = prepare((uint32_t *)svc_args[0], //paddr idPD,
                      svc_args[1], //index projectedSlotsNb,
                      (uint32_t *)svc_args[2] //paddr idRequisitionedBlock
                      );
    break;

    case 4:
        sp[0] = addMemoryBlock((uint32_t *)svc_args[0], //paddr idPDchild,
                              (uint32_t *)svc_args[1], //paddr idBlockToShare,
                              (uint32_t *)svc_args[2], //bool r,
                              (uint32_t *)svc_args[3], //bool w,
                              (uint32_t *)orig_sp[0] //bool e)
                              );
      break;
    case 5:
        sp[0] = removeMemoryBlock((uint32_t *)svc_args[0], //paddr idPDchild,
                                      (uint32_t *)svc_args[1] //paddr idBlockToRemove
                                      );
      break;

     case 6:
        sp[0] = deletePartition((uint32_t *)svc_args[0]); //paddr idPDchildToDelete
      break;

    case 7:
        sp[0] = collect((uint32_t *)svc_args[0]); //paddr idPD
      break;
    case 8:
        sp[0] = mapMPU( (uint32_t *)svc_args[0], //paddr idPD
                        (uint32_t *)svc_args[1], //paddr idBlockToEnable,
                        svc_args[2] // index mPURegionNb
                        );
      break;
    case 9:
        sp[0] = readMPU((uint32_t *)svc_args[0], //paddr idPD
                        svc_args[1] // index mPURegionNb
                        );
      break;
/*    case 10:
        sp[0] = findBlock((uint32_t *)svc_args[0], //paddr idPD
                          (uint32_t *)svc_args[1] // paddr addrInBlock)
                          );
      break;*/
#ifdef UNIT_TESTS
    case 127: // Enable Privileged mode !TODO!: to remove with system calls in SVC instead
      __set_CONTROL( __get_CONTROL( ) & ~CONTROL_nPRIV_Msk ) ;
      break;
    case 128: // Disable Privileged mode !TODO!: to remove with system calls in SVC instead
      __set_CONTROL(__get_CONTROL() |
                    CONTROL_nPRIV_Msk ); // switch to unprivileged Thread Mode
      __DMB();
      __ISB();
      __DSB();
      break;
#endif // UNIT_TESTS
    default:    // unknown SVC
      break;
  }

}
