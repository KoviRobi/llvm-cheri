//===-- Mips.h - Top-level interface for Mips representation ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM Mips back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_MIPS_MIPS_H
#define LLVM_LIB_TARGET_MIPS_MIPS_H

#include "MCTargetDesc/MipsMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
  class MipsTargetMachine;
  class ModulePass;
  class FunctionPass;
  class MachineFunctionPass;

  ModulePass *createMipsOs16Pass(MipsTargetMachine &TM);
  ModulePass *createMips16HardFloatPass(MipsTargetMachine &TM);

  FunctionPass *createMipsModuleISelDagPass(MipsTargetMachine &TM);
  FunctionPass *createMipsOptimizePICCallPass(MipsTargetMachine &TM);
  FunctionPass *createMipsDelaySlotFillerPass(MipsTargetMachine &TM);
  FunctionPass *createMipsLongBranchPass(MipsTargetMachine &TM);
  FunctionPass *createMipsConstantIslandPass(MipsTargetMachine &tm);

  FunctionPass *createCheriInvalidatePass(MipsTargetMachine &TM);
  FunctionPass *createCheriRangeChecker(void);
  FunctionPass *createCheriMemOpLowering(void);
  ModulePass *createCheriSandboxABI(void);
  MachineFunctionPass *createCheriAddressingModeFolder(MipsTargetMachine &TM);
  MachineFunctionPass *createCheriBranchFolder(void);
} // end namespace llvm;

#endif
