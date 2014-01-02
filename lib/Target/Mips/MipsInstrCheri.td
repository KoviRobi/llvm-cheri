//=- MipsInstrCheri.td - Target Description for CHERI Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the CHERI instruction definitions
//
//===----------------------------------------------------------------------===//

def SDT_MipsCBT      : SDTypeProfile<0, 2, [SDTCisVT<0, iFATPTR>]>;
def MipsCBTS : SDNode<"MipsISD::CBTS", SDT_MipsCBT,
                          [SDNPHasChain, SDNPOptInGlue]>;
def MipsCBTU : SDNode<"MipsISD::CBTU", SDT_MipsCBT,
                          [SDNPHasChain, SDNPOptInGlue]>;
let isCall=1, hasDelaySlot=1, Defs = [RA] in {}

// 11-bit immediate offset used by C[SL]CR
def simm11: Operand<i64>;
def immSExt11  : PatLeaf<(imm), [{ return isInt<11>(N->getSExtValue()); }]>;
// 8-bit immediate offset used by C[SL]C
def simm8: Operand<i64>;

////////////////////////////////////////////////////////////////////////////////
// Flow control
////////////////////////////////////////////////////////////////////////////////
def CBTS : CheriFmtCBT<0x0a, (outs), (ins CheriRegs:$cd, brtarget:$offset),
                        "cbts\t$cd, $offset",
                        [(MipsCBTS CheriRegs:$cd, bb:$offset)]>;
def CBTU : CheriFmtCBT<0x09, (outs), (ins CheriRegs:$cd, brtarget:$offset),
                        "cbtu\t$cd, $offset",
                        [(MipsCBTU CheriRegs:$cd, bb:$offset)]>;
def CJR : CheriFmt3CJMP<0x08, (outs), (ins CheriRegs:$cb, GPR64:$rt),
                              "cjr\t${rt}(${cb})",
                              []> {
  let hasDelaySlot=1;
}
let isTerminator=1, isCall=1, hasDelaySlot=1 in {
def CJALR : CheriFmt3CJMP<0x07, (outs), (ins CheriRegs:$cb, GPR64:$rt),
                              "cjalr\t${rt}(${cb})",
                              []>;
def CCall : CheriFmt3CCall<0x05, (outs), (ins CheriRegs:$cs, CheriRegs:$cb),
                              "ccall\t${cs}, ${cb}",
                              []>;
}
def CReturn : CheriFmt3CRet<0x06, (outs), (ins variable_ops),
                              "creturn",
                              []> {
  let isTerminator = 1;
  let isReturn = 1;
  let hasDelaySlot = 1;
}

////////////////////////////////////////////////////////////////////////////////
// Capability manipulation
////////////////////////////////////////////////////////////////////////////////
def CIncBase : CheriFmtSet<2, (outs CheriRegs:$cd), (ins CheriRegs:$cb, GPR64:$rt),
                           "cincbase\t$cd, $cb, $rt",
                           [(set CheriRegs:$cd, (inttoptr (add GPR64:$rt, (ptrtoint CheriRegs:$cb))))]> {
  let hasSideEffects = 1;
}
def : InstAlias<"cmove $dst, $src",
                (CIncBase CheriRegs:$dst, CheriRegs:$src,ZERO_64), 1>;

def CGetBase : CheriFmtGet<2, (outs GPR64:$rd), (ins CheriRegs:$cb),
                           "cgetbase $rd, $cb",
                           [(set GPR64:$rd, (ptrtoint CheriRegs:$cb))]>;


def CGetTag : CheriFmtGet<5, (outs GPR64:$rd), (ins CheriRegs:$cb),
                          "cgettag $rd, $cb",
                          [(set GPR64:$rd, (int_cheri_get_cap_tag CheriRegs:$cb))]>;

def CSetLength : CheriFmtSet<3, (outs CheriRegs:$cd), (ins CheriRegs:$cb, GPR64:$rt),
                             "csetlen\t$cd, $cb, $rt",
                             [(set CheriRegs:$cd, (int_cheri_set_cap_length CheriRegs:$cb, GPR64:$rt))]> {
  let hasSideEffects = 1;
}

def CGetLength : CheriFmtGet<3, (outs GPR64:$rd), (ins CheriRegs:$cb),
                             "cgetlen $rd, $cb",
                             [(set GPR64:$rd, (int_cheri_get_cap_length CheriRegs:$cb))]>;

def CAndPerm : CheriFmtSet<0, (outs CheriRegs:$cd), (ins CheriRegs:$cb, GPR64:$rt),
                           "candperm\t$cd, $cb, $rt",
                           [(set CheriRegs:$cd, (int_cheri_and_cap_perms CheriRegs:$cb, GPR64:$rt))]>;

def CGetPerm : CheriFmtGet<0, (outs GPR64:$rd), (ins CheriRegs:$cb),
                           "cgetperm $rd, $cb",
                           [(set GPR64:$rd, (int_cheri_get_cap_perms CheriRegs:$cb))]>;

def CSetType : CheriFmtSet<1, (outs CheriRegs:$cd), (ins CheriRegs:$cb, GPR64:$rt),
                           "csettype\t$cd, $cb, $rt",
                           [(set CheriRegs:$cd, (int_cheri_set_cap_type CheriRegs:$cb, GPR64:$rt))]>;

def CGetType : CheriFmtGet<1, (outs GPR64:$rd), (ins CheriRegs:$cb),
                           "cgettype $rd, $cb",
                           [(set GPR64:$rd, (int_cheri_get_cap_type CheriRegs:$cb))]>;

def CSealData : CheriFmt3Caps<0x02, (outs CheriRegs:$cd), (ins CheriRegs:$cs, CheriRegs:$ct),
                              "csealdata\t$cd, $cs, $ct",
                              [(set CheriRegs: $cd, (int_cheri_seal_cap_data CheriRegs:$cs, CheriRegs:$ct))]>;

def CSealCode : CheriFmt2Caps<0x01, (outs CheriRegs:$cd), (ins CheriRegs:$cs),
                              "csealcode\t$cd, $cs",
                              [(set CheriRegs: $cd, (int_cheri_seal_cap_code CheriRegs:$cs))]>;

def CUnseal   : CheriFmt3Caps<0x03, (outs CheriRegs:$cd), (ins CheriRegs:$cs, CheriRegs:$ct),
                              "cunseal\t$cd, $cs, $ct",
                              [(set CheriRegs: $cd, (int_cheri_unseal_cap CheriRegs:$cs, CheriRegs:$ct))]>;

def CGetUnsealed : CheriFmtGet<6, (outs GPR64:$rd), (ins CheriRegs:$cb),
                          "cgetunsealed\t$rd, $cb",
                          [(set GPR64:$rd, (int_cheri_get_cap_unsealed CheriRegs:$cb))]>;
def CGetPCC : CheriFmtGet<7, (outs GPR64:$rd, CheriRegs:$cb), (ins),
                          "cgetpcc\t${rd}(${cb})",
                          []>;
def CGetCause : CheriFmtCause<0, (outs GPR64:$rd), (ins ),
                          "cgetcause\t${rd}",
                          [(set GPR64:$rd, (int_cheri_get_cause))]>;
def CSetCause : CheriFmtCause<4, (outs), (ins GPR64: $rs),
                          "csetcause\t${rs}",
                          [(int_cheri_set_cause GPR64: $rs)]>;

// Int to pointer in address space 0
def : Pat<(inttoptr GPR64:$rt),
          (CIncBase C0, GPR64:$rt)>;

let DecoderNamespace="CHERI" in
def STORECAP : CheriFmtCSCR<(outs), (ins CheriRegs:$cs, GPR64:$rt, simm11:$offset, CheriRegs:$cb),
                         "csc\t$cs, ${rt}, ${offset}(${cb})",
                         [(store CheriRegs:$cs, (add (add GPR64:$rt, (ptrtoint CheriRegs:$cb)), (i64 immSExt11:$offset)))]>;

def CLEARTAG : CheriFmtClearTag<(outs CheriRegs:$cd), (ins), "ccleartag\t$cd",
                                [(set CheriRegs:$cd, (inttoptr (i64 0)))]>;

def : Pat<(store CheriRegs:$cs, CheriRegs:$cb),
          (STORECAP CheriRegs:$cs, ZERO_64, (i64 0), $cb)>;
def : Pat<(store CheriRegs:$cs, GPR64:$rt),
          (STORECAP CheriRegs:$cs, GPR64:$rt, (i64 0), C0)>;

// Load a capability
let Predicates = [IsCHERI] in {
def LOADCAP : CheriFmtCLCR<(outs CheriRegs:$cs), (ins GPR64:$rt, simm11:$offset, CheriRegs:$cb),
                        "clc\t$cs, ${rt}, ${offset}(${cb})",
                        [(set CheriRegs:$cs, (load (add (add GPR64:$rt, (ptrtoint CheriRegs:$cb)), (i64 immSExt11:$offset))))]> {
  let DecoderNamespace="CHERI";
}

def : Pat<(load GPR64:$rt),
          (LOADCAP GPR64:$rt, (i64 0), C0)>;
def : Pat<(load CheriRegs:$cb),
          (LOADCAP ZERO_64, (i64 0), CheriRegs:$cb)>;

// Load via a capability register
let canFoldAsLoad = 1, DecoderNamespace="CHERI" in
multiclass LoadViaCap<bits<2> t, bit sExt, string instr_asm, RegisterOperand RC, PatFrag loadType> {
  def #NAME# : CheriFmtCLX<t, sExt,
                             (outs RC:$rd),
                             (ins GPR64:$rt, simm8:$offset, CheriRegs:$cb),
                             !strconcat(instr_asm, "\t$rd, ${rt}, ${offset}(${cb})"),
                           [(set RC:$rd, (loadType(add (add (ptrtoint CheriRegs:$cb), GPR64:$rt), (i64 immSExt8:$offset))))]>;
}

let DecoderNamespace="CHERI" in {
def CLLD : CheriFmtCLX<3, 1,
                             (outs GPR64:$rd),
                             (ins GPR64:$rt, simm8:$offset, CheriRegs:$cb),
                             "clld\t$rd, ${rt}, ${offset}(${cb})",
                           []> {
  let mayLoad=1;
}
def CSCD : CheriFmtCSX<3, 1,
                             (outs ),
                             (ins GPR64:$rs, GPR64:$rt, simm8:$offset, CheriRegs:$cb),
                             "cscd\t$rs, ${rt}, ${offset}(${cb})",
                           []> {
  let mayStore=1;
}
}
multiclass LoadViaCap0<Instruction Op, PatFrag loadType> {
  def : Pat<(loadType CheriRegs:$cb),
            (Op ZERO_64, (i64 0), CheriRegs:$cb)>;
}


defm CAPLOAD8      : LoadViaCap<0, 1, "clb", GPR64Opnd, sextloadi8>;
defm CAPLOAD16     : LoadViaCap<1, 1, "clh", GPR64Opnd, sextloadi16>;
defm CAPLOAD32     : LoadViaCap<2, 1, "clw", GPR32Opnd, load>;
defm CAPLOAD64     : LoadViaCap<3, 0, "cld", GPR64Opnd, load>;

defm CAPLOADU8     : LoadViaCap<0, 0, "clbu", GPR64Opnd, extloadi8>;
defm CAPLOADU16    : LoadViaCap<1, 0, "clhu", GPR64Opnd, extloadi16>;
defm CAPLOADU32    : LoadViaCap<2, 0, "clwu", GPR64Opnd, extloadi32>;

defm CAP0LOADA8     : LoadViaCap0<CAPLOAD8, extloadi8>;
defm CAP0LOADA16    : LoadViaCap0<CAPLOAD16, extloadi16>;
defm CAP0LOADA32    : LoadViaCap0<CAPLOAD32, extloadi32>;

defm CAP0LOADU8     : LoadViaCap0<CAPLOADU8, zextloadi8>;
defm CAP0LOADU16    : LoadViaCap0<CAPLOADU16, zextloadi16>;
defm CAP0LOADU32    : LoadViaCap0<CAPLOADU32, zextloadi32>;

defm CAP0LOAD8     : LoadViaCap0<CAPLOAD8, sextloadi8>;
defm CAP0LOAD16    : LoadViaCap0<CAPLOAD16, sextloadi16>;
defm CAP0LOAD32    : LoadViaCap0<CAPLOAD32, load>;
defm CAP0LOAD64    : LoadViaCap0<CAPLOAD64, load>;

// Store via a capability register
let DecoderNamespace="CHERI" in
multiclass StoreViaCap<bits<2> t, bit e, string instr_asm, RegisterOperand RC, PatFrag storeType> {
  def #NAME# : CheriFmtCSX<t, e,
                             (outs),
                             (ins RC:$rs, GPR64:$rt, simm8:$offset, CheriRegs:$cb),
                             !strconcat(instr_asm, "\t$rs, ${rt}, ${offset}(${cb})"),
                           [(storeType (add (add (ptrtoint CheriRegs:$cb), GPR64: $rt), (i64 immSExt8:$offset)), RC:$rs)]>;
}
multiclass StoreViaCap0<Instruction Op, RegisterOperand RC, PatFrag storeType> {
  def : Pat<(storeType RC:$rd, CheriRegs:$cb),
            (Op RC:$rd, ZERO_64, (i64 0), CheriRegs:$cb)>;
  def : Pat<(storeType RC:$rd, (add (ptrtoint CheriRegs:$cb), GPR64:$rt)),
            (Op RC:$rd, GPR64:$rt, (i64 0), CheriRegs:$cb)>;
}
defm CAPSTORE8      : StoreViaCap<0, 0, "csb", GPR64Opnd, truncstorei8>;
defm CAPSTORE16     : StoreViaCap<1, 0, "csh", GPR64Opnd, truncstorei16>;
defm CAPSTORE32     : StoreViaCap<2, 0, "csw", GPR32Opnd, store>;
defm CAPSTORE64     : StoreViaCap<3, 0, "csd", GPR64Opnd, store>;
//def : Pat<(truncstorei8 (add (add (ptrtoint CheriRegs:$cb), GPR64: $rt), (i64 immSExt8:$offset)),
          

defm CAP0STORE8     : StoreViaCap0<CAPSTORE8, GPR64Opnd, truncstorei8>;
defm CAP0STORE16    : StoreViaCap0<CAPSTORE16, GPR64Opnd, truncstorei16>;
defm CAP0STORE32    : StoreViaCap0<CAPSTORE32, GPR32Opnd, store>;
defm CAP0STORE64    : StoreViaCap0<CAPSTORE64, GPR64Opnd, store>;

class CheriFPUMemPseudo<dag outs, dag ins, string asmstr,
                list<dag> pattern> :
  MipsInst<outs, ins, asmstr, pattern, NoItinerary, Pseudo>
{
  let isPseudo = 1;
  let usesCustomInserter = 1;
}

def CLDC1 : CheriFPUMemPseudo<(outs FGR64: $rd),
  (ins GPR64:$rt, simm8:$offset, CheriRegs:$cb),
  "cldc1\t$rd,  ${rt}, ${offset}(${cb})",
  [(set FGR64:$rd, (load (add (add (ptrtoint CheriRegs:$cb), GPR64:$rt), (i64 immSExt8:$offset))))]>;


def CLWC1 : CheriFPUMemPseudo<(outs FGR32Opnd: $rd),
  (ins GPR64:$rt, simm8:$offset, CheriRegs:$cb),
  "clwc1\t$rd,  ${rt}, ${offset}(${cb})",
  [(set FGR32Opnd:$rd, (load (add (add (ptrtoint CheriRegs:$cb), GPR64:$rt), (i64 immSExt8:$offset))))]>;

def CSDC1 : CheriFPUMemPseudo<(outs),
  (ins FGR64:$rs, GPR64:$rt, simm8:$offset, CheriRegs:$cb),
  "csdc1\t$rs,  ${rt}, ${offset}(${cb})",
  [(store (add (add (ptrtoint CheriRegs:$cb), GPR64:$rt), (i64 immSExt8:$offset)), FGR64: $rs)]>;

def CSWC1 : CheriFPUMemPseudo<(outs),
  (ins FGR32Opnd:$rs, GPR64:$rt, simm8:$offset, CheriRegs:$cb),
  "cswc1\t$rs,  ${rt}, ${offset}(${cb})",
  [(store (add (add (ptrtoint CheriRegs:$cb), GPR64:$rt), (i64 immSExt8:$offset)), FGR32Opnd: $rs)]>;

defm : LoadViaCap0<CLWC1, load>;
defm : LoadViaCap0<CLDC1, load>;
defm : StoreViaCap0<CSWC1, FGR32Opnd, store>;
defm : StoreViaCap0<CSDC1, FGR64Opnd, store>;

}