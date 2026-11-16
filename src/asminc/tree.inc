.struct TREENODE
    left .dword
    right .dword
    data .dword
    ; The null-terminated name. It must be the last member: addTreeNode
    ; allocates only as many bytes as the name needs, at most 24.
    key .res 24
.endstruct

