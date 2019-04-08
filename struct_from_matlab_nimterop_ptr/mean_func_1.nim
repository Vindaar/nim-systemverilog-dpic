import nimterop/cimport
import os
from macros import getProjectPath

# static:
#   cDisableCaching()
#   cDebug()

const
  meanFuncIncludePath = getProjectPath() / "matlab_export"
  meanFuncHeader = meanFuncIncludePath / "mean_func_1.h"
  # mean_func_1_64.so is generated by running ./build_script_64.
  meanFuncSo = meanFuncIncludePath / "mean_func_1_64.so"
static:
  doAssert fileExists(meanFuncIncludePath / "rtwtypes.h")
  doAssert fileExists(meanFuncIncludePath / "mean_func_1_types.h")
  doAssert fileExists(meanFuncHeader)
  # Put cAddSearchDir in static block:
  #  https://github.com/nimterop/nimterop/issues/122
  cAddSearchDir(meanFuncIncludePath)

cImport(cSearchPath("rtwtypes.h"))

cOverride:
  type
    emxArray_int32_T* = object
      data*: ptr UncheckedArray[cint] # this pointer needed to be fixed
      size*: ptr UncheckedArray[cint] # this pointer needed to be fixed
      allocatedSize*: cint
      numDimensions*: cint
      canFreeData*: boolean_T

# For now, we need to cimport each included file manually:
#  https://github.com/nimterop/nimterop/issues/123
cImport(cSearchPath("mean_func_1_types.h"))

type
  DataObj* = emxArray_int32_T
  InputObj* = struct0_T
  OutputObj* = struct1_T

# FIXME Below does not work
# proc mean_func*(inp: ptr InputObj; outp: ptr OutputObj) {.importc: "mean_func_1", header: meanFuncHeader.}
# Below is needed
proc mean_func*(inp: ptr InputObj; outp: ptr OutputObj) {.importc: "mean_func_1", dynlib: meanFuncSo.}
