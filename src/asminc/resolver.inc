
RESOLVER_BASE = $4000

declResolve = RESOLVER_BASE
setResolverUnitsList = RESOLVER_BASE + 3
getResolverUnitsList = RESOLVER_BASE + 6
injectSystemUnit = RESOLVER_BASE + 9
resolveUnits = RESOLVER_BASE + 12
setDeclOffsets = RESOLVER_BASE + 15
setUnitOffsets = RESOLVER_BASE + 18
fixGlobalOffsets = RESOLVER_BASE + 21
verifyFwdDeclarations = RESOLVER_BASE + 24
initStandardRoutines = RESOLVER_BASE + 27
addModuleUnit = RESOLVER_BASE + 30   ; a unit compiled on its own, root in Q
